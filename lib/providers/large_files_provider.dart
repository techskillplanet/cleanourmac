import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/large_file.dart';
import 'infra_providers.dart';

class LargeFilesState {
  final List<LargeFile> files;
  final bool scanning;
  final bool deleting;
  final int? deletedCount;
  final int? reclaimedBytes;

  const LargeFilesState({
    this.files = const [],
    this.scanning = false,
    this.deleting = false,
    this.deletedCount,
    this.reclaimedBytes,
  });

  int get selectedCount => files.where((f) => f.selected).length;
  int get selectedBytes => files.where((f) => f.selected).fold(0, (s, f) => s + f.sizeBytes);

  LargeFilesState copyWith({
    List<LargeFile>? files,
    bool? scanning,
    bool? deleting,
    int? deletedCount,
    int? reclaimedBytes,
  }) =>
      LargeFilesState(
        files: files ?? this.files,
        scanning: scanning ?? this.scanning,
        deleting: deleting ?? this.deleting,
        deletedCount: deletedCount ?? this.deletedCount,
        reclaimedBytes: reclaimedBytes ?? this.reclaimedBytes,
      );
}

final largeFilesProvider =
    StateNotifierProvider<LargeFilesNotifier, LargeFilesState>(
  (ref) => LargeFilesNotifier(ref),
);

class LargeFilesNotifier extends StateNotifier<LargeFilesState> {
  final Ref _ref;

  LargeFilesNotifier(this._ref) : super(const LargeFilesState());

  Future<void> scan() async {
    if (state.scanning) return;
    state = state.copyWith(scanning: true, files: [], deletedCount: null, reclaimedBytes: null);
    final home = _ref.read(homeProvider);
    final threshold = _ref.read(settingsProvider).largeFileThresholdMB;
    final scanner = _ref.read(findScannerProvider);

    await for (final file in scanner.scan(home, thresholdMB: threshold)) {
      // Skip keep-classified files — never show them as deletable candidates
      if (file.safety == LargeFileSafety.keep) continue;
      state = state.copyWith(files: [...state.files, file]);
    }
    state = state.copyWith(scanning: false);
  }

  void toggle(String path, bool selected) {
    final updated = state.files
        .map((f) => f.path == path ? f.copyWith(selected: selected) : f)
        .toList();
    state = state.copyWith(files: updated);
  }

  void toggleAll(bool selected) {
    // Only toggle caution files; safe files can always be toggled
    final updated = state.files
        .map((f) => f.copyWith(selected: selected))
        .toList();
    state = state.copyWith(files: updated);
  }

  void selectBySafety(LargeFileSafety safety, bool selected) {
    final updated = state.files
        .map((f) => f.safety == safety ? f.copyWith(selected: selected) : f)
        .toList();
    state = state.copyWith(files: updated);
  }

  // Returns list of paths that passed PathGuard and are selected
  List<LargeFile> dryRun() {
    final guard = _ref.read(pathGuardProvider);
    return state.files.where((f) => f.selected && guard.isSafe(f.path)).toList();
  }

  Future<void> deleteSelected() async {
    if (state.deleting) return;
    final guard = _ref.read(pathGuardProvider);
    final toDelete = dryRun();
    if (toDelete.isEmpty) return;

    state = state.copyWith(deleting: true);
    var count = 0;
    var reclaimed = 0;

    for (final f in toDelete) {
      try {
        guard.assertDeletable(f.path); // re-validate immediately before delete
        await File(f.path).delete();
        count++;
        reclaimed += f.sizeBytes;
      } catch (_) {
        // skip — don't abort entire batch
      }
    }

    // Remove deleted files from list
    final deletedPaths = toDelete.map((f) => f.path).toSet();
    final remaining = state.files.where((f) => !deletedPaths.contains(f.path)).toList();

    state = state.copyWith(
      files: remaining,
      deleting: false,
      deletedCount: count,
      reclaimedBytes: reclaimed,
    );
  }
}
