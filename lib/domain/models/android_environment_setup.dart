class AndroidEnvironmentSetupResult {
  final String sdkRoot;
  final String avdName;
  final String? logPath;

  const AndroidEnvironmentSetupResult({
    required this.sdkRoot,
    required this.avdName,
    this.logPath,
  });
}
