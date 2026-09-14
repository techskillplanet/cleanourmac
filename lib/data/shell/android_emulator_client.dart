import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/android_emulator.dart';
import '../../domain/models/android_emulator_config.dart';
export 'shell_escape.dart' show appleScriptStringLiteral, shellQuote;
import 'shell_escape.dart';
import 'shell_runner.dart';

List<int> encodeEmulatorClipboardText(String text) {
  final bytes = utf8.encode(text);
  return [0x0a, ..._encodeUnsignedVarint(bytes.length), ...bytes];
}

String decodeEmulatorClipboardText(List<int> bytes) {
  var offset = 0;
  while (offset < bytes.length) {
    final key = _decodeUnsignedVarint(bytes, offset);
    offset = key.nextOffset;
    final field = key.value >> 3;
    final wireType = key.value & 0x07;
    if (wireType == 2) {
      final length = _decodeUnsignedVarint(bytes, offset);
      offset = length.nextOffset;
      final end = offset + length.value;
      if (end > bytes.length) {
        throw const FormatException('Invalid clipboard protobuf length');
      }
      if (field == 1) return utf8.decode(bytes.sublist(offset, end));
      offset = end;
      continue;
    }
    if (wireType == 0) {
      offset = _decodeUnsignedVarint(bytes, offset).nextOffset;
      continue;
    }
    if (wireType == 1) {
      offset += 8;
      continue;
    }
    if (wireType == 5) {
      offset += 4;
      continue;
    }
    throw FormatException('Unsupported clipboard protobuf wire type $wireType');
  }
  return '';
}

List<int> _encodeUnsignedVarint(int value) {
  final result = <int>[];
  do {
    var byte = value & 0x7f;
    value >>= 7;
    if (value != 0) byte |= 0x80;
    result.add(byte);
  } while (value != 0);
  return result;
}

({int value, int nextOffset}) _decodeUnsignedVarint(
  List<int> bytes,
  int offset,
) {
  var value = 0;
  var shift = 0;
  while (offset < bytes.length && shift < 64) {
    final byte = bytes[offset++];
    value |= (byte & 0x7f) << shift;
    if ((byte & 0x80) == 0) {
      return (value: value, nextOffset: offset);
    }
    shift += 7;
  }
  throw const FormatException('Invalid clipboard protobuf varint');
}

String? parseAvdNameOutput(String stdout) {
  for (final rawLine in stdout.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.isEmpty || line == 'OK' || line.startsWith('KO:')) continue;
    return line;
  }
  return null;
}

class AndroidEmulatorLaunchException implements Exception {
  final String message;
  final String logPath;
  final Object cause;

  const AndroidEmulatorLaunchException({
    required this.message,
    required this.logPath,
    required this.cause,
  });

  @override
  String toString() => '$message\nDiagnostic log: $logPath';
}

class _EmulatorGrpcEndpoint {
  final int port;
  final String token;

  const _EmulatorGrpcEndpoint({required this.port, required this.token});
}

class _EmulatorControllerClient extends Client {
  _EmulatorControllerClient(super.channel);

  static final _setClipboard = ClientMethod<String, bool>(
    '/android.emulation.control.EmulatorController/setClipboard',
    encodeEmulatorClipboardText,
    (_) => true,
  );
  static final _getClipboard = ClientMethod<bool, String>(
    '/android.emulation.control.EmulatorController/getClipboard',
    (_) => const [],
    decodeEmulatorClipboardText,
  );

  Future<void> setClipboard(String text, String token) async {
    await $createUnaryCall(
      _setClipboard,
      text,
      options: CallOptions(
        metadata: {'authorization': 'Bearer $token'},
        timeout: const Duration(seconds: 5),
      ),
    );
  }

  Future<String> getClipboard(String token) {
    return $createUnaryCall(
      _getClipboard,
      true,
      options: CallOptions(
        metadata: {'authorization': 'Bearer $token'},
        timeout: const Duration(seconds: 5),
      ),
    );
  }
}

class AndroidEmulatorClient {
  final ShellRunner _runner;
  final String? _sdkRootOverride;
  final List<String>? _sdkRootsOverride;
  final String? _avdHomeOverride;
  final String? _diagnosticLogDirectoryOverride;
  final String? _emulatorDiscoveryDirectoryOverride;
  final String? _configBackupDirectoryOverride;
  final DateTime Function() _now;

  AndroidEmulatorClient(
    this._runner, {
    String? sdkRoot,
    List<String>? sdkRoots,
    String? avdHome,
    String? diagnosticLogDirectory,
    String? emulatorDiscoveryDirectory,
    String? configBackupDirectory,
    DateTime Function()? now,
  }) : _sdkRootOverride = sdkRoot,
       _sdkRootsOverride = sdkRoots,
       _avdHomeOverride = avdHome,
       _diagnosticLogDirectoryOverride = diagnosticLogDirectory,
       _emulatorDiscoveryDirectoryOverride = emulatorDiscoveryDirectory,
       _configBackupDirectoryOverride = configBackupDirectory,
       _now = now ?? DateTime.now;

  late final List<String> _sdkRoots = _discoverSdkRoots();

