// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mobile Dev Assistant';

  @override
  String get appTagline => 'A local toolkit for mobile engineering';

  @override
  String get workspaceSubtitle =>
      'See devices, storage, and development health at a glance';

  @override
  String get deviceLabSubtitle =>
      'Manage Android and iOS devices with focused debugging tools';

  @override
  String get settingsSubtitle =>
      'Tune scanning and safety rules to match your workflow';

  @override
  String get localPrivate => 'Local-first · Privacy-minded';

  @override
  String get brandEdition => 'MOBILE DEV TOOLKIT';

  @override
  String get deviceOverview => 'Device Status';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get openDeviceLab => 'Open Device Lab';

  @override
  String get startDiskScan => 'Scan Dev Environment';

  @override
  String androidDeviceCount(Object count) {
    return '$count Android devices';
  }

  @override
  String iosDeviceCount(Object count) {
    return '$count iOS simulators';
  }

  @override
  String get reclaimableMetric => 'Reclaimable space';

  @override
  String get storageOverview => 'Storage Overview';

  @override
  String get storageSubtitle => 'Actual disk usage on the primary data volume';

  @override
  String get noScanData => 'Development caches have not been scanned yet';

  @override
  String get scanNow => 'Scan Now';

  @override
  String adbDeviceSummary(Object running, Object total) {
    return '$running online · $total devices';
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
  String get adbReady => 'ADB ready';

  @override
  String get developerTools => 'Debug Shortcuts';

  @override
  String get scanPageSubtitle =>
      'Find rebuildable caches and reclaim space with reviewable actions';

  @override
  String get largeFilesSubtitle =>
      'Find files with real disk impact and review them by risk';

  @override
  String get nodeModulesSubtitle =>
      'Manage project dependencies by recency and disk usage';

  @override
  String get aiAgentCaches => 'AI Agent Caches';

  @override
  String get aiAgentCachesSubtitle =>
      'Detect and remove rebuildable caches while preserving accounts, settings, and sessions';

  @override
  String get detectCaches => 'Scan Again';

  @override
  String get scanningCaches => 'Scanning caches…';

  @override
  String get aiCachePrivacyTitle => 'Allowlisted caches only';

  @override
  String get aiCachePrivacyDescription =>
      'Account credentials, settings, project rules, code, session history, chats, and installed extensions are never deleted. Nothing is selected by default.';

  @override
  String get aiCacheCloseAppsHint =>
      'Close the relevant AI agents before cleaning so caches are not locked or immediately recreated.';

  @override
  String aiCacheDetectedSummary(Object agents, Object count, Object size) {
    return '$count cache directories · $agents agents · $size total';
  }

  @override
  String aiCacheSelectedSummary(Object count, Object size) {
    return '$count selected · $size';
  }

  @override
  String get noAiCachesFound => 'No AI agent caches found';

  @override
  String get noAiCachesFoundDescription =>
      'Checked known cache locations for Claude Code, OpenCode, Trae, Qoder, Codex, and Cursor.';

  @override
  String get selectAgentCaches => 'Select this agent’s caches';

  @override
  String get cleanSelectedCaches => 'Clean Selected Caches';

  @override
  String get confirmAiCacheCleanTitle => 'Confirm AI Agent Cache Cleanup';

  @override
  String get confirmAiCacheCleanDescription =>
      'Rebuildable data inside the following directories will be cleared while the directories remain. Sessions and settings are preserved.';

  @override
  String get aiCacheConsentLabel =>
      'I have closed the relevant AI agents and agree to clean the selected caches';

  @override
  String get aiCacheConsentRequired => 'Consent is required to continue';

  @override
  String get clearCaches => 'Confirm Cleanup';

  @override
  String aiCacheCleaned(Object count, Object size) {
    return 'Cleaned $count items and reclaimed $size';
  }

  @override
  String get aiCacheRebuildable => 'Rebuildable';

  @override
  String aiCachePathCount(Object count) {
    return '$count cache directories';
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
  String get cacheKindCli => 'CLI cache';

  @override
  String get cacheKindDesktop => 'Desktop cache';

  @override
  String get cacheKindCode => 'Code cache';

  @override
  String get cacheKindGpu => 'GPU cache';

  @override
  String get cacheKindExtensions => 'Extension downloads';

  @override
  String get cacheKindUpdater => 'Updater downloads';

  @override
  String get cacheKindShared => 'Shared client cache';

  @override
  String get cacheKindTemporary => 'Temporary files';

  @override
  String get cacheKindRuntime => 'Runtime cache';

  @override
  String get reactNative => 'React Native';

  @override
  String get reactNativeSubtitle =>
      'A focused workspace for project scripts, Metro, and device debugging';

  @override
  String get rnProjects => 'RN Projects';

  @override
  String get addRnProject => 'Add Project';

  @override
  String get chooseRnProject => 'Choose a React Native project directory';

  @override
  String get noRnProjects => 'No React Native projects found';

  @override
  String get noRnProjectsDescription =>
      'Add a project folder, or keep projects under Projects, Developer, StudioProjects, or a code folder on an external volume.';

  @override
  String get invalidRnProject =>
      'The selected folder is not a valid React Native project';

  @override
  String projectAdded(Object name) {
    return 'Added project: $name';
  }

  @override
  String get selectedProject => 'Current Project';

  @override
  String get quickCommands => 'Frequent Commands';

  @override
  String get moreScripts => 'More Scripts';

  @override
  String get startMetro => 'Start Metro';

  @override
  String get resetMetroCache => 'Reset Metro Cache';

  @override
  String get runAndroid => 'Run Android';

  @override
  String get runIos => 'Run iOS';

  @override
  String get runIosSetup => 'Install & Run iOS';

  @override
  String get runCharles => 'Start Charles';

  @override
  String get openRnDevTools => 'Open RN DevTools';

  @override
  String get openProject => 'Open Project';

  @override
  String get openProjectHint => 'Choose an app';

  @override
  String get openWithCodex => 'Codex Desktop';

  @override
  String get openWithCodexCli => 'Codex CLI';

  @override
  String get openWithCursor => 'Cursor';

  @override
  String get openWithVsCode => 'VS Code';

  @override
  String get openWithAndroidStudio => 'Android Studio (Android)';

  @override
  String get openWithXcode => 'Xcode (iOS)';

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
    return 'Opened $name with $app';
  }

  @override
  String get openInCursor => 'Open in Cursor';

  @override
  String commandStarted(Object command) {
    return 'Started in Terminal: $command';
  }

  @override
  String get metroService => 'Metro Service';

  @override
  String metroRunning(Object port) {
    return 'Running on port $port';
  }

  @override
  String metroStopped(Object port) {
    return 'Not running on port $port';
  }

  @override
  String metroProcess(Object pid, Object process) {
    return '$process · PID $pid';
  }

  @override
  String get metroWatching => 'Checked automatically every 4 seconds';

  @override
  String get rnDeviceTools => 'RN Device Shortcuts';

  @override
  String get androidDevMenu => 'Android Dev Menu';

  @override
  String get androidReload => 'Reload Android';

  @override
  String get androidMetroReverse => 'Connect Android to Metro';

  @override
  String get iosDevMenu => 'iOS Dev Menu';

  @override
  String get iosReload => 'Reload iOS';

  @override
  String metroReverseDone(Object name, Object port) {
    return 'Mapped Metro port $port for $name';
  }

  @override
  String get noRunningAndroid => 'No Android device is online';

  @override
  String get noBootedIos => 'No iOS simulator is booted';

  @override
  String get rnProjectRoots => 'React Native Project Folders';

  @override
  String get rnProjectRootsDescription =>
      'Pin frequently used RN projects. The workspace also discovers projects in common development folders.';

  @override
  String get metroPort => 'Default Metro port';

  @override
  String get iosDebugTools => 'iOS Debug Tools';

  @override
  String get copyUdid => 'Copy UDID';

  @override
  String udidCopied(Object udid) {
    return 'Copied UDID: $udid';
  }

  @override
  String get openSimulatorLogs => 'Live Logs';

  @override
  String get installIosApp => 'Install .app';

  @override
  String get chooseIosAppPrompt => 'Choose an .app to install on the simulator';

  @override
  String iosAppInstalled(Object name) {
    return 'Installed the app on $name';
  }

  @override
  String get openUrl => 'Open URL';

  @override
  String get openUrlTitle => 'Open a URL in the simulator';

  @override
  String get urlHint => 'For example myapp://debug or http://localhost:8081';

  @override
  String get invalidUrl => 'Enter a valid URL';

  @override
  String get iosRnShortcutHint =>
      'The RN iOS Dev Menu uses Command + D and reload uses Command + R. Accessibility permission may be required the first time.';

  @override
  String get projectCaches => 'Project Caches';

  @override
  String get projectCachesSubtitle =>
      'Find generated files from Flutter, Android, iOS, React Native, and Web projects';

  @override
  String get projectCacheSafetyTitle => 'Rebuildable directories only';

  @override
  String get projectCacheSafetyDescription =>
      'Source code, image assets, settings, signing files, certificates, lockfiles, databases, and node_modules itself are never deleted. Nothing is selected by default.';

  @override
  String projectCacheSummary(Object count, Object projects, Object size) {
    return '$count cache directories · $projects projects · $size total';
  }

  @override
  String get projectCacheEmpty => 'No project caches found';

  @override
  String get projectCacheEmptyDescription =>
      'Scanned common development folders and configured project roots.';

  @override
  String get projectCacheKindTool => 'Tool state';

  @override
  String get projectCacheKindBuild => 'Build output';

  @override
  String get projectCacheKindDependencies => 'Generated dependencies';

  @override
  String get projectCacheKindBundler => 'Bundler cache';

  @override
  String get projectCacheKindTest => 'Test and coverage output';

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
  String get confirmProjectCacheCleanTitle => 'Confirm Project Cache Cleanup';

  @override
  String get confirmProjectCacheCleanDescription =>
      'Selected directories will be removed completely and recreated by the next build or dependency install.';

  @override
  String get projectCacheConsentLabel =>
      'I reviewed the selected paths and agree to delete these generated files';

  @override
  String projectCacheCleaned(Object count, Object size) {
    return 'Cleaned $count items and reclaimed $size';
  }

  @override
  String get developmentRoots => 'Development Project Folders';

  @override
  String get developmentRootsDescription =>
      'Used to find build and tool caches in Flutter, Android, iOS, React Native, and Web projects.';

  @override
  String get targetAndroidCliCache => 'Android CLI Cache';

  @override
  String get targetAndroidCliCacheDescription =>
      'Downloaded Android command metadata and temporary package data.';

  @override
  String get targetAndroidStudioCache => 'Android Studio Cache';

  @override
  String get targetAndroidStudioCacheDescription =>
      'IDE indexes and generated caches, rebuilt after restart.';

  @override
  String get targetDartPubHosted => 'Dart Pub Hosted Cache';

  @override
  String get targetDartPubHostedDescription =>
      'Downloaded Dart and Flutter packages restored by Pub.';

  @override
  String get targetDartPubGit => 'Dart Pub Git Cache';

  @override
  String get targetDartPubGitDescription =>
      'Git dependencies downloaded by Pub and cloned again when needed.';

  @override
  String get targetYarnCache => 'Yarn Cache';

  @override
  String get targetYarnCacheDescription =>
      'Downloaded Yarn packages restored during the next install.';

  @override
  String get targetYarnXdgCache => 'Yarn XDG Cache';

  @override
  String get targetYarnXdgCacheDescription =>
      'Yarn package cache stored in the XDG cache directory.';

  @override
  String get targetPnpmStore => 'pnpm Store';

  @override
  String get targetPnpmStoreDescription =>
      'Content-addressed pnpm package store; packages may be downloaded again.';

  @override
  String get targetPnpmLegacyStore => 'pnpm Legacy Store';

  @override
  String get targetPnpmLegacyStoreDescription =>
      'Package store left by older pnpm installations.';

  @override
  String get targetBunCache => 'Bun Package Cache';

  @override
  String get targetBunCacheDescription =>
      'Packages downloaded by Bun and restored during installation.';

  @override
  String get targetCorepackCache => 'Corepack Cache';

  @override
  String get targetCorepackCacheDescription =>
      'Package-manager distributions downloaded by Corepack.';

  @override
  String get targetSwiftpmCache => 'Swift Package Manager Cache';

  @override
  String get targetSwiftpmCacheDescription =>
      'Swift package metadata and artifacts rebuilt by SwiftPM.';

  @override
  String get targetSwiftpmRepositories => 'SwiftPM Repository Cache';

  @override
  String get targetSwiftpmRepositoriesDescription =>
      'Cached Swift package repositories cloned again when needed.';

  @override
  String get targetCarthageCache => 'Carthage Cache';

  @override
  String get targetCarthageCacheDescription =>
      'Downloaded Carthage artifacts and repository metadata.';

  @override
  String get targetCypress => 'Cypress Cache';

  @override
  String get targetCypressDescription =>
      'Downloaded Cypress test runners restored when needed.';

  @override
  String get targetDenoCache => 'Deno Cache';

  @override
  String get targetDenoCacheDescription =>
      'Downloaded modules and compiled artifacts used by Deno.';

  @override
  String get targetXcodeDeviceSupport => 'Xcode Device Support';

  @override
  String get targetXcodeDeviceSupportDescription =>
      'Symbols and support files for connected iOS versions; review old versions before cleaning.';

  @override
  String get language => 'Language';

  @override
  String get languageDescription => 'Choose the language used by the interface';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get overview => 'Workspace';

  @override
  String get scanAndClean => 'Dev Cleanup';

  @override
  String get largeFiles => 'Large File Analysis';

  @override
  String get nodeModules => 'Node Modules';

  @override
  String get simulators => 'Device Lab';

  @override
  String get settings => 'Settings';

  @override
  String get scan => 'Scan';

  @override
  String get scanning => 'Scanning…';

  @override
  String get cancel => 'Cancel';

  @override
  String get refresh => 'Refresh';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get delete => 'Delete';

  @override
  String get permanentlyDelete => 'Delete Permanently';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get open => 'Open';

  @override
  String get stop => 'Stop';

  @override
  String get boot => 'Boot';

  @override
  String get moreActions => 'More actions';

  @override
  String errorMessage(Object error) {
    return 'Error: $error';
  }

  @override
  String operationError(Object error, Object title) {
    return '$title: $error';
  }

  @override
  String get notFound => 'Not found';

  @override
  String get noItemsFound => 'No items found';

  @override
  String itemCount(Object count) {
    return '$count items';
  }

  @override
  String get overviewTotalDisk => 'Total Disk';

  @override
  String get overviewUsed => 'Used';

  @override
  String get overviewRecoverable => 'Recoverable';

  @override
  String get overviewFree => 'Free';

  @override
  String get overviewReadyToRecover => 'Ready to recover';

  @override
  String get categories => 'Categories';

  @override
  String get mainDiskScan => 'Main Disk Scan';

  @override
  String scanningTarget(Object target) {
    return 'Scanning $target…';
  }

  @override
  String cleaningReclaimed(Object size) {
    return 'Cleaning… $size reclaimed';
  }

  @override
  String get scanEmptyPrompt => 'Press Scan to analyze your disk';

  @override
  String get startScan => 'Start Scan';

  @override
  String get confirmClean => 'Confirm Clean';

  @override
  String cleanDeleteSummary(Object count, Object size) {
    return '$count items totaling $size will be permanently deleted.';
  }

  @override
  String get macintoshDiskName => 'Macintosh HD · Primary Data Volume';

  @override
  String get primaryDataVolumeDescription =>
      '/System/Volumes/Data · allocated size, not sparse logical size';

  @override
  String diskUsed(Object size) {
    return '$size used';
  }

  @override
  String get capacity => 'Capacity';

  @override
  String get candidatesFound => 'Candidates found';

  @override
  String get selected => 'Selected';

  @override
  String get readingDiskUsage => 'Reading primary disk usage…';

  @override
  String get category => 'Category';

  @override
  String get safeToClean => 'Safe to clean';

  @override
  String get caution => 'Caution';

  @override
  String get danger => 'Danger';

  @override
  String foundAndSelected(Object found, Object selected) {
    return '$found found · $selected selected';
  }

  @override
  String selectedToClean(Object size) {
    return '$size selected to clean';
  }

  @override
  String get cleanNow => 'Clean Now';

  @override
  String cleanDone(Object size) {
    return 'Done! $size reclaimed';
  }

  @override
  String get simulatorNeverBooted => 'Never booted';

  @override
  String lastUsedDate(Object date) {
    return 'Last used: $date';
  }

  @override
  String simulatorScanDetailNever(Object runtime) {
    return '$runtime · never booted';
  }

  @override
  String simulatorScanDetailLastUsed(Object date, Object runtime) {
    return '$runtime · last used $date';
  }

  @override
  String runtimeBuild(Object build) {
    return 'Build $build';
  }

  @override
  String runtimeBuildLastUsed(Object build, Object date) {
    return 'Build $build · last used $date';
  }

  @override
  String runtimeCacheName(Object runtime) {
    return '$runtime dyld cache';
  }

  @override
  String get runtimeCacheDetail =>
      'Generated runtime cache · rebuilt automatically';

  @override
  String get largeFilesNoSafeCandidates =>
      'No files can be deleted safely (blocked by PathGuard)';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String fileDeleteSummary(Object count, Object size) {
    return '$count files · $size total';
  }

  @override
  String get permanentDeleteWarning =>
      'These files will be permanently deleted and cannot be recovered.';

  @override
  String findFilesOver(Object threshold) {
    return 'Find files larger than $threshold MB';
  }

  @override
  String get largeFileSafetyDescription =>
      'Safety rules mark caches and temporary files as safe; system, SDK, and source files are excluded';

  @override
  String largeFilesSummary(Object count, Object size) {
    return '$count files · $size';
  }

  @override
  String safeCount(Object count) {
    return 'Safe $count';
  }

  @override
  String cautionCount(Object count) {
    return 'Review $count';
  }

  @override
  String get safeToDelete => 'Safe to delete';

  @override
  String get requiresReview => 'Needs review';

  @override
  String countAndSize(Object count, Object size) {
    return '$count · $size';
  }

  @override
  String get largeFileSafetySafe => 'Safe';

  @override
  String get largeFileSafetyCaution => 'Review';

  @override
  String get largeFileSafetyReasonSafe =>
      'Cache or temporary file; safe to delete';

  @override
  String get largeFileSafetyReasonCaution =>
      'Confirm what this file is used for before deleting';

  @override
  String get showInFinder => 'Show in Finder';

  @override
  String selectedFiles(Object count) {
    return '$count files selected';
  }

  @override
  String totalSize(Object size) {
    return '$size total';
  }

  @override
  String get deleteSelected => 'Delete Selected';

  @override
  String deletedFilesSummary(Object count, Object size) {
    return 'Deleted $count files and reclaimed $size';
  }

  @override
  String get noNodeModulesFound => 'No node_modules found in configured roots';

  @override
  String get addNodeModulesRoots => 'Add project root folders in Settings.';

  @override
  String nodeModulesSummary(Object count, Object selected, Object total) {
    return '$count folders · $total · $selected selected';
  }

  @override
  String get deleteNodeModulesTitle => 'Delete node_modules?';

  @override
  String deleteNodeModulesContent(Object count, Object size) {
    return 'Delete $count folders ($size)?\n\nDependencies will need to be reinstalled with npm/yarn install.';
  }

  @override
  String get lruTitle => 'LRU (protect recently used)';

  @override
  String get lruEnabledDescription =>
      'Only auto-select dependencies unused for 30+ days';

  @override
  String get lruDisabledDescription => 'Show all; you pick what to delete';

  @override
  String get idle => 'idle';

  @override
  String lastUsed(Object date) {
    return 'Last used: $date';
  }

  @override
  String selectedSummary(Object count, Object size) {
    return '$count selected · $size';
  }

  @override
  String get scanThresholds => 'Scan Thresholds';

  @override
  String get largeFileThreshold => 'Large file threshold';

  @override
  String get simulatorStaleThreshold => 'Simulator stale threshold';

  @override
  String days(Object count) {
    return '$count days';
  }

  @override
  String get excludedPaths => 'Excluded Paths';

  @override
  String get excludedPathsDescription =>
      'These paths are never deleted, even if selected.';

  @override
  String get nodeModulesRoots => 'Node Modules Roots';

  @override
  String get nodeModulesRootsDescription =>
      'Folders scanned for node_modules. Leave empty to scan your home directory.';

  @override
  String get pathExample => 'e.g. /Users/you/projects/my-app';

  @override
  String get noSimulatorsFound => 'No simulators found';

  @override
  String get iosSimulators => 'iOS Simulators';

  @override
  String get androidEmulators => 'Android Devices';

  @override
  String get adbTools => 'ADB Tools';

  @override
  String get adbToolsDescription =>
      'Open a shell, stream Logcat, install APKs, and capture screenshots on running Android devices';

  @override
  String get restartAdb => 'Restart ADB';

  @override
  String get adbRestarted => 'ADB server restarted';

  @override
  String get copySerial => 'Copy Device Serial';

  @override
  String serialCopied(Object serial) {
    return 'Copied device serial: $serial';
  }

  @override
  String get openAdbShell => 'Open ADB Shell';

  @override
  String get openLogcat => 'Open Logcat';

  @override
  String get installApk => 'Install APK';

  @override
  String get chooseApkPrompt => 'Choose an APK to install';

  @override
  String get invalidApk => 'Choose a valid .apk file';

  @override
  String apkInstalled(Object name) {
    return 'APK installed on $name';
  }

  @override
  String get takeScreenshot => 'Take Screenshot';

  @override
  String screenshotSaved(Object path) {
    return 'Screenshot saved: $path';
  }

  @override
  String terminalOpened(Object name, Object tool) {
    return 'Opened $tool for $name';
  }

  @override
  String get virtualDevice => 'Emulator';

  @override
  String get physicalDevice => 'Physical';

  @override
  String get noAndroidVirtualDevices =>
      'No Android virtual or connected devices found';

  @override
  String unableToStartEmulator(Object name) {
    return 'Unable to start $name';
  }

  @override
  String get androidStartErrorDetails =>
      'The emulator process exited during startup. The raw output below can identify SDK, system image, lock-file, or graphics issues.';

  @override
  String androidFailureLogSaved(Object path) {
    return 'Failure log saved: $path';
  }

  @override
  String get openFailureLog => 'Show Log in Finder';

  @override
  String get copyErrorDetails => 'Copy Error Details';

  @override
  String get errorDetailsCopied => 'Error details copied';

  @override
  String get checkEmulatorConfig => 'Check Config';

  @override
  String get checkingEmulatorConfig => 'Checking configuration…';

  @override
  String get emulatorConfigCheckTitle => 'Android Emulator Configuration Check';

  @override
  String get emulatorConfigCheckSubtitle =>
      'Checks AVD descriptors, system images, computer keyboard input, and offline lock files';

  @override
  String get emulatorConfigSafetyNote =>
      'Only safely recoverable settings are repaired. Configurations are backed up first; apps, user data, and snapshots are never deleted.';

  @override
  String get emulatorConfigHealthy => 'Configuration Looks Good';

  @override
  String get emulatorConfigHealthyDescription =>
      'No configuration problems affecting Android emulator startup or debugging were found.';

  @override
  String get emulatorConfigNoAvds => 'No AVDs to Check';

  @override
  String get emulatorConfigNoAvdsDescription =>
      'There are no virtual devices in the current Android AVD directory.';

  @override
  String emulatorConfigSummary(Object avds, Object issues, Object repairable) {
    return 'Checked $avds AVDs · $issues issues · $repairable repairable';
  }

  @override
  String get selectAllRepairable => 'Select all repairable issues';

  @override
  String repairSelectedIssues(Object count) {
    return 'Repair Selected ($count)';
  }

  @override
  String get repairableIssue => 'Automatic repair';

  @override
  String get manualActionRequired => 'Manual action required';

  @override
  String get restartRequired => 'Restart required';

  @override
  String get repairingEmulatorConfig => 'Repairing configuration…';

  @override
  String get emulatorConfigRepairComplete => 'Configuration Repair Complete';

  @override
  String emulatorConfigRepairSummary(Object remaining, Object repaired) {
    return 'Repaired $repaired issues; $remaining still require attention.';
  }

  @override
  String emulatorConfigRepairSkipped(Object count) {
    return '$count issues were skipped because the state changed or a safety check failed.';
  }

  @override
  String emulatorConfigBackupSaved(Object path) {
    return 'Original configuration backed up to: $path';
  }

  @override
  String restartRequiredAvds(Object names) {
    return 'Restart these running emulators to apply changes: $names';
  }

  @override
  String get avdHomeMissingIssue => 'AVD Configuration Directory Unavailable';

  @override
  String avdHomeMissingDescription(Object path) {
    return 'Unable to read the Android AVD configuration directory: $path';
  }

  @override
  String get avdDescriptorMissingIssue => 'AVD Descriptor Missing';

  @override
  String avdDescriptorMissingDescription(Object name) {
    return '$name has no descriptor. A safe link to its actual AVD directory can be recreated.';
  }

  @override
  String get avdDescriptorPathIssue => 'AVD Path Mismatch';

  @override
  String avdDescriptorPathDescription(Object name) {
    return '$name has an invalid descriptor path or it does not match the actual directory.';
  }

  @override
  String get avdDirectoryMissingIssue => 'AVD Data Directory Missing';

  @override
  String avdDirectoryMissingDescription(Object name, Object path) {
    return 'The data directory for $name does not exist: $path';
  }

  @override
  String get avdConfigMissingIssue => 'config.ini Missing';

  @override
  String avdConfigMissingDescription(Object name, Object path) {
    return '$name is missing its core configuration file: $path';
  }

  @override
  String get systemImagePathMissingIssue => 'System Image Setting Missing';

  @override
  String systemImagePathMissingDescription(Object name) {
    return '$name has no image.sysdir.1 in config.ini, so the system image cannot be inferred safely.';
  }

  @override
  String get systemImageMissingIssue => 'System Image Not Installed';

  @override
  String systemImageMissingDescription(Object name, Object path) {
    return 'The system image used by $name is missing: $path. Install it with SDK Manager.';
  }

  @override
  String get systemImagePathIssue => 'System Image Path Is Stale';

  @override
  String systemImagePathDescription(Object name) {
    return '$name still points to an old SDK location and can be repaired to use the installed image.';
  }

  @override
  String get hardwareKeyboardIssue => 'Computer Keyboard Disabled';

  @override
  String hardwareKeyboardIssueDescription(Object name) {
    return '$name cannot reliably receive computer keyboard input and shortcuts.';
  }

  @override
  String get staleLockIssue => 'Offline Lock Files Found';

  @override
  String staleLockDescription(Object count, Object name) {
    return '$name is stopped but has $count stale lock files that may block its next launch.';
  }

  @override
  String currentConfigValue(Object value) {
    return 'Current: $value';
  }

  @override
  String suggestedConfigValue(Object value) {
    return 'Repair to: $value';
  }

  @override
  String get stopEmulatorTitle => 'Stop Emulator?';

  @override
  String stopAndroidEmulatorContent(Object name, Object serial) {
    return 'Shut down $name ($serial)?';
  }

  @override
  String unableToStopEmulator(Object name) {
    return 'Unable to stop $name';
  }

  @override
  String emulatorActionSent(Object action, Object name) {
    return '$action sent to $name';
  }

  @override
  String get stopBeforeDeleteEmulator => 'Stop the emulator before deleting it';

  @override
  String get deleteAvdTitle => 'Delete AVD?';

  @override
  String deleteAvdContent(Object name) {
    return '$name will be permanently removed.';
  }

  @override
  String get running => 'RUNNING';

  @override
  String get shutdown => 'SHUTDOWN';

  @override
  String get androidDeviceNavigation => 'Device Navigation';

  @override
  String get androidBack => 'Back';

  @override
  String get androidHome => 'Home';

  @override
  String get androidRecents => 'Recents';

  @override
  String get androidGestureNavigationHint =>
      'This emulator uses gesture navigation. The bottom pill is not a Back button; swipe inward from either edge or use the Back action here.';

  @override
  String get androidClipboard => 'Computer Clipboard';

  @override
  String get androidCopySelection => 'Copy Selection';

  @override
  String get androidPasteHostClipboard => 'Paste Computer Clipboard';

  @override
  String get androidClipboardHint =>
      'Focus an Android text field first. Unicode and special characters are supported; Mobile Dev Assistant accesses the clipboard only when clicked and never stores its contents.';

  @override
  String get hardwareKeyboardDisabled =>
      'This AVD has no computer keyboard enabled, so direct typing and keyboard shortcuts may not work.';

  @override
  String get enableHardwareKeyboard => 'Enable Computer Keyboard';

  @override
  String get enableHardwareKeyboardTitle =>
      'Enable Computer Keyboard and Restart?';

  @override
  String enableHardwareKeyboardDescription(Object name) {
    return 'This changes the AVD configuration for $name and restarts the emulator. Unsaved UI state may be lost.';
  }

  @override
  String get enableAndRestart => 'Enable and Restart';

  @override
  String hardwareKeyboardEnabled(Object name) {
    return 'Computer keyboard enabled for $name';
  }

  @override
  String get devMenu => 'Dev Menu';

  @override
  String get reloadJs => 'Reload JS';

  @override
  String get deleteEllipsis => 'Delete…';

  @override
  String get androidSdkNotFound => 'Android SDK not found';

  @override
  String get androidSdkNotFoundDescription =>
      'Install the Android SDK and set ANDROID_HOME to manage emulators.';

  @override
  String iosSimulatorSummary(Object count, Object size) {
    return '$count simulators · $size total';
  }

  @override
  String staleAfterDays(Object days) {
    return '> $days days = stale';
  }

  @override
  String stopIosSimulatorContent(Object name) {
    return 'Shut down $name?';
  }

  @override
  String get eraseContentTitle => 'Erase Content?';

  @override
  String eraseContentDescription(Object name) {
    return 'Erase all content and settings on $name? The device itself will be kept.';
  }

  @override
  String get erase => 'Erase';

  @override
  String get deleteSimulatorTitle => 'Delete Simulator?';

  @override
  String deleteSimulatorDescription(Object name, Object size) {
    return '$name will be permanently removed ($size).';
  }

  @override
  String get stale => 'stale';

  @override
  String iosSimulatorDetailLast(
    Object date,
    Object runtime,
    Object size,
    Object state,
  ) {
    return '$runtime · $state · Last: $date · $size';
  }

  @override
  String iosSimulatorDetailNever(Object runtime, Object size, Object state) {
    return '$runtime · $state · Never booted · $size';
  }

  @override
  String get targetIosRuntimeCaches => 'iOS Runtime Caches';

  @override
  String get targetIosRuntimeCachesDescription =>
      'Generated dyld caches. Xcode rebuilds them when the runtime is used again.';

  @override
  String get targetIosRuntimes => 'iOS Runtime Images';

  @override
  String get targetIosRuntimesDescription =>
      'Downloaded iOS versions. Remove old runtimes you no longer test against.';

  @override
  String get targetIosSimulators => 'iOS Simulator Devices';

  @override
  String get targetIosSimulatorsDescription =>
      'Simulator app data. Uses xcrun simctl for safe removal.';

  @override
  String get targetAppCaches => 'Application Caches';

  @override
  String get targetAppCachesDescription =>
      'Rebuildable per-app caches on the primary disk. System caches are excluded.';

  @override
  String get targetQqUpdates => 'QQ Update Downloads';

  @override
  String get targetQqUpdatesDescription =>
      'Downloaded and unpacked QQ updates. QQ can download them again when needed.';

  @override
  String get targetChromeModels => 'Chrome Downloaded Models';

  @override
  String get targetChromeModelsDescription =>
      'On-device optimization models. Chrome may download them again.';

  @override
  String get targetGoogleUpdaterCache => 'Google Updater Cache';

  @override
  String get targetGoogleUpdaterCacheDescription =>
      'Downloaded Chrome and Google component update packages.';

  @override
  String get targetAppSupportCaches => 'Application Update Cache';

  @override
  String get targetAppSupportCachesDescription =>
      'Installer and updater packages stored under Application Support.';

  @override
  String get targetAndroidStudioBackups => 'Android Studio Backups';

  @override
  String get targetAndroidStudioBackupsDescription =>
      'Configuration backups created during IDE upgrades. Review before deleting.';

  @override
  String get targetDownloadArchives => 'Downloaded Archives & Installers';

  @override
  String get targetDownloadArchivesDescription =>
      'Large archives and installers in Downloads. Always review these personal files.';

  @override
  String get targetGradleCaches => 'Gradle Caches';

  @override
  String get targetGradleCachesDescription =>
      'Build/dependency cache. The next build re-downloads dependencies and recompiles.';

  @override
  String get targetGradleWrapper => 'Gradle Wrapper Distributions';

  @override
  String get targetGradleWrapperDescription =>
      'Downloaded Gradle versions. They are restored on the next matching build.';

  @override
  String get targetKonanRuntimes => 'Kotlin/Native Toolchains';

  @override
  String get targetKonanRuntimesDescription =>
      'Downloaded Kotlin/Native versions. Keep versions used by active projects.';

  @override
  String get targetCodexRuntimes => 'Codex Runtime Cache';

  @override
  String get targetCodexRuntimesDescription =>
      'Bundled execution runtimes. They are restored when Codex needs them again.';

  @override
  String get targetLldbCache => 'LLDB Module Cache';

  @override
  String get targetLldbCacheDescription =>
      'Downloaded debugger modules and symbols. Rebuilt during future debug sessions.';

  @override
  String get targetCodexTemp => 'Codex Temporary Files';

  @override
  String get targetCodexTempDescription =>
      'Temporary plugin backups and staging files. Close Codex before cleaning.';

  @override
  String get targetNpmCache => 'npm Cache';

  @override
  String get targetNpmCacheDescription =>
      'npm package cache. Rebuilt automatically when installing packages.';

  @override
  String get targetNodeGyp => 'node-gyp Cache';

  @override
  String get targetNodeGypDescription =>
      'Native addon build cache. Rebuilt when compiling native packages.';

  @override
  String get targetCocoapods => 'CocoaPods Cache';

  @override
  String get targetCocoapodsDescription =>
      'iOS/macOS dependency cache. The next pod install re-downloads packages.';

  @override
  String get targetPipCache => 'pip Cache';

  @override
  String get targetPipCacheDescription =>
      'Python package cache. Rebuilt when installing Python packages.';

  @override
  String get targetHomebrew => 'Homebrew Cache';

  @override
  String get targetHomebrewDescription =>
      'Downloaded package archives. Installed packages remain available.';

  @override
  String get targetPlaywright => 'Playwright Browsers';

  @override
  String get targetPlaywrightDescription =>
      'Browser binaries for testing. Restore them with playwright install.';

  @override
  String get targetJetbrainsCache => 'JetBrains IDE Cache';

  @override
  String get targetJetbrainsCacheDescription =>
      'IDE indexes and caches. The first launch after cleaning is slower.';

  @override
  String get targetXcodeDerived => 'Xcode DerivedData';

  @override
  String get targetXcodeDerivedDescription =>
      'Build intermediates. The next build performs a full recompile.';

  @override
  String get targetXcodeArchives => 'Xcode Archives';

  @override
  String get targetXcodeArchivesDescription =>
      'Distribution archives. Delete only when the archived builds are no longer needed.';

  @override
  String get targetAppLogs => 'Application Logs';

  @override
  String get targetAppLogsDescription =>
      'Per-app log files stored on the primary disk.';
}
