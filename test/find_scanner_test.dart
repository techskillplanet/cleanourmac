import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/data/shell/find_scanner.dart';
import 'package:mac_tool/data/shell/shell_runner.dart';

class _FakeRunner extends ShellRunner {
  final List<String> outputLines;

  _FakeRunner(this.outputLines);

  @override
  Stream<String> lines(
    String executable,
    List<String> args, {
    Map<String, String>? environment,
    void Function(Process process)? onProcess,
  }) async* {
    yield* Stream.fromIterable(outputLines);
  }
}

void main() {
  test('large file scan reports allocated bytes for sparse files', () async {
    final scanner = FindScanner(
      _FakeRunner([
        // 256 blocks = 128 KiB allocated, despite a 228 GiB logical size.
        '256|245107195904|1700000000|/Users/test/large.raw',
        // 4096 blocks = 2 MiB allocated.
        '4096|2097152|1700000000|/Users/test/archive.zip',
      ]),
    );

    final files = await scanner.scan('/Users/test', thresholdMB: 1).toList();

    expect(files, hasLength(1));
    expect(files.single.path, '/Users/test/archive.zip');
    expect(files.single.sizeBytes, 2 * 1024 * 1024);
  });
}