  List<String> _discoverSdkRoots() {
    final overriddenRoots = _sdkRootsOverride;
    if (overriddenRoots != null) {
      return overriddenRoots.map(_normalizePath).toSet().toList();
    }

    final roots = <String>[];
    void addRoot(String? path) {
      if (path == null || path.trim().isEmpty) return;
      final normalized = _normalizePath(path.trim());
      if (Directory(normalized).existsSync() && !roots.contains(normalized)) {
        roots.add(normalized);
      }
    }

    addRoot(_sdkRootOverride);
    final env = Platform.environment;
    addRoot(env['ANDROID_HOME']);
    addRoot(env['ANDROID_SDK_ROOT']);

    final home = env['HOME'];
    if (home != null) {
      for (final studioRoot in _androidStudioSdkRoots(home)) {
        addRoot(studioRoot);
      }
      addRoot('$home/Library/Android/sdk');
    }

    final volumes = Directory('/Volumes');
    if (volumes.existsSync()) {
      try {
        for (final volume in volumes.listSync().whereType<Directory>()) {
          addRoot('${volume.path}/androidsdk');
          addRoot('${volume.path}/Android/sdk');
        }
      } on FileSystemException {
        // External volumes may disappear while SDK roots are being detected.
      }
    }
    return roots;
  }

  String? get _sdkRoot {
    final roots = _sdkRoots;
    return roots.isEmpty ? null : roots.first;
  }

  String? get _avdHome {
    if (_avdHomeOverride != null) return _normalizePath(_avdHomeOverride);
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
  String? emulatorBinary({String? avdName}) {
    final root = avdName == null
        ? _firstSdkRootContaining('emulator/emulator')
        : sdkRootForAvd(avdName);
    if (root == null) return null;
    final candidate = '$root/emulator/emulator';
    return File(candidate).existsSync() ? candidate : null;
  }

  String? adbBinary() {
    final root = _firstSdkRootContaining('platform-tools/adb');
    if (root == null) return null;
    final candidate = '$root/platform-tools/adb';
    return File(candidate).existsSync() ? candidate : null;
  }

  bool get isAvailable => adbBinary() != null || emulatorBinary() != null;

  String? sdkRootForAvd(String avdName) {
    final systemImage = _avdSystemImagePath(avdName);
    if (systemImage == null || systemImage.isEmpty) {
      return _firstSdkRootContaining('emulator/emulator');
    }

    for (final root in _sdkRoots) {
      final emulator = File('$root/emulator/emulator');
      final image = Directory(
        systemImage.startsWith('/') ? systemImage : '$root/$systemImage',
      );
      if (emulator.existsSync() && image.existsSync()) return root;
    }
    return null;
  }

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
  Future<Map<String, String>> _serialToAvd([
    Map<String, String>? connectedDevices,
  ]) async {
    final adb = adbBinary();
    if (adb == null) return const {};
    final serials = connectedDevices ?? await adbDevices();
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
      hardwareKeyboardEnabled: props['hw.keyboard'] == 'yes',
    );
  }

  String? _abiFromSysdir(String sysdir) {
    final parts = sysdir.split('/').where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.last;
  }

  // Combines AVDs with their current adb running state.
  Future<List<AndroidEmulator>> list() async {
    final avdNames = await listAvdNames();
    final connectedDevices = await adbDevices();
    final serialToAvd = await _serialToAvd(connectedDevices);
    final serialByName = <String, String>{};
    for (final entry in serialToAvd.entries) {
      serialByName[entry.value] = entry.key;
    }

    final devices = avdNames.map((name) {
      final emu = _avdFromConfig(name);
      final serial = serialByName[name];
      return emu.copyWith(isRunning: serial != null, serial: serial);
    }).toList();

    for (final entry in connectedDevices.entries) {
      if (entry.value != 'device' || serialToAvd.containsKey(entry.key)) {
        continue;
      }
      devices.add(await _connectedDevice(entry.key));
    }

    return devices;
  }

