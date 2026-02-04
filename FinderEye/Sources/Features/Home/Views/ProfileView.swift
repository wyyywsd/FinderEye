import SwiftUI

struct ProfileView: View {
    // 监听 SettingsManager 以触发语言更新
    @StateObject private var settings = SettingsManager.shared
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. 用户信息卡片
                    userInfoCard
                    
                    // 2. 功能菜单
                    VStack(spacing: 16) {
                        // 工具箱分组
                        menuGroup(title: "Toolbox".localized) {
                            NavigationLink(destination: Text("History Feature Coming Soon...")) {
                                menuRow(icon: "clock.arrow.circlepath", title: "History".localized, color: .blue)
                            }
                            NavigationLink(destination: Text("Favorites Feature Coming Soon...")) {
                                menuRow(icon: "star.fill", title: "Favorites".localized, color: .yellow)
                            }
                        }
                        
                        // 系统设置分组
                        menuGroup(title: "System".localized) {
                            NavigationLink(destination: SettingsView()) {
                                menuRow(icon: "gearshape.fill", title: "Settings".localized, color: .gray)
                            }
                            NavigationLink(destination: Text("Help & Feedback Feature Coming Soon...")) {
                                menuRow(icon: "questionmark.circle.fill", title: "Help & Feedback".localized, color: .green)
                            }
                            NavigationLink(destination: AboutView()) {
                                menuRow(icon: "info.circle.fill", title: "About".localized, color: .purple)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Profile".localized)
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Subviews
    
    var userInfoCard: some View {
        HStack(spacing: 16) {
            // 头像
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 70, height: 70)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Finder User".localized.replacingOccurrences(of: "User", with: "User")) // 简单演示
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Member".localized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    func menuGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    func menuRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(16)
    }
}

// 简单的关于页面
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.linearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
            
            Text("FinderEye")
                .font(.title)
                .bold()
            
            Text("Version 1.0.0")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.top, 50)
        .navigationTitle("About".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
