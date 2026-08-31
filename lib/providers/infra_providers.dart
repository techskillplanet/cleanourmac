import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/shell/shell_runner.dart';
import '../data/shell/du_scanner.dart';
import '../data/shell/df_client.dart';
import '../data/shell/simctl_client.dart';
import '../data/shell/find_scanner.dart';
import '../data/shell/tcc_probe.dart';
import '../data/shell/android_emulator_client.dart';
import '../data/shell/node_modules_scanner.dart';
import '../data/repositories/node_modules_repository.dart';
import '../data/repositories/android_emulator_repository.dart';
import '../data/safety/path_guard.dart';
import '../data/repositories/scan_repository.dart';
import '../data/repositories/clean_repository.dart';
import '../data/repositories/simulator_repository.dart';
import '../data/repositories/settings_repository.dart';

final homeProvider = Provider<String>((_) => Platform.environment['HOME']!);

final shellRunnerProvider = Provider<ShellRunner>((_) => ShellRunner());

final duScannerProvider = Provider<DuScanner>(
  (ref) => DuScanner(ref.watch(shellRunnerProvider)),
);

final dfClientProvider = Provider<DfClient>(
  (ref) => DfClient(ref.watch(shellRunnerProvider)),
);

final simctlClientProvider = Provider<SimctlClient>(
  (ref) => SimctlClient(ref.watch(shellRunnerProvider)),
);

final findScannerProvider = Provider<FindScanner>(
  (ref) => FindScanner(ref.watch(shellRunnerProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>((_) => SettingsRepository());

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(ref.watch(settingsRepositoryProvider)),
);

final pathGuardProvider = Provider<PathGuard>((ref) => PathGuard(
      home: ref.watch(homeProvider),
      userExclusions: ref.watch(settingsProvider).excludedPaths,
    ));

final scanRepositoryProvider = Provider<ScanRepository>((ref) => ScanRepository(
      ref.watch(duScannerProvider),
      ref.watch(dfClientProvider),
      ref.watch(simctlClientProvider),
    ));

final cleanRepositoryProvider = Provider<CleanRepository>((ref) => CleanRepository(
      ref.watch(pathGuardProvider),
      ref.watch(simctlClientProvider),
    ));

final simulatorRepositoryProvider = Provider<SimulatorRepository>(
  (ref) => SimulatorRepository(ref.watch(simctlClientProvider)),
);

final fullDiskAccessProvider = FutureProvider<bool>(
  (_) => TccProbe.hasFullDiskAccess(),
);

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repo;

  SettingsNotifier(this._repo) : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    state = await _repo.load();
  }

  Future<void> update(AppSettings settings) async {
    state = settings;
    await _repo.save(settings);
  }
}

final androidEmulatorClientProvider = Provider<AndroidEmulatorClient>(
  (ref) => AndroidEmulatorClient(ref.watch(shellRunnerProvider)),
);

final androidEmulatorRepositoryProvider = Provider<AndroidEmulatorRepository>(
  (ref) => AndroidEmulatorRepository(ref.watch(androidEmulatorClientProvider)),
);

final nodeModulesScannerProvider = Provider<NodeModulesScanner>(
  (ref) => NodeModulesScanner(ref.watch(shellRunnerProvider)),
);

final nodeModulesRepositoryProvider = Provider<NodeModulesRepository>(
  (ref) => NodeModulesRepository(
    ref.watch(nodeModulesScannerProvider),
    ref.watch(pathGuardProvider),
  ),
);
