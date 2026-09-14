import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format/byte_format.dart';
import '../../core/l10n/localization_extensions.dart';
import '../../core/theme/safety_colors.dart';
import '../../core/widgets/app_page_title.dart';
import '../../domain/models/category_summary.dart';
import '../../domain/models/cleanup_target.dart';
import '../../domain/models/disk_usage.dart';
import '../../domain/models/scan_state.dart';
import '../../providers/scan_providers.dart';
import '../../providers/clean_providers.dart';
import '../../providers/infra_providers.dart';
import '../categories/category_page.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(scanProvider);
    final recoverable = ref.watch(recoverableBytesProvider);
    final candidates = ref.watch(cleanupCandidateBytesProvider);
    final clean = ref.watch(cleanProvider);
    final diskAsync = ref.watch(diskUsageProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: AppPageTitle(
          title: l10n.scanAndClean,
          subtitle: l10n.scanPageSubtitle,
        ),
        actions: [
          if (scan.phase == ScanPhase.scanning)
            TextButton.icon(
              onPressed: () => ref.read(scanProvider.notifier).cancel(),
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(l10n.cancel),
            )
          else
            TextButton.icon(
              onPressed: () => ref.read(scanProvider.notifier).startScan(),
              icon: const Icon(Icons.search_rounded),
              label: Text(l10n.scan),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (scan.phase == ScanPhase.scanning) ...[
            LinearProgressIndicator(
              value: scan.progress == 0 ? null : scan.progress,
            ),
            if (scan.currentTargetId != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  l10n.scanningTarget(
                    l10n.cleanupTargetLabel(
                      scan.currentTargetId!,
                      fallback:
                          scan.categories[scan.currentTargetId]?.target.label ??
                          scan.currentTargetId!,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
          if (clean != null && !clean.finished)
            Column(
              children: [
                LinearProgressIndicator(
                  value: clean.fraction,
                  color: SafetyColors.safeFor(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    l10n.cleaningReclaimed(
                      formatBytes(
                        clean.reclaimedBytes,
                        locale: context.localeName,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          Expanded(
            child: scan.categories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.scanEmptyPrompt,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () =>
                              ref.read(scanProvider.notifier).startScan(),
                          icon: const Icon(Icons.search_rounded),
                          label: Text(l10n.startScan),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      diskAsync.when(
                        data: (disk) => _MainDiskCard(
                          disk: disk,
                          candidateBytes: candidates,
                          selectedBytes: recoverable,
                        ),
                        loading: () => const _MainDiskLoadingCard(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 12),
                      ...scan.categories.values.map(
                        (cat) => _CategoryCard(summary: cat),
                      ),
                    ],
                  ),
          ),
          if (scan.phase == ScanPhase.done && recoverable > 0)
            _CleanBar(
              recoverable: recoverable,
              onClean: () => _showCleanDialog(context, ref, scan),
            ),
          if (clean?.finished == true)
            _DoneBar(
              reclaimed: clean!.reclaimedBytes,
              onDismiss: () {
                ref.read(cleanProvider.notifier).reset();
                ref.invalidate(diskUsageProvider);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _showCleanDialog(
    BuildContext ctx,
    WidgetRef ref,
    ScanState scan,
  ) async {
    final l10n = ctx.l10n;
    final locale = ctx.localeName;
    final summaries = ref.read(scanProvider.notifier).selectedSummaries;
    final repo = ref.read(cleanRepositoryProvider);
    final items = repo.dryRun(summaries);
    final total = items.fold(0, (s, i) => s + i.sizeBytes);

    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text(l10n.confirmClean),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.cleanDeleteSummary(
                  items.length,
                  formatBytes(total, locale: locale),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items
                        .map(
                          (i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              i.path,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
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
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(
              backgroundColor: SafetyColors.dangerFor(context),
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm == true && ctx.mounted) {
      ref.read(cleanProvider.notifier).execute(summaries);
    }
  }
}

class _MainDiskCard extends StatelessWidget {
  final DiskUsage disk;
  final int candidateBytes;
  final int selectedBytes;

  const _MainDiskCard({
    required this.disk,
    required this.candidateBytes,
    required this.selectedBytes,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final locale = context.localeName;
    return Card(
      color: cs.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.laptop_mac_rounded, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.macintoshDiskName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.primaryDataVolumeDescription,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.diskUsed(
                    formatDiskBytes(disk.usedBytes, locale: locale),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: disk.usedFraction.clamp(0.0, 1.0).toDouble(),
                minHeight: 8,
                backgroundColor: cs.surface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _DiskMetric(
                  label: l10n.capacity,
                  value: formatDiskBytes(disk.totalBytes, locale: locale),
                ),
                const SizedBox(width: 28),
                _DiskMetric(
                  label: l10n.overviewFree,
                  value: formatDiskBytes(disk.freeBytes, locale: locale),
                ),
                const Spacer(),
                _DiskMetric(
                  label: l10n.candidatesFound,
                  value: formatBytes(candidateBytes, locale: locale),
                  color: SafetyColors.cautionFor(context),
                ),
                const SizedBox(width: 28),
                _DiskMetric(
                  label: l10n.selected,
                  value: formatBytes(selectedBytes, locale: locale),
                  color: SafetyColors.safeFor(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MainDiskLoadingCard extends StatelessWidget {
  const _MainDiskLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(context.l10n.readingDiskUsage),
          ],
        ),
      ),
    );
  }
}

class _DiskMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _DiskMetric({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final CategorySummary summary;
  const _CategoryCard({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeColor = _safetyColor(context, summary.target.safety);
    final l10n = context.l10n;
    final locale = context.localeName;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryDetailPage(categoryId: summary.target.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: safeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CategorySummary.iconFor(summary.target.id),
                  color: safeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.cleanupTargetLabel(
                        summary.target.id,
                        fallback: summary.target.label,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      summary.error ??
                          l10n.cleanupTargetDescription(
                            summary.target.id,
                            fallback: summary.target.description,
                          ),
                      style: TextStyle(
                        fontSize: 12,
                        color: summary.error == null
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : SafetyColors.dangerFor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (summary.scanning)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatBytes(summary.totalBytes, locale: locale),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      l10n.foundAndSelected(
                        summary.items.length,
                        summary.items.where((i) => i.selected).length,
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _safetyColor(BuildContext context, SafetyLevel s) => switch (s) {
    SafetyLevel.safe => SafetyColors.safeFor(context),
    SafetyLevel.caution => SafetyColors.cautionFor(context),
    SafetyLevel.danger => SafetyColors.dangerFor(context),
  };
}

class _CleanBar extends StatelessWidget {
  final int recoverable;
  final VoidCallback onClean;
  const _CleanBar({required this.recoverable, required this.onClean});

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
            Icons.cleaning_services_rounded,
            color: SafetyColors.safeFor(context),
          ),
          const SizedBox(width: 12),
          Text(
            context.l10n.selectedToClean(
              formatBytes(recoverable, locale: context.localeName),
            ),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: onClean,
            icon: const Icon(Icons.delete_sweep_rounded),
            label: Text(context.l10n.cleanNow),
            style: FilledButton.styleFrom(
              backgroundColor: SafetyColors.safeFor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneBar extends StatelessWidget {
  final int reclaimed;
  final VoidCallback onDismiss;
  const _DoneBar({required this.reclaimed, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: SafetyColors.safeSurfaceFor(context),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: SafetyColors.safeFor(context),
          ),
          const SizedBox(width: 12),
          Text(
            context.l10n.cleanDone(
              formatBytes(reclaimed, locale: context.localeName),
            ),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: SafetyColors.safeFor(context),
            ),
          ),
          const Spacer(),
          TextButton(onPressed: onDismiss, child: Text(context.l10n.dismiss)),
        ],
      ),
    );
  }
}
