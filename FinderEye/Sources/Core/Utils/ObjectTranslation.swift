import Foundation

struct ObjectTranslation {
    static let mapping: [String: String] = [
        // MARK: - People & Demographics
        "人": "person", "行人": "person", "人类": "person",
        "男人": "man", "男": "man", "男士": "man",
        "女人": "woman", "女": "woman", "女士": "woman",
        "孩子": "child", "儿童": "child", "小孩": "child",
        "男孩": "boy", "男生": "boy",
        "女孩": "girl", "女生": "girl",
        "婴儿": "baby", "宝宝": "baby",
        "老人": "elderly person", "老奶奶": "elderly person", "老爷爷": "elderly person",
        "脸": "face", "人脸": "face", "脸蛋": "face",
        "头": "head", "脑袋": "head", "人头": "head", "头部": "head",
        "手": "hand", "小手": "hand",
        "脚": "foot", "小脚": "foot", "脚丫": "foot",
        
        // MARK: - Transport & Vehicles
        "自行车": "bicycle", "单车": "bicycle", "脚踏车": "bicycle", "车子": "bicycle",
        "汽车": "car", "轿车": "car", "车": "car", "小汽车": "car", "座驾": "car",
        "摩托车": "motorcycle", "摩托": "motorcycle",
        "飞机": "airplane", "民航客机": "airplane",
        "公交车": "bus", "巴士": "bus", "公共汽车": "bus", "大巴": "bus", "大巴车": "bus",
        "火车": "train", "列车": "train", "高铁": "train", "动车": "train",
        "火车门": "train door", "车门": "train door",
        "开着的火车门": "open train door", "开着的车门": "open train door",
        "关闭的火车门": "closed train door", "关闭的车门": "closed train door",
        "卡车": "truck", "货车": "truck", "大货车": "truck",
        "船": "boat", "小船": "boat", "轮船": "boat", "游艇": "boat",
        "滑板车": "scooter", "电动车": "scooter", "电瓶车": "scooter", "小毛驴": "scooter",
        "面包车": "van", "厢式货车": "van",
        "越野车": "suv",
        "出租车": "taxi", "的士": "taxi",
        "警车": "police car",
        "救护车": "ambulance",
        "消防车": "fire truck",
        "轮椅": "wheelchair",
        "婴儿车": "stroller",
        "滑板": "skateboard",
        "冲浪板": "surfboard",
        
        // MARK: - Traffic & Street
        "红绿灯": "traffic light", "信号灯": "traffic light", "交通灯": "traffic light",
        "消防栓": "fire hydrant",
        "停车标志": "stop sign", "停车牌": "stop sign",
        "停车计时器": "parking meter",
        "长椅": "bench",
        "路灯": "street light",
        "斑马线": "crosswalk", "人行横道": "crosswalk",
        "路牌": "road sign", "交通标志": "road sign",
        
        // MARK: - Animals
        "鸟": "bird", "小鸟": "bird",
        "猫": "cat", "猫咪": "cat", "小猫": "cat", "喵星人": "cat",
        "狗": "dog", "狗狗": "dog", "小狗": "dog", "汪星人": "dog", "狗子": "dog",
        "马": "horse", "骏马": "horse",
        "羊": "sheep", "绵羊": "sheep", "山羊": "sheep",
        "牛": "cow", "奶牛": "cow", "黄牛": "cow",
        "大象": "elephant",
        "熊": "bear", "黑熊": "bear", "棕熊": "bear",
        "斑马": "zebra",
        "长颈鹿": "giraffe",
        "兔子": "rabbit",
        "老鼠": "mouse",
        "鸡": "chicken", "公鸡": "chicken", "母鸡": "chicken",
        "鸭": "duck", "鸭子": "duck",
        "鹅": "goose",
        "猪": "pig",
        "猴子": "monkey",
        "松鼠": "squirrel",
        "鱼": "fish",
        "昆虫": "insect", "虫子": "insect",
        "蜘蛛": "spider",
        "蛇": "snake",
        "蜥蜴": "lizard",
        "乌龟": "turtle", "海龟": "turtle",
        
        // MARK: - Accessories & Personal Items
        "背包": "backpack", "书包": "backpack", "双肩包": "backpack",
        "雨伞": "umbrella", "伞": "umbrella",
        "手提包": "handbag", "包": "handbag", "挎包": "handbag", "皮包": "handbag",
        "领带": "tie", "领结": "tie",
        "手提箱": "suitcase", "行李箱": "suitcase", "旅行箱": "suitcase",
        "钱包": "wallet", "钱夹": "wallet",
        "手袋": "purse", "女包": "purse",
        "眼镜": "glasses", "近视镜": "glasses",
        "墨镜": "sunglasses", "太阳镜": "sunglasses",
        "帽子": "hat", "礼帽": "hat",
        "鸭舌帽": "cap", "棒球帽": "cap",
        "头盔": "helmet", "安全帽": "helmet",
        "口罩": "mask", "面罩": "mask",
        "手套": "glove",
        "围巾": "scarf",
        "腰带": "belt", "皮带": "belt",
        "手表": "watch", "腕表": "watch",
        "戒指": "ring", "钻戒": "ring",
        "项链": "necklace",
        "耳环": "earrings", "耳钉": "earrings",
        "手链": "bracelet", "手镯": "bracelet",
        "鞋": "shoes", "鞋子": "shoes", "皮鞋": "shoes",
        "运动鞋": "sneakers", "球鞋": "sneakers", "跑鞋": "sneakers",
        "靴子": "boots", "马丁靴": "boots",
        "凉鞋": "sandals",
        "拖鞋": "slippers",
        "人字拖": "flip flops",
        "高跟鞋": "high heels",
        "袜子": "socks", "短袜": "socks", "长袜": "socks",
        
        // MARK: - Sports & Recreation
        "飞盘": "frisbee",
        "滑雪板": "skis", "双板": "skis",
        "单板滑雪": "snowboard", "单板": "snowboard",
        "球": "sports ball",
        "篮球": "basketball",
        "足球": "soccer ball",
        "橄榄球": "football",
        "网球": "tennis ball",
        "棒球": "baseball",
        "排球": "volleyball",
        "风筝": "kite",
        "棒球棒": "baseball bat",
        "棒球手套": "baseball glove",
        "网球拍": "tennis racket", "球拍": "tennis racket",
        "羽毛球拍": "badminton racket",
        "乒乓球拍": "ping pong paddle",
        
        // MARK: - Kitchen & Dining
        "瓶子": "bottle", "水瓶": "bottle", "塑料瓶": "bottle",
        "红酒杯": "wine glass", "酒杯": "wine glass", "高脚杯": "wine glass",
        "杯子": "cup", "水杯": "cup", "茶杯": "cup",
        "马克杯": "mug", "咖啡杯": "mug",
        "保温杯": "thermos",
        "叉子": "fork", "餐叉": "fork",
        "刀": "knife", "餐刀": "knife", "刀具": "knife", "水果刀": "knife",
        "勺子": "spoon", "汤勺": "spoon", "调羹": "spoon",
        "筷子": "chopsticks",
        "碗": "bowl", "饭碗": "bowl", "汤碗": "bowl",
        "盘子": "plate", "餐盘": "plate",
        "碟子": "dish",
        "水壶": "kettle", "烧水壶": "kettle",
        "锅": "pot", "汤锅": "pot",
        "平底锅": "pan", "炒锅": "pan",
        "托盘": "tray",
        
        // MARK: - Food & Drink
        "香蕉": "banana",
        "苹果": "apple",
        "三明治": "sandwich",
        "橘子": "orange", "橙子": "orange", "柑橘": "orange",
        "西兰花": "broccoli", "花菜": "broccoli",
        "胡萝卜": "carrot",
        "热狗": "hot dog", "香肠": "hot dog",
        "披萨": "pizza", "比萨": "pizza",
        "甜甜圈": "donut",
        "蛋糕": "cake",
        "水果": "fruit",
        "蔬菜": "vegetable",
        "面包": "bread",
        "鸡蛋": "egg",
        "肉": "meat",
        "鱼肉": "fish",
        "米饭": "rice",
        "面条": "noodle",
        "糖果": "candy",
        "饼干": "cookie",
        "巧克力": "chocolate",
        "冰淇淋": "ice cream", "雪糕": "ice cream",
        "饮料": "drink",
        "咖啡": "coffee",
        "茶": "tea",
        "水": "water", "矿泉水": "water",
        "果汁": "juice",
        "啤酒": "beer",
        "酒": "wine", "红酒": "wine",
        
        // MARK: - Furniture & Home
        "椅子": "chair", "座椅": "chair",
        "沙发": "couch",
        "单人沙发": "armchair",
        "凳子": "stool",
        "盆栽": "potted plant", "植物": "potted plant", "花盆": "potted plant",
        "床": "bed",
        "餐桌": "dining table", "桌子": "dining table", "饭桌": "dining table",
        "书桌": "desk", "办公桌": "desk",
        "柜子": "cabinet",
        "架子": "shelf", "书架": "shelf",
        "衣柜": "wardrobe",
        "马桶": "toilet", "厕所": "toilet",
        "电视": "tv", "电视机": "tv",
        "灯": "lamp", "台灯": "lamp",
        "镜子": "mirror",
        "地毯": "carpet",
        "窗帘": "curtain",
        "枕头": "pillow",
        "毯子": "blanket", "被子": "blanket",
        "毛巾": "towel",
        "垃圾桶": "trash can",
        "箱子": "box", "盒子": "box",
        "篮子": "basket",
        "时钟": "clock", "钟": "clock", "挂钟": "clock",
        "花瓶": "vase",
        
        // MARK: - Electronics & Gadgets
        "笔记本": "laptop", "电脑": "laptop", "笔记本电脑": "laptop", "本本": "laptop",
        "鼠标": "mouse",
        "遥控器": "remote", "遥控": "remote",
        "键盘": "keyboard",
        "手机": "cell phone", "电话": "cell phone", "智能手机": "cell phone", "爪机": "cell phone",
        "平板": "tablet", "iPad": "tablet",
        "显示器": "monitor", "屏幕": "monitor", "显示屏": "monitor",
        "照相机": "camera", "相机": "camera",
        "镜头": "lens",
        "三脚架": "tripod",
        "耳机": "headphones", "耳麦": "headphones", "头戴式耳机": "headphones", "耳机子": "headphones",
        "耳塞": "earbuds", "蓝牙耳机": "earbuds",
        "音箱": "speaker", "扬声器": "speaker",
        "麦克风": "microphone", "话筒": "microphone",
        "打印机": "printer",
        "扫描仪": "scanner",
        "路由器": "router", "WiFi": "router",
        "游戏手柄": "game controller", "手柄": "game controller",
        "游戏机": "console",
        "充电器": "charger", "电源适配器": "charger", "充电头": "charger",
        "充电宝": "power bank", "移动电源": "power bank",
        "线": "cable", "数据线": "cable", "充电线": "cable", "电线": "cable", "网线": "cable",
        "U盘": "usb drive", "优盘": "usb drive",
        "SD卡": "sd card", "存储卡": "sd card", "内存卡": "sd card",
        "电池": "battery", "干电池": "battery",
        "智能手表": "smart watch",
        "计算器": "calculator",
        
        // MARK: - Appliances
        "微波炉": "microwave",
        "烤箱": "oven",
        "烤面包机": "toaster",
        "水槽": "sink",
        "冰箱": "refrigerator", "冰柜": "refrigerator",
        "洗衣机": "washing machine",
        "烘干机": "dryer",
        "洗碗机": "dishwasher",
        "风扇": "fan", "电风扇": "fan",
        "空调": "air conditioner",
        "取暖器": "heater", "暖气": "heater",
        "吸尘器": "vacuum cleaner",
        "吹风机": "hair drier", "电吹风": "hair drier",
        "熨斗": "iron",
        "搅拌机": "blender", "破壁机": "blender",
        "咖啡机": "coffee maker",
        
        // MARK: - Office & Stationery
        "书": "book", "书籍": "book", "课本": "book",
        "笔记本本子": "notebook", "本子": "notebook", "记事本": "notebook",
        "纸": "paper", "文件": "paper", "A4纸": "paper",
        "笔": "pen", "钢笔": "pen", "圆珠笔": "pen", "水笔": "pen",
        "铅笔": "pencil",
        "记号笔": "marker",
        "橡皮": "eraser",
        "订书机": "stapler",
        "剪刀": "scissors",
        "胶带": "tape", "透明胶": "tape",
        "胶水": "glue", "强力胶": "glue",
        "回形针": "clip", "夹子": "clip",
        "文件夹": "folder",
        "信封": "envelope",
        
        // MARK: - Tools & Hardware
        "锤子": "hammer",
        "螺丝刀": "screwdriver", "改锥": "screwdriver",
        "扳手": "wrench",
        "钳子": "pliers",
        "锯子": "saw",
        "电钻": "drill",
        "梯子": "ladder",
        "手电筒": "flashlight",
        "锁": "lock",
        "钥匙": "key", "钥匙串": "key",
        "链子": "chain", "锁链": "chain",
        "绳子": "rope",
        
        // MARK: - Medical & Health
        "药": "medicine", "药品": "medicine",
        "药丸": "pill",
        "药瓶": "bottle",
        "注射器": "syringe",
        "温度计": "thermometer", "体温计": "thermometer",
        "绷带": "bandage",
        "拐杖": "crutch", "手杖": "cane",
        "助行器": "walker",
        
        // MARK: - Small Items & Others
        "牙签": "toothpick",
        "餐巾纸": "napkin", "纸巾": "tissue", "抽纸": "tissue", "手帕纸": "tissue",
        "打火机": "lighter",
        "火柴": "matchbox", "火柴盒": "matchbox",
        "香烟": "cigarette", "烟": "cigarette",
        "硬币": "coin", "零钱": "coin",
        "纽扣": "button", "扣子": "button",
        "拉链": "zipper", "拉锁": "zipper",
        "针": "needle",
        "线团": "thread",
        "玩具": "toy",
        "娃娃": "doll",
        "泰迪熊": "teddy bear", "玩偶": "teddy bear", "毛绒玩具": "teddy bear", "公仔": "teddy bear",
        "气球": "balloon",
        "旗帜": "flag", "国旗": "flag",
        
        // MARK: - Bathroom & Personal Care
        "牙刷": "toothbrush",
        "牙膏": "toothpaste",
        "肥皂": "soap", "香皂": "soap",
        "洗发水": "shampoo", "洗发露": "shampoo",
        "护发素": "conditioner",
        "梳子": "comb",
        "发刷": "hairbrush",
        "剃须刀": "razor", "刮胡刀": "razor",
        "浴缸": "bathtub",
        "淋浴": "shower", "花洒": "shower",
        "卫生纸": "toilet paper", "卷纸": "toilet paper", "手纸": "toilet paper",
        "毛巾架": "towel rack",
        
        // MARK: - Bedroom & Bedding
        "床垫": "mattress",
        "床单": "sheet",
        "棉被": "quilt",
        "羽绒被": "duvet",
        "床头柜": "nightstand",
        
        // MARK: - Clothing & Fashion
        "衬衫": "shirt", "衬衣": "shirt",
        "T恤": "t-shirt", "短袖": "t-shirt",
        "裤子": "pants",
        "长裤": "trousers",
        "牛仔裤": "jeans",
        "短裤": "shorts",
        "裙子": "skirt", "短裙": "skirt",
        "连衣裙": "dress", "长裙": "dress",
        "外套": "coat", "大衣": "coat",
        "夹克": "jacket",
        "毛衣": "sweater", "针织衫": "sweater",
        "背心": "vest", "马甲": "vest",
        "西装": "suit", "西服": "suit",
        "泳衣": "swimsuit", "泳裤": "swimsuit",
        "睡衣": "pajamas",
        "内衣": "underwear", "内裤": "underwear",
        "文胸": "bra",
        
        // MARK: - Musical Instruments
        "吉他": "guitar",
        "小提琴": "violin",
        "钢琴": "piano",
        "鼓": "drum",
        "长笛": "flute",
        "小号": "trumpet",
        "萨克斯": "saxophone",
        "大提琴": "cello",
        
        // MARK: - Cleaning & Chores
        "扫帚": "broom", "扫把": "broom",
        "拖把": "mop",
        "桶": "bucket", "水桶": "bucket",
        "簸箕": "dustpan",
        "海绵": "sponge",
        "洗洁精": "detergent", "洗衣液": "detergent",
        "脏衣篮": "laundry basket",
        
        // MARK: - Nature & Outdoors
        "树": "tree", "大树": "tree", "树木": "tree",
        "草": "grass", "草地": "grass",
        "花": "flower", "花朵": "flower",
        "石头": "rock", "石块": "stone",
        "山": "mountain", "高山": "mountain",
        "云": "cloud", "云朵": "cloud",
        "太阳": "sun",
        "月亮": "moon",
        "星星": "star",
        "河": "river", "河流": "river",
        "湖": "lake", "湖泊": "lake",
        "海": "ocean", "大海": "ocean", "海洋": "ocean",
        "沙滩": "beach",
        "森林": "forest", "树林": "forest"
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
            let personTerms = ["person", "man", "woman", "child", "boy", "girl", "baby"]
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
}
