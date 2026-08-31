import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/data/safety/path_guard.dart';
import 'package:mac_tool/data/safety/denylist.dart';

void main() {
  const home = '/Users/testuser';
  final guard = PathGuard(home: home);

  group('PathGuard.assertDeletable', () {
    test('allows safe dev cache path', () {
      expect(
        () => guard.assertDeletable('$home/.gradle/caches'),
        returnsNormally,
      );
    });

    test('allows nested cache path', () {
      expect(
        () => guard.assertDeletable('$home/Library/Caches/CocoaPods'),
        returnsNormally,
      );
    });

    test('rejects home itself', () {
      expect(
        () => guard.assertDeletable(home),
        throwsA(isA<UnsafePathException>()),
      );
    });

    test('rejects top-level home directory (depth 1)', () {
      expect(
        () => guard.assertDeletable('$home/Documents'),
        throwsA(isA<UnsafePathException>()),
      );
    });

    test('rejects path outside home', () {
      expect(
        () => guard.assertDeletable('/etc/passwd'),
        throwsA(isA<UnsafePathException>()),
      );
    });

    test('rejects ~/.ssh', () {
      expect(
        () => guard.assertDeletable('$home/.ssh/id_rsa'),
        throwsA(isA<UnsafePathException>()),
      );
    });

    test('rejects ~/.gradle/daemon', () {
      expect(
        () => guard.assertDeletable('$home/.gradle/daemon/7.6'),
        throwsA(isA<UnsafePathException>()),
      );
    });

    test('rejects ~/Library/Application Support', () {
      expect(
        () =>
            guard.assertDeletable('$home/Library/Application Support/SomeApp'),
        throwsA(isA<UnsafePathException>()),
      );
    });

    test('allows a narrowly approved Application Support target', () {
      const root = '$home/Library/Application Support/SomeApp/Cache';
      expect(
        () => guard.assertDeletable('$root/update.zip', approvedRoot: root),
        returnsNormally,
      );
    });

    test('approved root cannot escape its target', () {
      const root = '$home/Library/Application Support/SomeApp/Cache';
      expect(
        () => guard.assertDeletable(
          '$home/Library/Application Support/OtherApp/data.db',
          approvedRoot: root,
        ),
        throwsA(isA<UnsafePathException>()),
      );
    });

    test('user exclusions override an approved root', () {
      const root = '$home/Library/Application Support/SomeApp/Cache';
      final g = PathGuard(home: home, userExclusions: ['$root/keep']);
      expect(
        () => g.assertDeletable('$root/keep/file.bin', approvedRoot: root),
        throwsA(isA<UnsafePathException>()),
      );
    });

    test('rejects ~/.android', () {
      expect(
        () => guard.assertDeletable('$home/.android/avd'),
        throwsA(isA<UnsafePathException>()),
      );
    });

    test('respects userExclusions', () {
      final g = PathGuard(
        home: home,
        userExclusions: ['$home/projects/active'],
      );
      expect(
        () => g.assertDeletable('$home/projects/active/node_modules'),
        throwsA(isA<UnsafePathException>()),
      );
    });
  });

  group('Denylist.isSystemCachePath', () {
    test('blocks com.apple prefixed paths', () {
      expect(Denylist.isSystemCachePath('com.apple.Safari'), isTrue);
    });

    test('blocks GeoServices', () {
      expect(Denylist.isSystemCachePath('GeoServices'), isTrue);
    });

    test('allows regular app cache', () {
      expect(Denylist.isSystemCachePath('CocoaPods'), isFalse);
      expect(Denylist.isSystemCachePath('pip'), isFalse);
    });
  });
}
