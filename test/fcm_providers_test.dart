import 'package:flutter_test/flutter_test.dart';
import 'package:mac_tool/data/fcm/fcm_auth_client.dart';
import 'package:mac_tool/data/fcm/fcm_demo_payload.dart';
import 'package:mac_tool/data/fcm/fcm_push_client.dart';
import 'package:mac_tool/domain/models/fcm_models.dart';
import 'package:mac_tool/providers/fcm_providers.dart';

void main() {
  late FcmPushNotifier notifier;

  setUp(() {
    notifier = FcmPushNotifier(
      auth: FcmAuthClient(
        jwtSigner: (_, {required header, required payload, required key}) async =>
            'jwt',
      ),
      push: FcmPushClient(
        auth: FcmAuthClient(
          jwtSigner:
              (_, {required header, required payload, required key}) async =>
                  'jwt',
        ),
      ),
    );
  });

  test('imports valid service account into memory only', () {
    final error = notifier.importServiceAccountJson(_validServiceAccountJson());
    expect(error, isNull);
    expect(notifier.state.accounts, hasLength(1));
    expect(notifier.state.selectedAccount?.projectId, 'demo-project');
  });

  test('rejects invalid service account json', () {
    final error = notifier.importServiceAccountJson('{"project_id":"x"}');
    expect(error, isNotNull);
    expect(notifier.state.accounts, isEmpty);
  });

  test('loads demo payload into simple fields', () {
    notifier.loadDemoPayload();
    expect(notifier.state.deviceToken, FcmDemoPayload.placeholderToken);
    expect(notifier.state.title, contains('Firebase'));
    expect(notifier.state.mode, FcmSendMode.simple);
  });

  test('clears accounts', () {
    notifier.importServiceAccountJson(_validServiceAccountJson());
    notifier.clearAccounts();
    expect(notifier.state.accounts, isEmpty);
    expect(notifier.state.selectedAccountId, isNull);
  });

  test('loads default account from fallback file path', () async {
    await notifier.ensureDefaultAccountLoaded(force: true);
    expect(notifier.state.selectedAccountId, FcmPushNotifier.defaultAccountId);
    expect(notifier.state.selectedAccount?.projectId, 'clp-bol');
    expect(notifier.state.selectedAccount?.label, startsWith('默认'));
  });
}

String _validServiceAccountJson() => '''
{
  "type": "service_account",
  "project_id": "demo-project",
  "private_key_id": "abc",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIE\\n-----END PRIVATE KEY-----\\n",
  "client_email": "svc@demo-project.iam.gserviceaccount.com",
  "client_id": "1234567890",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token"
}
''';
