import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import '../../domain/models/react_native_project.dart';
import '../shell/shell_escape.dart';
import '../shell/shell_runner.dart';

class ReactNativeRepository {
  final String _home;
  final ShellRunner _runner;
  final List<String>? _applicationRootsOverride;
  final String? _codexCliPathOverride;
  final List<String>? _projectSearchRootsOverride;

  ReactNativeRepository(
    this._home,
    this._runner, {
    List<String>? applicationRoots,
    String? codexCliPath,
    List<String>? projectSearchRoots,
  }) : _applicationRootsOverride = applicationRoots,
       _codexCliPathOverride = codexCliPath,
       _projectSearchRootsOverride = projectSearchRoots;

  Future<List<ReactNativeProject>> discover(
    List<String> configuredRoots, {
    int defaultMetroPort = 8081,
  }) {
    final home = _home;
    final configuredApplicationRoots = _applicationRootsOverride;
    final applicationRoots = configuredApplicationRoots == null
        ? null
        : List<String>.from(configuredApplicationRoots);
    final configuredProjectSearchRoots = _projectSearchRootsOverride;
    final projectSearchRoots = configuredProjectSearchRoots == null
        ? null
        : List<String>.from(configuredProjectSearchRoots);
    final codexCliPath = _codexCliPathOverride;
    final roots = List<String>.from(configuredRoots);
    return Isolate.run(
      () => ReactNativeRepository(
        home,
        ShellRunner(),
        applicationRoots: applicationRoots,
        codexCliPath: codexCliPath,
        projectSearchRoots: projectSearchRoots,
      )._discover(roots, defaultMetroPort: defaultMetroPort),
    );
  }

  Future<List<ReactNativeProject>> _discover(
    List<String> configuredRoots, {
    required int defaultMetroPort,
  }) async {
    final candidates = <String>{};

    for (final root in configuredRoots) {
      final project = await _loadProject(
        root,
        defaultMetroPort: defaultMetroPort,
      );
      if (project != null) candidates.add(project.path);
    }

    for (final root in await _conventionalSearchRoots()) {
      candidates.addAll(await _findPackageRoots(root, maxDepth: 2));
    }

    final projects = <ReactNativeProject>[];
    for (final path in candidates) {
      final project = await _loadProject(
        path,
        defaultMetroPort: defaultMetroPort,
      );
      if (project != null) projects.add(project);
    }

    projects.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return projects;
  }

  Future<ReactNativeProject?> loadProject(
    String rawPath, {
    int defaultMetroPort = 8081,
  }) {
    final home = _home;
    final path = rawPath;
    return Isolate.run(
      () => ReactNativeRepository(
        home,
        ShellRunner(),
      )._loadProject(path, defaultMetroPort: defaultMetroPort),
    );
  }

