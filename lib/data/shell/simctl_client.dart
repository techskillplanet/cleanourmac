import 'dart:convert';
import '../../domain/models/simulator_device.dart';
import '../../domain/models/simulator_runtime.dart';
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
