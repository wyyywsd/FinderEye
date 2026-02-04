# FinderEye

**FinderEye** 是一款智能 iOS 应用程序，它将您的相机变成一个强大的物理世界搜索引擎。它结合了实时**光学字符识别 (OCR)** 和离线**开放词汇目标检测 (Open-Vocabulary Object Detection)**，帮助用户即时查找文本和物体。

FinderEye 采用极简美学设计，坚持隐私至上的原则，所有操作完全在设备端运行，快速、安全，并且无需互联网连接即可工作。

## ✨ 功能特性

- **实时搜索**：即时检测并高亮显示相机视图中的文本和物体。
- **智能文本提取**：从相机拍摄或相册导入图片，自动提取全部文字并保持原有排版。
- **文档透视矫正**：支持四角自由拖拽与透视变换，自动拉直歪斜的文档图像，提升识别准确率。
- **离线 AI**：由在 Core ML 上运行的自定义 **YOLO-World** 模型驱动，支持开放词汇检测。
- **智能翻译**：支持中文自然语言查询（例如，“红色的杯子” 映射为 “red cup”，“穿白衣的人” 映射为 “person in white”）。
- **极简 UI**：无干扰的界面，配合触觉反馈和流畅的动画。
- **隐私至上**：数据不出设备，所有处理均在本地完成。

## 🛠 技术栈

- **平台**: iOS 17.0+
- **语言**: Swift 5.9+
- **框架**:
  - **SwiftUI**: 现代化的声明式用户界面。
  - **Combine**: 用于处理相机和搜索事件的响应式数据流。
  - **AVFoundation**: 高性能相机流捕获。
  - **Vision Framework**: 精确的文本识别 (OCR)。
  - **Core Image**: 使用 `CIPerspectiveCorrection` 进行图像透视矫正。
  - **Core ML**: 设备端机器学习推理。
- **机器学习**:
  - **模型**: YOLO-World (实时开放词汇目标检测)。
  - **导出工具**: Python, Ultralytics, CoreMLTools。

## 📂 项目结构

```
FinderEye/
├── FinderEye/               # App 源代码目录
│   ├── Sources/
│   │   ├── App/             # App 入口 (FinderEyeApp.swift)
│   │   ├── Core/            # 核心服务和工具
│   │   │   ├── Camera/      # 相机管理 (AVFoundation)
│   │   │   ├── Vision/      # OCR 服务 (Vision Framework)
│   │   │   └── Utils/       # 几何计算, 翻译映射, 设置
│   │   ├── Features/        # 功能模块
│   │   │   └── Home/        # 主相机界面 (MVVM)
│   │   └── Models/          # 数据模型和资源
│   │       └── Resources/   # Core ML 模型文件 (.mlpackage)
│   └── App-Info.plist       # App 配置文件
├── Scripts/                 # 用于模型管理的 Python 脚本
├── docs/                    # 项目文档
└── requirements.txt         # Python 依赖项
```

## 🚀 快速开始

### 前置要求

- **Xcode 15.0+**
- **iOS 设备** 运行 iOS 17.0+ (相机功能无法在模拟器上运行)
- **Python 3.12+** (仅在需要更新模型时需要)

### 安装与运行

1.  **打开项目**：
    - 双击打开根目录下的 `FinderEye/FinderEye.xcodeproj`。

2.  **配置签名**：
    - 在 Xcode 中选择 `FinderEye` 项目根节点。
    - 选择 `FinderEye` Target -> **Signing & Capabilities**。
    - 选择您的 **Team** 以启用签名。

3.  **运行**：
    - 连接您的 iPhone。
    - 在 Xcode 中选择您的设备。
    - 构建并运行 (**Cmd + R**)。

> **注意**：首次运行时，App 会请求相机权限。请允许以使用实时检测功能。

## 🧠 模型管理与导出

该 App 使用经过优化并导出为 Core ML 格式的 YOLO-World 模型。您可以使用提供的脚本自定义可识别的物体（词汇表）。

### 1. 设置 Python 环境

```bash
# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt
```

### 2. 自定义词汇表

打开 `Scripts/export_model.py` 并修改 `common_objects` 列表或颜色组合。

```python
# 示例：添加一个新物体
common_objects = [
    "person", "bicycle", "car", ..., "new_object_name"
]
```

**注意**：如果您添加了新物体，请记得更新 `FinderEye/Sources/Core/Utils/ObjectTranslation.swift` 中的中文映射，以支持中文搜索。

### 3. 导出模型

运行导出脚本以生成新的 Core ML 模型：

```bash
python3 Scripts/export_model.py
```

这将执行以下操作：
1.  下载基础 YOLO-World 模型（如果需要）。
2.  嵌入自定义词汇表（类别）。
3.  将模型导出到 `FinderEye/Sources/Models/Resources/ObjectDetector.mlpackage`。
4.  自动替换源代码目录中的旧模型。

## 📝 许可证

Copyright © 2026 FinderEye. All rights reserved.
