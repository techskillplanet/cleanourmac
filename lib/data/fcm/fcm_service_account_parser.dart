import 'dart:convert';

import '../../domain/models/fcm_models.dart';

class FcmServiceAccountParseResult {
  final FcmServiceAccount? account;
  final List<String> errors;

  const FcmServiceAccountParseResult({this.account, required this.errors});

  bool get isValid => account != null && errors.isEmpty;
}

class FcmServiceAccountParser {
  static FcmServiceAccountParseResult parseJsonString(
    String raw, {
    String? id,
    String? label,
  }) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const FcmServiceAccountParseResult(errors: ['JSON 解析失败']);
    }
    if (decoded is! Map) {
      return const FcmServiceAccountParseResult(errors: ['配置必须是一个有效的JSON对象']);
    }
    return parseMap(
      decoded.map((key, value) => MapEntry('$key', value)),
      id: id,
      label: label,
    );
  }

  static FcmServiceAccountParseResult parseMap(
    Map<String, dynamic> config, {
    String? id,
    String? label,
  }) {
    final errors = <String>[];
    const requiredFields = {
      'project_id': '项目ID',
      'private_key': '私钥',
      'client_email': '客户端邮箱',
      'client_id': '客户端ID',
      'auth_uri': '认证URI',
      'token_uri': 'Token URI',
      'type': '服务账号类型',
    };

    for (final entry in requiredFields.entries) {
      final value = config[entry.key];
      if (value == null || '$value'.trim().isEmpty) {
        errors.add('缺少必需字段: ${entry.key} (${entry.value})');
      }
    }

    if (config['type'] != null && config['type'] != 'service_account') {
      errors.add('type字段必须为 "service_account"');
    }

    final email = config['client_email']?.toString() ?? '';
    if (email.isNotEmpty && !email.contains('@')) {
      errors.add('client_email格式不正确，应包含@符号');
    }

    final privateKey = config['private_key']?.toString() ?? '';
    if (privateKey.isNotEmpty && !privateKey.contains('BEGIN PRIVATE KEY') &&
        !privateKey.contains('BEGIN RSA PRIVATE KEY')) {
      errors.add('private_key格式不正确，应为PEM格式');
    }

    final projectId = config['project_id']?.toString() ?? '';
    if (projectId.isNotEmpty && !RegExp(r'^[a-z0-9-]+$').hasMatch(projectId)) {
      errors.add('project_id格式不正确，应只包含小写字母、数字和连字符');
    }

    if (errors.isNotEmpty) {
      return FcmServiceAccountParseResult(errors: errors);
    }

    final resolvedId =
        id ??
        '${projectId}_${email.hashCode}_${DateTime.now().microsecondsSinceEpoch}';
    final resolvedLabel = label ?? '$projectId ($email)';

    return FcmServiceAccountParseResult(
      account: FcmServiceAccount(
        id: resolvedId,
        label: resolvedLabel,
        projectId: projectId,
        clientEmail: email,
        privateKey: privateKey.replaceAll(r'\n', '\n'),
        clientId: config['client_id']?.toString(),
        type: config['type']?.toString(),
      ),
      errors: const [],
    );
  }
}
