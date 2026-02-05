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
    // private var isProcessing = false // Moved to DetectionState for thread safety
    private var searchTask: Task<Void, Never>?
    
    // Tracking
    private var lastResults: [RecognitionResult] = []
    private var lastFrameTime: TimeInterval = 0
    private let resultPersistenceTime: TimeInterval = 0.1 // 结果保留 0.1 秒，适应高刷新率
    
    // Result Fusion for Time-Sliced Detection
    // 缓存每个切片的检测结果，用于融合
    // Key: Slice Index (0=Full, 1..5=Slices)
    private var slicedResultsCache: [Int: [RecognitionResult]] = [:]
    // 缓存的过期时间 (超过 0.5 秒的切片结果视为失效)
    private var slicedResultsTimestamps: [Int: TimeInterval] = [:]
    private let sliceCacheDuration: TimeInterval = 0.5
    
    // Dynamic Frame Rate Control
    private class DetectionState: @unchecked Sendable {
        private let lock = NSLock()
        
        private var _isEditing = false
        var isEditing: Bool {
            get { lock.withLock { _isEditing } }
            set { lock.withLock { _isEditing = newValue } }
        }
        
        private var _hasResults = false
        var hasResults: Bool {
            get { lock.withLock { _hasResults } }
            set { lock.withLock { _hasResults = newValue } }
        }
        
        private var _lastProcessingTime: TimeInterval = 0
        var lastProcessingTime: TimeInterval {
            get { lock.withLock { _lastProcessingTime } }
            set { lock.withLock { _lastProcessingTime = newValue } }
        }
        
        private var _scanningFPS: Double = 5.0
        var scanningFPS: Double {
            get { lock.withLock { _scanningFPS } }
            set { lock.withLock { _scanningFPS = newValue } }
        }
        
        private var _trackingFPS: Double = 30.0
        var trackingFPS: Double {
            get { lock.withLock { _trackingFPS } }
            set { lock.withLock { _trackingFPS = newValue } }
        }
        
        private var _isProcessing = false
        var isProcessing: Bool {
            get { lock.withLock { _isProcessing } }
            set { lock.withLock { _isProcessing = newValue } }
        }
        
        private var _enableHighAccuracy: Bool = true
        var enableHighAccuracy: Bool {
            get { lock.withLock { _enableHighAccuracy } }
            set { lock.withLock { _enableHighAccuracy = newValue } }
        }
    }
    private let detectionState = DetectionState()
    
    // MARK: - Initialization
    init(initialMode: SearchMode = .text,
         cameraManager: CameraManager = CameraManager(),
         ocrService: OCRService = OCRService(),
         objectDetectionService: ObjectDetectionService = ObjectDetectionService()) {
        self.searchMode = initialMode
        self.cameraManager = cameraManager
        self.ocrService = ocrService
        self.objectDetectionService = objectDetectionService
        
        // Initialize FPS and Settings
        self.detectionState.scanningFPS = SettingsManager.shared.scanningFPS
        self.detectionState.trackingFPS = SettingsManager.shared.trackingFPS
        self.detectionState.enableHighAccuracy = SettingsManager.shared.isHighAccuracyModeEnabled
        
        setupBindings()
        setupSettingsObservers()
    }
    
    private func setupSettingsObservers() {
        SettingsManager.shared.$scanningFPS
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fps in
                self?.detectionState.scanningFPS = fps
            }
            .store(in: &cancellables)
            
        SettingsManager.shared.$trackingFPS
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fps in
                self?.detectionState.trackingFPS = fps
            }
            .store(in: &cancellables)
            
        SettingsManager.shared.$isHighAccuracyModeEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.detectionState.enableHighAccuracy = isEnabled
            }
            .store(in: &cancellables)
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
            
            // 线程安全的状态检查
            if self.detectionState.isProcessing { return }
            self.detectionState.isProcessing = true
            defer { self.detectionState.isProcessing = false }
            
            // 获取当前的搜索词和模式 (MainActor)
            let (currentKeyword, currentMode) = await MainActor.run { (self.searchText, self.searchMode) }
            
            if currentKeyword.isEmpty {
                 await MainActor.run {
                     self.recognitionResults = []
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
                    // 使用高精度模式 (切片检测) 处理静态图片，解决户外大场景下小物体漏检问题
                    newResults = try await objectDetectionService.detectHighAccuracy(on: cgImage, orientation: orientation, searchKeyword: currentKeyword)
                }
                
                if Task.isCancelled { return }
                
                await MainActor.run {
                    self.recognitionResults = newResults
                    
                    if !newResults.isEmpty {
                        self.triggerFeedback()
                    }
                }
            } catch {
                if !Task.isCancelled {
                    print("Static Image Processing Error: \(error)")
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
    
    func setEditing(_ isEditing: Bool) {
        detectionState.isEditing = isEditing
    }
    
    // MARK: - Bindings
    
    private func setupBindings() {
        // 订阅相机帧流
        cameraManager.videoOutputPublisher
            // 移除固定 throttle，改用手动动态帧率控制
            .receive(on: DispatchQueue.global(qos: .userInitiated)) // 确保处理逻辑在后台
            .sink { [weak self] buffer in
                guard let self = self else { return }
                
                // 在后台线程进行准入检查，减少主线程压力
                let now = Date().timeIntervalSince1970
                let state = self.detectionState
                
                // 1. 如果正在编辑 (键盘弹出)，完全暂停识别，优先保证 UI 响应
                if state.isEditing { return }
                
                // 2. 动态帧率控制
                // 尊重用户设置的 FPS，即使在高精度模式下也不强制限流
                let scanningFPS = state.scanningFPS
                let scanningInterval = 1.0 / max(scanningFPS, 0.1) // 防止除以零
                let trackingFPS = state.trackingFPS
                let trackingInterval = 1.0 / max(trackingFPS, 0.1)
                let targetInterval = state.hasResults ? trackingInterval : scanningInterval
                
                // print("DEBUG: FPS Check - Scanning: \(scanningFPS), Tracking: \(trackingFPS), HasResults: \(state.hasResults), TargetInterval: \(targetInterval)")
                
                if now - state.lastProcessingTime < targetInterval {
                    return
                }
                
                // 3. 并发限制 (线程安全)
                if state.isProcessing { return }
                state.isProcessing = true
                
                state.lastProcessingTime = now
                
                self.processFrame(buffer)
            }
            .store(in: &cancellables)
    }
    
    private func processFrame(_ buffer: CMSampleBuffer) {
        // 引用计数 +1，保持 buffer 有效直到处理完成
        // CMSampleBuffer 是 Core Foundation 对象，Swift 自动管理引用，但跨线程时需小心
        
        Task { [weak self] in
            guard let self = self else { return }
            
            // 确保任务结束时重置标志位
            defer { self.detectionState.isProcessing = false }
            
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
            
            // 获取 Buffer 尺寸
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else {
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
                    // Text mode doesn't use slicing cache yet
                    await MainActor.run {
                        self.updateResults(newResults)
                    }
                    
                case .object:
                    // 检查是否启用高精度分块检测
                    if self.detectionState.enableHighAccuracy {
                        // 使用分时切片检测 (Time-Sliced Detection)
                        // 每次只跑 1 次推理，极大提升 FPS
                        let (partialResults, sliceIndex) = try await objectDetectionService.detectTimeSliced(on: pixelBuffer, searchKeyword: currentKeyword)
                        
                        await MainActor.run {
                            // 1. 更新缓存
                            let now = Date().timeIntervalSince1970
                            self.slicedResultsCache[sliceIndex] = partialResults
                            self.slicedResultsTimestamps[sliceIndex] = now
                            
                            // 2. 清理过期缓存
                            for (idx, timestamp) in self.slicedResultsTimestamps {
                                if now - timestamp > self.sliceCacheDuration {
                                    self.slicedResultsCache.removeValue(forKey: idx)
                                    self.slicedResultsTimestamps.removeValue(forKey: idx)
                                }
                            }
                            
                            // 3. 融合结果 (Merge)
                            var allCachedResults: [RecognitionResult] = []
                            for (_, results) in self.slicedResultsCache {
                                allCachedResults.append(contentsOf: results)
                            }
                            
                            // 4. 客户端去重 (NMS)
                            let merged = self.mergeCachedResults(allCachedResults)
                            self.updateResults(merged)
                        }
                    } else {
                        // 仅使用全图检测 (无切片，性能最高)
                        newResults = try await objectDetectionService.detect(on: pixelBuffer, searchKeyword: currentKeyword)
                        
                        // 清空切片缓存，避免切换模式后残留
                        await MainActor.run {
                            if !self.slicedResultsCache.isEmpty {
                                self.slicedResultsCache.removeAll()
                                self.slicedResultsTimestamps.removeAll()
                            }
                            self.updateResults(newResults)
                        }
                    }
                }
            } catch {
                print("Vision Processing Error: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 简单的客户端结果合并 (解决分时检测导致的重叠)
    private func mergeCachedResults(_ results: [RecognitionResult]) -> [RecognitionResult] {
        if results.isEmpty { return [] }
        if results.count == 1 { return results }
        
        // 按置信度排序
        let sorted = results.sorted { $0.confidence > $1.confidence }
        var selected: [RecognitionResult] = []
        
        for item in sorted {
            // 检查是否与已选结果严重重叠
            var isRedundant = false
            for exist in selected {
                let iou = calculateIOU(item.boundingBox, exist.boundingBox)
                // 如果 IOU > 0.45 且标签相同（或非常相似），视为同一个
                // 这里我们简化：只要位置重叠大，就抑制低置信度的
                if iou > 0.45 {
                    isRedundant = true
                    break
                }
            }
            
            if !isRedundant {
                selected.append(item)
            }
        }
        return selected
    }
    
    private func calculateIOU(_ rect1: CGRect, _ rect2: CGRect) -> CGFloat {
        let intersection = rect1.intersection(rect2)
        if intersection.isNull { return 0 }
        let intersectionArea = intersection.width * intersection.height
        let unionArea = rect1.width * rect1.height + rect2.width * rect2.height - intersectionArea
        if unionArea <= 0 { return 0 }
        return intersectionArea / unionArea
    }
    
    /// 平滑更新结果，防止闪烁
    private func updateResults(_ newResults: [RecognitionResult]) {
        let now = Date().timeIntervalSince1970
        
        // 同步状态给后台线程
        detectionState.hasResults = !newResults.isEmpty
        
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

