import Foundation
import Combine
import CoreImage
import AVFoundation
import CoreGraphics
import UIKit
import ImageIO

@MainActor
class ObjectDetectionViewModel: ObservableObject {
    
    // MARK: - Services
    let cameraManager: CameraManager
    private let ocrService: OCRService
    private let objectDetectionService: ObjectDetectionService
    
    // MARK: - Published Properties
    @Published var searchText: String = ""
    @Published var recognitionResults: [RecognitionResult] = []
    @Published var bufferSize: CGSize = .zero
    @Published var searchMode: SearchMode = .text // 默认为文字搜索
    @Published var currentZoomFactor: CGFloat = 1.0 // 相机变焦
    @Published var isZooming: Bool = false // 是否正在缩放 (用于暂停识别以提升性能)
    
    // 预设的常用物品提示词
    let commonObjectPrompts = ["杯子", "手机", "键盘", "鼠标", "水瓶", "书", "人", "猫", "狗", "电脑", "椅子", "背包"]
    
    // MARK: - Enums
    enum SearchMode: String, CaseIterable, Identifiable {
        case text = "文字"
        case object = "物品"
        
        var id: String { self.rawValue }
        var icon: String {
            switch self {
            case .text: return "text.viewfinder"
            case .object: return "cube.transparent"
            }
        }
    }
    
    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private var isProcessing = false
    private var searchTask: Task<Void, Never>?
    
    // Tracking
    private var lastResults: [RecognitionResult] = []
    private var lastFrameTime: TimeInterval = 0
    private let resultPersistenceTime: TimeInterval = 0.5 // 结果保留 0.5 秒，防止闪烁
    
    // MARK: - Initialization
    init(initialMode: SearchMode = .text,
         cameraManager: CameraManager = CameraManager(),
         ocrService: OCRService = OCRService(),
         objectDetectionService: ObjectDetectionService = ObjectDetectionService()) {
        self.searchMode = initialMode
        self.cameraManager = cameraManager
        self.ocrService = ocrService
        self.objectDetectionService = objectDetectionService
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    func processStaticImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        let orientation = image.cgImagePropertyOrientation
        
        // 停止相机流 (如果正在运行)
        cameraManager.stopSession()
        
        // 更新 bufferSize 以匹配图片尺寸 (考虑旋转)
        // 注意：Vision 返回的坐标是基于"校正后"的图像的，所以 bufferSize 必须也是校正后的尺寸
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let isRotated: Bool
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            isRotated = true
        default:
            isRotated = false
        }
        let size = isRotated ? CGSize(width: height, height: width) : CGSize(width: width, height: height)
        self.bufferSize = size
        
        // 取消之前的任务
        searchTask?.cancel()
        
