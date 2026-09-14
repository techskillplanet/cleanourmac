# Mobile 开发助手

一款本地优先的 macOS 移动研发工作台，集中管理：

- Android 真机、AVD、ADB Shell、Logcat、APK 安装与截图
- iOS Simulator 的启动、抹除、实时日志、`.app` 安装、截图、URL 与 RN 调测
- React Native 项目识别、Metro 监听、`yarn android`、`yarn ios`、`yarn charles` 等脚本快捷操作
- Claude Code、OpenCode、Trae、Qoder、Codex、Cursor 缓存检测与授权清理
- Flutter、Android、iOS、React Native、Web 项目的构建产物与工具缓存
- Dart Pub、Gradle、CocoaPods、SwiftPM、npm、Yarn、pnpm、Bun、Playwright、Cypress 等全局开发缓存
- Node Modules、大文件和磁盘空间
- 中英文界面以及可配置的安全清理规则

## 开发

```bash
flutter pub get
flutter run -d macos
```

生成品牌图标：

```bash
python3 scripts/generate_brand_assets.py
```

构建 DMG：

```bash
bash scripts/build_dmg.sh
```