  Future<AndroidEmulatorConfigReport> inspectConfiguration() async {
    final checkedAt = _now();
    final avdHome = _avdHome;
    if (avdHome == null) {
      return AndroidEmulatorConfigReport(
        checkedAt: checkedAt,
        avdCount: 0,
        sdkRoots: List.unmodifiable(_sdkRoots),
        issues: const [
          AndroidEmulatorConfigIssue(
            avdName: '',
            kind: AndroidEmulatorConfigIssueKind.avdHomeMissing,
            severity: AndroidEmulatorConfigIssueSeverity.error,
            repairable: false,
            path: '',
          ),
        ],
      );
    }

    final homeDirectory = Directory(avdHome);
    if (!homeDirectory.existsSync()) {
      return AndroidEmulatorConfigReport(
        checkedAt: checkedAt,
        avdCount: 0,
        sdkRoots: List.unmodifiable(_sdkRoots),
        issues: [
          AndroidEmulatorConfigIssue(
            avdName: '',
            kind: AndroidEmulatorConfigIssueKind.avdHomeMissing,
            severity: AndroidEmulatorConfigIssueSeverity.error,
            repairable: false,
            path: avdHome,
          ),
        ],
      );
    }

    final names = await _knownAvdNames(homeDirectory);
    final runningNames = await _runningAvdNames();
    final issues = <AndroidEmulatorConfigIssue>[];

    for (final name in names) {
      final descriptor = File(p.join(avdHome, '$name.ini'));
      final descriptorProperties = descriptor.existsSync()
          ? _readProperties(descriptor)
          : const <String, String>{};
      final avdDirectory = _resolveAvdDirectory(
        avdHome: avdHome,
        avdName: name,
        descriptorProperties: descriptorProperties,
      );

      if (!avdDirectory.existsSync()) {
        issues.add(
          AndroidEmulatorConfigIssue(
            avdName: name,
            kind: AndroidEmulatorConfigIssueKind.avdDirectoryMissing,
            severity: AndroidEmulatorConfigIssueSeverity.error,
            repairable: false,
            path: avdDirectory.path,
          ),
        );
        continue;
      }

      final expectedPath = _canonicalPath(avdDirectory.path);
      final expectedRelativePath = p.join('avd', '$name.avd');
      if (!descriptor.existsSync()) {
        issues.add(
          AndroidEmulatorConfigIssue(
            avdName: name,
            kind: AndroidEmulatorConfigIssueKind.descriptorMissing,
            severity: AndroidEmulatorConfigIssueSeverity.error,
            repairable: true,
            path: descriptor.path,
            suggestedValue: expectedPath,
          ),
        );
      } else {
        final configuredPath = descriptorProperties['path'];
        final configuredRelativePath = descriptorProperties['path.rel'];
        final configuredAbsolutePath = configuredPath == null
            ? null
            : _descriptorPath(avdHome, configuredPath);
        final pathMatches =
            configuredAbsolutePath != null &&
            _canonicalPath(configuredAbsolutePath) == expectedPath;
        if (!pathMatches || configuredRelativePath != expectedRelativePath) {
          issues.add(
            AndroidEmulatorConfigIssue(
              avdName: name,
              kind: AndroidEmulatorConfigIssueKind.descriptorPathMismatch,
              severity: AndroidEmulatorConfigIssueSeverity.error,
              repairable: true,
              path: descriptor.path,
              currentValue: configuredPath ?? configuredRelativePath,
              suggestedValue: expectedPath,
            ),
          );
        }
      }

      final config = File(p.join(avdDirectory.path, 'config.ini'));
      if (!config.existsSync()) {
        issues.add(
          AndroidEmulatorConfigIssue(
            avdName: name,
            kind: AndroidEmulatorConfigIssueKind.configMissing,
            severity: AndroidEmulatorConfigIssueSeverity.error,
            repairable: false,
            path: config.path,
          ),
        );
        continue;
      }

      final configProperties = _readProperties(config);
      final imagePath = configProperties['image.sysdir.1'];
      if (imagePath == null || imagePath.isEmpty) {
        issues.add(
          AndroidEmulatorConfigIssue(
            avdName: name,
            kind: AndroidEmulatorConfigIssueKind.systemImagePathMissing,
            severity: AndroidEmulatorConfigIssueSeverity.error,
            repairable: false,
            path: config.path,
          ),
        );
      } else if (!_systemImageExists(imagePath)) {
        final replacement = _recoverSystemImagePath(imagePath);
        if (replacement != null) {
          issues.add(
            AndroidEmulatorConfigIssue(
              avdName: name,
              kind: AndroidEmulatorConfigIssueKind.systemImagePathMismatch,
              severity: AndroidEmulatorConfigIssueSeverity.error,
              repairable: true,
              requiresRestart: runningNames.contains(name),
              path: config.path,
              currentValue: imagePath,
              suggestedValue: replacement,
            ),
          );
        } else {
          issues.add(
            AndroidEmulatorConfigIssue(
              avdName: name,
              kind: AndroidEmulatorConfigIssueKind.systemImageMissing,
              severity: AndroidEmulatorConfigIssueSeverity.error,
              repairable: false,
              path: imagePath,
            ),
          );
        }
      }

      if (configProperties['hw.keyboard'] != 'yes') {
        issues.add(
          AndroidEmulatorConfigIssue(
            avdName: name,
            kind: AndroidEmulatorConfigIssueKind.hardwareKeyboardDisabled,
            severity: AndroidEmulatorConfigIssueSeverity.warning,
            repairable: true,
            requiresRestart: runningNames.contains(name),
            path: config.path,
            currentValue: configProperties['hw.keyboard'],
            suggestedValue: 'yes',
          ),
        );
      }

      if (!runningNames.contains(name)) {
        final staleLocks = _staleLockPaths(avdDirectory, checkedAt);
        if (staleLocks.isNotEmpty) {
          issues.add(
            AndroidEmulatorConfigIssue(
              avdName: name,
              kind: AndroidEmulatorConfigIssueKind.staleLockFiles,
              severity: AndroidEmulatorConfigIssueSeverity.warning,
              repairable: true,
              path: avdDirectory.path,
              relatedPaths: staleLocks,
            ),
          );
        }
      }
    }

    return AndroidEmulatorConfigReport(
      checkedAt: checkedAt,
      avdCount: names.length,
      sdkRoots: List.unmodifiable(_sdkRoots),
      issues: List.unmodifiable(issues),
    );
  }

