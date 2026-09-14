// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Mobile 开发助手';

  @override
  String get appTagline => '面向移动研发的本地工具箱';

  @override
  String get workspaceSubtitle => '设备、存储与开发环境状态一目了然';

  @override
  String get deviceLabSubtitle => '集中管理 Android、iOS 设备与调测工具';

  @override
  String get settingsSubtitle => '按你的研发习惯配置扫描与安全规则';

  @override
  String get localPrivate => '本地运行 · 隐私优先';

  @override
  String get brandEdition => 'MOBILE DEV TOOLKIT';

  @override
  String get deviceOverview => '设备状态';

  @override
  String get quickActions => '快捷操作';

  @override
  String get openDeviceLab => '打开设备调测';

  @override
  String get startDiskScan => '扫描开发环境';

  @override
  String androidDeviceCount(Object count) {
    return '$count 台 Android 设备';
  }

  @override
  String iosDeviceCount(Object count) {
    return '$count 台 iOS 模拟器';
  }

  @override
  String get reclaimableMetric => '可清理空间';

  @override
  String get storageOverview => '存储概览';

  @override
  String get storageSubtitle => '主数据卷的实际磁盘占用';

  @override
  String get noScanData => '尚未扫描开发缓存';

  @override
  String get scanNow => '立即扫描';

  @override
  String adbDeviceSummary(Object running, Object total) {
    return '$running 台在线 · 共 $total 台设备';
  }

  @override
  String androidTab(Object count) {
    return 'Android · $count';
  }

  @override
  String iosTab(Object count) {
    return 'iOS · $count';
  }

  @override
  String get adbReady => 'ADB 已就绪';

  @override
  String get developerTools => '调测快捷工具';

  @override
  String get scanPageSubtitle => '识别可重建缓存，以可审查的方式安全释放空间';

  @override
  String get largeFilesSubtitle => '定位真实占用磁盘空间的大文件并按风险分类';

  @override
  String get nodeModulesSubtitle => '按最近使用时间管理项目依赖目录';

  @override
  String get aiAgentCaches => 'AI Agent 缓存';

  @override
  String get aiAgentCachesSubtitle => '检测并清理可重建缓存，账号、配置与会话数据始终保留';

  @override
  String get detectCaches => '重新检测';

  @override
  String get scanningCaches => '正在检测缓存…';

  @override
  String get aiCachePrivacyTitle => '仅清理白名单缓存';

  @override
  String get aiCachePrivacyDescription =>
      '不会删除账号凭据、配置、项目规则、代码、会话历史、聊天记录或已安装扩展。所有项目默认不选中。';

  @override
  String get aiCacheCloseAppsHint => '清理前请关闭对应 AI Agent，避免缓存被占用或立即重新生成。';

  @override
  String aiCacheDetectedSummary(Object agents, Object count, Object size) {
    return '检测到 $count 个缓存目录 · $agents 个 Agent · 共 $size';
  }

  @override
  String aiCacheSelectedSummary(Object count, Object size) {
    return '已选择 $count 项 · $size';
  }

  @override
  String get noAiCachesFound => '未检测到 AI Agent 缓存';

  @override
  String get noAiCachesFoundDescription =>
      '已检查 Claude Code、OpenCode、Trae、Qoder、Codex 和 Cursor 的已知缓存目录。';

  @override
  String get selectAgentCaches => '选择此 Agent 的缓存';

  @override
  String get cleanSelectedCaches => '清理所选缓存';

  @override
  String get confirmAiCacheCleanTitle => '确认清理 AI Agent 缓存';

  @override
  String get confirmAiCacheCleanDescription =>
      '以下目录中的可重建缓存将被清空，目录本身会保留。此操作不会清理会话和配置。';

  @override
  String get aiCacheConsentLabel => '我已关闭相关 AI Agent，并同意清理所选缓存';

  @override
  String get aiCacheConsentRequired => '勾选同意后才能继续';

  @override
  String get clearCaches => '确认清理';

  @override
  String aiCacheCleaned(Object count, Object size) {
    return '已清理 $count 项，释放 $size';
  }

  @override
  String get aiCacheRebuildable => '可重建';

  @override
  String aiCachePathCount(Object count) {
    return '$count 个缓存目录';
  }

  @override
  String get claudeCode => 'Claude Code';

  @override
  String get openCode => 'OpenCode';

  @override
  String get trae => 'Trae / Trae SOLO';

  @override
  String get qoder => 'Qoder';

  @override
  String get codex => 'Codex';

  @override
  String get cursor => 'Cursor';

  @override
  String get cacheKindCli => '命令行缓存';

  @override
  String get cacheKindDesktop => '桌面应用缓存';

  @override
  String get cacheKindCode => '代码缓存';

  @override
  String get cacheKindGpu => '图形缓存';

  @override
  String get cacheKindExtensions => '扩展下载缓存';

  @override
  String get cacheKindUpdater => '更新下载缓存';

  @override
  String get cacheKindShared => '共享客户端缓存';

  @override
  String get cacheKindTemporary => '临时文件';

  @override
  String get cacheKindRuntime => '运行时缓存';

  @override
  String get reactNative => 'React Native';

  @override
  String get reactNativeSubtitle => '项目脚本、Metro 服务和设备调测的快捷工作台';

  @override
  String get rnProjects => 'RN 项目';

  @override
  String get addRnProject => '添加项目';

  @override
  String get chooseRnProject => '选择 React Native 项目目录';

  @override
  String get noRnProjects => '未发现 React Native 项目';

  @override
  String get noRnProjectsDescription =>
      '可添加项目目录，或将项目放在 Projects、Developer、StudioProjects 或外接磁盘的 code 目录下。';

  @override
  String get invalidRnProject => '所选目录不是有效的 React Native 项目';

  @override
  String projectAdded(Object name) {
    return '已添加项目：$name';
  }

  @override
  String get selectedProject => '当前项目';

  @override
  String get quickCommands => '高频命令';

  @override
  String get moreScripts => '更多脚本';

  @override
  String get startMetro => '启动 Metro';

  @override
  String get resetMetroCache => '重置 Metro 缓存';

  @override
  String get runAndroid => '运行 Android';

  @override
  String get runIos => '运行 iOS';

  @override
  String get runIosSetup => '安装依赖并运行 iOS';

  @override
  String get runCharles => '启动 Charles';

  @override
  String get openRnDevTools => '打开 RN DevTools';

  @override
  String get openProject => '打开项目';

  @override
  String get openProjectHint => '选择打开方式';

  @override
  String get openWithCodex => 'Codex 桌面端';

  @override
  String get openWithCodexCli => 'Codex CLI';

  @override
  String get openWithCursor => 'Cursor';

  @override
  String get openWithVsCode => 'VS Code';

  @override
  String get openWithAndroidStudio => 'Android Studio（Android）';

  @override
  String get openWithXcode => 'Xcode（iOS）';

  @override
  String get openWithQoder => 'Qoder';

  @override
  String get openWithTrae => 'Trae';

  @override
  String get openWithWebStorm => 'WebStorm';

  @override
  String get openWithZed => 'Zed';

  @override
  String get openWithWindsurf => 'Windsurf';

  @override
  String get openInTerminal => 'Terminal';

  @override
  String projectOpenedWith(Object app, Object name) {
    return '已使用 $app 打开 $name';
  }

  @override
  String get openInCursor => '在 Cursor 中打开';

  @override
  String commandStarted(Object command) {
    return '已在 Terminal 启动：$command';
  }

  @override
  String get metroService => 'Metro 服务';

  @override
  String metroRunning(Object port) {
    return '端口 $port 正在运行';
  }

  @override
  String metroStopped(Object port) {
    return '端口 $port 未运行';
  }

  @override
  String metroProcess(Object pid, Object process) {
    return '$process · PID $pid';
  }

  @override
  String get metroWatching => '每 4 秒自动检测';

  @override
  String get rnDeviceTools => 'RN 设备快捷调测';

  @override
  String get androidDevMenu => 'Android 开发菜单';

  @override
  String get androidReload => 'Android 重载';

  @override
  String get androidMetroReverse => '连接 Android Metro';

  @override
  String get iosDevMenu => 'iOS 开发菜单';

  @override
  String get iosReload => 'iOS 重载';

  @override
  String metroReverseDone(Object name, Object port) {
    return '已为 $name 映射 Metro 端口 $port';
  }

  @override
  String get noRunningAndroid => '没有在线 Android 设备';

  @override
  String get noBootedIos => '没有已启动的 iOS 模拟器';

  @override
  String get rnProjectRoots => 'React Native 项目目录';

  @override
  String get rnProjectRootsDescription => '用于固定常用 RN 项目；工作台也会自动发现常见开发目录下的项目。';

  @override
  String get metroPort => '默认 Metro 端口';

  @override
  String get iosDebugTools => 'iOS 调测工具';

  @override
  String get copyUdid => '复制 UDID';

  @override
  String udidCopied(Object udid) {
    return '已复制 UDID：$udid';
  }

  @override
  String get openSimulatorLogs => '实时日志';

  @override
  String get installIosApp => '安装 .app';

  @override
  String get chooseIosAppPrompt => '选择要安装到模拟器的 .app';

  @override
  String iosAppInstalled(Object name) {
    return '已将应用安装到 $name';
  }

  @override
  String get openUrl => '打开 URL';

  @override
  String get openUrlTitle => '在模拟器中打开 URL';

  @override
  String get urlHint => '例如 myapp://debug 或 http://localhost:8081';

  @override
  String get invalidUrl => '请输入有效 URL';

  @override
  String get iosRnShortcutHint =>
      'RN iOS 开发菜单使用 Command + D，重载使用 Command + R。首次使用可能需要允许辅助功能控制。';

  @override
  String get projectCaches => '项目缓存';

  @override
  String get projectCachesSubtitle =>
      '检索 Flutter、Android、iOS、React Native 与 Web 项目的生成文件';

  @override
  String get projectCacheSafetyTitle => '只识别可重新生成的目录';

  @override
  String get projectCacheSafetyDescription =>
      '不会删除源码、图片资源、配置、签名、证书、锁文件、数据库或 node_modules 本体。所有项目默认不选中。';

  @override
  String projectCacheSummary(Object count, Object projects, Object size) {
    return '发现 $count 个缓存目录 · $projects 个项目 · 共 $size';
  }

  @override
  String get projectCacheEmpty => '未发现项目缓存';

  @override
  String get projectCacheEmptyDescription => '已扫描常见开发目录和设置中配置的项目目录。';

  @override
  String get projectCacheKindTool => '工具状态';

  @override
  String get projectCacheKindBuild => '构建产物';

  @override
  String get projectCacheKindDependencies => '生成的依赖产物';

  @override
  String get projectCacheKindBundler => '打包器缓存';

  @override
  String get projectCacheKindTest => '测试与覆盖率产物';

  @override
  String get projectCacheEcosystemFlutter => 'Flutter';

  @override
  String get projectCacheEcosystemAndroid => 'Android';

  @override
  String get projectCacheEcosystemIos => 'iOS';

  @override
  String get projectCacheEcosystemRn => 'React Native';

  @override
  String get projectCacheEcosystemWeb => 'Web';

  @override
  String get confirmProjectCacheCleanTitle => '确认清理项目缓存';

  @override
  String get confirmProjectCacheCleanDescription =>
      '所选目录会被完整删除，并在下次构建或安装依赖时重新生成。';

  @override
  String get projectCacheConsentLabel => '我已确认所选路径，并同意删除这些生成文件';

  @override
  String projectCacheCleaned(Object count, Object size) {
    return '已清理 $count 项，释放 $size';
  }

  @override
  String get developmentRoots => '开发项目扫描目录';

  @override
  String get developmentRootsDescription =>
      '用于检索 Flutter、Android、iOS、React Native 和 Web 项目的构建与工具缓存。';

  @override
  String get targetAndroidCliCache => 'Android CLI 缓存';

  @override
  String get targetAndroidCliCacheDescription => 'Android 命令工具下载的元数据和临时包数据。';

  @override
  String get targetAndroidStudioCache => 'Android Studio 缓存';

  @override
  String get targetAndroidStudioCacheDescription => 'IDE 索引和生成缓存；重启后会重新构建。';

  @override
  String get targetDartPubHosted => 'Dart Pub 托管包缓存';

  @override
  String get targetDartPubHostedDescription =>
      '已下载的 Dart 与 Flutter 包；需要时由 Pub 重新获取。';

  @override
  String get targetDartPubGit => 'Dart Pub Git 缓存';

  @override
  String get targetDartPubGitDescription => 'Pub 下载的 Git 依赖；需要时可重新克隆。';

  @override
  String get targetYarnCache => 'Yarn 缓存';

  @override
  String get targetYarnCacheDescription => '已下载的 Yarn 包；下次安装依赖时重新获取。';

  @override
  String get targetYarnXdgCache => 'Yarn XDG 缓存';

  @override
  String get targetYarnXdgCacheDescription => '保存在 XDG 缓存目录中的 Yarn 包缓存。';

  @override
  String get targetPnpmStore => 'pnpm Store';

  @override
  String get targetPnpmStoreDescription => 'pnpm 内容寻址包存储；清理后可能需要重新下载。';

  @override
  String get targetPnpmLegacyStore => 'pnpm 旧版 Store';

  @override
  String get targetPnpmLegacyStoreDescription => '旧版本 pnpm 留下的包存储。';

  @override
  String get targetBunCache => 'Bun 包缓存';

  @override
  String get targetBunCacheDescription => 'Bun 下载的依赖包；安装时会重新获取。';

  @override
  String get targetCorepackCache => 'Corepack 缓存';

  @override
  String get targetCorepackCacheDescription => 'Corepack 下载的包管理器发行版本。';

  @override
  String get targetSwiftpmCache => 'Swift Package Manager 缓存';

  @override
  String get targetSwiftpmCacheDescription => 'Swift 包元数据和构建产物；SwiftPM 会重新生成。';

  @override
  String get targetSwiftpmRepositories => 'SwiftPM 仓库缓存';

  @override
  String get targetSwiftpmRepositoriesDescription => '缓存的 Swift 包仓库；需要时会重新克隆。';

  @override
  String get targetCarthageCache => 'Carthage 缓存';

  @override
  String get targetCarthageCacheDescription => 'Carthage 下载的依赖产物和仓库元数据。';

  @override
  String get targetCypress => 'Cypress 缓存';

  @override
  String get targetCypressDescription => '已下载的 Cypress 测试运行器；需要时重新安装。';

  @override
  String get targetDenoCache => 'Deno 缓存';

  @override
  String get targetDenoCacheDescription => 'Deno 项目下载的模块和编译产物。';

  @override
  String get targetXcodeDeviceSupport => 'Xcode 设备支持文件';

  @override
  String get targetXcodeDeviceSupportDescription =>
      '连接过的 iOS 版本对应符号和支持文件；请确认旧版本后清理。';

  @override
  String get language => '语言';

  @override
  String get languageDescription => '选择界面显示语言';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get overview => '工作台';

  @override
  String get scanAndClean => '开发环境清理';

  @override
  String get largeFiles => '大文件分析';

  @override
  String get nodeModules => 'Node Modules';

  @override
  String get simulators => '设备调测';

  @override
  String get settings => '设置';

  @override
  String get scan => '扫描';

  @override
  String get scanning => '扫描中…';

  @override
  String get cancel => '取消';

  @override
  String get refresh => '刷新';

  @override
  String get selectAll => '全选';

  @override
  String get deselectAll => '取消全选';

  @override
  String get delete => '删除';

  @override
  String get permanentlyDelete => '永久删除';

  @override
  String get dismiss => '关闭';

  @override
  String get open => '打开';

  @override
  String get stop => '停止';

  @override
  String get boot => '启动';

  @override
  String get moreActions => '更多操作';

  @override
  String errorMessage(Object error) {
    return '错误：$error';
  }

  @override
  String operationError(Object error, Object title) {
    return '$title：$error';
  }

  @override
  String get notFound => '未找到';

  @override
  String get noItemsFound => '未发现项目';

  @override
  String itemCount(Object count) {
    return '$count 项';
  }

  @override
  String get overviewTotalDisk => '磁盘总容量';

  @override
  String get overviewUsed => '已使用';

  @override
  String get overviewRecoverable => '可清理';

  @override
  String get overviewFree => '可用';

  @override
  String get overviewReadyToRecover => '可释放空间';

  @override
  String get categories => '分类';

  @override
  String get mainDiskScan => '主磁盘扫描';

  @override
  String scanningTarget(Object target) {
    return '正在扫描 $target…';
  }

  @override
  String cleaningReclaimed(Object size) {
    return '正在清理…已释放 $size';
  }

  @override
  String get scanEmptyPrompt => '点击“扫描”分析磁盘空间';

  @override
  String get startScan => '开始扫描';

  @override
  String get confirmClean => '确认清理';

  @override
  String cleanDeleteSummary(Object count, Object size) {
    return '将永久删除 $count 项，共 $size。';
  }

  @override
  String get macintoshDiskName => 'Macintosh HD · 主数据卷';

  @override
  String get primaryDataVolumeDescription =>
      '/System/Volumes/Data · 显示实际占用空间，不含稀疏文件逻辑大小';

  @override
  String diskUsed(Object size) {
    return '已使用 $size';
  }

  @override
  String get capacity => '总容量';

  @override
  String get candidatesFound => '发现可清理项';

  @override
  String get selected => '已选择';

  @override
  String get readingDiskUsage => '正在读取主磁盘用量…';

  @override
  String get category => '分类';

  @override
  String get safeToClean => '可安全清理';

  @override
  String get caution => '需要确认';

  @override
  String get danger => '高风险';

  @override
  String foundAndSelected(Object found, Object selected) {
    return '发现 $found 项 · 已选 $selected 项';
  }

  @override
  String selectedToClean(Object size) {
    return '已选择 $size 待清理';
  }

  @override
  String get cleanNow => '立即清理';

  @override
  String cleanDone(Object size) {
    return '清理完成，已释放 $size';
  }

  @override
  String get simulatorNeverBooted => '从未启动';

  @override
  String lastUsedDate(Object date) {
    return '上次使用：$date';
  }

  @override
  String simulatorScanDetailNever(Object runtime) {
    return '$runtime · 从未启动';
  }

  @override
  String simulatorScanDetailLastUsed(Object date, Object runtime) {
    return '$runtime · 上次使用：$date';
  }

  @override
  String runtimeBuild(Object build) {
    return '构建 $build';
  }

  @override
  String runtimeBuildLastUsed(Object build, Object date) {
    return '构建 $build · 上次使用：$date';
  }

  @override
  String runtimeCacheName(Object runtime) {
    return '$runtime dyld 缓存';
  }

  @override
  String get runtimeCacheDetail => '生成的运行时缓存 · 会自动重新构建';

  @override
  String get largeFilesNoSafeCandidates => '没有可安全删除的文件（PathGuard 已拦截）';

  @override
  String get confirmDelete => '确认删除';

  @override
  String fileDeleteSummary(Object count, Object size) {
    return '$count 个文件 · 共 $size';
  }

  @override
  String get permanentDeleteWarning => '这些文件将被永久删除，无法恢复。';

  @override
  String findFilesOver(Object threshold) {
    return '查找大于 $threshold MB 的文件';
  }

  @override
  String get largeFileSafetyDescription =>
      '安全分类：缓存和临时文件会标记为安全；系统、SDK 和源码文件不会列出';

  @override
  String largeFilesSummary(Object count, Object size) {
    return '共 $count 个文件 · $size';
  }

  @override
  String safeCount(Object count) {
    return '安全 $count';
  }

  @override
  String cautionCount(Object count) {
    return '需确认 $count';
  }

  @override
  String get safeToDelete => '可安全删除';

  @override
  String get requiresReview => '需要确认';

  @override
  String countAndSize(Object count, Object size) {
    return '$count 个 · $size';
  }

  @override
  String get largeFileSafetySafe => '安全';

  @override
  String get largeFileSafetyCaution => '需确认';

  @override
  String get largeFileSafetyReasonSafe => '缓存或临时文件，可安全删除';

  @override
  String get largeFileSafetyReasonCaution => '请确认文件用途后再删除';

  @override
  String get showInFinder => '在 Finder 中显示';

  @override
  String selectedFiles(Object count) {
    return '已选 $count 个文件';
  }

  @override
  String totalSize(Object size) {
    return '共 $size';
  }

  @override
  String get deleteSelected => '删除所选';

  @override
  String deletedFilesSummary(Object count, Object size) {
    return '已删除 $count 个文件，释放 $size';
  }

  @override
  String get noNodeModulesFound => '配置的目录中未发现 node_modules';

  @override
  String get addNodeModulesRoots => '请在设置中添加项目根目录。';

  @override
  String nodeModulesSummary(Object count, Object selected, Object total) {
    return '$count 个文件夹 · $total · 已选 $selected';
  }

  @override
  String get deleteNodeModulesTitle => '删除 node_modules？';

  @override
  String deleteNodeModulesContent(Object count, Object size) {
    return '删除 $count 个文件夹（$size）？\n\n之后需要通过 npm/yarn install 重新安装依赖。';
  }

  @override
  String get lruTitle => 'LRU（保护最近使用的依赖）';

  @override
  String get lruEnabledDescription => '仅自动选择 30 天以上未使用的依赖';

  @override
  String get lruDisabledDescription => '显示全部，由你手动选择要删除的内容';

  @override
  String get idle => '闲置';

  @override
  String lastUsed(Object date) {
    return '上次使用：$date';
  }

  @override
  String selectedSummary(Object count, Object size) {
    return '已选 $count 项 · $size';
  }

  @override
  String get scanThresholds => '扫描阈值';

  @override
  String get largeFileThreshold => '大文件阈值';

  @override
  String get simulatorStaleThreshold => '模拟器闲置阈值';

  @override
  String days(Object count) {
    return '$count 天';
  }

  @override
  String get excludedPaths => '排除路径';

  @override
  String get excludedPathsDescription => '即使被选中，也绝不会删除这些路径。';

  @override
  String get nodeModulesRoots => 'Node Modules 扫描目录';

  @override
  String get nodeModulesRootsDescription => '在这些目录中扫描 node_modules；留空时扫描用户主目录。';

  @override
  String get pathExample => '例如 /Users/you/projects/my-app';

  @override
  String get noSimulatorsFound => '未发现模拟器';

  @override
  String get iosSimulators => 'iOS 模拟器';

  @override
  String get androidEmulators => 'Android 设备';

  @override
  String get adbTools => 'ADB 调测工具';

  @override
  String get adbToolsDescription =>
      '为运行中的 Android 设备提供 Shell、Logcat、APK 安装和截图功能';

  @override
  String get restartAdb => '重启 ADB';

  @override
  String get adbRestarted => 'ADB 服务已重启';

  @override
  String get copySerial => '复制设备序列号';

  @override
  String serialCopied(Object serial) {
    return '已复制设备序列号：$serial';
  }

  @override
  String get openAdbShell => '打开 ADB Shell';

  @override
  String get openLogcat => '打开 Logcat';

  @override
  String get installApk => '安装 APK';

  @override
  String get chooseApkPrompt => '选择要安装的 APK';

  @override
  String get invalidApk => '请选择有效的 .apk 文件';

  @override
  String apkInstalled(Object name) {
    return '已将 APK 安装到 $name';
  }

  @override
  String get takeScreenshot => '截取屏幕';

  @override
  String screenshotSaved(Object path) {
    return '截图已保存：$path';
  }

  @override
  String terminalOpened(Object name, Object tool) {
    return '已为 $name 打开 $tool';
  }

  @override
  String get virtualDevice => '模拟器';

  @override
  String get physicalDevice => '真机';

  @override
  String get noAndroidVirtualDevices => '未发现 Android 虚拟设备或已连接设备';

  @override
  String unableToStartEmulator(Object name) {
    return '无法启动 $name';
  }

  @override
  String get androidStartErrorDetails =>
      '模拟器进程提前退出。下面是 emulator 的原始启动信息，可用于定位镜像、SDK、锁文件或图形驱动问题。';

  @override
  String androidFailureLogSaved(Object path) {
    return '失败日志已保存：$path';
  }

  @override
  String get openFailureLog => '在 Finder 中显示日志';

  @override
  String get copyErrorDetails => '复制错误详情';

  @override
  String get errorDetailsCopied => '错误详情已复制';

  @override
  String get checkEmulatorConfig => '检查配置';

  @override
  String get checkingEmulatorConfig => '正在检查配置…';

  @override
  String get emulatorConfigCheckTitle => 'Android 模拟器配置体检';

  @override
  String get emulatorConfigCheckSubtitle => '检查 AVD 描述、系统镜像、电脑键盘和离线锁文件';

  @override
  String get emulatorConfigSafetyNote =>
      '只修复可安全恢复的配置项；修改前自动备份配置，不会删除应用、用户数据或快照。';

  @override
  String get emulatorConfigHealthy => '配置状态良好';

  @override
  String get emulatorConfigHealthyDescription =>
      '未发现会影响 Android 模拟器启动和调测的配置问题。';

  @override
  String get emulatorConfigNoAvds => '没有可检查的 AVD';

  @override
  String get emulatorConfigNoAvdsDescription => '当前 Android AVD 目录中没有虚拟设备。';

  @override
  String emulatorConfigSummary(Object avds, Object issues, Object repairable) {
    return '已检查 $avds 个 AVD · 发现 $issues 个问题 · $repairable 项可修复';
  }

  @override
  String get selectAllRepairable => '选择全部可修复项';

  @override
  String repairSelectedIssues(Object count) {
    return '修复选中项（$count）';
  }

  @override
  String get repairableIssue => '可自动修复';

  @override
  String get manualActionRequired => '需要手动处理';

  @override
  String get restartRequired => '重启后生效';

  @override
  String get repairingEmulatorConfig => '正在修复配置…';

  @override
  String get emulatorConfigRepairComplete => '配置修复完成';

  @override
  String emulatorConfigRepairSummary(Object remaining, Object repaired) {
    return '已修复 $repaired 项，仍有 $remaining 项需要处理。';
  }

  @override
  String emulatorConfigRepairSkipped(Object count) {
    return '$count 项因状态变化或安全校验未通过而跳过。';
  }

  @override
  String emulatorConfigBackupSaved(Object path) {
    return '原配置已备份到：$path';
  }

  @override
  String restartRequiredAvds(Object names) {
    return '以下运行中的模拟器需重启后生效：$names';
  }

  @override
  String get avdHomeMissingIssue => 'AVD 配置目录不可用';

  @override
  String avdHomeMissingDescription(Object path) {
    return '无法读取 Android AVD 配置目录：$path';
  }

  @override
  String get avdDescriptorMissingIssue => 'AVD 描述文件缺失';

  @override
  String avdDescriptorMissingDescription(Object name) {
    return '$name 缺少描述文件，将重新建立到实际 AVD 目录的安全关联。';
  }

  @override
  String get avdDescriptorPathIssue => 'AVD 路径不一致';

  @override
  String avdDescriptorPathDescription(Object name) {
    return '$name 的描述路径无效或与实际目录不一致。';
  }

  @override
  String get avdDirectoryMissingIssue => 'AVD 数据目录缺失';

  @override
  String avdDirectoryMissingDescription(Object name, Object path) {
    return '$name 的数据目录不存在：$path';
  }

  @override
  String get avdConfigMissingIssue => 'config.ini 缺失';

  @override
  String avdConfigMissingDescription(Object name, Object path) {
    return '$name 缺少核心配置文件：$path';
  }

  @override
  String get systemImagePathMissingIssue => '系统镜像配置缺失';

  @override
  String systemImagePathMissingDescription(Object name) {
    return '$name 的 config.ini 中没有 image.sysdir.1，无法安全推断系统镜像。';
  }

  @override
  String get systemImageMissingIssue => '系统镜像未安装';

  @override
  String systemImageMissingDescription(Object name, Object path) {
    return '$name 使用的系统镜像不存在：$path。请通过 SDK Manager 安装对应镜像。';
  }

  @override
  String get systemImagePathIssue => '系统镜像路径失效';

  @override
  String systemImagePathDescription(Object name) {
    return '$name 仍指向旧 SDK 路径，可修复为当前已安装镜像。';
  }

  @override
  String get hardwareKeyboardIssue => '电脑键盘未启用';

  @override
  String hardwareKeyboardIssueDescription(Object name) {
    return '$name 无法稳定接收电脑键盘输入和快捷键。';
  }

  @override
  String get staleLockIssue => '发现离线锁文件';

  @override
  String staleLockDescription(Object count, Object name) {
    return '$name 已停止，但残留 $count 个过期锁文件，可能阻止下次启动。';
  }

  @override
  String currentConfigValue(Object value) {
    return '当前：$value';
  }

  @override
  String suggestedConfigValue(Object value) {
    return '修复为：$value';
  }

  @override
  String get stopEmulatorTitle => '停止模拟器？';

  @override
  String stopAndroidEmulatorContent(Object name, Object serial) {
    return '确定停止 $name（$serial）吗？';
  }

  @override
  String unableToStopEmulator(Object name) {
    return '无法停止 $name';
  }

  @override
  String emulatorActionSent(Object action, Object name) {
    return '已向 $name 发送“$action”';
  }

  @override
  String get stopBeforeDeleteEmulator => '请先停止模拟器再删除';

  @override
  String get deleteAvdTitle => '删除 AVD？';

  @override
  String deleteAvdContent(Object name) {
    return '$name 将被永久移除。';
  }

  @override
  String get running => '运行中';

  @override
  String get shutdown => '已关机';

  @override
  String get androidDeviceNavigation => '设备导航';

  @override
  String get androidBack => '返回';

  @override
  String get androidHome => '主屏幕';

  @override
  String get androidRecents => '最近任务';

  @override
  String get androidGestureNavigationHint =>
      '当前模拟器为手势导航：底部横条不可点击返回，可从屏幕左右边缘向内滑，或使用这里的返回按钮。';

  @override
  String get androidClipboard => '电脑剪贴板';

  @override
  String get androidCopySelection => '复制选中内容';

  @override
  String get androidPasteHostClipboard => '粘贴电脑剪贴板';

  @override
  String get androidClipboardHint =>
      '先在 Android 输入框中放置光标。支持中文和特殊字符；开发助手仅在点击操作时读取或写入剪贴板，不会保存内容。';

  @override
  String get hardwareKeyboardDisabled => '此 AVD 未启用电脑键盘，直接键盘输入和快捷键可能无效。';

  @override
  String get enableHardwareKeyboard => '启用电脑键盘';

  @override
  String get enableHardwareKeyboardTitle => '启用电脑键盘并重启？';

  @override
  String enableHardwareKeyboardDescription(Object name) {
    return '将修改 $name 的 AVD 配置并重新启动模拟器。当前未保存的界面状态可能丢失。';
  }

  @override
  String get enableAndRestart => '启用并重启';

  @override
  String hardwareKeyboardEnabled(Object name) {
    return '$name 已启用电脑键盘';
  }

  @override
  String get devMenu => '开发菜单';

  @override
  String get reloadJs => '重载 JS';

  @override
  String get deleteEllipsis => '删除…';

  @override
  String get androidSdkNotFound => '未找到 Android SDK';

  @override
  String get androidSdkNotFoundDescription =>
      '请安装 Android SDK 并设置 ANDROID_HOME，以管理 Android 模拟器。';

  @override
  String iosSimulatorSummary(Object count, Object size) {
    return '$count 台模拟器 · 共 $size';
  }

  @override
  String staleAfterDays(Object days) {
    return '超过 $days 天未使用视为闲置';
  }

  @override
  String stopIosSimulatorContent(Object name) {
    return '确定停止 $name 吗？';
  }

  @override
  String get eraseContentTitle => '抹掉内容？';

  @override
  String eraseContentDescription(Object name) {
    return '抹掉 $name 的所有内容和设置？模拟器设备本身会保留。';
  }

  @override
  String get erase => '抹掉';

  @override
  String get deleteSimulatorTitle => '删除模拟器？';

  @override
  String deleteSimulatorDescription(Object name, Object size) {
    return '$name 将被永久移除（$size）。';
  }

  @override
  String get stale => '闲置';

  @override
  String iosSimulatorDetailLast(
    Object date,
    Object runtime,
    Object size,
    Object state,
  ) {
    return '$runtime · $state · 上次启动：$date · $size';
  }

  @override
  String iosSimulatorDetailNever(Object runtime, Object size, Object state) {
    return '$runtime · $state · 从未启动 · $size';
  }

  @override
  String get targetIosRuntimeCaches => 'iOS 运行时缓存';

  @override
  String get targetIosRuntimeCachesDescription =>
      'Xcode 生成的 dyld 缓存；再次使用对应运行时时会自动重建。';

  @override
  String get targetIosRuntimes => 'iOS 运行时镜像';

  @override
  String get targetIosRuntimesDescription => '已下载的 iOS 版本；可移除不再用于测试的旧运行时。';

  @override
  String get targetIosSimulators => 'iOS 模拟器设备';

  @override
  String get targetIosSimulatorsDescription => '模拟器应用数据；通过 xcrun simctl 安全移除。';

  @override
  String get targetAppCaches => '应用缓存';

  @override
  String get targetAppCachesDescription => '主磁盘上的可重建应用缓存；系统缓存已排除。';

  @override
  String get targetQqUpdates => 'QQ 更新下载';

  @override
  String get targetQqUpdatesDescription => 'QQ 已下载并解压的更新；需要时可以重新下载。';

  @override
  String get targetChromeModels => 'Chrome 已下载模型';

  @override
  String get targetChromeModelsDescription => '设备端优化模型；Chrome 可能会重新下载。';

  @override
  String get targetGoogleUpdaterCache => 'Google 更新缓存';

  @override
  String get targetGoogleUpdaterCacheDescription =>
      'Chrome 和 Google 组件的已下载更新包。';

  @override
  String get targetAppSupportCaches => '应用更新缓存';

  @override
  String get targetAppSupportCachesDescription =>
      'Application Support 中保存的安装器和更新包。';

  @override
  String get targetAndroidStudioBackups => 'Android Studio 备份';

  @override
  String get targetAndroidStudioBackupsDescription => 'IDE 升级时创建的配置备份；删除前请确认。';

  @override
  String get targetDownloadArchives => '下载的压缩包与安装器';

  @override
  String get targetDownloadArchivesDescription =>
      '下载目录中的大型压缩包和安装器；这些是个人文件，请逐项确认。';

  @override
  String get targetGradleCaches => 'Gradle 缓存';

  @override
  String get targetGradleCachesDescription => '构建和依赖缓存；下次构建会重新下载依赖并编译。';

  @override
  String get targetGradleWrapper => 'Gradle Wrapper 发行版';

  @override
  String get targetGradleWrapperDescription => '已下载的 Gradle 版本；下次对应构建会自动恢复。';

  @override
  String get targetKonanRuntimes => 'Kotlin/Native 工具链';

  @override
  String get targetKonanRuntimesDescription =>
      '已下载的 Kotlin/Native 版本；请保留活跃项目使用的版本。';

  @override
  String get targetCodexRuntimes => 'Codex 运行时缓存';

  @override
  String get targetCodexRuntimesDescription => '内置执行运行时；Codex 再次需要时会自动恢复。';

  @override
  String get targetLldbCache => 'LLDB 模块缓存';

  @override
  String get targetLldbCacheDescription => '已下载的调试模块和符号；后续调试时会重新生成。';

  @override
  String get targetCodexTemp => 'Codex 临时文件';

  @override
  String get targetCodexTempDescription => '插件备份和暂存文件；清理前请关闭 Codex。';

  @override
  String get targetNpmCache => 'npm 缓存';

  @override
  String get targetNpmCacheDescription => 'npm 包缓存；安装依赖时会自动重建。';

  @override
  String get targetNodeGyp => 'node-gyp 缓存';

  @override
  String get targetNodeGypDescription => '原生扩展构建缓存；编译原生包时会重建。';

  @override
  String get targetCocoapods => 'CocoaPods 缓存';

  @override
  String get targetCocoapodsDescription =>
      'iOS/macOS 依赖缓存；下次 pod install 会重新下载。';

  @override
  String get targetPipCache => 'pip 缓存';

  @override
  String get targetPipCacheDescription => 'Python 包缓存；安装 Python 包时会重建。';

  @override
  String get targetHomebrew => 'Homebrew 缓存';

  @override
  String get targetHomebrewDescription => '已下载的软件包归档；已安装的软件不受影响。';

  @override
  String get targetPlaywright => 'Playwright 浏览器';

  @override
  String get targetPlaywrightDescription =>
      '用于测试的浏览器二进制；可通过 playwright install 恢复。';

  @override
  String get targetJetbrainsCache => 'JetBrains IDE 缓存';

  @override
  String get targetJetbrainsCacheDescription => 'IDE 索引和缓存；清理后首次启动会较慢。';

  @override
  String get targetXcodeDerived => 'Xcode DerivedData';

  @override
  String get targetXcodeDerivedDescription => '构建中间产物；下次构建会执行完整编译。';

  @override
  String get targetXcodeArchives => 'Xcode 归档';

  @override
  String get targetXcodeArchivesDescription => '发布归档；仅在不再需要已归档构建时删除。';

  @override
  String get targetAppLogs => '应用日志';

  @override
  String get targetAppLogsDescription => '主磁盘上各应用保存的日志文件。';
}
