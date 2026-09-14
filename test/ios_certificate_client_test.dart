import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/data/shell/ios_certificate_client.dart';
import 'package:mac_tool/data/shell/shell_runner.dart';
import 'package:mac_tool/domain/models/ios_signing_certificate.dart';

class _Command {
  final String executable;
  final List<String> arguments;

  const _Command(this.executable, this.arguments);
}

class _FakeShellRunner extends ShellRunner {
  final List<_Command> commands = [];
  final ShellResult Function(String executable, List<String> arguments)
  responder;

  _FakeShellRunner(this.responder);

  @override
  Future<ShellResult> run(
    String executable,
    List<String> args, {
    Map<String, String>? environment,
  }) async {
    commands.add(_Command(executable, List.of(args)));
    return responder(executable, args);
  }
}

void main() {
  test('parses OpenSSL certificate dates as UTC', () {
    expect(
      parseOpenSslCertificateDate('Jul 10 02:11:32 2026 GMT'),
      DateTime.utc(2026, 7, 10, 2, 11, 32),
    );
  });

  test('scans Apple development certificates and signing state', () async {
    final root = Directory.systemTemp.createTempSync('ios-certificate-');
    addTearDown(() => root.deleteSync(recursive: true));
    final keychain = File('${root.path}/login.keychain-db')
      ..writeAsStringSync('');
    const fingerprint = '31BCC40521448795F5DE6B67B384FB996AC5BB1E';
    final runner = _FakeShellRunner((executable, arguments) {
      if (arguments case ['list-keychains', '-d', 'user']) {
        return ShellResult('    "${keychain.path}"\n', '', 0);
      }
      if (arguments case ['find-identity', '-p', 'codesigning']) {
        return const ShellResult(
          '  1) $fingerprint "Apple Development: Dev (TEAM123)" '
              '(CSSMERR_TP_CERT_EXPIRED)\n',
          '',
          0,
        );
      }
      if (arguments case ['find-identity', '-v', '-p', 'codesigning']) {
        return const ShellResult('0 valid identities found\n', '', 0);
      }
      if (arguments case ['find-certificate', '-a', '-p', _]) {
        return const ShellResult(
          '-----BEGIN CERTIFICATE-----\nFAKE\n-----END CERTIFICATE-----\n',
          '',
          0,
        );
      }
      if (executable == '/usr/bin/openssl') {
        return const ShellResult(
          'subject= C=US,O=Example,OU=TEAM123,'
              'CN=Apple Development: Dev (TEAM123)\n'
              'issuer= C=US,O=Apple Inc.,'
              'CN=Apple Worldwide Developer Relations Certification Authority\n'
              'notBefore=Jul 10 02:11:33 2025 GMT\n'
              'notAfter=Jul 10 02:11:32 2026 GMT\n'
              'serial=425D43F7B5E87391\n'
              'SHA1 Fingerprint=31:BC:C4:05:21:44:87:95:F5:DE:6B:67:'
              'B3:84:FB:99:6A:C5:BB:1E\n',
          '',
          0,
        );
      }
      return const ShellResult('', '', 0);
    });
    final client = IosCertificateClient(
      runner,
      temporaryDirectory: root.path,
      now: () => DateTime.utc(2026, 9, 11),
    );

    final certificates = await client.listCertificates();

    expect(certificates, hasLength(1));
    final certificate = certificates.single;
    expect(certificate.commonName, 'Apple Development: Dev (TEAM123)');
    expect(certificate.teamId, 'TEAM123');
    expect(certificate.kind, IosSigningCertificateKind.development);
    expect(certificate.hasPrivateKey, isTrue);
    expect(certificate.isUsableForSigning, isFalse);
    expect(
      certificate.statusAt(DateTime.utc(2026, 9, 11)),
      IosSigningCertificateStatus.expired,
    );
  });

  test(
    'deletes only expired certificates and retains the private key',
    () async {
      final runner = _FakeShellRunner((_, _) => const ShellResult('', '', 0));
      final client = IosCertificateClient(
        runner,
        now: () => DateTime.utc(2026, 9, 11),
      );
      final expired = IosSigningCertificate(
        commonName: 'Apple Development: Dev',
        teamId: 'TEAM123',
        organization: null,
        issuer: 'Apple',
        serialNumber: '1',
        sha1: 'ABCDEF',
        notBefore: DateTime.utc(2025),
        notAfter: DateTime.utc(2026, 7, 10),
        keychainPath: '/tmp/login.keychain-db',
        kind: IosSigningCertificateKind.development,
        hasPrivateKey: true,
        isUsableForSigning: false,
      );

      await client.deleteExpiredCertificate(expired);

      expect(runner.commands.single.arguments, [
        'delete-certificate',
        '-Z',
        'ABCDEF',
        '/tmp/login.keychain-db',
      ]);
    },
  );

  test('refuses to delete a certificate that is not expired', () {
    final runner = _FakeShellRunner((_, _) => const ShellResult('', '', 0));
    final client = IosCertificateClient(
      runner,
      now: () => DateTime.utc(2026, 9, 11),
    );
    final valid = IosSigningCertificate(
      commonName: 'Apple Development: Dev',
      teamId: 'TEAM123',
      organization: null,
      issuer: 'Apple',
      serialNumber: '1',
      sha1: 'ABCDEF',
      notBefore: DateTime.utc(2026),
      notAfter: DateTime.utc(2027),
      keychainPath: '/tmp/login.keychain-db',
      kind: IosSigningCertificateKind.development,
      hasPrivateKey: true,
      isUsableForSigning: true,
    );

    expect(client.deleteExpiredCertificate(valid), throwsA(isA<StateError>()));
  });
}
