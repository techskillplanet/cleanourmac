import 'dart:async';
import 'dart:io';
import '../../domain/models/android_emulator.dart';
import 'shell_runner.dart';

String? parseAvdNameOutput(String stdout) {
  for (final rawLine in stdout.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.isEmpty || line == 'OK' || line.startsWith('KO:')) continue;
    return line;
  }
  return null;
}

class AndroidEmulatorClient {
  final ShellRunner _runner;

  AndroidEmulatorClient(this._runner);

  String? get _sdkRoot {
    final env = Platform.environment;
    if (env['ANDROID_HOME']?.isNotEmpty == true) {
      return env['ANDROID_HOME'];
    }
    if (env['ANDROID_SDK_ROOT']?.isNotEmpty == true) {
      return env['ANDROID_SDK_ROOT'];
    }
    final home = env['HOME'];
    if (home != null && Directory('$home/Library/Android/sdk').existsSync()) {
      return '$home/Library/Android/sdk';
    }
    return null;
  }

  String? get _avdHome {
    final env = Platform.environment;
    if (env['ANDROID_AVD_HOME']?.isNotEmpty == true) {
      return env['ANDROID_AVD_HOME'];
    }
    final home = env['HOME'];
    if (home != null && Directory('$home/.android/avd').existsSync()) {
      return '$home/.android/avd';
    }
    return null;
  }

  // Returns the emulator binary path if an Android SDK is available.
  String? emulatorBinary() {
    final root = _sdkRoot;
    if (root == null) return null;
    final candidate = '$root/emulator/emulator';
    return File(candidate).existsSync() ? candidate : null;
  }

  String? adbBinary() {
    final root = _sdkRoot;
    if (root == null) return null;
    final candidate = '$root/platform-tools/adb';
    return File(candidate).existsSync() ? candidate : null;
  }

  bool get isAvailable => emulatorBinary() != null;

