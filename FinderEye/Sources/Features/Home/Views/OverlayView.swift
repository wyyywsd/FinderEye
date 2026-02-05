import SwiftUI
import AVFoundation

struct OverlayView: View {
    let results: [RecognitionResult]
    let bufferSize: CGSize
    var contentMode: ContentMode = .fill // 默认为 fill
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(results) { result in
                    let rect = GeometryUtils.convertVisionRect(
                        result.boundingBox,
                        bufferSize: bufferSize,
                        viewSize: geometry.size,
                        videoGravity: contentMode == .fill ? .resizeAspectFill : .resizeAspect
                    )
                    
                    // 根据类型选择颜色
                    let color = result.type == .text ? Color.green : Color.blue
                    
                    ZStack(alignment: .topLeading) {
                        // 1. 高亮框 (更精致的 UI)
                        // 使用圆角矩形，加一个外发光效果
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color, lineWidth: 2)
                            .background(color.opacity(0.2).cornerRadius(6)) // 半透明填充
                            .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)
                        
                        // 2. 识别文字标签 (可选，如果文字太小可能看不清，可以仅显示框)
                        // 仅当框的高度足够时才显示标签
                        if rect.height > 15 {
                            Text("\(result.text) \(Int(result.confidence * 100))%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(color)
                                .cornerRadius(4)
                                .offset(y: -18) // 放在框的上方
                                .frame(width: rect.width, alignment: .center) // 居中
                        }
                    }
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rect)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// Helper for specific corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
