import SwiftUI

struct SmartCounterView: View {
    @StateObject private var viewModel = SmartCounterViewModel()
    @State private var showPhotoPicker = false
    @State private var showCameraPicker = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("Smart Counter".localized)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    // Hidden balance
                    Image(systemName: "xmark.circle.fill").opacity(0)
                        .font(.title)
                }
                .padding()
                
                // Content
                ZStack {
                    if let image = viewModel.image {
                        GeometryReader { geometry in
                            ZStack {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .overlay(
                                        // Pass the image size to calculate aspect ratio correctly if needed
                                        // But scaledToFit makes it tricky to get exact frame.
                                        // Use a helper to draw boxes in the image coordinate space.
                                        DetectionOverlay(imageSize: image.size, viewSize: geometry.size, results: viewModel.detectedObjects)
                                    )
                            }
                        }
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "camera.metering.matrix")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                            Text("Take a photo or choose from album to count objects".localized)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                    
                    if viewModel.isScanning {
                        Color.black.opacity(0.4)
                        ProgressView("Analyzing...".localized)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemGray6))
                
                // Bottom Area
                VStack(spacing: 16) {
                    // Results
                    if !viewModel.countSummary.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Statistics:".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(viewModel.countSummary)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                    }
                    
                    // Controls
                    HStack(spacing: 40) {
                        Button(action: {
                            showPhotoPicker = true
                        }) {
                            VStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 24))
                                Text("Album".localized)
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            showCameraPicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                                Circle()
                                    .stroke(Color.black.opacity(0.1), lineWidth: 2)
                                    .frame(width: 70, height: 70)
                                Image(systemName: "camera.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Button(action: {
                            viewModel.image = nil
                            viewModel.countSummary = ""
                            viewModel.detectedObjects = []
                        }) {
                            VStack {
                                Image(systemName: "trash")
                                    .font(.system(size: 24))
                                Text("Clear".localized)
                                    .font(.caption)
                            }
                            .foregroundColor(viewModel.image == nil ? .gray : .white)
                        }
                        .disabled(viewModel.image == nil)
                    }
                }
                .padding()
                .background(Color.black)
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(selectedImage: Binding(
                get: { nil },
                set: { if let img = $0 { viewModel.processImage(img) } }
            ))
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            CameraPicker(selectedImage: Binding(
                get: { nil },
                set: { if let img = $0 { viewModel.processImage(img) } }
            ))
            .edgesIgnoringSafeArea(.all)
        }
    }
}

// Helper view to draw boxes correctly on aspect-fit image
struct DetectionOverlay: View {
    let imageSize: CGSize
    let viewSize: CGSize
    let results: [RecognitionResult]
    
    // Helper to calculate frame without using imperative if-else in ViewBuilder
    private func calculateFrame(imageRatio: CGFloat, viewRatio: CGFloat, viewSize: CGSize) -> (width: CGFloat, height: CGFloat) {
        if imageRatio > viewRatio {
            // Width bound
            return (viewSize.width, viewSize.width / imageRatio)
        } else {
            // Height bound
            return (viewSize.height * imageRatio, viewSize.height)
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let imageRatio = imageSize.width / imageSize.height
            let viewRatio = viewSize.width / viewSize.height
            
            // Use helper method to calculate dimensions
            let fit = calculateFrame(imageRatio: imageRatio, viewRatio: viewRatio, viewSize: viewSize)
            let fitWidth = fit.width
            let fitHeight = fit.height
            
            let offsetX = (viewSize.width - fitWidth) / 2
            let offsetY = (viewSize.height - fitHeight) / 2
            
            ForEach(results) { result in
                let box = result.boundingBox
                // Box is normalized (0-1) in Vision coordinates (Bottom-Left origin)
                // But RecognitionResult from ObjectDetectionService maps it to normalized Top-Left for Display?
                // Wait, let's check ObjectDetectionService.detectWithLetterbox line 602.
                // It returns normalized rect in Original Size.
                // And line 587 uses y_pixel_target which comes from Vision box.origin.y (Bottom-Left).
                // But then it calculates y_pixel_new.
                // If the coordinate system is mixed, we might have issues.
                // Assuming standard normalized Top-Left for SwiftUI:
                // x, y, w, h
                
                // Note: The previous code in ObjectDetectionView or others likely handles this.
                // Let's assume the result.boundingBox is standard normalized Top-Left [0,0,1,1].
                // If results are upside down, we need to flip Y.
                // Usually Vision returns Y from bottom.
                // If `detectWithLetterbox` didn't flip it, we need to flip it here: (1 - y - h).
                
                // Let's check ObjectDetectionService again.
                // Line 560: box = observation.boundingBox (Vision, Bottom-Left)
                // Line 587: y_pixel_target = box.origin.y * targetSize.height (Bottom-Left pixel)
                // Then it removes padding and unscales.
                // Finally line 602 returns normalized rect.
                // Since it didn't explicitly flip Y (e.g. height - y), the resulting `normRect` Y is still "distance from bottom".
                // So (0,0) is bottom-left.
                // SwiftUI (0,0) is top-left.
                // So we MUST flip Y here: y_swiftUI = 1 - y_vision - height_vision.
                
                let rect = CGRect(
                    x: offsetX + box.origin.x * fitWidth,
                    y: offsetY + (1.0 - box.origin.y - box.height) * fitHeight,
                    width: box.width * fitWidth,
                    height: box.height * fitHeight
                )
                
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .path(in: rect)
                        .stroke(Color.yellow, lineWidth: 2)
                    
                    Text(getLocalizedName(for: result.text))
                        .font(.system(size: 10))
                        .padding(2)
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(2)
                        .position(x: rect.minX + 20, y: rect.minY - 10) // Approx position
                }
            }
        }
    }
    
    private func getLocalizedName(for text: String) -> String {
        if SettingsManager.shared.appLanguage == .english {
            return text.capitalized
        } else {
            return ObjectTranslation.getChineseName(for: text)
        }
    }
}
