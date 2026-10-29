import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fcm/fcm_auth_client.dart';
import '../data/fcm/fcm_demo_payload.dart';
import '../data/fcm/fcm_push_client.dart';
import '../data/fcm/fcm_service_account_parser.dart';
import '../domain/models/fcm_models.dart';

class FcmPushState {
  final List<FcmServiceAccount> accounts;
  final String? selectedAccountId;
  final FcmSendMode mode;
  final String deviceToken;
  final String title;
  final String body;
  final String imageUrl;
  final String dataJson;
  final String fullJson;
  final String? accessTokenPreview;
  final String? lastResult;
  final String? error;
  final bool busy;
  final List<FcmSendRecord> history;

  const FcmPushState({
    this.accounts = const [],
    this.selectedAccountId,
    this.mode = FcmSendMode.simple,
    this.deviceToken = '',
    this.title = '',
    this.body = '',
    this.imageUrl = '',
    this.dataJson = '{\n  \n}',
    this.fullJson = '{\n  "message": {\n  }\n}',
    this.accessTokenPreview,
    this.lastResult,
    this.error,
    this.busy = false,
    this.history = const [],
  });

  FcmServiceAccount? get selectedAccount {
    if (selectedAccountId == null) return null;
    for (final account in accounts) {
      if (account.id == selectedAccountId) return account;
    }
    return null;
  }

  FcmPushState copyWith({
    List<FcmServiceAccount>? accounts,
    String? selectedAccountId,
    bool clearSelectedAccount = false,
    FcmSendMode? mode,
    String? deviceToken,
    String? title,
    String? body,
    String? imageUrl,
    String? dataJson,
    String? fullJson,
    String? accessTokenPreview,
    bool clearAccessTokenPreview = false,
    String? lastResult,
    bool clearLastResult = false,
    String? error,
    bool clearError = false,
    bool? busy,
    List<FcmSendRecord>? history,
  }) {
    return FcmPushState(
      accounts: accounts ?? this.accounts,
      selectedAccountId: clearSelectedAccount
          ? null
          : (selectedAccountId ?? this.selectedAccountId),
      mode: mode ?? this.mode,
      deviceToken: deviceToken ?? this.deviceToken,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      dataJson: dataJson ?? this.dataJson,
      fullJson: fullJson ?? this.fullJson,
      accessTokenPreview: clearAccessTokenPreview
          ? null
          : (accessTokenPreview ?? this.accessTokenPreview),
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
      error: clearError ? null : (error ?? this.error),
      busy: busy ?? this.busy,
      history: history ?? this.history,
    );
  }
}

final fcmAuthClientProvider = Provider<FcmAuthClient>((ref) => FcmAuthClient());

final fcmPushClientProvider = Provider<FcmPushClient>((ref) {
  return FcmPushClient(auth: ref.watch(fcmAuthClientProvider));
});

final fcmPushProvider =
    StateNotifierProvider<FcmPushNotifier, FcmPushState>((ref) {
      return FcmPushNotifier(
        auth: ref.watch(fcmAuthClientProvider),
        push: ref.watch(fcmPushClientProvider),
      );
    });

class FcmPushNotifier extends StateNotifier<FcmPushState> {
  FcmPushNotifier({
    required this._auth,
    required this._push,
  }) : super(FcmPushState(fullJson: FcmDemoPayload.fullJsonTemplate()));

  final FcmAuthClient _auth;
  final FcmPushClient _push;

  void setMode(FcmSendMode mode) {
    state = state.copyWith(mode: mode, clearError: true);
  }

  void updateSimpleFields({
    String? deviceToken,
    String? title,
    String? body,
    String? imageUrl,
    String? dataJson,
  }) {
    state = state.copyWith(
      deviceToken: deviceToken,
      title: title,
      body: body,
      imageUrl: imageUrl,
      dataJson: dataJson,
      clearError: true,
    );
  }

  void updateFullJson(String value) {
    state = state.copyWith(fullJson: value, clearError: true);
  }

  String? importServiceAccountJson(String raw, {String? label}) {
    final parsed = FcmServiceAccountParser.parseJsonString(raw, label: label);
    if (!parsed.isValid || parsed.account == null) {
      state = state.copyWith(error: parsed.errors.join(', '));
      return parsed.errors.join(', ');
    }
    final account = parsed.account!;
    final accounts = [...state.accounts, account];
    _auth.clearCache();
    state = state.copyWith(
      accounts: accounts,
      selectedAccountId: account.id,
      clearError: true,
      clearAccessTokenPreview: true,
    );
    return null;
  }

  Future<String?> importServiceAccountFile(String path, {String? label}) async {
    try {
      final raw = await File(path).readAsString();
      return importServiceAccountJson(raw, label: label);
    } catch (error) {
      final message = '读取配置文件失败: $error';
      state = state.copyWith(error: message);
      return message;
    }
  }

  void selectAccount(String id) {
    _auth.clearCache();
    state = state.copyWith(
      selectedAccountId: id,
      clearAccessTokenPreview: true,
      clearError: true,
    );
  }

  void removeAccount(String id) {
    final accounts = state.accounts.where((a) => a.id != id).toList();
    final selected = state.selectedAccountId == id
        ? (accounts.isEmpty ? null : accounts.first.id)
        : state.selectedAccountId;
    _auth.clearCache();
    state = state.copyWith(
      accounts: accounts,
      selectedAccountId: selected,
      clearSelectedAccount: selected == null,
      clearAccessTokenPreview: true,
      clearError: true,
    );
  }

