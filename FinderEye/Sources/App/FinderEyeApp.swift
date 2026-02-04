import SwiftUI

@main
struct FinderEyeApp: App {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var isSplashFinished = false
    
    init() {
        // 全局外观配置
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !isSplashFinished {
                    SplashView(isFinished: $isSplashFinished)
                        .transition(.opacity)
                        .zIndex(1)
                } else {
                    MainTabView()
                        .transition(.opacity)
                        .zIndex(0)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isSplashFinished)
            .preferredColorScheme(settings.appTheme == .system ? nil : (settings.appTheme == .dark ? .dark : .light))
        }
    }
    
    private func configureAppearance() {
        // 这里可以配置全局的 UINavigationBar appearance 等，如果需要的话
    }
}
