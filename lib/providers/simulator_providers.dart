import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/platform/platform_capabilities.dart';
import '../domain/models/simulator_device.dart';
import 'infra_providers.dart';

final simulatorsProvider = FutureProvider<List<SimulatorDevice>>((ref) {
  if (!PlatformCapabilities.supportsIosTooling) {
    return Future.value(const []);
  }
  return ref.watch(simulatorRepositoryProvider).list();
});
