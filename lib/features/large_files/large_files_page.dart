import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format/byte_format.dart';
import '../../core/theme/safety_colors.dart';
import '../../domain/models/large_file.dart';
import '../../providers/large_files_provider.dart';
import '../../providers/infra_providers.dart';
import 'package:intl/intl.dart';

class LargeFilesPage extends ConsumerWidget {
  const LargeFilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(largeFilesProvider);
    final notifier = ref.read(largeFilesProvider.notifier);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Large Files'),
        elevation: 0,
        actions: [
          if (state.files.isNotEmpty && !state.scanning) ...[
            TextButton(
              onPressed: () => notifier.toggleAll(true),
              child: const Text('全选'),
            ),
            TextButton(
              onPressed: () => notifier.toggleAll(false),
              child: const Text('取消全选'),
            ),
          ],
          TextButton.icon(
            onPressed: state.scanning ? null : () => notifier.scan(),
            icon: state.scanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.search_rounded),
            label: Text(state.scanning ? '扫描中...' : '扫描'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.files.isEmpty && !state.scanning
          ? _EmptyState(threshold: settings.largeFileThresholdMB, onScan: () => notifier.scan())
          : Column(
              children: [
                if (state.scanning)
                  const LinearProgressIndicator(),
                if (state.deletedCount != null)
                  _DoneBanner(
                    count: state.deletedCount!,
                    bytes: state.reclaimedBytes ?? 0,
                  ),
                _SummaryBar(state: state, notifier: notifier),
                const Divider(height: 1),
                Expanded(child: _FileList(state: state, notifier: notifier)),
                if (state.selectedCount > 0)
                  _CleanBar(
                    state: state,
                    onClean: () => _confirmAndDelete(context, ref, notifier),
                  ),
              ],
            ),
    );
  }

  Future<void> _confirmAndDelete(
      BuildContext ctx, WidgetRef ref, LargeFilesNotifier notifier) async {
    final toDelete = notifier.dryRun();
    if (toDelete.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('没有可安全删除的文件（PathGuard 拦截）')),
      );
      return;
    }

    final totalBytes = toDelete.fold(0, (s, f) => s + f.sizeBytes);

    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('确认删除'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${toDelete.length} 个文件 · 共 ${formatBytes(totalBytes)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                '这些文件将被永久删除，无法恢复。',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: toDelete
                        .map((f) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.insert_drive_file_rounded,
                                      size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      f.path,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          color: Colors.grey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    formatBytes(f.sizeBytes),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: SafetyColors.danger),
            child: const Text('永久删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      notifier.deleteSelected();
    }
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final int threshold;
  final VoidCallback onScan;
  const _EmptyState({required this.threshold, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('查找大于 $threshold MB 的文件',
              style: const TextStyle(color: Colors.grey, fontSize: 15)),
          const SizedBox(height: 8),
          const Text(
            '安全分类：缓存/临时文件自动标绿，系统/SDK/源码文件不会列出',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.search_rounded),
            label: const Text('开始扫描'),
          ),
        ],
      ),
    );
  }
}

