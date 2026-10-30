import 'dart:io';

import 'package:path/path.dart' as p;

typedef ScrcpyExists = bool Function(String path);
typedef ScrcpyWhich = Future<String?> Function(String command);
typedef ScrcpyStartProcess =
    Future<Process> Function(
      String executable,
      List<String> arguments, {
      Map<String, String>? environment,
      ProcessStartMode? mode,
    });

/// Resolves and launches [scrcpy](https://github.com/Genymobile/scrcpy) as an
/// external mirror window for a given ADB serial.
class ScrcpyClient {
  ScrcpyClient({
    ScrcpyExists? exists,
    ScrcpyWhich? which,
    ScrcpyStartProcess? startProcess,
    this._adbBinary,
    List<String>? bundledCandidates,
    List<String>? systemCandidates,
  }) : _exists = exists ?? ((path) => File(path).existsSync()),
       _which = which ?? _defaultWhich,
       _startProcess = startProcess ?? _defaultStartProcess,
       _bundledCandidates = bundledCandidates ?? _defaultBundledCandidates(),
       _systemCandidates = systemCandidates ?? _defaultSystemCandidates;

  final ScrcpyExists _exists;
  final ScrcpyWhich _which;
  final ScrcpyStartProcess _startProcess;
  final String? Function()? _adbBinary;
  final List<String> _bundledCandidates;
  final List<String> _systemCandidates;

  static const _defaultSystemCandidates = <String>[
    '/opt/homebrew/bin/scrcpy',
    '/usr/local/bin/scrcpy',
  ];

  /// Sync resolve among bundled + system fixed paths (no PATH lookup).
  String? resolveBinary() {
    for (final candidate in [..._bundledCandidates, ..._systemCandidates]) {
      if (_exists(candidate)) return candidate;
    }
    return null;
  }

  /// Resolve including `which scrcpy` fallback.
  Future<String?> resolveBinaryAsync() async {
    final sync = resolveBinary();
    if (sync != null) return sync;
    final fromPath = await _which('scrcpy');
    if (fromPath != null && fromPath.isNotEmpty && _exists(fromPath)) {
      return fromPath;
    }
    return fromPath != null && fromPath.isNotEmpty ? fromPath : null;
  }

  Future<void> launchMirror(
    String serial, {
    String? windowTitle,
  }) async {
    final trimmed = serial.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Device serial is required');
    }

    final binary = await resolveBinaryAsync();
    if (binary == null) {
      throw StateError(
        '未找到 scrcpy。请在仓库根目录执行 ./tool/bundle_scrcpy.sh'
        '（需本机构建机已 brew install scrcpy），或安装系统 scrcpy。',
      );
    }

    final args = <String>['-s', trimmed];
    if (windowTitle != null && windowTitle.trim().isNotEmpty) {
      args.addAll(['--window-title', windowTitle.trim()]);
    }

    final environment = <String, String>{
      ...Platform.environment,
      'PATH': _pathWithHomebrew(Platform.environment['PATH']),
    };
    final adb = _adbBinary?.call();
    if (adb != null && adb.isNotEmpty) {
      environment['ADB'] = adb;
    }
    final server = p.join(p.dirname(binary), 'scrcpy-server');
    if (_exists(server)) {
      environment['SCRCPY_SERVER_PATH'] = server;
    }

    await _startProcess(
      binary,
      args,
      environment: environment,
      mode: ProcessStartMode.detached,
    );
  }

  static Future<Process> _defaultStartProcess(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
    ProcessStartMode? mode,
  }) {
    return Process.start(
      executable,
      arguments,
      environment: environment,
      mode: mode ?? ProcessStartMode.normal,
    );
  }

  static String _pathWithHomebrew(String? current) {
    const extras = '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin';
    if (current == null || current.isEmpty) return extras;
    return '$extras:$current';
  }

  static List<String> _defaultBundledCandidates() {
    final candidates = <String>[];

    // Dev / repo checkout: <repo>/third_party/scrcpy/scrcpy
    final script = Platform.script.toFilePath();
    final fromScript = p.normalize(
      p.join(p.dirname(script), '..', 'third_party', 'scrcpy', 'scrcpy'),
    );
    candidates.add(fromScript);

    try {
      final exe = Platform.resolvedExecutable;
      final exeDir = p.dirname(exe);
      // macOS .app/Contents/MacOS/<exe> → Resources/scrcpy/scrcpy
      candidates.add(
        p.join(exeDir, '..', 'Resources', 'scrcpy', 'scrcpy'),
      );
      candidates.add(p.join(exeDir, 'scrcpy', 'scrcpy'));
      candidates.add(p.join(exeDir, 'scrcpy'));
    } catch (_) {}

    // Relative to current working directory (flutter run from repo root)
    candidates.add(
      p.normalize(p.join(Directory.current.path, 'third_party', 'scrcpy', 'scrcpy')),
    );

    return candidates.map(p.normalize).toSet().toList();
  }

  static Future<String?> _defaultWhich(String command) async {
    try {
      final result = await Process.run('which', [
        command,
      ], environment: {
        ...Platform.environment,
        'PATH': _pathWithHomebrew(Platform.environment['PATH']),
      });
      if (result.exitCode != 0) return null;
      final path = (result.stdout as String).trim().split('\n').first.trim();
      return path.isEmpty ? null : path;
    } catch (_) {
      return null;
    }
  }
}
