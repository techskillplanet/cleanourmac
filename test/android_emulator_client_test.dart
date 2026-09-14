import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/data/shell/android_emulator_client.dart';
import 'package:mac_tool/data/shell/shell_runner.dart';
import 'package:mac_tool/domain/models/android_emulator_config.dart';

class _Command {
  final String executable;
  final List<String> arguments;

  const _Command(this.executable, this.arguments);
}

class _FakeShellRunner extends ShellRunner {
  final List<_Command> commands = [];
  final ShellResult Function(String executable, List<String> arguments)?
  responder;

  _FakeShellRunner({this.responder});

  @override
  Future<ShellResult> run(
    String executable,
    List<String> args, {
    Map<String, String>? environment,
  }) async {
    commands.add(_Command(executable, List.of(args)));
    return responder?.call(executable, args) ?? const ShellResult('', '', 0);
  }
}

void main() {
  group('parseAvdNameOutput', () {
    test('ignores the emulator console OK line', () {
      expect(parseAvdNameOutput('Medium_Phone\r\nOK\r\n'), 'Medium_Phone');
    });

    test('returns null for an error response', () {
      expect(parseAvdNameOutput('KO: emulator not running\r\n'), isNull);
    });

    test('ignores blank lines', () {
      expect(parseAvdNameOutput('\n\nPixel_9\nOK\n'), 'Pixel_9');
    });
  });

  test('encodes Unicode text as emulator ClipData protobuf', () {
    final encoded = encodeEmulatorClipboardText('A中');

    expect(encoded, [0x0a, 4, 0x41, 0xe4, 0xb8, 0xad]);
    expect(decodeEmulatorClipboardText(encoded), 'A中');
  });

  group('ADB tools', () {
    late Directory sdk;
    late _FakeShellRunner runner;
    late AndroidEmulatorClient client;

    setUp(() {
      sdk = Directory.systemTemp.createTempSync('android-sdk-');
      final adb = File('${sdk.path}/platform-tools/adb');
      adb.parent.createSync(recursive: true);
      adb.writeAsStringSync('');
      runner = _FakeShellRunner();
      client = AndroidEmulatorClient(
        runner,
        sdkRoot: sdk.path,
        emulatorDiscoveryDirectory: '${sdk.path}/running',
      );
    });

    tearDown(() => sdk.deleteSync(recursive: true));

    test('quotes shell arguments safely', () {
      expect(shellQuote("Pixel's Phone"), "'Pixel'\\''s Phone'");
      expect(appleScriptStringLiteral(r'a"b\c'), r'"a\"b\\c"');
    });

    test('installs an APK on the selected serial', () async {
      await client.installApk('emulator-5554', '/tmp/demo app.apk');

      expect(runner.commands, hasLength(1));
      expect(
        runner.commands.single.executable,
        '${sdk.path}/platform-tools/adb',
      );
      expect(runner.commands.single.arguments, [
        '-s',
        'emulator-5554',
        'install',
        '-r',
        '-d',
        '/tmp/demo app.apk',
      ]);
    });

    test('uses a macOS data UTI so APK files stay selectable', () async {
      runner = _FakeShellRunner(
        responder: (_, arguments) {
          if (arguments.isNotEmpty && arguments.first == '-e') {
            return const ShellResult('/tmp/demo.apk\n', '', 0);
          }
          return const ShellResult('', '', 0);
        },
      );
      client = AndroidEmulatorClient(
        runner,
        sdkRoot: sdk.path,
        emulatorDiscoveryDirectory: '${sdk.path}/running',
      );

      expect(await client.chooseApk('选择要安装的 APK'), '/tmp/demo.apk');
      final script = runner.commands.single.arguments.last;
      expect(script, contains('of type {"public.data"}'));
      expect(script, isNot(contains('com.android.package-archive')));
    });

    test('sends Android navigation and clipboard key events', () async {
      await client.pressBack('emulator-5554');
      await client.pressHome('emulator-5554');
      await client.pressRecents('emulator-5554');
      await client.copySelection('emulator-5554');
      await client.pasteClipboard('emulator-5554');

      expect(runner.commands.map((command) => command.arguments).toList(), [
        ['-s', 'emulator-5554', 'shell', 'input', 'keyevent', '4'],
        ['-s', 'emulator-5554', 'shell', 'input', 'keyevent', '3'],
        ['-s', 'emulator-5554', 'shell', 'input', 'keyevent', '187'],
        ['-s', 'emulator-5554', 'shell', 'input', 'keyevent', '278'],
        ['-s', 'emulator-5554', 'shell', 'input', 'keyevent', '279'],
      ]);
    });

    test('restarts the ADB server', () async {
      await client.restartAdb();

      expect(runner.commands.map((command) => command.arguments), [
        ['kill-server'],
        ['start-server'],
      ]);
    });

    test('opens an interactive shell in Terminal', () async {
      await client.openAdbShell('emulator-5554', 'ADB Shell · Pixel');

      expect(runner.commands, hasLength(1));
      expect(runner.commands.single.executable, '/usr/bin/osascript');
      expect(
        runner.commands.single.arguments[1],
        contains("-s 'emulator-5554' shell"),
      );
    });

    test('includes connected physical devices in the Android list', () async {
      runner = _FakeShellRunner(
        responder: (_, arguments) {
          if (arguments case ['devices']) {
            return const ShellResult(
              'List of devices attached\nR58M1234 device\n',
              '',
              0,
            );
          }
          final property = arguments.last;
          final value = switch (property) {
            'ro.product.manufacturer' => 'Google',
            'ro.product.model' => 'Pixel 9',
            'ro.build.version.sdk' => '36',
            'ro.product.cpu.abi' => 'arm64-v8a',
            _ => '',
          };
          return ShellResult('$value\n', '', 0);
        },
      );
      client = AndroidEmulatorClient(
        runner,
        sdkRoot: sdk.path,
        emulatorDiscoveryDirectory: '${sdk.path}/running',
      );

      final devices = await client.list();

      expect(devices, hasLength(1));
      expect(devices.single.name, 'Google Pixel 9');
      expect(devices.single.serial, 'R58M1234');
      expect(devices.single.target, 'API 36');
      expect(devices.single.abi, 'arm64-v8a');
      expect(devices.single.isAvd, isFalse);
    });
  });

  group('emulator startup', () {
    late Directory root;
    late Directory wrongSdk;
    late Directory correctSdk;
    late Directory avdHome;
    late _FakeShellRunner runner;

    setUp(() {
      root = Directory.systemTemp.createTempSync('emulator-startup-');
      wrongSdk = Directory('${root.path}/wrong-sdk');
      correctSdk = Directory('${root.path}/correct-sdk');
      avdHome = Directory('${root.path}/avd')..createSync(recursive: true);
      runner = _FakeShellRunner(
        responder: (_, arguments) => switch (arguments) {
          ['devices'] => const ShellResult('List of devices attached\n', '', 0),
          _ => const ShellResult('', '', 0),
        },
      );

      for (final sdk in [wrongSdk, correctSdk]) {
        final emulator = File('${sdk.path}/emulator/emulator');
        emulator.parent.createSync(recursive: true);
        emulator.writeAsStringSync('#!/bin/sh\nexit 0\n');
        Process.runSync('chmod', ['+x', emulator.path]);
        final adb = File('${sdk.path}/platform-tools/adb');
        adb.parent.createSync(recursive: true);
        adb.writeAsStringSync('');
      }

      final avd = Directory('${avdHome.path}/Medium_Phone.avd')
        ..createSync(recursive: true);
      File('${avd.path}/config.ini').writeAsStringSync(
        'image.sysdir.1='
        'system-images/android-36/google_apis_playstore_ps16k/arm64-v8a/\n'
        'hw.keyboard=no\n',
      );
    });

    tearDown(() => root.deleteSync(recursive: true));

    test('selects the SDK containing the AVD system image', () {
      Directory(
        '${correctSdk.path}/'
        'system-images/android-36/google_apis_playstore_ps16k/arm64-v8a',
      ).createSync(recursive: true);
      final client = AndroidEmulatorClient(
        runner,
        sdkRoots: [wrongSdk.path, correctSdk.path],
        avdHome: avdHome.path,
      );

      expect(client.sdkRootForAvd('Medium_Phone'), correctSdk.path);
      expect(
        client.emulatorBinary(avdName: 'Medium_Phone'),
        '${correctSdk.path}/emulator/emulator',
      );
    });

    test('detects and enables the host hardware keyboard', () async {
      final client = AndroidEmulatorClient(
        runner,
        sdkRoots: [correctSdk.path],
        avdHome: avdHome.path,
      );

      expect(client.hardwareKeyboardEnabled('Medium_Phone'), isFalse);

      await client.enableHardwareKeyboard('Medium_Phone');

      expect(client.hardwareKeyboardEnabled('Medium_Phone'), isTrue);
      expect(
        File('${avdHome.path}/Medium_Phone.avd/config.ini').readAsStringSync(),
        contains('hw.keyboard=yes'),
      );
    });

    test('reports the emulator process error without waiting for timeout', () {
      final image = Directory(
        '${correctSdk.path}/'
        'system-images/android-36/google_apis_playstore_ps16k/arm64-v8a',
      )..createSync(recursive: true);
      expect(image.existsSync(), isTrue);

      final emulator = File('${correctSdk.path}/emulator/emulator');
      emulator.writeAsStringSync(
        '#!/bin/sh\n'
        'echo "FATAL | Cannot load AVD image" >&2\n'
        'exit 1\n',
      );
      Process.runSync('chmod', ['+x', emulator.path]);
      final client = AndroidEmulatorClient(
        runner,
        sdkRoots: [correctSdk.path],
        avdHome: avdHome.path,
        diagnosticLogDirectory: '${root.path}/diagnostics',
      );

      expect(
        client.boot('Medium_Phone'),
        throwsA(
          predicate((error) {
            if (error is! AndroidEmulatorLaunchException) return false;
            final log = File(error.logPath);
            if (!log.existsSync()) return false;
            final contents = log.readAsStringSync();
            return error.toString().contains('Cannot load AVD image') &&
                error.toString().contains(correctSdk.path) &&
                contents.contains('AVD: Medium_Phone') &&
                contents.contains('SDK root: ${correctSdk.path}') &&
                contents.contains('System image:') &&
                contents.contains('FATAL | Cannot load AVD image') &&
                contents.contains('Failure:');
          }),
        ),
      );
    });

    test('records SDK resolution failures in the diagnostics directory', () {
      final client = AndroidEmulatorClient(
        runner,
        sdkRoots: [wrongSdk.path],
        avdHome: avdHome.path,
        diagnosticLogDirectory: '${root.path}/diagnostics',
      );

      expect(
        client.boot('Medium_Phone'),
        throwsA(
          predicate((error) {
            if (error is! AndroidEmulatorLaunchException) return false;
            final contents = File(error.logPath).readAsStringSync();
            return contents.contains('AVD: Medium_Phone') &&
                contents.contains('SDK root: unavailable') &&
                contents.contains('was not found in any Android SDK');
          }),
        ),
      );
    });
  });

  group('configuration inspection and repair', () {
    late Directory root;
    late Directory sdk;
    late Directory avdHome;
    late Directory discovery;
    late Directory backupRoot;
    late Directory avdDirectory;
    late File descriptor;
    late File config;
    late File staleLock;
    late AndroidEmulatorClient client;
    final now = DateTime(2026, 9, 11, 12);

    setUp(() {
      root = Directory.systemTemp.createTempSync('emulator-config-');
      sdk = Directory('${root.path}/sdk');
      avdHome = Directory('${root.path}/avd')..createSync(recursive: true);
      discovery = Directory('${root.path}/running')
        ..createSync(recursive: true);
      backupRoot = Directory('${root.path}/backups');
      avdDirectory = Directory('${avdHome.path}/Pixel_Test.avd')
        ..createSync(recursive: true);
      descriptor = File('${avdHome.path}/Pixel_Test.ini')
        ..writeAsStringSync(
          'avd.ini.encoding=UTF-8\n'
          'path=${root.path}/missing.avd\n'
          'path.rel=wrong/Pixel_Test.avd\n'
          'target=android-36\n',
        );
      config = File('${avdDirectory.path}/config.ini')
        ..writeAsStringSync(
          'image.sysdir.1=/old/sdk/'
          'system-images/android-36/google_apis/arm64-v8a/\n'
          'hw.keyboard=no\n',
        );
      staleLock = File('${avdDirectory.path}/multiinstance.lock')
        ..writeAsStringSync('');
      staleLock.setLastModifiedSync(now.subtract(const Duration(hours: 1)));

      final emulator = File('${sdk.path}/emulator/emulator');
      emulator.parent.createSync(recursive: true);
      emulator.writeAsStringSync('');
      final adb = File('${sdk.path}/platform-tools/adb');
      adb.parent.createSync(recursive: true);
      adb.writeAsStringSync('');
      Directory(
        '${sdk.path}/system-images/android-36/google_apis/arm64-v8a',
      ).createSync(recursive: true);

      client = AndroidEmulatorClient(
        _FakeShellRunner(
          responder: (_, arguments) => switch (arguments) {
            ['devices'] => const ShellResult(
              'List of devices attached\n',
              '',
              0,
            ),
            _ => const ShellResult('', '', 0),
          },
        ),
        sdkRoots: [sdk.path],
        avdHome: avdHome.path,
        emulatorDiscoveryDirectory: discovery.path,
        configBackupDirectory: backupRoot.path,
        now: () => now,
      );
    });

    tearDown(() => root.deleteSync(recursive: true));

    test('finds and safely repairs common AVD configuration issues', () async {
      final report = await client.inspectConfiguration();

      expect(report.avdCount, 1);
      expect(
        report.issues.map((issue) => issue.kind),
        containsAll([
          AndroidEmulatorConfigIssueKind.descriptorPathMismatch,
          AndroidEmulatorConfigIssueKind.systemImagePathMismatch,
          AndroidEmulatorConfigIssueKind.hardwareKeyboardDisabled,
          AndroidEmulatorConfigIssueKind.staleLockFiles,
        ]),
      );
      expect(report.repairableCount, 4);

      final result = await client.repairConfiguration(
        report.repairableIssues.map((issue) => issue.id),
      );

      expect(result.repairedCount, 4);
      expect(result.skippedCount, 0);
      expect(result.report.isHealthy, isTrue);
      expect(result.backupDirectory, isNotNull);
      expect(
        File('${result.backupDirectory}/Pixel_Test/config.ini').existsSync(),
        isTrue,
      );
      expect(
        File(
          '${result.backupDirectory}/Pixel_Test/Pixel_Test.ini',
        ).existsSync(),
        isTrue,
      );
      expect(staleLock.existsSync(), isFalse);

      final descriptorContents = descriptor.readAsStringSync();
      expect(
        descriptorContents,
        contains('path=${avdDirectory.resolveSymbolicLinksSync()}'),
      );
      expect(descriptorContents, contains('path.rel=avd/Pixel_Test.avd'));
      final configContents = config.readAsStringSync();
      expect(
        configContents,
        contains(
          'image.sysdir.1='
          'system-images/android-36/google_apis/arm64-v8a/',
        ),
      );
      expect(configContents, contains('hw.keyboard=yes'));
    });

    test('never reports lock files owned by a running emulator', () async {
      File(
        '${discovery.path}/pid_$pid.ini',
      ).writeAsStringSync('avd.id=Pixel_Test\n');

      final report = await client.inspectConfiguration();

      expect(
        report.issues.where(
          (issue) =>
              issue.kind == AndroidEmulatorConfigIssueKind.staleLockFiles,
        ),
        isEmpty,
      );
    });

    test(
      'does not offer repair when the system image is not installed',
      () async {
        config.writeAsStringSync(
          'image.sysdir.1=system-images/android-99/missing/arm64-v8a/\n'
          'hw.keyboard=yes\n',
        );

        final report = await client.inspectConfiguration();
        final issue = report.issues.singleWhere(
          (item) =>
              item.kind == AndroidEmulatorConfigIssueKind.systemImageMissing,
        );

        expect(issue.repairable, isFalse);
        expect(issue.severity, AndroidEmulatorConfigIssueSeverity.error);
      },
    );
  });
}
