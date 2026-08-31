import 'dart:io';

class TccProbe {
  // Attempts to list ~/.Trash — permission denied means Full Disk Access not granted.
  static Future<bool> hasFullDiskAccess() async {
    final home = Platform.environment['HOME'] ?? '';
    try {
      await Directory('$home/.Trash').list().first;
      return true;
    } on PathAccessException {
      return false;
    } catch (_) {
      return true; // Empty Trash or other non-permission error
    }
  }
}
