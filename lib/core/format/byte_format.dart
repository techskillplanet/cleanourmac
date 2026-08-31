import 'package:intl/intl.dart';

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var i = 0;
  while (value >= 1024 && i < units.length - 1) {
    value /= 1024;
    i++;
  }
  final fmt = value < 10 ? NumberFormat('0.0') : NumberFormat('0');
  return '${fmt.format(value)} ${units[i]}';
}

String formatBytesFromKb(int kb) => formatBytes(kb * 1024);
