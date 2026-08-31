import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/category_summary.dart';
import '../domain/models/disk_usage.dart';
import '../domain/models/scan_state.dart';
import 'infra_providers.dart';

final diskUsageProvider = FutureProvider<DiskUsage>((ref) {
  return ref.watch(scanRepositoryProvider).getDiskUsage();
});

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>(
  (ref) => ScanNotifier(ref),
);

class ScanNotifier extends StateNotifier<ScanState> {
  final Ref _ref;
  bool _cancelled = false;

  ScanNotifier(this._ref) : super(const ScanState());

  Future<void> startScan() async {
    _cancelled = false;
    final repo = _ref.read(scanRepositoryProvider);
    final stream = repo.scanAll();
    final categories = <String, CategorySummary>{};
    var count = 0;

    state = ScanState(
      phase: ScanPhase.scanning,
      categories: const {},
      scannedCount: 0,
      totalCount: repo.targetCount,
    );

    await for (final summary in stream) {
      if (_cancelled) break;
      categories[summary.target.id] = summary;
      if (!summary.scanning) count++;
      state = state.copyWith(
        categories: Map.from(categories),
        scannedCount: count,
        currentLabel: summary.scanning ? summary.target.label : null,
      );
    }

    state = state.copyWith(
      phase: _cancelled ? ScanPhase.cancelled : ScanPhase.done,
      currentLabel: null,
    );
  }

  void cancel() {
    _cancelled = true;
  }

  void toggleItem(String categoryId, String path, bool selected) {
    final cats = Map<String, CategorySummary>.from(state.categories);
    final cat = cats[categoryId];
    if (cat == null) return;
    final items = cat.items
        .map((i) => i.path == path ? i.copyWith(selected: selected) : i)
        .toList();
    cats[categoryId] = cat.copyWith(items: items);
    state = state.copyWith(categories: cats);
  }

  void toggleCategory(String categoryId, bool selected) {
    final cats = Map<String, CategorySummary>.from(state.categories);
    final cat = cats[categoryId];
    if (cat == null) return;
    final items = cat.items.map((i) => i.copyWith(selected: selected)).toList();
    cats[categoryId] = cat.copyWith(items: items);
    state = state.copyWith(categories: cats);
  }

  int get selectedBytes =>
      state.categories.values.fold(0, (s, c) => s + c.selectedBytes);

  List<CategorySummary> get selectedSummaries =>
      state.categories.values.where((c) => c.selectedBytes > 0).toList();
}

final recoverableBytesProvider = Provider<int>((ref) {
  final scan = ref.watch(scanProvider);
  return scan.categories.values.fold(0, (s, c) => s + c.selectedBytes);
});

final cleanupCandidateBytesProvider = Provider<int>((ref) {
  final scan = ref.watch(scanProvider);
  return scan.categories.values.fold(0, (s, c) => s + c.totalBytes);
});
