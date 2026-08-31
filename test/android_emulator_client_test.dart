import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/data/shell/android_emulator_client.dart';

void main() {
  group('parseAvdNameOutput', () {
    test('ignores the emulator console OK line', () {
      expect(parseAvdNameOutput('Medium_Phone\r\nOK\r\n'), 'Medium_Phone');
    });

    test('returns null for an error response', () {
      expect(parseAvdNameOutput('KO: emulator not running\r\n'), isNull);
    });

    test('ignores blank lines', () {
      expect(parseAvdNameOutput('\n\nPixel_9\nOK\n'), 'Pixel_9');
    });
  });
}
