import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/byte_format.dart';
import '../../core/l10n/localization_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_page_title.dart';
import '../../domain/models/category_summary.dart';
import '../../domain/models/disk_usage.dart';
import '../../domain/models/scan_state.dart';
import '../../providers/android_emulator_providers.dart';
import '../../providers/scan_providers.dart';
import '../../providers/simulator_providers.dart';

class DashboardPage extends ConsumerWidget {
  final VoidCallback onOpenDevices;
  final VoidCallback onStartScan;

  const DashboardPage({
    super.key,
    required this.onOpenDevices,
    required this.onStartScan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diskAsync = ref.watch(diskUsageProvider);
    final recoverable = ref.watch(recoverableBytesProvider);
    final scan = ref.watch(scanProvider);
    final androidDevices = ref.watch(androidEmulatorsProvider);
    final iosDevices = ref.watch(simulatorsProvider);
    final androidCount = androidDevices.isLoading
        ? null
        : androidDevices.valueOrNull?.length ?? 0;
    final iosCount = iosDevices.isLoading
        ? null
        : iosDevices.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: AppPageTitle(
          title: context.l10n.overview,
          subtitle: context.l10n.workspaceSubtitle,
        ),
      ),
      body: diskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(context.l10n.errorMessage(error))),
        data: (disk) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WorkspaceHero(
                onOpenDevices: onOpenDevices,
                onStartScan: onStartScan,
              ),
              const SizedBox(height: 18),
              _StatusMetrics(
                androidCount: androidCount,
                iosCount: iosCount,
                recoverable: recoverable,
              ),
              const SizedBox(height: 18),
              _StorageCard(disk: disk, recoverable: recoverable),
              const SizedBox(height: 18),
              if (scan.categories.isEmpty)
                _ScanCallout(onScan: onStartScan)
              else
                _CategoryGrid(scan: scan),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceHero extends StatelessWidget {
  final VoidCallback onOpenDevices;
  final VoidCallback onStartScan;

  const _WorkspaceHero({
    required this.onOpenDevices,
    required this.onStartScan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppPalette.heroStart, AppPalette.heroEnd],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17212A).withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/brand/mobile_dev_assistant_mark.png',
                  width: 54,
                  height: 54,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.appTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.appTagline,
                      style: const TextStyle(
                        color: Color(0xFFCDD5DB),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8DB7A5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      context.l10n.localPrivate,
                      style: const TextStyle(
                        color: Color(0xFFD7DEE3),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenDevices,
                  icon: const Icon(Icons.devices_rounded, size: 18),
                  label: Text(context.l10n.openDeviceLab),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F7F8),
                    foregroundColor: AppPalette.heroStart,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onStartScan,
                  icon: const Icon(Icons.radar_rounded, size: 18),
                  label: Text(context.l10n.startDiskScan),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.34),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusMetrics extends StatelessWidget {
  final int? androidCount;
  final int? iosCount;
  final int recoverable;

  const _StatusMetrics({
    required this.androidCount,
    required this.iosCount,
    required this.recoverable,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 20) / 3;
        return Row(
          children: [
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                icon: Icons.android_rounded,
                color: AppPalette.android,
                value: androidCount?.toString() ?? '—',
                label: context.l10n.androidEmulators,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                icon: Icons.phone_iphone_rounded,
                color: AppPalette.ios,
                value: iosCount?.toString() ?? '—',
                label: context.l10n.iosSimulators,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: cardWidth,
              child: _MetricCard(
                icon: Icons.cleaning_services_rounded,
                color: AppPalette.warningFor(context),
                value: formatBytes(recoverable, locale: context.localeName),
                label: context.l10n.reclaimableMetric,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _MetricCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 13),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.45,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  final DiskUsage disk;
  final int recoverable;

  const _StorageCard({required this.disk, required this.recoverable});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locale = context.localeName;
    final used = (disk.usedBytes - recoverable).clamp(0, disk.totalBytes);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.storage_rounded,
                    color: cs.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.storageOverview,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.storageSubtitle,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatDiskBytes(disk.totalBytes, locale: locale),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                SizedBox(
                  width: 134,
                  height: 134,
                  child: PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 3,
                      centerSpaceRadius: 42,
                      sections: [
                        PieChartSectionData(
                          value: used.toDouble(),
                          color: cs.primary,
                          title: '',
                          radius: 25,
                        ),
                        if (recoverable > 0)
                          PieChartSectionData(
                            value: recoverable.toDouble(),
                            color: AppPalette.warningFor(context),
                            title: '',
                            radius: 25,
                          ),
                        PieChartSectionData(
                          value: disk.freeBytes.toDouble(),
                          color: cs.surfaceContainerHighest,
                          title: '',
                          radius: 25,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _Legend(
                        color: cs.primary,
                        label: context.l10n.overviewUsed,
                        value: formatDiskBytes(used, locale: locale),
                      ),
                      const SizedBox(height: 12),
                      if (recoverable > 0) ...[
                        _Legend(
                          color: AppPalette.warningFor(context),
                          label: context.l10n.overviewRecoverable,
                          value: formatBytes(recoverable, locale: locale),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _Legend(
                        color: cs.surfaceContainerHighest,
                        label: context.l10n.overviewFree,
                        value: formatDiskBytes(disk.freeBytes, locale: locale),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: disk.usedFraction.clamp(0, 1),
                          minHeight: 7,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ScanCallout extends StatelessWidget {
  final VoidCallback onScan;

  const _ScanCallout({required this.onScan});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.radar_rounded, color: cs.primary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.noScanData,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.l10n.scanEmptyPrompt,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(context.l10n.scanNow),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final ScanState scan;

  const _CategoryGrid({required this.scan});

  @override
  Widget build(BuildContext context) {
    final categories = scan.categories.values.toList()
      ..sort((a, b) => b.totalBytes.compareTo(a.totalBytes));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.categories,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories
                  .take(8)
                  .map((summary) => _CategoryChip(summary: summary))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CategorySummary summary;

  const _CategoryChip({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(CategorySummary.iconFor(summary.target.id), size: 16),
      label: Text(
        '${context.l10n.cleanupTargetLabel(summary.target.id, fallback: summary.target.label)} · '
        '${formatBytes(summary.totalBytes, locale: context.localeName)}',
        style: const TextStyle(fontSize: 11.5),
      ),
    );
  }
}