  void clearAccounts() {
    _auth.clearCache();
    state = state.copyWith(
      accounts: const [],
      clearSelectedAccount: true,
      clearAccessTokenPreview: true,
      clearError: true,
    );
  }

  void loadDemoPayload() {
    final demo = FcmDemoPayload.simpleNotification();
    final notification = demo['notification'] as Map<String, dynamic>;
    state = state.copyWith(
      deviceToken: demo['token'] as String,
      title: notification['title'] as String,
      body: notification['body'] as String,
      imageUrl: notification['image'] as String? ?? '',
      dataJson: const JsonEncoder.withIndent('  ').convert(demo['data']),
      fullJson: FcmDemoPayload.fullJsonTemplate(),
      clearError: true,
    );
  }

  Future<void> generateAccessToken() async {
    final account = state.selectedAccount;
    if (account == null) {
      state = state.copyWith(error: '请先导入 Firebase 服务账号');
      return;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      final token = await _auth.getAccessToken(
        clientEmail: account.clientEmail,
        privateKey: account.privateKey,
      );
      final preview = token.length <= 28
          ? token
          : '${token.substring(0, 16)}...${token.substring(token.length - 8)}';
      state = state.copyWith(
        busy: false,
        accessTokenPreview: preview,
        lastResult: 'Access Token 已生成（仅预览，完整值不落盘）',
      );
    } catch (error) {
      state = state.copyWith(busy: false, error: error.toString());
    }
  }

  Map<String, dynamic>? _buildOutgoingMessage() {
    if (state.mode == FcmSendMode.fullJson) {
      try {
        final decoded = jsonDecode(state.fullJson);
        if (decoded is! Map) {
          state = state.copyWith(error: '完整 JSON 必须是对象');
          return null;
        }
        return decoded.map((key, value) => MapEntry('$key', value));
      } catch (_) {
        state = state.copyWith(error: '完整 JSON 解析失败');
        return null;
      }
    }

    Map<String, dynamic>? data;
    final trimmedData = state.dataJson.trim();
    if (trimmedData.isNotEmpty && trimmedData != '{}') {
      try {
        final decoded = jsonDecode(trimmedData);
        if (decoded is Map) {
          data = decoded.map((key, value) => MapEntry('$key', value));
        } else {
          state = state.copyWith(error: 'data 必须是 JSON 对象');
          return null;
        }
      } catch (_) {
        state = state.copyWith(error: 'data JSON 解析失败');
        return null;
      }
    }

    final notification = <String, dynamic>{
      'title': state.title,
      'body': state.body,
    };
    if (state.imageUrl.trim().isNotEmpty) {
      notification['image'] = state.imageUrl.trim();
    }

    return {
      'token': state.deviceToken.trim(),
      'notification': notification,
      'data': ?data,
    };
  }

  Future<void> sendSingle() async {
    final account = state.selectedAccount;
    if (account == null) {
      state = state.copyWith(error: '请先导入 Firebase 服务账号');
      return;
    }
    final message = _buildOutgoingMessage();
    if (message == null) return;

    state = state.copyWith(busy: true, clearError: true, clearLastResult: true);
    final result = await _push.sendNotification(
      message,
      projectId: account.projectId,
      clientEmail: account.clientEmail,
      privateKey: account.privateKey,
    );

    final record = FcmSendRecord(
      at: DateTime.now(),
      projectId: account.projectId,
      mode: state.mode,
      success: result.success,
      messageId: result.messageId,
      errorSummary: result.error,
    );

    state = state.copyWith(
      busy: false,
      lastResult: result.success
          ? '发送成功: ${result.messageId}'
          : null,
      error: result.success ? null : result.error,
      clearError: result.success,
      history: [record, ...state.history].take(50).toList(),
    );
  }

  Future<void> sendBatch(String rawTokens) async {
    final account = state.selectedAccount;
    if (account == null) {
      state = state.copyWith(error: '请先导入 Firebase 服务账号');
      return;
    }
    final tokens = FcmPushClient.parseDeviceTokens(rawTokens);
    if (tokens.isEmpty) {
      state = state.copyWith(error: '请填写至少一个设备 token');
      return;
    }

    final base = _buildOutgoingMessage();
    if (base == null) return;
    // Drop single token so multicast injects each token.
    base.remove('token');
    if (base['message'] is Map) {
      final message = Map<String, dynamic>.from(base['message'] as Map);
      message.remove('token');
      base['message'] = message;
    }

    state = state.copyWith(busy: true, clearError: true, clearLastResult: true);
    final batch = await _push.sendMulticastNotification(
      tokens: tokens,
      messageData: base,
      projectId: account.projectId,
      clientEmail: account.clientEmail,
      privateKey: account.privateKey,
    );

    final record = FcmSendRecord(
      at: DateTime.now(),
      projectId: account.projectId,
      mode: state.mode,
      success: batch.failureCount == 0,
      errorSummary: batch.failureCount == 0
          ? null
          : '${batch.failureCount} 条失败',
      batchTotal: batch.totalCount,
      batchSuccess: batch.successCount,
      batchFailure: batch.failureCount,
    );

    final summary =
        '批量完成: 成功 ${batch.successCount}/${batch.totalCount}，失败 ${batch.failureCount}';
    final failureDetail = batch.failures
        .take(5)
        .map((f) => '${f.token.substring(0, 12)}…: ${f.error}')
        .join('\n');

    state = state.copyWith(
      busy: false,
      lastResult: summary,
      error: batch.failureCount == 0
          ? null
          : (failureDetail.isEmpty ? summary : '$summary\n$failureDetail'),
      clearError: batch.failureCount == 0,
      history: [record, ...state.history].take(50).toList(),
    );
  }
}
