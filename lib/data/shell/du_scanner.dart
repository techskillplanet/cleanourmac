import 'dart:io';
import 'shell_runner.dart';

class DuResult {
  final String path;
  final int kb;
  DuResult(this.path, this.kb);
}

class DuScanner {
  final ShellRunner _runner;
  DuScanner(this._runner);

  // Returns size in bytes for a single path.
  Future<int> sizeOf(String path) async {
    if (!await _exists(path)) return 0;
    final result = await _runner.run('du', ['-sk', path]);
    return _parseFirst(result.stdout);
  }

  // Returns a map of path -> sizeBytes for multiple paths at once.
  Future<Map<String, int>> sizeOfMultiple(List<String> paths) async {
    final existing = <String>[];
    for (final path in paths) {
      if (await _exists(path)) existing.add(path);
    }
    if (existing.isEmpty) return {};

    final result = await _runner.run('du', ['-sk', ...existing]);
    return _parseAll(result.stdout);
  }

  // Returns child entries with their sizes (for contentsOnly targets).
  Future<List<DuResult>> childSizes(
    String dirPath, {
    Set<String> skip = const {},
  }) async {
    final dir = Directory(dirPath);
    if (!await _directoryExists(dir)) return [];

    final children = (await _listDirectory(dir))
        .where((e) => !skip.contains(e.uri.pathSegments.last))
        .map((e) => e.path)
        .toList();
    if (children.isEmpty) return [];

    final result = await _runner.run('du', ['-sk', ...children]);
    return _parseAll(
      result.stdout,
    ).entries.map((e) => DuResult(e.key, e.value ~/ 1024)).toList();
  }

  Future<bool> _exists(String path) async {
    if (await _directoryExists(Directory(path))) return true;
    try {
      return await File(path).exists().timeout(const Duration(seconds: 2));
    } catch (_) {
      return false;
    }
  }

  Future<bool> _directoryExists(Directory directory) async {
    try {
      return await directory.exists().timeout(const Duration(seconds: 2));
    } catch (_) {
      return false;
    }
  }

  Future<List<FileSystemEntity>> _listDirectory(Directory directory) async {
    try {
      return await directory
          .list(followLinks: false)
          .timeout(const Duration(seconds: 3))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  int _parseFirst(String stdout) {
    final line = stdout.trim().split('\n').first.trim();
    if (line.isEmpty) return 0;
    final kb = int.tryParse(line.split('\t').first.trim()) ?? 0;
    return kb * 1024;
  }

  Map<String, int> _parseAll(String stdout) {
    final result = <String, int>{};
    for (final line in stdout.trim().split('\n')) {
      final parts = line.trim().split('\t');
      if (parts.length < 2) continue;
      final kb = int.tryParse(parts[0].trim()) ?? 0;
      final path = parts.sublist(1).join('\t').trim();
      if (path.isNotEmpty) result[path] = kb * 1024;
    }
    return result;
  }
}