  Future<ReactNativeProject?> _loadProject(
    String rawPath, {
    required int defaultMetroPort,
  }) async {
    final directory = Directory(rawPath);
    if (!await _directoryExists(directory)) return null;
    final packageFile = File('${directory.path}/package.json');
    if (!await _fileExists(packageFile)) return null;

    try {
      final data =
          jsonDecode(await packageFile.readAsString()) as Map<String, dynamic>;
      final scripts = (data['scripts'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, value.toString()),
      );
      final dependencies = <String, dynamic>{
        ...?data['dependencies'] as Map<String, dynamic>?,
        ...?data['devDependencies'] as Map<String, dynamic>?,
      };
      final looksLikeReactNative =
          dependencies.containsKey('react-native') ||
          scripts.containsKey('android') ||
          scripts.containsKey('ios') ||
          (scripts.containsKey('start') &&
              scripts['start']!.contains('react-native'));
      if (!looksLikeReactNative) return null;

      final resolvedPath = await _resolve(directory.path);
      return ReactNativeProject(
        path: resolvedPath,
        name: (data['name'] as String?)?.trim().isNotEmpty == true
            ? (data['name'] as String).trim()
            : resolvedPath.split('/').last,
        scripts: scripts,
        packageManager: await _detectPackageManager(
          directory,
          data['packageManager'] as String?,
        ),
        metroPort: _inferMetroPort(
          scripts['start'],
          fallback: defaultMetroPort,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> chooseProject(String prompt) async {
    final script =
        'set selectedFolder to choose folder with prompt '
        '${appleScriptStringLiteral(prompt)}\n'
        'return POSIX path of selectedFolder';
    final result = await _runner.run('/usr/bin/osascript', ['-e', script]);
    if (result.exitCode != 0) {
      final error = result.stderr.trim();
      if (error.contains('User canceled') || error.contains('-128')) {
        return null;
      }
      _throwIfFailed(result, fallback: 'Failed to choose project');
    }
    final path = result.stdout.trim();
    return path.isEmpty ? null : path;
  }

  Future<void> runScript(ReactNativeProject project, String script) {
    if (!project.hasScript(script)) {
      throw StateError('Script "$script" not found');
    }
    final command = _scriptCommand(project.packageManager, script);
    final title = script == 'start'
        ? metroTerminalTitle(project)
        : 'RN $script · ${project.name}';
    return _openTerminal(project.path, command, title);
  }

  Future<void> startMetroReset(ReactNativeProject project) {
    if (!project.hasScript('start')) {
      throw StateError('Script "start" not found');
    }
    final command =
        '${_scriptCommand(project.packageManager, 'start')} --reset-cache';
    return _openTerminal(
      project.path,
      command,
      '${metroTerminalTitle(project)} · Reset',
    );
  }

  Future<void> openReactNativeDevTools(ReactNativeProject project) async {
    final title = metroTerminalTitle(project);
    final script =
        'tell application "Terminal"\n'
        'activate\n'
        'set matchedWindow to missing value\n'
        'repeat with terminalWindow in windows\n'
        'if name of terminalWindow contains '
        '${appleScriptStringLiteral(title)} then\n'
        'set matchedWindow to terminalWindow\n'
        'exit repeat\n'
        'end if\n'
        'end repeat\n'
        'if matchedWindow is missing value then error '
        '${appleScriptStringLiteral('Metro terminal not found')}\n'
        'set index of matchedWindow to 1\n'
        'end tell\n'
        'tell application "System Events" to keystroke "j"';
    final result = await _runner.run('/usr/bin/osascript', ['-e', script]);
    _throwIfFailed(result, fallback: 'Failed to open React Native DevTools');
  }

  Future<List<ProjectOpenOption>> availableOpenOptions(
    ReactNativeProject project,
  ) {
    final home = _home;
    final configuredApplicationRoots = _applicationRootsOverride;
    final applicationRoots = configuredApplicationRoots == null
        ? null
        : List<String>.from(configuredApplicationRoots);
    final configuredProjectSearchRoots = _projectSearchRootsOverride;
    final projectSearchRoots = configuredProjectSearchRoots == null
        ? null
        : List<String>.from(configuredProjectSearchRoots);
    final codexCliPath = _codexCliPathOverride;
    return Isolate.run(
      () => ReactNativeRepository(
        home,
        ShellRunner(),
        applicationRoots: applicationRoots,
        codexCliPath: codexCliPath,
        projectSearchRoots: projectSearchRoots,
      )._availableOpenOptions(project),
    );
  }

  Future<List<ProjectOpenOption>> _availableOpenOptions(
    ReactNativeProject project,
  ) async {
    final options = <ProjectOpenOption>[];
    final applicationRoots = await _applicationRoots();

    Future<void> addApplication(
      ProjectOpenTarget target,
      List<String> applicationNames, {
      String? openPath,
    }) async {
      final applicationPath = await _findApplication(
        applicationNames,
        applicationRoots,
      );
      if (applicationPath == null) return;
      options.add(
        ProjectOpenOption(
          target: target,
          applicationPath: applicationPath,
          openPath: openPath ?? project.path,
        ),
      );
    }

    await addApplication(ProjectOpenTarget.codexDesktop, const ['Codex.app']);
    if (await _findCodexCli() != null) {
      options.add(
        ProjectOpenOption(
          target: ProjectOpenTarget.codexCli,
          openPath: project.path,
        ),
      );
    }
    await addApplication(ProjectOpenTarget.cursor, const ['Cursor.app']);
    await addApplication(ProjectOpenTarget.visualStudioCode, const [
      'Visual Studio Code.app',
      'Code.app',
    ]);
    await addApplication(ProjectOpenTarget.qoder, const ['Qoder.app']);
    await addApplication(ProjectOpenTarget.trae, const [
      'TRAE SOLO CN.app',
      'Trae.app',
      'Trae CN.app',
    ]);
    await addApplication(ProjectOpenTarget.webStorm, const ['WebStorm.app']);
    await addApplication(ProjectOpenTarget.zed, const ['Zed.app']);
    await addApplication(ProjectOpenTarget.windsurf, const ['Windsurf.app']);

    final androidProject = await _findAndroidProject(project.path);
    if (androidProject != null) {
      await addApplication(ProjectOpenTarget.androidStudio, const [
        'Android Studio.app',
      ], openPath: androidProject);
    }

    final xcodeProject = await _findXcodeProject(project.path);
    if (xcodeProject != null) {
      await addApplication(ProjectOpenTarget.xcode, const [
        'Xcode.app',
      ], openPath: xcodeProject);
    }

    options.add(
      ProjectOpenOption(
        target: ProjectOpenTarget.finder,
        openPath: project.path,
      ),
    );
    options.add(
      ProjectOpenOption(
        target: ProjectOpenTarget.terminal,
        openPath: project.path,
      ),
    );
    return options;
  }

  Future<void> openProject(
    ReactNativeProject project,
    ProjectOpenTarget target,
  ) async {
    final option = (await availableOpenOptions(
      project,
    )).where((item) => item.target == target);
    if (option.isEmpty) throw StateError('Application is not available');
    final selected = option.first;

    if (target == ProjectOpenTarget.terminal) {
      final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
      await _openTerminal(
        project.path,
        '${shellQuote(shell)} -l',
        'Terminal · ${project.name}',
      );
      return;
    }
    if (target == ProjectOpenTarget.codexCli) {
      final codex = await _findCodexCli();
      if (codex == null) throw StateError('Codex CLI is not available');
      await _openTerminal(
        project.path,
        '${shellQuote(codex)} --cd ${shellQuote(project.path)}',
        'Codex CLI · ${project.name}',
      );
      return;
    }

    final args = <String>[
      if (selected.applicationPath != null) ...[
        '-a',
        selected.applicationPath!,
      ],
      selected.openPath,
    ];
    final result = await _runner.run('/usr/bin/open', args);
    _throwIfFailed(result, fallback: 'Failed to open project');
  }

  Future<MetroStatus> checkMetro(int port) async {
    var running = false;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 1);
    try {
      final request = await client
          .getUrl(Uri.parse('http://127.0.0.1:$port/status'))
          .timeout(const Duration(seconds: 1));
      final response = await request.close().timeout(
        const Duration(seconds: 1),
      );
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 1));
      running =
          response.statusCode == HttpStatus.ok &&
          body.toLowerCase().contains('packager-status:running');
    } catch (_) {
      running = false;
    } finally {
      client.close(force: true);
    }

    if (!running) return MetroStatus(running: false, port: port);

    final lsof = await _runner.run('/usr/sbin/lsof', [
      '-nP',
      '-iTCP:$port',
      '-sTCP:LISTEN',
    ]);
    final lines = lsof.stdout
        .split(RegExp(r'\r?\n'))
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.length < 2) return MetroStatus(running: true, port: port);

    final parts = lines[1].trim().split(RegExp(r'\s+'));
    return MetroStatus(
      running: true,
      port: port,
      processName: parts.isEmpty ? null : parts.first,
      pid: parts.length < 2 ? null : int.tryParse(parts[1]),
    );
  }

