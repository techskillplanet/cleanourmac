import 'cleanup_target.dart';

class ScanItem {
  final String path;
  final int sizeBytes;
  final SafetyLevel safety;
  final String? displayName;
  final String? detail;
  final String? actionId;
  bool selected;

  ScanItem({
    required this.path,
    required this.sizeBytes,
    required this.safety,
    this.displayName,
    this.detail,
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
    actionId: actionId,
    selected: selected ?? this.selected,
  );
}
