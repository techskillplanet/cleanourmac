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
      'npm_cache' ||
      'node_gyp' => Icons.code,
      'cocoapods' || 'pip_cache' || 'homebrew' || 'playwright' => Icons.science,
      'xcode_derived' ||
      'xcode_archives' ||
      'android_studio_backups' => Icons.build,
      'ios_simulators' => Icons.phone_iphone,
      'ios_runtimes' || 'ios_runtime_caches' => Icons.developer_mode,
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
