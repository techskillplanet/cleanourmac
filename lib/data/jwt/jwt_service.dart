import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../shell/shell_runner.dart';

class JwtVerification {
  final bool signatureValid;
  final bool? tokenValid;
  final Map<String, dynamic> header;
  final dynamic payload;
  final String? error;

  const JwtVerification({
    required this.signatureValid,
    required this.tokenValid,
    required this.header,
    required this.payload,
    this.error,
  });
}

class JwtService {
  final ShellRunner _runner;
  final String? _opensslOverride;

  JwtService({ShellRunner? runner, String? opensslPath})
    : _runner = runner ?? ShellRunner(),
      _opensslOverride = opensslPath;

  Future<String> sign({
    required String algorithm,
    required Map<String, dynamic> header,
    required dynamic payload,
    required String key,
  }) async {
    final normalizedAlgorithm = algorithm.toUpperCase();
    final input = '${_encodeJson(header)}.${_encodeJson(payload)}';
    final signature = await _signInput(normalizedAlgorithm, input, key);
    return '$input.${_base64UrlEncode(signature)}';
  }

  Future<JwtVerification> verify({
    required String token,
    required String key,
    List<String>? acceptedAlgorithms,
  }) async {
    try {
      final parts = token.trim().split('.');
      if (parts.length != 3 || parts.any((part) => part.isEmpty)) {
        throw const FormatException('JWT must contain three non-empty parts');
      }

      final header = _decodeJson(parts[0]);
      final payload = _decodeJson(parts[1]);
      if (header is! Map<String, dynamic>) {
        throw const FormatException('JWT header must be a JSON object');
      }
      final algorithm = (header['alg'] as String? ?? '').toUpperCase();
      if (algorithm.isEmpty) {
        throw const FormatException('JWT header is missing alg');
      }
      final accepted = acceptedAlgorithms
          ?.map((item) => item.toUpperCase())
          .toSet();
      if (accepted != null && !accepted.contains(algorithm)) {
        throw FormatException('Algorithm $algorithm is not accepted');
      }

      final input = '${parts[0]}.${parts[1]}';
      final signature = _base64UrlDecode(parts[2]);
      final signatureValid = await _verifySignature(
        algorithm,
        input,
        key,
        signature,
      );
      final expiration = payload is Map<String, dynamic>
          ? _asInt(payload['exp'])
          : null;
      final tokenValid = expiration == null
          ? signatureValid
          : signatureValid &&
                expiration >= DateTime.now().millisecondsSinceEpoch ~/ 1000;

      return JwtVerification(
        signatureValid: signatureValid,
        tokenValid: tokenValid,
        header: header,
        payload: payload,
      );
    } catch (error) {
      return JwtVerification(
        signatureValid: false,
        tokenValid: false,
        header: const {},
        payload: null,
        error: error.toString(),
      );
    }
  }

  String normalizePem(String value) {
    final pem = value.trim();
    final match = RegExp(
      r'-----BEGIN ([^-]+)-----([\s\S]*)-----END ([^-]+)-----',
    ).firstMatch(pem);
    if (match == null) return pem;
    final label = match.group(1)!.trim();
    final body = match.group(2)!.replaceAll(RegExp(r'\s+'), '');
    final lines = <String>[];
    for (var index = 0; index < body.length; index += 64) {
      final end = index + 64 < body.length ? index + 64 : body.length;
      lines.add(body.substring(index, end));
    }
    return '-----BEGIN $label-----\n'
        '${lines.join('\n')}\n'
        '-----END $label-----';
  }

