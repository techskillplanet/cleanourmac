import 'cleanup_target.dart';

enum ScanItemDetailType { simulator, runtime, runtimeCache }

class ScanItem {
  final String path;
  final int sizeBytes;
  final SafetyLevel safety;
  final String? displayName;
  final String? detail;
  final ScanItemDetailType? detailType;
  final String? detailValue;
  final DateTime? detailDate;
  final String? actionId;
  bool selected;

  ScanItem({
    required this.path,
    required this.sizeBytes,
    required this.safety,
    this.displayName,
    this.detail,
    this.detailType,
    this.detailValue,
    this.detailDate,
    this.actionId,
    this.selected = true,
  });

  String get name => displayName ?? path.split('/').last;

  ScanItem copyWith({bool? selected}) => ScanItem(
    path: path,
    sizeBytes: sizeBytes,
    safety: safety,
    displayName: displayName,
    detail: detail,
    detailType: detailType,
    detailValue: detailValue,
    detailDate: detailDate,
    actionId: actionId,
    selected: selected ?? this.selected,
  );
}
