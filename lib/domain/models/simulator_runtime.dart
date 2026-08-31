class SimulatorRuntime {
  final String identifier;
  final String runtimeIdentifier;
  final String version;
  final String build;
  final String path;
  final int sizeBytes;
  final DateTime? lastUsedAt;
  final bool deletable;

  const SimulatorRuntime({
    required this.identifier,
    required this.runtimeIdentifier,
    required this.version,
    required this.build,
    required this.path,
    required this.sizeBytes,
    this.lastUsedAt,
    required this.deletable,
  });

  String get displayName => 'iOS $version';
}
