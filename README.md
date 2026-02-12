<div align="center">

# 🔍 FinderEye

**Transform your camera into a powerful search engine for the physical world.**

[![Platform](https://img.shields.io/badge/Platform-iOS%2017.0+-blue?style=flat-square&logo=apple)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0071E3?style=flat-square&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![Core ML](https://img.shields.io/badge/ML-Core%20ML-34C759?style=flat-square&logo=apple&logoColor=white)](https://developer.apple.com/machine-learning/core-ml/)
[![YOLO-World](https://img.shields.io/badge/Model-YOLO--World-FF6F00?style=flat-square)](https://github.com/AILab-CVC/YOLO-World)
[![License](https://img.shields.io/badge/License-All%20Rights%20Reserved-lightgrey?style=flat-square)](#-license)

[English](docs/README_EN.md) | [中文](docs/README_CN.md)

<br/>

<!-- Add your app screenshots here -->
<!-- <img src="docs/assets/demo.gif" width="280" alt="FinderEye Demo"> -->

</div>

---

## 📖 About

**FinderEye** is an intelligent iOS application that combines real-time **Optical Character Recognition (OCR)** with offline **Open-Vocabulary Object Detection**, helping users instantly find text and objects through their camera.

Built with a minimalist aesthetic and a **privacy-first** approach, all processing runs entirely on-device — fast, secure, and fully functional without an internet connection.

> **FinderEye** 是一款智能 iOS 应用，结合实时 **OCR** 与离线**开放词汇目标检测**，将相机变为物理世界的搜索引擎。所有处理均在设备端完成，隐私至上。

---

## ✨ Features

| Feature | Description |
|:--------|:------------|
| **🔎 Real-time Search** | Instantly detect and highlight text & objects in the camera view |
| **📝 Text Extraction** | Extract full text from photos/camera with layout preservation |
| **📐 Perspective Crop** | Correct skewed documents using 4-corner perspective transformation |
| **🤖 Offline AI** | Powered by custom **YOLO-World** model running on **Core ML** |
| **🌐 Smart Translation** | Natural language queries in Chinese (e.g., `红色的杯子` → `red cup`) |
| **🎨 Minimalist UI** | Distraction-free interface with haptic feedback and fluid animations |
| **🔒 Privacy First** | Zero network requests — all processing stays on your device |

---

## 🛠 Tech Stack

<table>
<tr>
<td><b>Category</b></td>
<td><b>Technology</b></td>
</tr>
<tr>
<td><b>Platform</b></td>
<td><img src="https://img.shields.io/badge/iOS-17.0+-000000?style=flat-square&logo=apple&logoColor=white" alt="iOS 17.0+"></td>
</tr>
<tr>
<td><b>Language</b></td>
<td><img src="https://img.shields.io/badge/Swift-5.9+-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 5.9+"></td>
</tr>
<tr>
<td><b>UI Framework</b></td>
<td><img src="https://img.shields.io/badge/SwiftUI-Declarative%20UI-0071E3?style=flat-square&logo=swift&logoColor=white" alt="SwiftUI"></td>
</tr>
<tr>
<td><b>Reactive</b></td>
<td><img src="https://img.shields.io/badge/Combine-Data%20Flow-8E44AD?style=flat-square&logo=apple&logoColor=white" alt="Combine"></td>
</tr>
<tr>
<td><b>Camera</b></td>
<td><img src="https://img.shields.io/badge/AVFoundation-Camera%20Capture-FF9500?style=flat-square&logo=apple&logoColor=white" alt="AVFoundation"></td>
</tr>
<tr>
<td><b>OCR</b></td>
<td><img src="https://img.shields.io/badge/Vision-Text%20Recognition-5856D6?style=flat-square&logo=apple&logoColor=white" alt="Vision"></td>
</tr>
<tr>
<td><b>Image Processing</b></td>
<td><img src="https://img.shields.io/badge/Core%20Image-Perspective%20Correction-30B0C7?style=flat-square&logo=apple&logoColor=white" alt="Core Image"></td>
</tr>
<tr>
<td><b>ML Inference</b></td>
<td><img src="https://img.shields.io/badge/Core%20ML-On--Device%20ML-34C759?style=flat-square&logo=apple&logoColor=white" alt="Core ML"></td>
</tr>
<tr>
<td><b>ML Model</b></td>
<td><img src="https://img.shields.io/badge/YOLO--World-Open%20Vocabulary%20Detection-FF6F00?style=flat-square" alt="YOLO-World"></td>
</tr>
<tr>
<td><b>Model Export</b></td>
<td><img src="https://img.shields.io/badge/Python-Ultralytics%20%7C%20CoreMLTools-3776AB?style=flat-square&logo=python&logoColor=white" alt="Python"></td>
</tr>
</table>

---

## 🏗 Architecture

The project follows **MVVM** architecture with a clean modular structure:

```
FinderEye/
├── FinderEye/                    # App Source Code
│   ├── Sources/
│   │   ├── App/                  # App Entry Point (FinderEyeApp.swift)
│   │   ├── Core/                 # Core Services & Utilities
│   │   │   ├── Camera/           #   └─ Camera Management (AVFoundation)
│   │   │   ├── Vision/           #   └─ OCR Service (Vision Framework)
│   │   │   └── Utils/            #   └─ Geometry, Translation, Settings
│   │   ├── Features/             # Feature Modules
│   │   │   └── Home/             #   └─ Main Camera Interface (MVVM)
│   │   │       ├── ViewModels/   #       └─ Detection & OCR ViewModels
│   │   │       └── Views/        #       └─ SwiftUI Views & Overlays
│   │   └── Models/               # Data Models & Resources
│   │       └── Resources/        #   └─ Core ML Models (.mlpackage)
│   └── App-Info.plist            # App Configuration
├── Scripts/                      # Python Scripts for Model Export
├── docs/                         # Documentation (EN / CN)
├── requirements.txt              # Python Dependencies
└── FinderEye.xcodeproj           # Xcode Project
```

---

## 🚀 Getting Started

### Prerequisites

| Requirement | Version |
|:------------|:--------|
| **Xcode** | 15.0+ |
| **iOS Device** | iOS 17.0+ (Camera requires a physical device) |
| **Python** | 3.12+ *(only for model export)* |

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-username/FinderEye.git
cd FinderEye

# 2. Open in Xcode
open FinderEye.xcodeproj
```

**Then in Xcode:**

1. Select `FinderEye` Target → **Signing & Capabilities** → choose your **Team**
2. Connect your iPhone and select it as the run destination
3. Build and Run (**⌘ + R**)

> [!NOTE]
> The app will request camera permissions on first launch. Please allow it to enable real-time detection.

---

## 🧠 Model Management

FinderEye uses **YOLO-World** models exported to **Core ML** format. You can customize the detection vocabulary using the provided Python scripts.

### Setup & Export

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Export model (downloads base model if needed)
python3 Scripts/export_model.py
```

### Customize Vocabulary

Edit `Scripts/export_model.py` to modify the `base_objects` list:

```python
base_objects = [
    "person", "bicycle", "car", ..., "your_new_object"
]
```

> [!IMPORTANT]
> After adding new objects, update the Chinese mapping in `FinderEye/Sources/Core/Utils/ObjectTranslation.swift` to support Chinese search queries.

The export script will:
1. Download the base YOLO-World model (if needed)
2. Embed the custom vocabulary
3. Export to `FinderEye/Sources/Models/Resources/ObjectDetector.mlpackage`
4. Automatically replace the old model

---

## 🗺 Roadmap

- [x] Real-time OCR text search
- [x] Open-vocabulary object detection
- [x] Chinese natural language query support
- [x] Document perspective correction
- [ ] Multi-language query support
- [ ] Detection history & favorites
- [ ] iPad optimization
- [ ] Widget support

---

## 📝 License

Copyright © 2026 FinderEye. All rights reserved.

