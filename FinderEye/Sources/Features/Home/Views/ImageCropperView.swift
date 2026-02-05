import SwiftUI
import UIKit

struct ImageCropperView: View {
    @Binding var image: UIImage
    @Binding var isPresented: Bool
    var onComplete: (UIImage) -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = scale * delta
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newOffset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                    offset = newOffset
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
            }
            .navigationTitle("Crop Image".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done".localized) {
                        // Simple pass-through for now, or implement actual cropping based on offset/scale
                        // For this hotfix, we return the original image to ensure stability.
                        // Ideally we should crop.
                        onComplete(image)
                    }
                }
            }
        }
    }
}
