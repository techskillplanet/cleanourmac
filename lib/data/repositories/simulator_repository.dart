import '../../domain/models/simulator_device.dart';
import '../shell/simctl_client.dart';

class SimulatorRepository {
  final SimctlClient _client;
  SimulatorRepository(this._client);

  Future<List<SimulatorDevice>> list() => _client.listDevices();

  Future<void> boot(String udid) => _client.boot(udid);

  Future<void> shutdown(String udid) => _client.shutdown(udid);

  Future<void> erase(String udid) => _client.erase(udid);

  Future<void> delete(String udid) => _client.deleteDevice(udid);

  Future<void> deleteUnavailable() => _client.deleteUnavailable();

  Future<void> openSimulatorApp() => _client.openSimulatorApp();
}
