import SwiftUI
import AVFoundation

struct CustomCameraView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedImage: UIImage?
    
    // We can reuse the existing CameraManager, but we need to make sure it's not conflicting 
    // if another instance is running. Since this is a fullScreenCover, the HomeView one might still be active?
    // HomeView uses ObjectDetectionViewModel which has its own CameraManager.
    // When fullScreenCover is presented, the HomeView usually stays.
    // However, only one AVCaptureSession can access the hardware effectively usually, or at least we should stop the other one.
    // But for simplicity, let's assume we can create a new manager or pass one in.
    // Passing one in is safer but the existing one is tied to ObjectDetection logic.
    // Let's create a new one for this "Photo Mode" and ensure the other one is stopped or paused?
    // The ObjectDetectionView is NOT presented when this view is presented.
    // But HomeView is. HomeView doesn't run camera. ObjectDetectionView does.
    // So HomeView is just a dashboard. No camera running.
    // So we can safely create a new CameraManager.
    
    @StateObject private var cameraManager = CameraManager()
    @State private var flashMode: AVCaptureDevice.FlashMode = .off
    @State private var isCapturing = false
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if cameraManager.isSessionRunning {
                CameraPreviewView(session: cameraManager.session)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("Starting Camera...".localized)
                    .foregroundColor(.white)
            }
            
            // Overlay Controls
            VStack {
                // Top Bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Flash Toggle (Future implementation, just placeholder or functional if easy)
                    // CameraManager needs flash support update for this. Skipping for now.
                }
                .padding(.horizontal)
                .padding(.top, 50)
                
                Spacer()
                
                // Bottom Bar
                HStack {
                    Spacer()
                    
                    // Shutter Button
                    Button(action: {
                        capturePhoto()
                    }) {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                            
                            if isCapturing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                            }
                        }
                    }
                    .disabled(isCapturing)
                    
                    Spacer()
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            setupCamera()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    private func setupCamera() {
        Task {
            if await cameraManager.checkPermissions() {
                try? cameraManager.setupCamera()
                cameraManager.startSession()
            }
        }
    }
    
    private func capturePhoto() {
        guard !isCapturing else { return }
        isCapturing = true
        
        Task {
            do {
                let image = try await cameraManager.capturePhoto()
                await MainActor.run {
                    self.selectedImage = image
                    self.presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("Capture failed: \(error)")
                isCapturing = false
            }
        }
    }
}
