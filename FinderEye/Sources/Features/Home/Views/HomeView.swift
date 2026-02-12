import SwiftUI

struct HomeView: View {
    // 监听 SettingsManager 以触发语言更新
    @StateObject private var settings = SettingsManager.shared
    
    // Navigation State
    enum ActiveSheet: Identifiable {
        case objectDetection(mode: ObjectDetectionViewModel.SearchMode)
        case textExtraction
        case smartCounter
        
        var id: String {
            switch self {
            case .objectDetection(let mode): return "objectDetection-\(mode.rawValue)"
            case .textExtraction: return "textExtraction"
            case .smartCounter: return "smartCounter"
            }
        }
    }
    
    @State private var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Header Section
                    headerSection
                    
                    // 2. Main Feature Card (Finder - Object Search)
                    mainFeatureCard
                    
                    // 3. Secondary Features Grid (Text Scanner, etc.)
                    secondaryFeaturesGrid
                    
                    // 4. Recent Activity (Placeholder)
                    recentActivitySection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarHidden(true)
            .fullScreenCover(item: $activeSheet) { item in
                switch item {
                case .objectDetection(let mode):
                    ObjectDetectionView(initialMode: mode)
                case .textExtraction:
                    TextExtractionView()
                case .smartCounter:
                    SmartCounterView()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Discovery".localized)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Explore the world around you".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.top, 20)
    }
    
    var mainFeatureCard: some View {
        Button(action: {
            activeSheet = .objectDetection(mode: .object)
        }) {
            ZStack(alignment: .bottomLeading) {
                // Background Gradient
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Decorative Circle
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .offset(x: 100, y: 50)
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 32))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 20, weight: .bold))
                            .opacity(0.6)
                    }
                    
                    Spacer()
                    
                    Text("Smart Finder".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Locate objects in real-time".localized)
                        .font(.footnote)
                        .opacity(0.9)
                        .multilineTextAlignment(.leading)
                }
                .foregroundColor(.white)
                .padding(20)
            }
            .frame(height: 180)
            .cornerRadius(24)
            .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 10)
        }
    }
    
    var secondaryFeaturesGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tools".localized)
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                // Feature 1: Text Scanner
                Button(action: {
                    activeSheet = .objectDetection(mode: .text)
                }) {
                    featureCardContent(
                        icon: "text.viewfinder",
                        title: "Text Scanner".localized,
                        subtitle: "Search text in scene".localized,
                        color: .orange
                    )
                }
                
                // Feature 2: Text Extraction
                Button(action: {
                    activeSheet = .textExtraction
                }) {
                    featureCardContent(
                        icon: "doc.text.viewfinder",
                        title: "Extract Text".localized,
                        subtitle: "OCR from Image".localized,
                        color: .green
                    )
                }
                
                // Feature 3: Smart Counter
                Button(action: {
                    activeSheet = .smartCounter
                }) {
                    featureCardContent(
                        icon: "number.square",
                        title: "Smart Counter".localized,
                        subtitle: "Count objects in scene".localized,
                        color: .purple
                    )
                }
            }
        }
    }
    
    func featureCardContent(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent".localized)
                .font(.headline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                            .frame(width: 140, height: 140)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray.opacity(0.3))
                                    Text("No History".localized)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                    }
                }
            }
        }
    }
}
