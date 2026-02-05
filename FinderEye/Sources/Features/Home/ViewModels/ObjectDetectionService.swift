import Vision
import CoreML
import UIKit
import ImageIO
import Combine
import CoreImage
import CoreImage.CIFilterBuiltins

/// 负责加载 YOLO-World Core ML 模型并进行推理
final class ObjectDetectionService {
    
    // MARK: - Properties
    
    private var visionModel: VNCoreMLModel?
    private var detectionRequest: VNCoreMLRequest?
    private var cancellables = Set<AnyCancellable>()
    private var modelInputSize: CGSize = CGSize(width: 640, height: 640) // Default, will be updated from model
    
    // 用于过滤结果的置信度阈值
    // private let confidenceThreshold: Float = 0.3 // 已废弃，改用 SettingsManager

    
    // 模型文件名称 (Dynamic)
    // private let modelName = "ObjectDetector"
    
    // NMS IOU 阈值
    private let iouThreshold: Float = 0.45
    
    // 边缘过滤阈值 (0.0 - 1.0)
    // 如果物体中心点距离边缘小于此值，则视为边缘误检
    private let edgeMargin: CGFloat = 0.02
    
    // MARK: - Slicing Logic (Stateful)
    
    // 用于分时检测的 ROI 索引
    private var currentSliceIndex = 0
    
