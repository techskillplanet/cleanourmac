import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format/byte_format.dart';
import '../../core/l10n/localization_extensions.dart';
import '../../core/theme/safety_colors.dart';
import '../../core/widgets/app_page_title.dart';
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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: AppPageTitle(
          title: l10n.largeFiles,
          subtitle: l10n.largeFilesSubtitle,
        ),
        actions: [
          if (state.files.isNotEmpty && !state.scanning) ...[
            TextButton(
              onPressed: () => notifier.toggleAll(true),
              child: Text(l10n.selectAll),
            ),
            TextButton(
              onPressed: () => notifier.toggleAll(false),
              child: Text(l10n.deselectAll),
            ),
          ],
          TextButton.icon(
            onPressed: state.scanning ? null : () => notifier.scan(),
            icon: state.scanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search_rounded),
            label: Text(state.scanning ? l10n.scanning : l10n.scan),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.files.isEmpty && !state.scanning
          ? _EmptyState(
              threshold: settings.largeFileThresholdMB,
              onScan: () => notifier.scan(),
            )
          : Column(
              children: [
                if (state.scanning) const LinearProgressIndicator(),
                if (state.deletedCount != null)
                  _DoneBanner(
                    count: state.deletedCount!,
                    bytes: state.reclaimedBytes ?? 0,
                  ),
                _SummaryBar(state: state, notifier: notifier),
                const Divider(height: 1),
                Expanded(
                  child: _FileList(state: state, notifier: notifier),
                ),
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
    BuildContext ctx,
    WidgetRef ref,
    LargeFilesNotifier notifier,
  ) async {
    final toDelete = notifier.dryRun();
    if (toDelete.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(ctx.l10n.largeFilesNoSafeCandidates)),
      );
      return;
    }

    final totalBytes = toDelete.fold(0, (s, f) => s + f.sizeBytes);

    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text(ctx.l10n.confirmDelete),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ctx.l10n.fileDeleteSummary(
                  toDelete.length,
                  formatBytes(totalBytes, locale: ctx.localeName),
                ),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                ctx.l10n.permanentDeleteWarning,
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.error,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: toDelete
                        .map(
                          (f) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.insert_drive_file_rounded,
                                  size: 12,
                                  color: Theme.of(
                                    ctx,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    f.path,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: Theme.of(
                                        ctx,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  formatBytes(
                                    f.sizeBytes,
                                    locale: ctx.localeName,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
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
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(
              backgroundColor: SafetyColors.dangerFor(ctx),
            ),
            child: Text(ctx.l10n.permanentlyDelete),
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
          Icon(
            Icons.folder_open_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.findFilesOver(threshold),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.largeFileSafetyDescription,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.search_rounded),
            label: Text(context.l10n.startScan),
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
    final safeCount = state.files
        .where((f) => f.safety == LargeFileSafety.safe)
        .length;
    final cautionCount = state.files
        .where((f) => f.safety == LargeFileSafety.caution)
        .length;
    final total = state.files.fold(0, (s, f) => s + f.sizeBytes);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            context.l10n.largeFilesSummary(
              state.files.length,
              formatBytes(total, locale: context.localeName),
            ),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          if (safeCount > 0)
            _Tag(
              color: SafetyColors.safeFor(context),
              label: context.l10n.safeCount(safeCount),
              onTap: () => notifier.selectBySafety(LargeFileSafety.safe, true),
            ),
          const SizedBox(width: 6),
          if (cautionCount > 0)
            _Tag(
              color: SafetyColors.cautionFor(context),
              label: context.l10n.cautionCount(cautionCount),
              onTap: () =>
                  notifier.selectBySafety(LargeFileSafety.caution, true),
            ),
          const Spacer(),
          if (state.scanning)
            Text(
              context.l10n.scanning,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
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
    final safeFiles = state.files
        .where((f) => f.safety == LargeFileSafety.safe)
        .toList();
    final cautionFiles = state.files
        .where((f) => f.safety == LargeFileSafety.caution)
        .toList();

    final items = <Widget>[];

    if (safeFiles.isNotEmpty) {
      items.add(
        _SectionHeader(
          label: context.l10n.safeToDelete,
          color: SafetyColors.safeFor(context),
          count: safeFiles.length,
          totalBytes: safeFiles.fold(0, (s, f) => s + f.sizeBytes),
          onSelectAll: () =>
              notifier.selectBySafety(LargeFileSafety.safe, true),
          onDeselectAll: () =>
              notifier.selectBySafety(LargeFileSafety.safe, false),
        ),
      );
      for (final f in safeFiles) {
        items.add(
          _FileTile(file: f, onToggle: (v) => notifier.toggle(f.path, v)),
        );
      }
    }

    if (cautionFiles.isNotEmpty) {
      items.add(
        _SectionHeader(
          label: context.l10n.requiresReview,
          color: SafetyColors.cautionFor(context),
          count: cautionFiles.length,
          totalBytes: cautionFiles.fold(0, (s, f) => s + f.sizeBytes),
          onSelectAll: () =>
              notifier.selectBySafety(LargeFileSafety.caution, true),
          onDeselectAll: () =>
              notifier.selectBySafety(LargeFileSafety.caution, false),
        ),
      );
      for (final f in cautionFiles) {
        items.add(
          _FileTile(file: f, onToggle: (v) => notifier.toggle(f.path, v)),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: items,
    );
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
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            context.l10n.countAndSize(
              count,
              formatBytes(totalBytes, locale: context.localeName),
            ),
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7)),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSelectAll,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              context.l10n.selectAll,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onDeselectAll,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              context.l10n.cancel,
              style: const TextStyle(fontSize: 12),
            ),
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
    final l10n = context.l10n;
    final fmt = DateFormat.yMd(context.localeName);
    final safeColor = file.safety == LargeFileSafety.safe
        ? SafetyColors.safeFor(context)
        : SafetyColors.cautionFor(context);

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
              l10n.largeFileSafetyLabel(file.safety),
              style: TextStyle(
                fontSize: 10,
                color: safeColor,
                fontWeight: FontWeight.w600,
              ),
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
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            l10n.largeFileSafetyReason(file.safety),
            style: TextStyle(
              fontSize: 10,
              color: safeColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      secondary: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatBytes(file.sizeBytes, locale: context.localeName),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          Text(
            fmt.format(file.modifiedAt),
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          GestureDetector(
            onTap: () => Process.run('open', ['-R', file.path]),
            child: Text(
              l10n.showInFinder,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.primary,
              ),
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
            color:
                state.files.any(
                  (f) => f.selected && f.safety == LargeFileSafety.safe,
                )
                ? SafetyColors.safeFor(context)
                : SafetyColors.cautionFor(context),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.selectedFiles(state.selectedCount),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                context.l10n.totalSize(
                  formatBytes(state.selectedBytes, locale: context.localeName),
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (state.deleting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            FilledButton.icon(
              onPressed: onClean,
              icon: const Icon(Icons.delete_rounded),
              label: Text(context.l10n.deleteSelected),
              style: FilledButton.styleFrom(
                backgroundColor: SafetyColors.dangerFor(context),
              ),
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
      color: SafetyColors.safeSurfaceFor(context),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: SafetyColors.safeFor(context),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            context.l10n.deletedFilesSummary(
              count,
              formatBytes(bytes, locale: context.localeName),
            ),
            style: TextStyle(
              color: SafetyColors.safeFor(context),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
