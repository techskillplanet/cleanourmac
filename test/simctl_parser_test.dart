import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/data/shell/simctl_client.dart';
import 'package:mac_tool/data/shell/shell_runner.dart';

class _FakeRunner extends ShellRunner {
  final String fakeOutput;
  _FakeRunner(this.fakeOutput);

  @override
  Future<ShellResult> run(
    String executable,
    List<String> args, {
    Map<String, String>? environment,
  }) async {
    return ShellResult(fakeOutput, '', 0);
  }
}

class _RecordingRunner extends ShellRunner {
  final List<(String, List<String>)> commands = [];

  @override
  Future<ShellResult> run(
    String executable,
    List<String> args, {
    Map<String, String>? environment,
  }) async {
    commands.add((executable, List.of(args)));
    return const ShellResult('', '', 0);
  }
}

const _sampleJson = '''
{
  "devices": {
    "com.apple.CoreSimulator.SimRuntime.iOS-17-2": [
      {
        "udid": "ABC123",
        "name": "iPhone 15",
        "state": "Shutdown",
        "isAvailable": true,
        "dataPathSize": 1073741824,
        "lastBootedAt": "2024-01-01T10:00:00Z"
      }
    ],
    "com.apple.CoreSimulator.SimRuntime.iOS-16-4": [
      {
        "udid": "DEF456",
        "name": "iPhone 14",
        "state": "Shutdown",
        "isAvailable": true,
        "dataPathSize": 536870912
      }
    ]
  }
}
''';

const _runtimeJson = '''
{
  "RUNTIME-UUID": {
    "build": "22F77",
    "deletable": true,
    "identifier": "RUNTIME-UUID",
    "lastUsedAt": "2026-01-02T03:04:05Z",
    "path": "/System/Library/AssetsV2/iOS18.dmg",
    "runtimeIdentifier": "com.apple.CoreSimulator.SimRuntime.iOS-18-5",
    "sizeBytes": 8837333817,
    "version": "18.5"
  }
}
''';

void main() {
  group('SimctlClient', () {
    test('parses device list correctly', () async {
      final client = SimctlClient(_FakeRunner(_sampleJson));
      final devices = await client.listDevices();

      expect(devices.length, 2);
      final iphone15 = devices.firstWhere((d) => d.name == 'iPhone 15');
      expect(iphone15.udid, 'ABC123');
      expect(iphone15.sizeBytes, 1073741824);
      expect(iphone15.runtime, 'iOS 17.2');
      expect(iphone15.lastBootedAt, isNotNull);
    });

    test('handles missing lastBootedAt', () async {
      final client = SimctlClient(_FakeRunner(_sampleJson));
      final devices = await client.listDevices();
      final iphone14 = devices.firstWhere((d) => d.name == 'iPhone 14');
      expect(iphone14.lastBootedAt, isNull);
    });

    test('device isStale with no boot date', () async {
      final client = SimctlClient(_FakeRunner(_sampleJson));
      final devices = await client.listDevices();
      final iphone14 = devices.firstWhere((d) => d.name == 'iPhone 14');
      expect(iphone14.isStale(30), isTrue);
    });

    test('device with old boot date is stale', () async {
      final client = SimctlClient(_FakeRunner(_sampleJson));
      final devices = await client.listDevices();
      final iphone15 = devices.firstWhere((d) => d.name == 'iPhone 15');
      // lastBootedAt is 2024-01-01, definitely stale after 30 days
      expect(iphone15.isStale(30), isTrue);
    });

    test('returns empty list on empty JSON', () async {
      final client = SimctlClient(_FakeRunner('{}'));
      final devices = await client.listDevices();
      expect(devices, isEmpty);
    });

    test('returns empty list on invalid JSON', () async {
      final client = SimctlClient(_FakeRunner('not json'));
      final devices = await client.listDevices();
      expect(devices, isEmpty);
    });

    test('parses deletable runtime metadata', () async {
      final client = SimctlClient(_FakeRunner(_runtimeJson));
      final runtimes = await client.listRuntimes();

      expect(runtimes, hasLength(1));
      expect(runtimes.single.identifier, 'RUNTIME-UUID');
      expect(
        runtimes.single.runtimeIdentifier,
        'com.apple.CoreSimulator.SimRuntime.iOS-18-5',
      );
      expect(runtimes.single.displayName, 'iOS 18.5');
      expect(runtimes.single.sizeBytes, 8837333817);
      expect(runtimes.single.lastUsedAt, isNotNull);
    });

    test('installs apps and opens URLs on the selected simulator', () async {
      final runner = _RecordingRunner();
      final client = SimctlClient(runner);

      await client.installApp('ABC123', '/tmp/Demo.app');
      await client.openUrl('ABC123', 'myapp://debug');

      expect(runner.commands, hasLength(2));
      expect(runner.commands[0].$1, 'xcrun');
      expect(runner.commands[0].$2, [
        'simctl',
        'install',
        'ABC123',
        '/tmp/Demo.app',
      ]);
      expect(runner.commands[1].$1, 'xcrun');
      expect(runner.commands[1].$2, [
        'simctl',
        'openurl',
        'ABC123',
        'myapp://debug',
      ]);
    });
  });
}
