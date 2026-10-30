# 01 · 背景与目标

- **Status**: confirmed
- **Prerequisite**: `00-spec-index.md`

## 问题

设备调测仅有单次截图，联调时看不到实时画面。

## 目标

对已连接 Android 设备，用户点击「屏幕镜像」即可打开 scrcpy 外窗，实时看到并可操作设备屏幕。

## 成功信号

点击后出现投屏窗；无 scrcpy/无设备时有明确错误，且不影响既有 ADB 工具。

## 非目标

页内嵌屏、AS Agent 移植、iOS 真机。
