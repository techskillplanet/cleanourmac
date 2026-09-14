import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/data/repositories/project_cache_repository.dart';
import 'package:mac_tool/data/shell/du_scanner.dart';
import 'package:mac_tool/data/shell/shell_runner.dart';

void main() {
  group('ProjectCacheRepository', () {
    late Directory root;
    late Directory flutterProject;
    late Directory webProject;

    setUp(() {
      root = Directory.systemTemp.createTempSync('project-cache-');
      flutterProject = Directory('${root.path}/flutter_app')
        ..createSync(recursive: true);
      File('${flutterProject.path}/pubspec.yaml').writeAsStringSync(
        'name: flutter_app\nflutter:\n  uses-material-design: true\n',
      );
      File('${flutterProject.path}/lib/main.dart')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('void main() {}');
      _writeCache('${flutterProject.path}/.dart_tool/package_config.json');
      _writeCache('${flutterProject.path}/build/output.bin');
      _writeCache('${flutterProject.path}/android/.gradle/state.bin');
      _writeCache('${flutterProject.path}/android/app/build/app.apk');
      _writeCache('${flutterProject.path}/ios/Pods/Manifest.lock');

      webProject = Directory('${root.path}/web_app')
        ..createSync(recursive: true);
      File('${webProject.path}/package.json').writeAsStringSync(
        jsonEncode({
          'name': 'web-app',
          'scripts': {'build': 'vite build'},
          'dependencies': {'vite': '^7.0.0'},
        }),
      );
      _writeCache('${webProject.path}/node_modules/.vite/metadata.json');
      _writeCache('${webProject.path}/.next/cache/webpack.bin');
      _writeCache('${webProject.path}/.turbo/cache.bin');
      _writeCache('${webProject.path}/dist/index.js');
      File('${webProject.path}/src/index.ts')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync('export const value = 1;');
    });

    tearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    test('detects generated caches across Flutter, mobile, and Web', () async {
      final repository = ProjectCacheRepository(
        root.path,
        DuScanner(ShellRunner()),
        ShellRunner(),
        searchRoots: [root.path],
      );

      final items = await repository.scan([]);
      final relativePaths = items
          .map(
            (item) => item.path
                .substring(item.projectRoot.length + 1)
                .replaceAll('\\', '/'),
          )
          .toSet();

      expect(relativePaths, contains('.dart_tool'));
      expect(relativePaths, contains('build'));
      expect(relativePaths, contains('android/.gradle'));
      expect(relativePaths, contains('android/app/build'));
      expect(relativePaths, contains('ios/Pods'));
      expect(relativePaths, contains('node_modules/.vite'));
      expect(relativePaths, contains('.next/cache'));
      expect(relativePaths, contains('.turbo'));
      expect(relativePaths, contains('dist'));
      expect(items.every((item) => item.sizeBytes > 0), isTrue);
      expect(items.every((item) => !item.selected), isTrue);
      expect(
        items.any(
          (item) => item.path.contains('/lib/') || item.path.contains('/src/'),
        ),
        isFalse,
      );
    });

    test('cleans only allowlisted generated directories', () async {
      final repository = ProjectCacheRepository(
        root.path,
        DuScanner(ShellRunner()),
        ShellRunner(),
        searchRoots: [root.path],
      );
      final items = await repository.scan([]);
      final selected = items
          .map((item) => item.copyWith(selected: true))
          .toList();

      final result = await repository.clean(selected);

      expect(result.cleanedCount, selected.length);
      expect(result.reclaimedBytes, greaterThan(0));
      for (final item in selected) {
        expect(Directory(item.path).existsSync(), isFalse);
      }
      expect(File('${flutterProject.path}/lib/main.dart').existsSync(), isTrue);
      expect(File('${webProject.path}/src/index.ts').existsSync(), isTrue);
      expect(File('${webProject.path}/package.json').existsSync(), isTrue);
      expect(File('${flutterProject.path}/pubspec.yaml').existsSync(), isTrue);
    });

    test('respects excluded project paths', () async {
      final repository = ProjectCacheRepository(
        root.path,
        DuScanner(ShellRunner()),
        ShellRunner(),
        excludedPaths: ['${webProject.path}/.next'],
        searchRoots: [root.path],
      );

      final items = await repository.scan([]);

      expect(items.any((item) => item.path.contains('/.next/')), isFalse);
      expect(items.any((item) => item.projectName == 'web-app'), isTrue);
    });
  });
}

void _writeCache(String path) {
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(List<int>.filled(4096, 1));
}
