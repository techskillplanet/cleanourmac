import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/app.dart';
import 'package:mac_tool/domain/models/android_emulator.dart';
import 'package:mac_tool/domain/models/android_emulator_config.dart';
import 'package:mac_tool/domain/models/disk_usage.dart';
import 'package:mac_tool/features/simulators/android_emulator_config_dialog.dart';
import 'package:mac_tool/features/simulators/android_emulator_panel.dart';
import 'package:mac_tool/features/simulators/ios_simulator_panel.dart';
import 'package:mac_tool/l10n/app_localizations.dart';
import 'package:mac_tool/providers/android_emulator_providers.dart';
import 'package:mac_tool/providers/scan_providers.dart';
import 'package:mac_tool/providers/simulator_providers.dart';
import 'package:mac_tool/domain/models/simulator_device.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    // Override disk usage so the dashboard renders data instead of an
    // indeterminate spinner (whose animation timer would otherwise stay pending).
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diskUsageProvider.overrideWith(
            (ref) async =>
                const DiskUsage(totalBytes: 100, usedBytes: 40, freeBytes: 60),
          ),
          androidEmulatorsProvider.overrideWith((ref) async => const []),
          simulatorsProvider.overrideWith((ref) async => const []),
        ],
        child: const MobileDevAssistantApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('App defaults to Simplified Chinese', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester);

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('工作台'), findsWidgets);
    expect(find.text('存储概览'), findsOneWidget);
  });

  testWidgets('App restores the saved English locale', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'locale': 'en'});
    await pumpApp(tester);

    expect(find.text('Workspace'), findsWidgets);
    expect(find.text('Storage Overview'), findsOneWidget);
  });

  testWidgets('Android devices expose localized ADB tools', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: AndroidEmulatorPanel(
              sdkAvailable: true,
              emulators: [
                AndroidEmulator(
                  name: 'Pixel 9',
                  device: 'pixel_9',
                  target: 'API 36',
                  abi: 'arm64-v8a',
                  isRunning: true,
                  serial: 'emulator-5554',
                  hardwareKeyboardEnabled: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ADB 调测工具'), findsOneWidget);
    expect(find.text('模拟器'), findsOneWidget);
    expect(find.text('打开 ADB Shell'), findsOneWidget);
    expect(find.text('打开 Logcat'), findsOneWidget);
    expect(find.text('安装 APK'), findsOneWidget);
    expect(find.text('截取屏幕'), findsOneWidget);
    expect(find.text('检查配置'), findsOneWidget);
    expect(find.text('电脑剪贴板'), findsOneWidget);
    expect(find.text('复制选中内容'), findsOneWidget);
    expect(find.text('粘贴电脑剪贴板'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS simulators expose localized RN debug tools', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: IosSimulatorPanel(
              devices: [
                SimulatorDevice(
                  udid: 'ABC123',
                  name: 'iPhone 17 Pro',
                  runtime: 'iOS 26.1',
                  sizeBytes: 1024,
                  lastBootedAt: null,
                  state: 'Booted',
                  isAvailable: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('实时日志'), findsOneWidget);
    expect(find.text('安装 .app'), findsOneWidget);
    expect(find.text('截取屏幕'), findsOneWidget);
    expect(find.text('打开 URL'), findsOneWidget);
    expect(find.text('iOS 开发菜单'), findsOneWidget);
    expect(find.text('iOS 重载'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android configuration check previews repairs before consent', (
    WidgetTester tester,
  ) async {
    final report = AndroidEmulatorConfigReport(
      checkedAt: DateTime(2026, 9, 11),
      avdCount: 1,
      sdkRoots: const ['/tmp/android-sdk'],
      issues: const [
        AndroidEmulatorConfigIssue(
          avdName: 'Pixel_Test',
          kind: AndroidEmulatorConfigIssueKind.staleLockFiles,
          severity: AndroidEmulatorConfigIssueSeverity.warning,
          repairable: true,
          path: '/tmp/Pixel_Test.avd',
          relatedPaths: ['/tmp/Pixel_Test.avd/multiinstance.lock'],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () =>
                    showAndroidEmulatorConfigCheckDialog(context, report),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Android 模拟器配置体检'), findsOneWidget);
    expect(find.text('Pixel_Test 已停止，但残留 1 个过期锁文件，可能阻止下次启动。'), findsOneWidget);
    expect(find.text('修复选中项（1）'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
