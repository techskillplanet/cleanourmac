import '../../domain/models/android_emulator.dart';
import '../../domain/models/android_emulator_config.dart';
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

  Future<void> pressBack(String serial) => _client.pressBack(serial);

  Future<void> pressHome(String serial) => _client.pressHome(serial);

  Future<void> pressRecents(String serial) => _client.pressRecents(serial);

  Future<void> copySelection(String serial) => _client.copySelection(serial);

  Future<void> pasteClipboard(String serial) => _client.pasteClipboard(serial);

  Future<void> enableHardwareKeyboard(String avdName) =>
      _client.enableHardwareKeyboard(avdName);

  Future<AndroidEmulatorConfigReport> inspectConfiguration() =>
      _client.inspectConfiguration();

  Future<AndroidEmulatorConfigRepairResult> repairConfiguration(
    Iterable<String> issueIds,
  ) => _client.repairConfiguration(issueIds);

  Future<void> reversePort(String serial, int port) =>
      _client.reversePort(serial, port);

  Future<void> openAdbShell(String serial, String title) =>
      _client.openAdbShell(serial, title);

  Future<void> openLogcat(String serial, String title) =>
      _client.openLogcat(serial, title);

  Future<String?> chooseApk(String prompt) => _client.chooseApk(prompt);

  Future<void> installApk(String serial, String apkPath) =>
      _client.installApk(serial, apkPath);

  Future<String> captureScreenshot(String serial, String deviceName) =>
      _client.captureScreenshot(serial, deviceName);

  Future<void> restartAdb() => _client.restartAdb();

  Future<void> revealDiagnosticLog(String path) =>
      _client.revealDiagnosticLog(path);

  Future<void> delete(String avdName) => _client.delete(avdName);
}
