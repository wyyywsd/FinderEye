import AVFoundation
import Combine
import UIKit

/// 定义相机服务的协议，方便后续进行 Mock 或替换实现
protocol CameraServiceProtocol: AnyObject {
    var session: AVCaptureSession { get }
    var isSessionRunning: Bool { get }
    var videoOutputPublisher: PassthroughSubject<CMSampleBuffer, Never> { get }
    
    func checkPermissions() async -> Bool
    func startSession()
    func stopSession()
    func setupCamera() throws
    
    // Zoom Support
    func setZoom(factor: CGFloat)
    func getZoomFactor() -> CGFloat
}

enum CameraError: Error {
    case permissionDenied
    case noCameraAvailable
    case setupFailed
}

/// 负责管理 AVCaptureSession，处理相机输入输出
final class CameraManager: NSObject, CameraServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.findereye.camera.sessionQueue")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    // 使用 Combine 发布每一帧数据，供 OCR 或 ML 模型订阅
    // 注意：这里的 Buffer 是在后台线程产生的，订阅者需要注意线程切换
    let videoOutputPublisher = PassthroughSubject<CMSampleBuffer, Never>()
    
    @Published var isSessionRunning: Bool = false
    private var isConfigured = false
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Public API
    
    func capturePhoto() async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .auto
            
            // Set up a delegate to handle the capture
            let delegate = PhotoCaptureDelegate { image in
                if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: CameraError.setupFailed) // Generic error
                }
            }
            
            // Keep a reference to the delegate so it doesn't get deallocated
            // This is a bit tricky with async/await and delegates.
            // A common pattern is to hold the delegate in a collection until it finishes.
            self.photoCaptureDelegates[settings.uniqueID] = delegate
            
            self.photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
    
    private var photoCaptureDelegates = [Int64: PhotoCaptureDelegate]()
    
    func checkPermissions() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
    
    func setupCamera() throws {
        guard !isConfigured else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.configureSession()
        }
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                }
            }
        }
    }
    
    // MARK: - Zoom Support
    
    func setZoom(factor: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let device = self.videoDeviceInput?.device else { return }
            
            do {
                try device.lockForConfiguration()
                // 限制缩放范围，防止过大模糊
                let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 5.0)
                let zoom = max(1.0, min(factor, maxZoom))
                device.videoZoomFactor = zoom
                device.unlockForConfiguration()
            } catch {
                print("Error setting zoom: \(error)")
            }
        }
    }
    
    func getZoomFactor() -> CGFloat {
        return videoDeviceInput?.device.videoZoomFactor ?? 1.0
    }
    
    // MARK: - Private Configuration
    
    private func configureSession() {
        session.beginConfiguration()
        
        // 1. 设置 Preset
        // 1080p 对于 OCR 和目标检测通常足够且性能平衡
        if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        } else {
            session.sessionPreset = .high
        }
        
        // 2. 添加输入
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoDeviceInput) else {
            print("Error: Cannot find camera or add input")
            session.commitConfiguration()
            return
        }
        
        // 配置自动对焦
        do {
            try videoDevice.lockForConfiguration()
            if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoDevice.focusMode = .continuousAutoFocus
            }
            if videoDevice.isSmoothAutoFocusSupported {
                videoDevice.isSmoothAutoFocusEnabled = true
            }
            videoDevice.unlockForConfiguration()
        } catch {
            print("Error configuring camera focus: \(error)")
        }
        
        session.addInput(videoDeviceInput)
        self.videoDeviceInput = videoDeviceInput
        
        // 3. 添加输出
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            
            // 丢弃延迟的帧，保证实时性
            videoOutput.alwaysDiscardsLateVideoFrames = true
            
            // 设置像素格式为 BGRA，Vision 框架支持良好
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            
            // 设置代理，在专门的处理队列中回调
            let videoDataOutputQueue = DispatchQueue(label: "com.findereye.camera.videoDataOutputQueue")
            videoOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Error: Cannot add video output")
            session.commitConfiguration()
            return
        }
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        // 4. 设置视频方向 (竖屏)
        if let connection = videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        session.commitConfiguration()
        isConfigured = true
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // 将视频帧发送出去
        videoOutputPublisher.send(sampleBuffer)
    }
}

// MARK: - PhotoCaptureDelegate
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            completion(nil)
            return
        }
        
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion(nil)
            return
        }
        
        completion(image)
    }
}
