import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/android_emulator.dart';
import '../../providers/android_emulator_providers.dart';
import '../../providers/infra_providers.dart';

class AndroidEmulatorPanel extends ConsumerStatefulWidget {
  final List<AndroidEmulator> emulators;
  final bool sdkAvailable;

  const AndroidEmulatorPanel({
    super.key,
    required this.emulators,
    required this.sdkAvailable,
  });

  @override
  ConsumerState<AndroidEmulatorPanel> createState() =>
      _AndroidEmulatorPanelState();
}

class _AndroidEmulatorPanelState extends ConsumerState<AndroidEmulatorPanel> {
  String? _booting;
  final Set<String> _busyKeys = {};

  @override
  Widget build(BuildContext context) {
    if (!widget.sdkAvailable) {
      return const _NoSdk();
    }
    if (widget.emulators.isEmpty) {
      return const Center(
        child: Text(
          'No Android Virtual Devices found',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.emulators.length,
      itemBuilder: (ctx, i) {
        final emu = widget.emulators[i];
        final key = emu.serial ?? emu.name;
        return _EmulatorCard(
          emu: emu,
          booting: _booting == emu.name,
          busy: _busyKeys.contains(key),
          onBoot: () => _boot(emu.name),
          onShutdown: () => _shutdown(emu),
          onDevMenu: () => _runOn(emu, 'openDevMenu', 'Dev Menu'),
          onReload: () => _runOn(emu, 'reloadJs', 'Reload'),
          onDelete: () => _delete(emu),
        );
      },
    );
  }

  Future<void> _boot(String name) async {
    setState(() => _booting = name);
    Object? error;
    try {
      await ref.read(androidEmulatorRepositoryProvider).boot(name);
    } catch (e) {
      error = e;
    }
    if (!mounted) return;

    setState(() => _booting = null);
    ref.invalidate(androidEmulatorsProvider);
    if (error != null) {
      _showError('Unable to start $name', error);
    }
  }

  Future<void> _shutdown(AndroidEmulator emu) async {
    final serial = emu.serial;
    if (serial == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Stop Emulator?'),
        content: Text('Shut down ${emu.name} ($serial)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busyKeys.add(serial));
    Object? error;
    try {
      await ref.read(androidEmulatorRepositoryProvider).shutdown(serial);
    } catch (e) {
      error = e;
    }
    if (mounted) {
      setState(() => _busyKeys.remove(serial));
      ref.invalidate(androidEmulatorsProvider);
      if (error != null) {
        _showError('Unable to stop ${emu.name}', error);
      }
    }
  }

  void _showError(String title, Object error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$title: $error')));
  }

  Future<void> _runOn(AndroidEmulator emu, String method, String label) async {
    final serial = emu.serial;
    if (serial == null) return;
    setState(() => _busyKeys.add(serial));
    try {
      final repo = ref.read(androidEmulatorRepositoryProvider);
      if (method == 'openDevMenu') {
        await repo.openDevMenu(serial);
      } else {
        await repo.reloadJs(serial);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('$label sent to ${emu.name}')));
      }
    } catch (_) {}
    if (mounted) setState(() => _busyKeys.remove(serial));
  }

  Future<void> _delete(AndroidEmulator emu) async {
    if (emu.isRunning) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Stop the emulator before deleting it')),
        );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete AVD?'),
        content: Text('${emu.name} will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busyKeys.add(emu.name));
    try {
      await ref.read(androidEmulatorRepositoryProvider).delete(emu.name);
    } catch (_) {}
    if (mounted) {
      setState(() => _busyKeys.remove(emu.name));
      ref.invalidate(androidEmulatorsProvider);
    }
  }
}

class _EmulatorCard extends StatelessWidget {
  final AndroidEmulator emu;
  final bool booting;
  final bool busy;
  final VoidCallback onBoot;
  final VoidCallback onShutdown;
  final VoidCallback onDevMenu;
  final VoidCallback onReload;
  final VoidCallback onDelete;

  const _EmulatorCard({
    required this.emu,
    required this.booting,
    required this.busy,
    required this.onBoot,
    required this.onShutdown,
    required this.onDevMenu,
    required this.onReload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final running = emu.isRunning;

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
                    color: (running ? Colors.green : cs.primaryContainer)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    running ? Icons.phone_android : Icons.android,
                    color: running ? Colors.green : cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emu.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        emu.detail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (booting)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: (running ? Colors.green : Colors.grey).withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      running ? 'RUNNING' : 'SHUTDOWN',
                      style: TextStyle(
                        fontSize: 10,
                        color: running ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  enabled: !busy && !booting,
                  tooltip: 'More actions',
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete…',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (running) ...[
                  OutlinedButton.icon(
                    onPressed: busy ? null : onDevMenu,
                    icon: const Icon(Icons.menu_rounded, size: 18),
                    label: const Text('Dev Menu'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: busy ? null : onReload,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reload JS'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: busy ? null : onShutdown,
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: const Text('Stop'),
                  ),
                ] else
                  FilledButton.icon(
                    onPressed: booting ? null : onBoot,
                    icon: booting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow_rounded),
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

class _NoSdk extends StatelessWidget {
  const _NoSdk();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.android, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Android SDK not found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Install the Android SDK and set ANDROID_HOME to manage emulators.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