  String metroTerminalTitle(ReactNativeProject project) =>
      'RN Metro · ${project.name}';

  Future<String?> _findApplication(
    List<String> names,
    List<String> roots,
  ) async {
    for (final root in roots) {
      for (final name in names) {
        final candidate = Directory('$root/$name');
        if (await _directoryExists(candidate)) return candidate.path;
      }
    }
    return null;
  }

  Future<String?> _findCodexCli() async {
    final override = _codexCliPathOverride;
    if (override != null && await _fileExists(File(override))) return override;
    final candidates = <String>[
      '$_home/.local/bin/codex',
      '$_home/.nvm/versions/node/current/bin/codex',
      '/usr/local/bin/codex',
      '/opt/homebrew/bin/codex',
      '/Volumes/outmount/Applications/Codex.app/Contents/Resources/codex',
    ];
    for (final candidate in candidates) {
      if (await _fileExists(File(candidate))) return candidate;
    }
    return null;
  }

  Future<List<String>> _applicationRoots() async {
    final override = _applicationRootsOverride;
    if (override != null) return override;
    final roots = <String>['/Applications', '$_home/Applications'];
    final volumes = Directory('/Volumes');
    if (await _directoryExists(volumes)) {
      for (final volume in (await _listDirectory(
        volumes,
      )).whereType<Directory>()) {
        final applications = Directory('${volume.path}/Applications');
        if (await _directoryExists(applications)) roots.add(applications.path);
      }
    }
    return roots;
  }

