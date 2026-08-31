import 'dart:async';
import 'dart:io';
import '../../domain/models/category_summary.dart';
import '../../domain/models/clean_progress.dart';
import '../../domain/models/cleanup_target.dart';
import '../../domain/models/scan_item.dart';
import '../../data/safety/path_guard.dart';
import '../../data/shell/simctl_client.dart';

class CleanRepository {
  final PathGuard _guard;
  final SimctlClient _simctl;

  CleanRepository(this._guard, this._simctl);

  // Validates and returns items that can safely be deleted.
  List<ScanItem> dryRun(List<CategorySummary> summaries) {
    final items = <ScanItem>[];
    for (final summary in summaries) {
      for (final item in summary.items.where((i) => i.selected)) {
        if (_usesSimctl(summary.target.strategy)) {
          items.add(item);
        } else if (_guard.isSafe(
          item.path,
          approvedRoot: summary.target.absolutePath,
        )) {
          items.add(item);
        }
      }
    }
    return items;
  }

  // Deletes the contents of [dir] but keeps the directory itself.
  Future<void> _clearDirectory(Directory dir) async {
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is Directory) {
        await entity.delete(recursive: true);
      } else {
        await entity.delete();
      }
    }
  }

  // Executes deletion with PathGuard re-check per item.
  Stream<CleanProgress> execute(List<CategorySummary> summaries) async* {
    final items = dryRun(summaries);
    var done = 0;
    var reclaimed = 0;

    for (final summary in summaries) {
      final contentsOnly = summary.target.contentsOnly;
      for (final item in summary.items.where((i) => i.selected)) {
        if (!items.contains(item)) continue;

        yield CleanProgress(
          totalItems: items.length,
          doneItems: done,
          reclaimedBytes: reclaimed,
          currentPath: item.path,
        );

        try {
          final strategy = summary.target.strategy;
          if (strategy == ScanStrategy.simctl) {
            await _simctl.deleteDevice(item.actionId ?? item.path);
          } else if (strategy == ScanStrategy.simctlRuntime) {
            await _simctl.deleteRuntime(item.actionId ?? item.path);
          } else if (strategy == ScanStrategy.simctlDyldCache) {
            await _simctl.removeDyldCache(item.actionId ?? item.path);
          } else {
            _guard.assertDeletable(
              item.path,
              approvedRoot: summary.target.absolutePath,
            );
            final entity = FileSystemEntity.typeSync(
              item.path,
              followLinks: false,
            );
            if (entity == FileSystemEntityType.directory) {
              final dir = Directory(item.path);
              if (contentsOnly) {
                await _clearDirectory(dir);
              } else {
                await dir.delete(recursive: true);
              }
            } else if (entity == FileSystemEntityType.file) {
              await File(item.path).delete();
            }
          }
          reclaimed += item.sizeBytes;
        } catch (e) {
          // Skip and continue — log but don't abort the whole clean
        }

        done++;
      }
    }

    yield CleanProgress(
      totalItems: items.length,
      doneItems: done,
      reclaimedBytes: reclaimed,
      finished: true,
    );
  }

  bool _usesSimctl(ScanStrategy strategy) =>
      strategy == ScanStrategy.simctl ||
      strategy == ScanStrategy.simctlRuntime ||
      strategy == ScanStrategy.simctlDyldCache;
}
