import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/domain/models/category_summary.dart';
import 'package:mac_tool/domain/models/cleanup_target.dart';
import 'package:mac_tool/domain/models/scan_item.dart';
import 'package:mac_tool/providers/scan_providers.dart';

const _target = CleanupTarget(
  id: 'test',
  label: 'Test',
  description: 'Test category',
  absolutePath: '/tmp/test',
  safety: SafetyLevel.safe,
);

void main() {
  group('shouldRetainScanSummary', () {
    test('keeps a category while it is being scanned', () {
      expect(
        shouldRetainScanSummary(
          const CategorySummary(target: _target, scanning: true),
        ),
        isTrue,
      );
    });

    test('removes a completed zero-byte category without errors', () {
      expect(
        shouldRetainScanSummary(const CategorySummary(target: _target)),
        isFalse,
      );
    });

    test('removes a category whose items all report zero bytes', () {
      expect(
        shouldRetainScanSummary(
          CategorySummary(
            target: _target,
            items: [
              ScanItem(
                path: '/tmp/test/empty',
                sizeBytes: 0,
                safety: SafetyLevel.safe,
              ),
            ],
          ),
        ),
        isFalse,
      );
    });

    test('keeps completed categories with reclaimable data', () {
      expect(
        shouldRetainScanSummary(
          CategorySummary(
            target: _target,
            items: [
              ScanItem(
                path: '/tmp/test/cache',
                sizeBytes: 1024,
                safety: SafetyLevel.safe,
              ),
            ],
          ),
        ),
        isTrue,
      );
    });

    test('keeps zero-byte categories when an error needs to be shown', () {
      expect(
        shouldRetainScanSummary(
          const CategorySummary(target: _target, error: 'permission denied'),
        ),
        isTrue,
      );
    });
  });
}
