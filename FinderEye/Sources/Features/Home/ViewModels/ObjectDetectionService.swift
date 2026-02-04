import Vision
import CoreML
import UIKit
import ImageIO

/// 负责加载 YOLO-World Core ML 模型并进行推理
final class ObjectDetectionService {
    
    // MARK: - Properties
    
    private var visionModel: VNCoreMLModel?
    private var detectionRequest: VNCoreMLRequest?
    
    // 用于过滤结果的置信度阈值
    // private let confidenceThreshold: Float = 0.3 // 已废弃，改用 SettingsManager

    
    // 模型文件名称
    private let modelName = "ObjectDetector"
    
    // MARK: - Initialization
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        Task {
            do {
                // 1. 寻找模型文件路径
                // 注意：在实际 App Bundle 中，编译后的模型通常是 .mlmodelc 文件夹
                // 这里我们假设 .mlpackage 已经被 Xcode 编译并打包进 Bundle
                guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
                    print("❌ Error: Could not find \(modelName).mlmodelc in bundle.")
                    return
                }
                
                // 2. 加载 Core ML 模型
                let config = MLModelConfiguration()
                config.computeUnits = .all // 优先使用 NPU (ANE)
                
                let model = try MLModel(contentsOf: modelURL, configuration: config)
                self.visionModel = try VNCoreMLModel(for: model)
                
                // 3. 创建 Vision 请求
                if let visionModel = self.visionModel {
                    let request = VNCoreMLRequest(model: visionModel)
                    // 使用 scaleFit 以保持纵横比，避免宽屏图片被压缩变形导致识别失败
                    // YOLO 模型通常使用方形输入 (如 640x640)，scaleFit 会在周围填充黑边 (letterbox)
                    request.imageCropAndScaleOption = .scaleFit 
                    self.detectionRequest = request
                }
                
                print("✅ ObjectDetectionService initialized successfully.")
                
            } catch {
                print("❌ Failed to load Core ML model: \(error)")
            }
        }
    }
    
    // MARK: - Public API
    
    /// 执行物品检测 (Buffer)
    func detect(on pixelBuffer: CVPixelBuffer, searchKeyword: String) async throws -> [RecognitionResult] {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        return try await detect(with: handler, searchKeyword: searchKeyword)
    }
    
    /// 执行物品检测 (CGImage)
    func detect(on image: CGImage, orientation: CGImagePropertyOrientation = .up, searchKeyword: String) async throws -> [RecognitionResult] {
        let handler = VNImageRequestHandler(cgImage: image, orientation: orientation)
        return try await detect(with: handler, searchKeyword: searchKeyword)
    }
    
    private func detect(with handler: VNImageRequestHandler, searchKeyword: String) async throws -> [RecognitionResult] {
        guard let request = detectionRequest else {
            // 尝试重新加载
            setupModel()
            return []
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([request])
                
                guard let observations = request.results as? [VNRecognizedObjectObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                // 转换为统一的结果格式
                let results = observations.compactMap { observation -> RecognitionResult? in
                    // 1. 过滤置信度 (从 SettingsManager 获取动态阈值)
                    let currentThreshold = Float(SettingsManager.shared.confidenceThreshold)
                    guard observation.confidence >= currentThreshold else { return nil }
                    
                    // 2. 获取最佳标签
                    guard let topLabel = observation.labels.first else { return nil }
                    
                    // 3. 关键词匹配 (如果用户输入了关键词)
                    if !searchKeyword.isEmpty {
                        let normalizedKeyword = searchKeyword.lowercased()
                        let label = topLabel.identifier.lowercased()
                        
                        // A. 直接匹配
                        var isMatch = label.contains(normalizedKeyword) || normalizedKeyword.contains(label)
                        
                        // B. 查表匹配 (如果 A 不中)
                        if !isMatch {
                            // 使用新的 ObjectTranslation 结构体
                            if let englishKeyword = ObjectTranslation.getEnglishName(for: searchKeyword)?.lowercased() {
                                isMatch = label.contains(englishKeyword)
                            }
                        }
                        
                        if isMatch {
                            return RecognitionResult(
                                text: topLabel.identifier, // 这里依然返回原始英文标签，或者可以映射回中文
                                boundingBox: observation.boundingBox,
                                confidence: topLabel.confidence,
                                type: .object
                            )
                        }
                    }
                    
                    return nil
                }
                
                continuation.resume(returning: results)
                
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
