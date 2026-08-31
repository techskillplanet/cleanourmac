import 'category_summary.dart';

enum ScanPhase { idle, scanning, done, cancelled }

class ScanState {
  final ScanPhase phase;
  final Map<String, CategorySummary> categories;
  final int scannedCount;
  final int totalCount;
  final String? currentLabel;

  const ScanState({
    this.phase = ScanPhase.idle,
    this.categories = const {},
    this.scannedCount = 0,
    this.totalCount = 0,
    this.currentLabel,
  });

  double get progress => totalCount == 0 ? 0 : scannedCount / totalCount;

  ScanState copyWith({
    ScanPhase? phase,
    Map<String, CategorySummary>? categories,
    int? scannedCount,
    int? totalCount,
    String? currentLabel,
  }) =>
      ScanState(
        phase: phase ?? this.phase,
        categories: categories ?? this.categories,
        scannedCount: scannedCount ?? this.scannedCount,
        totalCount: totalCount ?? this.totalCount,
        currentLabel: currentLabel ?? this.currentLabel,
      );
}
