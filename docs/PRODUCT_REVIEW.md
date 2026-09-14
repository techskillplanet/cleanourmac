# Mobile 开发助手：产品走查与改造记录

日期：2026-09-01

## 走查结论

改造前的产品能力已经覆盖缓存清理、模拟器和 ADB，但体验仍以“磁盘清理器”为中心：

1. **定位不清晰**：品牌、图标和概览页都更像通用清理工具，移动研发能力没有成为第一认知。
2. **信息架构倒置**：设备调测位于侧栏后部，Android 也排在 iOS 之后，与实际高频调试路径不符。
3. **工作台价值不足**：概览只有磁盘图表，无法快速判断设备状态，也缺少直达核心任务的操作入口。
4. **ADB 能力隐藏过深**：Shell、Logcat、APK 安装和截图位于更多菜单，发现成本高。
5. **视觉系统不统一**：页面标题、卡片、按钮、空状态和状态标签缺少统一层级，界面留白利用率低。
6. **页面状态容易丢失**：直接切换页面会重建子页面，不利于长时间扫描和设备调试。

## 本轮产品调整

### 品牌与定位

- 产品改名为 **Mobile 开发助手**。
- 新 Logo 使用“移动设备轨道组成的 M + 终端光标”作为核心识别。
- 品牌色调整为深海军蓝、青绿色和少量功能蓝，强调本地、专业和开发者属性。
- 侧栏与工作台明确标注“本地运行 · 隐私优先”。

### 信息架构

- 侧栏顺序调整为：工作台、设备调测、开发环境清理、大文件分析、Node Modules、设置。
- 页面使用按需创建的缓存式 `IndexedStack`，首次访问后保留页面状态，同时避免启动时加载所有工具。
- 设备调测默认进入 Android，iOS 作为第二标签。

### 工作台

- 增加品牌任务区和两个核心快捷入口：设备调测、开发环境扫描。
- 增加 Android 设备数、iOS 模拟器数、可清理空间三项关键指标。
- 重构存储概览，强化容量、已用、可用和可清理空间之间的关系。
- 未扫描时提供明确的下一步操作，扫描后展示主要清理分类。

### 设备与 ADB

- ADB Shell、Logcat、APK 安装和截图提升为设备卡片中的一级快捷操作。
- 设备卡片补充序列号、设备类型、在线状态和清晰的操作层级。
- ADB 工具条显示在线设备概况，并保留重启 ADB 服务入口。
- 支持 Android AVD 和通过 ADB 连接的真机。

### AI Agent 缓存

- 新增 Claude Code、OpenCode、Trae、Qoder、Codex 和 Cursor 专用缓存检测。
- 采用严格路径白名单，不扫描或删除账号凭据、配置、项目规则、代码、会话、聊天记录和安装状态。
- 所有缓存默认不选中，且通用大文件扫描会绕开这些专用目录。
- 清理前必须逐项选择，并勾选“已关闭相关 AI Agent 且同意清理”后才能执行。
- 清理仅清空缓存目录内容，目录本身保留，失败项会跳过而不会中断整批任务。

### React Native 工作台

- 新增独立的 React Native 菜单，自动识别常见开发目录中的 RN 项目。
- 读取 `package.json` 脚本和 lockfile，识别 Yarn、npm、pnpm、Bun，并按实际包管理器执行命令。
- 提供 `start Metro`、重置 Metro 缓存、打开 RN DevTools、在 Cursor 中打开项目等入口。
- 按项目脚本提供 Android、iOS、Charles 和自定义脚本快捷操作；不存在的脚本不会显示为可点击按钮。
- 每 4 秒检测 Metro `/status`，展示端口、进程和 PID。
- 设备区提供 Android Metro 端口反向映射，以及 Android/iOS RN 开发菜单和重载按钮。

### iOS Simulator 调测

- 使用 `simctl` 为 iOS Simulator 增加实时系统日志、安装 `.app`、截图、打开 URL 和复制 UDID。
- RN 快捷操作使用 iOS Simulator 的 `Command + D` 开发菜单和 `Command + R` 重载路径。
- 截图按设备和时间保存到桌面的 `iOS Simulator Screenshots` 目录。

### 稳定性与卡顿治理

- 移除 React Native 页面 `build()` 中的同步项目、IDE 和原生工程递归扫描。
- RN 项目发现与 IDE 工程识别整体运行在独立 isolate，避免文件系统阻塞 Flutter UI isolate。
- 对外接盘、已删除项目和不可访问目录增加超时及容错，不再等待失效路径。
- Metro 轮询与项目刷新增加互斥合并，避免定时任务和手动刷新重叠堆积。
- RN 页面不可见时停止 Metro 轮询，返回页面后自动恢复。
- 开发缓存、Node Modules 和 AI Agent 缓存的目录存在性、目录枚举和文件状态读取改为异步操作。

### Android 模拟器失败诊断

- Android 模拟器启动失败时写入持久诊断日志，而不是只显示临时错误提示。
- 日志包含时间、AVD、SDK 搜索路径、最终 SDK、系统镜像、启动命令、emulator 原始输出、失败原因和堆栈。
- 诊断文件保存在 `~/Library/Logs/Mobile 开发助手/Android Emulator/`。
- 错误弹窗展示日志路径，并支持一键在 Finder 中定位和复制错误详情。
- 成功启动时删除临时启动输出，不产生失败日志。

### 跨平台开发缓存

- 全局缓存覆盖 Dart Pub、Gradle、Android Studio、CocoaPods、SwiftPM、Carthage、npm、Yarn、pnpm、Bun、Corepack、Deno、Playwright 和 Cypress。
- 新增“项目缓存”菜单，检索 Flutter、Android、iOS、React Native 和 Web 项目的生成目录。
- 项目规则覆盖 `.dart_tool`、Flutter `build`、Android `.gradle/build`、iOS `Pods/build`、Vite、Next.js、Nuxt、SvelteKit、Angular、Parcel、Turbo、Webpack、测试覆盖率和 Web 构建产物。
- 项目缓存扫描运行在独立 isolate，并设置目录数量与时间上限，避免大型仓库或外接盘阻塞 UI。
- 不扫描源码、资源源文件、配置、证书、签名、锁文件、数据库或 `node_modules` 本体。
- 所有项目缓存默认不选中，清理前展示完整路径并要求明确勾选同意。

### 视觉与交互

- 建立统一的页面标题、说明文字、卡片边界、按钮高度和圆角体系。
- 侧栏增加渐变氛围、品牌图标、选中态和隐私状态。
- 设置页按语言、扫描阈值、安全排除和 Node Modules 目录重新分组。
- 统一页面标题副文案，让功能目的和下一步操作更明确。

## 后续建议

1. 增加应用包名管理，支持一键 Force Stop、Clear Data、启动 Activity 和端口反向代理。
2. 增加 Logcat 会话保存、过滤模板和错误聚合。
3. 增加 APK/IPA 构建产物历史和拖拽安装。
4. 增加设备截图历史、录屏和多设备批量操作。
5. 增加开发环境健康检查，例如 Android SDK、Xcode、CocoaPods、Java 和 Flutter 版本诊断。
