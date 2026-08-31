class DiskUsage {
  final int totalBytes;
  final int usedBytes;
  final int freeBytes;

  const DiskUsage({
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
  });

  double get usedFraction => totalBytes == 0 ? 0 : usedBytes / totalBytes;
  double get freeFraction => totalBytes == 0 ? 0 : freeBytes / totalBytes;
}
