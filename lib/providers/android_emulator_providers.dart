import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/android_emulator.dart';
import 'infra_providers.dart';

final androidEmulatorsProvider = FutureProvider<List<AndroidEmulator>>((ref) {
  return ref.watch(androidEmulatorRepositoryProvider).list();
});
