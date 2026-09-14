import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/models/ios_signing_certificate.dart';
import 'shell_escape.dart';
import 'shell_runner.dart';

DateTime? parseOpenSslCertificateDate(String value) {
  final match = RegExp(
    r'^([A-Z][a-z]{2})\s+(\d{1,2})\s+'
    r'(\d{2}):(\d{2}):(\d{2})\s+(\d{4})\s+GMT$',
  ).firstMatch(value.trim());
  if (match == null) return null;
  const months = {
    'Jan': 1,
    'Feb': 2,
    'Mar': 3,
    'Apr': 4,
    'May': 5,
    'Jun': 6,
    'Jul': 7,
    'Aug': 8,
    'Sep': 9,
    'Oct': 10,
    'Nov': 11,
    'Dec': 12,
  };
  final month = months[match.group(1)];
  if (month == null) return null;
  return DateTime.utc(
    int.parse(match.group(6)!),
    month,
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
  );
}

String? parseDistinguishedNameValue(String value, String key) {
  final match = RegExp(
    '(?:^|,)\\s*${RegExp.escape(key)}\\s*=\\s*((?:\\\\.|[^,])*)',
  ).firstMatch(value);
  final result = match?.group(1)?.trim();
  if (result == null || result.isEmpty) return null;
  return result.replaceAll(r'\,', ',').replaceAll(r'\\', r'\');
}

class IosCertificateClient {
  static const _security = '/usr/bin/security';
  static const _openssl = '/usr/bin/openssl';
  static const _keychainAccess =
      '/System/Library/CoreServices/Applications/Keychain Access.app';

  final ShellRunner _runner;
  final String? _temporaryDirectoryOverride;
  final DateTime Function() _now;

  IosCertificateClient(
    this._runner, {
    String? temporaryDirectory,
    DateTime Function()? now,
  }) : _temporaryDirectoryOverride = temporaryDirectory,
       _now = now ?? DateTime.now;

  Future<List<IosSigningCertificate>> listCertificates() async {
    final keychains = await _listUserKeychains();
    final identityFingerprints = await _identityFingerprints(validOnly: false);
    final validIdentityFingerprints = await _identityFingerprints(
      validOnly: true,
    );
    final certificates = <IosSigningCertificate>[];
    final seenFingerprints = <String>{};
    final temporaryRoot = Directory(
      _temporaryDirectoryOverride ?? Directory.systemTemp.path,
    )..createSync(recursive: true);
    final temporaryDirectory = await temporaryRoot.createTemp(
      'mobile-dev-assistant-certificates-',
    );

    try {
      var certificateIndex = 0;
      for (final keychain in keychains) {
        final result = await _runner.run(_security, [
          'find-certificate',
          '-a',
          '-p',
          keychain,
        ]);
        if (result.exitCode != 0) continue;

        for (final pem in _pemCertificates(result.stdout)) {
          final file = File(
            p.join(
              temporaryDirectory.path,
              'certificate-$certificateIndex.pem',
            ),
          );
          certificateIndex++;
          await file.writeAsString('$pem\n', flush: true);
          final details = await _runner.run(_openssl, [
            'x509',
            '-in',
            file.path,
            '-noout',
            '-subject',
            '-issuer',
            '-startdate',
            '-enddate',
            '-serial',
            '-fingerprint',
            '-sha1',
            '-nameopt',
            'RFC2253',
          ]);
          if (details.exitCode != 0) continue;

          final certificate = _parseCertificateDetails(
            details.stdout,
            keychain,
            identityFingerprints,
            validIdentityFingerprints,
          );
          if (certificate == null || !seenFingerprints.add(certificate.sha1)) {
            continue;
          }
          certificates.add(certificate);
        }
      }
    } finally {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    }

    final now = _now();
    certificates.sort((a, b) {
      final statusCompare = _statusRank(
        a.statusAt(now),
      ).compareTo(_statusRank(b.statusAt(now)));
      if (statusCompare != 0) return statusCompare;
      return a.notAfter.compareTo(b.notAfter);
    });
    return certificates;
  }

  Future<void> openKeychainAccess() async {
    final result = await _runner.run('/usr/bin/open', [_keychainAccess]);
    _throwIfFailed(result, fallback: 'Failed to open Keychain Access');
  }

  Future<void> importCertificate(String prompt) async {
    final script =
        'set selectedCertificate to choose file with prompt '
        '${appleScriptStringLiteral(prompt)}\n'
        'return POSIX path of selectedCertificate';
    final selection = await _runner.run('/usr/bin/osascript', ['-e', script]);
    if (selection.exitCode != 0) {
      final error = selection.stderr.trim();
      if (error.contains('User canceled') || error.contains('-128')) return;
      _throwIfFailed(selection, fallback: 'Failed to choose certificate');
    }
    final path = selection.stdout.trim();
    if (path.isEmpty) return;

    final result = await _runner.run('/usr/bin/open', [
      '-a',
      _keychainAccess,
      path,
    ]);
    _throwIfFailed(result, fallback: 'Failed to import certificate');
  }

  Future<void> deleteExpiredCertificate(
    IosSigningCertificate certificate,
  ) async {
    if (!certificate.isExpiredAt(_now())) {
      throw StateError('Only expired certificates can be removed');
    }
    final result = await _runner.run(_security, [
      'delete-certificate',
      '-Z',
      certificate.sha1,
      certificate.keychainPath,
    ]);
    _throwIfFailed(result, fallback: 'Failed to remove expired certificate');
  }

  Future<List<String>> _listUserKeychains() async {
    final result = await _runner.run(_security, [
      'list-keychains',
      '-d',
      'user',
    ]);
    final keychains = <String>[];
    if (result.exitCode == 0) {
      for (final line in result.stdout.split('\n')) {
        final value = line.trim().replaceAll(RegExp(r'^"|"$'), '');
        if (value.isNotEmpty) keychains.add(value);
      }
    }
    if (keychains.isNotEmpty) return keychains;

    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) return const [];
    final loginKeychain = '$home/Library/Keychains/login.keychain-db';
    return File(loginKeychain).existsSync() ? [loginKeychain] : const [];
  }

  Future<Set<String>> _identityFingerprints({required bool validOnly}) async {
    final arguments = [
      'find-identity',
      if (validOnly) '-v',
      '-p',
      'codesigning',
    ];
    final result = await _runner.run(_security, arguments);
    if (result.exitCode != 0) return {};
    return RegExp(r'\b[A-Fa-f0-9]{40}\b')
        .allMatches(result.stdout)
        .map((match) => match.group(0)!.toUpperCase())
        .toSet();
  }

  Iterable<String> _pemCertificates(String output) {
    return RegExp(
      r'-----BEGIN CERTIFICATE-----[\s\S]*?-----END CERTIFICATE-----',
    ).allMatches(output).map((match) => match.group(0)!);
  }

  IosSigningCertificate? _parseCertificateDetails(
    String output,
    String keychain,
    Set<String> identityFingerprints,
    Set<String> validIdentityFingerprints,
  ) {
    final values = <String, String>{};
    for (final line in output.split('\n')) {
      final separator = line.indexOf('=');
      if (separator <= 0) continue;
      values[line.substring(0, separator).trim()] = line
          .substring(separator + 1)
          .trim();
    }
    final subject = values['subject'];
    final commonName = subject == null
        ? null
        : parseDistinguishedNameValue(subject, 'CN');
    if (commonName == null || !_isAppleSigningCertificate(commonName)) {
      return null;
    }

    final notBefore = parseOpenSslCertificateDate(values['notBefore'] ?? '');
    final notAfter = parseOpenSslCertificateDate(values['notAfter'] ?? '');
    final fingerprint = values['SHA1 Fingerprint']
        ?.replaceAll(':', '')
        .toUpperCase();
    if (notBefore == null ||
        notAfter == null ||
        fingerprint == null ||
        fingerprint.isEmpty) {
      return null;
    }

    final issuerDn = values['issuer'] ?? '';
    final issuer =
        parseDistinguishedNameValue(issuerDn, 'CN') ?? issuerDn.trim();
    return IosSigningCertificate(
      commonName: commonName,
      teamId: parseDistinguishedNameValue(subject!, 'OU'),
      organization: parseDistinguishedNameValue(subject, 'O'),
      issuer: issuer,
      serialNumber: values['serial'] ?? '',
      sha1: fingerprint,
      notBefore: notBefore,
      notAfter: notAfter,
      keychainPath: keychain,
      kind: commonName.toLowerCase().contains('distribution')
          ? IosSigningCertificateKind.distribution
          : IosSigningCertificateKind.development,
      hasPrivateKey: identityFingerprints.contains(fingerprint),
      isUsableForSigning: validIdentityFingerprints.contains(fingerprint),
    );
  }

  bool _isAppleSigningCertificate(String commonName) {
    final name = commonName.toLowerCase();
    return name.startsWith('apple development:') ||
        name.startsWith('apple distribution:') ||
        name.startsWith('iphone developer:') ||
        name.startsWith('iphone distribution:') ||
        name.startsWith('ios development:') ||
        name.startsWith('ios distribution:');
  }

  int _statusRank(IosSigningCertificateStatus status) => switch (status) {
    IosSigningCertificateStatus.expired => 0,
    IosSigningCertificateStatus.expiringSoon => 1,
    IosSigningCertificateStatus.missingPrivateKey => 2,
    IosSigningCertificateStatus.notYetValid => 3,
    IosSigningCertificateStatus.ready => 4,
  };

  void _throwIfFailed(ShellResult result, {required String fallback}) {
    if (result.exitCode == 0) return;
    final error = result.stderr.trim().isNotEmpty
        ? result.stderr.trim()
        : result.stdout.trim();
    throw StateError(error.isEmpty ? fallback : error);
  }
}
