import 'dart:convert';
import 'dart:io';
import '../../domain/models/simulator_device.dart';
import '../../domain/models/simulator_runtime.dart';
import 'shell_escape.dart';
import 'shell_runner.dart';

class SimctlClient {
  final ShellRunner _runner;
  SimctlClient(this._runner);

  Future<List<SimulatorDevice>> listDevices() async {
    final result = await _runner.run('xcrun', [
      'simctl',
      'list',
      'devices',
      '--json',
    ]);
    if (result.exitCode != 0) return [];
    return _parse(result.stdout);
  }

  Future<void> boot(String udid) async {
    await _runner.run('xcrun', ['simctl', 'boot', udid]);
  }

  Future<void> shutdown(String udid) async {
    await _runner.run('xcrun', ['simctl', 'shutdown', udid]);
  }

  Future<void> erase(String udid) async {
    await _runner.run('xcrun', ['simctl', 'erase', udid]);
  }

  Future<void> deleteDevice(String udid) async {
    await _runner.run('xcrun', ['simctl', 'delete', udid]);
  }

  Future<void> deleteUnavailable() async {
    await _runner.run('xcrun', ['simctl', 'delete', 'unavailable']);
  }

  Future<List<SimulatorRuntime>> listRuntimes() async {
    final result = await _runner.run('xcrun', [
      'simctl',
      'runtime',
      'list',
      '--json',
    ]);
    if (result.exitCode != 0) return [];
    return _parseRuntimes(result.stdout);
  }

  Future<void> deleteRuntime(String identifier) async {
    final result = await _runner.run('xcrun', [
      'simctl',
      'runtime',
      'delete',
      identifier,
    ]);
    if (result.exitCode != 0) {
      throw StateError(
        result.stderr.trim().isEmpty
            ? 'Failed to delete simulator runtime'
            : result.stderr.trim(),
      );
    }
  }

  Future<void> removeDyldCache(String runtimeIdentifier) async {
    final result = await _runner.run('xcrun', [
      'simctl',
      'runtime',
      'dyld_shared_cache',
      'remove',
      runtimeIdentifier,
    ]);
    if (result.exitCode != 0) {
      throw StateError(
        result.stderr.trim().isEmpty
            ? 'Failed to remove simulator cache'
            : result.stderr.trim(),
      );
    }
  }

  Future<void> openSimulatorApp() async {
    await _runner.run('open', ['-a', 'Simulator']);
  }

  Future<void> openSimulatorDevice(String udid) async {
    await _runner.run('open', [
      '-a',
      'Simulator',
      '--args',
      '-CurrentDeviceUDID',
      udid,
    ]);
  }

  Future<String?> chooseAppBundle(String prompt) async {
    final script =
        'set selectedApp to choose file with prompt '
        '${appleScriptStringLiteral(prompt)} '
        'of type {"com.apple.application-bundle"}\n'
        'return POSIX path of selectedApp';
    final result = await _runner.run('/usr/bin/osascript', ['-e', script]);
    if (result.exitCode != 0) {
      final error = result.stderr.trim();
      if (error.contains('User canceled') || error.contains('-128')) {
        return null;
      }
      _throwIfFailed(result, fallback: 'Failed to choose app bundle');
    }
    final path = result.stdout.trim();
    return path.isEmpty ? null : path;
  }

  Future<void> installApp(String udid, String appPath) async {
    final result = await _runner.run('xcrun', [
      'simctl',
      'install',
      udid,
      appPath,
    ]);
    _throwIfFailed(result, fallback: 'Failed to install app');
  }

  Future<void> openUrl(String udid, String url) async {
    final result = await _runner.run('xcrun', ['simctl', 'openurl', udid, url]);
    _throwIfFailed(result, fallback: 'Failed to open URL');
  }

  Future<void> openLogStream(String udid, String title) async {
    final command =
        "${shellQuote('xcrun')} simctl spawn ${shellQuote(udid)} "
        "log stream --style compact --level debug";
    await _openTerminal(command, title);
  }

  Future<String> captureScreenshot(String udid, String deviceName) async {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      throw StateError('Home directory not found');
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final safeName = deviceName.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    final outputDirectory = Directory(
      '$home/Desktop/iOS Simulator Screenshots',
    );
    await outputDirectory.create(recursive: true);
    final outputPath = '${outputDirectory.path}/$safeName-$timestamp.png';

    final result = await _runner.run('xcrun', [
      'simctl',
      'io',
      udid,
      'screenshot',
      '--mask=black',
      outputPath,
    ]);
    _throwIfFailed(result, fallback: 'Failed to capture screenshot');
    await _runner.run('/usr/bin/open', ['-R', outputPath]);
    return outputPath;
  }

