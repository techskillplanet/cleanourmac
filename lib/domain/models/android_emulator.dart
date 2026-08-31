class AndroidEmulator {
  final String name; // AVD name
  final String device; // hardware device (e.g. pixel_7)
  final String? target; // API / android version (e.g. android-35, API 35)
  final String? abi; // e.g. arm64-v8a, x86_64
  final bool isRunning;
  final String? serial; // adb serial (emulator-5554) when running

  const AndroidEmulator({
    required this.name,
    required this.device,
    this.target,
    this.abi,
    this.isRunning = false,
    this.serial,
  });

  String get detail {
    final parts = <String>[
      if (target != null && target!.isNotEmpty) target!,
      if (abi != null && abi!.isNotEmpty) abi!,
    ];
    return parts.isEmpty ? device : parts.join(' • ');
  }

  AndroidEmulator copyWith({bool? isRunning, String? serial}) => AndroidEmulator(
        name: name,
        device: device,
        target: target,
        abi: abi,
        isRunning: isRunning ?? this.isRunning,
        serial: serial ?? this.serial,
      );
}