  // Lists AVD names via `emulator -list-avds`.
  Future<List<String>> listAvdNames() async {
    final emulator = emulatorBinary();
    if (emulator == null) return const [];
    final result = await _runner.run(emulator, ['-list-avds']);
    if (result.exitCode != 0) return const [];
    return result.stdout
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  // Returns a map of adb serial -> state ("device", "offline", etc).
  Future<Map<String, String>> adbDevices() async {
    final adb = adbBinary();
    if (adb == null) return const {};
    final result = await _runner.run(adb, ['devices']);
    final map = <String, String>{};
    final lines = result.stdout.split('\n');
    for (final line in lines.skip(1)) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[0].isNotEmpty) {
        map[parts[0]] = parts[1];
      }
    }
    return map;
  }

  // Resolves which AVD name each running emulator serial maps to.
  Future<Map<String, String>> _serialToAvd() async {
    final adb = adbBinary();
    if (adb == null) return const {};
    final serials = await adbDevices();
    final result = <String, String>{};
    for (final serial
        in serials.entries
            .where(
              (entry) =>
                  entry.key.startsWith('emulator-') && entry.value == 'device',
            )
            .map((entry) => entry.key)) {
      final r = await _runner.run(adb, ['-s', serial, 'emu', 'avd', 'name']);
      final name = parseAvdNameOutput(r.stdout);
      if (name != null) result[serial] = name;
    }
    return result;
  }

  // Parses the AVD's config.ini for display metadata.
  AndroidEmulator _avdFromConfig(String name) {
    final avdHome = _avdHome;
    if (avdHome == null) return AndroidEmulator(name: name, device: name);
    final configFile = File('$avdHome/$name.avd/config.ini');
    if (!configFile.existsSync()) {
      return AndroidEmulator(name: name, device: name);
    }

    final props = <String, String>{};
    for (final line in configFile.readAsLinesSync()) {
      final idx = line.indexOf('=');
      if (idx <= 0) continue;
      props[line.substring(0, idx).trim()] = line.substring(idx + 1).trim();
    }

    final device = props['hw.device.name'] ?? name;
    final sysdir = props['image.sysdir.1'] ?? '';
    final apiMatch = RegExp(r'android-(\d+)').firstMatch(sysdir);
    final target = apiMatch != null
        ? 'API ${apiMatch.group(1)}'
        : (props['image.androidVersion.api_level'] != null
              ? 'API ${props['image.androidVersion.api_level']}'
              : null);
    final abi = props['abi.type'] ?? _abiFromSysdir(sysdir);

    return AndroidEmulator(
      name: name,
      device: device,
      target: target,
      abi: abi,
    );
  }

  String? _abiFromSysdir(String sysdir) {
    final parts = sysdir.split('/').where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.last;
  }

  // Combines AVDs with their current adb running state.
  Future<List<AndroidEmulator>> list() async {
    final avdNames = await listAvdNames();
    if (avdNames.isEmpty) return const [];
    final serialToAvd = await _serialToAvd();
    final serialByName = <String, String>{};
    for (final entry in serialToAvd.entries) {
      serialByName[entry.value] = entry.key;
    }

    return avdNames.map((name) {
      final emu = _avdFromConfig(name);
      final serial = serialByName[name];
      return emu.copyWith(isRunning: serial != null, serial: serial);
    }).toList();
  }

  // Launches detached, then waits until adb can map the serial back to the AVD.
  Future<void> boot(String avdName) async {
    final emulator = emulatorBinary();
    if (emulator == null) throw StateError('Android SDK not found');

    if ((await _serialToAvd()).containsValue(avdName)) return;

    await Process.start(emulator, [
      '-avd',
      avdName,
      '-no-boot-anim',
    ], mode: ProcessStartMode.detached);

    final deadline = DateTime.now().add(const Duration(seconds: 90));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if ((await _serialToAvd()).containsValue(avdName)) return;
    }
    throw TimeoutException('Timed out waiting for $avdName to start');
  }

  Future<void> shutdown(String serial) async {
    final adb = adbBinary();
    if (adb == null) return;
    final result = await _runner.run(adb, ['-s', serial, 'emu', 'kill']);
    if (result.exitCode != 0) {
      throw StateError(
        result.stderr.trim().isEmpty
            ? 'Failed to stop $serial'
            : result.stderr.trim(),
      );
    }

    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!(await adbDevices()).containsKey(serial)) return;
    }
    throw TimeoutException('Timed out waiting for $serial to stop');
  }

  // RN helper: open the React Native dev menu (keyevent 82 = MENU).
  Future<void> openDevMenu(String serial) async {
    final adb = adbBinary();
    if (adb == null) return;
    await _runner.run(adb, ['-s', serial, 'shell', 'input', 'keyevent', '82']);
  }

  // RN helper: reload the JS bundle.
  Future<void> reloadJs(String serial) async {
    final adb = adbBinary();
    if (adb == null) return;
    await _runner.run(adb, ['-s', serial, 'shell', 'input', 'text', 'RR']);
  }

  String? avdManagerBinary() {
    final root = _sdkRoot;
    if (root == null) return null;
    final candidates = [
      '$root/cmdline-tools/latest/bin/avdmanager',
      '$root/tools/bin/avdmanager',
    ];
    // Also pick the newest cmdline-tools/<version>/bin/avdmanager if present.
    final cmdTools = Directory('$root/cmdline-tools');
    if (cmdTools.existsSync()) {
      for (final entity in cmdTools.listSync().whereType<Directory>()) {
        final bin = '${entity.path}/bin/avdmanager';
        if (File(bin).existsSync()) candidates.insert(0, bin);
      }
    }
    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  // Deletes an AVD. Prefer avdmanager; fall back to removing ini + .avd folder.
  Future<void> delete(String avdName) async {
    final manager = avdManagerBinary();
    if (manager != null) {
      final result = await _runner.run(manager, [
        'delete',
        'avd',
        '-n',
        avdName,
      ]);
      if (result.exitCode == 0) return;
    }

    final avdHome = _avdHome;
    if (avdHome == null) throw StateError('AVD home not found');
    final ini = File('$avdHome/$avdName.ini');
    final dir = Directory('$avdHome/$avdName.avd');
    if (ini.existsSync()) await ini.delete();
    if (dir.existsSync()) await dir.delete(recursive: true);
  }
}
