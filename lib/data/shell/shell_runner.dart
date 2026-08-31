import 'dart:io';

class ShellResult {
  final String stdout;
  final String stderr;
  final int exitCode;
  const ShellResult(this.stdout, this.stderr, this.exitCode);
}

class ShellRunner {
  // Runs a command and returns result without throwing on non-zero exit.
  // du exits 1 on partial permission errors but still emits valid output.
  Future<ShellResult> run(
    String executable,
    List<String> args, {
    Map<String, String>? environment,
  }) async {
    final env = {
      'HOME': Platform.environment['HOME'] ?? '',
      'LANG': 'en_US.UTF-8',
      'PATH': '/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:${Platform.environment['PATH'] ?? ''}',
      ...?environment,
    };

    final proc = await Process.start(executable, args, environment: env);
    final out = StringBuffer();
    final err = StringBuffer();

    await Future.wait([
      proc.stdout.transform(const SystemEncoding().decoder).forEach(out.write),
      proc.stderr.transform(const SystemEncoding().decoder).forEach(err.write),
    ]);

    final code = await proc.exitCode;
    return ShellResult(out.toString(), err.toString(), code);
  }

  // Streams lines from a long-running command; cancel via the process handle.
  Stream<String> lines(
    String executable,
    List<String> args, {
    Map<String, String>? environment,
    void Function(Process)? onProcess,
  }) async* {
    final env = {
      'HOME': Platform.environment['HOME'] ?? '',
      'LANG': 'en_US.UTF-8',
      'PATH': '/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:${Platform.environment['PATH'] ?? ''}',
      ...?environment,
    };

    final proc = await Process.start(executable, args, environment: env);
    onProcess?.call(proc);

    await for (final chunk in proc.stdout.transform(const SystemEncoding().decoder)) {
      for (final line in chunk.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) yield trimmed;
      }
    }

    await proc.exitCode; // drain
  }
}
