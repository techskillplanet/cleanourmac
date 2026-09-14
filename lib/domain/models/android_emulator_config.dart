enum AndroidEmulatorConfigIssueSeverity { warning, error }

enum AndroidEmulatorConfigIssueKind {
  avdHomeMissing,
  descriptorMissing,
  descriptorPathMismatch,
  avdDirectoryMissing,
  configMissing,
  systemImagePathMissing,
  systemImageMissing,
  systemImagePathMismatch,
  hardwareKeyboardDisabled,
  staleLockFiles,
}

class AndroidEmulatorConfigIssue {
  final String avdName;
  final AndroidEmulatorConfigIssueKind kind;
  final AndroidEmulatorConfigIssueSeverity severity;
  final bool repairable;
  final bool requiresRestart;
  final String path;
  final String? currentValue;
  final String? suggestedValue;
  final List<String> relatedPaths;

  const AndroidEmulatorConfigIssue({
    required this.avdName,
    required this.kind,
    required this.severity,
    required this.repairable,
    required this.path,
    this.requiresRestart = false,
    this.currentValue,
    this.suggestedValue,
    this.relatedPaths = const [],
  });

  String get id => '$avdName:${kind.name}';
}

class AndroidEmulatorConfigReport {
  final DateTime checkedAt;
  final int avdCount;
  final List<String> sdkRoots;
  final List<AndroidEmulatorConfigIssue> issues;

  const AndroidEmulatorConfigReport({
    required this.checkedAt,
    required this.avdCount,
    required this.sdkRoots,
    required this.issues,
  });

  List<AndroidEmulatorConfigIssue> get repairableIssues =>
      issues.where((issue) => issue.repairable).toList();

  int get repairableCount => repairableIssues.length;

  bool get isHealthy => issues.isEmpty;
}

class AndroidEmulatorConfigRepairResult {
  final int repairedCount;
  final int skippedCount;
  final String? backupDirectory;
  final List<String> restartRequiredAvds;
  final AndroidEmulatorConfigReport report;

  const AndroidEmulatorConfigRepairResult({
    required this.repairedCount,
    required this.skippedCount,
    required this.backupDirectory,
    required this.restartRequiredAvds,
    required this.report,
  });
}
