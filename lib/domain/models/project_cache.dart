enum ProjectCacheEcosystem { flutter, android, ios, reactNative, web }

enum ProjectCacheKind {
  toolState,
  buildOutput,
  dependencyArtifacts,
  bundlerCache,
  testOutput,
}

class ProjectCacheItem {
  final String id;
  final String projectName;
  final String projectRoot;
  final String path;
  final ProjectCacheEcosystem ecosystem;
  final ProjectCacheKind kind;
  final int sizeBytes;
  final bool selected;

  const ProjectCacheItem({
    required this.id,
    required this.projectName,
    required this.projectRoot,
    required this.path,
    required this.ecosystem,
    required this.kind,
    required this.sizeBytes,
    this.selected = false,
  });

  ProjectCacheItem copyWith({int? sizeBytes, bool? selected}) {
    return ProjectCacheItem(
      id: id,
      projectName: projectName,
      projectRoot: projectRoot,
      path: path,
      ecosystem: ecosystem,
      kind: kind,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      selected: selected ?? this.selected,
    );
  }
}

class ProjectCacheCleanupResult {
  final int cleanedCount;
  final int reclaimedBytes;

  const ProjectCacheCleanupResult({
    required this.cleanedCount,
    required this.reclaimedBytes,
  });
}