// ── Summary Bar ───────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final LargeFilesState state;
  final LargeFilesNotifier notifier;
  const _SummaryBar({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final safeCount = state.files.where((f) => f.safety == LargeFileSafety.safe).length;
    final cautionCount = state.files.where((f) => f.safety == LargeFileSafety.caution).length;
    final total = state.files.fold(0, (s, f) => s + f.sizeBytes);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text('共 ${state.files.length} 个文件 · ${formatBytes(total)}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          if (safeCount > 0)
            _Tag(
              color: SafetyColors.safe,
              label: '安全 $safeCount',
              onTap: () => notifier.selectBySafety(LargeFileSafety.safe, true),
            ),
          const SizedBox(width: 6),
          if (cautionCount > 0)
            _Tag(
              color: SafetyColors.caution,
              label: '需确认 $cautionCount',
              onTap: () => notifier.selectBySafety(LargeFileSafety.caution, true),
            ),
          const Spacer(),
          if (state.scanning)
            const Text('扫描中...', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _Tag({required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── File List ─────────────────────────────────────────────────────────────────

class _FileList extends StatelessWidget {
  final LargeFilesState state;
  final LargeFilesNotifier notifier;
  const _FileList({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    // Group by safety
    final safeFiles = state.files.where((f) => f.safety == LargeFileSafety.safe).toList();
    final cautionFiles = state.files.where((f) => f.safety == LargeFileSafety.caution).toList();

    final items = <Widget>[];

    if (safeFiles.isNotEmpty) {
      items.add(_SectionHeader(
        label: '可安全删除',
        color: SafetyColors.safe,
        count: safeFiles.length,
        totalBytes: safeFiles.fold(0, (s, f) => s + f.sizeBytes),
        onSelectAll: () => notifier.selectBySafety(LargeFileSafety.safe, true),
        onDeselectAll: () => notifier.selectBySafety(LargeFileSafety.safe, false),
      ));
      for (final f in safeFiles) {
        items.add(_FileTile(file: f, onToggle: (v) => notifier.toggle(f.path, v)));
      }
    }

    if (cautionFiles.isNotEmpty) {
      items.add(_SectionHeader(
        label: '需要确认',
        color: SafetyColors.caution,
        count: cautionFiles.length,
        totalBytes: cautionFiles.fold(0, (s, f) => s + f.sizeBytes),
        onSelectAll: () => notifier.selectBySafety(LargeFileSafety.caution, true),
        onDeselectAll: () => notifier.selectBySafety(LargeFileSafety.caution, false),
      ));
      for (final f in cautionFiles) {
        items.add(_FileTile(file: f, onToggle: (v) => notifier.toggle(f.path, v)));
      }
    }

    return ListView(padding: const EdgeInsets.only(bottom: 80), children: items);
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  final int totalBytes;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  const _SectionHeader({
    required this.label,
    required this.color,
    required this.count,
    required this.totalBytes,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.06),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: color)),
          const SizedBox(width: 8),
          Text('$count 个 · ${formatBytes(totalBytes)}',
              style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7))),
          const Spacer(),
          TextButton(
            onPressed: onSelectAll,
            style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('全选', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: onDeselectAll,
            style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: const Text('取消', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final LargeFile file;
  final ValueChanged<bool> onToggle;
  const _FileTile({required this.file, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd');
    final safeColor = file.safety == LargeFileSafety.safe
        ? SafetyColors.safe
        : SafetyColors.caution;

    return CheckboxListTile(
      value: file.selected,
      onChanged: (v) => onToggle(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      title: Row(
        children: [
          Expanded(
            child: Text(
              file.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: safeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              file.safety == LargeFileSafety.safe ? '安全' : '需确认',
              style: TextStyle(fontSize: 10, color: safeColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            file.path,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            file.safetyReason,
            style: TextStyle(fontSize: 10, color: safeColor.withValues(alpha: 0.8)),
          ),
        ],
      ),
      secondary: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatBytes(file.sizeBytes),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          Text(
            fmt.format(file.modifiedAt),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          GestureDetector(
            onTap: () => Process.run('open', ['-R', file.path]),
            child: const Text(
              '在 Finder 中显示',
              style: TextStyle(fontSize: 10, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Clean Bar ─────────────────────────────────────────────────────────────────

class _CleanBar extends StatelessWidget {
  final LargeFilesState state;
  final VoidCallback onClean;
  const _CleanBar({required this.state, required this.onClean});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.delete_sweep_rounded,
            color: state.files.any((f) => f.selected && f.safety == LargeFileSafety.safe)
                ? SafetyColors.safe
                : SafetyColors.caution,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '已选 ${state.selectedCount} 个文件',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '共 ${formatBytes(state.selectedBytes)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),
          if (state.deleting)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            FilledButton.icon(
              onPressed: onClean,
              icon: const Icon(Icons.delete_rounded),
              label: const Text('删除所选'),
              style: FilledButton.styleFrom(backgroundColor: SafetyColors.danger),
            ),
        ],
      ),
    );
  }
}

// ── Done Banner ───────────────────────────────────────────────────────────────

class _DoneBanner extends StatelessWidget {
  final int count;
  final int bytes;
  const _DoneBanner({required this.count, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: SafetyColors.safeLight,
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: SafetyColors.safe, size: 18),
          const SizedBox(width: 8),
          Text(
            '已删除 $count 个文件，释放 ${formatBytes(bytes)}',
            style: const TextStyle(
                color: SafetyColors.safe, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
