class SimulatorDevice {
  final String udid;
  final String name;
  final String runtime;
  final int sizeBytes;
  final DateTime? lastBootedAt;
  final String state;
  final bool isAvailable;

  const SimulatorDevice({
    required this.udid,
    required this.name,
    required this.runtime,
    required this.sizeBytes,
    this.lastBootedAt,
    required this.state,
    required this.isAvailable,
  });

  bool get isBooted => state.toLowerCase() == 'booted';

  bool isStale(int thresholdDays) {
    if (lastBootedAt == null) return true;
    return DateTime.now().difference(lastBootedAt!).inDays > thresholdDays;
  }
}
