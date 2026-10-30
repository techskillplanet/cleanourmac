# 04 · To-Be

- **Status**: confirmed
- **Prerequisite**: `03-as-is.md`

## 目标行为

1. 解析 scrcpy 可执行文件（捆绑 Resources / `third_party/scrcpy` / Homebrew / PATH）。
2. 用户点击「屏幕镜像」→ 以 detached 进程启动 `scrcpy -s <serial>`，并尽量传入已知 `ADB` 路径。
3. 成功：提示已打开镜像窗口；失败：展示可理解错误。

## 概念边界

- **Scrcpy 启动器**：路径解析 + 进程拉起（数据层）。
- **设备面板**：按钮与反馈（表现层）。
- **scrcpy 自身**：编码、窗口、触控（外部程序）。
