import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import '../../domain/models/project_cache.dart';
import '../shell/du_scanner.dart';
import '../shell/shell_escape.dart';
import '../shell/shell_runner.dart';

class _ProjectDescriptor {
  final String name;
  final String root;
  final Set<ProjectCacheEcosystem> ecosystems;

  const _ProjectDescriptor({
    required this.name,
    required this.root,
    required this.ecosystems,
  });
}

class _ProjectCacheCandidate {
  final String projectName;
  final String projectRoot;
  final String path;
  final ProjectCacheEcosystem ecosystem;
  final ProjectCacheKind kind;

  const _ProjectCacheCandidate({
    required this.projectName,
    required this.projectRoot,
    required this.path,
    required this.ecosystem,
    required this.kind,
  });
}

class ProjectCacheRepository {
  final String _home;
  final DuScanner _du;
  final ShellRunner _runner;
  final List<String> excludedPaths;
  final List<String>? _searchRootsOverride;

  ProjectCacheRepository(
    this._home,
    this._du,
    this._runner, {
    this.excludedPaths = const [],
    List<String>? searchRoots,
  }) : _searchRootsOverride = searchRoots;

  Future<List<ProjectCacheItem>> scan(List<String> configuredRoots) async {
    final home = _home;
    final exclusions = List<String>.from(excludedPaths);
    final searchRoots = _searchRootsOverride;
    final override = searchRoots == null
        ? null
        : List<String>.from(searchRoots);
    final candidates = await Isolate.run(
      () => _discoverCandidates(home, configuredRoots, exclusions, override),
    );
    if (candidates.isEmpty) return const [];

    final sizes = await _du.sizeOfMultiple(
      candidates.map((candidate) => candidate.path).toList(),
    );
    return candidates
        .map(
          (candidate) => ProjectCacheItem(
            id: candidate.path,
            projectName: candidate.projectName,
            projectRoot: candidate.projectRoot,
            path: candidate.path,
            ecosystem: candidate.ecosystem,
            kind: candidate.kind,
            sizeBytes: sizes[candidate.path] ?? 0,
          ),
        )
        .where((item) => item.sizeBytes > 0)
        .toList()
      ..sort((a, b) {
        final projectOrder = a.projectName.compareTo(b.projectName);
        return projectOrder != 0
            ? projectOrder
            : b.sizeBytes.compareTo(a.sizeBytes);
      });
  }

  Future<String?> chooseRoot(String prompt) async {
    final script =
        'set selectedFolder to choose folder with prompt '
        '${appleScriptStringLiteral(prompt)}\n'
        'return POSIX path of selectedFolder';
    final result = await _runner.run('/usr/bin/osascript', ['-e', script]);
    if (result.exitCode != 0) {
      final error = result.stderr.trim();
      if (error.contains('User canceled') || error.contains('-128')) {
        return null;
      }
      throw StateError(error.isEmpty ? 'Failed to choose folder' : error);
    }
    final path = result.stdout.trim();
    return path.isEmpty ? null : path;
  }

  Future<ProjectCacheCleanupResult> clean(List<ProjectCacheItem> items) async {
    var cleaned = 0;
    var reclaimed = 0;
    for (final item in items.where((item) => item.selected)) {
      if (!_isAllowedItem(item) ||
          _isExcluded(item.path) ||
          !await _hasProjectManifest(item.projectRoot)) {
        continue;
      }
      try {
        final type = await FileSystemEntity.type(item.path, followLinks: false);
        if (type != FileSystemEntityType.directory) continue;
        await Directory(item.path).delete(recursive: true);
        cleaned++;
        reclaimed += item.sizeBytes;
      } catch (_) {
        // Skip files that changed or became locked after scanning.
      }
    }
    return ProjectCacheCleanupResult(
      cleanedCount: cleaned,
      reclaimedBytes: reclaimed,
    );
  }

