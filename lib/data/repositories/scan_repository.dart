import 'dart:async';
import 'dart:io';
import '../../domain/models/category_summary.dart';
import '../../domain/models/cleanup_target.dart';
import '../../domain/models/disk_usage.dart';
import '../../domain/models/scan_item.dart';
import '../../domain/models/simulator_device.dart';
import '../../data/safety/denylist.dart';
import '../../data/shell/du_scanner.dart';
import '../../data/shell/df_client.dart';
import '../../data/shell/simctl_client.dart';
import '../../data/registry/cleanup_registry.dart';

class ScanRepository {
  final DuScanner _du;
  final DfClient _df;
  final SimctlClient _simctl;

  ScanRepository(this._du, this._df, this._simctl);

  Future<DiskUsage> getDiskUsage() => _df.getDataVolume();
  int get targetCount => CleanupRegistry.build().length;

  // Streams category summaries one by one as they are scanned.
  Stream<CategorySummary> scanAll() async* {
    final targets = CleanupRegistry.build();
    for (final target in targets) {
      yield CategorySummary(target: target, scanning: true);
      try {
        final items = await _scanTarget(target);
        yield CategorySummary(target: target, items: items);
      } catch (e) {
        yield CategorySummary(target: target, error: e.toString());
      }
    }
  }

  Future<List<ScanItem>> _scanTarget(CleanupTarget target) async {
    switch (target.strategy) {
      case ScanStrategy.duChildren:
        return _scanChildren(target);
      case ScanStrategy.duMatchingChildren:
        return _scanMatchingChildren(target);
      case ScanStrategy.matchingFiles:
        return _scanMatchingFiles(target);
      case ScanStrategy.simctl:
        return _scanSimulators();
      case ScanStrategy.simctlRuntime:
        return _scanRuntimes();
      case ScanStrategy.simctlDyldCache:
        return _scanRuntimeCaches(target);
      case ScanStrategy.duSingle:
      case ScanStrategy.findLarge:
        return _scanSingle(target);
    }
  }

  Future<List<ScanItem>> _scanSingle(CleanupTarget target) async {
    final sizeBytes = await _du.sizeOf(target.absolutePath);
    if (sizeBytes == 0) return [];
    return [
      ScanItem(
        path: target.absolutePath,
        sizeBytes: sizeBytes,
        safety: target.safety,
        selected: target.safety == SafetyLevel.safe,
      ),
    ];
  }

  // Directories already tracked as their own cleanup targets. Skipping them
  // here prevents app_caches from duplicating/mis-deleting dev tool caches.
  static const _devCacheNames = <String>{
    'JetBrains',
    'CocoaPods',
    'pip',
    'Homebrew',
    'node-gyp',
    'ms-playwright',
    'npm',
  };

  Future<List<ScanItem>> _scanChildren(CleanupTarget target) async {
    final dir = Directory(target.absolutePath);
    if (!dir.existsSync()) return [];

    final children = dir
        .listSync(followLinks: false)
        .map((e) => e.path)
        .toList();
    if (children.isEmpty) return [];

    final sizes = await _du.sizeOfMultiple(children);

    return sizes.entries
        .where((e) {
          final basename = e.key.split('/').last;
          if (Denylist.isSystemCachePath(basename)) return false;
          if (target.id == 'app_caches' && _devCacheNames.contains(basename)) {
            return false;
          }
          if (target.keepChildren.contains(basename)) return false;
          return e.value > 0;
        })
        .map(
          (e) => ScanItem(
            path: e.key,
            sizeBytes: e.value,
            safety: target.safety,
            selected: target.safety == SafetyLevel.safe,
          ),
        )
        .toList()
      ..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
  }

