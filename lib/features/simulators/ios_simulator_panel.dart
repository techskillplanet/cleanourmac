import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/format/byte_format.dart';
import '../../domain/models/simulator_device.dart';
import '../../providers/infra_providers.dart';
import '../../providers/simulator_providers.dart';

class IosSimulatorPanel extends ConsumerStatefulWidget {
  final List<SimulatorDevice> devices;

  const IosSimulatorPanel({super.key, required this.devices});

  @override
  ConsumerState<IosSimulatorPanel> createState() => _IosSimulatorPanelState();
}

class _IosSimulatorPanelState extends ConsumerState<IosSimulatorPanel> {
  final Set<String> _busy = {};

  @override
  Widget build(BuildContext context) {
    final staleDays = ref.watch(settingsProvider).simulatorStaleDays;
    final devices = widget.devices;
    final totalSize = devices.fold(0, (s, d) => s + d.sizeBytes);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${devices.length} simulators • ${formatBytes(totalSize)} total',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '> $staleDays days = stale',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            itemBuilder: (ctx, i) {
              final d = devices[i];
              return _IosCard(
                device: d,
                stale: d.isStale(staleDays),
                busy: _busy.contains(d.udid),
                onBoot: () => _run(d.udid, () async {
                  final repo = ref.read(simulatorRepositoryProvider);
                  await repo.boot(d.udid);
                  await repo.openSimulatorApp();
                }),
                onShutdown: () => _confirmShutdown(d),
                onOpen: () => _run(d.udid, () => ref.read(simulatorRepositoryProvider).openSimulatorApp()),
                onErase: () => _confirmErase(d),
                onDelete: () => _confirmDelete(d),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _run(String udid, Future<void> Function() action) async {
    setState(() => _busy.add(udid));
    try {
      await action();
    } catch (_) {}
    if (mounted) {
      setState(() => _busy.remove(udid));
      ref.invalidate(simulatorsProvider);
    }
  }

  Future<void> _confirmShutdown(SimulatorDevice d) async {
    final ok = await _confirm(
      title: 'Stop Simulator?',
      content: 'Shut down ${d.name}?',
      action: 'Stop',
    );
    if (ok != true) return;
    await _run(d.udid, () => ref.read(simulatorRepositoryProvider).shutdown(d.udid));
  }

  Future<void> _confirmErase(SimulatorDevice d) async {
    final ok = await _confirm(
      title: 'Erase Content?',
      content: 'Erase all content and settings on ${d.name}? The device itself will be kept.',
      action: 'Erase',
      destructive: true,
    );
    if (ok != true) return;
    await _run(d.udid, () async {
      final repo = ref.read(simulatorRepositoryProvider);
      if (d.isBooted) await repo.shutdown(d.udid);
      await repo.erase(d.udid);
    });
  }

  Future<void> _confirmDelete(SimulatorDevice d) async {
    final ok = await _confirm(
      title: 'Delete Simulator?',
      content: '${d.name} will be permanently removed (${formatBytes(d.sizeBytes)}).',
      action: 'Delete',
      destructive: true,
    );
    if (ok != true) return;
    await _run(d.udid, () => ref.read(simulatorRepositoryProvider).delete(d.udid));
  }

  Future<bool?> _confirm({
    required String title,
    required String content,
    required String action,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class _IosCard extends StatelessWidget {
  final SimulatorDevice device;
  final bool stale;
  final bool busy;
  final VoidCallback onBoot;
  final VoidCallback onShutdown;
  final VoidCallback onOpen;
  final VoidCallback onErase;
  final VoidCallback onDelete;

  const _IosCard({
    required this.device,
    required this.stale,
    required this.busy,
    required this.onBoot,
    required this.onShutdown,
    required this.onOpen,
    required this.onErase,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final booted = device.isBooted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (booted ? Colors.green : cs.primaryContainer).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.phone_iphone_rounded,
                    color: booted ? Colors.green : cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              device.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (stale) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('stale',
                                  style: TextStyle(fontSize: 10, color: Colors.orange)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${device.runtime} • ${device.state}'
                        '${device.lastBootedAt != null ? ' • Last: ${DateFormat('yyyy-MM-dd').format(device.lastBootedAt!)}' : ' • Never booted'}'
                        ' • ${formatBytes(device.sizeBytes)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  _StatusChip(booted: booted),
                PopupMenuButton<_IosAction>(
                  enabled: !busy,
                  tooltip: 'More actions',
                  onSelected: (a) {
                    switch (a) {
                      case _IosAction.erase:
                        onErase();
                      case _IosAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: _IosAction.erase, child: Text('Erase Content')),
                    PopupMenuItem(
                      value: _IosAction.delete,
                      child: Text('Delete…', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (booted) ...[
                  OutlinedButton.icon(
                    onPressed: busy ? null : onOpen,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: busy ? null : onShutdown,
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: const Text('Stop'),
                  ),
                ] else
                  FilledButton.icon(
                    onPressed: busy ? null : onBoot,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Boot'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _IosAction { erase, delete }

class _StatusChip extends StatelessWidget {
  final bool booted;
  const _StatusChip({required this.booted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (booted ? Colors.green : Colors.grey).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        booted ? 'BOOTED' : 'SHUTDOWN',
        style: TextStyle(
          fontSize: 10,
          color: booted ? Colors.green : Colors.grey,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
