import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/core/format/byte_format.dart';

void main() {
  group('byte formatting', () {
    test('uses decimal units like macOS storage settings', () {
      expect(formatDiskBytes(245107195904), '245.11 GB');
    });

    test('does not force trailing zeroes for exact capacities', () {
      expect(formatDiskBytes(500000000000), '500 GB');
    });

    test('keeps compact formatting for scanned item sizes', () {
      expect(formatBytes(1073741824), '1.1 GB');
    });
  });
}
