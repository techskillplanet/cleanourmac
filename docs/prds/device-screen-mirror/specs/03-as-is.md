# 03 · As-Is

- **Status**: confirmed
- **Evidence**: `android_emulator_panel.dart`、`android_emulator_client.dart` captureScreenshot

设备调测 Android 面板对 running 设备提供 Shell、Logcat、安装 APK、截图与导航键；截图为 `adb screencap` 落盘。无投屏、无 scrcpy 集成。
