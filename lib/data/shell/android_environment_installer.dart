import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/models/android_environment_setup.dart';

class AndroidEnvironmentInstaller {
  final String? _sdkRootOverride;
  final String? _avdNameOverride;

  AndroidEnvironmentInstaller({String? sdkRoot, String? avdName})
    : _sdkRootOverride = sdkRoot,
      _avdNameOverride = avdName;

  String get defaultSdkRoot {
    final override = _sdkRootOverride;
    if (override != null && override.isNotEmpty) return override;
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null || home.isEmpty) {
      throw StateError('无法确定用户目录');
    }
    return Platform.isWindows
        ? p.join(Platform.environment['LOCALAPPDATA'] ?? home, 'Android', 'Sdk')
        : p.join(home, 'Library', 'Android', 'sdk');
  }

  String get defaultAvdName => _avdNameOverride ?? 'Mobile_Dev_API_35';

  Future<AndroidEnvironmentSetupResult> initialize({
    void Function(String message)? onProgress,
  }) async {
    final sdkRoot = defaultSdkRoot;
    final avdName = defaultAvdName;
    final logDirectory = Directory(
      p.join(Directory.systemTemp.path, 'mobile-dev-assistant'),
    )..createSync(recursive: true);
    final logFile = File(
      p.join(
        logDirectory.path,
        'android-environment-${DateTime.now().millisecondsSinceEpoch}.log',
      ),
    );
    final output = StringBuffer();

    try {
      await Directory(sdkRoot).create(recursive: true);
      final sdkmanager = await _ensureCommandLineTools(
        sdkRoot,
        output,
        onProgress,
      );
      onProgress?.call('接受 Android SDK 许可…');
      await _run(
        sdkmanager,
        ['--sdk_root=$sdkRoot', '--licenses'],
        output,
        input: 'y\n' * 20,
      );

      onProgress?.call('安装 Android SDK 组件…');
      await _run(
        sdkmanager,
        [
          '--sdk_root=$sdkRoot',
          'platform-tools',
          'emulator',
          'platforms;android-35',
          'system-images;android-35;google_apis;${_hostAbi()}',
        ],
        output,
        input: 'y\n' * 20,
      );

      final avdmanager = _toolPath(sdkRoot, 'avdmanager');
      if (!File(avdmanager).existsSync()) {
        throw StateError('avdmanager 安装失败');
      }

      onProgress?.call('创建默认 Android 模拟器…');
      final existing = await _run(
        avdmanager,
        ['list', 'avd'],
        output,
        allowFailure: true,
      );
      if (!existing.stdout.contains('Name: $avdName')) {
        await _run(
          avdmanager,
          [
            'create',
            'avd',
            '--force',
            '--name',
            avdName,
            '--package',
            'system-images;android-35;google_apis;${_hostAbi()}',
            '--device',
            'pixel_5',
          ],
          output,
          input: 'no\n',
        );
      }

      await logFile.writeAsString(output.toString(), flush: true);
      return AndroidEnvironmentSetupResult(
        sdkRoot: sdkRoot,
        avdName: avdName,
        logPath: logFile.path,
      );
    } catch (error, stackTrace) {
      output
        ..writeln()
        ..writeln('ERROR: $error')
        ..writeln(stackTrace);
      await logFile.writeAsString(output.toString(), flush: true);
      throw AndroidEnvironmentSetupException(
        message: error.toString(),
        logPath: logFile.path,
      );
    }
  }

  Future<String> _ensureCommandLineTools(
    String sdkRoot,
    StringBuffer output,
    void Function(String message)? onProgress,
  ) async {
    final existing = _findSdkManager(sdkRoot);
    if (existing != null) return existing;

    onProgress?.call('下载 Android Command-line Tools…');
    final zip = File(
      p.join(
        Directory.systemTemp.path,
        Platform.isWindows
            ? 'commandlinetools-win.zip'
            : 'commandlinetools-mac.zip',
      ),
    );
    final url = _commandLineToolsUrl();
    await _run(Platform.isWindows ? 'curl.exe' : '/usr/bin/curl', [
      '-fL',
      '--retry',
      '3',
      '--progress-bar',
      url,
      '-o',
      zip.path,
    ], output);

    final staging = Directory(p.join(sdkRoot, 'cmdline-tools', '_latest'));
    if (staging.existsSync()) {
      staging.deleteSync(recursive: true);
    }
    await staging.create(recursive: true);
    onProgress?.call('解压 Android Command-line Tools…');
    if (Platform.isWindows) {
      await _run('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        'Expand-Archive -LiteralPath '
            '${_quotePowerShell(zip.path)} -DestinationPath '
            '${_quotePowerShell(staging.path)} -Force',
      ], output);
    } else {
      await _run('/usr/bin/unzip', [
        '-q',
        '-o',
        zip.path,
        '-d',
        staging.path,
      ], output);
    }
    final nested = Directory(p.join(staging.path, 'cmdline-tools'));
    final latest = Directory(p.join(sdkRoot, 'cmdline-tools', 'latest'));
    if (latest.existsSync()) latest.deleteSync(recursive: true);
    if (nested.existsSync()) {
      await nested.rename(latest.path);
      staging.deleteSync(recursive: true);
    } else {
      await staging.rename(latest.path);
    }
    if (zip.existsSync()) zip.deleteSync();

    final manager = _findSdkManager(sdkRoot);
    if (manager == null) throw StateError('sdkmanager 安装失败');
    return manager;
  }

  String? _findSdkManager(String sdkRoot) {
    final candidates = [
      _toolPath(sdkRoot, 'sdkmanager'),
      p.join(sdkRoot, 'cmdline-tools', 'bin', 'sdkmanager'),
    ];
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) return candidate;
    }
    return null;
  }

  String _commandLineToolsUrl() {
    if (Platform.isMacOS) {
      return 'https://dl.google.com/android/repository/'
          'commandlinetools-mac-13114758_latest.zip';
    }
    if (Platform.isWindows) {
      return 'https://dl.google.com/android/repository/'
          'commandlinetools-win-13114758_latest.zip';
    }
    throw UnsupportedError('当前仅支持 macOS 和 Windows Android 环境初始化');
  }

  String _hostAbi() =>
      switch (Platform.environment['PROCESSOR_ARCHITECTURE'] ?? _runUname()) {
        'x86_64' || 'AMD64' => 'x86_64',
        _ => 'arm64-v8a',
      };

  String _runUname() {
    final result = Process.runSync(
      Platform.isWindows ? 'cmd.exe' : '/usr/bin/uname',
      Platform.isWindows
          ? [
              '/c',
              'echo',
              Platform.environment['PROCESSOR_ARCHITECTURE'] ?? 'AMD64',
            ]
          : ['-m'],
    );
    return result.stdout.toString().trim();
  }

  Future<_CommandResult> _run(
    String executable,
    List<String> arguments,
    StringBuffer output, {
    String? input,
    bool allowFailure = false,
  }) async {
    final actualExecutable =
        Platform.isWindows && executable.toLowerCase().endsWith('.bat')
        ? 'cmd.exe'
        : executable;
    final actualArguments =
        Platform.isWindows && executable.toLowerCase().endsWith('.bat')
        ? ['/c', executable, ...arguments]
        : arguments;
    final process = await Process.start(
      actualExecutable,
      actualArguments,
      environment: {
        ...Platform.environment,
        'ANDROID_HOME': defaultSdkRoot,
        'ANDROID_SDK_ROOT': defaultSdkRoot,
        'PATH': Platform.isWindows
            ? '${p.join(defaultSdkRoot, 'platform-tools')};'
                  '${p.join(defaultSdkRoot, 'emulator')};'
                  '${Platform.environment['PATH'] ?? ''}'
            : '${p.join(defaultSdkRoot, 'platform-tools')}:'
                  '${p.join(defaultSdkRoot, 'emulator')}:'
                  '${Platform.environment['PATH'] ?? ''}',
      },
    );
    if (input != null) {
      process.stdin.write(input);
      await process.stdin.close();
    }
    final stdout = StringBuffer();
    final stderr = StringBuffer();
    await Future.wait([
      process.stdout.transform(SystemEncoding().decoder).forEach((chunk) {
        stdout.write(chunk);
        output.write(chunk);
      }),
      process.stderr.transform(SystemEncoding().decoder).forEach((chunk) {
        stderr.write(chunk);
        output.write(chunk);
      }),
    ]);
    final exitCode = await process.exitCode;
    if (exitCode != 0 && !allowFailure) {
      throw StateError(
        '${p.basename(executable)} 失败（$exitCode）：'
        '${stderr.toString().trim().isEmpty ? stdout.toString().trim() : stderr.toString().trim()}',
      );
    }
    return _CommandResult(
      stdout: stdout.toString(),
      stderr: stderr.toString(),
      exitCode: exitCode,
    );
  }

  String _toolPath(String sdkRoot, String name) {
    final base = p.join(sdkRoot, 'cmdline-tools', 'latest', 'bin', name);
    return Platform.isWindows ? '$base.bat' : base;
  }

  String _quotePowerShell(String value) => "'${value.replaceAll("'", "''")}'";
}

class _CommandResult {
  final String stdout;
  final String stderr;
  final int exitCode;

  const _CommandResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
  });
}

class AndroidEnvironmentSetupException implements Exception {
  final String message;
  final String logPath;

  const AndroidEnvironmentSetupException({
    required this.message,
    required this.logPath,
  });

  @override
  String toString() => '$message\n诊断日志：$logPath';
}
