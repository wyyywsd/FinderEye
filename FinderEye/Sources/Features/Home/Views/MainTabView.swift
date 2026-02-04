import SwiftUI

struct MainTabView: View {
    @StateObject private var settings = SettingsManager.shared // Listen for updates
    @State private var selectedTab: Int = 0
    
    // 自定义 TabBar 外观
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        
        // 选中状态颜色
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.selected.iconColor = UIColor.systemBlue
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        
        // 未选中状态颜色
        itemAppearance.normal.iconColor = UIColor.gray
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        
        appearance.stackedLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("Discovery".localized)
                }
                .tag(0)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile".localized)
                }
                .tag(1)
        }
        .accentColor(.blue) // SwiftUI 层面的选中颜色
    }
}
