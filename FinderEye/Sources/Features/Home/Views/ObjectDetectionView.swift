import SwiftUI

struct ObjectDetectionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: ObjectDetectionViewModel
    @State private var showSettings = false
    @State private var showPhotoPicker = false
    @State private var selectedImage: UIImage?
    
    // 初始化时传入模式
    let initialMode: ObjectDetectionViewModel.SearchMode
    
    init(initialMode: ObjectDetectionViewModel.SearchMode = .object) {
        self.initialMode = initialMode
        _viewModel = StateObject(wrappedValue: ObjectDetectionViewModel(initialMode: initialMode))
    }
    
    // Static Image Interaction
    @State private var imageScale: CGFloat = 1.0
    @State private var lastImageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastImageOffset: CGSize = .zero
    
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        ZStack {
            // Layer 1: Content (Camera or Static Image)
            contentLayer
            
            // Layer 2: UI Overlay
            uiOverlayLayer
        }
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(selectedImage: $selectedImage)
        }
        // Settings sheet logic removed (moved to Tab)
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                resetImageState()
                viewModel.processStaticImage(image)
            }
        }
        .onChange(of: viewModel.searchText) { _ in
            if let image = selectedImage {
                viewModel.processStaticImage(image)
            }
        }
        .onChange(of: isSearchFocused) { isFocused in
            viewModel.setEditing(isFocused)
        }
        .onAppear {
            // 确保模式正确设置
            viewModel.searchMode = initialMode
            
            if selectedImage == nil {
                viewModel.onAppear()
            }
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
    
    // MARK: - Content Layer
    
    var contentLayer: some View {
        ZStack {
            Color.black // Background
            
            if let image = selectedImage {
                staticImageMode(image: image)
            } else {
                cameraMode
            }
        }
    }
    
    var cameraMode: some View {
        ZStack {
            CameraPreviewView(session: viewModel.cameraManager.session)
                .opacity(viewModel.cameraManager.isSessionRunning ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.5), value: viewModel.cameraManager.isSessionRunning)
            
            // Overlays for Camera
            if !viewModel.recognitionResults.isEmpty {
                OverlayView(
                    results: viewModel.recognitionResults,
                    bufferSize: viewModel.bufferSize,
                    contentMode: .fill
                )
            }
        }
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    if !viewModel.isZooming { viewModel.isZooming = true }
                    let delta = value / lastImageScale
                    lastImageScale = value
                    let newZoom = viewModel.currentZoomFactor * delta
                    viewModel.setCameraZoom(factor: newZoom)
                }
                .onEnded { _ in
                    lastImageScale = 1.0
                    viewModel.isZooming = false
                }
        )
    }
    
    func staticImageMode(image: UIImage) -> some View {
        GeometryReader { geometry in
            ZStack {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                    if !viewModel.recognitionResults.isEmpty {
                        OverlayView(
                            results: viewModel.recognitionResults,
                            bufferSize: viewModel.bufferSize,
                            contentMode: .fit
                        )
                    }
                }
                .scaleEffect(imageScale)
                .offset(imageOffset)
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                if !viewModel.isZooming { viewModel.isZooming = true }
                                let delta = value / lastImageScale
                                lastImageScale = value
                                let newScale = imageScale * delta
                                imageScale = min(max(newScale, 1.0), 5.0)
                            }
                            .onEnded { _ in
                                lastImageScale = 1.0
                                if imageScale <= 1.0 {
                                    withAnimation {
                                        imageOffset = .zero
                                        lastImageOffset = .zero
                                    }
                                }
                                viewModel.isZooming = false
                            },
                        DragGesture()
                            .onChanged { value in
                                guard imageScale > 1.0 else { return }
                                if !viewModel.isZooming { viewModel.isZooming = true }
                                let newOffset = CGSize(
                                    width: lastImageOffset.width + value.translation.width,
                                    height: lastImageOffset.height + value.translation.height
                                )
                                imageOffset = newOffset
                            }
                            .onEnded { _ in
                                lastImageOffset = imageOffset
                                viewModel.isZooming = false
                            }
                    )
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
            }
        }
    }
    
    // MARK: - UI Overlay Layer
    
    var uiOverlayLayer: some View {
        VStack {
            // Top Area: Search Bar & Photo Picker
            HStack(spacing: 12) {
                // Back Button
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }

                // Mode Indicator & Title (Centered)
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: viewModel.searchMode == .object ? "cube.transparent" : "text.viewfinder")
                        .font(.caption)
                    Text(viewModel.searchMode == .object ? "Object Search".localized : "Text Scanner".localized)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                
                Spacer()
                
                // Photo Picker Button
                Button(action: { showPhotoPicker = true }) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 60) // Safe Area top padding
            
            // Search Bar (Floating below top bar)
            VStack {
                Spacer()
                    .frame(height: 120) // Leave space for top bar
                
                SearchBar(text: $viewModel.searchText, placeholder: "Enter search keyword".localized, isFocused: $isSearchFocused) {
                        // Submit action
                }
                .padding(.horizontal, 16)
                
                // 不支持的关键词提示
                if let warning = viewModel.keywordWarning {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text(warning)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(2)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.2), value: viewModel.keywordWarning)
                }
                
                Spacer()
            }
            .ignoresSafeArea(.keyboard) // Prevent layout shift when keyboard appears
            
            Spacer()
            
            // Bottom Area: Return to Camera (Floating)
            if selectedImage != nil {
                Button(action: {
                    withAnimation {
                        selectedImage = nil
                        viewModel.onAppear()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                        Text("Return to Camera".localized)
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 5)
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    private func resetImageState() {
        imageScale = 1.0
        imageOffset = .zero
        lastImageScale = 1.0
        lastImageOffset = .zero
    }
}