  Future<void> openReactNativeDevMenu(String udid) async {
    await _sendSimulatorShortcut(udid, 'keystroke "d" using command down');
  }

  Future<void> reloadReactNative(String udid) async {
    await _sendSimulatorShortcut(udid, 'keystroke "r" using command down');
  }

  Future<void> _sendSimulatorShortcut(String udid, String shortcut) async {
    await openSimulatorDevice(udid);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final script =
        'tell application "Simulator" to activate\n'
        'tell application "System Events"\n'
        'tell process "Simulator"\n'
        'set frontmost to true\n'
        '$shortcut\n'
        'end tell\n'
        'end tell';
    final result = await _runner.run('/usr/bin/osascript', ['-e', script]);
    _throwIfFailed(result, fallback: 'Failed to control Simulator');
  }

  Future<void> _openTerminal(String command, String title) async {
    final titledCommand =
        "printf '\\033]0;%s\\007' ${shellQuote(title)}; clear; exec $command";
    final script =
        'tell application "Terminal"\n'
        'activate\n'
        'do script ${appleScriptStringLiteral(titledCommand)}\n'
        'end tell';
    final result = await _runner.run('/usr/bin/osascript', ['-e', script]);
    _throwIfFailed(result, fallback: 'Failed to open Terminal');
  }

  void _throwIfFailed(ShellResult result, {required String fallback}) {
    if (result.exitCode == 0) return;
    final error = result.stderr.trim().isNotEmpty
        ? result.stderr.trim()
        : result.stdout.trim();
    throw StateError(error.isEmpty ? fallback : error);
  }

  List<SimulatorDevice> _parse(String json) {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final devices = data['devices'] as Map<String, dynamic>? ?? {};
      final result = <SimulatorDevice>[];

      for (final entry in devices.entries) {
        final runtime = _friendlyRuntime(entry.key);
        for (final d in (entry.value as List)) {
          final map = d as Map<String, dynamic>;
          final sizeBytes = (map['dataPathSize'] as num?)?.toInt() ?? 0;
          final lastBooted = map['lastBootedAt'] as String?;
          result.add(
            SimulatorDevice(
              udid: map['udid'] as String? ?? '',
              name: map['name'] as String? ?? 'Unknown',
              runtime: runtime,
              sizeBytes: sizeBytes,
              lastBootedAt: lastBooted != null
                  ? DateTime.tryParse(lastBooted)
                  : null,
              state: map['state'] as String? ?? 'Unknown',
              isAvailable: map['isAvailable'] as bool? ?? false,
            ),
          );
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  List<SimulatorRuntime> _parseRuntimes(String json) {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final runtimes = <SimulatorRuntime>[];

      for (final entry in data.entries) {
        final map = entry.value as Map<String, dynamic>;
        final runtimeIdentifier = map['runtimeIdentifier'] as String? ?? '';
        final identifier = map['identifier'] as String? ?? entry.key;
        if (runtimeIdentifier.isEmpty || identifier.isEmpty) continue;

        final lastUsedAt = map['lastUsedAt'] as String?;
        runtimes.add(
          SimulatorRuntime(
            identifier: identifier,
            runtimeIdentifier: runtimeIdentifier,
            version: map['version'] as String? ?? 'Unknown',
            build: map['build'] as String? ?? '',
            path:
                map['path'] as String? ??
                map['runtimeBundlePath'] as String? ??
                '',
            sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
            lastUsedAt: lastUsedAt == null
                ? null
                : DateTime.tryParse(lastUsedAt),
            deletable: map['deletable'] as bool? ?? false,
          ),
        );
      }

      return runtimes;
    } catch (_) {
      return [];
    }
  }

  String _friendlyRuntime(String key) {
    // com.apple.CoreSimulator.SimRuntime.iOS-17-2  ->  iOS 17.2
    final m = RegExp(r'\.(\w+)-(\d+)-(\d+)$').firstMatch(key);
    if (m != null) return '${m.group(1)} ${m.group(2)}.${m.group(3)}';
    return key.split('.').last.replaceAll('-', ' ');
  }
}
