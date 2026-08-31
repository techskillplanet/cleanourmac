import 'dart:io';
import '../../domain/models/cleanup_target.dart';

class CleanupRegistry {
  static List<CleanupTarget> build() {
    final home = Platform.environment['HOME']!;
    return [
      // High-impact items physically stored on the primary Data volume.
      const CleanupTarget(
        id: 'ios_runtime_caches',
        label: 'iOS Runtime Caches',
        description:
            'Generated dyld caches. Xcode rebuilds them when the runtime is used again.',
        absolutePath: '/Library/Developer/CoreSimulator/Caches/dyld',
        safety: SafetyLevel.caution,
        strategy: ScanStrategy.simctlDyldCache,
      ),
      const CleanupTarget(
        id: 'ios_runtimes',
        label: 'iOS Runtime Images',
        description:
            'Downloaded iOS versions. Remove old runtimes you no longer test against.',
        absolutePath: '/Library/Developer/CoreSimulator',
        safety: SafetyLevel.caution,
        strategy: ScanStrategy.simctlRuntime,
      ),
      CleanupTarget(
        id: 'ios_simulators',
        label: 'iOS Simulator Devices',
        description: 'Simulator app data. Uses xcrun simctl for safe removal.',
        absolutePath: '$home/Library/Developer/CoreSimulator/Devices',
        safety: SafetyLevel.caution,
        strategy: ScanStrategy.simctl,
      ),
      CleanupTarget(
        id: 'app_caches',
        label: 'Application Caches',
        description:
            'Rebuildable per-app caches on the primary disk. System caches are excluded.',
        absolutePath: '$home/Library/Caches',
        safety: SafetyLevel.caution,
        strategy: ScanStrategy.duChildren,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'qq_updates',
        label: 'QQ Update Downloads',
        description:
            'Downloaded and unpacked QQ updates. QQ can download them again when needed.',
        absolutePath:
            '$home/Library/Containers/com.tencent.qq/Data/Library/Application Support/QQ/versions',
        safety: SafetyLevel.caution,
        strategy: ScanStrategy.duChildren,
      ),
      CleanupTarget(
        id: 'chrome_models',
        label: 'Chrome Downloaded Models',
        description:
            'On-device optimization models. Chrome may download them again.',
        absolutePath:
            '$home/Library/Application Support/Google/Chrome/OptGuideOnDeviceModel',
        safety: SafetyLevel.caution,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'google_updater_cache',
        label: 'Google Updater Cache',
        description: 'Downloaded Chrome and Google component update packages.',
        absolutePath:
            '$home/Library/Application Support/Google/GoogleUpdater/crx_cache',
        safety: SafetyLevel.safe,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'app_support_caches',
        label: 'Application Update Cache',
        description:
            'Installer and updater packages stored under Application Support.',
        absolutePath: '$home/Library/Application Support/Caches',
        safety: SafetyLevel.safe,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'android_studio_backups',
        label: 'Android Studio Backups',
        description:
            'Configuration backups created during IDE upgrades. Review before deleting.',
        absolutePath: '$home/Library/Application Support/Google',
        safety: SafetyLevel.caution,
        strategy: ScanStrategy.duMatchingChildren,
        includeChildSuffixes: {'-backup'},
      ),
      CleanupTarget(
        id: 'download_archives',
        label: 'Downloaded Archives & Installers',
        description:
            'Large archives and installers in Downloads. Always review these personal files.',
        absolutePath: '$home/Downloads',
        safety: SafetyLevel.danger,
        strategy: ScanStrategy.matchingFiles,
        includeExtensions: {
          '7z',
          'bz2',
          'dmg',
          'gz',
          'iso',
          'pkg',
          'rar',
          'tar',
          'tgz',
          'xip',
          'xz',
          'zip',
        },
        minimumSizeBytes: 50 * 1024 * 1024,
      ),

      // Developer caches. These are rebuildable but can make the next build slower.
      CleanupTarget(
        id: 'gradle_caches',
        label: 'Gradle Caches',
        description:
            'Build/dependency cache. The next build re-downloads dependencies and recompiles.',
        absolutePath: '$home/.gradle/caches',
        safety: SafetyLevel.caution,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'gradle_wrapper',
        label: 'Gradle Wrapper Distributions',
        description:
            'Downloaded Gradle versions. They are restored on the next matching build.',
        absolutePath: '$home/.gradle/wrapper/dists',
        safety: SafetyLevel.caution,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'konan_runtimes',
        label: 'Kotlin/Native Toolchains',
        description:
            'Downloaded Kotlin/Native versions. Keep versions used by active projects.',
        absolutePath: '$home/.konan',
        safety: SafetyLevel.caution,
        strategy: ScanStrategy.duChildren,
      ),
      CleanupTarget(
        id: 'codex_runtimes',
        label: 'Codex Runtime Cache',
        description:
            'Bundled execution runtimes. They are restored when Codex needs them again.',
        absolutePath: '$home/.cache/codex-runtimes',
        safety: SafetyLevel.caution,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'lldb_cache',
        label: 'LLDB Module Cache',
        description:
            'Downloaded debugger modules and symbols. Rebuilt during future debug sessions.',
        absolutePath: '$home/.lldb/module_cache',
        safety: SafetyLevel.safe,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'codex_temp',
        label: 'Codex Temporary Files',
        description:
            'Temporary plugin backups and staging files. Close Codex before cleaning.',
        absolutePath: '$home/.codex/.tmp',
        safety: SafetyLevel.safe,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'npm_cache',
        label: 'npm Cache',
        description:
            'npm package cache. Rebuilt automatically when installing packages.',
        absolutePath: '$home/.npm/_cacache',
        safety: SafetyLevel.safe,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'node_gyp',
        label: 'node-gyp Cache',
        description:
            'Native addon build cache. Rebuilt when compiling native packages.',
        absolutePath: '$home/Library/Caches/node-gyp',
        safety: SafetyLevel.safe,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'cocoapods',
        label: 'CocoaPods Cache',
        description:
            'iOS/macOS dependency cache. The next pod install re-downloads packages.',
        absolutePath: '$home/Library/Caches/CocoaPods',
        safety: SafetyLevel.caution,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'pip_cache',
        label: 'pip Cache',
        description:
            'Python package cache. Rebuilt when installing Python packages.',
        absolutePath: '$home/Library/Caches/pip',
        safety: SafetyLevel.safe,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'homebrew',
        label: 'Homebrew Cache',
        description:
            'Downloaded package archives. Installed packages remain available.',
        absolutePath: '$home/Library/Caches/Homebrew',
        safety: SafetyLevel.safe,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'playwright',
        label: 'Playwright Browsers',
        description:
            'Browser binaries for testing. Restore them with playwright install.',
        absolutePath: '$home/Library/Caches/ms-playwright',
        safety: SafetyLevel.caution,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'jetbrains_cache',
        label: 'JetBrains IDE Cache',
        description:
            'IDE indexes and caches. The first launch after cleaning is slower.',
        absolutePath: '$home/Library/Caches/JetBrains',
        safety: SafetyLevel.caution,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'xcode_derived',
        label: 'Xcode DerivedData',
        description:
            'Build intermediates. The next build performs a full recompile.',
        absolutePath: '$home/Library/Developer/Xcode/DerivedData',
        safety: SafetyLevel.caution,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'xcode_archives',
        label: 'Xcode Archives',
        description:
            'Distribution archives. Delete only when the archived builds are no longer needed.',
        absolutePath: '$home/Library/Developer/Xcode/Archives',
        safety: SafetyLevel.caution,
        contentsOnly: true,
      ),
      CleanupTarget(
        id: 'app_logs',
        label: 'Application Logs',
        description: 'Per-app log files stored on the primary disk.',
        absolutePath: '$home/Library/Logs',
        safety: SafetyLevel.safe,
        strategy: ScanStrategy.duChildren,
        contentsOnly: true,
      ),
    ];
  }
}