  Future<String?> _findAndroidProject(String projectPath) async {
    final matches = await _findProjectArtifacts(
      projectPath,
      (name) => name == 'settings.gradle' || name == 'settings.gradle.kts',
      maxDepth: 4,
    );
    if (matches.isEmpty) return null;
    matches.sort((a, b) => a.length.compareTo(b.length));
    return File(matches.first).parent.path;
  }

  Future<String?> _findXcodeProject(String projectPath) async {
    final workspaces = await _findProjectArtifacts(
      projectPath,
      (name) => name.endsWith('.xcworkspace'),
      maxDepth: 4,
      directoriesOnly: true,
    );
    final projects = await _findProjectArtifacts(
      projectPath,
      (name) => name.endsWith('.xcodeproj'),
      maxDepth: 4,
      directoriesOnly: true,
    );
    final matches = workspaces.isNotEmpty ? workspaces : projects;
    if (matches.isEmpty) return null;
    matches.sort((a, b) => a.length.compareTo(b.length));
    return matches.first;
  }

  Future<List<String>> _findProjectArtifacts(
    String root,
    bool Function(String name) matches, {
    required int maxDepth,
    bool directoriesOnly = false,
  }) async {
    final result = <String>[];

    final deadline = DateTime.now().add(const Duration(seconds: 3));
    var visitedDirectories = 0;

    Future<void> visit(Directory directory, int depth) async {
      if (depth > maxDepth) return;
      if (DateTime.now().isAfter(deadline) || visitedDirectories >= 1200) {
        return;
      }
      visitedDirectories++;
      for (final entity in await _listDirectory(directory)) {
        final name = entity.path.split('/').last;
        if (name == 'node_modules' ||
            name == 'Pods' ||
            name == 'build' ||
            name.startsWith('.')) {
          continue;
        }
        if (matches(name) && (!directoriesOnly || entity is Directory)) {
          result.add(entity.path);
        }
        if (entity is Directory && !matches(name)) {
          await visit(entity, depth + 1);
        }
      }
    }

    if (await _directoryExists(Directory(root))) {
      await visit(Directory(root), 0);
    }
    return result;
  }

  Future<List<String>> _conventionalSearchRoots() async {
    final override = _projectSearchRootsOverride;
    if (override != null) {
      final existing = <String>[];
      for (final root in override) {
        if (await _directoryExists(Directory(root))) existing.add(root);
      }
      return existing;
    }

    final roots = <String>[
      '$_home/Projects',
      '$_home/Developer',
      '$_home/StudioProjects',
    ];
    final volumes = Directory('/Volumes');
    if (await _directoryExists(volumes)) {
      for (final volume in (await _listDirectory(
        volumes,
      )).whereType<Directory>()) {
        final code = Directory('${volume.path}/code');
        if (await _directoryExists(code)) roots.add(code.path);
      }
    }
    final existing = <String>[];
    for (final root in roots) {
      if (await _directoryExists(Directory(root))) existing.add(root);
    }
    return existing;
  }

