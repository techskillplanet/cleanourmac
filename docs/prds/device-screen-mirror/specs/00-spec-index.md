# Spec Index · 设备调测 · 手机屏幕镜像

- **PRD**: `device-screen-mirror`
- **Status**: confirmed（用户 2026-10-30 确认：开窗开盒 + 按钮启动）
- **Created**: 2026-10-30

## 范围

在「设备调测」Android 已连接设备上提供 **scrcpy 外窗镜像**：一点击打开独立投屏窗口；运行件优先捆绑/本机可解析路径，用户无需另行理解 scrcpy 用法。

## 文档地图

| 序号 | 文档 | 状态 |
|------|------|------|
| 00 | `00-spec-index.md` | confirmed |
| 01 | `01-background-and-goal.md` | confirmed |
| 02 | `02-acceptance-criteria.md` | confirmed |
| 03 | `03-as-is.md` | confirmed |
| 04 | `04-to-be.md` | confirmed |

## 已确认决策

1. **呈现**：独立 scrcpy 外窗（不嵌入 Flutter）。
2. **开盒**：`tool/bundle_scrcpy.sh` 生成可重定位 scrcpy（含 dylib + server），构建时嵌入 `.app/Contents/Resources/scrcpy/`；运行时优先捆绑，回退 Homebrew/PATH。构建机仍需一次 `brew install scrcpy` 以打包；**终端用户安装助手后无需再装 scrcpy**（仍需 ADB/已连接设备）。
3. **入口**：运行中设备卡片增加「屏幕镜像」按钮。
4. **平台**：本阶段仅 Android（真机 + 模拟器）；iOS 非目标。
5. **控制**：沿用 scrcpy 默认触控/键盘（外窗内操作）。

## 非目标

- 助手页内嵌画面、移植 screen-sharing-agent、iOS 真机投屏。
