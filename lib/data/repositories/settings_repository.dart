import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final int largeFileThresholdMB;
  final int simulatorStaleDays;
  final List<String> excludedPaths;
  final List<String> nodeModulesRoots;
  final bool lruEnabled;

  const AppSettings({
    this.largeFileThresholdMB = 100,
    this.simulatorStaleDays = 30,
    this.excludedPaths = const [],
    this.nodeModulesRoots = const [],
    this.lruEnabled = true,
  });

  AppSettings copyWith({
    int? largeFileThresholdMB,
    int? simulatorStaleDays,
    List<String>? excludedPaths,
    List<String>? nodeModulesRoots,
    bool? lruEnabled,
  }) =>
      AppSettings(
        largeFileThresholdMB: largeFileThresholdMB ?? this.largeFileThresholdMB,
        simulatorStaleDays: simulatorStaleDays ?? this.simulatorStaleDays,
        excludedPaths: excludedPaths ?? this.excludedPaths,
        nodeModulesRoots: nodeModulesRoots ?? this.nodeModulesRoots,
        lruEnabled: lruEnabled ?? this.lruEnabled,
      );
}

class SettingsRepository {
  static const _keyLargeFile = 'large_file_mb';
  static const _keySimDays = 'sim_stale_days';
  static const _keyExcluded = 'excluded_paths';
  static const _keyNodeRoots = 'node_modules_roots';
  static const _keyLru = 'node_modules_lru';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      largeFileThresholdMB: prefs.getInt(_keyLargeFile) ?? 100,
      simulatorStaleDays: prefs.getInt(_keySimDays) ?? 30,
      excludedPaths: prefs.getStringList(_keyExcluded) ?? [],
      nodeModulesRoots: prefs.getStringList(_keyNodeRoots) ?? [],
      lruEnabled: prefs.getBool(_keyLru) ?? true,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLargeFile, settings.largeFileThresholdMB);
    await prefs.setInt(_keySimDays, settings.simulatorStaleDays);
    await prefs.setStringList(_keyExcluded, settings.excludedPaths);
    await prefs.setStringList(_keyNodeRoots, settings.nodeModulesRoots);
    await prefs.setBool(_keyLru, settings.lruEnabled);
  }
}
