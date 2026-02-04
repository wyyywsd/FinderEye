import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var isHapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(isHapticsEnabled, forKey: "isHapticsEnabled") }
    }
    
    @Published var isSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(isSoundEnabled, forKey: "isSoundEnabled") }
    }
    
    @Published var confidenceThreshold: Double {
        didSet { UserDefaults.standard.set(confidenceThreshold, forKey: "confidenceThreshold") }
    }
    
    // 主题设置
    enum AppTheme: String, CaseIterable, Identifiable {
        case system = "跟随系统"
        case light = "浅色模式"
        case dark = "深色模式"
        var id: String { self.rawValue }
    }
    
    @Published var appTheme: AppTheme {
        didSet { UserDefaults.standard.set(appTheme.rawValue, forKey: "appTheme") }
    }
    
    // 语言设置
    enum AppLanguage: String, CaseIterable, Identifiable {
        case english = "English"
        case chinese = "中文"
        var id: String { self.rawValue }
    }
    
    @Published var appLanguage: AppLanguage {
        didSet { UserDefaults.standard.set(appLanguage.rawValue, forKey: "appLanguage") }
    }
    
    // 文字搜索匹配模式
    enum TextMatchMode: String, CaseIterable, Identifiable {
        case wholeLine = "整行文字"
        case specific = "具体文字"
        var id: String { self.rawValue }
    }
    
    @Published var textMatchMode: TextMatchMode {
        didSet { UserDefaults.standard.set(textMatchMode.rawValue, forKey: "textMatchMode") }
    }
    
    private init() {
        self.isHapticsEnabled = UserDefaults.standard.object(forKey: "isHapticsEnabled") as? Bool ?? true
        self.isSoundEnabled = UserDefaults.standard.object(forKey: "isSoundEnabled") as? Bool ?? false
        self.confidenceThreshold = UserDefaults.standard.object(forKey: "confidenceThreshold") as? Double ?? 0.3
        
        let savedTheme = UserDefaults.standard.string(forKey: "appTheme") ?? AppTheme.system.rawValue
        self.appTheme = AppTheme(rawValue: savedTheme) ?? .system
        
        let savedLang = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.chinese.rawValue
        self.appLanguage = AppLanguage(rawValue: savedLang) ?? .chinese
        
        let savedMode = UserDefaults.standard.string(forKey: "textMatchMode") ?? TextMatchMode.wholeLine.rawValue
        self.textMatchMode = TextMatchMode(rawValue: savedMode) ?? .wholeLine
    }
}
