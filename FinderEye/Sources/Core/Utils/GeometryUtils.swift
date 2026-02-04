import Foundation
import CoreGraphics
import AVFoundation

struct GeometryUtils {
    
    /// 将 Vision 框架的归一化坐标 (左下角为原点) 转换为 SwiftUI 视图坐标 (左上角为原点)
    /// 考虑了 Aspect Fill 的裁剪情况
    static func convertVisionRect(
        _ normalizedRect: CGRect,
        bufferSize: CGSize,
        viewSize: CGSize,
        videoGravity: AVLayerVideoGravity = .resizeAspectFill
    ) -> CGRect {
        
        // 1. 翻转 Y 轴 (Vision 原点在左下，UI 在左上)
        let visionRect = CGRect(
            x: normalizedRect.origin.x,
            y: 1.0 - normalizedRect.origin.y - normalizedRect.height,
            width: normalizedRect.width,
            height: normalizedRect.height
        )
        
        // 2. 计算缩放比例和偏移量
        // 注意：UI 坐标通常是按照 Point 计算的，而 bufferSize 是 Pixel。
        // 在 Retina 屏幕上，viewSize * scale 应该等于 bufferSize (如果 scale 是 contentScaleFactor)
        // 但这里的 viewSize 已经是 Point，我们需要将 Vision 的归一化坐标映射到 viewSize 上。
        
        let viewAspectRatio = viewSize.width / viewSize.height
        let bufferAspectRatio = bufferSize.width / bufferSize.height
        
        var scale: CGFloat = 1.0
        var offsetX: CGFloat = 0.0
        var offsetY: CGFloat = 0.0
        
        if videoGravity == .resizeAspectFill {
            if viewAspectRatio > bufferAspectRatio {
                // 视图更宽（比如 iPhone 竖屏时），图像会被上下裁剪
                // 以视图宽度为基准计算缩放
                scale = viewSize.width / bufferSize.width
                
                let scaledHeight = bufferSize.height * scale
                // 垂直偏移量 = (视图高度 - 缩放后的图像高度) / 2
                offsetY = (viewSize.height - scaledHeight) / 2.0
            } else {
                // 视图更高（比如 iPad 或者横屏），图像会被左右裁剪
                // 以视图高度为基准计算缩放
                scale = viewSize.height / bufferSize.height
                
                let scaledWidth = bufferSize.width * scale
                // 水平偏移量 = (视图宽度 - 缩放后的图像宽度) / 2
                offsetX = (viewSize.width - scaledWidth) / 2.0
            }
        } else {
            // .resizeAspect (Fit)
             scale = min(viewSize.width / bufferSize.width, viewSize.height / bufferSize.height)
             let scaledWidth = bufferSize.width * scale
             let scaledHeight = bufferSize.height * scale
             offsetX = (viewSize.width - scaledWidth) / 2.0
             offsetY = (viewSize.height - scaledHeight) / 2.0
        }
        
        // 3. 应用变换
        // 步骤 A: 将归一化坐标 (0-1) 映射到 原始缓冲区像素坐标
        // 注意：Vision 坐标系 Y 轴向上，而 buffer 和 view 都是 Y 轴向下
        // 正确的步骤是：
        // 1. Vision (Normalized, Y-up) -> Vision (Normalized, Y-down)
        // 2. Vision (Normalized, Y-down) -> Scaled Image Coordinates (in View Points)
        // 3. Apply Offset to center/crop the image within the View
        
        let x = normalizedRect.origin.x
        // 翻转 Y 轴：Vision 原点在左下，UI 在左上
        let y = 1.0 - normalizedRect.origin.y - normalizedRect.height
        let w = normalizedRect.width
        let h = normalizedRect.height
        
        // 映射到 View 的坐标空间
        // rectX = x * bufferW * scale + offsetX
        // 这里的 bufferW * scale 其实就是 "缩放后的图像在 View 坐标系中的宽度"
        
        let finalRect = CGRect(
            x: x * bufferSize.width * scale + offsetX,
            y: y * bufferSize.height * scale + offsetY,
            width: w * bufferSize.width * scale,
            height: h * bufferSize.height * scale
        )
        
        return finalRect
    }
}
