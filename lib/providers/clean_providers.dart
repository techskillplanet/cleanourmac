import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/category_summary.dart';
import '../domain/models/clean_progress.dart';
import 'infra_providers.dart';
import 'scan_providers.dart';

final cleanProvider = StateNotifierProvider<CleanNotifier, CleanProgress?>(
  (ref) => CleanNotifier(ref),
);

class CleanNotifier extends StateNotifier<CleanProgress?> {
  final Ref _ref;
  CleanNotifier(this._ref) : super(null);

  Future<void> execute(List<CategorySummary> summaries) async {
    final repo = _ref.read(cleanRepositoryProvider);
    await for (final progress in repo.execute(summaries)) {
      state = progress;
    }
    // Refresh disk usage and scan after cleaning
    _ref.invalidate(diskUsageProvider);
  }

  void reset() => state = null;
}
