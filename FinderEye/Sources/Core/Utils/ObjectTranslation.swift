import Foundation

struct ObjectTranslation {
     static let mapping: [String: String] = [
        // COCO Classes
        "人": "person", "行人": "person",
        "自行车": "bicycle", "单车": "bicycle",
        "汽车": "car", "轿车": "car", "车": "car",
        "摩托车": "motorcycle",
        "飞机": "airplane",
        "公交车": "bus", "巴士": "bus",
        "火车": "train",
        "卡车": "truck", "货车": "truck",
        "船": "boat",
        "红绿灯": "traffic light", "信号灯": "traffic light",
        "消防栓": "fire hydrant",
        "停车标志": "stop sign",
        "停车计时器": "parking meter",
        "长椅": "bench", "椅子": "chair",
        "鸟": "bird",
        "猫": "cat", "猫咪": "cat",
        "狗": "dog", "狗狗": "dog",
        "马": "horse",
        "羊": "sheep",
        "牛": "cow",
        "大象": "elephant",
        "熊": "bear",
        "斑马": "zebra",
        "长颈鹿": "giraffe",
        "背包": "backpack", "书包": "backpack",
        "雨伞": "umbrella", "伞": "umbrella",
        "手提包": "handbag", "包": "handbag",
        "领带": "tie",
        "手提箱": "suitcase", "行李箱": "suitcase",
        "飞盘": "frisbee",
        "滑雪板": "skis", "单板滑雪": "snowboard",
        "球": "sports ball", "篮球": "sports ball", "足球": "sports ball",
        "风筝": "kite",
        "棒球棒": "baseball bat",
        "棒球手套": "baseball glove",
        "滑板": "skateboard",
        "冲浪板": "surfboard",
        "网球拍": "tennis racket",
        "瓶子": "bottle", "水瓶": "bottle",
        "红酒杯": "wine glass", "酒杯": "wine glass",
        "杯子": "cup", "水杯": "cup",
        "叉子": "fork",
        "刀": "knife",
        "勺子": "spoon",
        "碗": "bowl",
        "香蕉": "banana",
        "苹果": "apple",
        "三明治": "sandwich",
        "橘子": "orange", "橙子": "orange",
        "西兰花": "broccoli",
        "胡萝卜": "carrot",
        "热狗": "hot dog",
        "披萨": "pizza",
        "甜甜圈": "donut",
        "蛋糕": "cake",
        "沙发": "couch",
        "盆栽": "potted plant", "植物": "potted plant",
        "床": "bed",
        "餐桌": "dining table", "桌子": "dining table",
        "马桶": "toilet", "厕所": "toilet",
        "电视": "tv", "显示器": "tv",
        "笔记本": "laptop", "电脑": "laptop",
        "鼠标": "mouse",
        "遥控器": "remote",
        "键盘": "keyboard",
        "手机": "cell phone", "电话": "cell phone",
        "微波炉": "microwave",
        "烤箱": "oven",
        "烤面包机": "toaster",
        "水槽": "sink",
        "冰箱": "refrigerator",
        "书": "book", "书籍": "book",
        "时钟": "clock", "钟": "clock",
        "花瓶": "vase",
        "剪刀": "scissors",
        "泰迪熊": "teddy bear", "玩偶": "teddy bear",
        "吹风机": "hair drier",
        "牙刷": "toothbrush",
        
        // Additional Common Items
        "钥匙": "keys",
        "钱包": "wallet",
        "信用卡": "credit card", "银行卡": "credit card",
        "钱": "money", "钞票": "money",
        "笔": "pen", "钢笔": "pen",
        "铅笔": "pencil",
        "纸": "paper",
        "笔记本本子": "notebook",
        "眼镜": "glasses",
        "墨镜": "sunglasses", "太阳镜": "sunglasses",
        "帽子": "hat", "鸭舌帽": "cap",
        "鞋": "shoes", "鞋子": "shoes",
        "运动鞋": "sneakers",
        "靴子": "boots",
        "手表": "watch",
        "戒指": "ring",
        "项链": "necklace",
        "耳环": "earrings",
        "水壶": "water bottle",
        "马克杯": "coffee mug",
        "耳机": "headphones",
        "充电器": "charger",
        "充电宝": "power bank", "移动电源": "power bank",
        "线": "cable", "数据线": "cable",
        "门": "door",
        "窗户": "window", "窗": "window",
        "地板": "floor",
        "天花板": "ceiling",
        
        // Small Items
        "牙签": "toothpick",
        "餐巾纸": "napkin", "纸巾": "tissue",
        "打火机": "lighter",
        "火柴": "matchbox",
        "订书机": "stapler",
        "胶带": "tape",
        "胶水": "glue",
        "电池": "battery",
        "U盘": "usb drive",
        "SD卡": "sd card",
        "SIM卡": "sim card",
        "硬币": "coin",
        "纽扣": "button",
        "拉链": "zipper",
        "口罩": "mask",
        "手套": "glove",
        "袜子": "sock"
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
        "棕": "brown", "棕色": "brown"
    ]
    
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
            if object == "person" {
                // Special case for person: "person in {color}"
                // Or "person in {color} clothes"
                return "person in \(color)"
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
}
