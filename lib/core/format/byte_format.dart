import 'package:intl/intl.dart';

String formatBytes(int bytes, {String? locale}) {
  return _formatBytes(bytes, maxFractionDigits: null, locale: locale);
}

String formatDiskBytes(int bytes, {String? locale}) {
  return _formatBytes(bytes, maxFractionDigits: 2, locale: locale);
}

String _formatBytes(
  int bytes, {
  required int? maxFractionDigits,
  required String? locale,
}) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var i = 0;
  while (value >= 1000 && i < units.length - 1) {
    value /= 1000;
    i++;
  }
  final digits = maxFractionDigits ?? (value < 10 ? 1 : 0);
  final decimals = List.filled(digits, '#').join();
  final fmt = NumberFormat(digits == 0 ? '0' : '0.$decimals', locale);
  return '${fmt.format(value)} ${units[i]}';
}

String formatBytesFromKb(int kb) => formatBytes(kb * 1024);
