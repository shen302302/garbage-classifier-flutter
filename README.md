# ♻️ 垃圾分类助手 - Garbage Classifier

基于 Ultralytics YOLO 的垃圾分类 Flutter 应用，支持拍照识别和相册选择，实时对垃圾进行分类。

## ✨ 功能特点

- **拍照识别** - 使用相机拍摄垃圾图片进行实时分类
- **相册选择** - 从相册选择图片进行识别
- **多分类支持** - 识别多种常见垃圾类别
- **置信度显示** - 显示每个识别结果的置信度
- **设置功能** - 置信度阈值调节、日志管理
- **跨平台** - 支持 Android 和 iOS

## 🚀 快速开始

### 环境要求

- Flutter >= 3.32.1
- Dart SDK >= 3.8.1
- Android Studio / Xcode

### 运行

```bash
cd example
flutter pub get
flutter run
```

### 构建 APK

```bash
cd example
flutter build apk --release
```

## 📱 使用说明

1. 打开应用，点击中心方框区域
2. 选择"拍照"或"从相册选择"
3. 等待模型识别完成
4. 查看识别结果和置信度

## 🗂️ 项目结构

```
lib/
├── pages/          # 页面
├── widgets/        # UI组件
├── services/       # 服务层
└── models/         # 数据模型
```

## 📄 许可证

本项目基于 AGPL-3.0 许可证开源。
