import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/data/shell/df_client.dart';
import 'package:mac_tool/data/shell/shell_runner.dart';

class _FakeRunner extends ShellRunner {
  final String output;

  _FakeRunner(this.output);

  @override
  Future<ShellResult> run(
    String executable,
    List<String> args, {
    Map<String, String>? environment,
  }) async {
    return ShellResult(output, '', 0);
  }
}

void main() {
  test('converts df 1024-blocks to exact bytes', () async {
    const output = '''
Filesystem   1024-blocks      Used Available Capacity Mounted on
/dev/disk3s5   239362496 121574648  77131868    62% /System/Volumes/Data
''';

    final usage = await DfClient(_FakeRunner(output)).getDataVolume();

    expect(usage.totalBytes, 245107195904);
    expect(usage.usedBytes, 124492439552);
    expect(usage.freeBytes, 78983032832);
  });
}
