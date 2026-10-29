import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mac_tool/data/fcm/fcm_auth_client.dart';
import 'package:mac_tool/data/fcm/fcm_push_client.dart';
import 'package:mac_tool/domain/models/fcm_models.dart';

void main() {
  group('parseDeviceTokens', () {
    test('splits by newline and comma', () {
      expect(
        FcmPushClient.parseDeviceTokens('a\nb, c,,\n'),
        ['a', 'b', 'c'],
      );
    });
  });

  group('validateMessageData', () {
    final longToken =
        'eq1CvDbZSzKMup_jhsRhwk:APA91bHEfDn6KBj2U_Vxqu7EHSL6UPsMLpO0eH9VcNR9MZs7MvCueveve8JCAwIiUz7aZYbZCY2tFpMsXbvjelSDbRQpAB8GIYHz7_qGD5UeMBA6rjoKaeQ';

    test('accepts simple format', () {
      final result = FcmPushClient.validateMessageData({
        'token': longToken,
        'notification': {'title': 'Hi', 'body': 'Body'},
      });
      expect(result.isValid, isTrue);
      expect(result.format, FcmSendMode.simple);
    });

    test('rejects missing title and body', () {
      final result = FcmPushClient.validateMessageData({
        'token': longToken,
        'notification': {},
      });
      expect(result.isValid, isFalse);
      expect(result.errors, containsAll(['缺少通知标题', '缺少通知内容']));
    });

    test('accepts full message format', () {
      final result = FcmPushClient.validateMessageData({
        'message': {
          'token': longToken,
          'notification': {'title': 'T', 'body': 'B'},
        },
      });
      expect(result.isValid, isTrue);
      expect(result.format, FcmSendMode.fullJson);
    });
  });

  group('buildFcmMessage', () {
    test('stringifies data values in simple format', () {
      final message = FcmPushClient.buildFcmMessage({
        'token': 't' * 60,
        'notification': {'title': 'T', 'body': 'B'},
        'data': {'n': 1, 'ok': true},
      });
      expect(message['data'], {'n': '1', 'ok': 'true'});
    });

    test('passes through full message object', () {
      final original = {
        'token': 't' * 60,
        'notification': {'title': 'T', 'body': 'B'},
        'android': {
          'notification': {'sound': 'default'},
        },
      };
      final message = FcmPushClient.buildFcmMessage({'message': original});
      expect(message, original);
    });
  });

  group('sendNotification / multicast', () {
    test('posts to FCM and returns message id', () async {
      final client = MockClient((request) async {
        expect(request.url.path, contains('/projects/demo/messages:send'));
        expect(request.headers['Authorization'], 'Bearer access-token');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['message']['notification']['title'], 'Hi');
        return http.Response(
          jsonEncode({'name': 'projects/demo/messages/1'}),
          200,
        );
      });

      final push = FcmPushClient(
        auth: _FakeAuth(),
        httpClient: client,
      );
      final longToken =
          'eq1CvDbZSzKMup_jhsRhwk:APA91bHEfDn6KBj2U_Vxqu7EHSL6UPsMLpO0eH9VcNR9MZs7MvCueveve8JCAwIiUz7aZYbZCY2tFpMsXbvjelSDbRQpAB8GIYHz7_qGD5UeMBA6rjoKaeQ';

      final result = await push.sendNotification(
        {
          'token': longToken,
          'notification': {'title': 'Hi', 'body': 'Body'},
        },
        projectId: 'demo',
        clientEmail: 'a@b.com',
        privateKey: 'key',
      );

      expect(result.success, isTrue);
      expect(result.messageId, 'projects/demo/messages/1');
    });

    test('batch continues after a failure', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        if (calls == 1) {
          return http.Response(
            jsonEncode({
              'error': {'message': 'bad token'},
            }),
            400,
          );
        }
        return http.Response(
          jsonEncode({'name': 'projects/demo/messages/2'}),
          200,
        );
      });

      final push = FcmPushClient(auth: _FakeAuth(), httpClient: client);
      final t1 =
          'eq1CvDbZSzKMup_jhsRhwk:APA91bHEfDn6KBj2U_Vxqu7EHSL6UPsMLpO0eH9VcNR9MZs7MvCueveve8JCAwIiUz7aZYbZCY2tFpMsXbvjelSDbRQpAB8GIYHz7_qGD5UeMBA6rjoKae1';
      final t2 =
          'eq1CvDbZSzKMup_jhsRhwk:APA91bHEfDn6KBj2U_Vxqu7EHSL6UPsMLpO0eH9VcNR9MZs7MvCueveve8JCAwIiUz7aZYbZCY2tFpMsXbvjelSDbRQpAB8GIYHz7_qGD5UeMBA6rjoKae2';

      final batch = await push.sendMulticastNotification(
        tokens: [t1, t2],
        messageData: {
          'notification': {'title': 'T', 'body': 'B'},
        },
        projectId: 'demo',
        clientEmail: 'a@b.com',
        privateKey: 'key',
      );

      expect(batch.totalCount, 2);
      expect(batch.successCount, 1);
      expect(batch.failureCount, 1);
      expect(batch.failures.first.error, contains('bad token'));
    });
  });
}

class _FakeAuth extends FcmAuthClient {
  _FakeAuth() : super(jwtSigner: (_, {required header, required payload, required key}) async => 'jwt');

  @override
  Future<String> getAccessToken({
    required String clientEmail,
    required String privateKey,
    int expirationSeconds = 3600,
  }) async => 'access-token';
}
