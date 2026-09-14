import 'category_summary.dart';

enum ScanPhase { idle, scanning, done, cancelled }

class ScanState {
  final ScanPhase phase;
  final Map<String, CategorySummary> categories;
  final int scannedCount;
  final int totalCount;
  final String? currentTargetId;

  const ScanState({
    this.phase = ScanPhase.idle,
    this.categories = const {},
    this.scannedCount = 0,
    this.totalCount = 0,
    this.currentTargetId,
  });

  double get progress => totalCount == 0 ? 0 : scannedCount / totalCount;

  ScanState copyWith({
    ScanPhase? phase,
    Map<String, CategorySummary>? categories,
    int? scannedCount,
    int? totalCount,
    String? currentTargetId,
    bool clearCurrentTarget = false,
  }) => ScanState(
    phase: phase ?? this.phase,
    categories: categories ?? this.categories,
    scannedCount: scannedCount ?? this.scannedCount,
    totalCount: totalCount ?? this.totalCount,
    currentTargetId: clearCurrentTarget
        ? null
        : currentTargetId ?? this.currentTargetId,
  );
}
