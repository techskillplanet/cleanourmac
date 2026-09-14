import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'Mobile 开发助手'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In zh, this message translates to:
  /// **'面向移动研发的本地工具箱'**
  String get appTagline;

  /// No description provided for @workspaceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'设备、存储与开发环境状态一目了然'**
  String get workspaceSubtitle;

  /// No description provided for @deviceLabSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'集中管理 Android、iOS 设备与调测工具'**
  String get deviceLabSubtitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'按你的研发习惯配置扫描与安全规则'**
  String get settingsSubtitle;

  /// No description provided for @localPrivate.
  ///
  /// In zh, this message translates to:
  /// **'本地运行 · 隐私优先'**
  String get localPrivate;

  /// No description provided for @brandEdition.
  ///
  /// In zh, this message translates to:
  /// **'MOBILE DEV TOOLKIT'**
  String get brandEdition;

  /// No description provided for @deviceOverview.
  ///
  /// In zh, this message translates to:
  /// **'设备状态'**
  String get deviceOverview;

  /// No description provided for @quickActions.
  ///
  /// In zh, this message translates to:
  /// **'快捷操作'**
  String get quickActions;

  /// No description provided for @openDeviceLab.
  ///
  /// In zh, this message translates to:
  /// **'打开设备调测'**
  String get openDeviceLab;

  /// No description provided for @startDiskScan.
  ///
  /// In zh, this message translates to:
  /// **'扫描开发环境'**
  String get startDiskScan;

  /// No description provided for @androidDeviceCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 台 Android 设备'**
  String androidDeviceCount(Object count);

  /// No description provided for @iosDeviceCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 台 iOS 模拟器'**
  String iosDeviceCount(Object count);

  /// No description provided for @reclaimableMetric.
  ///
  /// In zh, this message translates to:
  /// **'可清理空间'**
  String get reclaimableMetric;

  /// No description provided for @storageOverview.
  ///
  /// In zh, this message translates to:
  /// **'存储概览'**
  String get storageOverview;

  /// No description provided for @storageSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'主数据卷的实际磁盘占用'**
  String get storageSubtitle;

  /// No description provided for @noScanData.
  ///
  /// In zh, this message translates to:
  /// **'尚未扫描开发缓存'**
  String get noScanData;

  /// No description provided for @scanNow.
  ///
  /// In zh, this message translates to:
  /// **'立即扫描'**
  String get scanNow;

  /// No description provided for @adbDeviceSummary.
  ///
  /// In zh, this message translates to:
  /// **'{running} 台在线 · 共 {total} 台设备'**
  String adbDeviceSummary(Object running, Object total);

  /// No description provided for @androidTab.
  ///
  /// In zh, this message translates to:
  /// **'Android · {count}'**
  String androidTab(Object count);

  /// No description provided for @iosTab.
  ///
  /// In zh, this message translates to:
  /// **'iOS · {count}'**
  String iosTab(Object count);

  /// No description provided for @adbReady.
  ///
  /// In zh, this message translates to:
  /// **'ADB 已就绪'**
  String get adbReady;

  /// No description provided for @developerTools.
  ///
  /// In zh, this message translates to:
  /// **'调测快捷工具'**
  String get developerTools;

  /// No description provided for @scanPageSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'识别可重建缓存，以可审查的方式安全释放空间'**
  String get scanPageSubtitle;

  /// No description provided for @largeFilesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'定位真实占用磁盘空间的大文件并按风险分类'**
  String get largeFilesSubtitle;

  /// No description provided for @nodeModulesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'按最近使用时间管理项目依赖目录'**
  String get nodeModulesSubtitle;

  /// No description provided for @aiAgentCaches.
  ///
  /// In zh, this message translates to:
  /// **'AI Agent 缓存'**
  String get aiAgentCaches;

  /// No description provided for @aiAgentCachesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'检测并清理可重建缓存，账号、配置与会话数据始终保留'**
  String get aiAgentCachesSubtitle;

  /// No description provided for @detectCaches.
  ///
  /// In zh, this message translates to:
  /// **'重新检测'**
  String get detectCaches;

  /// No description provided for @scanningCaches.
  ///
  /// In zh, this message translates to:
  /// **'正在检测缓存…'**
  String get scanningCaches;

  /// No description provided for @aiCachePrivacyTitle.
  ///
  /// In zh, this message translates to:
  /// **'仅清理白名单缓存'**
  String get aiCachePrivacyTitle;

  /// No description provided for @aiCachePrivacyDescription.
  ///
  /// In zh, this message translates to:
  /// **'不会删除账号凭据、配置、项目规则、代码、会话历史、聊天记录或已安装扩展。所有项目默认不选中。'**
  String get aiCachePrivacyDescription;

  /// No description provided for @aiCacheCloseAppsHint.
  ///
  /// In zh, this message translates to:
  /// **'清理前请关闭对应 AI Agent，避免缓存被占用或立即重新生成。'**
  String get aiCacheCloseAppsHint;

  /// No description provided for @aiCacheDetectedSummary.
  ///
  /// In zh, this message translates to:
  /// **'检测到 {count} 个缓存目录 · {agents} 个 Agent · 共 {size}'**
  String aiCacheDetectedSummary(Object agents, Object count, Object size);

  /// No description provided for @aiCacheSelectedSummary.
  ///
  /// In zh, this message translates to:
  /// **'已选择 {count} 项 · {size}'**
  String aiCacheSelectedSummary(Object count, Object size);

  /// No description provided for @noAiCachesFound.
  ///
  /// In zh, this message translates to:
  /// **'未检测到 AI Agent 缓存'**
  String get noAiCachesFound;

  /// No description provided for @noAiCachesFoundDescription.
  ///
  /// In zh, this message translates to:
  /// **'已检查 Claude Code、OpenCode、Trae、Qoder、Codex 和 Cursor 的已知缓存目录。'**
  String get noAiCachesFoundDescription;

  /// No description provided for @selectAgentCaches.
  ///
  /// In zh, this message translates to:
  /// **'选择此 Agent 的缓存'**
  String get selectAgentCaches;

  /// No description provided for @cleanSelectedCaches.
  ///
  /// In zh, this message translates to:
  /// **'清理所选缓存'**
  String get cleanSelectedCaches;

  /// No description provided for @confirmAiCacheCleanTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认清理 AI Agent 缓存'**
  String get confirmAiCacheCleanTitle;

  /// No description provided for @confirmAiCacheCleanDescription.
  ///
  /// In zh, this message translates to:
  /// **'以下目录中的可重建缓存将被清空，目录本身会保留。此操作不会清理会话和配置。'**
  String get confirmAiCacheCleanDescription;

  /// No description provided for @aiCacheConsentLabel.
  ///
  /// In zh, this message translates to:
  /// **'我已关闭相关 AI Agent，并同意清理所选缓存'**
  String get aiCacheConsentLabel;

  /// No description provided for @aiCacheConsentRequired.
  ///
  /// In zh, this message translates to:
  /// **'勾选同意后才能继续'**
  String get aiCacheConsentRequired;

  /// No description provided for @clearCaches.
  ///
  /// In zh, this message translates to:
  /// **'确认清理'**
  String get clearCaches;

  /// No description provided for @aiCacheCleaned.
  ///
  /// In zh, this message translates to:
  /// **'已清理 {count} 项，释放 {size}'**
  String aiCacheCleaned(Object count, Object size);

  /// No description provided for @aiCacheRebuildable.
  ///
  /// In zh, this message translates to:
  /// **'可重建'**
  String get aiCacheRebuildable;

  /// No description provided for @aiCachePathCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个缓存目录'**
  String aiCachePathCount(Object count);

  /// No description provided for @claudeCode.
  ///
  /// In zh, this message translates to:
  /// **'Claude Code'**
  String get claudeCode;

  /// No description provided for @openCode.
  ///
  /// In zh, this message translates to:
  /// **'OpenCode'**
  String get openCode;

  /// No description provided for @trae.
  ///
  /// In zh, this message translates to:
  /// **'Trae / Trae SOLO'**
  String get trae;

  /// No description provided for @qoder.
  ///
  /// In zh, this message translates to:
  /// **'Qoder'**
  String get qoder;

  /// No description provided for @codex.
  ///
  /// In zh, this message translates to:
  /// **'Codex'**
  String get codex;

  /// No description provided for @cursor.
  ///
  /// In zh, this message translates to:
  /// **'Cursor'**
  String get cursor;

  /// No description provided for @cacheKindCli.
  ///
  /// In zh, this message translates to:
  /// **'命令行缓存'**
  String get cacheKindCli;

  /// No description provided for @cacheKindDesktop.
  ///
  /// In zh, this message translates to:
  /// **'桌面应用缓存'**
  String get cacheKindDesktop;

  /// No description provided for @cacheKindCode.
  ///
  /// In zh, this message translates to:
  /// **'代码缓存'**
  String get cacheKindCode;

  /// No description provided for @cacheKindGpu.
  ///
  /// In zh, this message translates to:
  /// **'图形缓存'**
  String get cacheKindGpu;

  /// No description provided for @cacheKindExtensions.
  ///
  /// In zh, this message translates to:
  /// **'扩展下载缓存'**
  String get cacheKindExtensions;

  /// No description provided for @cacheKindUpdater.
  ///
  /// In zh, this message translates to:
  /// **'更新下载缓存'**
  String get cacheKindUpdater;

  /// No description provided for @cacheKindShared.
  ///
  /// In zh, this message translates to:
  /// **'共享客户端缓存'**
  String get cacheKindShared;

  /// No description provided for @cacheKindTemporary.
  ///
  /// In zh, this message translates to:
  /// **'临时文件'**
  String get cacheKindTemporary;

  /// No description provided for @cacheKindRuntime.
  ///
  /// In zh, this message translates to:
  /// **'运行时缓存'**
  String get cacheKindRuntime;

  /// No description provided for @reactNative.
  ///
  /// In zh, this message translates to:
  /// **'React Native'**
  String get reactNative;

  /// No description provided for @reactNativeSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'项目脚本、Metro 服务和设备调测的快捷工作台'**
  String get reactNativeSubtitle;

  /// No description provided for @rnProjects.
  ///
  /// In zh, this message translates to:
  /// **'RN 项目'**
  String get rnProjects;

  /// No description provided for @addRnProject.
  ///
  /// In zh, this message translates to:
  /// **'添加项目'**
  String get addRnProject;

  /// No description provided for @chooseRnProject.
  ///
  /// In zh, this message translates to:
  /// **'选择 React Native 项目目录'**
  String get chooseRnProject;

  /// No description provided for @noRnProjects.
  ///
  /// In zh, this message translates to:
  /// **'未发现 React Native 项目'**
  String get noRnProjects;

  /// No description provided for @noRnProjectsDescription.
  ///
  /// In zh, this message translates to:
  /// **'可添加项目目录，或将项目放在 Projects、Developer、StudioProjects 或外接磁盘的 code 目录下。'**
  String get noRnProjectsDescription;

  /// No description provided for @invalidRnProject.
  ///
  /// In zh, this message translates to:
  /// **'所选目录不是有效的 React Native 项目'**
  String get invalidRnProject;

  /// No description provided for @projectAdded.
  ///
  /// In zh, this message translates to:
  /// **'已添加项目：{name}'**
  String projectAdded(Object name);

  /// No description provided for @selectedProject.
  ///
  /// In zh, this message translates to:
  /// **'当前项目'**
  String get selectedProject;

  /// No description provided for @quickCommands.
  ///
  /// In zh, this message translates to:
  /// **'高频命令'**
  String get quickCommands;

  /// No description provided for @moreScripts.
  ///
  /// In zh, this message translates to:
  /// **'更多脚本'**
  String get moreScripts;

  /// No description provided for @startMetro.
  ///
  /// In zh, this message translates to:
  /// **'启动 Metro'**
  String get startMetro;

  /// No description provided for @resetMetroCache.
  ///
  /// In zh, this message translates to:
  /// **'重置 Metro 缓存'**
  String get resetMetroCache;

  /// No description provided for @runAndroid.
  ///
  /// In zh, this message translates to:
  /// **'运行 Android'**
  String get runAndroid;

  /// No description provided for @runIos.
  ///
  /// In zh, this message translates to:
  /// **'运行 iOS'**
  String get runIos;

  /// No description provided for @runIosSetup.
  ///
  /// In zh, this message translates to:
  /// **'安装依赖并运行 iOS'**
  String get runIosSetup;

  /// No description provided for @runCharles.
  ///
  /// In zh, this message translates to:
  /// **'启动 Charles'**
  String get runCharles;

  /// No description provided for @openRnDevTools.
  ///
  /// In zh, this message translates to:
  /// **'打开 RN DevTools'**
  String get openRnDevTools;

  /// No description provided for @openProject.
  ///
  /// In zh, this message translates to:
  /// **'打开项目'**
  String get openProject;

  /// No description provided for @openProjectHint.
  ///
  /// In zh, this message translates to:
  /// **'选择打开方式'**
  String get openProjectHint;

  /// No description provided for @openWithCodex.
  ///
  /// In zh, this message translates to:
  /// **'Codex 桌面端'**
  String get openWithCodex;

  /// No description provided for @openWithCodexCli.
  ///
  /// In zh, this message translates to:
  /// **'Codex CLI'**
  String get openWithCodexCli;

  /// No description provided for @openWithCursor.
  ///
  /// In zh, this message translates to:
  /// **'Cursor'**
  String get openWithCursor;

  /// No description provided for @openWithVsCode.
  ///
  /// In zh, this message translates to:
  /// **'VS Code'**
  String get openWithVsCode;

  /// No description provided for @openWithAndroidStudio.
  ///
  /// In zh, this message translates to:
  /// **'Android Studio（Android）'**
  String get openWithAndroidStudio;

  /// No description provided for @openWithXcode.
  ///
  /// In zh, this message translates to:
  /// **'Xcode（iOS）'**
  String get openWithXcode;

  /// No description provided for @openWithQoder.
  ///
  /// In zh, this message translates to:
  /// **'Qoder'**
  String get openWithQoder;

  /// No description provided for @openWithTrae.
  ///
  /// In zh, this message translates to:
  /// **'Trae'**
  String get openWithTrae;

  /// No description provided for @openWithWebStorm.
  ///
  /// In zh, this message translates to:
  /// **'WebStorm'**
  String get openWithWebStorm;

  /// No description provided for @openWithZed.
  ///
  /// In zh, this message translates to:
  /// **'Zed'**
  String get openWithZed;

  /// No description provided for @openWithWindsurf.
  ///
  /// In zh, this message translates to:
  /// **'Windsurf'**
  String get openWithWindsurf;

  /// No description provided for @openInTerminal.
  ///
  /// In zh, this message translates to:
  /// **'Terminal'**
  String get openInTerminal;

  /// No description provided for @projectOpenedWith.
  ///
  /// In zh, this message translates to:
  /// **'已使用 {app} 打开 {name}'**
  String projectOpenedWith(Object app, Object name);

  /// No description provided for @openInCursor.
  ///
  /// In zh, this message translates to:
  /// **'在 Cursor 中打开'**
  String get openInCursor;

  /// No description provided for @commandStarted.
  ///
  /// In zh, this message translates to:
  /// **'已在 Terminal 启动：{command}'**
  String commandStarted(Object command);

  /// No description provided for @metroService.
  ///
  /// In zh, this message translates to:
  /// **'Metro 服务'**
  String get metroService;

  /// No description provided for @metroRunning.
  ///
  /// In zh, this message translates to:
  /// **'端口 {port} 正在运行'**
  String metroRunning(Object port);

  /// No description provided for @metroStopped.
  ///
  /// In zh, this message translates to:
  /// **'端口 {port} 未运行'**
  String metroStopped(Object port);

  /// No description provided for @metroProcess.
  ///
  /// In zh, this message translates to:
  /// **'{process} · PID {pid}'**
  String metroProcess(Object pid, Object process);

  /// No description provided for @metroWatching.
  ///
  /// In zh, this message translates to:
  /// **'每 4 秒自动检测'**
  String get metroWatching;

  /// No description provided for @rnDeviceTools.
  ///
  /// In zh, this message translates to:
  /// **'RN 设备快捷调测'**
  String get rnDeviceTools;

  /// No description provided for @androidDevMenu.
  ///
  /// In zh, this message translates to:
  /// **'Android 开发菜单'**
  String get androidDevMenu;

  /// No description provided for @androidReload.
  ///
  /// In zh, this message translates to:
  /// **'Android 重载'**
  String get androidReload;

  /// No description provided for @androidMetroReverse.
  ///
  /// In zh, this message translates to:
  /// **'连接 Android Metro'**
  String get androidMetroReverse;

  /// No description provided for @iosDevMenu.
  ///
  /// In zh, this message translates to:
  /// **'iOS 开发菜单'**
  String get iosDevMenu;

  /// No description provided for @iosReload.
  ///
  /// In zh, this message translates to:
  /// **'iOS 重载'**
  String get iosReload;

  /// No description provided for @metroReverseDone.
  ///
  /// In zh, this message translates to:
  /// **'已为 {name} 映射 Metro 端口 {port}'**
  String metroReverseDone(Object name, Object port);

  /// No description provided for @noRunningAndroid.
  ///
  /// In zh, this message translates to:
  /// **'没有在线 Android 设备'**
  String get noRunningAndroid;

  /// No description provided for @noBootedIos.
  ///
  /// In zh, this message translates to:
  /// **'没有已启动的 iOS 模拟器'**
  String get noBootedIos;

  /// No description provided for @rnProjectRoots.
  ///
  /// In zh, this message translates to:
  /// **'React Native 项目目录'**
  String get rnProjectRoots;

  /// No description provided for @rnProjectRootsDescription.
  ///
  /// In zh, this message translates to:
  /// **'用于固定常用 RN 项目；工作台也会自动发现常见开发目录下的项目。'**
  String get rnProjectRootsDescription;

  /// No description provided for @metroPort.
  ///
  /// In zh, this message translates to:
  /// **'默认 Metro 端口'**
  String get metroPort;

  /// No description provided for @iosDebugTools.
  ///
  /// In zh, this message translates to:
  /// **'iOS 调测工具'**
  String get iosDebugTools;

  /// No description provided for @copyUdid.
  ///
  /// In zh, this message translates to:
  /// **'复制 UDID'**
  String get copyUdid;

  /// No description provided for @udidCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制 UDID：{udid}'**
  String udidCopied(Object udid);

  /// No description provided for @openSimulatorLogs.
  ///
  /// In zh, this message translates to:
  /// **'实时日志'**
  String get openSimulatorLogs;

  /// No description provided for @installIosApp.
  ///
  /// In zh, this message translates to:
  /// **'安装 .app'**
  String get installIosApp;

  /// No description provided for @chooseIosAppPrompt.
  ///
  /// In zh, this message translates to:
  /// **'选择要安装到模拟器的 .app'**
  String get chooseIosAppPrompt;

  /// No description provided for @iosAppInstalled.
  ///
  /// In zh, this message translates to:
  /// **'已将应用安装到 {name}'**
  String iosAppInstalled(Object name);

  /// No description provided for @openUrl.
  ///
  /// In zh, this message translates to:
  /// **'打开 URL'**
  String get openUrl;

  /// No description provided for @openUrlTitle.
  ///
  /// In zh, this message translates to:
  /// **'在模拟器中打开 URL'**
  String get openUrlTitle;

  /// No description provided for @urlHint.
  ///
  /// In zh, this message translates to:
  /// **'例如 myapp://debug 或 http://localhost:8081'**
  String get urlHint;

  /// No description provided for @invalidUrl.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效 URL'**
  String get invalidUrl;

  /// No description provided for @iosRnShortcutHint.
  ///
  /// In zh, this message translates to:
  /// **'RN iOS 开发菜单使用 Command + D，重载使用 Command + R。首次使用可能需要允许辅助功能控制。'**
  String get iosRnShortcutHint;

  /// No description provided for @projectCaches.
  ///
  /// In zh, this message translates to:
  /// **'项目缓存'**
  String get projectCaches;

  /// No description provided for @projectCachesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'检索 Flutter、Android、iOS、React Native 与 Web 项目的生成文件'**
  String get projectCachesSubtitle;

  /// No description provided for @projectCacheSafetyTitle.
  ///
  /// In zh, this message translates to:
  /// **'只识别可重新生成的目录'**
  String get projectCacheSafetyTitle;

  /// No description provided for @projectCacheSafetyDescription.
  ///
  /// In zh, this message translates to:
  /// **'不会删除源码、图片资源、配置、签名、证书、锁文件、数据库或 node_modules 本体。所有项目默认不选中。'**
  String get projectCacheSafetyDescription;

  /// No description provided for @projectCacheSummary.
  ///
  /// In zh, this message translates to:
  /// **'发现 {count} 个缓存目录 · {projects} 个项目 · 共 {size}'**
  String projectCacheSummary(Object count, Object projects, Object size);

  /// No description provided for @projectCacheEmpty.
  ///
  /// In zh, this message translates to:
  /// **'未发现项目缓存'**
  String get projectCacheEmpty;

  /// No description provided for @projectCacheEmptyDescription.
  ///
  /// In zh, this message translates to:
  /// **'已扫描常见开发目录和设置中配置的项目目录。'**
  String get projectCacheEmptyDescription;

  /// No description provided for @projectCacheKindTool.
  ///
  /// In zh, this message translates to:
  /// **'工具状态'**
  String get projectCacheKindTool;

  /// No description provided for @projectCacheKindBuild.
  ///
  /// In zh, this message translates to:
  /// **'构建产物'**
  String get projectCacheKindBuild;

  /// No description provided for @projectCacheKindDependencies.
  ///
  /// In zh, this message translates to:
  /// **'生成的依赖产物'**
  String get projectCacheKindDependencies;

  /// No description provided for @projectCacheKindBundler.
  ///
  /// In zh, this message translates to:
  /// **'打包器缓存'**
  String get projectCacheKindBundler;

  /// No description provided for @projectCacheKindTest.
  ///
  /// In zh, this message translates to:
  /// **'测试与覆盖率产物'**
  String get projectCacheKindTest;

  /// No description provided for @projectCacheEcosystemFlutter.
  ///
  /// In zh, this message translates to:
  /// **'Flutter'**
  String get projectCacheEcosystemFlutter;

  /// No description provided for @projectCacheEcosystemAndroid.
  ///
  /// In zh, this message translates to:
  /// **'Android'**
  String get projectCacheEcosystemAndroid;

  /// No description provided for @projectCacheEcosystemIos.
  ///
  /// In zh, this message translates to:
  /// **'iOS'**
  String get projectCacheEcosystemIos;

  /// No description provided for @projectCacheEcosystemRn.
  ///
  /// In zh, this message translates to:
  /// **'React Native'**
  String get projectCacheEcosystemRn;

  /// No description provided for @projectCacheEcosystemWeb.
  ///
  /// In zh, this message translates to:
  /// **'Web'**
  String get projectCacheEcosystemWeb;

  /// No description provided for @confirmProjectCacheCleanTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认清理项目缓存'**
  String get confirmProjectCacheCleanTitle;

  /// No description provided for @confirmProjectCacheCleanDescription.
  ///
  /// In zh, this message translates to:
  /// **'所选目录会被完整删除，并在下次构建或安装依赖时重新生成。'**
  String get confirmProjectCacheCleanDescription;

  /// No description provided for @projectCacheConsentLabel.
  ///
  /// In zh, this message translates to:
  /// **'我已确认所选路径，并同意删除这些生成文件'**
  String get projectCacheConsentLabel;

  /// No description provided for @projectCacheCleaned.
  ///
  /// In zh, this message translates to:
  /// **'已清理 {count} 项，释放 {size}'**
  String projectCacheCleaned(Object count, Object size);

  /// No description provided for @developmentRoots.
  ///
  /// In zh, this message translates to:
  /// **'开发项目扫描目录'**
  String get developmentRoots;

  /// No description provided for @developmentRootsDescription.
  ///
  /// In zh, this message translates to:
  /// **'用于检索 Flutter、Android、iOS、React Native 和 Web 项目的构建与工具缓存。'**
  String get developmentRootsDescription;

  /// No description provided for @targetAndroidCliCache.
  ///
  /// In zh, this message translates to:
  /// **'Android CLI 缓存'**
  String get targetAndroidCliCache;

  /// No description provided for @targetAndroidCliCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'Android 命令工具下载的元数据和临时包数据。'**
  String get targetAndroidCliCacheDescription;

  /// No description provided for @targetAndroidStudioCache.
  ///
  /// In zh, this message translates to:
  /// **'Android Studio 缓存'**
  String get targetAndroidStudioCache;

  /// No description provided for @targetAndroidStudioCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'IDE 索引和生成缓存；重启后会重新构建。'**
  String get targetAndroidStudioCacheDescription;

  /// No description provided for @targetDartPubHosted.
  ///
  /// In zh, this message translates to:
  /// **'Dart Pub 托管包缓存'**
  String get targetDartPubHosted;

  /// No description provided for @targetDartPubHostedDescription.
  ///
  /// In zh, this message translates to:
  /// **'已下载的 Dart 与 Flutter 包；需要时由 Pub 重新获取。'**
  String get targetDartPubHostedDescription;

  /// No description provided for @targetDartPubGit.
  ///
  /// In zh, this message translates to:
  /// **'Dart Pub Git 缓存'**
  String get targetDartPubGit;

  /// No description provided for @targetDartPubGitDescription.
  ///
  /// In zh, this message translates to:
  /// **'Pub 下载的 Git 依赖；需要时可重新克隆。'**
  String get targetDartPubGitDescription;

  /// No description provided for @targetYarnCache.
  ///
  /// In zh, this message translates to:
  /// **'Yarn 缓存'**
  String get targetYarnCache;

  /// No description provided for @targetYarnCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'已下载的 Yarn 包；下次安装依赖时重新获取。'**
  String get targetYarnCacheDescription;

  /// No description provided for @targetYarnXdgCache.
  ///
  /// In zh, this message translates to:
  /// **'Yarn XDG 缓存'**
  String get targetYarnXdgCache;

  /// No description provided for @targetYarnXdgCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'保存在 XDG 缓存目录中的 Yarn 包缓存。'**
  String get targetYarnXdgCacheDescription;

  /// No description provided for @targetPnpmStore.
  ///
  /// In zh, this message translates to:
  /// **'pnpm Store'**
  String get targetPnpmStore;

  /// No description provided for @targetPnpmStoreDescription.
  ///
  /// In zh, this message translates to:
  /// **'pnpm 内容寻址包存储；清理后可能需要重新下载。'**
  String get targetPnpmStoreDescription;

  /// No description provided for @targetPnpmLegacyStore.
  ///
  /// In zh, this message translates to:
  /// **'pnpm 旧版 Store'**
  String get targetPnpmLegacyStore;

  /// No description provided for @targetPnpmLegacyStoreDescription.
  ///
  /// In zh, this message translates to:
  /// **'旧版本 pnpm 留下的包存储。'**
  String get targetPnpmLegacyStoreDescription;

  /// No description provided for @targetBunCache.
  ///
  /// In zh, this message translates to:
  /// **'Bun 包缓存'**
  String get targetBunCache;

  /// No description provided for @targetBunCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'Bun 下载的依赖包；安装时会重新获取。'**
  String get targetBunCacheDescription;

  /// No description provided for @targetCorepackCache.
  ///
  /// In zh, this message translates to:
  /// **'Corepack 缓存'**
  String get targetCorepackCache;

  /// No description provided for @targetCorepackCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'Corepack 下载的包管理器发行版本。'**
  String get targetCorepackCacheDescription;

  /// No description provided for @targetSwiftpmCache.
  ///
  /// In zh, this message translates to:
  /// **'Swift Package Manager 缓存'**
  String get targetSwiftpmCache;

  /// No description provided for @targetSwiftpmCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'Swift 包元数据和构建产物；SwiftPM 会重新生成。'**
  String get targetSwiftpmCacheDescription;

  /// No description provided for @targetSwiftpmRepositories.
  ///
  /// In zh, this message translates to:
  /// **'SwiftPM 仓库缓存'**
  String get targetSwiftpmRepositories;

  /// No description provided for @targetSwiftpmRepositoriesDescription.
  ///
  /// In zh, this message translates to:
  /// **'缓存的 Swift 包仓库；需要时会重新克隆。'**
  String get targetSwiftpmRepositoriesDescription;

  /// No description provided for @targetCarthageCache.
  ///
  /// In zh, this message translates to:
  /// **'Carthage 缓存'**
  String get targetCarthageCache;

  /// No description provided for @targetCarthageCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'Carthage 下载的依赖产物和仓库元数据。'**
  String get targetCarthageCacheDescription;

  /// No description provided for @targetCypress.
  ///
  /// In zh, this message translates to:
  /// **'Cypress 缓存'**
  String get targetCypress;

  /// No description provided for @targetCypressDescription.
  ///
  /// In zh, this message translates to:
  /// **'已下载的 Cypress 测试运行器；需要时重新安装。'**
  String get targetCypressDescription;

  /// No description provided for @targetDenoCache.
  ///
  /// In zh, this message translates to:
  /// **'Deno 缓存'**
  String get targetDenoCache;

  /// No description provided for @targetDenoCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'Deno 项目下载的模块和编译产物。'**
  String get targetDenoCacheDescription;

  /// No description provided for @targetXcodeDeviceSupport.
  ///
  /// In zh, this message translates to:
  /// **'Xcode 设备支持文件'**
  String get targetXcodeDeviceSupport;

  /// No description provided for @targetXcodeDeviceSupportDescription.
  ///
  /// In zh, this message translates to:
  /// **'连接过的 iOS 版本对应符号和支持文件；请确认旧版本后清理。'**
  String get targetXcodeDeviceSupportDescription;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @languageDescription.
  ///
  /// In zh, this message translates to:
  /// **'选择界面显示语言'**
  String get languageDescription;

  /// No description provided for @languageChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @overview.
  ///
  /// In zh, this message translates to:
  /// **'工作台'**
  String get overview;

  /// No description provided for @scanAndClean.
  ///
  /// In zh, this message translates to:
  /// **'开发环境清理'**
  String get scanAndClean;

  /// No description provided for @largeFiles.
  ///
  /// In zh, this message translates to:
  /// **'大文件分析'**
  String get largeFiles;

  /// No description provided for @nodeModules.
  ///
  /// In zh, this message translates to:
  /// **'Node Modules'**
  String get nodeModules;

  /// No description provided for @simulators.
  ///
  /// In zh, this message translates to:
  /// **'设备调测'**
  String get simulators;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @scan.
  ///
  /// In zh, this message translates to:
  /// **'扫描'**
  String get scan;

  /// No description provided for @scanning.
  ///
  /// In zh, this message translates to:
  /// **'扫描中…'**
  String get scanning;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get refresh;

  /// No description provided for @selectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In zh, this message translates to:
  /// **'取消全选'**
  String get deselectAll;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @permanentlyDelete.
  ///
  /// In zh, this message translates to:
  /// **'永久删除'**
  String get permanentlyDelete;

  /// No description provided for @dismiss.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get dismiss;

  /// No description provided for @open.
  ///
  /// In zh, this message translates to:
  /// **'打开'**
  String get open;

  /// No description provided for @stop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get stop;

  /// No description provided for @boot.
  ///
  /// In zh, this message translates to:
  /// **'启动'**
  String get boot;

  /// No description provided for @moreActions.
  ///
  /// In zh, this message translates to:
  /// **'更多操作'**
  String get moreActions;

  /// No description provided for @errorMessage.
  ///
  /// In zh, this message translates to:
  /// **'错误：{error}'**
  String errorMessage(Object error);

  /// No description provided for @operationError.
  ///
  /// In zh, this message translates to:
  /// **'{title}：{error}'**
  String operationError(Object error, Object title);

  /// No description provided for @notFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到'**
  String get notFound;

  /// No description provided for @noItemsFound.
  ///
  /// In zh, this message translates to:
  /// **'未发现项目'**
  String get noItemsFound;

  /// No description provided for @itemCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 项'**
  String itemCount(Object count);

  /// No description provided for @overviewTotalDisk.
  ///
  /// In zh, this message translates to:
  /// **'磁盘总容量'**
  String get overviewTotalDisk;

  /// No description provided for @overviewUsed.
  ///
  /// In zh, this message translates to:
  /// **'已使用'**
  String get overviewUsed;

  /// No description provided for @overviewRecoverable.
  ///
  /// In zh, this message translates to:
  /// **'可清理'**
  String get overviewRecoverable;

  /// No description provided for @overviewFree.
  ///
  /// In zh, this message translates to:
  /// **'可用'**
  String get overviewFree;

  /// No description provided for @overviewReadyToRecover.
  ///
  /// In zh, this message translates to:
  /// **'可释放空间'**
  String get overviewReadyToRecover;

  /// No description provided for @categories.
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get categories;

  /// No description provided for @mainDiskScan.
  ///
  /// In zh, this message translates to:
  /// **'主磁盘扫描'**
  String get mainDiskScan;

  /// No description provided for @scanningTarget.
  ///
  /// In zh, this message translates to:
  /// **'正在扫描 {target}…'**
  String scanningTarget(Object target);

  /// No description provided for @cleaningReclaimed.
  ///
  /// In zh, this message translates to:
  /// **'正在清理…已释放 {size}'**
  String cleaningReclaimed(Object size);

  /// No description provided for @scanEmptyPrompt.
  ///
  /// In zh, this message translates to:
  /// **'点击“扫描”分析磁盘空间'**
  String get scanEmptyPrompt;

  /// No description provided for @startScan.
  ///
  /// In zh, this message translates to:
  /// **'开始扫描'**
  String get startScan;

  /// No description provided for @confirmClean.
  ///
  /// In zh, this message translates to:
  /// **'确认清理'**
  String get confirmClean;

  /// No description provided for @cleanDeleteSummary.
  ///
  /// In zh, this message translates to:
  /// **'将永久删除 {count} 项，共 {size}。'**
  String cleanDeleteSummary(Object count, Object size);

  /// No description provided for @macintoshDiskName.
  ///
  /// In zh, this message translates to:
  /// **'Macintosh HD · 主数据卷'**
  String get macintoshDiskName;

  /// No description provided for @primaryDataVolumeDescription.
  ///
  /// In zh, this message translates to:
  /// **'/System/Volumes/Data · 显示实际占用空间，不含稀疏文件逻辑大小'**
  String get primaryDataVolumeDescription;

  /// No description provided for @diskUsed.
  ///
  /// In zh, this message translates to:
  /// **'已使用 {size}'**
  String diskUsed(Object size);

  /// No description provided for @capacity.
  ///
  /// In zh, this message translates to:
  /// **'总容量'**
  String get capacity;

  /// No description provided for @candidatesFound.
  ///
  /// In zh, this message translates to:
  /// **'发现可清理项'**
  String get candidatesFound;

  /// No description provided for @selected.
  ///
  /// In zh, this message translates to:
  /// **'已选择'**
  String get selected;

  /// No description provided for @readingDiskUsage.
  ///
  /// In zh, this message translates to:
  /// **'正在读取主磁盘用量…'**
  String get readingDiskUsage;

  /// No description provided for @category.
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get category;

  /// No description provided for @safeToClean.
  ///
  /// In zh, this message translates to:
  /// **'可安全清理'**
  String get safeToClean;

  /// No description provided for @caution.
  ///
  /// In zh, this message translates to:
  /// **'需要确认'**
  String get caution;

  /// No description provided for @danger.
  ///
  /// In zh, this message translates to:
  /// **'高风险'**
  String get danger;

  /// No description provided for @foundAndSelected.
  ///
  /// In zh, this message translates to:
  /// **'发现 {found} 项 · 已选 {selected} 项'**
  String foundAndSelected(Object found, Object selected);

  /// No description provided for @selectedToClean.
  ///
  /// In zh, this message translates to:
  /// **'已选择 {size} 待清理'**
  String selectedToClean(Object size);

  /// No description provided for @cleanNow.
  ///
  /// In zh, this message translates to:
  /// **'立即清理'**
  String get cleanNow;

  /// No description provided for @cleanDone.
  ///
  /// In zh, this message translates to:
  /// **'清理完成，已释放 {size}'**
  String cleanDone(Object size);

  /// No description provided for @simulatorNeverBooted.
  ///
  /// In zh, this message translates to:
  /// **'从未启动'**
  String get simulatorNeverBooted;

  /// No description provided for @lastUsedDate.
  ///
  /// In zh, this message translates to:
  /// **'上次使用：{date}'**
  String lastUsedDate(Object date);

  /// No description provided for @simulatorScanDetailNever.
  ///
  /// In zh, this message translates to:
  /// **'{runtime} · 从未启动'**
  String simulatorScanDetailNever(Object runtime);

  /// No description provided for @simulatorScanDetailLastUsed.
  ///
  /// In zh, this message translates to:
  /// **'{runtime} · 上次使用：{date}'**
  String simulatorScanDetailLastUsed(Object date, Object runtime);

  /// No description provided for @runtimeBuild.
  ///
  /// In zh, this message translates to:
  /// **'构建 {build}'**
  String runtimeBuild(Object build);

  /// No description provided for @runtimeBuildLastUsed.
  ///
  /// In zh, this message translates to:
  /// **'构建 {build} · 上次使用：{date}'**
  String runtimeBuildLastUsed(Object build, Object date);

  /// No description provided for @runtimeCacheName.
  ///
  /// In zh, this message translates to:
  /// **'{runtime} dyld 缓存'**
  String runtimeCacheName(Object runtime);

  /// No description provided for @runtimeCacheDetail.
  ///
  /// In zh, this message translates to:
  /// **'生成的运行时缓存 · 会自动重新构建'**
  String get runtimeCacheDetail;

  /// No description provided for @largeFilesNoSafeCandidates.
  ///
  /// In zh, this message translates to:
  /// **'没有可安全删除的文件（PathGuard 已拦截）'**
  String get largeFilesNoSafeCandidates;

  /// No description provided for @confirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get confirmDelete;

  /// No description provided for @fileDeleteSummary.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个文件 · 共 {size}'**
  String fileDeleteSummary(Object count, Object size);

  /// No description provided for @permanentDeleteWarning.
  ///
  /// In zh, this message translates to:
  /// **'这些文件将被永久删除，无法恢复。'**
  String get permanentDeleteWarning;

  /// No description provided for @findFilesOver.
  ///
  /// In zh, this message translates to:
  /// **'查找大于 {threshold} MB 的文件'**
  String findFilesOver(Object threshold);

  /// No description provided for @largeFileSafetyDescription.
  ///
  /// In zh, this message translates to:
  /// **'安全分类：缓存和临时文件会标记为安全；系统、SDK 和源码文件不会列出'**
  String get largeFileSafetyDescription;

  /// No description provided for @largeFilesSummary.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 个文件 · {size}'**
  String largeFilesSummary(Object count, Object size);

  /// No description provided for @safeCount.
  ///
  /// In zh, this message translates to:
  /// **'安全 {count}'**
  String safeCount(Object count);

  /// No description provided for @cautionCount.
  ///
  /// In zh, this message translates to:
  /// **'需确认 {count}'**
  String cautionCount(Object count);

  /// No description provided for @safeToDelete.
  ///
  /// In zh, this message translates to:
  /// **'可安全删除'**
  String get safeToDelete;

  /// No description provided for @requiresReview.
  ///
  /// In zh, this message translates to:
  /// **'需要确认'**
  String get requiresReview;

  /// No description provided for @countAndSize.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个 · {size}'**
  String countAndSize(Object count, Object size);

  /// No description provided for @largeFileSafetySafe.
  ///
  /// In zh, this message translates to:
  /// **'安全'**
  String get largeFileSafetySafe;

  /// No description provided for @largeFileSafetyCaution.
  ///
  /// In zh, this message translates to:
  /// **'需确认'**
  String get largeFileSafetyCaution;

  /// No description provided for @largeFileSafetyReasonSafe.
  ///
  /// In zh, this message translates to:
  /// **'缓存或临时文件，可安全删除'**
  String get largeFileSafetyReasonSafe;

  /// No description provided for @largeFileSafetyReasonCaution.
  ///
  /// In zh, this message translates to:
  /// **'请确认文件用途后再删除'**
  String get largeFileSafetyReasonCaution;

  /// No description provided for @showInFinder.
  ///
  /// In zh, this message translates to:
  /// **'在 Finder 中显示'**
  String get showInFinder;

  /// No description provided for @selectedFiles.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count} 个文件'**
  String selectedFiles(Object count);

  /// No description provided for @totalSize.
  ///
  /// In zh, this message translates to:
  /// **'共 {size}'**
  String totalSize(Object size);

  /// No description provided for @deleteSelected.
  ///
  /// In zh, this message translates to:
  /// **'删除所选'**
  String get deleteSelected;

  /// No description provided for @deletedFilesSummary.
  ///
  /// In zh, this message translates to:
  /// **'已删除 {count} 个文件，释放 {size}'**
  String deletedFilesSummary(Object count, Object size);

  /// No description provided for @noNodeModulesFound.
  ///
  /// In zh, this message translates to:
  /// **'配置的目录中未发现 node_modules'**
  String get noNodeModulesFound;

  /// No description provided for @addNodeModulesRoots.
  ///
  /// In zh, this message translates to:
  /// **'请在设置中添加项目根目录。'**
  String get addNodeModulesRoots;

  /// No description provided for @nodeModulesSummary.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个文件夹 · {total} · 已选 {selected}'**
  String nodeModulesSummary(Object count, Object selected, Object total);

  /// No description provided for @deleteNodeModulesTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除 node_modules？'**
  String get deleteNodeModulesTitle;

  /// No description provided for @deleteNodeModulesContent.
  ///
  /// In zh, this message translates to:
  /// **'删除 {count} 个文件夹（{size}）？\n\n之后需要通过 npm/yarn install 重新安装依赖。'**
  String deleteNodeModulesContent(Object count, Object size);

  /// No description provided for @lruTitle.
  ///
  /// In zh, this message translates to:
  /// **'LRU（保护最近使用的依赖）'**
  String get lruTitle;

  /// No description provided for @lruEnabledDescription.
  ///
  /// In zh, this message translates to:
  /// **'仅自动选择 30 天以上未使用的依赖'**
  String get lruEnabledDescription;

  /// No description provided for @lruDisabledDescription.
  ///
  /// In zh, this message translates to:
  /// **'显示全部，由你手动选择要删除的内容'**
  String get lruDisabledDescription;

  /// No description provided for @idle.
  ///
  /// In zh, this message translates to:
  /// **'闲置'**
  String get idle;

  /// No description provided for @lastUsed.
  ///
  /// In zh, this message translates to:
  /// **'上次使用：{date}'**
  String lastUsed(Object date);

  /// No description provided for @selectedSummary.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count} 项 · {size}'**
  String selectedSummary(Object count, Object size);

  /// No description provided for @scanThresholds.
  ///
  /// In zh, this message translates to:
  /// **'扫描阈值'**
  String get scanThresholds;

  /// No description provided for @largeFileThreshold.
  ///
  /// In zh, this message translates to:
  /// **'大文件阈值'**
  String get largeFileThreshold;

  /// No description provided for @simulatorStaleThreshold.
  ///
  /// In zh, this message translates to:
  /// **'模拟器闲置阈值'**
  String get simulatorStaleThreshold;

  /// No description provided for @days.
  ///
  /// In zh, this message translates to:
  /// **'{count} 天'**
  String days(Object count);

  /// No description provided for @excludedPaths.
  ///
  /// In zh, this message translates to:
  /// **'排除路径'**
  String get excludedPaths;

  /// No description provided for @excludedPathsDescription.
  ///
  /// In zh, this message translates to:
  /// **'即使被选中，也绝不会删除这些路径。'**
  String get excludedPathsDescription;

  /// No description provided for @nodeModulesRoots.
  ///
  /// In zh, this message translates to:
  /// **'Node Modules 扫描目录'**
  String get nodeModulesRoots;

  /// No description provided for @nodeModulesRootsDescription.
  ///
  /// In zh, this message translates to:
  /// **'在这些目录中扫描 node_modules；留空时扫描用户主目录。'**
  String get nodeModulesRootsDescription;

  /// No description provided for @pathExample.
  ///
  /// In zh, this message translates to:
  /// **'例如 /Users/you/projects/my-app'**
  String get pathExample;

  /// No description provided for @noSimulatorsFound.
  ///
  /// In zh, this message translates to:
  /// **'未发现模拟器'**
  String get noSimulatorsFound;

  /// No description provided for @iosSimulators.
  ///
  /// In zh, this message translates to:
  /// **'iOS 模拟器'**
  String get iosSimulators;

  /// No description provided for @androidEmulators.
  ///
  /// In zh, this message translates to:
  /// **'Android 设备'**
  String get androidEmulators;

  /// No description provided for @adbTools.
  ///
  /// In zh, this message translates to:
  /// **'ADB 调测工具'**
  String get adbTools;

  /// No description provided for @adbToolsDescription.
  ///
  /// In zh, this message translates to:
  /// **'为运行中的 Android 设备提供 Shell、Logcat、APK 安装和截图功能'**
  String get adbToolsDescription;

  /// No description provided for @restartAdb.
  ///
  /// In zh, this message translates to:
  /// **'重启 ADB'**
  String get restartAdb;

  /// No description provided for @adbRestarted.
  ///
  /// In zh, this message translates to:
  /// **'ADB 服务已重启'**
  String get adbRestarted;

  /// No description provided for @copySerial.
  ///
  /// In zh, this message translates to:
  /// **'复制设备序列号'**
  String get copySerial;

  /// No description provided for @serialCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制设备序列号：{serial}'**
  String serialCopied(Object serial);

  /// No description provided for @openAdbShell.
  ///
  /// In zh, this message translates to:
  /// **'打开 ADB Shell'**
  String get openAdbShell;

  /// No description provided for @openLogcat.
  ///
  /// In zh, this message translates to:
  /// **'打开 Logcat'**
  String get openLogcat;

  /// No description provided for @installApk.
  ///
  /// In zh, this message translates to:
  /// **'安装 APK'**
  String get installApk;

  /// No description provided for @chooseApkPrompt.
  ///
  /// In zh, this message translates to:
  /// **'选择要安装的 APK'**
  String get chooseApkPrompt;

  /// No description provided for @invalidApk.
  ///
  /// In zh, this message translates to:
  /// **'请选择有效的 .apk 文件'**
  String get invalidApk;

  /// No description provided for @apkInstalled.
  ///
  /// In zh, this message translates to:
  /// **'已将 APK 安装到 {name}'**
  String apkInstalled(Object name);

  /// No description provided for @takeScreenshot.
  ///
  /// In zh, this message translates to:
  /// **'截取屏幕'**
  String get takeScreenshot;

  /// No description provided for @screenshotSaved.
  ///
  /// In zh, this message translates to:
  /// **'截图已保存：{path}'**
  String screenshotSaved(Object path);

  /// No description provided for @terminalOpened.
  ///
  /// In zh, this message translates to:
  /// **'已为 {name} 打开 {tool}'**
  String terminalOpened(Object name, Object tool);

  /// No description provided for @virtualDevice.
  ///
  /// In zh, this message translates to:
  /// **'模拟器'**
  String get virtualDevice;

  /// No description provided for @physicalDevice.
  ///
  /// In zh, this message translates to:
  /// **'真机'**
  String get physicalDevice;

  /// No description provided for @noAndroidVirtualDevices.
  ///
  /// In zh, this message translates to:
  /// **'未发现 Android 虚拟设备或已连接设备'**
  String get noAndroidVirtualDevices;

  /// No description provided for @unableToStartEmulator.
  ///
  /// In zh, this message translates to:
  /// **'无法启动 {name}'**
  String unableToStartEmulator(Object name);

  /// No description provided for @androidStartErrorDetails.
  ///
  /// In zh, this message translates to:
  /// **'模拟器进程提前退出。下面是 emulator 的原始启动信息，可用于定位镜像、SDK、锁文件或图形驱动问题。'**
  String get androidStartErrorDetails;

  /// No description provided for @androidFailureLogSaved.
  ///
  /// In zh, this message translates to:
  /// **'失败日志已保存：{path}'**
  String androidFailureLogSaved(Object path);

  /// No description provided for @openFailureLog.
  ///
  /// In zh, this message translates to:
  /// **'在 Finder 中显示日志'**
  String get openFailureLog;

  /// No description provided for @copyErrorDetails.
  ///
  /// In zh, this message translates to:
  /// **'复制错误详情'**
  String get copyErrorDetails;

  /// No description provided for @errorDetailsCopied.
  ///
  /// In zh, this message translates to:
  /// **'错误详情已复制'**
  String get errorDetailsCopied;

  /// No description provided for @checkEmulatorConfig.
  ///
  /// In zh, this message translates to:
  /// **'检查配置'**
  String get checkEmulatorConfig;

  /// No description provided for @checkingEmulatorConfig.
  ///
  /// In zh, this message translates to:
  /// **'正在检查配置…'**
  String get checkingEmulatorConfig;

  /// No description provided for @emulatorConfigCheckTitle.
  ///
  /// In zh, this message translates to:
  /// **'Android 模拟器配置体检'**
  String get emulatorConfigCheckTitle;

  /// No description provided for @emulatorConfigCheckSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'检查 AVD 描述、系统镜像、电脑键盘和离线锁文件'**
  String get emulatorConfigCheckSubtitle;

  /// No description provided for @emulatorConfigSafetyNote.
  ///
  /// In zh, this message translates to:
  /// **'只修复可安全恢复的配置项；修改前自动备份配置，不会删除应用、用户数据或快照。'**
  String get emulatorConfigSafetyNote;

  /// No description provided for @emulatorConfigHealthy.
  ///
  /// In zh, this message translates to:
  /// **'配置状态良好'**
  String get emulatorConfigHealthy;

  /// No description provided for @emulatorConfigHealthyDescription.
  ///
  /// In zh, this message translates to:
  /// **'未发现会影响 Android 模拟器启动和调测的配置问题。'**
  String get emulatorConfigHealthyDescription;

  /// No description provided for @emulatorConfigNoAvds.
  ///
  /// In zh, this message translates to:
  /// **'没有可检查的 AVD'**
  String get emulatorConfigNoAvds;

  /// No description provided for @emulatorConfigNoAvdsDescription.
  ///
  /// In zh, this message translates to:
  /// **'当前 Android AVD 目录中没有虚拟设备。'**
  String get emulatorConfigNoAvdsDescription;

  /// No description provided for @emulatorConfigSummary.
  ///
  /// In zh, this message translates to:
  /// **'已检查 {avds} 个 AVD · 发现 {issues} 个问题 · {repairable} 项可修复'**
  String emulatorConfigSummary(Object avds, Object issues, Object repairable);

  /// No description provided for @selectAllRepairable.
  ///
  /// In zh, this message translates to:
  /// **'选择全部可修复项'**
  String get selectAllRepairable;

  /// No description provided for @repairSelectedIssues.
  ///
  /// In zh, this message translates to:
  /// **'修复选中项（{count}）'**
  String repairSelectedIssues(Object count);

  /// No description provided for @repairableIssue.
  ///
  /// In zh, this message translates to:
  /// **'可自动修复'**
  String get repairableIssue;

  /// No description provided for @manualActionRequired.
  ///
  /// In zh, this message translates to:
  /// **'需要手动处理'**
  String get manualActionRequired;

  /// No description provided for @restartRequired.
  ///
  /// In zh, this message translates to:
  /// **'重启后生效'**
  String get restartRequired;

  /// No description provided for @repairingEmulatorConfig.
  ///
  /// In zh, this message translates to:
  /// **'正在修复配置…'**
  String get repairingEmulatorConfig;

  /// No description provided for @emulatorConfigRepairComplete.
  ///
  /// In zh, this message translates to:
  /// **'配置修复完成'**
  String get emulatorConfigRepairComplete;

  /// No description provided for @emulatorConfigRepairSummary.
  ///
  /// In zh, this message translates to:
  /// **'已修复 {repaired} 项，仍有 {remaining} 项需要处理。'**
  String emulatorConfigRepairSummary(Object remaining, Object repaired);

  /// No description provided for @emulatorConfigRepairSkipped.
  ///
  /// In zh, this message translates to:
  /// **'{count} 项因状态变化或安全校验未通过而跳过。'**
  String emulatorConfigRepairSkipped(Object count);

  /// No description provided for @emulatorConfigBackupSaved.
  ///
  /// In zh, this message translates to:
  /// **'原配置已备份到：{path}'**
  String emulatorConfigBackupSaved(Object path);

  /// No description provided for @restartRequiredAvds.
  ///
  /// In zh, this message translates to:
  /// **'以下运行中的模拟器需重启后生效：{names}'**
  String restartRequiredAvds(Object names);

  /// No description provided for @avdHomeMissingIssue.
  ///
  /// In zh, this message translates to:
  /// **'AVD 配置目录不可用'**
  String get avdHomeMissingIssue;

  /// No description provided for @avdHomeMissingDescription.
  ///
  /// In zh, this message translates to:
  /// **'无法读取 Android AVD 配置目录：{path}'**
  String avdHomeMissingDescription(Object path);

  /// No description provided for @avdDescriptorMissingIssue.
  ///
  /// In zh, this message translates to:
  /// **'AVD 描述文件缺失'**
  String get avdDescriptorMissingIssue;

  /// No description provided for @avdDescriptorMissingDescription.
  ///
  /// In zh, this message translates to:
  /// **'{name} 缺少描述文件，将重新建立到实际 AVD 目录的安全关联。'**
  String avdDescriptorMissingDescription(Object name);

  /// No description provided for @avdDescriptorPathIssue.
  ///
  /// In zh, this message translates to:
  /// **'AVD 路径不一致'**
  String get avdDescriptorPathIssue;

  /// No description provided for @avdDescriptorPathDescription.
  ///
  /// In zh, this message translates to:
  /// **'{name} 的描述路径无效或与实际目录不一致。'**
  String avdDescriptorPathDescription(Object name);

  /// No description provided for @avdDirectoryMissingIssue.
  ///
  /// In zh, this message translates to:
  /// **'AVD 数据目录缺失'**
  String get avdDirectoryMissingIssue;

  /// No description provided for @avdDirectoryMissingDescription.
  ///
  /// In zh, this message translates to:
  /// **'{name} 的数据目录不存在：{path}'**
  String avdDirectoryMissingDescription(Object name, Object path);

  /// No description provided for @avdConfigMissingIssue.
  ///
  /// In zh, this message translates to:
  /// **'config.ini 缺失'**
  String get avdConfigMissingIssue;

  /// No description provided for @avdConfigMissingDescription.
  ///
  /// In zh, this message translates to:
  /// **'{name} 缺少核心配置文件：{path}'**
  String avdConfigMissingDescription(Object name, Object path);

  /// No description provided for @systemImagePathMissingIssue.
  ///
  /// In zh, this message translates to:
  /// **'系统镜像配置缺失'**
  String get systemImagePathMissingIssue;

  /// No description provided for @systemImagePathMissingDescription.
  ///
  /// In zh, this message translates to:
  /// **'{name} 的 config.ini 中没有 image.sysdir.1，无法安全推断系统镜像。'**
  String systemImagePathMissingDescription(Object name);

  /// No description provided for @systemImageMissingIssue.
  ///
  /// In zh, this message translates to:
  /// **'系统镜像未安装'**
  String get systemImageMissingIssue;

  /// No description provided for @systemImageMissingDescription.
  ///
  /// In zh, this message translates to:
  /// **'{name} 使用的系统镜像不存在：{path}。请通过 SDK Manager 安装对应镜像。'**
  String systemImageMissingDescription(Object name, Object path);

  /// No description provided for @systemImagePathIssue.
  ///
  /// In zh, this message translates to:
  /// **'系统镜像路径失效'**
  String get systemImagePathIssue;

  /// No description provided for @systemImagePathDescription.
  ///
  /// In zh, this message translates to:
  /// **'{name} 仍指向旧 SDK 路径，可修复为当前已安装镜像。'**
  String systemImagePathDescription(Object name);

  /// No description provided for @hardwareKeyboardIssue.
  ///
  /// In zh, this message translates to:
  /// **'电脑键盘未启用'**
  String get hardwareKeyboardIssue;

  /// No description provided for @hardwareKeyboardIssueDescription.
  ///
  /// In zh, this message translates to:
  /// **'{name} 无法稳定接收电脑键盘输入和快捷键。'**
  String hardwareKeyboardIssueDescription(Object name);

  /// No description provided for @staleLockIssue.
  ///
  /// In zh, this message translates to:
  /// **'发现离线锁文件'**
  String get staleLockIssue;

  /// No description provided for @staleLockDescription.
  ///
  /// In zh, this message translates to:
  /// **'{name} 已停止，但残留 {count} 个过期锁文件，可能阻止下次启动。'**
  String staleLockDescription(Object count, Object name);

  /// No description provided for @currentConfigValue.
  ///
  /// In zh, this message translates to:
  /// **'当前：{value}'**
  String currentConfigValue(Object value);

  /// No description provided for @suggestedConfigValue.
  ///
  /// In zh, this message translates to:
  /// **'修复为：{value}'**
  String suggestedConfigValue(Object value);

  /// No description provided for @stopEmulatorTitle.
  ///
  /// In zh, this message translates to:
  /// **'停止模拟器？'**
  String get stopEmulatorTitle;

  /// No description provided for @stopAndroidEmulatorContent.
  ///
  /// In zh, this message translates to:
  /// **'确定停止 {name}（{serial}）吗？'**
  String stopAndroidEmulatorContent(Object name, Object serial);

  /// No description provided for @unableToStopEmulator.
  ///
  /// In zh, this message translates to:
  /// **'无法停止 {name}'**
  String unableToStopEmulator(Object name);

  /// No description provided for @emulatorActionSent.
  ///
  /// In zh, this message translates to:
  /// **'已向 {name} 发送“{action}”'**
  String emulatorActionSent(Object action, Object name);

  /// No description provided for @stopBeforeDeleteEmulator.
  ///
  /// In zh, this message translates to:
  /// **'请先停止模拟器再删除'**
  String get stopBeforeDeleteEmulator;

  /// No description provided for @deleteAvdTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除 AVD？'**
  String get deleteAvdTitle;

  /// No description provided for @deleteAvdContent.
  ///
  /// In zh, this message translates to:
  /// **'{name} 将被永久移除。'**
  String deleteAvdContent(Object name);

  /// No description provided for @running.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get running;

  /// No description provided for @shutdown.
  ///
  /// In zh, this message translates to:
  /// **'已关机'**
  String get shutdown;

  /// No description provided for @androidDeviceNavigation.
  ///
  /// In zh, this message translates to:
  /// **'设备导航'**
  String get androidDeviceNavigation;

  /// No description provided for @androidBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get androidBack;

  /// No description provided for @androidHome.
  ///
  /// In zh, this message translates to:
  /// **'主屏幕'**
  String get androidHome;

  /// No description provided for @androidRecents.
  ///
  /// In zh, this message translates to:
  /// **'最近任务'**
  String get androidRecents;

  /// No description provided for @androidGestureNavigationHint.
  ///
  /// In zh, this message translates to:
  /// **'当前模拟器为手势导航：底部横条不可点击返回，可从屏幕左右边缘向内滑，或使用这里的返回按钮。'**
  String get androidGestureNavigationHint;

  /// No description provided for @androidClipboard.
  ///
  /// In zh, this message translates to:
  /// **'电脑剪贴板'**
  String get androidClipboard;

  /// No description provided for @androidCopySelection.
  ///
  /// In zh, this message translates to:
  /// **'复制选中内容'**
  String get androidCopySelection;

  /// No description provided for @androidPasteHostClipboard.
  ///
  /// In zh, this message translates to:
  /// **'粘贴电脑剪贴板'**
  String get androidPasteHostClipboard;

  /// No description provided for @androidClipboardHint.
  ///
  /// In zh, this message translates to:
  /// **'先在 Android 输入框中放置光标。支持中文和特殊字符；开发助手仅在点击操作时读取或写入剪贴板，不会保存内容。'**
  String get androidClipboardHint;

  /// No description provided for @hardwareKeyboardDisabled.
  ///
  /// In zh, this message translates to:
  /// **'此 AVD 未启用电脑键盘，直接键盘输入和快捷键可能无效。'**
  String get hardwareKeyboardDisabled;

  /// No description provided for @enableHardwareKeyboard.
  ///
  /// In zh, this message translates to:
  /// **'启用电脑键盘'**
  String get enableHardwareKeyboard;

  /// No description provided for @enableHardwareKeyboardTitle.
  ///
  /// In zh, this message translates to:
  /// **'启用电脑键盘并重启？'**
  String get enableHardwareKeyboardTitle;

  /// No description provided for @enableHardwareKeyboardDescription.
  ///
  /// In zh, this message translates to:
  /// **'将修改 {name} 的 AVD 配置并重新启动模拟器。当前未保存的界面状态可能丢失。'**
  String enableHardwareKeyboardDescription(Object name);

  /// No description provided for @enableAndRestart.
  ///
  /// In zh, this message translates to:
  /// **'启用并重启'**
  String get enableAndRestart;

  /// No description provided for @hardwareKeyboardEnabled.
  ///
  /// In zh, this message translates to:
  /// **'{name} 已启用电脑键盘'**
  String hardwareKeyboardEnabled(Object name);

  /// No description provided for @devMenu.
  ///
  /// In zh, this message translates to:
  /// **'开发菜单'**
  String get devMenu;

  /// No description provided for @reloadJs.
  ///
  /// In zh, this message translates to:
  /// **'重载 JS'**
  String get reloadJs;

  /// No description provided for @deleteEllipsis.
  ///
  /// In zh, this message translates to:
  /// **'删除…'**
  String get deleteEllipsis;

  /// No description provided for @androidSdkNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到 Android SDK'**
  String get androidSdkNotFound;

  /// No description provided for @androidSdkNotFoundDescription.
  ///
  /// In zh, this message translates to:
  /// **'请安装 Android SDK 并设置 ANDROID_HOME，以管理 Android 模拟器。'**
  String get androidSdkNotFoundDescription;

  /// No description provided for @iosSimulatorSummary.
  ///
  /// In zh, this message translates to:
  /// **'{count} 台模拟器 · 共 {size}'**
  String iosSimulatorSummary(Object count, Object size);

  /// No description provided for @staleAfterDays.
  ///
  /// In zh, this message translates to:
  /// **'超过 {days} 天未使用视为闲置'**
  String staleAfterDays(Object days);

  /// No description provided for @stopIosSimulatorContent.
  ///
  /// In zh, this message translates to:
  /// **'确定停止 {name} 吗？'**
  String stopIosSimulatorContent(Object name);

  /// No description provided for @eraseContentTitle.
  ///
  /// In zh, this message translates to:
  /// **'抹掉内容？'**
  String get eraseContentTitle;

  /// No description provided for @eraseContentDescription.
  ///
  /// In zh, this message translates to:
  /// **'抹掉 {name} 的所有内容和设置？模拟器设备本身会保留。'**
  String eraseContentDescription(Object name);

  /// No description provided for @erase.
  ///
  /// In zh, this message translates to:
  /// **'抹掉'**
  String get erase;

  /// No description provided for @deleteSimulatorTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除模拟器？'**
  String get deleteSimulatorTitle;

  /// No description provided for @deleteSimulatorDescription.
  ///
  /// In zh, this message translates to:
  /// **'{name} 将被永久移除（{size}）。'**
  String deleteSimulatorDescription(Object name, Object size);

  /// No description provided for @stale.
  ///
  /// In zh, this message translates to:
  /// **'闲置'**
  String get stale;

  /// No description provided for @iosSimulatorDetailLast.
  ///
  /// In zh, this message translates to:
  /// **'{runtime} · {state} · 上次启动：{date} · {size}'**
  String iosSimulatorDetailLast(
    Object date,
    Object runtime,
    Object size,
    Object state,
  );

  /// No description provided for @iosSimulatorDetailNever.
  ///
  /// In zh, this message translates to:
  /// **'{runtime} · {state} · 从未启动 · {size}'**
  String iosSimulatorDetailNever(Object runtime, Object size, Object state);

  /// No description provided for @targetIosRuntimeCaches.
  ///
  /// In zh, this message translates to:
  /// **'iOS 运行时缓存'**
  String get targetIosRuntimeCaches;

  /// No description provided for @targetIosRuntimeCachesDescription.
  ///
  /// In zh, this message translates to:
  /// **'Xcode 生成的 dyld 缓存；再次使用对应运行时时会自动重建。'**
  String get targetIosRuntimeCachesDescription;

  /// No description provided for @targetIosRuntimes.
  ///
  /// In zh, this message translates to:
  /// **'iOS 运行时镜像'**
  String get targetIosRuntimes;

  /// No description provided for @targetIosRuntimesDescription.
  ///
  /// In zh, this message translates to:
  /// **'已下载的 iOS 版本；可移除不再用于测试的旧运行时。'**
  String get targetIosRuntimesDescription;

  /// No description provided for @targetIosSimulators.
  ///
  /// In zh, this message translates to:
  /// **'iOS 模拟器设备'**
  String get targetIosSimulators;

  /// No description provided for @targetIosSimulatorsDescription.
  ///
  /// In zh, this message translates to:
  /// **'模拟器应用数据；通过 xcrun simctl 安全移除。'**
  String get targetIosSimulatorsDescription;

  /// No description provided for @targetAppCaches.
  ///
  /// In zh, this message translates to:
  /// **'应用缓存'**
  String get targetAppCaches;

  /// No description provided for @targetAppCachesDescription.
  ///
  /// In zh, this message translates to:
  /// **'主磁盘上的可重建应用缓存；系统缓存已排除。'**
  String get targetAppCachesDescription;

  /// No description provided for @targetQqUpdates.
  ///
  /// In zh, this message translates to:
  /// **'QQ 更新下载'**
  String get targetQqUpdates;

  /// No description provided for @targetQqUpdatesDescription.
  ///
  /// In zh, this message translates to:
  /// **'QQ 已下载并解压的更新；需要时可以重新下载。'**
  String get targetQqUpdatesDescription;

  /// No description provided for @targetChromeModels.
  ///
  /// In zh, this message translates to:
  /// **'Chrome 已下载模型'**
  String get targetChromeModels;

  /// No description provided for @targetChromeModelsDescription.
  ///
  /// In zh, this message translates to:
  /// **'设备端优化模型；Chrome 可能会重新下载。'**
  String get targetChromeModelsDescription;

  /// No description provided for @targetGoogleUpdaterCache.
  ///
  /// In zh, this message translates to:
  /// **'Google 更新缓存'**
  String get targetGoogleUpdaterCache;

  /// No description provided for @targetGoogleUpdaterCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'Chrome 和 Google 组件的已下载更新包。'**
  String get targetGoogleUpdaterCacheDescription;

  /// No description provided for @targetAppSupportCaches.
  ///
  /// In zh, this message translates to:
  /// **'应用更新缓存'**
  String get targetAppSupportCaches;

  /// No description provided for @targetAppSupportCachesDescription.
  ///
  /// In zh, this message translates to:
  /// **'Application Support 中保存的安装器和更新包。'**
  String get targetAppSupportCachesDescription;

  /// No description provided for @targetAndroidStudioBackups.
  ///
  /// In zh, this message translates to:
  /// **'Android Studio 备份'**
  String get targetAndroidStudioBackups;

  /// No description provided for @targetAndroidStudioBackupsDescription.
  ///
  /// In zh, this message translates to:
  /// **'IDE 升级时创建的配置备份；删除前请确认。'**
  String get targetAndroidStudioBackupsDescription;

  /// No description provided for @targetDownloadArchives.
  ///
  /// In zh, this message translates to:
  /// **'下载的压缩包与安装器'**
  String get targetDownloadArchives;

  /// No description provided for @targetDownloadArchivesDescription.
  ///
  /// In zh, this message translates to:
  /// **'下载目录中的大型压缩包和安装器；这些是个人文件，请逐项确认。'**
  String get targetDownloadArchivesDescription;

  /// No description provided for @targetGradleCaches.
  ///
  /// In zh, this message translates to:
  /// **'Gradle 缓存'**
  String get targetGradleCaches;

  /// No description provided for @targetGradleCachesDescription.
  ///
  /// In zh, this message translates to:
  /// **'构建和依赖缓存；下次构建会重新下载依赖并编译。'**
  String get targetGradleCachesDescription;

  /// No description provided for @targetGradleWrapper.
  ///
  /// In zh, this message translates to:
  /// **'Gradle Wrapper 发行版'**
  String get targetGradleWrapper;

  /// No description provided for @targetGradleWrapperDescription.
  ///
  /// In zh, this message translates to:
  /// **'已下载的 Gradle 版本；下次对应构建会自动恢复。'**
  String get targetGradleWrapperDescription;

  /// No description provided for @targetKonanRuntimes.
  ///
  /// In zh, this message translates to:
  /// **'Kotlin/Native 工具链'**
  String get targetKonanRuntimes;

  /// No description provided for @targetKonanRuntimesDescription.
  ///
  /// In zh, this message translates to:
  /// **'已下载的 Kotlin/Native 版本；请保留活跃项目使用的版本。'**
  String get targetKonanRuntimesDescription;

  /// No description provided for @targetCodexRuntimes.
  ///
  /// In zh, this message translates to:
  /// **'Codex 运行时缓存'**
  String get targetCodexRuntimes;

  /// No description provided for @targetCodexRuntimesDescription.
  ///
  /// In zh, this message translates to:
  /// **'内置执行运行时；Codex 再次需要时会自动恢复。'**
  String get targetCodexRuntimesDescription;

  /// No description provided for @targetLldbCache.
  ///
  /// In zh, this message translates to:
  /// **'LLDB 模块缓存'**
  String get targetLldbCache;

  /// No description provided for @targetLldbCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'已下载的调试模块和符号；后续调试时会重新生成。'**
  String get targetLldbCacheDescription;

  /// No description provided for @targetCodexTemp.
  ///
  /// In zh, this message translates to:
  /// **'Codex 临时文件'**
  String get targetCodexTemp;

  /// No description provided for @targetCodexTempDescription.
  ///
  /// In zh, this message translates to:
  /// **'插件备份和暂存文件；清理前请关闭 Codex。'**
  String get targetCodexTempDescription;

  /// No description provided for @targetNpmCache.
  ///
  /// In zh, this message translates to:
  /// **'npm 缓存'**
  String get targetNpmCache;

  /// No description provided for @targetNpmCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'npm 包缓存；安装依赖时会自动重建。'**
  String get targetNpmCacheDescription;

  /// No description provided for @targetNodeGyp.
  ///
  /// In zh, this message translates to:
  /// **'node-gyp 缓存'**
  String get targetNodeGyp;

  /// No description provided for @targetNodeGypDescription.
  ///
  /// In zh, this message translates to:
  /// **'原生扩展构建缓存；编译原生包时会重建。'**
  String get targetNodeGypDescription;

  /// No description provided for @targetCocoapods.
  ///
  /// In zh, this message translates to:
  /// **'CocoaPods 缓存'**
  String get targetCocoapods;

  /// No description provided for @targetCocoapodsDescription.
  ///
  /// In zh, this message translates to:
  /// **'iOS/macOS 依赖缓存；下次 pod install 会重新下载。'**
  String get targetCocoapodsDescription;

  /// No description provided for @targetPipCache.
  ///
  /// In zh, this message translates to:
  /// **'pip 缓存'**
  String get targetPipCache;

  /// No description provided for @targetPipCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'Python 包缓存；安装 Python 包时会重建。'**
  String get targetPipCacheDescription;

  /// No description provided for @targetHomebrew.
  ///
  /// In zh, this message translates to:
  /// **'Homebrew 缓存'**
  String get targetHomebrew;

  /// No description provided for @targetHomebrewDescription.
  ///
  /// In zh, this message translates to:
  /// **'已下载的软件包归档；已安装的软件不受影响。'**
  String get targetHomebrewDescription;

  /// No description provided for @targetPlaywright.
  ///
  /// In zh, this message translates to:
  /// **'Playwright 浏览器'**
  String get targetPlaywright;

  /// No description provided for @targetPlaywrightDescription.
  ///
  /// In zh, this message translates to:
  /// **'用于测试的浏览器二进制；可通过 playwright install 恢复。'**
  String get targetPlaywrightDescription;

  /// No description provided for @targetJetbrainsCache.
  ///
  /// In zh, this message translates to:
  /// **'JetBrains IDE 缓存'**
  String get targetJetbrainsCache;

  /// No description provided for @targetJetbrainsCacheDescription.
  ///
  /// In zh, this message translates to:
  /// **'IDE 索引和缓存；清理后首次启动会较慢。'**
  String get targetJetbrainsCacheDescription;

  /// No description provided for @targetXcodeDerived.
  ///
  /// In zh, this message translates to:
  /// **'Xcode DerivedData'**
  String get targetXcodeDerived;

  /// No description provided for @targetXcodeDerivedDescription.
  ///
  /// In zh, this message translates to:
  /// **'构建中间产物；下次构建会执行完整编译。'**
  String get targetXcodeDerivedDescription;

  /// No description provided for @targetXcodeArchives.
  ///
  /// In zh, this message translates to:
  /// **'Xcode 归档'**
  String get targetXcodeArchives;

  /// No description provided for @targetXcodeArchivesDescription.
  ///
  /// In zh, this message translates to:
  /// **'发布归档；仅在不再需要已归档构建时删除。'**
  String get targetXcodeArchivesDescription;

  /// No description provided for @targetAppLogs.
  ///
  /// In zh, this message translates to:
  /// **'应用日志'**
  String get targetAppLogs;

  /// No description provided for @targetAppLogsDescription.
  ///
  /// In zh, this message translates to:
  /// **'主磁盘上各应用保存的日志文件。'**
  String get targetAppLogsDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