  Future<List<ScanItem>> _scanMatchingChildren(CleanupTarget target) async {
    final dir = Directory(target.absolutePath);
    if (!dir.existsSync()) return [];

    final children = dir
        .listSync(followLinks: false)
        .where((entity) {
          final name = entity.path.split('/').last;
          return target.includeChildSuffixes.any(name.endsWith);
        })
        .map((entity) => entity.path)
        .toList();
    if (children.isEmpty) return [];

    final sizes = await _du.sizeOfMultiple(children);
    return sizes.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => ScanItem(
            path: entry.key,
            sizeBytes: entry.value,
            safety: target.safety,
            selected: target.safety == SafetyLevel.safe,
          ),
        )
        .toList()
      ..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
  }

  Future<List<ScanItem>> _scanMatchingFiles(CleanupTarget target) async {
    final dir = Directory(target.absolutePath);
    if (!dir.existsSync()) return [];

    final paths = <String>[];
    try {
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;
        final name = entity.path.split('/').last;
        final dot = name.lastIndexOf('.');
        if (dot < 0) continue;
        final extension = name.substring(dot + 1).toLowerCase();
        if (target.includeExtensions.contains(extension)) {
          paths.add(entity.path);
        }
      }
    } on FileSystemException {
      // Return the readable candidates when a protected subdirectory is hit.
    }
    if (paths.isEmpty) return [];

    final sizes = <String, int>{};
    for (var start = 0; start < paths.length; start += 100) {
      final end = (start + 100).clamp(0, paths.length).toInt();
      sizes.addAll(await _du.sizeOfMultiple(paths.sublist(start, end)));
    }

    return sizes.entries
        .where((entry) => entry.value >= target.minimumSizeBytes)
        .map(
          (entry) => ScanItem(
            path: entry.key,
            sizeBytes: entry.value,
            safety: target.safety,
            selected: target.safety == SafetyLevel.safe,
          ),
        )
        .toList()
      ..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
  }

  Future<List<ScanItem>> _scanSimulators() async {
    final devices = await _simctl.listDevices();
    return devices
        .where((d) => d.sizeBytes > 0)
        .map(
          (d) => ScanItem(
            path: d.udid,
            sizeBytes: d.sizeBytes,
            safety: SafetyLevel.caution,
            displayName: d.name,
            detail:
                '${d.runtime} · ${d.lastBootedAt == null ? 'never booted' : 'last used ${_formatDate(d.lastBootedAt!)}'}',
            actionId: d.udid,
            selected: false, // default unselected for simulators
          ),
        )
        .toList()
      ..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
  }

  Future<List<ScanItem>> _scanRuntimes() async {
    final runtimes = await _simctl.listRuntimes();
    return runtimes
        .where((runtime) => runtime.deletable && runtime.sizeBytes > 0)
        .map(
          (runtime) => ScanItem(
            path: runtime.path,
            sizeBytes: runtime.sizeBytes,
            safety: SafetyLevel.caution,
            displayName: runtime.displayName,
            detail:
                'Build ${runtime.build}${runtime.lastUsedAt == null ? '' : ' · last used ${_formatDate(runtime.lastUsedAt!)}'}',
            actionId: runtime.identifier,
            selected: false,
          ),
        )
        .toList()
      ..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
  }

  Future<List<ScanItem>> _scanRuntimeCaches(CleanupTarget target) async {
    final root = Directory(target.absolutePath);
    if (!root.existsSync()) return [];

    final runtimes = await _simctl.listRuntimes();
    final cacheDirs = <String>[];
    for (final hostDir
        in root.listSync(followLinks: false).whereType<Directory>()) {
      cacheDirs.addAll(
        hostDir
            .listSync(followLinks: false)
            .whereType<Directory>()
            .map((directory) => directory.path),
      );
    }

    final items = <ScanItem>[];
    for (final runtime in runtimes) {
      final matches = cacheDirs.where((path) {
        final name = path.split('/').last;
        return name == runtime.runtimeIdentifier ||
            name.startsWith('${runtime.runtimeIdentifier}.');
      }).toList();
      if (matches.isEmpty) continue;

      final sizes = await _du.sizeOfMultiple(matches);
      final total = sizes.values.fold<int>(0, (sum, size) => sum + size);
      if (total == 0) continue;

      items.add(
        ScanItem(
          path: matches.first,
          sizeBytes: total,
          safety: SafetyLevel.caution,
          displayName: '${runtime.displayName} dyld cache',
          detail: 'Generated runtime cache · rebuilt automatically',
          actionId: runtime.runtimeIdentifier,
          selected: false,
        ),
      );
    }

    return items..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)}';
  }

  Future<List<SimulatorDevice>> listSimulators() => _simctl.listDevices();
}
