import Foundation
import UIKit
import Combine

@MainActor
class TextExtractionViewModel: ObservableObject {
    @Published var extractedText: String = ""
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var showResult: Bool = false
    
    private let ocrService: OCRService
    
    init(ocrService: OCRService = OCRService()) {
        self.ocrService = ocrService
    }
    
    func extractText(from image: UIImage) {
        self.isProcessing = true
        self.errorMessage = nil
        self.extractedText = ""
        
        Task {
            do {
                // Ensure image is upright
                let fixedImage = fixOrientation(img: image)
                
                let lines = try await ocrService.performFullOCR(on: fixedImage)
                
                if lines.isEmpty {
                    self.errorMessage = "No text found in the image.".localized
                } else {
                    self.extractedText = lines.joined(separator: "\n")
                    self.showResult = true
                }
            } catch {
                self.errorMessage = "Failed to extract text: \(error.localizedDescription)"
            }
            
            self.isProcessing = false
        }
    }
    
    // Helper to fix orientation if needed (though OCRService handles it via property orientation, 
    // sometimes drawing/resizing needs a fixed image)
    private func fixOrientation(img: UIImage) -> UIImage {
        if img.imageOrientation == .up { return img }
        
        UIGraphicsBeginImageContextWithOptions(img.size, false, img.scale)
        img.draw(in: CGRect(origin: .zero, size: img.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? img
    }
}
