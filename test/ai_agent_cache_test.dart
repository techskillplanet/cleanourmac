import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/data/registry/ai_agent_cache_registry.dart';
import 'package:mac_tool/data/repositories/ai_agent_cache_repository.dart';
import 'package:mac_tool/data/safety/path_guard.dart';
import 'package:mac_tool/data/shell/du_scanner.dart';
import 'package:mac_tool/data/shell/shell_runner.dart';
import 'package:mac_tool/domain/models/ai_agent_cache.dart';
import 'package:mac_tool/features/ai_agents/ai_agent_cache_page.dart';
import 'package:mac_tool/l10n/app_localizations.dart';
import 'package:mac_tool/providers/ai_agent_cache_providers.dart';
import 'package:mac_tool/providers/infra_providers.dart';

void main() {
  group('AI agent cache registry', () {
    test('contains only explicit cache paths, never user state paths', () {
      final targets = AiAgentCacheRegistry.build('/Users/tester');
      final paths = targets.map((target) => target.path).toList();

      expect(paths, contains('/Users/tester/Library/Caches/claude-cli-nodejs'));
      expect(paths, contains('/Users/tester/.cache/opencode'));
      expect(
        paths,
        contains('/Users/tester/Library/Application Support/Cursor/CachedData'),
      );
      expect(
        paths,
        contains(
          '/Users/tester/Library/Application Support/Qoder/SharedClientCache',
        ),
      );

      for (final path in paths) {
        expect(path, isNot(contains('/sessions')));
        expect(path, isNot(contains('/projects')));
        expect(path, isNot(contains('/User/')));
        expect(path, isNot(contains('/workspaceStorage')));
        expect(path, isNot(contains('/Local Storage')));
        expect(path, isNot(contains('/Backups')));
        expect(path, isNot(contains('/logs')));
      }
    });
  });

  group('AI agent cache cleanup', () {
    late Directory home;
    late Directory cacheRoot;
    late AiAgentCacheRepository repository;
    late String resolvedHome;

    setUp(() {
      home = Directory.systemTemp.createTempSync('mobile-assistant-home-');
      resolvedHome = home.resolveSymbolicLinksSync();
      cacheRoot = Directory('$resolvedHome/Library/Caches/claude-cli-nodejs')
        ..createSync(recursive: true);
      File(
        '${cacheRoot.path}/cache.bin',
      ).writeAsBytesSync(List<int>.filled(4096, 1));
      Directory('${cacheRoot.path}/nested').createSync();
      File('${cacheRoot.path}/nested/data.bin').writeAsStringSync('cache');

      repository = AiAgentCacheRepository(
        resolvedHome,
        DuScanner(ShellRunner()),
        PathGuard(home: resolvedHome),
      );
    });

    tearDown(() {
      if (home.existsSync()) home.deleteSync(recursive: true);
    });

    test('keeps cache roots and clears only selected contents', () async {
      final items = await repository.scan();
      expect(items, hasLength(1));
      expect(repository.dryRun(items), isEmpty);

      final selected = [items.single.copyWith(selected: true)];
      final result = await repository.clean(selected);

      expect(result.cleanedCount, 1);
      expect(result.reclaimedBytes, greaterThan(0));
      expect(cacheRoot.existsSync(), isTrue);
      expect(cacheRoot.listSync(), isEmpty);
    });

    testWidgets('requires explicit consent before cleanup', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProvider.overrideWithValue(resolvedHome),
            aiAgentCacheProvider.overrideWith(
              (ref) => AiAgentCacheNotifier(
                repository,
                initialState: const AiAgentCacheState(
                  items: [
                    AiAgentCacheItem(
                      target: AiAgentCacheTarget(
                        id: 'claude_cli_cache',
                        agent: AiAgentKind.claudeCode,
                        kind: AiAgentCacheKind.cliCache,
                        path: '/test/cache',
                      ),
                      sizeBytes: 4096,
                    ),
                  ],
                ),
                autoScan: false,
              ),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('zh'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: AiAgentCachePage(),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('清理所选缓存'));
      await tester.pumpAndSettle();

      final confirmFinder = find.widgetWithText(FilledButton, '确认清理');
      expect(confirmFinder, findsOneWidget);
      expect(tester.widget<FilledButton>(confirmFinder).onPressed, isNull);

      await tester.tap(find.text('我已关闭相关 AI Agent，并同意清理所选缓存'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(confirmFinder).onPressed, isNotNull);
    });
  });
}
