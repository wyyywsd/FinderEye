import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ImageCropperView: View {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    var onCrop: (UIImage) -> Void
    
    // 4 Corner Points for Perspective Correction
    @State private var topLeft: CGPoint = .zero
    @State private var topRight: CGPoint = .zero
    @State private var bottomLeft: CGPoint = .zero
    @State private var bottomRight: CGPoint = .zero
    
    @State private var viewSize: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Toolbar
                    HStack {
                        Button("Cancel".localized) {
                            isPresented = false
                        }
                        .foregroundColor(.white)
                        Spacer()
                        Text("Crop Image".localized)
                            .foregroundColor(.white)
                            .font(.headline)
                        Spacer()
                        Button("Done".localized) {
                            if let cropped = cropImage(containerSize: viewSize) {
                                onCrop(cropped)
                            }
                        }
                        .foregroundColor(.yellow)
                    }
                    .padding()
                    .background(Color.black)
                    
                    Spacer()
                    
                    // Image Area
                    ZStack {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .onAppear {
                                                viewSize = geo.size
                                                resetCropBox(size: geo.size)
                                            }
                                            .onChange(of: geo.size) { newSize in
                                                viewSize = newSize
                                                resetCropBox(size: newSize)
                                            }
                                    }
                                )
                                .overlay(
                                    ZStack {
                                        // Dimmed Background with Cutout
                                        Color.black.opacity(0.5)
                                            .mask(
                                                Rectangle()
                                                    .overlay(
                                                        QuadShape(tl: topLeft, tr: topRight, bl: bottomLeft, br: bottomRight)
                                                            .blendMode(.destinationOut)
                                                    )
                                                    .compositingGroup()
                                            )
                                            .allowsHitTesting(false)
                                        
                                        // Interactive Quad Area (Transparent) - Allows dragging the whole box
                                        QuadShape(tl: topLeft, tr: topRight, bl: bottomLeft, br: bottomRight)
                                            .fill(Color.white.opacity(0.001))
                                            .gesture(
                                                DragGesture()
                                                    .onChanged { value in
                                                        moveAllPoints(delta: value.translation)
                                                    }
                                                    .onEnded { _ in
                                                        lastOffset = .zero
                                                    }
                                            )
                                        
                                        // Border connecting corners
                                        QuadShape(tl: topLeft, tr: topRight, bl: bottomLeft, br: bottomRight)
                                            .stroke(Color.white, lineWidth: 2)
                                            .allowsHitTesting(false)
                                        
                                        // 4 Corner Handles
                                        DragHandle(position: $topLeft, limits: viewSize)
                                        DragHandle(position: $topRight, limits: viewSize)
                                        DragHandle(position: $bottomLeft, limits: viewSize)
                                        DragHandle(position: $bottomRight, limits: viewSize)
                                    }
                                )
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
        }
    }
    
    func resetCropBox(size: CGSize) {
        // Default to 80% of image size, centered
        let paddingW = size.width * 0.1
        let paddingH = size.height * 0.1
        
        topLeft = CGPoint(x: paddingW, y: paddingH)
        topRight = CGPoint(x: size.width - paddingW, y: paddingH)
        bottomLeft = CGPoint(x: paddingW, y: size.height - paddingH)
        bottomRight = CGPoint(x: size.width - paddingW, y: size.height - paddingH)
    }
    
    func moveAllPoints(delta: CGSize) {
        let currentDrag = CGSize(
            width: delta.width - lastOffset.width,
            height: delta.height - lastOffset.height
        )
        lastOffset = delta
        
        // Calculate potential new positions
        let newTL = CGPoint(x: topLeft.x + currentDrag.width, y: topLeft.y + currentDrag.height)
        let newTR = CGPoint(x: topRight.x + currentDrag.width, y: topRight.y + currentDrag.height)
        let newBL = CGPoint(x: bottomLeft.x + currentDrag.width, y: bottomLeft.y + currentDrag.height)
        let newBR = CGPoint(x: bottomRight.x + currentDrag.width, y: bottomRight.y + currentDrag.height)
        
        // Simple bounds check: Stop dragging if any point hits the edge
        let allPoints = [newTL, newTR, newBL, newBR]
        let minX = allPoints.map { $0.x }.min() ?? 0
        let maxX = allPoints.map { $0.x }.max() ?? viewSize.width
        let minY = allPoints.map { $0.y }.min() ?? 0
        let maxY = allPoints.map { $0.y }.max() ?? viewSize.height
        
        if minX >= 0 && maxX <= viewSize.width && minY >= 0 && maxY <= viewSize.height {
            topLeft = newTL
            topRight = newTR
            bottomLeft = newBL
            bottomRight = newBR
        }
    }
    
    func cropImage(containerSize: CGSize) -> UIImage? {
        guard let inputImage = image?.fixedOrientation() else { return nil }
        
        // Coordinate conversion setup
        let imageSize = inputImage.size
        let widthRatio = containerSize.width / imageSize.width
        let heightRatio = containerSize.height / imageSize.height
        let scale = min(widthRatio, heightRatio)
        
        let displayWidth = imageSize.width * scale
        let displayHeight = imageSize.height * scale
        
        let offsetX = (containerSize.width - displayWidth) / 2
        let offsetY = (containerSize.height - displayHeight) / 2
        
        // Helper to convert View Point -> Image Point
        func mapPoint(_ point: CGPoint) -> CGPoint {
            let x = (point.x - offsetX) / scale
            let y = (point.y - offsetY) / scale
            return CGPoint(x: x, y: y)
        }
        
        let pTL = mapPoint(topLeft)
        let pTR = mapPoint(topRight)
        let pBL = mapPoint(bottomLeft)
        let pBR = mapPoint(bottomRight)
        
        // Prepare Core Image
        guard let ciImage = CIImage(image: inputImage) else { return nil }
        
        // Core Image Coordinates: (0,0) is Bottom-Left.
        // We need to flip Y for the vectors relative to the image height.
        // The CIPerspectiveCorrection protocol expects CGPoint, not CIVector.
        func toCIPoint(_ p: CGPoint) -> CGPoint {
            return CGPoint(x: p.x, y: imageSize.height - p.y)
        }
        
        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = ciImage
        filter.topLeft = toCIPoint(pTL)
        filter.topRight = toCIPoint(pTR)
        filter.bottomRight = toCIPoint(pBR)
        filter.bottomLeft = toCIPoint(pBL)
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let context = CIContext()
        // The output extent of perspective correction is automatically calculated by Core Image? 
        // No, perspectiveCorrection usually maps to a rectangle defined by the corners.
        // However, standard use implies we want the "rectified" size.
        // Core Image's default behavior for perspective correction output extent might be the bounding box of input.
        // Let's rely on outputImage.extent
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
}

// Custom Shape for the Quadrilateral Crop Area
struct QuadShape: Shape {
    var tl: CGPoint
    var tr: CGPoint
    var bl: CGPoint
    var br: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: tl)
        path.addLine(to: tr)
        path.addLine(to: br)
        path.addLine(to: bl)
        path.closeSubpath()
        return path
    }
}

// Draggable Handle
struct DragHandle: View {
    @Binding var position: CGPoint
    let limits: CGSize
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 24, height: 24)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newX = min(max(value.location.x, 0), limits.width)
                        let newY = min(max(value.location.y, 0), limits.height)
                        position = CGPoint(x: newX, y: newY)
                    }
            )
    }
}

// Ensure orientation is fixed before processing
extension UIImage {
    func fixedOrientation() -> UIImage? {
        guard imageOrientation != .up else { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage
    }
}
