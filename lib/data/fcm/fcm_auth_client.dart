import 'dart:convert';

import 'package:http/http.dart' as http;

import '../jwt/jwt_service.dart';

typedef JwtSigner =
    Future<String> Function(
      String algorithm, {
      required Map<String, dynamic> header,
      required dynamic payload,
      required String key,
    });

class FcmAuthClient {
  static const oauthTokenUrl = 'https://oauth2.googleapis.com/token';
  static const messagingScope =
      'https://www.googleapis.com/auth/firebase.messaging';
  static const grantType = 'urn:ietf:params:oauth:grant-type:jwt-bearer';

  final http.Client _http;
  final JwtSigner _jwtSigner;
  final Duration _skew;

  String? _cachedToken;
  DateTime? _cachedExpiry;
  String? _cachedKeyFingerprint;

  FcmAuthClient({
    http.Client? httpClient,
    JwtSigner? jwtSigner,
    JwtService? jwtService,
    this._skew = const Duration(seconds: 60),
  }) : _http = httpClient ?? http.Client(),
       _jwtSigner =
           jwtSigner ??
           ((algorithm, {required header, required payload, required key}) {
             final service = jwtService ?? JwtService();
             return service.sign(
               algorithm: algorithm,
               header: header,
               payload: payload,
               key: key,
             );
           });

  Future<String> getAccessToken({
    required String clientEmail,
    required String privateKey,
    int expirationSeconds = 3600,
  }) async {
    final fingerprint = '$clientEmail|${privateKey.hashCode}';
    final now = DateTime.now();
    if (_cachedToken != null &&
        _cachedExpiry != null &&
        _cachedKeyFingerprint == fingerprint &&
        now.isBefore(_cachedExpiry!.subtract(_skew))) {
      return _cachedToken!;
    }

    final expSeconds = expirationSeconds.clamp(1, 3600);
    final issuedAt = now.millisecondsSinceEpoch ~/ 1000;
    final assertion = await _jwtSigner(
      'RS256',
      header: const {'alg': 'RS256', 'typ': 'JWT'},
      payload: {
        'iss': clientEmail,
        'scope': messagingScope,
        'aud': oauthTokenUrl,
        'iat': issuedAt,
        'exp': issuedAt + expSeconds,
      },
      key: privateKey,
    );

    final response = await _http.post(
      Uri.parse(oauthTokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'grant_type': grantType, 'assertion': assertion},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_formatOAuthError(response));
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic> || body['access_token'] is! String) {
      throw StateError('未能获取访问令牌: 响应中缺少access_token字段');
    }

    final accessToken = body['access_token'] as String;
    final expiresIn = body['expires_in'];
    final ttlSeconds = expiresIn is int
        ? expiresIn
        : int.tryParse('$expiresIn') ?? expSeconds;

    _cachedToken = accessToken;
    _cachedExpiry = now.add(Duration(seconds: ttlSeconds));
    _cachedKeyFingerprint = fingerprint;
    return accessToken;
  }

  void clearCache() {
    _cachedToken = null;
    _cachedExpiry = null;
    _cachedKeyFingerprint = null;
  }

  String _formatOAuthError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return '获取访问令牌失败: ${jsonEncode(body)}';
    } catch (_) {
      return '获取访问令牌失败: HTTP ${response.statusCode} ${response.body}';
    }
  }
}
