enum JavaScriptPackageManager { yarn, npm, pnpm, bun }

enum ProjectOpenTarget {
  codexDesktop,
  codexCli,
  cursor,
  visualStudioCode,
  androidStudio,
  xcode,
  qoder,
  trae,
  webStorm,
  zed,
  windsurf,
  finder,
  terminal,
}

class ProjectOpenOption {
  final ProjectOpenTarget target;
  final String openPath;
  final String? applicationPath;

  const ProjectOpenOption({
    required this.target,
    required this.openPath,
    this.applicationPath,
  });
}

class ReactNativeProject {
  final String path;
  final String name;
  final Map<String, String> scripts;
  final JavaScriptPackageManager packageManager;
  final int metroPort;

  const ReactNativeProject({
    required this.path,
    required this.name,
    required this.scripts,
    required this.packageManager,
    required this.metroPort,
  });

  bool hasScript(String name) => scripts.containsKey(name);

  String get packageManagerLabel => switch (packageManager) {
    JavaScriptPackageManager.yarn => 'Yarn',
    JavaScriptPackageManager.npm => 'npm',
    JavaScriptPackageManager.pnpm => 'pnpm',
    JavaScriptPackageManager.bun => 'Bun',
  };
}

class MetroStatus {
  final bool running;
  final int port;
  final int? pid;
  final String? processName;

  const MetroStatus({
    required this.running,
    required this.port,
    this.pid,
    this.processName,
  });
}
