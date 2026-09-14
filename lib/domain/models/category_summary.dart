import 'package:flutter/material.dart';
import 'cleanup_target.dart';
import 'scan_item.dart';

class CategorySummary {
  final CleanupTarget target;
  final List<ScanItem> items;
  final bool scanning;
  final String? error;

  const CategorySummary({
    required this.target,
    this.items = const [],
    this.scanning = false,
    this.error,
  });

  int get totalBytes => items.fold(0, (s, i) => s + i.sizeBytes);
  int get selectedBytes =>
      items.where((i) => i.selected).fold(0, (s, i) => s + i.sizeBytes);
  bool get allSelected => items.isNotEmpty && items.every((i) => i.selected);

  CategorySummary copyWith({
    List<ScanItem>? items,
    bool? scanning,
    String? error,
  }) => CategorySummary(
    target: target,
    items: items ?? this.items,
    scanning: scanning ?? this.scanning,
    error: error ?? this.error,
  );

  static IconData iconFor(String id) {
    return switch (id) {
      'gradle_caches' ||
      'gradle_wrapper' ||
      'android_cli_cache' ||
      'android_studio_cache' ||
      'dart_pub_hosted' ||
      'dart_pub_git' ||
      'npm_cache' ||
      'yarn_cache' ||
      'yarn_xdg_cache' ||
      'pnpm_store' ||
      'pnpm_legacy_store' ||
      'bun_cache' ||
      'corepack_cache' ||
      'deno_cache' ||
      'node_gyp' => Icons.code,
      'cocoapods' ||
      'swiftpm_cache' ||
      'swiftpm_repositories' ||
      'carthage_cache' ||
      'pip_cache' ||
      'homebrew' => Icons.science,
      'playwright' || 'cypress' => Icons.web_asset,
      'xcode_derived' ||
      'xcode_archives' ||
      'android_studio_backups' => Icons.build,
      'ios_simulators' => Icons.phone_iphone,
      'ios_runtimes' || 'ios_runtime_caches' => Icons.developer_mode,
      'xcode_device_support' => Icons.phonelink_setup,
      'app_caches' => Icons.folder_open,
      'qq_updates' ||
      'app_support_caches' ||
      'google_updater_cache' => Icons.system_update_alt,
      'chrome_models' => Icons.memory,
      'download_archives' => Icons.download_done,
      'konan_runtimes' ||
      'codex_runtimes' ||
      'lldb_cache' ||
      'codex_temp' => Icons.code,
      'app_logs' => Icons.description,
      _ => Icons.cleaning_services,
    };
  }
}
