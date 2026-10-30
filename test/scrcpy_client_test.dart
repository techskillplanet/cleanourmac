import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/data/shell/scrcpy_client.dart';

void main() {
  test('resolveBinary returns first existing candidate', () {
    final client = ScrcpyClient(
      exists: (path) => path == '/opt/homebrew/bin/scrcpy',
      which: (_) async => null,
      startProcess: (_, __, {environment, mode}) async {
        throw StateError('should not start');
      },
    );

    expect(client.resolveBinary(), '/opt/homebrew/bin/scrcpy');
  });

  test('resolveBinary falls back to which(scrcpy)', () async {
    final client = ScrcpyClient(
      exists: (_) => false,
      which: (command) async => command == 'scrcpy' ? '/usr/local/bin/scrcpy' : null,
      startProcess: (_, __, {environment, mode}) async {
        throw StateError('should not start');
      },
    );

    expect(await client.resolveBinaryAsync(), '/usr/local/bin/scrcpy');
  });

  test('launchMirror starts detached scrcpy with serial and ADB env', () async {
    String? startedExecutable;
    List<String>? startedArgs;
    Map<String, String>? startedEnv;
    ProcessStartMode? startedMode;

    final client = ScrcpyClient(
      exists: (path) =>
          path == '/bundled/scrcpy' || path == '/bundled/scrcpy-server',
      which: (_) async => null,
      adbBinary: () => '/sdk/platform-tools/adb',
      bundledCandidates: const ['/bundled/scrcpy'],
      startProcess:
          (executable, args, {environment, mode}) async {
            startedExecutable = executable;
            startedArgs = args;
            startedEnv = environment;
            startedMode = mode;
            return _FakeProcess();
          },
    );

    await client.launchMirror('emulator-5554', windowTitle: 'Pixel Demo');

    expect(startedExecutable, '/bundled/scrcpy');
    expect(startedArgs, containsAll(['-s', 'emulator-5554']));
    expect(startedArgs, containsAll(['--window-title', 'Pixel Demo']));
    expect(startedEnv?['ADB'], '/sdk/platform-tools/adb');
    expect(startedEnv?['SCRCPY_SERVER_PATH'], '/bundled/scrcpy-server');
    expect(startedMode, ProcessStartMode.detached);
  });

  test('launchMirror throws when scrcpy is missing', () async {
    final client = ScrcpyClient(
      exists: (_) => false,
      which: (_) async => null,
      startProcess: (_, __, {environment, mode}) async {
        throw StateError('should not start');
      },
    );

    expect(
      () => client.launchMirror('serial-1'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('scrcpy'),
        ),
      ),
    );
  });

  test('launchMirror rejects blank serial', () async {
    final client = ScrcpyClient(
      exists: (_) => true,
      which: (_) async => null,
      startProcess: (_, __, {environment, mode}) async => _FakeProcess(),
    );

    expect(
      () => client.launchMirror('  '),
      throwsA(isA<ArgumentError>()),
    );
  });
}

class _FakeProcess implements Process {
  @override
  Future<int> get exitCode async => 0;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => true;

  @override
  int get pid => 1;

  @override
  Stream<List<int>> get stderr => const Stream.empty();

  @override
  IOSink get stdin => throw UnsupportedError('stdin');

  @override
  Stream<List<int>> get stdout => const Stream.empty();
}
