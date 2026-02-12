import Foundation

struct ObjectTranslation {
    
    // MARK: - Supported Classes (must match export_model.py vocabulary)
    // 模型支持的所有英文类别，用于校验用户输入
    static let supportedClasses: Set<String> = [
        "person", "face", "hand",
        "cat", "dog",
        "bicycle", "car", "motorcycle", "bus", "truck",
        "backpack", "umbrella", "handbag", "tie", "suitcase",
        "hat", "glasses", "sunglasses",
        "shoe", "bag", "belt", "glove", "scarf", "mask",
        "watch", "ring", "necklace",
        "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl",
        "chopsticks", "plate", "pan", "pot",
        "banana", "apple", "sandwich", "orange", "broccoli", "carrot",
        "pizza", "donut", "cake",
        "chair", "couch", "potted plant", "bed", "dining table", "toilet", "tv",
        "lamp", "clock", "vase", "pillow", "towel", "trash can",
        "mirror", "curtain", "door", "shelf", "box",
        "laptop", "mouse", "remote", "keyboard", "cell phone", "tablet", "monitor",
        "camera", "headphones", "speaker",
        "charger", "power strip", "router", "printer",
        "microwave", "oven", "toaster", "sink", "refrigerator",
        "washing machine", "fan", "hair drier",
        "book", "scissors", "pen", "pencil", "notebook", "ruler",
        "stapler", "tape", "eraser",
        "toothbrush", "toothpaste", "soap", "comb", "tissue",
        "key", "lighter", "wallet",
        "teddy bear"
    ]
    
    /// 校验关键词是否被模型支持
    /// 返回 nil 表示支持，返回 String 表示不支持的原因提示
    static func validateKeyword(_ keyword: String) -> String? {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        
        let lowered = trimmed.lowercased()
        
        // 1. 英文直接输入 — 检查是否在支持列表中
        if lowered.allSatisfy({ $0.isASCII }) {
            if supportedClasses.contains(lowered) { return nil }
            // 模糊匹配：输入是某个支持类别的子串，或反之
            for cls in supportedClasses {
                if cls.contains(lowered) || lowered.contains(cls) { return nil }
            }
            return "\"\(trimmed)\"" + " is not supported by the current model".localized
        }
        
        // 2. 中文输入 — 检查翻译后是否在支持列表中
        if let english = getEnglishName(for: trimmed) {
            let englishLower = english.lowercased()
            if supportedClasses.contains(englishLower) { return nil }
            // 模糊匹配
            for cls in supportedClasses {
                if cls.contains(englishLower) || englishLower.contains(cls) { return nil }
            }
        }
        
        return "\"\(trimmed)\"" + " is not supported by the current model".localized
    }
    
