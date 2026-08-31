import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format/byte_format.dart';
import '../../providers/scan_providers.dart';
import '../../domain/models/disk_usage.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diskAsync = ref.watch(diskUsageProvider);
    final recoverable = ref.watch(recoverableBytesProvider);
    final scan = ref.watch(scanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Overview'), elevation: 0),
      body: diskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (disk) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DiskUsageCard(disk: disk, recoverable: recoverable),
              const SizedBox(height: 24),
              if (recoverable > 0) _RecoverableCard(bytes: recoverable),
              if (scan.categories.isNotEmpty) ...[
                const SizedBox(height: 24),
                _CategoryGrid(scan: scan),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DiskUsageCard extends StatelessWidget {
  final DiskUsage disk;
  final int recoverable;

  const _DiskUsageCard({required this.disk, required this.recoverable});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final usedNotRecoverable = disk.usedBytes - recoverable;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(
                      value: usedNotRecoverable.toDouble(),
                      color: cs.primary,
                      title: '',
                      radius: 36,
                    ),
                    if (recoverable > 0)
                      PieChartSectionData(
                        value: recoverable.toDouble(),
                        color: const Color(0xFF16A34A),
                        title: '',
                        radius: 36,
                      ),
                    PieChartSectionData(
                      value: disk.freeBytes.toDouble(),
                      color: cs.surfaceContainerHighest,
                      title: '',
                      radius: 36,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatBytes(disk.totalBytes),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text('Total Disk', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  _Legend(color: cs.primary, label: 'Used', value: formatBytes(usedNotRecoverable)),
                  const SizedBox(height: 8),
                  if (recoverable > 0)
                    _Legend(
                        color: const Color(0xFF16A34A),
                        label: 'Recoverable',
                        value: formatBytes(recoverable)),
                  if (recoverable > 0) const SizedBox(height: 8),
                  _Legend(
                      color: cs.surfaceContainerHighest,
                      label: 'Free',
                      value: formatBytes(disk.freeBytes),
                      textColor: Theme.of(context).textTheme.bodyMedium?.color),
                ],
              ),
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
  final Color? textColor;

  const _Legend({required this.color, required this.label, required this.value, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: textColor)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _RecoverableCard extends StatelessWidget {
  final int bytes;
  const _RecoverableCard({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFDCFCE7),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.eco_rounded, color: Color(0xFF16A34A), size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatBytes(bytes),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF16A34A),
                    )),
                const Text('Ready to recover', style: TextStyle(color: Color(0xFF15803D))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final dynamic scan;
  const _CategoryGrid({required this.scan});

  @override
  Widget build(BuildContext context) {
    final cats = (scan.categories as Map).values.toList()
      ..sort((a, b) => b.totalBytes.compareTo(a.totalBytes));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Categories', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cats.map<Widget>((c) => _CategoryChip(summary: c)).toList(),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final dynamic summary;
  const _CategoryChip({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        summary.target != null
            ? (summary.target.id != null
                ? _iconFor(summary.target.id as String)
                : Icons.folder)
            : Icons.folder,
        size: 16,
      ),
      label: Text(
        '${summary.target?.label ?? ''} • ${formatBytes(summary.totalBytes as int)}',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  IconData _iconFor(String id) {
    if (id.contains('gradle') || id.contains('npm') || id.contains('node')) return Icons.code;
    if (id.contains('cocoapods') || id.contains('pip') || id.contains('homebrew')) return Icons.science;
    if (id.contains('xcode')) return Icons.build;
    if (id.contains('simulat')) return Icons.phone_iphone;
    return Icons.folder_open;
  }
}
