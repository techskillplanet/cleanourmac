import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/data/repositories/react_native_repository.dart';
import 'package:mac_tool/data/shell/shell_runner.dart';
import 'package:mac_tool/domain/models/react_native_project.dart';
import 'package:mac_tool/providers/react_native_providers.dart';

class _RecordingRunner extends ShellRunner {
  final List<(String, List<String>)> commands = [];
  final ShellResult Function(String executable, List<String> args)? responder;

  _RecordingRunner({this.responder});

  @override
  Future<ShellResult> run(
    String executable,
    List<String> args, {
    Map<String, String>? environment,
  }) async {
    commands.add((executable, List.of(args)));
    return responder?.call(executable, args) ?? const ShellResult('', '', 0);
  }
}

class _SlowReactNativeRepository extends ReactNativeRepository {
  final ReactNativeProject project;
  int activeDiscoveries = 0;
  int maxActiveDiscoveries = 0;
  int discoveryCount = 0;
  int activeMetroChecks = 0;
  int maxActiveMetroChecks = 0;
  int metroCheckCount = 0;

  _SlowReactNativeRepository(this.project)
    : super(
        Directory.systemTemp.path,
        _RecordingRunner(),
        projectSearchRoots: const [],
      );

  @override
  Future<List<ReactNativeProject>> discover(
    List<String> configuredRoots, {
    int defaultMetroPort = 8081,
  }) async {
    discoveryCount++;
    activeDiscoveries++;
    if (activeDiscoveries > maxActiveDiscoveries) {
      maxActiveDiscoveries = activeDiscoveries;
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));
    activeDiscoveries--;
    return [project];
  }

  @override
  Future<List<ProjectOpenOption>> availableOpenOptions(
    ReactNativeProject project,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return [
      ProjectOpenOption(
        target: ProjectOpenTarget.finder,
        openPath: project.path,
      ),
    ];
  }

  @override
  Future<MetroStatus> checkMetro(int port) async {
    metroCheckCount++;
    activeMetroChecks++;
    if (activeMetroChecks > maxActiveMetroChecks) {
      maxActiveMetroChecks = activeMetroChecks;
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));
    activeMetroChecks--;
    return MetroStatus(running: false, port: port);
  }
}