    // MARK: - Chinese → English Mapping
    // 只保留模型支持的类别 (与 export_model.py 的 base_objects 对应)
    static let mapping: [String: String] = [
        // MARK: - People
        "人": "person", "行人": "person", "人类": "person",
        "男人": "person", "女人": "person", "男": "person", "女": "person",
        "男士": "person", "女士": "person",
        "孩子": "person", "儿童": "person", "小孩": "person",
        "男孩": "person", "女孩": "person", "男生": "person", "女生": "person",
        "婴儿": "person", "宝宝": "person",
        "老人": "person", "老奶奶": "person", "老爷爷": "person",
        "脸": "face", "人脸": "face", "脸蛋": "face",
        "手": "hand", "小手": "hand",
        
        // MARK: - Pets
        "猫": "cat", "猫咪": "cat", "小猫": "cat", "喵星人": "cat",
        "狗": "dog", "狗狗": "dog", "小狗": "dog", "汪星人": "dog", "狗子": "dog",
        
        // MARK: - Transport
        "自行车": "bicycle", "单车": "bicycle", "脚踏车": "bicycle",
        "汽车": "car", "轿车": "car", "车": "car", "小汽车": "car", "座驾": "car",
        "摩托车": "motorcycle", "摩托": "motorcycle",
        "公交车": "bus", "巴士": "bus", "公共汽车": "bus", "大巴": "bus", "大巴车": "bus",
        "卡车": "truck", "货车": "truck", "大货车": "truck",
        
        // MARK: - Clothing & Accessories
        "背包": "backpack", "书包": "backpack", "双肩包": "backpack",
        "雨伞": "umbrella", "伞": "umbrella",
        "手提包": "handbag", "挎包": "handbag", "皮包": "handbag",
        "领带": "tie", "领结": "tie",
        "手提箱": "suitcase", "行李箱": "suitcase", "旅行箱": "suitcase",
        "眼镜": "glasses", "近视镜": "glasses",
        "墨镜": "sunglasses", "太阳镜": "sunglasses",
        "帽子": "hat", "礼帽": "hat", "鸭舌帽": "hat", "棒球帽": "hat",
        "鞋": "shoe", "鞋子": "shoe", "皮鞋": "shoe",
        "运动鞋": "shoe", "球鞋": "shoe", "跑鞋": "shoe",
        "靴子": "shoe", "凉鞋": "shoe", "拖鞋": "shoe", "高跟鞋": "shoe",
        "包": "bag", "手袋": "bag", "女包": "bag",
        "腰带": "belt", "皮带": "belt",
        "手套": "glove",
        "围巾": "scarf",
        "口罩": "mask", "面罩": "mask",
        "手表": "watch", "腕表": "watch", "智能手表": "watch",
        "戒指": "ring", "钻戒": "ring",
        "项链": "necklace",
        
        // MARK: - Kitchen & Dining
        "瓶子": "bottle", "水瓶": "bottle", "塑料瓶": "bottle",
        "红酒杯": "wine glass", "酒杯": "wine glass", "高脚杯": "wine glass",
        "杯子": "cup", "水杯": "cup", "茶杯": "cup", "马克杯": "cup", "咖啡杯": "cup",
        "叉子": "fork", "餐叉": "fork",
        "刀": "knife", "餐刀": "knife", "刀具": "knife", "水果刀": "knife",
        "勺子": "spoon", "汤勺": "spoon", "调羹": "spoon",
        "筷子": "chopsticks",
        "碗": "bowl", "饭碗": "bowl", "汤碗": "bowl",
        "盘子": "plate", "餐盘": "plate", "碟子": "plate",
        "平底锅": "pan", "炒锅": "pan", "煎锅": "pan",
        "锅": "pot", "汤锅": "pot", "炖锅": "pot",
        
        // MARK: - Food
        "香蕉": "banana",
        "苹果": "apple",
        "三明治": "sandwich",
        "橘子": "orange", "橙子": "orange", "柑橘": "orange",
        "西兰花": "broccoli", "花菜": "broccoli",
        "胡萝卜": "carrot",
        "披萨": "pizza", "比萨": "pizza",
        "甜甜圈": "donut",
        "蛋糕": "cake",
        
        // MARK: - Furniture & Home
        "椅子": "chair", "座椅": "chair", "凳子": "chair",
        "沙发": "couch", "单人沙发": "couch",
        "盆栽": "potted plant", "植物": "potted plant", "花盆": "potted plant",
        "床": "bed",
        "餐桌": "dining table", "桌子": "dining table", "饭桌": "dining table",
        "书桌": "dining table", "办公桌": "dining table",
        "马桶": "toilet", "厕所": "toilet",
        "电视": "tv", "电视机": "tv",
        "灯": "lamp", "台灯": "lamp",
        "枕头": "pillow",
        "毛巾": "towel",
        "垃圾桶": "trash can",
        "时钟": "clock", "钟": "clock", "挂钟": "clock",
        "花瓶": "vase",
        "镜子": "mirror",
        "窗帘": "curtain",
        "门": "door", "房门": "door",
        "架子": "shelf", "书架": "shelf", "置物架": "shelf",
        "箱子": "box", "盒子": "box", "快递盒": "box",
        
        // MARK: - Electronics & Gadgets
        "笔记本": "laptop", "电脑": "laptop", "笔记本电脑": "laptop", "本本": "laptop",
        "鼠标": "mouse",
        "遥控器": "remote", "遥控": "remote",
        "键盘": "keyboard",
        "手机": "cell phone", "电话": "cell phone", "智能手机": "cell phone", "爪机": "cell phone",
        "平板": "tablet", "iPad": "tablet",
        "显示器": "monitor", "屏幕": "monitor", "显示屏": "monitor",
        "照相机": "camera", "相机": "camera",
        "耳机": "headphones", "耳麦": "headphones", "头戴式耳机": "headphones",
        "耳塞": "headphones", "蓝牙耳机": "headphones",
        "音箱": "speaker", "扬声器": "speaker",
        "充电器": "charger", "充电头": "charger", "电源适配器": "charger",
        "插排": "power strip", "插座": "power strip", "排插": "power strip",
        "路由器": "router", "WiFi": "router",
        "打印机": "printer",
        
        // MARK: - Appliances
        "微波炉": "microwave",
        "烤箱": "oven",
        "烤面包机": "toaster",
        "水槽": "sink",
        "冰箱": "refrigerator", "冰柜": "refrigerator",
        "洗衣机": "washing machine",
        "风扇": "fan", "电风扇": "fan",
        "吹风机": "hair drier", "电吹风": "hair drier",
        
        // MARK: - Office & Stationery
        "书": "book", "书籍": "book", "课本": "book",
        "剪刀": "scissors",
        "笔": "pen", "钢笔": "pen", "圆珠笔": "pen", "水笔": "pen",
        "铅笔": "pencil",
        "笔记本本子": "notebook", "本子": "notebook", "记事本": "notebook",
        "尺子": "ruler", "直尺": "ruler",
        "订书机": "stapler",
        "胶带": "tape", "透明胶": "tape",
        "橡皮": "eraser", "橡皮擦": "eraser",
        
        // MARK: - Personal Care
        "牙刷": "toothbrush",
        "牙膏": "toothpaste",
        "肥皂": "soap", "香皂": "soap", "洗手液": "soap",
        "梳子": "comb",
        "纸巾": "tissue", "抽纸": "tissue", "餐巾纸": "tissue", "卷纸": "tissue",
        
        // MARK: - Tools & Daily Misc
        "钥匙": "key", "钥匙串": "key",
        "打火机": "lighter",
        "钱包": "wallet", "钱夹": "wallet",
        
        // MARK: - Toys
        "泰迪熊": "teddy bear", "玩偶": "teddy bear", "毛绒玩具": "teddy bear", "公仔": "teddy bear"
    ]
    
