# Plan 01 · scrcpy 外窗镜像按钮

- **Spec**: `docs/prds/device-screen-mirror/specs/`（confirmed）
- **complexity**: plan-required（数据层 + UI + l10n + 开盒路径）

## 步骤

1. [x] TDD：`ScrcpyClient.resolveBinary` / `launchMirror`（可注入 exists 与 start）
2. [x] Repository 暴露 `openScreenMirror(serial)`
3. [x] Android 卡片增加按钮与 action；l10n 中英
4. [x] `third_party/scrcpy/README.md` + 解析捆绑路径；本机 `brew install scrcpy` 验证
5. [x] `flutter test` 相关用例；重启 macOS 应用

## 验证

- AC-01～05；`test/scrcpy_client_test.dart` 通过
