# 02 · 验收标准

- **Status**: confirmed
- **Prerequisite**: `01-background-and-goal.md`

| ID | 标准 | 验证 |
|----|------|------|
| AC-01 | 运行中 Android 设备卡片有「屏幕镜像」入口 | UI 可见 |
| AC-02 | 在已解析到 scrcpy 且设备 online 时，点击后启动外窗进程（带 `-s <serial>`） | 手工 + 单测参数 |
| AC-03 | 找不到 scrcpy 时不崩溃，提示缺失与安装指引 | 手工 / 单测抛错文案 |
| AC-04 | 无 serial / 非运行设备不提供有效启动 | UI disabled 或早期返回 |
| AC-05 | 不改变既有 Shell/Logcat/安装/截图行为 | 回归点按 |
