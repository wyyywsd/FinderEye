import Vision
import CoreImage
import Foundation
import ImageIO
import UIKit

protocol OCRServiceProtocol {
    func performOCR(on buffer: CVPixelBuffer, keyword: String) async throws -> [RecognitionResult]
}

final class OCRService: OCRServiceProtocol {
    
    // MARK: - Properties
    
    private let textRecognitionRequest: VNRecognizeTextRequest
    
    // MARK: - Initialization
    
    init() {
        textRecognitionRequest = VNRecognizeTextRequest()
        configureRequest()
    }
    
    private func configureRequest() {
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.usesLanguageCorrection = true
        // 优先支持中文和英文
        textRecognitionRequest.recognitionLanguages = ["zh-Hans", "en-US"]
    }
    
    // MARK: - Public API
    
    func performOCR(on buffer: CVPixelBuffer, keyword: String) async throws -> [RecognitionResult] {
        let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: [:])
        return try await performOCR(with: handler, keyword: keyword)
    }
    
    func performOCR(on image: CGImage, orientation: CGImagePropertyOrientation = .up, keyword: String) async throws -> [RecognitionResult] {
        let handler = VNImageRequestHandler(cgImage: image, orientation: orientation, options: [:])
        return try await performOCR(with: handler, keyword: keyword)
    }
    
    func performFullOCR(on image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else { return [] }
        
        // Handle orientation
        let orientation = image.cgImagePropertyOrientation
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([textRecognitionRequest])
                guard let observations = textRecognitionRequest.results else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Sort observations by vertical position (top to bottom)
                // If Y coordinates are similar, sort by X (left to right)
                // Note: Vision coordinates have (0,0) at bottom-left. So higher Y is top.
                // But textRecognitionRequest results are usually ordered?
                // Let's rely on default order or sort explicitly if needed.
                // Standard reading order is usually provided by 'candidate' string but observations list might be unordered.
                // Vision usually returns text in reading order.
                
                let results = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: results)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func performOCR(with handler: VNImageRequestHandler, keyword: String) async throws -> [RecognitionResult] {
        guard !keyword.isEmpty else { return [] }
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try handler.perform([textRecognitionRequest])
                guard let observations = textRecognitionRequest.results else {
                    continuation.resume(returning: [])
                    return
                }
                
                // 过滤和匹配逻辑
                let results = observations.compactMap { observation -> RecognitionResult? in
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }
                    
                    let recognizedText = topCandidate.string
                    
                    // 模糊匹配逻辑
                    if self.isFuzzyMatch(text: recognizedText, keyword: keyword) {
                        
                        // 尝试获取关键词的具体包围框
                        // 注意：这里需要找到关键词在 recognizedText 中的 Range
                        var finalBoundingBox = observation.boundingBox
                        let matchMode = SettingsManager.shared.textMatchMode
                        
                        // 只有在选择“具体文字”模式时，才去计算具体位置
                        if matchMode == .specific {
                            if let range = recognizedText.range(of: keyword, options: [.caseInsensitive, .diacriticInsensitive]) {
                                // Vision 提供了 boundingBox(for: Range) 方法
                                if let box = try? topCandidate.boundingBox(for: range) {
                                    finalBoundingBox = box.boundingBox
                                }
                            }
                        }
                        
                        // 根据设置决定返回整行文字还是关键词
                        let displayText = matchMode == .wholeLine ? recognizedText : keyword
                        
                        return RecognitionResult(
                            text: displayText, 
                            boundingBox: finalBoundingBox, // Vision 坐标系 (0,0) 在左下
                            confidence: topCandidate.confidence,
                            type: .text
                        )
                    }
                    return nil
                }
                
                continuation.resume(returning: results)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Private Helpers
    
    /// 简单的模糊匹配判断
    private func isFuzzyMatch(text: String, keyword: String) -> Bool {
        // 1. 直接包含 (忽略大小写)
        if text.localizedStandardContains(keyword) {
            return true
        }
        
        // 2. 如果关键词较长，允许一定的编辑距离容错 (这里简化处理，仅做长度判断和部分包含)
        // 真正的 Levenshtein Distance 在高性能要求下可能需要更优化的实现
        // 这里为了 MVP 保持简单：如果关键词 > 2 个字符，且匹配度较高
        if keyword.count > 2 {
             // 简单的子序列检查或编辑距离可以放这里
             // 暂时仅依赖 localizedStandardContains，后续可扩展
        }
        
        return false
    }
}