        // 启动新的搜索任务 (延迟执行以防抖)
        searchTask = Task {
            // 简单的防抖：等待 0.3 秒，如果任务被取消则自动退出
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            
            // 如果正在缩放，暂缓识别
            if await MainActor.run(body: { self.isZooming }) { return }
            
            await MainActor.run { self.isProcessing = true }
            
            // 获取当前的搜索词和模式 (MainActor)
            let (currentKeyword, currentMode) = await MainActor.run { (self.searchText, self.searchMode) }
            
            if currentKeyword.isEmpty {
                 await MainActor.run {
                     self.recognitionResults = []
                     self.isProcessing = false
                 }
                 return
            }
            
            // 在后台线程执行耗时操作
            do {
                var newResults: [RecognitionResult] = []
                
                switch currentMode {
                case .text:
                    newResults = try await ocrService.performOCR(on: cgImage, orientation: orientation, keyword: currentKeyword)
                case .object:
                    newResults = try await objectDetectionService.detect(on: cgImage, orientation: orientation, searchKeyword: currentKeyword)
                }
                
                if Task.isCancelled { return }
                
                await MainActor.run {
                    self.recognitionResults = newResults
                    self.isProcessing = false
                    
                    if !newResults.isEmpty {
                        self.triggerFeedback()
                    }
                }
            } catch {
                if !Task.isCancelled {
                    print("Static Image Processing Error: \(error)")
                    await MainActor.run { self.isProcessing = false }
                }
            }
        }
    }

    func onAppear() {
        Task {
            if await cameraManager.checkPermissions() {
                try? cameraManager.setupCamera()
                cameraManager.startSession()
            }
        }
    }
    
    func onDisappear() {
        cameraManager.stopSession()
    }
    
    func setCameraZoom(factor: CGFloat) {
        cameraManager.setZoom(factor: factor)
        // 更新 UI 状态
        Task { @MainActor in
            self.currentZoomFactor = factor
        }
    }
    
    // MARK: - Bindings
    
    private func setupBindings() {
        // 订阅相机帧流
        cameraManager.videoOutputPublisher
            // 优化节流策略：
            // 1. 降低处理频率：从 200ms (5fps) 调整为 300ms (~3fps)，留出更多 CPU 给 UI 渲染
            // 2. 确保在后台线程处理，绝对不阻塞主线程
            .throttle(for: .milliseconds(300), scheduler: DispatchQueue.global(qos: .userInteractive), latest: true)
            .receive(on: DispatchQueue.global(qos: .userInitiated)) // 确保处理逻辑在后台
            .sink { [weak self] buffer in
                self?.processFrame(buffer)
            }
            .store(in: &cancellables)
    }
    
    private func processFrame(_ buffer: CMSampleBuffer) {
        // 快速检查：如果没有搜索词，直接跳过，不做任何耗时操作
        // 注意：这里访问 searchText 需要线程安全，或者仅在改变时更新一个 atomic 变量
        // 为简化，我们在 Task 内部再次检查，但这里先做个预判会更好。
        // 由于 searchText 是 @Published 且在主线程更新，直接访问可能不安全。
        // 更好的做法是：processFrame 仅负责丢进 Task，逻辑在 Task 内处理。
        
        guard !isProcessing else { return }
        
        // 引用计数 +1，保持 buffer 有效直到处理完成
        // CMSampleBuffer 是 Core Foundation 对象，Swift 自动管理引用，但跨线程时需小心
        
        Task { [weak self] in
            guard let self = self else { return }
            
            // 在 MainActor 获取当前状态，避免数据竞争
            let currentState = await MainActor.run { (self.searchText, self.searchMode, self.isZooming) }
            let currentKeyword = currentState.0
            let currentMode = currentState.1
            let isZooming = currentState.2
            
            // 如果正在缩放，跳过本帧识别，节省性能
            if isZooming { return }
            
            if currentKeyword.isEmpty {
                 await MainActor.run {
                     if !self.recognitionResults.isEmpty {
                         self.recognitionResults = []
                     }
                 }
                 return
            }
            
            if self.isProcessing { return }
            self.isProcessing = true
            
            // 获取 Buffer 尺寸
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else {
                self.isProcessing = false
                return
            }
            
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let size = CGSize(width: CGFloat(width), height: CGFloat(height))
            
            await MainActor.run {
                if self.bufferSize != size {
                    self.bufferSize = size
                }
            }
            
            do {
                // 根据模式选择执行的服务
                var newResults: [RecognitionResult] = []
                
                switch currentMode {
                case .text:
                    newResults = try await ocrService.performOCR(on: pixelBuffer, keyword: currentKeyword)
                case .object:
                    newResults = try await objectDetectionService.detect(on: pixelBuffer, searchKeyword: currentKeyword)
                }
                
                await MainActor.run {
                    self.updateResults(newResults)
                    self.isProcessing = false
                }
            } catch {
                print("Vision Processing Error: \(error)")
                self.isProcessing = false
            }
        }
    }
    
    /// 平滑更新结果，防止闪烁
    private func updateResults(_ newResults: [RecognitionResult]) {
        let now = Date().timeIntervalSince1970
        
        if !newResults.isEmpty {
            // 有新结果，直接更新并记录时间
            self.recognitionResults = newResults
            self.lastResults = newResults
            self.lastFrameTime = now
            
            // 触发反馈 (如果是新发现的目标)
            // 这里简单判断：如果之前为空，现在不为空，则触发
            if self.lastResults.isEmpty {
                self.triggerFeedback()
            }
        } else {
            // 没有新结果，检查是否在保留时间内
            if now - lastFrameTime < resultPersistenceTime {
                // 保持显示旧结果 (可选：可以降低不透明度)
                self.recognitionResults = lastResults
            } else {
                // 超时，清空
                self.recognitionResults = []
                self.lastResults = []
            }
        }
    }
    
    private func triggerFeedback() {
        if SettingsManager.shared.isHapticsEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        
        if SettingsManager.shared.isSoundEnabled {
            // 这里可以播放一个简短的系统音效
            AudioServicesPlaySystemSound(1057) // System sound for 'Tick' or similar
        }
    }
}

