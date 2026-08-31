import '../../domain/models/android_emulator.dart';
import '../shell/android_emulator_client.dart';

class AndroidEmulatorRepository {
  final AndroidEmulatorClient _client;
  AndroidEmulatorRepository(this._client);

  bool get isAvailable => _client.isAvailable;

  Future<List<AndroidEmulator>> list() => _client.list();

  Future<void> boot(String avdName) => _client.boot(avdName);

  Future<void> shutdown(String serial) => _client.shutdown(serial);

  Future<void> openDevMenu(String serial) => _client.openDevMenu(serial);

  Future<void> reloadJs(String serial) => _client.reloadJs(serial);

  Future<void> delete(String avdName) => _client.delete(avdName);
}
