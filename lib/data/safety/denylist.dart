class Denylist {
  static List<String> build(String home) => [
        '$home/.ssh',
        '$home/.gnupg',
        '$home/.aws',
        '$home/.android',
        '$home/.gradle/daemon',
        '$home/Library/Android',
        '$home/Library/Application Support',
        '$home/Library/Keychains',
        '$home/Library/Preferences',
        '$home/Library/Mail',
        '$home/Library/Calendars',
        '$home/Library/Contacts',
        '$home/Library/Messages',
        '$home/Library/Safari',
        '/System',
        '/Library',
        '/usr',
        '/bin',
        '/sbin',
        '/etc',
        '/var',
        '/private',
      ];

  // Returns true if a cache path should be skipped (system caches)
  static bool isSystemCachePath(String basename) {
    if (basename.startsWith('com.apple.')) return true;
    if (basename == 'GeoServices') return true;
    if (basename == 'CloudKit') return true;
    if (basename == 'com.crashlytics') return true;
    return false;
  }
}
