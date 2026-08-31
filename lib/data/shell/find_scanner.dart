import '../../domain/models/large_file.dart';
import 'shell_runner.dart';

class FindScanner {
  final ShellRunner _runner;
  FindScanner(this._runner);

  Stream<LargeFile> scan(String home, {int thresholdMB = 100}) async* {
    final thresholdStr = '+${thresholdMB * 1024 * 2}'; // 512-byte blocks
    final thresholdBytes = thresholdMB * 1024 * 1024;

    final stream = _runner.lines('find', [
      '-x',
      home,
      '(',
      '-path',
      '$home/Library/Application Support',
      '-o',
      '-path',
      '$home/.ssh',
      '-o',
      '-path',
      '$home/.gnupg',
      '-o',
      '-path',
      '$home/.aws',
      '-o',
      '-path',
      '$home/.gradle/daemon',
      '-o',
      '-name',
      'node_modules',
      '-o',
      '-name',
      '.git',
      ')',
      '-prune',
      '-o',
      '-type',
      'f',
      '-size',
      thresholdStr,
      '-exec',
      'stat',
      '-f',
      '%b|%z|%m|%N',
      '{}',
      '+',
    ]);

    await for (final line in stream) {
      final file = _parse(line, home, thresholdBytes);
      if (file != null) yield file;
    }
  }

  LargeFile? _parse(String line, String home, int thresholdBytes) {
    final firstPipe = line.indexOf('|');
    if (firstPipe < 0) return null;
    final secondPipe = line.indexOf('|', firstPipe + 1);
    if (secondPipe < 0) return null;
    final thirdPipe = line.indexOf('|', secondPipe + 1);
    if (thirdPipe < 0) return null;

    final allocatedBlocks = int.tryParse(line.substring(0, firstPipe));
    final logicalSize = int.tryParse(line.substring(firstPipe + 1, secondPipe));
    final mtime = int.tryParse(line.substring(secondPipe + 1, thirdPipe));
    final path = line.substring(thirdPipe + 1);

    if (allocatedBlocks == null ||
        logicalSize == null ||
        mtime == null ||
        path.isEmpty) {
      return null;
    }

    // Finder/stat logical sizes can report hundreds of GB for sparse VM disks.
    // Use allocated blocks so the shown reclaimable size matches real disk use.
    final allocatedBytes = allocatedBlocks * 512;
    if (allocatedBytes < thresholdBytes) return null;

    final safety = classifyLargeFile(path, home);
    return LargeFile(
      path: path,
      sizeBytes: allocatedBytes,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(mtime * 1000),
      safety: safety,
      safetyReason: safetyReasonFor(path, safety),
      // 默认只预选 safe 类型
      selected: safety == LargeFileSafety.safe,
    );
  }
}
