enum FcmSendMode { simple, fullJson }

class FcmServiceAccount {
  final String id;
  final String label;
  final String projectId;
  final String clientEmail;
  final String privateKey;
  final String? clientId;
  final String? type;

  const FcmServiceAccount({
    required this.id,
    required this.label,
    required this.projectId,
    required this.clientEmail,
    required this.privateKey,
    this.clientId,
    this.type,
  });

  FcmServiceAccount copyWith({String? label}) => FcmServiceAccount(
    id: id,
    label: label ?? this.label,
    projectId: projectId,
    clientEmail: clientEmail,
    privateKey: privateKey,
    clientId: clientId,
    type: type,
  );
}

class FcmValidationResult {
  final bool isValid;
  final List<String> errors;
  final FcmSendMode format;

  const FcmValidationResult({
    required this.isValid,
    required this.errors,
    required this.format,
  });
}

class FcmSendResult {
  final bool success;
  final String? messageId;
  final Map<String, dynamic>? data;
  final String? error;

  const FcmSendResult({
    required this.success,
    this.messageId,
    this.data,
    this.error,
  });
}

class FcmBatchItemResult {
  final String token;
  final bool success;
  final String? messageId;
  final String? error;

  const FcmBatchItemResult({
    required this.token,
    required this.success,
    this.messageId,
    this.error,
  });
}

class FcmBatchResult {
  final int totalCount;
  final int successCount;
  final int failureCount;
  final List<FcmBatchItemResult> results;
  final List<FcmBatchItemResult> failures;

  const FcmBatchResult({
    required this.totalCount,
    required this.successCount,
    required this.failureCount,
    required this.results,
    required this.failures,
  });
}

class FcmSendRecord {
  final DateTime at;
  final String projectId;
  final FcmSendMode mode;
  final bool success;
  final String? messageId;
  final String? errorSummary;
  final int? batchTotal;
  final int? batchSuccess;
  final int? batchFailure;

  const FcmSendRecord({
    required this.at,
    required this.projectId,
    required this.mode,
    required this.success,
    this.messageId,
    this.errorSummary,
    this.batchTotal,
    this.batchSuccess,
    this.batchFailure,
  });
}