  Future<bool> _hasProjectManifest(String root) async {
    for (final name in const [
      'pubspec.yaml',
      'package.json',
      'settings.gradle',
      'settings.gradle.kts',
    ]) {
      try {
        if (await File('$root/$name').exists()) return true;
      } catch (_) {
        return false;
      }
    }
    try {
      await for (final entity in Directory(root).list(followLinks: false)) {
        if (entity is Directory &&
            (entity.path.endsWith('.xcodeproj') ||
                entity.path.endsWith('.xcworkspace'))) {
          return true;
        }
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  bool _isAllowedItem(ProjectCacheItem item) {
    final root = p.normalize(item.projectRoot);
    final path = p.normalize(item.path);
    if (!p.isWithin(root, path)) return false;
    final relative = p.relative(path, from: root);
    return _classifyCache(relative, item.ecosystem) != null;
  }

  bool _isExcluded(String path) {
    final normalized = p.normalize(path);
    return excludedPaths.any((excluded) {
      final root = p.normalize(excluded);
      return normalized == root || p.isWithin(root, normalized);
    });
  }
}

List<_ProjectCacheCandidate> _discoverCandidates(
  String home,
  List<String> configuredRoots,
  List<String> excludedPaths,
  List<String>? searchRootsOverride,
) {
  final searchRoots = <String>{
    ...configuredRoots,
    ...?searchRootsOverride,
    if (searchRootsOverride == null) ...[
      '$home/Projects',
      '$home/Developer',
      '$home/StudioProjects',
      ..._volumeCodeRoots(),
    ],
  }.where((root) => Directory(root).existsSync()).toList();

  final projects = <String, _ProjectDescriptor>{};
  for (final searchRoot in searchRoots) {
    _walk(
      Directory(searchRoot),
      maxDepth: 3,
      maxDirectories: 1800,
      onDirectory: (directory) {
        final descriptor = _detectProject(directory);
        if (descriptor != null) projects[descriptor.root] = descriptor;
      },
    );
  }

  final candidates = <String, _ProjectCacheCandidate>{};
  for (final project in projects.values) {
    _walk(
      Directory(project.root),
      maxDepth: 5,
      maxDirectories: 2200,
      includeNodeModulesCache: true,
      onDirectory: (directory) {
        if (directory.path == project.root) return;
        final relative = p.relative(directory.path, from: project.root);
        final classified = _classifyForEcosystems(relative, project.ecosystems);
        if (classified == null) return;
        if (_isPathExcluded(directory.path, excludedPaths)) return;
        candidates[directory.path] = _ProjectCacheCandidate(
          projectName: project.name,
          projectRoot: project.root,
          path: directory.path,
          ecosystem: classified.$1,
          kind: classified.$2,
        );
      },
    );
  }
  return candidates.values.toList();
}

_ProjectDescriptor? _detectProject(Directory directory) {
  final path = directory.path;
  if (_isIgnoredProjectPath(path)) return null;
  final ecosystems = <ProjectCacheEcosystem>{};
  var name = path.split('/').last;

  final pubspec = File('$path/pubspec.yaml');
  if (pubspec.existsSync()) {
    final text = _readSmallFile(pubspec);
    if (RegExp(r'^\s*flutter\s*:', multiLine: true).hasMatch(text)) {
      ecosystems.add(ProjectCacheEcosystem.flutter);
      final match = RegExp(
        r'^name\s*:\s*([^\s#]+)',
        multiLine: true,
      ).firstMatch(text);
      if (match != null) name = match.group(1)!;
    }
  }

  final package = File('$path/package.json');
  if (package.existsSync()) {
    try {
      final data = jsonDecode(_readSmallFile(package)) as Map<String, dynamic>;
      name = (data['name'] as String?) ?? name;
      final dependencies = <String, dynamic>{
        ...?data['dependencies'] as Map<String, dynamic>?,
        ...?data['devDependencies'] as Map<String, dynamic>?,
      };
      ecosystems.add(
        dependencies.containsKey('react-native')
            ? ProjectCacheEcosystem.reactNative
            : ProjectCacheEcosystem.web,
      );
    } catch (_) {
      ecosystems.add(ProjectCacheEcosystem.web);
    }
  }

  if (File('$path/settings.gradle').existsSync() ||
      File('$path/settings.gradle.kts').existsSync()) {
    ecosystems.add(ProjectCacheEcosystem.android);
  }
  try {
    if (directory
        .listSync(followLinks: false)
        .whereType<Directory>()
        .any(
          (child) =>
              child.path.endsWith('.xcodeproj') ||
              child.path.endsWith('.xcworkspace'),
        )) {
      ecosystems.add(ProjectCacheEcosystem.ios);
    }
  } catch (_) {
    // Ignore unreadable folders.
  }

  if (ecosystems.isEmpty) return null;
  return _ProjectDescriptor(name: name, root: path, ecosystems: ecosystems);
}

(ProjectCacheEcosystem, ProjectCacheKind)? _classifyForEcosystems(
  String relative,
  Set<ProjectCacheEcosystem> ecosystems,
) {
  const order = [
    ProjectCacheEcosystem.flutter,
    ProjectCacheEcosystem.reactNative,
    ProjectCacheEcosystem.web,
    ProjectCacheEcosystem.android,
    ProjectCacheEcosystem.ios,
  ];
  for (final ecosystem in order) {
    if (!ecosystems.contains(ecosystem)) continue;
    final kind = _classifyCache(relative, ecosystem);
    if (kind != null) return (ecosystem, kind);
  }
  return null;
}

ProjectCacheKind? _classifyCache(
  String relative,
  ProjectCacheEcosystem ecosystem,
) {
  final path = relative.replaceAll('\\', '/');
  final basename = p.basename(path);

  if (basename == '.dart_tool' && ecosystem == ProjectCacheEcosystem.flutter) {
    return ProjectCacheKind.toolState;
  }
  if (RegExp(r'(^|/)android/\.gradle$').hasMatch(path) ||
      (ecosystem == ProjectCacheEcosystem.android && path == '.gradle')) {
    return ProjectCacheKind.toolState;
  }
  if (RegExp(r'(^|/)android/(app/)?build$').hasMatch(path) ||
      (ecosystem == ProjectCacheEcosystem.android &&
          (path == 'build' || path == 'app/build'))) {
    return ProjectCacheKind.buildOutput;
  }
  if (RegExp(r'(^|/)ios/(Pods|build|\.symlinks)$').hasMatch(path) ||
      (ecosystem == ProjectCacheEcosystem.ios &&
          {'Pods', 'build', '.build'}.contains(path))) {
    return basename == 'Pods'
        ? ProjectCacheKind.dependencyArtifacts
        : ProjectCacheKind.buildOutput;
  }
  if (path == 'build' && ecosystem == ProjectCacheEcosystem.flutter) {
    return ProjectCacheKind.buildOutput;
  }
  if (path == 'node_modules/.cache' ||
      path == 'node_modules/.vite' ||
      path == '.next/cache' ||
      path == '.angular/cache' ||
      path == '.parcel-cache' ||
      path == '.turbo' ||
      path == '.vite' ||
      path == '.cache') {
    return ProjectCacheKind.bundlerCache;
  }
  if ({'.nuxt', '.svelte-kit'}.contains(path)) {
    return ProjectCacheKind.buildOutput;
  }
  if ({'coverage', '.nyc_output'}.contains(path)) {
    return ProjectCacheKind.testOutput;
  }
  if ({'dist', 'build'}.contains(path) &&
      ecosystem == ProjectCacheEcosystem.web) {
    return ProjectCacheKind.buildOutput;
  }
  return null;
}

void _walk(
  Directory root, {
  required int maxDepth,
  required int maxDirectories,
  required void Function(Directory directory) onDirectory,
  bool includeNodeModulesCache = false,
}) {
  var visited = 0;
  final deadline = DateTime.now().add(const Duration(seconds: 5));

  void visit(Directory directory, int depth) {
    if (depth > maxDepth ||
        visited >= maxDirectories ||
        DateTime.now().isAfter(deadline)) {
      return;
    }
    visited++;
    onDirectory(directory);
    try {
      for (final child
          in directory.listSync(followLinks: false).whereType<Directory>()) {
        final name = p.basename(child.path);
        if (name.startsWith('.git') ||
            name == 'Pods' ||
            name == 'build' ||
            name == 'dist') {
          onDirectory(child);
          continue;
        }
        if (name == 'node_modules') {
          if (includeNodeModulesCache) {
            for (final cacheName in const ['.cache', '.vite']) {
              final cache = Directory('${child.path}/$cacheName');
              if (cache.existsSync()) onDirectory(cache);
            }
          }
          continue;
        }
        visit(child, depth + 1);
      }
    } catch (_) {
      // Ignore unreadable or disconnected folders.
    }
  }

  visit(root, 0);
}

List<String> _volumeCodeRoots() {
  final roots = <String>[];
  try {
    for (final volume in Directory(
      '/Volumes',
    ).listSync().whereType<Directory>()) {
      final code = Directory('${volume.path}/code');
      if (code.existsSync()) roots.add(code.path);
    }
  } catch (_) {
    // Ignore unavailable volumes.
  }
  return roots;
}

String _readSmallFile(File file) {
  final bytes = file.readAsBytesSync();
  final limited = bytes.length > 1024 * 1024
      ? bytes.sublist(0, 1024 * 1024)
      : bytes;
  return utf8.decode(limited, allowMalformed: true);
}

bool _isIgnoredProjectPath(String path) {
  return path.contains('/node_modules/') ||
      path.contains('/.pub-cache/') ||
      path.contains('/flutter-sdk/') ||
      path.contains('/Pods/');
}

bool _isPathExcluded(String path, List<String> exclusions) {
  final normalized = p.normalize(path);
  return exclusions.any((excluded) {
    final root = p.normalize(excluded);
    return normalized == root || p.isWithin(root, normalized);
  });
}