    static let colors: [String: String] = [
        "红": "red", "红色": "red",
        "绿": "green", "绿色": "green",
        "蓝": "blue", "蓝色": "blue",
        "黄": "yellow", "黄色": "yellow",
        "橙": "orange", "橙色": "orange",
        "紫": "purple", "紫色": "purple",
        "粉": "pink", "粉色": "pink",
        "黑": "black", "黑色": "black",
        "白": "white", "白色": "white",
        "灰": "gray", "灰色": "gray",
        "棕": "brown", "棕色": "brown",
        "金": "gold", "金色": "gold",
        "银": "silver", "银色": "silver",
        "米": "beige", "米色": "beige"
    ]
    
    // MARK: - Helper Methods
    
    static func getEnglishName(for chinese: String) -> String? {
        // 1. Direct Match
        if let english = mapping[chinese] {
            return english
        }
        
        // 2. Dynamic Color Parsing (e.g. "红色的杯子" -> "red cup")
        var detectedColor: String? = nil
        var detectedObject: String? = nil
        
        // Find longest matching color
        let sortedColors = colors.keys.sorted { $0.count > $1.count }
        for colorKey in sortedColors {
            if chinese.contains(colorKey) {
                detectedColor = colors[colorKey]
                break
            }
        }
        
        // Find longest matching object
        let sortedObjects = mapping.keys.sorted { $0.count > $1.count }
        for objectKey in sortedObjects {
            if chinese.contains(objectKey) {
                detectedObject = mapping[objectKey]
                break
            }
        }
        
        if let color = detectedColor, let object = detectedObject {
            // Check if object is a person-related term to use natural language phrasing
            let personTerms = ["person"]
            if personTerms.contains(object) {
                // Special case for person: "person in {color}"
                // Or "person in {color} clothes"
                return "\(object) in \(color)"
            } else {
                return "\(color) \(object)"
            }
        }
        
        // 3. Fallback: Contains Match
        // If no specific color+object combo found, try to find just the object
        // (This handles cases where the user types something complex but we only recognize the object)
        if let object = detectedObject {
            return object
        }
        
        return nil
    }
    
    // MARK: - Reverse Mapping Logic
    
    private static let preferredOverrides: [String: String] = [
        "mouse": "鼠标",        // Avoid "老鼠" (rat)
        "laptop": "笔记本电脑",  // Avoid slang "本本"
        "cell phone": "手机",    // Avoid slang "爪机"
        "tv": "电视",
        "car": "汽车",          // "车" is too generic
        "bicycle": "自行车",     // "单车" is also fine but "自行车" is more formal
        "notebook": "本子",      // Avoid "笔记本本子"
        "wallet": "钱包",       // Avoid "钱夹"
        "tissue": "纸巾"        // Avoid "抽纸"
    ]
    
    // Automatically generated reverse mapping (English -> Chinese)
    // Logic: Shortest Chinese word wins (usually most common/colloquial), unless overridden.
    private static let reverseMapping: [String: String] = {
        var map = [String: String]()
        
        // 1. Generate from mapping
        // Sort keys by length descending so that shorter keys overwrite longer ones
        let sortedKeys = mapping.keys.sorted {
            if $0.count != $1.count {
                return $0.count > $1.count
            }
            return $0 < $1 // Stable sort
        }
        
        for key in sortedKeys {
            if let value = mapping[key] {
                map[value.lowercased()] = key
            }
        }
        
        // 2. Apply overrides
        for (key, value) in preferredOverrides {
            map[key.lowercased()] = value
        }
        
        return map
    }()
    
    static func getChineseName(for englishName: String) -> String {
        let normalized = englishName.lowercased()
        return reverseMapping[normalized] ?? englishName
    }
}
