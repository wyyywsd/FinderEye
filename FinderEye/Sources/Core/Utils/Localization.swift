import Foundation
import SwiftUI

// 简单的本地化管理器
class LocalizationManager {
    static let shared = LocalizationManager()
    
    private init() {}
    
    var language: SettingsManager.AppLanguage {
        SettingsManager.shared.appLanguage
    }
    
    func localized(_ key: String) -> String {
        let langCode = language == .english ? "en" : "zh"
        return translations[langCode]?[key] ?? key
    }
    
    private let translations: [String: [String: String]] = [
        "zh": [
            // Home / Dashboard
            "Discovery": "发现",
            "Explore the world around you": "探索你周围的世界",
            "Smart Finder": "智能寻物",
            "Locate objects in real-time": "实时或从照片中定位物品",
            "Text Scanner": "文字搜索",
            "Search text in scene": "在场景中搜索特定文字",
            "Tools": "工具箱",
            "Magnifier": "放大镜",
            "Zoom details": "查看细节",
            "Crop Image": "裁剪图片",
            "Copied to Clipboard": "已复制到剪贴板",
            "Crop": "裁剪",
            "Starting Camera...": "正在启动相机...",
            "Cancel": "取消",
            "Extract Text": "提取文字",
            "OCR from Image": "图片文字识别",
            "Text Extraction": "文字提取",
            "Select an image to extract text": "选择图片以提取文字",
            "Camera": "相机",
            "Photos": "相册",
            "Extracting Text...": "正在提取文字...",
            "Extracted Text": "提取结果",
            "No text found in the image.": "未在图片中发现文字",
            
            // Smart Counter
            "Smart Counter": "智能计数器",
            "Count objects in scene": "统计场景中物品数量",
            "Take a photo or choose from album to count objects": "拍照或从相册选择图片以统计物品",
            "Statistics:": "统计结果:",
            "Analyzing...": "正在分析...",
            "No objects detected.": "未检测到物品。",
            "Album": "相册",
            "Clear": "清除",
            
            "Error": "错误",
            "Close": "关闭",
            "Recent": "最近记录",
            "No History": "暂无记录",
            
            // Object Detection
            "Object Search": "物品搜索",
            "Return to Camera": "返回相机",
            "Enter search keyword": "输入搜索内容",
            " is not supported by the current model": " 不在当前模型支持范围内",
            
            // Profile
            "Profile": "我的",
            "User": "用户",
            "Member": "普通会员",
            "Toolbox": "工具箱",
            "History": "识别历史",
            "Favorites": "我的收藏",
            "System": "系统",
            "Settings": "设置",
            "Help & Feedback": "帮助与反馈",
            "About": "关于",
            
            // Settings
            "Appearance": "外观",
            "Theme Mode": "主题模式",
            "System Follow": "跟随系统",
            "Light Mode": "浅色模式",
            "Dark Mode": "深色模式",
            "Language": "语言",
            "General": "通用",
            "Haptics": "震动反馈",
            "Sounds": "提示音",
            "Smart Detection": "智能检测",
            "Confidence Threshold": "置信度阈值",
            "Search Display": "搜索显示",
            "Match Mode": "匹配模式",
            "Whole Line": "整行文字",
            "Specific Text": "具体文字",
            "Match Mode Desc Whole": "显示包含关键词的整行文字，提供更多上下文信息。",
            "Match Mode Desc Specific": "仅高亮显示匹配的关键词，界面更加简洁。",
            "Low": "低",
            "High": "高",
            "Current Threshold": "当前阈值",
            
            // Performance Settings
            "Performance Settings": "性能设置",
            "Scanning FPS": "扫描模式帧率",
            "Tracking FPS": "追踪模式帧率",
            "Higher FPS consumes more battery.": "高帧率模式会增加耗电量。",
            "High Accuracy Mode": "高精度模式",
            "Uses slicing to detect small objects. Disable to improve performance.": "使用分块技术识别小物体。关闭可提升性能。",
            
            // Model Selection
            "Detection Model": "检测模型",
            "Model Selection Desc": "大型模型识别更准确，但速度较慢且更耗电。",
            "ModelType Small": "速度优先 (Small)",
            "ModelType Medium": "平衡模式 (Medium)",
            "ModelType Large": "精度优先 (Large)",
            
            // Common
            "Back": "返回",
            "Done": "完成"
        ],
        "en": [
            // Home / Dashboard
            "Discovery": "Discovery",
            "Explore the world around you": "Explore the world around you",
            "Smart Finder": "Smart Finder",
            "Locate objects in real-time": "Locate objects in real-time",
            "Text Scanner": "Text Search",
            "Search text in scene": "Search specific text in scene",
            "Tools": "Tools",
            "Magnifier": "Magnifier",
            "Zoom details": "Zoom details",
            "Crop Image": "Crop Image",
            "Copied to Clipboard": "Copied to Clipboard",
            "Crop": "Crop",
            "Starting Camera...": "Starting Camera...",
            "Cancel": "Cancel",
            "Extract Text": "Extract Text",
            "OCR from Image": "OCR from Image",
            "Text Extraction": "Text Extraction",
            "Select an image to extract text": "Select an image to extract text",
            "Camera": "Camera",
            "Photos": "Photos",
            "Extracting Text...": "Extracting Text...",
            "Extracted Text": "Extracted Text",
            "No text found in the image.": "No text found in the image.",
            "Error": "Error",
            "Close": "Close",
            "Recent": "Recent",
            "No History": "No History",
            
            // Object Detection
            "Object Search": "Object Search",
            "Return to Camera": "Return to Camera",
            "Enter search keyword": "Enter search keyword",
            " is not supported by the current model": " is not supported by the current model",
            
            // Profile
            "Profile": "Profile",
            "User": "User",
            "Member": "Member",
            "Toolbox": "Toolbox",
            "History": "History",
            "Favorites": "Favorites",
            "System": "System",
            "Settings": "Settings",
            "Help & Feedback": "Help & Feedback",
            "About": "About",
            
            // Settings
            "Appearance": "Appearance",
            "Theme Mode": "Theme Mode",
            "System Follow": "System",
            "Light Mode": "Light",
            "Dark Mode": "Dark",
            "Language": "Language",
            "General": "General",
            "Haptics": "Haptics",
            "Sounds": "Sounds",
            "Smart Detection": "Smart Detection",
            "Confidence Threshold": "Confidence Threshold",
            "Search Display": "Search Display",
            "Match Mode": "Match Mode",
            "Whole Line": "Whole Line",
            "Specific Text": "Specific Text",
            "Match Mode Desc Whole": "Show whole line containing keywords for more context.",
            "Match Mode Desc Specific": "Highlight only matching keywords for cleaner UI.",
            "Low": "Low",
            "High": "High",
            "Current Threshold": "Current Threshold",
            
            // Performance Settings
            "Performance Settings": "Performance Settings",
            "Scanning FPS": "Scanning FPS",
            "Tracking FPS": "Tracking FPS",
            "Higher FPS consumes more battery.": "Higher FPS consumes more battery.",
            "High Accuracy Mode": "High Accuracy Mode",
            "Uses slicing to detect small objects. Disable to improve performance.": "Uses slicing to detect small objects. Disable to improve performance.",
            
            // Model Selection
            "Detection Model": "Detection Model",
            "Model Selection Desc": "Larger models are more accurate but slower.",
            "ModelType Small": "Speed (Small)",
            "ModelType Medium": "Balanced (Medium)",
            "ModelType Large": "Accuracy (Large)",
            
            // Common
            "Back": "Back",
            "Done": "Done"
        ]
    ]
}

// String Extension for easy usage
extension String {
    var localized: String {
        LocalizationManager.shared.localized(self)
    }
}
