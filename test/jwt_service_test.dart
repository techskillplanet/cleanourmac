import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/data/jwt/jwt_defaults.dart';
import 'package:mac_tool/data/jwt/jwt_service.dart';

void main() {
  const header = {'alg': 'HS256', 'typ': 'JWT'};
  const payload = {'iss': 'MOBILE_APP', 'iat': 1, 'exp': 4102444800};
  const secret = 'mobile-dev-secret';

  test('signs and verifies an HS256 token', () async {
    final service = JwtService();

    final token = await service.sign(
      algorithm: 'HS256',
      header: header,
      payload: payload,
      key: secret,
    );
    final result = await service.verify(token: token, key: secret);

    expect(token.split('.'), hasLength(3));
    expect(result.signatureValid, isTrue);
    expect(result.tokenValid, isTrue);
    expect(result.header['alg'], 'HS256');
    expect(result.payload['iss'], 'MOBILE_APP');
  });

  test('rejects a modified token and an expired token', () async {
    final service = JwtService();
    final token = await service.sign(
      algorithm: 'HS256',
      header: header,
      payload: payload,
      key: secret,
    );
    final parts = token.split('.');
    final modifiedPayload = base64Url
        .encode(utf8.encode(jsonEncode({...payload, 'iss': 'tampered'})))
        .replaceAll('=', '');
    final modified = '${parts[0]}.$modifiedPayload.${parts[2]}';
    final expired = await service.sign(
      algorithm: 'HS256',
      header: header,
      payload: {...payload, 'exp': 1},
      key: secret,
    );

    expect(
      (await service.verify(token: modified, key: secret)).signatureValid,
      isFalse,
    );
    expect(
      (await service.verify(token: expired, key: secret)).signatureValid,
      isTrue,
    );
    expect(
      (await service.verify(token: expired, key: secret)).tokenValid,
      isFalse,
    );
  });

  test('normalizes PEM body whitespace without changing its label', () {
    final service = JwtService();

    expect(
      service.normalizePem(
        '-----BEGIN PUBLIC KEY----- AAAA BBBB -----END PUBLIC KEY-----',
      ),
      '-----BEGIN PUBLIC KEY-----\nAAAABBBB\n-----END PUBLIC KEY-----',
    );
  });

  test('signs and verifies an RS256 token with OpenSSL', () async {
    final openssl = File('/usr/bin/openssl').existsSync()
        ? '/usr/bin/openssl'
        : 'openssl';
    final directory = await Directory.systemTemp.createTemp(
      'mobile-dev-assistant-jwt-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final privateFile = File('${directory.path}/private.pem');
    final publicFile = File('${directory.path}/public.pem');
    final generated = await Process.run(openssl, [
      'genrsa',
      '-out',
      privateFile.path,
      '2048',
    ]);
    if (generated.exitCode != 0) {
      markTestSkipped('OpenSSL RSA generation is unavailable');
      return;
    }
    final publicResult = await Process.run(openssl, [
      'rsa',
      '-in',
      privateFile.path,
      '-pubout',
      '-out',
      publicFile.path,
    ]);
    expect(publicResult.exitCode, 0);

    final service = JwtService(opensslPath: openssl);
    final token = await service.sign(
      algorithm: 'RS256',
      header: const {'alg': 'RS256', 'typ': 'JWT'},
      payload: payload,
      key: await privateFile.readAsString(),
    );
    final result = await service.verify(
      token: token,
      key: await publicFile.readAsString(),
    );

    expect(result.signatureValid, isTrue);
    expect(result.tokenValid, isTrue);
  });

  test('HTML defaults generate a valid RS256 token', () async {
    final service = JwtService();
    final token = await service.sign(
      algorithm: 'RS256',
      header: jsonDecode(JwtDefaults.headerJson) as Map<String, dynamic>,
      payload: jsonDecode(JwtDefaults.payloadJson),
      key: JwtDefaults.privateKey,
    );
    final result = await service.verify(
      token: token,
      key: JwtDefaults.publicKey,
    );

    expect(result.signatureValid, isTrue);
    expect(result.tokenValid, isTrue);
  });
}
