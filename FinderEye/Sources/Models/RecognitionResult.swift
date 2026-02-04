import Foundation
import CoreGraphics

enum RecognitionType: String, Equatable {
    case text
    case object
}

struct RecognitionResult: Identifiable, Equatable {
    let id = UUID()
    let text: String
    /// 归一化坐标 (0.0 - 1.0)，原点在左下角 (Vision 坐标系)
    let boundingBox: CGRect
    let confidence: Float
    let type: RecognitionType
}
