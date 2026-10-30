import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mac_tool/data/fcm/fcm_auth_client.dart';

void main() {
  test('exchanges JWT assertion for access token and caches it', () async {
    var calls = 0;
    String? assertionSeen;
    final client = MockClient((request) async {
      calls++;
      expect(request.url.toString(), FcmAuthClient.oauthTokenUrl);
      expect(
        request.headers['Content-Type'],
        contains('application/x-www-form-urlencoded'),
      );
      assertionSeen = request.bodyFields['assertion'];
      expect(
        request.bodyFields['grant_type'],
        FcmAuthClient.grantType,
      );
      return http.Response(
        jsonEncode({
          'access_token': 'ya29.token',
          'expires_in': 3600,
          'token_type': 'Bearer',
        }),
        200,
      );
    });

    final auth = FcmAuthClient(
      httpClient: client,
      jwtSigner: (algorithm, {required header, required payload, required key}) async {
        expect(algorithm, 'RS256');
        expect(header['alg'], 'RS256');
        expect(payload['iss'], 'svc@demo.iam.gserviceaccount.com');
        expect(payload['scope'], FcmAuthClient.messagingScope);
        expect(payload['aud'], FcmAuthClient.oauthTokenUrl);
        expect(payload['iat'], isA<int>());
        expect(payload['exp'], isA<int>());
        expect(payload['exp'] as int, greaterThan(payload['iat'] as int));
        expect(key, 'PRIVATE');
        return 'signed.jwt.value';
      },
    );

    final first = await auth.getAccessToken(
      clientEmail: 'svc@demo.iam.gserviceaccount.com',
      privateKey: 'PRIVATE',
    );
    final second = await auth.getAccessToken(
      clientEmail: 'svc@demo.iam.gserviceaccount.com',
      privateKey: 'PRIVATE',
    );

    expect(first, 'ya29.token');
    expect(second, 'ya29.token');
    expect(assertionSeen, 'signed.jwt.value');
    expect(calls, 1);
  });

  test('surfaces oauth error body', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'error': 'invalid_grant',
          'error_description': 'Bad JWT',
        }),
        400,
      );
    });

    final auth = FcmAuthClient(
      httpClient: client,
      jwtSigner: (_, {required header, required payload, required key}) async =>
          'jwt',
    );

    expect(
      () => auth.getAccessToken(
        clientEmail: 'a@b.com',
        privateKey: 'k',
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('invalid_grant'),
        ),
      ),
    );
  });
}
