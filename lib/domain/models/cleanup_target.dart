enum SafetyLevel { safe, caution, danger }

enum ScanStrategy {
  duSingle,
  duChildren,
  duMatchingChildren,
  matchingFiles,
  simctl,
  simctlRuntime,
  simctlDyldCache,
  findLarge,
}

class CleanupTarget {
  final String id;
  final String label;
  final String description;
  final String absolutePath;
  final SafetyLevel safety;
  final ScanStrategy strategy;
  final bool contentsOnly;
  final Set<String> keepChildren;
  final Set<String> includeChildPrefixes;
  final Set<String> includeChildSuffixes;
  final Set<String> includeExtensions;
  final int minimumSizeBytes;

  const CleanupTarget({
    required this.id,
    required this.label,
    required this.description,
    required this.absolutePath,
    required this.safety,
    this.strategy = ScanStrategy.duSingle,
    this.contentsOnly = false,
    this.keepChildren = const {},
    this.includeChildPrefixes = const {},
    this.includeChildSuffixes = const {},
    this.includeExtensions = const {},
    this.minimumSizeBytes = 0,
  });
}
