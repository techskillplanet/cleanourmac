import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final int largeFileThresholdMB;
  final int simulatorStaleDays;
  final List<String> excludedPaths;
  final List<String> nodeModulesRoots;
  final List<String> reactNativeRoots;
  final List<String> developmentRoots;
  final bool lruEnabled;
  final String localeCode;
  final int metroPort;

  const AppSettings({
    this.largeFileThresholdMB = 100,
    this.simulatorStaleDays = 30,
    this.excludedPaths = const [],
    this.nodeModulesRoots = const [],
    this.reactNativeRoots = const [],
    this.developmentRoots = const [],
    this.lruEnabled = true,
    this.localeCode = 'zh',
    this.metroPort = 8081,
  });

  AppSettings copyWith({
    int? largeFileThresholdMB,
    int? simulatorStaleDays,
    List<String>? excludedPaths,
    List<String>? nodeModulesRoots,
    List<String>? reactNativeRoots,
    List<String>? developmentRoots,
    bool? lruEnabled,
    String? localeCode,
    int? metroPort,
  }) => AppSettings(
    largeFileThresholdMB: largeFileThresholdMB ?? this.largeFileThresholdMB,
    simulatorStaleDays: simulatorStaleDays ?? this.simulatorStaleDays,
    excludedPaths: excludedPaths ?? this.excludedPaths,
    nodeModulesRoots: nodeModulesRoots ?? this.nodeModulesRoots,
    reactNativeRoots: reactNativeRoots ?? this.reactNativeRoots,
    developmentRoots: developmentRoots ?? this.developmentRoots,
    lruEnabled: lruEnabled ?? this.lruEnabled,
    localeCode: localeCode ?? this.localeCode,
    metroPort: metroPort ?? this.metroPort,
  );
}

class SettingsRepository {
  static const _keyLargeFile = 'large_file_mb';
  static const _keySimDays = 'sim_stale_days';
  static const _keyExcluded = 'excluded_paths';
  static const _keyNodeRoots = 'node_modules_roots';
  static const _keyReactNativeRoots = 'react_native_roots';
  static const _keyDevelopmentRoots = 'development_roots';
  static const _keyLru = 'node_modules_lru';
  static const _keyLocale = 'locale';
  static const _keyMetroPort = 'metro_port';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      largeFileThresholdMB: prefs.getInt(_keyLargeFile) ?? 100,
      simulatorStaleDays: prefs.getInt(_keySimDays) ?? 30,
      excludedPaths: prefs.getStringList(_keyExcluded) ?? [],
      nodeModulesRoots: prefs.getStringList(_keyNodeRoots) ?? [],
      reactNativeRoots: prefs.getStringList(_keyReactNativeRoots) ?? [],
      developmentRoots: prefs.getStringList(_keyDevelopmentRoots) ?? [],
      lruEnabled: prefs.getBool(_keyLru) ?? true,
      localeCode: prefs.getString(_keyLocale) ?? 'zh',
      metroPort: prefs.getInt(_keyMetroPort) ?? 8081,
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLargeFile, settings.largeFileThresholdMB);
    await prefs.setInt(_keySimDays, settings.simulatorStaleDays);
    await prefs.setStringList(_keyExcluded, settings.excludedPaths);
    await prefs.setStringList(_keyNodeRoots, settings.nodeModulesRoots);
    await prefs.setStringList(_keyReactNativeRoots, settings.reactNativeRoots);
    await prefs.setStringList(_keyDevelopmentRoots, settings.developmentRoots);
    await prefs.setBool(_keyLru, settings.lruEnabled);
    await prefs.setString(_keyLocale, settings.localeCode);
    await prefs.setInt(_keyMetroPort, settings.metroPort);
  }
}
