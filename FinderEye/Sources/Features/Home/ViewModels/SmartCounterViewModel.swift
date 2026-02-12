import SwiftUI
import Combine
import Vision

final class SmartCounterViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var isScanning = false
    @Published var detectedObjects: [RecognitionResult] = []
    @Published var countSummary: String = ""
    @Published var errorMessage: String?
    
    private let detectionService = ObjectDetectionService()
    
    func processImage(_ uiImage: UIImage) {
        self.image = uiImage
        self.isScanning = true
        self.errorMessage = nil
        self.detectedObjects = []
        self.countSummary = ""
        
        guard let cgImage = uiImage.cgImage else {
            self.errorMessage = "Invalid image"
            self.isScanning = false
            return
        }
        
        Task {
            do {
                // Use detectHighAccuracy for better results on static images
                // searchKeyword = "" means return all detected objects
                // Handle orientation properly
                let orientation = self.cgOrientation(from: uiImage.imageOrientation)
                
                let results = try await detectionService.detectHighAccuracy(
                    on: cgImage,
                    orientation: orientation,
                    searchKeyword: ""
                )
                
                await MainActor.run {
                    self.detectedObjects = results
                    self.generateSummary(results)
                    self.isScanning = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isScanning = false
                }
            }
        }
    }
    
    private func generateSummary(_ results: [RecognitionResult]) {
        if results.isEmpty {
            self.countSummary = "No objects detected.".localized
            return
        }
        
        var counts: [String: Int] = [:]
        
        let isEnglish = SettingsManager.shared.appLanguage == .english
        
        for result in results {
            let name: String
            if isEnglish {
                name = result.text.capitalized
            } else {
                name = ObjectTranslation.getChineseName(for: result.text)
            }
            counts[name, default: 0] += 1
        }
        
        // Format: "3把椅子, 1台电脑" or "3 Chairs, 1 Computer"
        
        let separator = isEnglish ? ", " : "，"
        let summaryParts = counts.map { (name, count) in
            "\(count) \(name)"
        }
        .sorted() // Consistent order
        
        self.countSummary = summaryParts.joined(separator: separator)
    }
    
    private func cgOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