void main() {
  group('ReactNativeRepository', () {
    late Directory home;
    late Directory project;
    late Directory applications;

    setUp(() {
      home = Directory.systemTemp.createTempSync('rn-workspace-home-');
      project = Directory('${home.path}/Projects/demo')
        ..createSync(recursive: true);
      Directory('${project.path}/android').createSync(recursive: true);
      File('${project.path}/android/settings.gradle').writeAsStringSync('');
      Directory(
        '${project.path}/ios/Demo.xcworkspace',
      ).createSync(recursive: true);
      applications = Directory('${home.path}/Applications')
        ..createSync(recursive: true);
      File('${project.path}/package.json').writeAsStringSync(
        jsonEncode({
          'name': 'demo-mobile',
          'dependencies': {'react-native': '0.82.0'},
          'scripts': {
            'start': 'react-native start --port 8090',
            'android': 'react-native run-android',
            'ios': 'react-native run-ios',
            'charles': 'node scripts/charles.js',
          },
        }),
      );
      File('${project.path}/yarn.lock').writeAsStringSync('');
    });

    tearDown(() {
      if (home.existsSync()) home.deleteSync(recursive: true);
    });

    test(
      'discovers projects, scripts, package manager, and Metro port',
      () async {
        final repository = ReactNativeRepository(
          home.path,
          _RecordingRunner(),
          projectSearchRoots: ['${home.path}/Projects'],
        );

        final projects = await repository.discover([]);

        final discovered = projects.firstWhere(
          (item) => item.name == 'demo-mobile',
        );
        expect(discovered.packageManager, JavaScriptPackageManager.yarn);
        expect(discovered.metroPort, 8090);
        expect(discovered.hasScript('charles'), isTrue);
      },
    );

    test('ignores configured projects deleted before refresh', () async {
      final deleted = Directory('${home.path}/Projects/deleted')
        ..createSync(recursive: true);
      deleted.deleteSync(recursive: true);
      final repository = ReactNativeRepository(
        home.path,
        _RecordingRunner(),
        projectSearchRoots: const [],
      );
      final watch = Stopwatch()..start();

      final projects = await repository.discover([deleted.path]);

      expect(projects, isEmpty);
      expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
    });

    test('opens frequent scripts in a project-scoped Terminal', () async {
      final runner = _RecordingRunner();
      final repository = ReactNativeRepository(home.path, runner);
      final loaded = await repository.loadProject(project.path);

      await repository.runScript(loaded!, 'android');

      expect(runner.commands, hasLength(1));
      expect(runner.commands.single.$1, '/usr/bin/osascript');
      final script = runner.commands.single.$2[1];
      expect(script, contains('RN android · demo-mobile'));
      expect(script, contains('yarn'));
      expect(script, contains('android'));
      expect(script, contains(project.path));
    });

    test(
      'lists only installed project openers and resolves native subprojects',
      () async {
        for (final name in [
          'Codex.app',
          'Cursor.app',
          'Android Studio.app',
          'Qoder.app',
          'TRAE SOLO CN.app',
          'WebStorm.app',
          'Xcode.app',
        ]) {
          Directory('${applications.path}/$name').createSync();
        }

        final repository = ReactNativeRepository(
          home.path,
          _RecordingRunner(),
          applicationRoots: [applications.path],
          codexCliPath: '${applications.path}/codex',
        );
        File('${applications.path}/codex').writeAsStringSync('');
        final loaded = await repository.loadProject(project.path);
        final options = await repository.availableOpenOptions(loaded!);
        final targets = options.map((option) => option.target).toSet();

        expect(targets, contains(ProjectOpenTarget.codexDesktop));
        expect(targets, contains(ProjectOpenTarget.codexCli));
        expect(targets, contains(ProjectOpenTarget.cursor));
        expect(targets, contains(ProjectOpenTarget.androidStudio));
        expect(targets, contains(ProjectOpenTarget.xcode));
        expect(targets, contains(ProjectOpenTarget.qoder));
        expect(targets, contains(ProjectOpenTarget.trae));
        expect(targets, contains(ProjectOpenTarget.webStorm));
        expect(targets, contains(ProjectOpenTarget.finder));
        expect(targets, contains(ProjectOpenTarget.terminal));

        final android = options.firstWhere(
          (option) => option.target == ProjectOpenTarget.androidStudio,
        );
        final xcode = options.firstWhere(
          (option) => option.target == ProjectOpenTarget.xcode,
        );
        expect(android.openPath, '${loaded.path}/android');
        expect(xcode.openPath, '${loaded.path}/ios/Demo.xcworkspace');
      },
    );

    test('opens Codex Desktop with the selected project path', () async {
      Directory('${applications.path}/Codex.app').createSync();
      File('${applications.path}/codex').writeAsStringSync('');
      final runner = _RecordingRunner();
      final repository = ReactNativeRepository(
        home.path,
        runner,
        applicationRoots: [applications.path],
        codexCliPath: '${applications.path}/codex',
      );
      final loaded = await repository.loadProject(project.path);

      await repository.openProject(loaded!, ProjectOpenTarget.codexDesktop);

      expect(runner.commands.single.$1, '/usr/bin/open');
      expect(runner.commands.single.$2, [
        '-a',
        '${applications.path}/Codex.app',
        loaded.path,
      ]);
    });

    test('monitors a running Metro status endpoint', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) {
        request.response
          ..statusCode = HttpStatus.ok
          ..write('packager-status:running')
          ..close();
      });

      final runner = _RecordingRunner(
        responder: (_, args) => args.isNotEmpty && args.first == '-nP'
            ? const ShellResult(
                'COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME\n'
                    'node 4242 user 24u IPv4 0 0t0 TCP 127.0.0.1:8081 (LISTEN)\n',
                '',
                0,
              )
            : const ShellResult('', '', 0),
      );
      final repository = ReactNativeRepository(home.path, runner);

      final status = await repository.checkMetro(server.port);

      expect(status.running, isTrue);
      expect(status.port, server.port);
      expect(status.pid, 4242);
      expect(status.processName, 'node');
    });

    test('coalesces overlapping project and Metro refreshes', () async {
      final loaded = await ReactNativeRepository(
        home.path,
        _RecordingRunner(),
      ).loadProject(project.path);
      final repository = _SlowReactNativeRepository(loaded!);
      final notifier = ReactNativeWorkspaceNotifier(
        repository,
        const [],
        8081,
        autoStart: false,
        refreshInterval: null,
      );
      addTearDown(notifier.dispose);

      final firstRefresh = notifier.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await Future.wait([firstRefresh, notifier.refresh(), notifier.refresh()]);

      final firstMetro = notifier.refreshMetro();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await Future.wait([
        firstMetro,
        notifier.refreshMetro(),
        notifier.refreshMetro(),
      ]);

      expect(repository.maxActiveDiscoveries, 1);
      expect(repository.discoveryCount, 2);
      expect(repository.maxActiveMetroChecks, 1);
      expect(repository.metroCheckCount, greaterThanOrEqualTo(2));
    });
  });
}
