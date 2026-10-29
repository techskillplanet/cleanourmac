# FCM 推送调试接入实施计划

**Spec 引用：** `docs/prds/fcm-debug/specs/00-spec-index.md`  
**状态：** 已实现（2026-10-29）  
**说明：** 与 Cursor Plan `fcm_debug_feature` 对齐的仓库内副本；执行结果见下方验证。

## 验证证据

- `flutter test`：101 passed
- `flutter analyze`：仅 info 级提示（无 error）
- `flutter build macos`：本机无 `/Applications/Xcode.app`，桌面构建受阻；需安装完整 Xcode 后做 AC-10 手工验收

## 交付文件

见 Spec To-Be 与实现目录 `lib/data/fcm/`、`lib/features/fcm/`、`lib/providers/fcm_providers.dart`、侧栏/AppShell/l10n。
