class CleanProgress {
  final int totalItems;
  final int doneItems;
  final int reclaimedBytes;
  final String? currentPath;
  final bool finished;
  final String? error;

  const CleanProgress({
    required this.totalItems,
    required this.doneItems,
    required this.reclaimedBytes,
    this.currentPath,
    this.finished = false,
    this.error,
  });

  double get fraction => totalItems == 0 ? 0 : doneItems / totalItems;
}
