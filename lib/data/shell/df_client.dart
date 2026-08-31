import '../../domain/models/disk_usage.dart';
import 'shell_runner.dart';

class DfClient {
  final ShellRunner _runner;
  DfClient(this._runner);

  Future<DiskUsage> getDataVolume() async {
    final result = await _runner.run('df', ['-k', '/System/Volumes/Data']);
    return _parse(result.stdout);
  }

  DiskUsage _parse(String stdout) {
    final lines = stdout.trim().split('\n');
    if (lines.length < 2) return const DiskUsage(totalBytes: 0, usedBytes: 0, freeBytes: 0);

    final parts = lines[1].trim().split(RegExp(r'\s+'));
    if (parts.length < 4) return const DiskUsage(totalBytes: 0, usedBytes: 0, freeBytes: 0);

    final total = (int.tryParse(parts[1]) ?? 0) * 1024;
    final used = (int.tryParse(parts[2]) ?? 0) * 1024;
    final free = (int.tryParse(parts[3]) ?? 0) * 1024;
    return DiskUsage(totalBytes: total, usedBytes: used, freeBytes: free);
  }
}
