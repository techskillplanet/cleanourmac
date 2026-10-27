import 'dart:io';

class PlatformCapabilities {
  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;

  static bool get supportsIosTooling => isMacOS;
  static bool get supportsAppleKeychain => isMacOS;
  static bool get supportsMacTerminal => isMacOS;
}
