# FinderEye

**FinderEye** is an intelligent iOS application that transforms your camera into a powerful search engine for the physical world. It combines real-time **Optical Character Recognition (OCR)** with offline **Open-Vocabulary Object Detection** to help users find text and objects instantly.

Designed with a minimalist aesthetic and a privacy-first approach, FinderEye operates entirely on-device, making it fast, secure, and capable of working without an internet connection.

## ✨ Features

- **Real-time Search**: Instantly detect and highlight text and objects in the camera view.
- **Text Extraction**: Extract full text from photos/camera with layout preservation.
- **Perspective Crop**: Correct skewed documents using 4-corner perspective correction.
- **Offline AI**: Powered by a custom **YOLO-World** model running on Core ML for open-vocabulary detection.
- **Smart Translation**: Supports natural language queries in Chinese (e.g., "红色的杯子" maps to "red cup", "穿白衣的人" maps to "person in white").
- **Minimalist UI**: Distraction-free interface with haptic feedback and fluid animations.
- **Privacy First**: No data leaves your device; all processing is local.

## 🛠 Tech Stack

- **Platform**: iOS 17.0+
- **Language**: Swift 5.9+
- **Frameworks**:
  - **SwiftUI**: Modern, declarative user interface.
  - **Combine**: Reactive data flow for camera and search events.
  - **AVFoundation**: High-performance camera stream capture.
  - **Vision Framework**: Accurate text recognition (OCR).
  - **Core Image**: Image perspective correction using `CIPerspectiveCorrection`.
  - **Core ML**: On-device machine learning inference.
- **Machine Learning**:
  - **Model**: YOLO-World (Real-time Open-Vocabulary Object Detection).
  - **Export Tool**: Python, Ultralytics, CoreMLTools.

## 📂 Project Structure

```
FinderEye/
├── FinderEye/               # App Source Code Directory
│   ├── Sources/
│   │   ├── App/             # App Entry Point (FinderEyeApp.swift)
│   │   ├── Core/            # Core Services and Utilities
│   │   │   ├── Camera/      # Camera Management (AVFoundation)
│   │   │   ├── Vision/      # OCR Service (Vision Framework)
│   │   │   └── Utils/       # Geometry, Translation, Settings
│   │   ├── Features/        # Feature Modules
│   │   │   └── Home/        # Main Camera Interface (MVVM)
│   │   └── Models/          # Data Models and Resources
│   │       └── Resources/   # Core ML Model Files (.mlpackage)
│   └── App-Info.plist       # App Configuration
├── Scripts/                 # Python Scripts for Model Management
├── docs/                    # Documentation
└── requirements.txt         # Python Dependencies
```

## 🚀 Getting Started

### Prerequisites

- **Xcode 15.0+**
- **iOS Device** running iOS 17.0+ (Camera features do not work on Simulator)
- **Python 3.12+** (Only required for model updates)

### Installation & Running

1.  **Open Project**:
    - Double-click `FinderEye/FinderEye.xcodeproj` in the root directory.

2.  **Configure Signing**:
    - Select the `FinderEye` project root in Xcode.
    - Select `FinderEye` Target -> **Signing & Capabilities**.
    - Select your **Team** to enable signing.

3.  **Run**:
    - Connect your iPhone.
    - Select your device in Xcode.
    - Build and Run (**Cmd + R**).

> **Note**: The app will request camera permissions on first run. Please allow it to use real-time detection features.

## 🧠 Model Management & Export

The app uses a YOLO-World model that has been optimized and exported to Core ML. You can customize the recognized objects (vocabulary) using the provided scripts.

### 1. Setup Python Environment

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Customize Vocabulary

Open `Scripts/export_model.py` and modify the `common_objects` list or the color combinations.

```python
# Example: Adding a new object
common_objects = [
    "person", "bicycle", "car", ..., "new_object_name"
]
```

**Note**: If you add new objects, remember to update the Chinese mapping in `FinderEye/Sources/Core/Utils/ObjectTranslation.swift` to support searching for them in Chinese.

### 3. Export Model

Run the export script to generate a new Core ML model:

```bash
python3 Scripts/export_model.py
```

This will:
1.  Download the base YOLO-World model (if needed).
2.  Embed the custom vocabulary (classes).
3.  Export the model to `FinderEye/Sources/Models/Resources/ObjectDetector.mlpackage`.
4.  Automatically replace the old model in the source directory.

## 📝 License

Copyright © 2026 FinderEye. All rights reserved.