  Future<AndroidEmulatorConfigRepairResult> repairConfiguration(
    Iterable<String> issueIds,
  ) async {
    final selectedIds = issueIds.toSet();
    final currentReport = await inspectConfiguration();
    final selectedIssues = currentReport.repairableIssues
        .where((issue) => selectedIds.contains(issue.id))
        .toList();
    var skippedCount = selectedIds.length - selectedIssues.length;
    var repairedCount = 0;
    Directory? backupDirectory;
    final backedUpPaths = <String>{};
    final restartRequiredAvds = <String>{};
    final runningNames = await _runningAvdNames();

    Future<void> backup(File file, String avdName) async {
      if (!file.existsSync() || !backedUpPaths.add(file.path)) return;
      backupDirectory ??= await _createConfigBackupDirectory();
      final destinationDirectory = Directory(
        p.join(backupDirectory!.path, _safeFileName(avdName)),
      );
      await destinationDirectory.create(recursive: true);
      await file.copy(p.join(destinationDirectory.path, p.basename(file.path)));
    }

    for (final issue in selectedIssues) {
      try {
        switch (issue.kind) {
          case AndroidEmulatorConfigIssueKind.descriptorMissing:
          case AndroidEmulatorConfigIssueKind.descriptorPathMismatch:
            final avdHome = _avdHome;
            if (avdHome == null || issue.suggestedValue == null) {
              skippedCount++;
              continue;
            }
            final descriptor = File(p.join(avdHome, '${issue.avdName}.ini'));
            await backup(descriptor, issue.avdName);
            await _updateProperties(descriptor, {
              'avd.ini.encoding': 'UTF-8',
              'path': issue.suggestedValue!,
              'path.rel': p.join('avd', '${issue.avdName}.avd'),
            }, create: true);
          case AndroidEmulatorConfigIssueKind.systemImagePathMismatch:
            final config = File(issue.path);
            final replacement = issue.suggestedValue;
            if (!config.existsSync() || replacement == null) {
              skippedCount++;
              continue;
            }
            await backup(config, issue.avdName);
            await _updateProperties(config, {'image.sysdir.1': replacement});
          case AndroidEmulatorConfigIssueKind.hardwareKeyboardDisabled:
            final config = File(issue.path);
            if (!config.existsSync()) {
              skippedCount++;
              continue;
            }
            await backup(config, issue.avdName);
            await _updateProperties(config, {'hw.keyboard': 'yes'});
          case AndroidEmulatorConfigIssueKind.staleLockFiles:
            if (runningNames.contains(issue.avdName) ||
                (await _runningAvdNames()).contains(issue.avdName)) {
              skippedCount++;
              continue;
            }
            var removedAny = false;
            for (final lockPath in issue.relatedPaths) {
              if (!_isSafeLockPath(issue.path, lockPath) ||
                  !_isStaleLockPath(lockPath, _now())) {
                continue;
              }
              final type = FileSystemEntity.typeSync(lockPath);
              if (type == FileSystemEntityType.file ||
                  type == FileSystemEntityType.link) {
                File(lockPath).deleteSync();
                removedAny = true;
              } else if (type == FileSystemEntityType.directory) {
                Directory(lockPath).deleteSync(recursive: true);
                removedAny = true;
              }
            }
            if (!removedAny) {
              skippedCount++;
              continue;
            }
          case AndroidEmulatorConfigIssueKind.avdHomeMissing:
          case AndroidEmulatorConfigIssueKind.avdDirectoryMissing:
          case AndroidEmulatorConfigIssueKind.configMissing:
          case AndroidEmulatorConfigIssueKind.systemImagePathMissing:
          case AndroidEmulatorConfigIssueKind.systemImageMissing:
            skippedCount++;
            continue;
        }
        repairedCount++;
        if (issue.requiresRestart) restartRequiredAvds.add(issue.avdName);
      } on FileSystemException {
        skippedCount++;
      }
    }

    final report = await inspectConfiguration();
    return AndroidEmulatorConfigRepairResult(
      repairedCount: repairedCount,
      skippedCount: skippedCount,
      backupDirectory: backupDirectory?.path,
      restartRequiredAvds: restartRequiredAvds.toList()..sort(),
      report: report,
    );
  }

  Future<List<String>> _knownAvdNames(Directory avdHome) async {
    final names = <String>{};
    try {
      names.addAll(await listAvdNames());
    } catch (_) {
      // Damaged descriptors can make emulator -list-avds fail; inspect disk too.
    }
    try {
      for (final entity in avdHome.listSync(followLinks: false)) {
        final basename = p.basename(entity.path);
        if (entity is File && basename.endsWith('.ini')) {
          names.add(basename.substring(0, basename.length - 4));
        } else if (entity is Directory && basename.endsWith('.avd')) {
          names.add(basename.substring(0, basename.length - 4));
        }
      }
    } on FileSystemException {
      // The caller will still receive names returned by emulator -list-avds.
    }
    return names.toList()..sort();
  }

  Future<Set<String>> _runningAvdNames() async {
    final names = <String>{};
    try {
      names.addAll((await _serialToAvd()).values);
    } catch (_) {
      // The runtime discovery files below also cover booting/offline emulators.
    }

    final directory = Directory(_emulatorDiscoveryDirectory);
    if (!directory.existsSync()) return names;
    try {
      for (final file in directory.listSync().whereType<File>()) {
        final match = RegExp(r'pid_(\d+)\.ini$').firstMatch(file.path);
        if (match == null) continue;
        final pid = int.tryParse(match.group(1)!);
        if (pid == null || !await _isProcessRunning(pid)) continue;
        final properties = _readProperties(file);
        final avdName = properties['avd.id'] ?? properties['avd.name'];
        if (avdName != null && avdName.isNotEmpty) names.add(avdName);
      }
    } on FileSystemException {
      return names;
    }
    return names;
  }

  Directory _resolveAvdDirectory({
    required String avdHome,
    required String avdName,
    required Map<String, String> descriptorProperties,
  }) {
    final defaultDirectory = Directory(p.join(avdHome, '$avdName.avd'));
    final configuredPath = descriptorProperties['path'];
    final configuredDirectory = configuredPath == null
        ? null
        : Directory(_descriptorPath(avdHome, configuredPath));
    final relativePath = descriptorProperties['path.rel'];
    final relativeDirectory = relativePath == null
        ? null
        : Directory(p.join(p.dirname(avdHome), relativePath));

    for (final candidate in [
      configuredDirectory,
      relativeDirectory,
      defaultDirectory,
    ]) {
      if (candidate?.existsSync() == true) return candidate!;
    }
    return configuredDirectory ?? relativeDirectory ?? defaultDirectory;
  }

  String _descriptorPath(String avdHome, String value) {
    return p.isAbsolute(value) ? value : p.join(avdHome, value);
  }

