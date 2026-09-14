import 'dart:io';

import '../../domain/models/ai_agent_cache.dart';
import '../registry/ai_agent_cache_registry.dart';
import '../safety/path_guard.dart';
import '../shell/du_scanner.dart';

class AiAgentCacheRepository {
  final String _home;
  final DuScanner _du;
  final PathGuard _guard;

  AiAgentCacheRepository(this._home, this._du, this._guard);

  Future<List<AiAgentCacheItem>> scan() async {
    final targets = <AiAgentCacheTarget>[];
    for (final target in AiAgentCacheRegistry.build(_home)) {
      try {
        if (await Directory(
          target.path,
        ).exists().timeout(const Duration(seconds: 2))) {
          targets.add(target);
        }
      } catch (_) {
        // Ignore unavailable cache roots, including disconnected volumes.
      }
    }
    if (targets.isEmpty) return const [];

    final sizes = await _du.sizeOfMultiple(
      targets.map((target) => target.path).toList(),
    );
    return targets
        .map(
          (target) => AiAgentCacheItem(
            target: target,
            sizeBytes: sizes[target.path] ?? 0,
          ),
        )
        .where((item) => item.sizeBytes > 0)
        .toList()
      ..sort((a, b) {
        final agentOrder = a.target.agent.index.compareTo(b.target.agent.index);
        return agentOrder != 0
            ? agentOrder
            : b.sizeBytes.compareTo(a.sizeBytes);
      });
  }

  List<AiAgentCacheItem> dryRun(List<AiAgentCacheItem> items) {
    return items
        .where(
          (item) =>
              item.selected &&
              _guard.isSafe(item.target.path, approvedRoot: item.target.path),
        )
        .toList();
  }

  Future<AiAgentCleanupResult> clean(List<AiAgentCacheItem> items) async {
    final approved = dryRun(items);
    var count = 0;
    var reclaimed = 0;

    for (final item in approved) {
      try {
        _guard.assertDeletable(
          item.target.path,
          approvedRoot: item.target.path,
        );
        await _clearDirectory(Directory(item.target.path));
        count++;
        reclaimed += item.sizeBytes;
      } catch (_) {
        // A locked or changed cache is skipped without aborting the batch.
      }
    }

    return AiAgentCleanupResult(cleanedCount: count, reclaimedBytes: reclaimed);
  }

  Future<void> _clearDirectory(Directory directory) async {
    if (!directory.existsSync()) return;
    await for (final entity in directory.list(followLinks: false)) {
      final type = FileSystemEntity.typeSync(entity.path, followLinks: false);
      switch (type) {
        case FileSystemEntityType.directory:
          await Directory(entity.path).delete(recursive: true);
        case FileSystemEntityType.file:
          await File(entity.path).delete();
        case FileSystemEntityType.link:
          await Link(entity.path).delete();
        case FileSystemEntityType.notFound:
          break;
        case FileSystemEntityType.pipe:
        case FileSystemEntityType.unixDomainSock:
          await File(entity.path).delete();
      }
    }
  }
}
