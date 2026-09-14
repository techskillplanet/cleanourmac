import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../domain/models/ai_agent_cache.dart';
import '../../domain/models/cleanup_target.dart';
import '../../domain/models/large_file.dart';
import '../../domain/models/project_cache.dart';
import '../../domain/models/react_native_project.dart';
import '../../domain/models/scan_item.dart';
import '../../l10n/app_localizations.dart';

extension BuildContextLocalization on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String get localeName => Localizations.localeOf(this).toLanguageTag();
}

extension AppLocalizationsHelpers on AppLocalizations {
  String projectCacheEcosystemLabel(ProjectCacheEcosystem ecosystem) {
    return switch (ecosystem) {
      ProjectCacheEcosystem.flutter => projectCacheEcosystemFlutter,
      ProjectCacheEcosystem.android => projectCacheEcosystemAndroid,
      ProjectCacheEcosystem.ios => projectCacheEcosystemIos,
      ProjectCacheEcosystem.reactNative => projectCacheEcosystemRn,
      ProjectCacheEcosystem.web => projectCacheEcosystemWeb,
    };
  }

  String projectCacheKindLabel(ProjectCacheKind kind) {
    return switch (kind) {
      ProjectCacheKind.toolState => projectCacheKindTool,
      ProjectCacheKind.buildOutput => projectCacheKindBuild,
      ProjectCacheKind.dependencyArtifacts => projectCacheKindDependencies,
      ProjectCacheKind.bundlerCache => projectCacheKindBundler,
      ProjectCacheKind.testOutput => projectCacheKindTest,
    };
  }

  String projectOpenTargetLabel(ProjectOpenTarget target) {
    return switch (target) {
      ProjectOpenTarget.codexDesktop => openWithCodex,
      ProjectOpenTarget.codexCli => openWithCodexCli,
      ProjectOpenTarget.cursor => openWithCursor,
      ProjectOpenTarget.visualStudioCode => openWithVsCode,
      ProjectOpenTarget.androidStudio => openWithAndroidStudio,
      ProjectOpenTarget.xcode => openWithXcode,
      ProjectOpenTarget.qoder => openWithQoder,
      ProjectOpenTarget.trae => openWithTrae,
      ProjectOpenTarget.webStorm => openWithWebStorm,
      ProjectOpenTarget.zed => openWithZed,
      ProjectOpenTarget.windsurf => openWithWindsurf,
      ProjectOpenTarget.finder => showInFinder,
      ProjectOpenTarget.terminal => openInTerminal,
    };
  }

  String aiAgentName(AiAgentKind agent) {
    return switch (agent) {
      AiAgentKind.claudeCode => claudeCode,
      AiAgentKind.openCode => openCode,
      AiAgentKind.trae => trae,
      AiAgentKind.qoder => qoder,
      AiAgentKind.codex => codex,
      AiAgentKind.cursor => cursor,
    };
  }

  String aiAgentCacheKindLabel(AiAgentCacheKind kind) {
    return switch (kind) {
      AiAgentCacheKind.cliCache => cacheKindCli,
      AiAgentCacheKind.desktopCache => cacheKindDesktop,
      AiAgentCacheKind.codeCache => cacheKindCode,
      AiAgentCacheKind.gpuCache => cacheKindGpu,
      AiAgentCacheKind.extensionPackages => cacheKindExtensions,
      AiAgentCacheKind.updaterDownloads => cacheKindUpdater,
      AiAgentCacheKind.sharedClientCache => cacheKindShared,
      AiAgentCacheKind.temporaryFiles => cacheKindTemporary,
      AiAgentCacheKind.runtimeCache => cacheKindRuntime,
    };
  }

  String cleanupTargetLabel(String id, {required String fallback}) {
    return switch (id) {
      'ios_runtime_caches' => targetIosRuntimeCaches,
      'ios_runtimes' => targetIosRuntimes,
      'ios_simulators' => targetIosSimulators,
      'app_caches' => targetAppCaches,
      'qq_updates' => targetQqUpdates,
      'chrome_models' => targetChromeModels,
      'google_updater_cache' => targetGoogleUpdaterCache,
      'app_support_caches' => targetAppSupportCaches,
      'android_studio_backups' => targetAndroidStudioBackups,
      'download_archives' => targetDownloadArchives,
      'gradle_caches' => targetGradleCaches,
      'gradle_wrapper' => targetGradleWrapper,
      'android_cli_cache' => targetAndroidCliCache,
      'android_studio_cache' => targetAndroidStudioCache,
      'dart_pub_hosted' => targetDartPubHosted,
      'dart_pub_git' => targetDartPubGit,
      'konan_runtimes' => targetKonanRuntimes,
      'codex_runtimes' => targetCodexRuntimes,
      'lldb_cache' => targetLldbCache,
      'codex_temp' => targetCodexTemp,
      'npm_cache' => targetNpmCache,
      'yarn_cache' => targetYarnCache,
      'yarn_xdg_cache' => targetYarnXdgCache,
      'pnpm_store' => targetPnpmStore,
      'pnpm_legacy_store' => targetPnpmLegacyStore,
      'bun_cache' => targetBunCache,
      'corepack_cache' => targetCorepackCache,
      'node_gyp' => targetNodeGyp,
      'cocoapods' => targetCocoapods,
      'swiftpm_cache' => targetSwiftpmCache,
      'swiftpm_repositories' => targetSwiftpmRepositories,
      'carthage_cache' => targetCarthageCache,
      'pip_cache' => targetPipCache,
      'homebrew' => targetHomebrew,
      'playwright' => targetPlaywright,
      'cypress' => targetCypress,
      'deno_cache' => targetDenoCache,
      'jetbrains_cache' => targetJetbrainsCache,
      'xcode_derived' => targetXcodeDerived,
      'xcode_archives' => targetXcodeArchives,
      'xcode_device_support' => targetXcodeDeviceSupport,
      'app_logs' => targetAppLogs,
      _ => fallback,
    };
  }