  Future<List<int>> _signInput(
    String algorithm,
    String input,
    String key,
  ) async {
    if (algorithm.startsWith('HS')) {
      final digest = _hmacDigest(
        algorithm,
        utf8.encode(key),
        utf8.encode(input),
      );
      return digest.bytes;
    }

    if (!algorithm.startsWith('RS') || algorithm == 'RS') {
      throw UnsupportedError('Unsupported JWT algorithm: $algorithm');
    }
    final digest = _rsaDigestName(algorithm);
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'mobile-dev-assistant-jwt-',
    );
    try {
      final keyFile = File(p.join(temporaryDirectory.path, 'key.pem'));
      final inputFile = File(p.join(temporaryDirectory.path, 'input.txt'));
      final signatureFile = File(
        p.join(temporaryDirectory.path, 'signature.bin'),
      );
      await keyFile.writeAsString(normalizePem(key), flush: true);
      await inputFile.writeAsString(input, flush: true);
      final result = await _runner.run(_opensslPath, [
        'dgst',
        '-$digest',
        '-sign',
        keyFile.path,
        '-out',
        signatureFile.path,
        inputFile.path,
      ]);
      if (result.exitCode != 0) {
        throw StateError(
          result.stderr.trim().isEmpty
              ? 'OpenSSL failed to sign JWT'
              : result.stderr.trim(),
        );
      }
      return await signatureFile.readAsBytes();
    } finally {
      if (temporaryDirectory.existsSync()) {
        await temporaryDirectory.delete(recursive: true);
      }
    }
  }

  Future<bool> _verifySignature(
    String algorithm,
    String input,
    String key,
    List<int> signature,
  ) async {
    if (algorithm.startsWith('HS')) {
      final expected = _hmacDigest(
        algorithm,
        utf8.encode(key),
        utf8.encode(input),
      );
      return _constantTimeEquals(expected.bytes, signature);
    }
    if (!algorithm.startsWith('RS') || algorithm == 'RS') {
      throw UnsupportedError('Unsupported JWT algorithm: $algorithm');
    }
    final digest = _rsaDigestName(algorithm);
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'mobile-dev-assistant-jwt-',
    );
    try {
      final keyFile = File(p.join(temporaryDirectory.path, 'key.pem'));
      final inputFile = File(p.join(temporaryDirectory.path, 'input.txt'));
      final signatureFile = File(
        p.join(temporaryDirectory.path, 'signature.bin'),
      );
      await keyFile.writeAsString(normalizePem(key), flush: true);
      await inputFile.writeAsString(input, flush: true);
      await signatureFile.writeAsBytes(signature, flush: true);
      final result = await _runner.run(_opensslPath, [
        'dgst',
        '-$digest',
        '-verify',
        keyFile.path,
        '-signature',
        signatureFile.path,
        inputFile.path,
      ]);
      return result.exitCode == 0 && result.stdout.contains('Verified OK');
    } finally {
      if (temporaryDirectory.existsSync()) {
        await temporaryDirectory.delete(recursive: true);
      }
    }
  }

  Digest _hmacDigest(String algorithm, List<int> key, List<int> input) {
    final hash = switch (algorithm) {
      'HS256' => sha256,
      'HS384' => sha384,
      'HS512' => sha512,
      _ => throw UnsupportedError('Unsupported JWT algorithm: $algorithm'),
    };
    return Hmac(hash, key).convert(input);
  }

  String _rsaDigestName(String algorithm) => switch (algorithm) {
    'RS256' => 'sha256',
    'RS384' => 'sha384',
    'RS512' => 'sha512',
    _ => throw UnsupportedError('Unsupported JWT algorithm: $algorithm'),
  };

  String get _opensslPath {
    if (_opensslOverride case final path?) return path;
    if (Platform.isMacOS && File('/usr/bin/openssl').existsSync()) {
      return '/usr/bin/openssl';
    }
    return 'openssl';
  }

  String _encodeJson(dynamic value) {
    return _base64UrlEncode(utf8.encode(jsonEncode(value)));
  }

  dynamic _decodeJson(String value) {
    return jsonDecode(utf8.decode(_base64UrlDecode(value)));
  }

  String _base64UrlEncode(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  Uint8List _base64UrlDecode(String value) {
    final normalized = value.replaceAll('-', '+').replaceAll('_', '/');
    final padded = '$normalized${'=' * ((4 - normalized.length % 4) % 4)}';
    return Uint8List.fromList(base64.decode(padded));
  }

  bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}
