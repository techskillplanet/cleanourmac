import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/app.dart';
import 'package:mac_tool/domain/models/disk_usage.dart';
import 'package:mac_tool/providers/scan_providers.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Override disk usage so the dashboard renders data instead of an
    // indeterminate spinner (whose animation timer would otherwise stay pending).
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diskUsageProvider.overrideWith((ref) async =>
              const DiskUsage(totalBytes: 100, usedBytes: 40, freeBytes: 60)),
        ],
        child: const MacToolApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
