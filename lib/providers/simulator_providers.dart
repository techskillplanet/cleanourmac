import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/simulator_device.dart';
import 'infra_providers.dart';

final simulatorsProvider = FutureProvider<List<SimulatorDevice>>((ref) {
  return ref.watch(simulatorRepositoryProvider).list();
});
