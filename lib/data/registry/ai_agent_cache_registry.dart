import '../../domain/models/ai_agent_cache.dart';

class AiAgentCacheRegistry {
  static List<AiAgentCacheTarget> build(String home) {
    return [
      AiAgentCacheTarget(
        id: 'claude_cli_cache',
        agent: AiAgentKind.claudeCode,
        kind: AiAgentCacheKind.cliCache,
        path: '$home/Library/Caches/claude-cli-nodejs',
      ),
      AiAgentCacheTarget(
        id: 'opencode_cli_cache',
        agent: AiAgentKind.openCode,
        kind: AiAgentCacheKind.cliCache,
        path: '$home/.cache/opencode',
      ),
      AiAgentCacheTarget(
        id: 'opencode_desktop_cache',
        agent: AiAgentKind.openCode,
        kind: AiAgentCacheKind.desktopCache,
        path: '$home/Library/Application Support/ai.opencode.desktop/Cache',
      ),
      AiAgentCacheTarget(
        id: 'opencode_desktop_code_cache',
        agent: AiAgentKind.openCode,
        kind: AiAgentCacheKind.codeCache,
        path:
            '$home/Library/Application Support/ai.opencode.desktop/Code Cache',
      ),
      AiAgentCacheTarget(
        id: 'opencode_desktop_gpu_cache',
        agent: AiAgentKind.openCode,
        kind: AiAgentCacheKind.gpuCache,
        path: '$home/Library/Application Support/ai.opencode.desktop/GPUCache',
      ),
      AiAgentCacheTarget(
        id: 'opencode_updater_cache',
        agent: AiAgentKind.openCode,
        kind: AiAgentCacheKind.updaterDownloads,
        path: '$home/Library/Caches/@opencode-aidesktop-updater',
      ),
      ..._electronTargets(
        home: home,
        agent: AiAgentKind.trae,
        idPrefix: 'trae_cn',
        supportName: 'Trae CN',
      ),
      ..._electronTargets(
        home: home,
        agent: AiAgentKind.trae,
        idPrefix: 'trae_solo_cn',
        supportName: 'TRAE SOLO CN',
      ),
      AiAgentCacheTarget(
        id: 'trae_solo_cache',
        agent: AiAgentKind.trae,
        kind: AiAgentCacheKind.desktopCache,
        path: '$home/Library/Caches/TRAE SOLO CN',
      ),
      AiAgentCacheTarget(
        id: 'trae_solo_updater_cache',
        agent: AiAgentKind.trae,
        kind: AiAgentCacheKind.updaterDownloads,
        path: '$home/Library/Caches/cn.trae.solo.app.ShipIt',
      ),
      ..._electronTargets(
        home: home,
        agent: AiAgentKind.qoder,
        idPrefix: 'qoder',
        supportName: 'Qoder',
        includeExtensions: true,
      ),
      AiAgentCacheTarget(
        id: 'qoder_shared_client_cache',
        agent: AiAgentKind.qoder,
        kind: AiAgentCacheKind.sharedClientCache,
        path: '$home/Library/Application Support/Qoder/SharedClientCache',
      ),
      ..._electronTargets(
        home: home,
        agent: AiAgentKind.qoder,
        idPrefix: 'qoder_stable',
        supportName: 'com.qoder.app.stable',
      ),
      AiAgentCacheTarget(
        id: 'codex_cli_cache',
        agent: AiAgentKind.codex,
        kind: AiAgentCacheKind.cliCache,
        path: '$home/.codex/cache',
      ),
      AiAgentCacheTarget(
        id: 'codex_plugin_cache',
        agent: AiAgentKind.codex,
        kind: AiAgentCacheKind.extensionPackages,
        path: '$home/.codex/plugins/cache',
      ),
      AiAgentCacheTarget(
        id: 'codex_temp',
        agent: AiAgentKind.codex,
        kind: AiAgentCacheKind.temporaryFiles,
        path: '$home/.codex/.tmp',
      ),
      AiAgentCacheTarget(
        id: 'codex_runtime_cache',
        agent: AiAgentKind.codex,
        kind: AiAgentCacheKind.runtimeCache,
        path: '$home/.cache/codex-runtimes',
      ),
      ..._electronTargets(
        home: home,
        agent: AiAgentKind.codex,
        idPrefix: 'codex_desktop',
        supportName: 'Codex',
      ),
      AiAgentCacheTarget(
        id: 'codex_library_cache',
        agent: AiAgentKind.codex,
        kind: AiAgentCacheKind.desktopCache,
        path: '$home/Library/Caches/Codex',
      ),
      ..._electronTargets(
        home: home,
        agent: AiAgentKind.cursor,
        idPrefix: 'cursor',
        supportName: 'Cursor',
        includeExtensions: true,
      ),
      AiAgentCacheTarget(
        id: 'cursor_updater_cache',
        agent: AiAgentKind.cursor,
        kind: AiAgentCacheKind.updaterDownloads,
        path: '$home/Library/Caches/com.todesktop.230313mzl4w4u92.ShipIt',
      ),
    ];
  }

  static List<AiAgentCacheTarget> _electronTargets({
    required String home,
    required AiAgentKind agent,
    required String idPrefix,
    required String supportName,
    bool includeExtensions = false,
  }) {
    final root = '$home/Library/Application Support/$supportName';
    return [
      AiAgentCacheTarget(
        id: '${idPrefix}_cache',
        agent: agent,
        kind: AiAgentCacheKind.desktopCache,
        path: '$root/Cache',
      ),
      AiAgentCacheTarget(
        id: '${idPrefix}_code_cache',
        agent: agent,
        kind: AiAgentCacheKind.codeCache,
        path: '$root/Code Cache',
      ),
      AiAgentCacheTarget(
        id: '${idPrefix}_cached_data',
        agent: agent,
        kind: AiAgentCacheKind.runtimeCache,
        path: '$root/CachedData',
      ),
      AiAgentCacheTarget(
        id: '${idPrefix}_gpu_cache',
        agent: agent,
        kind: AiAgentCacheKind.gpuCache,
        path: '$root/GPUCache',
      ),
      if (includeExtensions)
        AiAgentCacheTarget(
          id: '${idPrefix}_extension_packages',
          agent: agent,
          kind: AiAgentCacheKind.extensionPackages,
          path: '$root/CachedExtensionVSIXs',
        ),
    ];
  }
}
