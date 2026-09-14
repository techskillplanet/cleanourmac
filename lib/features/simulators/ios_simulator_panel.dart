import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/format/byte_format.dart';
import '../../core/l10n/localization_extensions.dart';
import '../../core/theme/app_theme.dart';
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
                context.l10n.iosSimulatorSummary(
                  devices.length,
                  formatBytes(totalSize, locale: context.localeName),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.staleAfterDays(staleDays),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
                  await repo.openSimulatorDevice(d.udid);
                }, refresh: true),
                onShutdown: () => _confirmShutdown(d),
                onOpen: () => _run(
                  d.udid,
                  () => ref
                      .read(simulatorRepositoryProvider)
                      .openSimulatorDevice(d.udid),
                ),
                onCopyUdid: () => _copyUdid(d),
                onLogs: () => _run(
                  d.udid,
                  () => ref
                      .read(simulatorRepositoryProvider)
                      .openLogStream(
                        d.udid,
                        '${context.l10n.openSimulatorLogs} · ${d.name}',
                      ),
                  success: context.l10n.terminalOpened(
                    context.l10n.openSimulatorLogs,
                    d.name,
                  ),
                ),
                onInstall: () => _installApp(d),
                onScreenshot: () => _captureScreenshot(d),
                onOpenUrl: () => _openUrl(d),
                onDevMenu: () => _run(
                  d.udid,
                  () => ref
                      .read(simulatorRepositoryProvider)
                      .openReactNativeDevMenu(d.udid),
                  success: context.l10n.emulatorActionSent(
                    context.l10n.iosDevMenu,
                    d.name,
                  ),
                ),
                onReload: () => _run(
                  d.udid,
                  () => ref
                      .read(simulatorRepositoryProvider)
                      .reloadReactNative(d.udid),
                  success: context.l10n.emulatorActionSent(
                    context.l10n.iosReload,
                    d.name,
                  ),
                ),
                onErase: () => _confirmErase(d),
                onDelete: () => _confirmDelete(d),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _run(
    String udid,
    Future<void> Function() action, {
    String? success,
    bool refresh = false,
  }) async {
    setState(() => _busy.add(udid));
    Object? error;
    try {
      await action();
    } catch (caught) {
      error = caught;
    }
    if (!mounted) return;

    setState(() => _busy.remove(udid));
    if (refresh) ref.invalidate(simulatorsProvider);
    if (error != null) {
      _showError(error);
    } else if (success != null) {
      _showMessage(success);
    }
  }

  Future<void> _copyUdid(SimulatorDevice device) async {
    await Clipboard.setData(ClipboardData(text: device.udid));
    if (mounted) _showMessage(context.l10n.udidCopied(device.udid));
  }

  Future<void> _installApp(SimulatorDevice device) async {
    final repository = ref.read(simulatorRepositoryProvider);
    try {
      final path = await repository.chooseAppBundle(
        context.l10n.chooseIosAppPrompt,
      );
      if (path == null || !mounted) return;
      await _run(
        device.udid,
        () => repository.installApp(device.udid, path),
        success: context.l10n.iosAppInstalled(device.name),
      );
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _captureScreenshot(SimulatorDevice device) async {
    String? path;
    await _run(device.udid, () async {
      path = await ref
          .read(simulatorRepositoryProvider)
          .captureScreenshot(device.udid, device.name);
    });
    if (mounted && path != null) {
      _showMessage(context.l10n.screenshotSaved(path!));
    }
  }

  Future<void> _openUrl(SimulatorDevice device) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.openUrlTitle),
        content: SizedBox(
          width: 440,
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: context.l10n.urlHint),
            onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(context.l10n.openUrl),
          ),
        ],
      ),
    );
    controller.dispose();
    if (url == null || url.isEmpty || !mounted) return;
    if (Uri.tryParse(url)?.hasScheme != true) {
      _showMessage(context.l10n.invalidUrl);
      return;
    }
    await _run(
      device.udid,
      () => ref.read(simulatorRepositoryProvider).openUrl(device.udid, url),
      success: context.l10n.emulatorActionSent(
        context.l10n.openUrl,
        device.name,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.errorMessage(error))));
  }

  Future<void> _confirmShutdown(SimulatorDevice d) async {
    final ok = await _confirm(
      title: context.l10n.stopEmulatorTitle,
      content: context.l10n.stopIosSimulatorContent(d.name),
      action: context.l10n.stop,
    );
    if (ok != true) return;
    await _run(
      d.udid,
      () => ref.read(simulatorRepositoryProvider).shutdown(d.udid),
      refresh: true,
    );
  }

  Future<void> _confirmErase(SimulatorDevice d) async {
    final ok = await _confirm(
      title: context.l10n.eraseContentTitle,
      content: context.l10n.eraseContentDescription(d.name),
      action: context.l10n.erase,
      destructive: true,
    );
    if (ok != true) return;
    await _run(d.udid, () async {
      final repo = ref.read(simulatorRepositoryProvider);
      if (d.isBooted) await repo.shutdown(d.udid);
      await repo.erase(d.udid);
    }, refresh: true);
  }

  Future<void> _confirmDelete(SimulatorDevice d) async {
    final ok = await _confirm(
      title: context.l10n.deleteSimulatorTitle,
      content: context.l10n.deleteSimulatorDescription(
        d.name,
        formatBytes(d.sizeBytes, locale: context.localeName),
      ),
      action: context.l10n.delete,
      destructive: true,
    );
    if (ok != true) return;
    await _run(
      d.udid,
      () => ref.read(simulatorRepositoryProvider).delete(d.udid),
      refresh: true,
    );
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
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
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
  final VoidCallback onCopyUdid;
  final VoidCallback onLogs;
  final VoidCallback onInstall;
  final VoidCallback onScreenshot;
  final VoidCallback onOpenUrl;
  final VoidCallback onDevMenu;
  final VoidCallback onReload;
  final VoidCallback onErase;
  final VoidCallback onDelete;

  const _IosCard({
    required this.device,
    required this.stale,
    required this.busy,
    required this.onBoot,
    required this.onShutdown,
    required this.onOpen,
    required this.onCopyUdid,
    required this.onLogs,
    required this.onInstall,
    required this.onScreenshot,
    required this.onOpenUrl,
    required this.onDevMenu,
    required this.onReload,
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
                    color:
                        (booted
                                ? AppPalette.successFor(context)
                                : cs.surfaceContainerHigh)
                            .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.phone_iphone_rounded,
                    color: booted
                        ? AppPalette.successFor(context)
                        : cs.onSurfaceVariant,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (stale) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.warningFor(
                                  context,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                context.l10n.stale,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppPalette.warningFor(context),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        device.lastBootedAt == null
                            ? context.l10n.iosSimulatorDetailNever(
                                device.runtime,
                                booted
                                    ? context.l10n.running
                                    : context.l10n.shutdown,
                                formatBytes(
                                  device.sizeBytes,
                                  locale: context.localeName,
                                ),
                              )
                            : context.l10n.iosSimulatorDetailLast(
                                device.runtime,
                                booted
                                    ? context.l10n.running
                                    : context.l10n.shutdown,
                                DateFormat.yMd(
                                  context.localeName,
                                ).format(device.lastBootedAt!.toLocal()),
                                formatBytes(
                                  device.sizeBytes,
                                  locale: context.localeName,
                                ),
                              ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  _StatusChip(booted: booted),
                PopupMenuButton<_IosAction>(
                  enabled: !busy,
                  tooltip: context.l10n.moreActions,
                  onSelected: (a) {
                    switch (a) {
                      case _IosAction.copyUdid:
                        onCopyUdid();
                      case _IosAction.erase:
                        onErase();
                      case _IosAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _IosAction.copyUdid,
                      child: Text(context.l10n.copyUdid),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: _IosAction.erase,
                      child: Text(context.l10n.erase),
                    ),
                    PopupMenuItem(
                      value: _IosAction.delete,
                      child: Text(
                        context.l10n.deleteEllipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (booted) ...[
              Text(
                context.l10n.iosDebugTools,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.35,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _IosQuickAction(
                      icon: Icons.subject_rounded,
                      label: context.l10n.openSimulatorLogs,
                      onTap: busy ? null : onLogs,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _IosQuickAction(
                      icon: Icons.install_mobile_rounded,
                      label: context.l10n.installIosApp,
                      onTap: busy ? null : onInstall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _IosQuickAction(
                      icon: Icons.screenshot_monitor_rounded,
                      label: context.l10n.takeScreenshot,
                      onTap: busy ? null : onScreenshot,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _IosQuickAction(
                      icon: Icons.link_rounded,
                      label: context.l10n.openUrl,
                      onTap: busy ? null : onOpenUrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: cs.outlineVariant.withValues(alpha: 0.65)),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: busy ? null : onOpen,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(context.l10n.open),
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: busy ? null : onDevMenu,
                    icon: const Icon(Icons.bug_report_outlined, size: 17),
                    label: Text(context.l10n.iosDevMenu),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: busy ? null : onReload,
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: Text(context.l10n.iosReload),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: busy ? null : onShutdown,
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: Text(context.l10n.stop),
                  ),
                ],
              ),
            ] else
              FilledButton.icon(
                onPressed: busy ? null : onBoot,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(context.l10n.boot),
              ),
          ],
        ),
      ),
    );
  }
}

enum _IosAction { copyUdid, erase, delete }

class _IosQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _IosQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            child: Column(
              children: [
                Icon(icon, size: 19, color: cs.primary),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool booted;
  const _StatusChip({required this.booted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            (booted
                    ? AppPalette.successFor(context)
                    : Theme.of(context).colorScheme.onSurfaceVariant)
                .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        booted ? context.l10n.running : context.l10n.shutdown,
        style: TextStyle(
          fontSize: 10,
          color: booted
              ? AppPalette.successFor(context)
              : Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
