enum AiAgentKind { claudeCode, openCode, trae, qoder, codex, cursor }

enum AiAgentCacheKind {
  cliCache,
  desktopCache,
  codeCache,
  gpuCache,
  extensionPackages,
  updaterDownloads,
  sharedClientCache,
  temporaryFiles,
  runtimeCache,
}

class AiAgentCacheTarget {
  final String id;
  final AiAgentKind agent;
  final AiAgentCacheKind kind;
  final String path;

  const AiAgentCacheTarget({
    required this.id,
    required this.agent,
    required this.kind,
    required this.path,
  });
}

class AiAgentCacheItem {
  final AiAgentCacheTarget target;
  final int sizeBytes;
  final bool selected;

  const AiAgentCacheItem({
    required this.target,
    required this.sizeBytes,
    this.selected = false,
  });

  AiAgentCacheItem copyWith({int? sizeBytes, bool? selected}) {
    return AiAgentCacheItem(
      target: target,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      selected: selected ?? this.selected,
    );
  }
}

class AiAgentCleanupResult {
  final int cleanedCount;
  final int reclaimedBytes;

  const AiAgentCleanupResult({
    required this.cleanedCount,
    required this.reclaimedBytes,
  });
}