  String cleanupTargetDescription(String id, {required String fallback}) {
    return switch (id) {
      'ios_runtime_caches' => targetIosRuntimeCachesDescription,
      'ios_runtimes' => targetIosRuntimesDescription,
      'ios_simulators' => targetIosSimulatorsDescription,
      'app_caches' => targetAppCachesDescription,
      'qq_updates' => targetQqUpdatesDescription,
      'chrome_models' => targetChromeModelsDescription,
      'google_updater_cache' => targetGoogleUpdaterCacheDescription,
      'app_support_caches' => targetAppSupportCachesDescription,
      'android_studio_backups' => targetAndroidStudioBackupsDescription,
      'download_archives' => targetDownloadArchivesDescription,
      'gradle_caches' => targetGradleCachesDescription,
      'gradle_wrapper' => targetGradleWrapperDescription,
      'android_cli_cache' => targetAndroidCliCacheDescription,
      'android_studio_cache' => targetAndroidStudioCacheDescription,
      'dart_pub_hosted' => targetDartPubHostedDescription,
      'dart_pub_git' => targetDartPubGitDescription,
      'konan_runtimes' => targetKonanRuntimesDescription,
      'codex_runtimes' => targetCodexRuntimesDescription,
      'lldb_cache' => targetLldbCacheDescription,
      'codex_temp' => targetCodexTempDescription,
      'npm_cache' => targetNpmCacheDescription,
      'yarn_cache' => targetYarnCacheDescription,
      'yarn_xdg_cache' => targetYarnXdgCacheDescription,
      'pnpm_store' => targetPnpmStoreDescription,
      'pnpm_legacy_store' => targetPnpmLegacyStoreDescription,
      'bun_cache' => targetBunCacheDescription,
      'corepack_cache' => targetCorepackCacheDescription,
      'node_gyp' => targetNodeGypDescription,
      'cocoapods' => targetCocoapodsDescription,
      'swiftpm_cache' => targetSwiftpmCacheDescription,
      'swiftpm_repositories' => targetSwiftpmRepositoriesDescription,
      'carthage_cache' => targetCarthageCacheDescription,
      'pip_cache' => targetPipCacheDescription,
      'homebrew' => targetHomebrewDescription,
      'playwright' => targetPlaywrightDescription,
      'cypress' => targetCypressDescription,
      'deno_cache' => targetDenoCacheDescription,
      'jetbrains_cache' => targetJetbrainsCacheDescription,
      'xcode_derived' => targetXcodeDerivedDescription,
      'xcode_archives' => targetXcodeArchivesDescription,
      'xcode_device_support' => targetXcodeDeviceSupportDescription,
      'app_logs' => targetAppLogsDescription,
      _ => fallback,
    };
  }

  String safetyLabel(SafetyLevel safety) {
    return switch (safety) {
      SafetyLevel.safe => safeToClean,
      SafetyLevel.caution => caution,
      SafetyLevel.danger => danger,
    };
  }

  String largeFileSafetyLabel(LargeFileSafety safety) {
    return switch (safety) {
      LargeFileSafety.safe => largeFileSafetySafe,
      LargeFileSafety.caution => largeFileSafetyCaution,
      LargeFileSafety.keep => caution,
    };
  }

  String largeFileSafetyReason(LargeFileSafety safety) {
    return switch (safety) {
      LargeFileSafety.safe => largeFileSafetyReasonSafe,
      LargeFileSafety.caution ||
      LargeFileSafety.keep => largeFileSafetyReasonCaution,
    };
  }

  String localizedScanItemName(String categoryId, ScanItem item) {
    if (categoryId == 'ios_runtime_caches') {
      return runtimeCacheName(item.name);
    }
    return item.name;
  }

  String? localizedScanItemDetail(ScanItem item) {
    final value = item.detailValue;
    final date = item.detailDate == null
        ? null
        : DateFormat.yMd(localeName).format(item.detailDate!.toLocal());

    return switch (item.detailType) {
      ScanItemDetailType.simulator when value != null && date != null =>
        simulatorScanDetailLastUsed(value, date),
      ScanItemDetailType.simulator when value != null =>
        simulatorScanDetailNever(value),
      ScanItemDetailType.runtime when value != null && date != null =>
        runtimeBuildLastUsed(value, date),
      ScanItemDetailType.runtime when value != null => runtimeBuild(value),
      ScanItemDetailType.runtimeCache => runtimeCacheDetail,
      _ => item.detail,
    };
  }
}
