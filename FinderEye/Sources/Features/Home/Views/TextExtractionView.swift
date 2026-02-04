import SwiftUI

struct TextExtractionView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = TextExtractionViewModel()
    
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var showCropper = false
    @State private var selectedImage: UIImage?
    @State private var rawImage: UIImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Image Preview Area
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(16)
                            .shadow(radius: 5)
                            .padding()
                            .frame(maxHeight: 400)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "text.viewfinder")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            Text("Select an image to extract text".localized)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: 20) {
                        actionButton(icon: "camera.fill", title: "Camera".localized) {
                            showCamera = true
                        }
                        
                        actionButton(icon: "photo.fill", title: "Photos".localized) {
                            showPhotoLibrary = true
                        }
                    }
                    .padding(.bottom, 40)
                }
                
                // Loading Overlay
                if viewModel.isProcessing {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("Extracting Text...".localized)
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Text Extraction".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CustomCameraView(selectedImage: $rawImage)
            }
            .sheet(isPresented: $showPhotoLibrary) {
                PhotoPicker(selectedImage: $rawImage)
            }
            .fullScreenCover(isPresented: $showCropper) {
                if let image = rawImage {
                    ImageCropperView(image: .constant(image), isPresented: $showCropper) { croppedImage in
                        self.selectedImage = croppedImage
                        self.showCropper = false
                        viewModel.extractText(from: croppedImage)
                    }
                }
            }
            .onChange(of: rawImage) { newImage in
                if newImage != nil {
                    showCropper = true
                }
            }
            // Result Sheet
            .sheet(isPresented: $viewModel.showResult) {
                TextResultView(text: viewModel.extractedText)
            }
            .alert(item: Binding<AlertItem?>(
                get: { viewModel.errorMessage.map { AlertItem(message: $0) } },
                set: { _ in viewModel.errorMessage = nil }
            )) { item in
                Alert(title: Text("Error".localized), message: Text(item.message), dismissButton: .default(Text("OK".localized)))
            }
        }
    }
    
    func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

struct TextResultView: View {
    let text: String
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showToast = false
    
    var body: some View {
        NavigationView {
            ZStack {
                TextEditor(text: .constant(text))
                    .font(.body)
                    .padding()
                
                if showToast {
                    VStack {
                        Spacer()
                        Text("Copied to Clipboard".localized)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(10)
                            .padding(.bottom, 50)
                            .transition(.opacity)
                    }
                    .zIndex(1)
                }
            }
            .navigationTitle("Extracted Text".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        UIPasteboard.general.string = text
                        withAnimation {
                            showToast = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showToast = false
                            }
                        }
                    }) {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
        }
    }
}
