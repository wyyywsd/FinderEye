import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    @Binding var isFinished: Bool
    
    var body: some View {
        ZStack {
            // 背景
            Color("LaunchBackground") // 如果没有 Asset 颜色，会回退到系统背景，这里我们直接用代码处理
            Color.black.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Logo 区域
                VStack(spacing: 20) {
                    Image(systemName: "eye.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            .linearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .shadow(color: .blue.opacity(0.5), radius: 20, x: 0, y: 10)
                        .scaleEffect(isActive ? 1.0 : 0.8)
                        .opacity(isActive ? 1.0 : 0.0)
                    
                    Text("FinderEye")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(isActive ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // 广告占位区 (模拟)
                VStack {
                    Text("ADVERTISEMENT")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.bottom, 4)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                        
                        VStack {
                            Image(systemName: "star.fill")
                                .font(.largeTitle)
                                .foregroundColor(.yellow)
                            Text("Premium Features Coming Soon")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 120)
                    .padding(.horizontal, 40)
                }
                .opacity(opacity)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // 动画序列
            withAnimation(.easeOut(duration: 0.8)) {
                self.isActive = true
            }
            
            withAnimation(.easeIn(duration: 0.8).delay(0.5)) {
                self.opacity = 1.0
            }
            
            // 模拟加载/广告展示时间
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    self.isFinished = true
                }
            }
        }
    }
}