  Future<Set<String>> _findPackageRoots(
    String root, {
    required int maxDepth,
  }) async {
    final result = <String>{};
    final deadline = DateTime.now().add(const Duration(seconds: 4));
    var visitedDirectories = 0;

    Future<void> visit(Directory directory, int depth) async {
      if (DateTime.now().isAfter(deadline) || visitedDirectories >= 1500) {
        return;
      }
      visitedDirectories++;
      if (await _fileExists(File('${directory.path}/package.json'))) {
        result.add(directory.path);
      }
      if (depth >= maxDepth) return;
      for (final child in (await _listDirectory(
        directory,
      )).whereType<Directory>()) {
        final name = child.path.split('/').last;
        if (name.startsWith('.') ||
            name == 'node_modules' ||
            name == 'build' ||
            name == 'Pods') {
          continue;
        }
        await visit(child, depth + 1);
      }
    }

    if (await _directoryExists(Directory(root))) {
      await visit(Directory(root), 0);
    }
    return result;
  }

  Future<JavaScriptPackageManager> _detectPackageManager(
    Directory project,
    String? declared,
  ) async {
    final value = declared?.toLowerCase() ?? '';
    if (value.startsWith('pnpm')) return JavaScriptPackageManager.pnpm;
    if (value.startsWith('bun')) return JavaScriptPackageManager.bun;
    if (value.startsWith('npm')) return JavaScriptPackageManager.npm;
    if (value.startsWith('yarn')) return JavaScriptPackageManager.yarn;
    if (await _fileExists(File('${project.path}/pnpm-lock.yaml'))) {
      return JavaScriptPackageManager.pnpm;
    }
    if (await _fileExists(File('${project.path}/bun.lock')) ||
        await _fileExists(File('${project.path}/bun.lockb'))) {
      return JavaScriptPackageManager.bun;
    }
    if (await _fileExists(File('${project.path}/package-lock.json'))) {
      return JavaScriptPackageManager.npm;
    }
    return JavaScriptPackageManager.yarn;
  }

  int _inferMetroPort(String? startScript, {required int fallback}) {
    if (startScript == null) return fallback;
    final match = RegExp(r'--port(?:=|\s+)(\d+)').firstMatch(startScript);
    return int.tryParse(match?.group(1) ?? '') ?? fallback;
  }

  String _scriptCommand(JavaScriptPackageManager manager, String script) {
    final quoted = shellQuote(script);
    return switch (manager) {
      JavaScriptPackageManager.yarn => 'yarn $quoted',
      JavaScriptPackageManager.npm => 'npm run $quoted',
      JavaScriptPackageManager.pnpm => 'pnpm $quoted',
      JavaScriptPackageManager.bun => 'bun run $quoted',
    };
  }

  Future<void> _openTerminal(
    String workingDirectory,
    String command,
    String title,
  ) async {
    final titledCommand =
        "printf '\\033]0;%s\\007' ${shellQuote(title)}; "
        'cd ${shellQuote(workingDirectory)} && exec $command';
    final script =
        'tell application "Terminal"\n'
        'activate\n'
        'do script ${appleScriptStringLiteral(titledCommand)}\n'
        'end tell';
    final result = await _runner.run('/usr/bin/osascript', ['-e', script]);
    _throwIfFailed(result, fallback: 'Failed to open Terminal');
  }

  Future<String> _resolve(String path) async {
    try {
      return await Directory(
        path,
      ).resolveSymbolicLinks().timeout(const Duration(seconds: 2));
    } catch (_) {
      return Directory(path).absolute.path;
    }
  }

  Future<bool> _directoryExists(Directory directory) async {
    try {
      return await directory.exists().timeout(const Duration(seconds: 2));
    } catch (_) {
      return false;
    }
  }

  Future<bool> _fileExists(File file) async {
    try {
      return await file.exists().timeout(const Duration(seconds: 2));
    } catch (_) {
      return false;
    }
  }

  Future<List<FileSystemEntity>> _listDirectory(Directory directory) async {
    try {
      return await directory
          .list(followLinks: false)
          .timeout(const Duration(seconds: 2))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void _throwIfFailed(ShellResult result, {required String fallback}) {
    if (result.exitCode == 0) return;
    final error = result.stderr.trim().isNotEmpty
        ? result.stderr.trim()
        : result.stdout.trim();
    throw StateError(error.isEmpty ? fallback : error);
  }
}