  String _canonicalPath(String value) {
    try {
      return File(value).resolveSymbolicLinksSync();
    } on FileSystemException {
      return p.normalize(p.absolute(value));
    }
  }

  bool _systemImageExists(String imagePath) {
    if (p.isAbsolute(imagePath)) {
      return Directory(imagePath).existsSync();
    }
    return _sdkRoots.any(
      (root) => Directory(p.join(root, imagePath)).existsSync(),
    );
  }

  String? _recoverSystemImagePath(String imagePath) {
    final normalized = imagePath.replaceAll(r'\', '/');
    final marker = normalized.indexOf('system-images/');
    if (marker < 0) return null;
    var relativePath = normalized.substring(marker);
    if (!_sdkRoots.any(
      (root) => Directory(p.join(root, relativePath)).existsSync(),
    )) {
      return null;
    }
    if (imagePath.endsWith('/') && !relativePath.endsWith('/')) {
      relativePath = '$relativePath/';
    }
    return relativePath;
  }

  List<String> _staleLockPaths(Directory avdDirectory, DateTime now) {
    const minimumAge = Duration(minutes: 5);
    final paths = <String>[];
    try {
      for (final entity in avdDirectory.listSync(followLinks: false)) {
        if (!p.basename(entity.path).endsWith('.lock')) continue;
        final modifiedAt = entity.statSync().modified;
        if (now.difference(modifiedAt) >= minimumAge) {
          paths.add(entity.path);
        }
      }
    } on FileSystemException {
      return paths;
    }
    paths.sort();
    return paths;
  }

  bool _isSafeLockPath(String avdDirectory, String lockPath) {
    if (!p.basename(lockPath).endsWith('.lock')) return false;
    final root = _canonicalPath(avdDirectory);
    final candidate = _canonicalPath(lockPath);
    return candidate.startsWith('$root${p.separator}');
  }

  bool _isStaleLockPath(String lockPath, DateTime now) {
    try {
      return now.difference(FileStat.statSync(lockPath).modified) >=
          const Duration(minutes: 5);
    } on FileSystemException {
      return false;
    }
  }

  Future<Directory> _createConfigBackupDirectory() async {
    final timestamp = _now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final directory = Directory(p.join(_configBackupDirectory, timestamp));
    await directory.create(recursive: true);
    return directory;
  }

  Future<void> _updateProperties(
    File file,
    Map<String, String> changes, {
    bool create = false,
  }) async {
    if (!file.existsSync() && !create) {
      throw FileSystemException('Configuration file not found', file.path);
    }
    if (create) await file.parent.create(recursive: true);
    final lines = file.existsSync() ? await file.readAsLines() : <String>[];
    final remaining = Map<String, String>.of(changes);
    final updated = <String>[];
    for (final line in lines) {
      final separator = line.indexOf('=');
      if (separator <= 0) {
        updated.add(line);
        continue;
      }
      final key = line.substring(0, separator).trim();
      final replacement = remaining.remove(key);
      updated.add(replacement == null ? line : '$key=$replacement');
    }
    for (final entry in remaining.entries) {
      updated.add('${entry.key}=${entry.value}');
    }
    await file.writeAsString('${updated.join('\n')}\n', flush: true);
  }

  Future<AndroidEmulator> _connectedDevice(String serial) async {
    Future<String?> property(String name) async {
      final result = await _runAdb(['-s', serial, 'shell', 'getprop', name]);
      final value = result.stdout.trim();
      return value.isEmpty ? null : value;
    }

    final values = await Future.wait([
      property('ro.product.manufacturer'),
      property('ro.product.model'),
      property('ro.build.version.sdk'),
      property('ro.product.cpu.abi'),
    ]);
    final manufacturer = values[0];
    final model = values[1];
    final displayName = <String?>[
      manufacturer,
      model != manufacturer ? model : null,
    ].whereType<String>().join(' ').trim();

    return AndroidEmulator(
      name: displayName.isEmpty ? serial : displayName,
      device: serial,
      target: values[2] == null ? null : 'API ${values[2]}',
      abi: values[3],
      isRunning: true,
      serial: serial,
      isAvd: false,
    );
  }

  // Launches detached, then waits until adb can map the serial back to the AVD.
  Future<void> boot(String avdName) async {
    final systemImage = _avdSystemImagePath(avdName);
    String? sdkRoot;
    String? emulator;
    File? temporaryLog;

    try {
      sdkRoot = sdkRootForAvd(avdName);
      if (sdkRoot == null) {
        final searched = _sdkRoots.isEmpty ? 'none' : _sdkRoots.join(', ');
        throw StateError(
          systemImage == null
              ? 'Android SDK with an emulator was not found. '
                    'Searched: $searched'
              : 'The AVD system image "$systemImage" was not found in any '
                    'Android SDK. Searched: $searched',
        );
      }
      emulator = '$sdkRoot/emulator/emulator';

      if ((await _serialToAvd()).containsValue(avdName)) return;

      final avdHome = _avdHome;
      final logDirectory = Directory(
        '${Directory.systemTemp.path}/mobile-dev-assistant',
      )..createSync(recursive: true);
      final safeName = _safeFileName(avdName);
      temporaryLog = File(
        '${logDirectory.path}/emulator-$safeName-'
        '${DateTime.now().millisecondsSinceEpoch}.log',
      );
      final process = await Process.start(
        '/bin/sh',
        [
          '-c',
          r'log=$1; shift; exec "$@" >"$log" 2>&1',
          'mobile-dev-assistant-emulator',
          temporaryLog.path,
          emulator,
          '-avd',
          avdName,
          '-no-boot-anim',
        ],
        mode: ProcessStartMode.detached,
        environment: {
          ...Platform.environment,
          'HOME': Platform.environment['HOME'] ?? avdHome ?? '',
          'PATH': _emulatorPathEnvironment(sdkRoot),
          'ANDROID_HOME': sdkRoot,
          'ANDROID_SDK_ROOT': sdkRoot,
          'ANDROID_AVD_HOME': ?avdHome,
        },
      );

      final deadline = DateTime.now().add(const Duration(seconds: 90));
      while (DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if ((await _serialToAvd()).containsValue(avdName)) {
          _deleteTemporaryLog(temporaryLog);
          return;
        }
        if (!await _isProcessRunning(process.pid)) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          throw StateError(
            _emulatorLaunchError(
              avdName: avdName,
              sdkRoot: sdkRoot,
              output: _readLaunchLog(temporaryLog),
            ),
          );
        }
      }
      Process.killPid(process.pid);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final output = _readLaunchLog(temporaryLog);
      throw TimeoutException(
        'Timed out waiting for $avdName to start with SDK $sdkRoot.'
        '${output.isEmpty ? '' : '\n$output'}',
      );
    } catch (error, stackTrace) {
      final logPath = await _persistLaunchFailure(
        avdName: avdName,
        sdkRoot: sdkRoot,
        systemImage: systemImage,
        emulator: emulator,
        temporaryLog: temporaryLog,
        error: error,
        stackTrace: stackTrace,
      );
      throw AndroidEmulatorLaunchException(
        message: error.toString(),
        logPath: logPath,
        cause: error,
      );
    } finally {
      _deleteTemporaryLog(temporaryLog);
    }
  }

