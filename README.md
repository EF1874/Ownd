# 物历 (Device Manager)

一个基于 Flutter 开发的现代化物品管理应用，旨在帮助用户高效管理个人物品资产。

## ✨ 功能特性

-   **物品管理**：轻松添加、编辑和删除物品信息。
-   **分类管理**：支持自定义物品分类，内置多种常用分类。
-   **本地存储**：使用 Isar 数据库进行本地数据持久化，保护隐私。
-   **数据备份**：支持本地数据备份与恢复。
-   **响应式设计**：适配多种屏幕尺寸，支持高刷新率。
-   **多语言支持**：支持简体中文和英语。
-   **深色模式**：自动跟随系统主题切换深色/浅色模式。

## 🛠️ 技术栈

本项目采用现代化的 Flutter 开发架构：

-   **Framework**: [Flutter](https://flutter.dev/) (SDK >=3.10.0)
-   **Language**: [Dart](https://dart.dev/)
-   **State Management**: [Riverpod](https://riverpod.dev/) (with code generation)
-   **Database**: [Isar](https://isar.dev/)
-   **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
-   **UI Components**:
    -   [Flutter Animate](https://pub.dev/packages/flutter_animate) (动画)
    -   [Gap](https://pub.dev/packages/gap) (布局间距)
    -   [Flutter Slidable](https://pub.dev/packages/flutter_slidable) (侧滑操作)

## 🚀 本地开发

### 环境要求

-   Flutter SDK: `>=3.10.0 <4.0.0`
-   Dart SDK: 对应 Flutter 版本

### 启动步骤

1. **克隆项目**

    ```bash
    git clone https://github.com/EF1874/device-manage.git
    cd device-manage
    ```

2. **安装依赖**

    ```bash
    flutter pub get
    ```

3. **生成代码**

    本项目使用了 Riverpod 和 Isar 的代码生成功能，运行前必须执行：

    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

4. **运行项目**

    ```bash
    flutter run
    ```

## 📦 打包发布(目前仅有 Android 版本)

### Android

构建 Release 版本 APK：

```bash
flutter build apk --release
```

构建 App Bundle (Google Play):

```bash
flutter build appbundle --release
```

### iOS

构建 iOS 应用 (需要 macOS 环境):

```bash
flutter build ios --release
```

### Windows

构建 Windows 可执行文件:

```bash
flutter build windows --release
```

## 📂 项目结构

```
lib/
├── core/           # 核心功能 (主题, 常量, 工具类)
├── data/           # 数据层 (Repositories, Services, Models)
├── features/       # 业务功能模块 (按功能划分)
├── shared/         # 共享组件和工具
└── main.dart       # 应用入口
```

## 📄 License

This project is licensed under the MIT License.
