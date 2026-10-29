import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/fcm_models.dart';
import 'fcm_auth_client.dart';

class FcmPushClient {
  final FcmAuthClient _auth;
  final http.Client _http;
  final String Function(String projectId) _messagesUrl;

  FcmPushClient({
    required this._auth,
    http.Client? httpClient,
    String Function(String projectId)? messagesUrlBuilder,
  }) : _http = httpClient ?? http.Client(),
       _messagesUrl =
           messagesUrlBuilder ??
           ((projectId) =>
               'https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

  /// Splits multi-token input by newlines and commas.
  static List<String> parseDeviceTokens(String raw) {
    final tokens = <String>[];
    for (final line in raw.split(RegExp(r'[\n,]'))) {
      final token = line.trim();
      if (token.isNotEmpty) tokens.add(token);
    }
    return tokens;
  }

  static bool validateToken(String token) {
    if (token.isEmpty) return false;
    final tokenRegex = RegExp(r'^[A-Za-z0-9_:-]+$');
    return token.length > 50 && tokenRegex.hasMatch(token);
  }

  static FcmValidationResult validateMessageData(Map<String, dynamic> messageData) {
    final errors = <String>[];
    late final String? token;
    late final Map<String, dynamic>? notification;
    final format = messageData.containsKey('message')
        ? FcmSendMode.fullJson
        : FcmSendMode.simple;

    if (format == FcmSendMode.fullJson) {
      final message = _asStringKeyedMap(messageData['message']);
      if (message == null) {
        return FcmValidationResult(
          isValid: false,
          errors: const ['message must be an object'],
          format: format,
        );
      }
      token = message['token']?.toString();
      notification = _asStringKeyedMap(message['notification']);
    } else {
      token = messageData['token']?.toString();
      notification = _asStringKeyedMap(messageData['notification']);
    }

    if (token == null || token.isEmpty) {
      errors.add('缺少设备token');
    } else if (!validateToken(token)) {
      errors.add('设备token格式不正确');
    }

    if (notification == null) {
      errors.add('缺少通知数据');
    } else {
      final title = notification['title'];
      final body = notification['body'];
      if (title == null || '$title'.trim().isEmpty) {
        errors.add('缺少通知标题');
      }
      if (body == null || '$body'.trim().isEmpty) {
        errors.add('缺少通知内容');
      }
    }

    return FcmValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      format: format,
    );
  }

  static Map<String, dynamic> buildFcmMessage(Map<String, dynamic> messageData) {
    if (messageData.containsKey('message')) {
      final message = _asStringKeyedMap(messageData['message']);
      if (message == null) {
        throw ArgumentError('message must be an object');
      }
      return message;
    }

    final token = messageData['token']?.toString();
    final notificationRaw = _asStringKeyedMap(messageData['notification']);
    if (token == null || notificationRaw == null) {
      throw ArgumentError('simple format requires token and notification');
    }

    final notification = <String, dynamic>{
      'title': notificationRaw['title'],
      'body': notificationRaw['body'],
    };
    if (notificationRaw['image'] != null) {
      notification['image'] = notificationRaw['image'];
    }

    final fcmMessage = <String, dynamic>{
      'token': token,
      'notification': notification,
    };

    final data = messageData['data'];
    if (data is Map) {
      fcmMessage['data'] = <String, String>{
        for (final entry in data.entries) '${entry.key}': '${entry.value}',
      };
    }

    final android = _asStringKeyedMap(messageData['android']);
    if (android != null) {
      fcmMessage['android'] = android;
    }

    return fcmMessage;
  }

  static Map<String, dynamic>? _asStringKeyedMap(Object? value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) {
      return value.map((key, dynamic v) => MapEntry('$key', v));
    }
    return null;
  }

  Future<FcmSendResult> sendNotification(
    Map<String, dynamic> messageData, {
    required String projectId,
    required String clientEmail,
    required String privateKey,
  }) async {
    final validation = validateMessageData(messageData);
    if (!validation.isValid) {
      return FcmSendResult(
        success: false,
        error: validation.errors.join(', '),
      );
    }

    try {
      final accessToken = await _auth.getAccessToken(
        clientEmail: clientEmail,
        privateKey: privateKey,
      );
      final fcmMessage = buildFcmMessage(messageData);
      final url = Uri.parse(_messagesUrl(projectId));
      final response = await _http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'message': fcmMessage}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return FcmSendResult(
          success: true,
          messageId: body['name'] as String?,
          data: body,
        );
      }

      return FcmSendResult(
        success: false,
        error: _formatHttpError(response),
      );
    } catch (error) {
      return FcmSendResult(success: false, error: _handleError(error));
    }
  }

  Future<FcmBatchResult> sendMulticastNotification({
    required List<String> tokens,
    required Map<String, dynamic> messageData,
    required String projectId,
    required String clientEmail,
    required String privateKey,
  }) async {
    final results = <FcmBatchItemResult>[];
    final failures = <FcmBatchItemResult>[];

    for (final token in tokens) {
      final single = Map<String, dynamic>.from(messageData);
      if (single.containsKey('message') && single['message'] is Map) {
        final message = Map<String, dynamic>.from(
          single['message'] as Map<String, dynamic>,
        );
        message['token'] = token;
        single['message'] = message;
      } else {
        single['token'] = token;
      }

      final result = await sendNotification(
        single,
        projectId: projectId,
        clientEmail: clientEmail,
        privateKey: privateKey,
      );

      final item = FcmBatchItemResult(
        token: token,
        success: result.success,
        messageId: result.messageId,
        error: result.error,
      );
      if (result.success) {
        results.add(item);
      } else {
        failures.add(item);
      }
    }

    return FcmBatchResult(
      totalCount: tokens.length,
      successCount: results.length,
      failureCount: failures.length,
      results: results,
      failures: failures,
    );
  }

  String _formatHttpError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        return _handleErrorBody(body) ??
            'HTTP ${response.statusCode}: ${response.reasonPhrase}';
      }
    } catch (_) {}
    return 'HTTP ${response.statusCode}: ${response.body}';
  }

  String _handleError(Object error) {
    if (error is http.ClientException) {
      return '网络连接失败，请检查网络连接';
    }
    return error.toString();
  }

  String? _handleErrorBody(Map<String, dynamic> errorData) {
    final error = errorData['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String && message.isNotEmpty) return message;
      final details = error['details'];
      if (details is List && details.isNotEmpty) {
        final first = details.first;
        if (first is Map && first['reason'] != null) {
          return '${first['reason']}';
        }
      }
    }
    return null;
  }
}
