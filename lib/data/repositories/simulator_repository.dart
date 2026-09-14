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

  Future<void> openSimulatorDevice(String udid) =>
      _client.openSimulatorDevice(udid);

  Future<String?> chooseAppBundle(String prompt) =>
      _client.chooseAppBundle(prompt);

  Future<void> installApp(String udid, String appPath) =>
      _client.installApp(udid, appPath);

  Future<void> openUrl(String udid, String url) => _client.openUrl(udid, url);

  Future<void> openLogStream(String udid, String title) =>
      _client.openLogStream(udid, title);

  Future<String> captureScreenshot(String udid, String deviceName) =>
      _client.captureScreenshot(udid, deviceName);

  Future<void> openReactNativeDevMenu(String udid) =>
      _client.openReactNativeDevMenu(udid);

  Future<void> reloadReactNative(String udid) =>
      _client.reloadReactNative(udid);
}
