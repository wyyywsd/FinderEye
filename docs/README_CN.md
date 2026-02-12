<div align="center">

# 🔍 FinderEye

**将你的相机变成物理世界的搜索引擎**

[![Platform](https://img.shields.io/badge/平台-iOS%2017.0+-blue?style=flat-square&logo=apple)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0071E3?style=flat-square&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![Core ML](https://img.shields.io/badge/ML-Core%20ML-34C759?style=flat-square&logo=apple&logoColor=white)](https://developer.apple.com/machine-learning/core-ml/)
[![YOLO-World](https://img.shields.io/badge/模型-YOLO--World-FF6F00?style=flat-square)](https://github.com/AILab-CVC/YOLO-World)
[![License](https://img.shields.io/badge/许可证-All%20Rights%20Reserved-lightgrey?style=flat-square)](#-许可证)

[English](README_EN.md) | **中文**

</div>

---

## 📖 关于

**FinderEye** 是一款智能 iOS 应用程序，结合实时**光学字符识别 (OCR)** 与离线**开放词汇目标检测 (Open-Vocabulary Object Detection)**，帮助用户通过相机即时查找文本和物体。

采用极简美学设计，坚持**隐私至上**的原则 — 所有处理完全在设备端运行，快速、安全，无需互联网连接。

---

## ✨ 功能特性

| 功能 | 描述 |
|:-----|:-----|
| **🔎 实时搜索** | 即时检测并高亮显示相机视图中的文本和物体 |
| **📝 智能文本提取** | 从相机拍摄或相册导入图片，自动提取全部文字并保持原有排版 |
| **📐 文档透视矫正** | 支持四角自由拖拽与透视变换，自动拉直歪斜的文档图像 |
| **🤖 离线 AI** | 由在 Core ML 上运行的自定义 **YOLO-World** 模型驱动 |
| **🌐 智能翻译** | 支持中文自然语言查询（如 `红色的杯子` → `red cup`，`穿白衣的人` → `person in white`） |
| **🎨 极简 UI** | 无干扰界面，配合触觉反馈和流畅动画 |
| **🔒 隐私至上** | 零网络请求 — 数据不出设备，所有处理均在本地完成 |

---

## 🛠 技术栈

<table>
<tr>
<td><b>类别</b></td>
<td><b>技术</b></td>
</tr>
<tr>
<td><b>平台</b></td>
<td><img src="https://img.shields.io/badge/iOS-17.0+-000000?style=flat-square&logo=apple&logoColor=white" alt="iOS 17.0+"></td>
</tr>
<tr>
<td><b>语言</b></td>
<td><img src="https://img.shields.io/badge/Swift-5.9+-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 5.9+"></td>
</tr>
<tr>
<td><b>UI 框架</b></td>
<td><img src="https://img.shields.io/badge/SwiftUI-声明式%20UI-0071E3?style=flat-square&logo=swift&logoColor=white" alt="SwiftUI"></td>
</tr>
<tr>
<td><b>响应式</b></td>
<td><img src="https://img.shields.io/badge/Combine-数据流-8E44AD?style=flat-square&logo=apple&logoColor=white" alt="Combine"></td>
</tr>
<tr>
<td><b>相机</b></td>
<td><img src="https://img.shields.io/badge/AVFoundation-相机捕获-FF9500?style=flat-square&logo=apple&logoColor=white" alt="AVFoundation"></td>
</tr>
<tr>
<td><b>OCR</b></td>
<td><img src="https://img.shields.io/badge/Vision-文本识别-5856D6?style=flat-square&logo=apple&logoColor=white" alt="Vision"></td>
</tr>
<tr>
<td><b>图像处理</b></td>
<td><img src="https://img.shields.io/badge/Core%20Image-透视矫正-30B0C7?style=flat-square&logo=apple&logoColor=white" alt="Core Image"></td>
</tr>
<tr>
<td><b>ML 推理</b></td>
<td><img src="https://img.shields.io/badge/Core%20ML-设备端推理-34C759?style=flat-square&logo=apple&logoColor=white" alt="Core ML"></td>
</tr>
<tr>
<td><b>ML 模型</b></td>
<td><img src="https://img.shields.io/badge/YOLO--World-开放词汇检测-FF6F00?style=flat-square" alt="YOLO-World"></td>
</tr>
<tr>
<td><b>模型导出</b></td>
<td><img src="https://img.shields.io/badge/Python-Ultralytics%20%7C%20CoreMLTools-3776AB?style=flat-square&logo=python&logoColor=white" alt="Python"></td>
</tr>
</table>

---

## 🏗 项目架构

项目采用 **MVVM** 架构，模块化清晰：

```
FinderEye/
├── FinderEye/                    # App 源代码
│   ├── Sources/
│   │   ├── App/                  # App 入口 (FinderEyeApp.swift)
│   │   ├── Core/                 # 核心服务与工具
│   │   │   ├── Camera/           #   └─ 相机管理 (AVFoundation)
│   │   │   ├── Vision/           #   └─ OCR 服务 (Vision Framework)
│   │   │   └── Utils/            #   └─ 几何计算, 翻译映射, 设置
│   │   ├── Features/             # 功能模块
│   │   │   └── Home/             #   └─ 主相机界面 (MVVM)
│   │   │       ├── ViewModels/   #       └─ 检测 & OCR ViewModel
│   │   │       └── Views/        #       └─ SwiftUI 视图 & 覆盖层
│   │   └── Models/               # 数据模型与资源
│   │       └── Resources/        #   └─ Core ML 模型 (.mlpackage)
│   └── App-Info.plist            # App 配置文件
├── Scripts/                      # Python 模型导出脚本
├── docs/                         # 项目文档 (EN / CN)
├── requirements.txt              # Python 依赖项
└── FinderEye.xcodeproj           # Xcode 项目
```

---

## 🚀 快速开始

### 前置要求

| 要求 | 版本 |
|:-----|:-----|
| **Xcode** | 15.0+ |
| **iOS 设备** | iOS 17.0+（相机功能需要真机） |
| **Python** | 3.12+（*仅模型导出时需要*） |

### 安装与运行

```bash
# 1. 克隆仓库
git clone https://github.com/your-username/FinderEye.git
cd FinderEye

# 2. 用 Xcode 打开项目
open FinderEye.xcodeproj
```

**在 Xcode 中：**

1. 选择 `FinderEye` Target → **Signing & Capabilities** → 选择你的 **Team**
2. 连接 iPhone 并选择为运行目标
3. 构建并运行（**⌘ + R**）

> [!NOTE]
> 首次运行时，App 会请求相机权限。请允许以使用实时检测功能。

---

## 🧠 模型管理与导出

FinderEye 使用经过优化并导出为 **Core ML** 格式的 **YOLO-World** 模型。你可以使用提供的 Python 脚本自定义可识别的物体（词汇表）。

### 环境搭建与导出

```bash
# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 导出模型（如需要会自动下载基础模型）
python3 Scripts/export_model.py
```

### 自定义词汇表

编辑 `Scripts/export_model.py` 中的 `base_objects` 列表：

```python
base_objects = [
    "person", "bicycle", "car", ..., "your_new_object"
]
```

> [!IMPORTANT]
> 添加新物体后，请同步更新 `FinderEye/Sources/Core/Utils/ObjectTranslation.swift` 中的中文映射，以支持中文搜索。

导出脚本将执行以下操作：
1. 下载基础 YOLO-World 模型（如需要）
2. 嵌入自定义词汇表（类别）
3. 导出到 `FinderEye/Sources/Models/Resources/ObjectDetector.mlpackage`
4. 自动替换源代码目录中的旧模型

---

## 🗺 路线图

- [x] 实时 OCR 文本搜索
- [x] 开放词汇目标检测
- [x] 中文自然语言查询支持
- [x] 文档透视矫正
- [ ] 多语言查询支持
- [ ] 检测历史与收藏
- [ ] iPad 适配优化
- [ ] 小组件支持

---

## 📝 许可证

Copyright 2026 FinderEye. All rights reserved.