    // 定义切片 ROIs (Full + 5 Slices)
    private let timeSlicedROIs: [CGRect] = [
        CGRect(x: 0, y: 0, width: 1, height: 1),         // Full (整体)
        CGRect(x: 0, y: 0.4, width: 0.6, height: 0.6),   // Top-Left
        CGRect(x: 0.4, y: 0.4, width: 0.6, height: 0.6), // Top-Right
        CGRect(x: 0, y: 0, width: 0.6, height: 0.6),     // Bottom-Left
        CGRect(x: 0.4, y: 0, width: 0.6, height: 0.6),   // Bottom-Right
        CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)  // Center
    ]
    
    /// 执行分时高精度检测
    /// 每次调用只处理一个 ROI (全图或某个切片)，通过轮询实现全覆盖
    /// 返回元组：(本次检测结果, 本次检测的 ROI 索引)
    func detectTimeSliced(on pixelBuffer: CVPixelBuffer, searchKeyword: String, orientation: CGImagePropertyOrientation = .up) async throws -> (results: [RecognitionResult], sliceIndex: Int) {
        
        // 1. Determine ROI Index
        var targetIndex = 0
        currentSliceIndex = (currentSliceIndex + 1) % timeSlicedROIs.count
        targetIndex = currentSliceIndex
        let roiNorm = timeSlicedROIs[targetIndex]
        
        // 2. Prepare Image (Crop + Letterbox)
        // We do this manually to ensure aspect ratio is preserved via letterboxing
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(orientation)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        return try await Task.detached(priority: .userInitiated) {
            // A. Crop
            // CIImage uses Bottom-Left origin.
            // ROI is defined in Vision coordinates (Bottom-Left origin).
            let roiY_CI = roiNorm.origin.y * CGFloat(height)
            
            let roiRect = CGRect(
                x: roiNorm.origin.x * CGFloat(width),
                y: roiY_CI,
                width: roiNorm.width * CGFloat(width),
                height: roiNorm.height * CGFloat(height)
            )
            let cropped = ciImage.cropped(to: roiRect)
            if cropped.extent.isEmpty { return ([], targetIndex) }
            
            // B. Detect
            do {
                let partResults = try await self.detectWithLetterbox(image: cropped, searchKeyword: searchKeyword, filterArtifacts: true)
                
                // C. Map
                var finalResults: [RecognitionResult] = []
                if targetIndex == 0 {
                    finalResults = partResults
                } else {
                    finalResults = partResults.map { res in
                        let box = res.boundingBox
                        let globalRect = CGRect(
                            x: roiNorm.origin.x + box.origin.x * roiNorm.width,
                            y: roiNorm.origin.y + box.origin.y * roiNorm.height,
                            width: box.width * roiNorm.width,
                            height: box.height * roiNorm.height
                        )
                        return RecognitionResult(
                            text: res.text,
                            boundingBox: globalRect,
                            confidence: res.confidence,
                            type: res.type
                        )
                    }
                }
                
                let filtered = ObjectDetectionService.filterRealTimeArtifacts(finalResults)
                return (filtered, targetIndex)
                
            } catch {
                print("Time Sliced Detection Error: \(error)")
                return ([], targetIndex)
            }
        }.value
    }
    
    // MARK: - Initialization
    
    init() {
        setupModel()
        
        // 监听模型设置变化
        SettingsManager.shared.$modelType
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.setupModel()
            }
            .store(in: &cancellables)
    }
    
    private func setupModel() {
        // Use detached task to avoid blocking the Main Thread during model loading
        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                // 1. 寻找模型文件路径
                // Access SettingsManager on MainActor safely if needed, or assume it's thread-safe (it is @Published but access might need care)
                // SettingsManager.shared is a class. Accessing .modelType might be on MainActor if it's an ObservableObject?
                // Actually SettingsManager.shared is likely a singleton.
                // Let's grab the model name before detaching or safely inside.
                
                let modelName = await MainActor.run { SettingsManager.shared.modelType.fileName }
                
                print("🔄 Loading model: \(modelName)...")
                
                // 注意：在实际 App Bundle 中，编译后的模型通常是 .mlmodelc 文件夹
                // 这里我们假设 .mlpackage 已经被 Xcode 编译并打包进 Bundle
                guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
                    print("❌ Error: Could not find \(modelName).mlmodelc in bundle.")
                    return
                }
                
                // 2. 加载 Core ML 模型 (Heavy operation)
                let config = MLModelConfiguration()
                config.computeUnits = .all // 优先使用 NPU (ANE)
                
                let model = try MLModel(contentsOf: modelURL, configuration: config)
                let visionModel = try VNCoreMLModel(for: model)
                
                // 3. Update state on MainActor or safely
                guard let self = self else { return }
                self.visionModel = visionModel
                
                // 获取模型输入尺寸
                if let inputDesc = model.modelDescription.inputDescriptionsByName.first?.value,
                   let constraint = inputDesc.imageConstraint {
                    self.modelInputSize = CGSize(width: CGFloat(constraint.pixelsWide), height: CGFloat(constraint.pixelsHigh))
                    print("✅ Model input size detected: \(self.modelInputSize)")
                }
                
                // 4. 创建 Vision 请求
                let request = VNCoreMLRequest(model: visionModel)
                // 关键修改：使用 scaleFill 配合手动 Letterbox
                // 我们将手动把图片填充为正方形 (带灰条)，所以这里告诉 Vision 直接拉伸填充即可 (实际上不会拉伸，因为我们已经处理好了长宽比)
                // 这样可以完全掌控预处理过程，避免 Vision 自动缩放导致的坐标问题或挤压问题
                request.imageCropAndScaleOption = .scaleFill
                self.detectionRequest = request
                
                print("✅ ObjectDetectionService initialized successfully with \(modelName).")
                
            } catch {
                print("❌ Failed to load Core ML model: \(error)")
            }
        }
    }
    
    // MARK: - Public API
    
    /// 执行物品检测 (Buffer)
    func detect(on pixelBuffer: CVPixelBuffer, searchKeyword: String) async throws -> [RecognitionResult] {
        // 1. Convert to CIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // 2. Perform Letterbox Detection
        return try await detectWithLetterbox(image: ciImage, searchKeyword: searchKeyword, filterArtifacts: true)
    }
    
    /// 执行高精度物品检测 (Buffer 版，使用 ROI 切片)
    /// 适用于实时流，通过 Vision 的 RegionOfInterest 高效分块
    func detectHighAccuracy(on pixelBuffer: CVPixelBuffer, searchKeyword: String, orientation: CGImagePropertyOrientation = .up) async throws -> [RecognitionResult] {
        // 由于我们需要手动 Letterbox，不能简单使用 Vision 的 ROI (因为 Vision ROI 是在原图上切，切完后 Vision 再缩放)
        // 为了保证一致性，我们手动切片 -> Letterbox -> Detect
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(orientation)
        
        // 定义切片 ROIs (归一化)
        let rois = [
            CGRect(x: 0, y: 0, width: 1, height: 1),         // Full
            CGRect(x: 0, y: 0.4, width: 0.6, height: 0.6),   // Top-Left
            CGRect(x: 0.4, y: 0.4, width: 0.6, height: 0.6), // Top-Right
            CGRect(x: 0, y: 0, width: 0.6, height: 0.6),     // Bottom-Left
            CGRect(x: 0.4, y: 0, width: 0.6, height: 0.6),   // Bottom-Right
            CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)  // Center
        ]
        
        return try await Task.detached(priority: .userInitiated) {
            var allResults: [RecognitionResult] = []
            
            for (index, roiNorm) in rois.enumerated() {
                // A. Crop
                // CIImage cropping uses Bottom-Left coordinates
                // ROI is defined in Vision coordinates (Bottom-Left origin)
                // So we can use y directly.
                let roiY_CI = roiNorm.origin.y * CGFloat(height)
                
                let roiRect = CGRect(
                    x: roiNorm.origin.x * CGFloat(width),
                    y: roiY_CI,
                    width: roiNorm.width * CGFloat(width),
                    height: roiNorm.height * CGFloat(height)
                )
                
                let cropped = ciImage.cropped(to: roiRect)
                // 如果 crop 区域为空或无效，跳过
                if cropped.extent.isEmpty { continue }
                
                // B. Detect
                let partResults = try await self.detectWithLetterbox(image: cropped, searchKeyword: searchKeyword, filterArtifacts: true)
                
                // C. Map back to global
                if index == 0 {
                    allResults.append(contentsOf: partResults)
                } else {
                    // partResults are relative to the crop (roiNorm)
                    // Global = ROI.origin + Local * ROI.size
                    let mapped = partResults.map { res -> RecognitionResult in
                        let box = res.boundingBox
                        let globalRect = CGRect(
                            x: roiNorm.origin.x + box.origin.x * roiNorm.width,
                            y: roiNorm.origin.y + box.origin.y * roiNorm.height,
                            width: box.width * roiNorm.width,
                            height: box.height * roiNorm.height
                        )
                        return RecognitionResult(
                            text: res.text,
                            boundingBox: globalRect,
                            confidence: res.confidence,
                            type: res.type
                        )
                    }
                    allResults.append(contentsOf: mapped)
                }
            }
            
            // Filter & Merge
            let filtered = ObjectDetectionService.filterRealTimeArtifacts(allResults)
            let merged = ObjectDetectionService.mergeFragmentedDetections(filtered)
            return ObjectDetectionService.applyNMS(merged, iouThreshold: 0.45)
        }.value
    }
    
    /// 执行物品检测 (CGImage)
    func detect(on image: CGImage, orientation: CGImagePropertyOrientation = .up, searchKeyword: String) async throws -> [RecognitionResult] {
        let ciImage = CIImage(cgImage: image).oriented(orientation)
        return try await detectWithLetterbox(image: ciImage, searchKeyword: searchKeyword, filterArtifacts: false)
    }
    
    /// 执行高精度物品检测 (适用于静态大图，使用切片策略)
    /// 将图片切分为 2x2 的网格分别检测，并与全图检测结果合并
    func detectHighAccuracy(on image: CGImage, orientation: CGImagePropertyOrientation = .up, searchKeyword: String) async throws -> [RecognitionResult] {
        // 0. 预处理：标准化图片方向为 .up
        // 这是为了确保切片逻辑 (基于 Raw Image) 和 Vision 检测逻辑 (基于 Rotated Image) 的坐标系一致
        // 如果 Orientation 不是 .up，Raw Image 的左上角可能并不是显示图片的左上角，会导致坐标映射错乱
        var targetImage = image
        if orientation != .up {
            let uiOrientation: UIImage.Orientation
            switch orientation {
            case .up: uiOrientation = .up
            case .upMirrored: uiOrientation = .upMirrored
            case .down: uiOrientation = .down
            case .downMirrored: uiOrientation = .downMirrored
            case .left: uiOrientation = .left
            case .leftMirrored: uiOrientation = .leftMirrored
            case .right: uiOrientation = .right
            case .rightMirrored: uiOrientation = .rightMirrored
            default: uiOrientation = .up
            }
            
            let uiImage = UIImage(cgImage: image, scale: 1.0, orientation: uiOrientation)
            if let fixed = uiImage.fixedOrientation()?.cgImage {
                targetImage = fixed
            }
        }
        
        // 1. 全图检测 (捕捉大物体和整体上下文)
        // 注意：这里 orientation 传 .up，因为 targetImage 已经被转正了
        let fullResults = try await detect(on: targetImage, orientation: .up, searchKeyword: searchKeyword)
        
        // 如果图片太小，切片没有意义，直接返回
        let width = targetImage.width
        let height = targetImage.height
        if width < 1000 || height < 1000 {
            return fullResults
        }
        
        // 2. 切片检测 (2x2) + 中心重叠块
        var slicedResults: [RecognitionResult] = []
        let rows = 2
        let cols = 2
        
        // 增加 20% 的重叠率，防止物体正好在切割线上被切断导致无法识别
        let overlapRatio: CGFloat = 0.2
        let tileWidth = CGFloat(width) / CGFloat(cols)
        let tileHeight = CGFloat(height) / CGFloat(rows)
        
        // 实际切片大小 (包含重叠部分)
        let effectiveTileWidth = tileWidth * (1 + overlapRatio)
        let effectiveTileHeight = tileHeight * (1 + overlapRatio)
        
        // 使用 TaskGroup 并行处理切片
        let tilesResults = await withTaskGroup(of: [RecognitionResult].self) { group -> [RecognitionResult] in
            // A. 2x2 网格 (带重叠)
            for row in 0..<rows {
                for col in 0..<cols {
                    // 计算起始坐标
                    // 逻辑：每个块向右/下延伸重叠，除了最后一行/列
                    // 但为了覆盖中间的缝隙，简单的做法是让每个块都比标准大 20%，并保持中心点或者 TopLeft 适当偏移
                    // 采用最稳健的策略：基于标准网格中心点向外扩张
                    
                    // 标准网格起始点
                    let originX = CGFloat(col) * tileWidth
                    let originY = CGFloat(row) * tileHeight
                    
                    // 调整起始点以实现居中扩张 (Centered Expansion)
                    // newX = centerX - newWidth / 2
                    // centerX = originX + tileWidth / 2
                    // newX = originX + tileWidth / 2 - tileWidth * (1 + overlap) / 2
                    //      = originX - tileWidth * overlap / 2
                    
                    let centerX = originX + tileWidth / 2
                    let centerY = originY + tileHeight / 2
                    
                    var x = centerX - effectiveTileWidth / 2
                    var y = centerY - effectiveTileHeight / 2
                    
                    // 边界修正：不能超出图像范围 too much (Vision handle crop ok?)
                    // CGImage cropping handles out of bounds by returning null or empty usually? 
                    // No, we must ensure rect is within bounds.
                    // But if we clamp, we lose the overlap at the edges? 
                    // Actually, at the edges (0 and width), we don't need overlap OUTSIDE.
                    // We only need overlap INSIDE.
                    
                    // 修正策略：
                    // Col 0: x = 0, width = tileWidth + overlapAmount
                    // Col 1: x = width - (tileWidth + overlapAmount), width = ...
                    
                    // 对于 2x2 这种简单情况，直接硬编码最安全
                    if col == 0 { x = 0 }
                    else { x = CGFloat(width) - effectiveTileWidth }
                    
                    if row == 0 { y = 0 }
                    else { y = CGFloat(height) - effectiveTileHeight }
                    
                    // 确保 rect 合法 (防止 effective > full)
                    let w = min(effectiveTileWidth, CGFloat(width))
                    let h = min(effectiveTileHeight, CGFloat(height))
                    x = max(0, min(x, CGFloat(width) - w))
                    y = max(0, min(y, CGFloat(height) - h))
                    
                    let rect = CGRect(x: x, y: y, width: w, height: h)
                    self.addTask(to: &group, rect: rect, image: targetImage, orientation: .up, searchKeyword: searchKeyword, fullSize: CGSize(width: width, height: height))
                }
            }
            
            // B. 中心重叠块 (解决十字盲区) - 依然保留，作为双重保险
            let centerRect = CGRect(x: CGFloat(width) / 4, y: CGFloat(height) / 4, width: CGFloat(width) / 2, height: CGFloat(height) / 2)
            self.addTask(to: &group, rect: centerRect, image: targetImage, orientation: .up, searchKeyword: searchKeyword, fullSize: CGSize(width: width, height: height))
            
            var all = [RecognitionResult]()
            for await res in group {
                all.append(contentsOf: res)
            }
            return all
        }
        
        slicedResults.append(contentsOf: tilesResults)
        
        // 3. 合并全图结果和切片结果，并运行 NMS 去重
        let combinedResults = fullResults + slicedResults
        
        // 3.5 碎片合并 (新增：解决分块导致的物体切断问题)
        // 注意：静态检测通常不需要 filterRealTimeArtifacts，但需要碎片合并
        let mergedResults = ObjectDetectionService.mergeFragmentedDetections(combinedResults)
        
        return ObjectDetectionService.applyNMS(mergedResults, iouThreshold: 0.45)
    }
    
    private func addTask(to group: inout TaskGroup<[RecognitionResult]>, rect: CGRect, image: CGImage, orientation: CGImagePropertyOrientation, searchKeyword: String, fullSize: CGSize) {
        guard let cropped = image.cropping(to: rect) else { return }
        
        group.addTask {
            do {
                // 切片检测也必须关闭伪影过滤，否则切片边缘物体会被误删
                let results = try await self.detect(on: cropped, orientation: orientation, searchKeyword: searchKeyword)
                
                // 坐标映射
                let offsetX = rect.minX
                let offsetY = rect.minY // CGImage Y starts from top usually, but let's check mapping
                
                // Wait, in previous logic I used scale ratios. Here let's use absolute logic then normalize.
                // Or better, keep using relative logic if possible, but rect is absolute here.
                
                // Vision returns normalized [0,1] relative to the *cropped* image.
                // We need to convert to [0,1] relative to *full* image.
                
                // Note: Vision coordinates (Y up) vs CGImage (Y down usually, but depends on context).
                // However, detect() returns normalized coordinates (0-1).
                // So we just need to scale and translate the normalized box.
                
                // Let's assume standard normalized Vision coordinates (0,0 is bottom-left).
                // If we cropped the Top-Left of the image (CGImage coordinates):
                // That corresponds to Top-Left in Vision too if orientation is handled.
                // Actually Vision handles orientation.
                
                // Let's rely on the relative position of the crop rect in the full image.
                // Crop Rect (CGImage) -> Normalized Rect in Full Image
                // Note: CGImage origin is Top-Left. Vision origin is Bottom-Left.
                // This coordinate flip is tricky.
                
                // Let's simplify:
                // If we crop a rect from CGImage, Vision sees that crop as a full image [0,0,1,1].
                // We need to map that back to the full image's normalized space.
                
                // Calculate crop's normalized frame in full image
                let normX = rect.minX / fullSize.width
                let normW = rect.width / fullSize.width
                // For Y: CGImage (0 at top) vs Vision (0 at bottom)
                // If we crop top-left (y=0 in CGImage), that is y=1 in Vision space?
                // Actually, let's look at how `detect` handles it.
                // `detect` passes `orientation`.
                // If we pass the same orientation for the crop, Vision handles it.
                // The issue is mapping the result box back.
                
                // Safe bet: Assume Vision works in "Image Space" regardless of orientation tag?
                // No, orientation tag rotates the image before processing.
                
                // Let's look at the previous implementation's logic:
                // "Vision Y 轴是从底部开始的... row 0 (CGImage Top) 对应 Vision 的高位 Y"
                // This suggests we need to flip Y if we use CGImage crop logic.
                
                let normY_CG = rect.minY / fullSize.height
                let normH = rect.height / fullSize.height
                
                // Convert CGImage crop rect (Top-Left origin) to Vision crop rect (Bottom-Left origin)
                // Vision Y = 1 - CGImage Y - Height
                let normY_Vision = 1.0 - normY_CG - normH
                
                return results.map { res in
                    let box = res.boundingBox
                    let newRect = CGRect(
                        x: normX + box.origin.x * normW,
                        y: normY_Vision + box.origin.y * normH,
                        width: box.width * normW,
                        height: box.height * normH
                    )
                    
                    return RecognitionResult(
                        text: res.text,
                        boundingBox: newRect,
                        confidence: res.confidence,
                        type: res.type
                    )
                }
            } catch {
                return []
            }
        }
    }
    
    // Removed legacy detect(with handler...) method
    // MARK: - Letterbox Helper
    
    private struct LetterboxInfo {
        let image: CIImage
        let scale: CGFloat
        let offset: CGPoint
        let originalSize: CGSize
        let newSize: CGSize
    }
    
    /// 将图片进行 Letterbox 处理 (保持长宽比缩放到目标正方形尺寸，并填充灰色背景)
    /// 解决 16:9 图片被强行压缩到 1:1 模型输入导致的形变问题
    private func letterbox(image: CIImage, targetSize: CGSize) -> LetterboxInfo {
        let originalSize = image.extent.size
        // 计算缩放比例 (Fit)
        let scale = min(targetSize.width / originalSize.width, targetSize.height / originalSize.height)
        
        let newWidth = originalSize.width * scale
        let newHeight = originalSize.height * scale
        
        // 居中偏移
        let offsetX = (targetSize.width - newWidth) / 2.0
        let offsetY = (targetSize.height - newHeight) / 2.0
        
        // 1. 缩放 + 平移
        // 注意：CIImage 变换原点
        let scaledImage = image
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
        
        // 2. 背景 (YOLO 常用灰色 114/255)
        let background = CIImage(color: CIColor(red: 114/255, green: 114/255, blue: 114/255))
            .cropped(to: CGRect(origin: .zero, size: targetSize))
        
        // 3. 合成 (SourceOver)
        let resultImage = scaledImage.composited(over: background)
        
        return LetterboxInfo(
            image: resultImage,
            scale: scale,
            offset: CGPoint(x: offsetX, y: offsetY),
            originalSize: originalSize,
            newSize: CGSize(width: newWidth, height: newHeight)
        )
    }
    
    /// 核心检测逻辑 (使用 Letterbox)
    private func detectWithLetterbox(image: CIImage, searchKeyword: String, filterArtifacts: Bool) async throws -> [RecognitionResult] {
        guard let request = detectionRequest else {
            setupModel()
            return []
        }
        
        let targetSize = self.modelInputSize
        let info = letterbox(image: image, targetSize: targetSize)
        
        let handler = VNImageRequestHandler(ciImage: info.image, orientation: .up) // Image already oriented
        
        let currentThreshold = await MainActor.run { Float(SettingsManager.shared.confidenceThreshold) }
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results as? [VNRecognizedObjectObservation] else {
                return []
            }
            
            // Map observations back to original image space
            let results = observations.compactMap { observation -> RecognitionResult? in
                guard let topLabel = observation.labels.first else { return nil }
                if topLabel.confidence < currentThreshold { return nil }
                
                // 关键词匹配
                var isMatch = true
                if !searchKeyword.isEmpty {
                    let normalizedKeyword = searchKeyword.lowercased()
                    let label = topLabel.identifier.lowercased()
                    isMatch = label.contains(normalizedKeyword) || normalizedKeyword.contains(label)
                    if !isMatch {
                        if let english = ObjectTranslation.getEnglishName(for: searchKeyword)?.lowercased() {
                            isMatch = label.contains(english) || english.contains(label)
                        }
                    }
                }
                
                if isMatch {
                    // Coordinate Mapping
                    // Vision Box (0-1 in Target Square) -> Pixel in Target
                    let box = observation.boundingBox
                    
                    // Vision origin is Bottom-Left
                    // CIImage origin is Bottom-Left
                    // Perfect match.
                    
                    let x_pixel_target = box.origin.x * targetSize.width
                    let y_pixel_target = box.origin.y * targetSize.height
                    let w_pixel_target = box.width * targetSize.width
                    let h_pixel_target = box.height * targetSize.height
                    
                    // Remove Padding
                    let x_pixel_new = x_pixel_target - info.offset.x
                    let y_pixel_new = y_pixel_target - info.offset.y
                    
                    // Un-scale
                    let x_pixel_orig = x_pixel_new / info.scale
                    let y_pixel_orig = y_pixel_new / info.scale
                    let w_pixel_orig = w_pixel_target / info.scale
                    let h_pixel_orig = h_pixel_target / info.scale
                    
                    // Normalize to Original Size
                    let normRect = CGRect(
                        x: x_pixel_orig / info.originalSize.width,
                        y: y_pixel_orig / info.originalSize.height,
                        width: w_pixel_orig / info.originalSize.width,
                        height: h_pixel_orig / info.originalSize.height
                    )
                    
                    return RecognitionResult(
                        text: topLabel.identifier,
                        boundingBox: normRect,
                        confidence: topLabel.confidence,
                        type: .object
                    )
                }
                return nil
            }
            
            var finalResults = results
            if filterArtifacts {
                finalResults = ObjectDetectionService.filterRealTimeArtifacts(results)
            }
            
            return ObjectDetectionService.applyNMS(finalResults, iouThreshold: 0.45)
            
        } catch {
            throw error
        }
    }

    // MARK: - Private Helpers
    
    /// 尝试合并相邻的碎片检测结果 (在 NMS 之前调用)
    /// 解决分块检测导致的物体被切断问题 (不重叠但空间相邻)
    private static func mergeFragmentedDetections(_ results: [RecognitionResult]) -> [RecognitionResult] {
        if results.isEmpty { return [] }
        
        // 关键修改：不再按标签严格分组，允许不同标签但空间重叠的物体合并 (例如 "mouse" 和 "black mouse")
        // 前提是这些结果都已经通过了关键词过滤，说明它们都与用户搜索相关
        
        var sortedItems = results.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
        var mergedGroups: [[RecognitionResult]] = []
        
        while !sortedItems.isEmpty {
            var currentGroup = [sortedItems.removeFirst()]
            var changed = true
            
            while changed {
                changed = false
                var nextRoundItems: [RecognitionResult] = []
                
                for item in sortedItems {
                    // 检查 item 是否与 currentGroup 中的任意一个足够"接近"
                    if isCloseEnough(item, to: currentGroup) {
                        currentGroup.append(item)
                        changed = true
                    } else {
                        nextRoundItems.append(item)
                    }
                }
                sortedItems = nextRoundItems
            }
            mergedGroups.append(currentGroup)
        }
        
        var finalResults: [RecognitionResult] = []
        
        // 将每组合并成一个大框
        for group in mergedGroups {
            if group.count == 1 {
                finalResults.append(group[0])
            } else {
                // 合并 BoundingBox
                let minX = group.map { $0.boundingBox.minX }.min() ?? 0
                let minY = group.map { $0.boundingBox.minY }.min() ?? 0
                let maxX = group.map { $0.boundingBox.maxX }.max() ?? 0
                let maxY = group.map { $0.boundingBox.maxY }.max() ?? 0
                
                let mergedRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                
                // 取最高置信度的结果作为代表
                // 优先选择标签更详细的? 或者置信度最高的?
                // 通常置信度高意味着匹配更好
                if let bestItem = group.max(by: { $0.confidence < $1.confidence }) {
                    finalResults.append(RecognitionResult(
                        text: bestItem.text,
                        boundingBox: mergedRect,
                        confidence: bestItem.confidence,
                        type: bestItem.type
                    ))
                }
            }
        }
        
        return finalResults
    }
    
    /// 判断一个物体是否与一组物体中的任意一个足够接近
    private static func isCloseEnough(_ item: RecognitionResult, to group: [RecognitionResult]) -> Bool {
        let box = item.boundingBox
        // 阈值：框宽度的 20% 或 高度的 20% (视作相邻)
        // 或者固定距离，但在归一化坐标下不好定。使用相对尺寸较好。
        
        for groupItem in group {
            let gBox = groupItem.boundingBox
            
            // 1. 检查是否有重叠 (Intersection)
            if box.intersects(gBox) { return true }
            
            // 2. 检查距离 (Distance)
            // 计算两个矩形的最近距离
            let xDist = max(0, max(box.minX - gBox.maxX, gBox.minX - box.maxX))
            let yDist = max(0, max(box.minY - gBox.maxY, gBox.minY - box.maxY))
            
            // 允许的间隙：取两个框中较小尺寸的 10%
            let toleranceX = min(box.width, gBox.width) * 0.1
            let toleranceY = min(box.height, gBox.height) * 0.1
            
            // 如果在 X 或 Y 方向上非常接近，且另一个方向上有显著投影重叠
            // (例如：左右相邻，且高度上有重叠)
            
            // 水平相邻 check
            let yOverlap = max(0, min(box.maxY, gBox.maxY) - max(box.minY, gBox.minY))
            let hasVerticalOverlap = yOverlap > min(box.height, gBox.height) * 0.5
            if xDist < toleranceX && hasVerticalOverlap { return true }
            
            // 垂直相邻 check
            let xOverlap = max(0, min(box.maxX, gBox.maxX) - max(box.minX, gBox.minX))
            let hasHorizontalOverlap = xOverlap > min(box.width, gBox.width) * 0.5
            if yDist < toleranceY && hasHorizontalOverlap { return true }
        }
        
        return false
    }

    // Removed legacy processObservations method

    /// 过滤实时流中的伪影 (边缘误检 + 过小物体)
    private static func filterRealTimeArtifacts(_ results: [RecognitionResult]) -> [RecognitionResult] {
        let edgeMargin: CGFloat = 0.01 // 边缘保留区 1% (Optimization: Reduced from 2%)
        let minSize: CGFloat = 0.01    // 最小尺寸 1% (Optimization: Reduced from 3% to detect smaller objects)
        
        return results.filter { result in
            let box = result.boundingBox
            let center = CGPoint(x: box.midX, y: box.midY)
            
            // 1. 边缘过滤：检查中心点是否过于靠近边缘
            // 很多时候边缘的“半个物体”会被识别成错误的类别，或者根本不存在
            if center.x < edgeMargin || center.x > (1.0 - edgeMargin) ||
               center.y < edgeMargin || center.y > (1.0 - edgeMargin) {
                return false
            }
            
            // 2. 尺寸过滤：过滤极小的闪烁噪点
            // 在实时流中，太小的物体通常不稳定
            if box.width < minSize || box.height < minSize {
                return false
            }
            
            return true
        }
    }
    
    /// 非极大值抑制 (NMS)
    private static func applyNMS(_ results: [RecognitionResult], iouThreshold: Float) -> [RecognitionResult] {
        // 0. 包含关系过滤 (Containment Filtering)
        // 解决分块检测导致的"大框包小框"问题 (例如: 全图检测出一个完整键盘，切片检测出半个键盘)
        // 如果两个框类别相同，且一个框包含了另一个框的大部分区域，则保留置信度高的那个(通常是大框，或者置信度更高的小框)
        // 但为了简单有效，我们假设大框是更好的结果(因为它完整)，或者置信度高的更好。
        // 这里我们采用"基于置信度排序后的 IOU 抑制"，但加上"包含抑制"。
        
        // 1. 按置信度降序排序
        let sortedResults = results.sorted { $0.confidence > $1.confidence }
        var selectedResults: [RecognitionResult] = []
        var activeResults = sortedResults
        
        // 调整 IOU 阈值：对于分块合并，稍微激进一点 (0.35)
        // 原始 0.45 可能导致重叠较多的两个部分被保留
        let effectiveIOU = min(iouThreshold, 0.35)
        
        while !activeResults.isEmpty {
            // 取出当前最高置信度的框
            let best = activeResults.removeFirst()
            selectedResults.append(best)
            
            // 过滤掉与 best 冲突的框
            activeResults = activeResults.filter { other in
                // A. 计算 IOU
                let iou = calculateIOU(best.boundingBox, other.boundingBox)
                if iou >= CGFloat(effectiveIOU) {
                    return false // IOU 过大，抑制
                }
                
                // B. 计算包含关系 (Intersection over Smaller Area)
                let intersection = best.boundingBox.intersection(other.boundingBox)
                if !intersection.isNull {
                    let intersectionArea = intersection.width * intersection.height
                    let otherArea = other.boundingBox.width * other.boundingBox.height
                    let bestArea = best.boundingBox.width * best.boundingBox.height
                    
                    // 1. 小框抑制 (抑制被大框包含的小框)
                    // 如果 other (较小置信度) 被 best 包含 (>60%)，且 best 面积比 other 大 -> 抑制 other
                    // 逻辑：如果有一个高置信度的大框，里面的小框大概率是分块产生的碎片
                    if intersectionArea / otherArea > 0.6 && bestArea > otherArea {
                         return false
                    }
                    
                    // 2. 大框抑制 (抑制包含了小框但置信度较低的大框 - 慎用，除非重叠度极高)
                    // 如果 best 被 other 包含 (>80%)，说明 best 是局部的精细检测，other 是整体但置信度低
                    // 这种情况下，我们通常希望保留 best (因为置信度高)，抑制 other (大而无当)
                    // 这里的逻辑已经通过 removeFirst 实现了 (保留 best)，所以只需要决定是否抑制 other
                    // 如果 other 包含了 best，且重叠区域占 best 的 80% 以上...
                    // 这种情况下 IOU 可能不大 (因为 other 很大)，但我们不应该抑制 other 吗？
                    // 如果 best 是键盘的一部分，other 是整个键盘...
                    // 用户抱怨"识别成多个"，意味着大框和小框并存。
                    // 我们应该只保留一个。
                    // 策略：只要有显著重叠 (>60% of minArea)，就只保留置信度最高的那个。
                    let minArea = min(otherArea, bestArea)
                    if intersectionArea / minArea > 0.6 {
                         return false
                    }
                }
                
                return true
            }
        }
        
        return selectedResults
    }
    
    /// 计算两个矩形的交并比 (IOU)
    private static func calculateIOU(_ rect1: CGRect, _ rect2: CGRect) -> CGFloat {
        let intersection = rect1.intersection(rect2)
        if intersection.isNull { return 0 }
        
        let intersectionArea = intersection.width * intersection.height
        let unionArea = rect1.width * rect1.height + rect2.width * rect2.height - intersectionArea
        
        if unionArea <= 0 { return 0 }
        return intersectionArea / unionArea
    }
}
