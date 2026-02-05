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
    
    // 模型类型设置
    enum ModelType: String, CaseIterable, Identifiable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        var id: String { self.rawValue }
        
        var fileName: String {
            switch self {
            case .small: return "ObjectDetectorS"
            case .medium: return "ObjectDetectorM"
            case .large: return "ObjectDetectorL"
            }
        }
        
        var displayName: String {
            switch self {
            case .small: return "ModelType Small".localized
            case .medium: return "ModelType Medium".localized
            case .large: return "ModelType Large".localized
            }
        }
    }
    
    @Published var modelType: ModelType {
        didSet { UserDefaults.standard.set(modelType.rawValue, forKey: "modelType") }
    }
    
    // 性能设置：扫描模式帧率 (FPS)
    // 默认 5 FPS (0.2s 间隔)
    @Published var scanningFPS: Double {
        didSet { UserDefaults.standard.set(scanningFPS, forKey: "scanningFPS") }
    }
    
    // 性能设置：追踪模式帧率 (FPS)
    // 默认 30 FPS (0.033s 间隔)
    @Published var trackingFPS: Double {
        didSet { UserDefaults.standard.set(trackingFPS, forKey: "trackingFPS") }
    }
    
    // 性能设置：是否启用高精度分块检测 (High Accuracy / Slicing)
    // 默认开启，但允许用户关闭以节省性能或避免误检
    @Published var isHighAccuracyModeEnabled: Bool {
        didSet { UserDefaults.standard.set(isHighAccuracyModeEnabled, forKey: "isHighAccuracyModeEnabled") }
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
        
        let savedModel = UserDefaults.standard.string(forKey: "modelType") ?? ModelType.medium.rawValue
        self.modelType = ModelType(rawValue: savedModel) ?? .medium
        
        self.scanningFPS = UserDefaults.standard.object(forKey: "scanningFPS") as? Double ?? 5.0
        self.trackingFPS = UserDefaults.standard.object(forKey: "trackingFPS") as? Double ?? 30.0
        self.isHighAccuracyModeEnabled = UserDefaults.standard.object(forKey: "isHighAccuracyModeEnabled") as? Bool ?? true
    }
}
