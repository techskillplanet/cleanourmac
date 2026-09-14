import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/data/registry/cleanup_registry.dart';
import 'package:mac_tool/domain/models/cleanup_target.dart';

void main() {
  test('covers common cross-platform development caches', () {
    final targets = CleanupRegistry.build();
    final byId = {for (final target in targets) target.id: target};

    expect(
      byId.keys,
      containsAll({
        'gradle_caches',
        'android_cli_cache',
        'android_studio_cache',
        'dart_pub_hosted',
        'dart_pub_git',
        'cocoapods',
        'swiftpm_cache',
        'swiftpm_repositories',
        'xcode_derived',
        'xcode_device_support',
        'npm_cache',
        'yarn_cache',
        'yarn_xdg_cache',
        'pnpm_store',
        'pnpm_legacy_store',
        'bun_cache',
        'corepack_cache',
        'playwright',
        'cypress',
        'deno_cache',
      }),
    );
    expect(
      byId['android_studio_cache']!.strategy,
      ScanStrategy.duMatchingChildren,
    );
    expect(
      byId['android_studio_cache']!.includeChildPrefixes,
      contains('AndroidStudio'),
    );
    expect(targets.map((target) => target.id).toSet().length, targets.length);
  });
}
