import 'dart:io';
import 'package:path/path.dart' as p;
import 'denylist.dart';

class UnsafePathException implements Exception {
  final String path;
  final String reason;
  UnsafePathException(this.path, this.reason);

  @override
  String toString() => 'UnsafePathException: "$path" — $reason';
}

class PathGuard {
  final String home;
  final List<String> userExclusions;

  PathGuard({required this.home, this.userExclusions = const []});

  void assertDeletable(String rawPath, {String? approvedRoot}) {
    final resolved = _resolve(rawPath);

    // Must be inside home
    if (resolved != home && !p.isWithin(home, resolved)) {
      throw UnsafePathException(resolved, 'outside home directory');
    }

    // Must not be home itself or a top-level home directory
    final rel = p.relative(resolved, from: home);
    final parts = p.split(rel);
    if (parts.length < 2) {
      throw UnsafePathException(resolved, 'too close to home root (depth < 2)');
    }

    // User exclusions always win, including for registry-approved locations.
    for (final excluded in userExclusions) {
      final normalized = p.normalize(excluded);
      if (resolved == normalized || p.isWithin(normalized, resolved)) {
        throw UnsafePathException(resolved, 'in user exclusions: $normalized');
      }
    }

    // Some narrowly scoped registry targets live below Application Support.
    // Allow only the approved root itself or one of its descendants.
    if (approvedRoot != null) {
      final resolvedRoot = _resolve(approvedRoot);
      final rootInsideHome =
          resolvedRoot != home && p.isWithin(home, resolvedRoot);
      final itemInsideRoot =
          resolved == resolvedRoot || p.isWithin(resolvedRoot, resolved);
      if (rootInsideHome && itemInsideRoot) return;
    }

    // Check the permanent denylist.
    for (final deniedPath in Denylist.build(home)) {
      final normalized = p.normalize(deniedPath);
      if (resolved == normalized || p.isWithin(normalized, resolved)) {
        throw UnsafePathException(resolved, 'in denylist: $normalized');
      }
    }
  }

  String _resolve(String rawPath) {
    try {
      return File(rawPath).resolveSymbolicLinksSync();
    } catch (_) {
      return p.normalize(rawPath);
    }
  }

  bool isSafe(String rawPath, {String? approvedRoot}) {
    try {
      assertDeletable(rawPath, approvedRoot: approvedRoot);
      return true;
    } catch (_) {
      return false;
    }
  }
}