  Future<void> revealDiagnosticLog(String path) async {
    final result = await _runner.run('/usr/bin/open', ['-R', path]);
    _throwIfFailed(result, fallback: 'Failed to reveal diagnostic log');
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

  Future<void> pressBack(String serial) => _sendKeyEvent(serial, 4);

  Future<void> pressHome(String serial) => _sendKeyEvent(serial, 3);

  Future<void> pressRecents(String serial) => _sendKeyEvent(serial, 187);

  Future<void> copySelection(String serial) async {
    await _sendKeyEvent(serial, 278);
    final endpoint = _emulatorGrpcEndpoint(serial);
    if (endpoint == null) return;

    await Future<void>.delayed(const Duration(milliseconds: 150));
    final text = await _getEmulatorClipboard(endpoint);
    if (text.isNotEmpty) await _writeHostClipboard(text);
  }

  Future<void> pasteClipboard(String serial) async {
    final endpoint = _emulatorGrpcEndpoint(serial);
    if (endpoint != null) {
      final clipboard = await _runner.run('/usr/bin/pbpaste', const []);
      _throwIfFailed(
        clipboard,
        fallback: 'Failed to read the computer clipboard',
      );
      if (clipboard.stdout.isEmpty) {
        throw StateError('The computer clipboard is empty');
      }
      await _setEmulatorClipboard(endpoint, clipboard.stdout);
    }
    await _sendKeyEvent(serial, 279);
  }

  Future<void> _sendKeyEvent(String serial, int keyCode) async {
    final result = await _runAdb([
      '-s',
      serial,
      'shell',
      'input',
      'keyevent',
      '$keyCode',
    ]);
    _throwIfFailed(result, fallback: 'Failed to send key event $keyCode');
  }

  bool hardwareKeyboardEnabled(String avdName) {
    final config = _avdConfigFile(avdName);
    if (config == null || !config.existsSync()) return false;
    return config.readAsLinesSync().any(
      (line) => line.trim() == 'hw.keyboard=yes',
    );
  }

  Future<void> enableHardwareKeyboard(String avdName) async {
    final config = _avdConfigFile(avdName);
    if (config == null || !await config.exists()) {
      throw StateError('AVD configuration not found: $avdName');
    }

    final lines = await config.readAsLines();
    var replaced = false;
    final updated = lines.map((line) {
      if (line.trimLeft().startsWith('hw.keyboard=')) {
        replaced = true;
        return 'hw.keyboard=yes';
      }
      return line;
    }).toList();
    if (!replaced) updated.add('hw.keyboard=yes');
    await config.writeAsString('${updated.join('\n')}\n', flush: true);
  }

  _EmulatorGrpcEndpoint? _emulatorGrpcEndpoint(String serial) {
    final serialPort = int.tryParse(serial.split('-').last);
    if (serialPort == null) return null;

    final directory = Directory(_emulatorDiscoveryDirectory);
    if (!directory.existsSync()) return null;
    try {
      for (final file in directory.listSync().whereType<File>()) {
        if (!file.path.endsWith('.ini')) continue;
        final properties = _readProperties(file);
        if (int.tryParse(properties['port.serial'] ?? '') != serialPort) {
          continue;
        }
        final grpcPort = int.tryParse(properties['grpc.port'] ?? '');
        final token = properties['grpc.token'];
        if (grpcPort != null && token != null && token.isNotEmpty) {
          return _EmulatorGrpcEndpoint(port: grpcPort, token: token);
        }
      }
    } on FileSystemException {
      return null;
    }
    return null;
  }

  Future<void> _setEmulatorClipboard(
    _EmulatorGrpcEndpoint endpoint,
    String text,
  ) async {
    final channel = ClientChannel(
      '127.0.0.1',
      port: endpoint.port,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    try {
      await _EmulatorControllerClient(
        channel,
      ).setClipboard(text, endpoint.token);
    } finally {
      await channel.shutdown();
    }
  }

  Future<String> _getEmulatorClipboard(_EmulatorGrpcEndpoint endpoint) async {
    final channel = ClientChannel(
      '127.0.0.1',
      port: endpoint.port,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    try {
      return await _EmulatorControllerClient(
        channel,
      ).getClipboard(endpoint.token);
    } finally {
      await channel.shutdown();
    }
  }

  Future<void> _writeHostClipboard(String text) async {
    final process = await Process.start('/usr/bin/pbcopy', const []);
    final stderr = process.stderr.transform(utf8.decoder).join();
    final stdout = process.stdout.drain<void>();
    process.stdin.add(utf8.encode(text));
    await process.stdin.close();
    await stdout;
    final error = await stderr;
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw StateError(
        error.trim().isEmpty
            ? 'Failed to write the computer clipboard'
            : error.trim(),
      );
    }
  }

  Map<String, String> _readProperties(File file) {
    final properties = <String, String>{};
    for (final line in file.readAsLinesSync()) {
      final separator = line.indexOf('=');
      if (separator <= 0) continue;
      properties[line.substring(0, separator).trim()] = line
          .substring(separator + 1)
          .trim();
    }
    return properties;
  }

  Future<void> reversePort(String serial, int port) async {
    final result = await _runAdb([
      '-s',
      serial,
      'reverse',
      'tcp:$port',
      'tcp:$port',
    ]);
    _throwIfFailed(result, fallback: 'Failed to reverse Metro port');
  }

  Future<void> openAdbShell(String serial, String title) async {
    final adb = _requireAdb();
    await _openTerminal(
      "${shellQuote(adb)} -s ${shellQuote(serial)} shell",
      title,
    );
  }

  Future<void> openLogcat(String serial, String title) async {
    final adb = _requireAdb();
    await _openTerminal(
      "${shellQuote(adb)} -s ${shellQuote(serial)} logcat -v threadtime",
      title,
    );
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

  Future<String?> chooseApk(String prompt) async {
    final script =
        'set selectedFile to choose file with prompt '
        '${appleScriptStringLiteral(prompt)} '
        // com.android.package-archive is an Android MIME type, not a macOS
        // UTI, so Finder disables real .apk files when it is used here.
        'of type {"public.data"}\n'
        'return POSIX path of selectedFile';
    final result = await _runner.run('/usr/bin/osascript', ['-e', script]);
    if (result.exitCode != 0) {
      final error = result.stderr.trim();
      if (error.contains('User canceled') || error.contains('-128')) {
        return null;
      }
      _throwIfFailed(result, fallback: 'Failed to choose APK');
    }
    final path = result.stdout.trim();
    return path.isEmpty ? null : path;
  }

  Future<void> installApk(String serial, String apkPath) async {
    final result = await _runAdb([
      '-s',
      serial,
      'install',
      '-r',
      '-d',
      apkPath,
    ]);
    _throwIfFailed(result, fallback: 'Failed to install APK');
  }

  Future<String> captureScreenshot(String serial, String deviceName) async {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      throw StateError('Home directory not found');
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final safeName = deviceName.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    final outputDirectory = Directory('$home/Desktop/Android Screenshots');
    await outputDirectory.create(recursive: true);

    final remotePath = '/sdcard/Download/cleanourmac-$timestamp.png';
    final localPath = '${outputDirectory.path}/$safeName-$timestamp.png';

    final capture = await _runAdb([
      '-s',
      serial,
      'shell',
      'screencap',
      '-p',
      remotePath,
    ]);
    _throwIfFailed(capture, fallback: 'Failed to capture screenshot');

    try {
      final pull = await _runAdb(['-s', serial, 'pull', remotePath, localPath]);
      _throwIfFailed(pull, fallback: 'Failed to save screenshot');
    } finally {
      await _runAdb(['-s', serial, 'shell', 'rm', '-f', remotePath]);
    }

    await _runner.run('/usr/bin/open', ['-R', localPath]);
    return localPath;
  }

  Future<void> restartAdb() async {
    final adb = _requireAdb();
    await _runner.run(adb, ['kill-server']);
    final result = await _runner.run(adb, ['start-server']);
    _throwIfFailed(result, fallback: 'Failed to start ADB server');
  }

  String _requireAdb() {
    final adb = adbBinary();
    if (adb == null) throw StateError('ADB not found');
    return adb;
  }

  Future<ShellResult> _runAdb(List<String> args) {
    return _runner.run(_requireAdb(), args);
  }

  void _throwIfFailed(ShellResult result, {required String fallback}) {
    if (result.exitCode == 0) return;
    final error = result.stderr.trim().isNotEmpty
        ? result.stderr.trim()
        : result.stdout.trim();
    throw StateError(error.isEmpty ? fallback : error);
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

  String? _firstSdkRootContaining(String relativePath) {
    for (final root in _sdkRoots) {
      if (File('$root/$relativePath').existsSync()) return root;
    }
    return null;
  }

  String? _avdSystemImagePath(String avdName) {
    final config = _avdConfigFile(avdName);
    if (config == null || !config.existsSync()) return null;
    return _readProperties(config)['image.sysdir.1'];
  }

  File? _avdConfigFile(String avdName) {
    final avdHome = _avdHome;
    if (avdHome == null) return null;
    final descriptor = File(p.join(avdHome, '$avdName.ini'));
    final properties = descriptor.existsSync()
        ? _readProperties(descriptor)
        : const <String, String>{};
    final directory = _resolveAvdDirectory(
      avdHome: avdHome,
      avdName: avdName,
      descriptorProperties: properties,
    );
    return File(p.join(directory.path, 'config.ini'));
  }

  List<String> _androidStudioSdkRoots(String home) {
    final google = Directory('$home/Library/Application Support/Google');
    if (!google.existsSync()) return const [];

    final roots = <String>[];
    try {
      final studios =
          google
              .listSync(followLinks: false)
              .whereType<Directory>()
              .where(
                (directory) =>
                    directory.path.split('/').last.startsWith('AndroidStudio'),
              )
              .toList()
            ..sort(
              (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
            );
      final valuePattern = RegExp(r'androidSdkAbsolutePath"\s+value="([^"]+)"');
      for (final studio in studios) {
        final settings = File('${studio.path}/options/android.sdk.path.xml');
        if (!settings.existsSync()) continue;
        final match = valuePattern.firstMatch(settings.readAsStringSync());
        if (match?.group(1) != null) roots.add(match!.group(1)!);
      }
    } on FileSystemException {
      return roots;
    }
    return roots;
  }

  String _normalizePath(String? path) {
    if (path == null) return '';
    if (path == '~') return Platform.environment['HOME'] ?? path;
    if (path.startsWith('~/')) {
      return '${Platform.environment['HOME'] ?? ''}/${path.substring(2)}';
    }
    return Directory(path).absolute.path;
  }

  Future<bool> _isProcessRunning(int pid) async {
    final result = await Process.run('/bin/kill', ['-0', '$pid']);
    return result.exitCode == 0;
  }

  String _readLaunchLog(File logFile) {
    if (!logFile.existsSync()) return '';
    final contents = logFile.readAsStringSync().trim();
    const maxLength = 12000;
    return contents.length <= maxLength
        ? contents
        : contents.substring(contents.length - maxLength);
  }

  Future<String> _persistLaunchFailure({
    required String avdName,
    required String? sdkRoot,
    required String? systemImage,
    required String? emulator,
    required File? temporaryLog,
    required Object error,
    required StackTrace stackTrace,
  }) async {
    final directory = Directory(_diagnosticLogDirectory);
    await directory.create(recursive: true);
    final timestamp = DateTime.now();
    final fileTimestamp = timestamp
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final logFile = File(
      '${directory.path}/android-emulator-${_safeFileName(avdName)}-'
      '$fileTimestamp.log',
    );
    final emulatorOutput = temporaryLog == null
        ? ''
        : _readLaunchLog(temporaryLog);
    final searchedRoots = _sdkRoots.isEmpty ? 'none' : _sdkRoots.join(', ');
    final buffer = StringBuffer()
      ..writeln('Mobile 开发助手 - Android Emulator Startup Failure')
      ..writeln('Timestamp: ${timestamp.toIso8601String()}')
      ..writeln('AVD: $avdName')
      ..writeln('SDK root: ${sdkRoot ?? 'unavailable'}')
      ..writeln('Searched SDK roots: $searchedRoots')
      ..writeln('AVD home: ${_avdHome ?? 'unavailable'}')
      ..writeln('System image: ${systemImage ?? 'unavailable'}')
      ..writeln('Emulator binary: ${emulator ?? 'unavailable'}')
      ..writeln(
        'Command: ${emulator == null ? 'unavailable' : '$emulator -avd $avdName -no-boot-anim'}',
      )
      ..writeln()
      ..writeln('Failure:')
      ..writeln(error)
      ..writeln()
      ..writeln('Emulator output:')
      ..writeln(emulatorOutput.isEmpty ? '(no output)' : emulatorOutput)
      ..writeln()
      ..writeln('Stack trace:')
      ..writeln(stackTrace);
    await logFile.writeAsString(buffer.toString(), flush: true);
    return logFile.path;
  }

  String get _diagnosticLogDirectory {
    final override = _diagnosticLogDirectoryOverride;
    if (override != null && override.isNotEmpty) return override;
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      return '${Directory.systemTemp.path}/Mobile 开发助手/Android Emulator';
    }
    return '$home/Library/Logs/Mobile 开发助手/Android Emulator';
  }

  String get _emulatorDiscoveryDirectory {
    final override = _emulatorDiscoveryDirectoryOverride;
    if (override != null && override.isNotEmpty) return override;
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) return '';
    return '$home/Library/Caches/TemporaryItems/avd/running';
  }

  String _emulatorPathEnvironment(String sdkRoot) {
    final existing = Platform.environment['PATH'] ?? '';
    return [
      '$sdkRoot/platform-tools',
      '$sdkRoot/emulator',
      existing,
    ].where((part) => part.isNotEmpty).join(':');
  }

  String get _configBackupDirectory {
    final override = _configBackupDirectoryOverride;
    if (override != null && override.isNotEmpty) return override;
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      return p.join(
        Directory.systemTemp.path,
        'Mobile 开发助手',
        'Android Emulator Backups',
      );
    }
    return p.join(
      home,
      'Library',
      'Application Support',
      'Mobile 开发助手',
      'Android Emulator Backups',
    );
  }

  String _safeFileName(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');

  void _deleteTemporaryLog(File? logFile) {
    if (logFile == null) return;
    try {
      if (logFile.existsSync()) logFile.deleteSync();
    } catch (_) {
      // Temporary launch output is best-effort cleanup.
    }
  }

  String _emulatorLaunchError({
    required String avdName,
    required String sdkRoot,
    required String output,
  }) {
    final details = output.trim();
    return 'Android emulator "$avdName" exited during startup '
        'using SDK "$sdkRoot".'
        '${details.isEmpty ? '' : '\n$details'}';
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
