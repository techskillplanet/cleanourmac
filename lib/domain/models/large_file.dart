enum LargeFileSafety {
  safe,    // 可以安全删除（缓存、临时文件、归档）
  caution, // 需要用户确认（下载、视频、压缩包）
  keep,    // 不应删除（源码、SDK、工程文件、数据库）
}

class LargeFile {
  final String path;
  final int sizeBytes;
  final DateTime modifiedAt;
  final LargeFileSafety safety;
  bool selected;

  LargeFile({
    required this.path,
    required this.sizeBytes,
    required this.modifiedAt,
    required this.safety,
    this.selected = false,
  });

  LargeFile copyWith({bool? selected}) => LargeFile(
        path: path,
        sizeBytes: sizeBytes,
        modifiedAt: modifiedAt,
        safety: safety,
        selected: selected ?? this.selected,
      );

  String get name => path.split('/').last;
  String get ext => name.contains('.') ? name.split('.').last.toLowerCase() : '';
}

/// 判断一个大文件的安全等级（纯函数，基于路径和扩展名）
LargeFileSafety classifyLargeFile(String path, String home) {
  final parts = path.split('/');
  final name = parts.last;
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';

  // ── 绝对不删（SDK、源码、工程、数据库）──────────────────────────────
  // Android SDK / NDK
  if (path.contains('/Library/Android/sdk') ||
      path.contains('/Library/Android/ndk') ||
      path.contains('/.android/')) { return LargeFileSafety.keep; }

  // Flutter SDK
  if (path.contains('/flutter-sdk/') ||
      path.contains('/flutter/bin/') ||
      path.contains('flutter_tools.snapshot')) { return LargeFileSafety.keep; }

  // 代码仓库（不删 .git 内容，已在 find 命令里 prune）
  if (path.contains('/.git/')) { return LargeFileSafety.keep; }

  // 虚拟机磁盘镜像
  if (['vmdk', 'vdi', 'vhd', 'vhdx', 'ova', 'ovf'].contains(ext)) {
    return LargeFileSafety.keep;
  }

  // 数据库文件
  if (['db', 'sqlite', 'sqlite3'].contains(ext)) { return LargeFileSafety.keep; }

  // 源码文件（大型单文件，如 generated 代码）
  if (['dart', 'swift', 'kt', 'java', 'js', 'ts', 'py', 'go', 'rs', 'cpp', 'c', 'h'].contains(ext)) {
    return LargeFileSafety.keep;
  }

  // iOS/macOS 打包产物（.app/.ipa/.xcarchive 在 Archives 里）—— 可谨慎删
  // 在 Xcode/Archives 路径下视为 caution
  if (path.contains('/Xcode/Archives/') || path.contains('/Xcode/DerivedData/')) {
    return LargeFileSafety.caution;
  }

  // ── 可以安全删除 ─────────────────────────────────────────────────────
  // 各类缓存目录
  if (path.contains('/Library/Caches/') ||
      path.contains('/.gradle/caches/') ||
      path.contains('/.gradle/wrapper/') ||
      path.contains('/.npm/') ||
      path.contains('/node-gyp/') ||
      path.contains('/ms-playwright/') ||
      path.contains('/pip/') ||
      path.contains('/Homebrew/')) { return LargeFileSafety.safe; }

  // 日志文件
  if (['log', 'logs'].contains(ext) || path.contains('/Library/Logs/')) {
    return LargeFileSafety.safe;
  }

  // 临时文件
  if (path.contains('/tmp/') || path.contains('/Temp/') || ext == 'tmp') {
    return LargeFileSafety.safe;
  }

  // 崩溃报告
  if (path.contains('/DiagnosticReports/') || ext == 'crash' || ext == 'ips') {
    return LargeFileSafety.safe;
  }

  // ── 需要用户确认 ─────────────────────────────────────────────────────
  // 下载目录
  if (path.contains('/Downloads/')) { return LargeFileSafety.caution; }

  // 压缩包（已下载的安装包）
  if (['zip', 'gz', 'tar', 'bz2', 'xz', 'rar', '7z', 'dmg', 'pkg', 'iso'].contains(ext)) {
    return LargeFileSafety.caution;
  }

  // 媒体文件
  if (['mp4', 'mov', 'avi', 'mkv', 'mp3', 'wav', 'flac', 'aac'].contains(ext)) {
    return LargeFileSafety.caution;
  }

  // 文档/图片
  if (['pdf', 'docx', 'xlsx', 'pptx', 'keynote', 'pages', 'numbers',
       'psd', 'ai', 'sketch', 'fig'].contains(ext)) {
    return LargeFileSafety.caution;
  }

  // 其他一律 caution
  return LargeFileSafety.caution;
}
