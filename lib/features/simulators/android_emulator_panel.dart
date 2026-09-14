import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/localization_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../data/shell/android_emulator_client.dart'
    show AndroidEmulatorLaunchException;
import '../../domain/models/android_emulator.dart';
import '../../domain/models/android_emulator_config.dart';
import '../../providers/android_emulator_providers.dart';
import '../../providers/infra_providers.dart';
import 'android_emulator_config_dialog.dart';

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
  bool _restartingAdb = false;
  bool _checkingConfiguration = false;
  bool _repairingConfiguration = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.sdkAvailable) {
      return const _NoSdk();
    }

    final runningCount = widget.emulators
        .where((device) => device.isRunning)
        .length;

    return Column(
      children: [
        _AdbToolbar(
          restarting: _restartingAdb,
          runningCount: runningCount,
          totalCount: widget.emulators.length,
          onRestart: _restartAdb,
          checkingConfiguration: _checkingConfiguration,
          repairingConfiguration: _repairingConfiguration,
          onCheckConfiguration: _checkConfiguration,
        ),
        Expanded(
          child: widget.emulators.isEmpty
              ? _AndroidEmptyState(
                  onRestart: _restartingAdb ? null : _restartAdb,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
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
                      onDevMenu: () =>
                          _runOn(emu, 'openDevMenu', context.l10n.devMenu),
                      onReload: () =>
                          _runOn(emu, 'reloadJs', context.l10n.reloadJs),
                      onBack: () => _runNavigation(
                        emu,
                        (serial) => ref
                            .read(androidEmulatorRepositoryProvider)
                            .pressBack(serial),
                        context.l10n.androidBack,
                      ),
                      onHome: () => _runNavigation(
                        emu,
                        (serial) => ref
                            .read(androidEmulatorRepositoryProvider)
                            .pressHome(serial),
                        context.l10n.androidHome,
                      ),
                      onRecents: () => _runNavigation(
                        emu,
                        (serial) => ref
                            .read(androidEmulatorRepositoryProvider)
                            .pressRecents(serial),
                        context.l10n.androidRecents,
                      ),
                      onCopySelection: () => _runNavigation(
                        emu,
                        (serial) => ref
                            .read(androidEmulatorRepositoryProvider)
                            .copySelection(serial),
                        context.l10n.androidCopySelection,
                      ),
                      onPasteClipboard: () => _runNavigation(
                        emu,
                        (serial) => ref
                            .read(androidEmulatorRepositoryProvider)
                            .pasteClipboard(serial),
                        context.l10n.androidPasteHostClipboard,
                      ),
                      onEnableHardwareKeyboard: () =>
                          _enableHardwareKeyboard(emu),
                      onAction: (action) => _handleAdbAction(emu, action),
                      onDelete: () => _delete(emu),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _restartAdb() async {
    setState(() => _restartingAdb = true);
    Object? error;
    try {
      await ref.read(androidEmulatorRepositoryProvider).restartAdb();
    } catch (e) {
      error = e;
    }
    if (!mounted) return;

    setState(() => _restartingAdb = false);
    ref.invalidate(androidEmulatorsProvider);
    if (error != null) {
      _showError(context.l10n.restartAdb, error);
    } else {
      _showMessage(context.l10n.adbRestarted);
    }
  }

  Future<void> _checkConfiguration() async {
    setState(() => _checkingConfiguration = true);
    Object? error;
    AndroidEmulatorConfigReport? report;
    try {
      report = await ref
          .read(androidEmulatorRepositoryProvider)
          .inspectConfiguration();
    } catch (caught) {
      error = caught;
    }
    if (!mounted) return;

    setState(() => _checkingConfiguration = false);
    if (error != null) {
      _showError(context.l10n.checkEmulatorConfig, error);
      return;
    }

    final selectedIds = await showAndroidEmulatorConfigCheckDialog(
      context,
      report!,
    );
    if (selectedIds == null || selectedIds.isEmpty || !mounted) return;

    setState(() => _repairingConfiguration = true);
    Object? repairError;
    AndroidEmulatorConfigRepairResult? result;
    try {
      result = await ref
          .read(androidEmulatorRepositoryProvider)
          .repairConfiguration(selectedIds);
    } catch (caught) {
      repairError = caught;
    }
    if (!mounted) return;

    setState(() => _repairingConfiguration = false);
    ref.invalidate(androidEmulatorsProvider);
    if (repairError != null) {
      _showError(context.l10n.repairingEmulatorConfig, repairError);
      return;
    }
    await showAndroidEmulatorConfigRepairResult(context, result!);
  }

  Future<void> _handleAdbAction(
    AndroidEmulator emu,
    _AndroidAction action,
  ) async {
    final serial = emu.serial;
    if (serial == null) return;

    switch (action) {
      case _AndroidAction.copySerial:
        await Clipboard.setData(ClipboardData(text: serial));
        if (mounted) _showMessage(context.l10n.serialCopied(serial));
      case _AndroidAction.shell:
        await _openTerminalTool(
          emu,
          context.l10n.openAdbShell,
          () => ref
              .read(androidEmulatorRepositoryProvider)
              .openAdbShell(
                serial,
                '${context.l10n.openAdbShell} · ${emu.name}',
              ),
        );
      case _AndroidAction.logcat:
        await _openTerminalTool(
          emu,
          context.l10n.openLogcat,
          () => ref
              .read(androidEmulatorRepositoryProvider)
              .openLogcat(serial, '${context.l10n.openLogcat} · ${emu.name}'),
        );
      case _AndroidAction.installApk:
        await _installApk(emu);
      case _AndroidAction.screenshot:
        await _captureScreenshot(emu);
    }
  }

  Future<void> _openTerminalTool(
    AndroidEmulator emu,
    String tool,
    Future<void> Function() action,
  ) async {
    final serial = emu.serial;
    if (serial == null) return;
    setState(() => _busyKeys.add(serial));
    Object? error;
    try {
      await action();
    } catch (e) {
      error = e;
    }
    if (!mounted) return;

    setState(() => _busyKeys.remove(serial));
    if (error != null) {
      _showError(tool, error);
    } else {
      _showMessage(context.l10n.terminalOpened(tool, emu.name));
    }
  }

  Future<void> _installApk(AndroidEmulator emu) async {
    final serial = emu.serial;
    if (serial == null) return;
    final repository = ref.read(androidEmulatorRepositoryProvider);

    String? apkPath;
    try {
      apkPath = await repository.chooseApk(context.l10n.chooseApkPrompt);
    } catch (error) {
      if (mounted) _showError(context.l10n.installApk, error);
      return;
    }
    if (apkPath == null || !mounted) return;
    if (!apkPath.toLowerCase().endsWith('.apk')) {
      _showError(context.l10n.installApk, context.l10n.invalidApk);
      return;
    }

    setState(() => _busyKeys.add(serial));
    Object? error;
    try {
      await repository.installApk(serial, apkPath);
    } catch (e) {
      error = e;
    }
    if (!mounted) return;

    setState(() => _busyKeys.remove(serial));
    if (error != null) {
      _showError(context.l10n.installApk, error);
    } else {
      _showMessage(context.l10n.apkInstalled(emu.name));
    }
  }

  Future<void> _captureScreenshot(AndroidEmulator emu) async {
    final serial = emu.serial;
    if (serial == null) return;
    setState(() => _busyKeys.add(serial));

    Object? error;
    String? path;
    try {
      path = await ref
          .read(androidEmulatorRepositoryProvider)
          .captureScreenshot(serial, emu.name);
    } catch (e) {
      error = e;
    }
    if (!mounted) return;

    setState(() => _busyKeys.remove(serial));
    if (error != null) {
      _showError(context.l10n.takeScreenshot, error);
    } else if (path != null) {
      _showMessage(context.l10n.screenshotSaved(path));
    }
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
      await _showStartError(name, error);
    }
  }

  Future<void> _showStartError(String name, Object error) {
    final details = error.toString();
    final logPath = error is AndroidEmulatorLaunchException
        ? error.logPath
        : null;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.unableToStartEmulator(name)),
        content: SizedBox(
          width: 620,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.androidStartErrorDetails),
              if (logPath != null) ...[
                const SizedBox(height: 8),
                SelectableText(
                  context.l10n.androidFailureLogSaved(logPath),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    details,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (logPath != null)
            TextButton.icon(
              onPressed: () async {
                try {
                  await ref
                      .read(androidEmulatorRepositoryProvider)
                      .revealDiagnosticLog(logPath);
                } catch (revealError) {
                  if (mounted) {
                    _showError(context.l10n.openFailureLog, revealError);
                  }
                }
              },
              icon: const Icon(Icons.folder_open_rounded, size: 17),
              label: Text(context.l10n.openFailureLog),
            ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: details));
              if (mounted) _showMessage(context.l10n.errorDetailsCopied);
            },
            icon: const Icon(Icons.copy_rounded, size: 17),
            label: Text(context.l10n.copyErrorDetails),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.dismiss),
          ),
        ],
      ),
    );
  }

  Future<void> _shutdown(AndroidEmulator emu) async {
    if (!emu.isAvd) return;
    final serial = emu.serial;
    if (serial == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.l10n.stopEmulatorTitle),
        content: Text(
          context.l10n.stopAndroidEmulatorContent(emu.name, serial),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.stop),
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
        _showError(context.l10n.unableToStopEmulator(emu.name), error);
      }
    }
  }

  void _showError(String title, Object error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.operationError(title, error))),
      );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _runOn(AndroidEmulator emu, String method, String label) async {
    final serial = emu.serial;
    if (serial == null) return;
    setState(() => _busyKeys.add(serial));
    Object? error;
    try {
      final repo = ref.read(androidEmulatorRepositoryProvider);
      if (method == 'openDevMenu') {
        await repo.openDevMenu(serial);
      } else {
        await repo.reloadJs(serial);
      }
    } catch (caught) {
      error = caught;
    }
    if (!mounted) return;

    setState(() => _busyKeys.remove(serial));
    if (error != null) {
      _showError(label, error);
    } else {
      _showMessage(context.l10n.emulatorActionSent(label, emu.name));
    }
  }

  Future<void> _runNavigation(
    AndroidEmulator emu,
    Future<void> Function(String serial) action,
    String label,
  ) async {
    final serial = emu.serial;
    if (serial == null) return;
    setState(() => _busyKeys.add(serial));
    Object? error;
    try {
      await action(serial);
    } catch (caught) {
      error = caught;
    }
    if (!mounted) return;

    setState(() => _busyKeys.remove(serial));
    if (error != null) {
      _showError(label, error);
    }
  }

  Future<void> _enableHardwareKeyboard(AndroidEmulator emu) async {
    if (!emu.isAvd) return;
    final serial = emu.serial;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.enableHardwareKeyboardTitle),
        content: Text(context.l10n.enableHardwareKeyboardDescription(emu.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.enableAndRestart),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final busyKey = serial ?? emu.name;
    setState(() {
      _busyKeys.add(busyKey);
      _booting = emu.name;
    });

    Object? error;
    try {
      final repository = ref.read(androidEmulatorRepositoryProvider);
      if (serial != null) {
        await repository.shutdown(serial);
      }
      await repository.enableHardwareKeyboard(emu.name);
      await repository.boot(emu.name);
    } catch (caught) {
      error = caught;
    }
    if (!mounted) return;

    setState(() {
      _busyKeys.remove(busyKey);
      _booting = null;
    });
    ref.invalidate(androidEmulatorsProvider);
    if (error != null) {
      _showError(context.l10n.enableHardwareKeyboard, error);
    } else {
      _showMessage(context.l10n.hardwareKeyboardEnabled(emu.name));
    }
  }

  Future<void> _delete(AndroidEmulator emu) async {
    if (!emu.isAvd) return;
    if (emu.isRunning) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.stopBeforeDeleteEmulator)),
        );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.l10n.deleteAvdTitle),
        content: Text(context.l10n.deleteAvdContent(emu.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busyKeys.add(emu.name));
    Object? error;
    try {
      await ref.read(androidEmulatorRepositoryProvider).delete(emu.name);
    } catch (caught) {
      error = caught;
    }
    if (mounted) {
      setState(() => _busyKeys.remove(emu.name));
      ref.invalidate(androidEmulatorsProvider);
      if (error != null) {
        _showError(context.l10n.delete, error);
      }
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
  final VoidCallback onBack;
  final VoidCallback onHome;
  final VoidCallback onRecents;
  final VoidCallback onCopySelection;
  final VoidCallback onPasteClipboard;
  final VoidCallback onEnableHardwareKeyboard;
  final ValueChanged<_AndroidAction> onAction;
  final VoidCallback onDelete;

  const _EmulatorCard({
    required this.emu,
    required this.booting,
    required this.busy,
    required this.onBoot,
    required this.onShutdown,
    required this.onDevMenu,
    required this.onReload,
    required this.onBack,
    required this.onHome,
    required this.onRecents,
    required this.onCopySelection,
    required this.onPasteClipboard,
    required this.onEnableHardwareKeyboard,
    required this.onAction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final running = emu.isRunning;
    final statusColor = running ? AppPalette.successFor(context) : cs.outline;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: running
                        ? AppPalette.successFor(context).withValues(alpha: 0.08)
                        : cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    emu.isAvd
                        ? Icons.phone_android_rounded
                        : Icons.smartphone_rounded,
                    color: running
                        ? AppPalette.successFor(context)
                        : cs.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              emu.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _DeviceKindChip(isAvd: emu.isAvd),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emu.detail,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (emu.serial != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.terminal_rounded,
                              size: 12,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                emu.serial!,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 10.5,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (booting || busy)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  _StatusChip(running: running),
                PopupMenuButton<_AndroidMenuAction>(
                  enabled: !busy && !booting,
                  tooltip: context.l10n.moreActions,
                  onSelected: (action) {
                    switch (action) {
                      case _AndroidMenuAction.copySerial:
                        onAction(_AndroidAction.copySerial);
                      case _AndroidMenuAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (_) => [
                    if (running)
                      PopupMenuItem(
                        value: _AndroidMenuAction.copySerial,
                        child: ListTile(
                          leading: const Icon(Icons.copy_rounded, size: 18),
                          title: Text(context.l10n.copySerial),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    if (emu.isAvd)
                      PopupMenuItem(
                        value: _AndroidMenuAction.delete,
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          title: Text(
                            context.l10n.deleteEllipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (running) ...[
              Text(
                context.l10n.developerTools,
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
                    child: _AdbQuickAction(
                      icon: Icons.terminal_rounded,
                      label: context.l10n.openAdbShell,
                      enabled: !busy,
                      onTap: () => onAction(_AndroidAction.shell),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AdbQuickAction(
                      icon: Icons.subject_rounded,
                      label: context.l10n.openLogcat,
                      enabled: !busy,
                      onTap: () => onAction(_AndroidAction.logcat),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AdbQuickAction(
                      icon: Icons.install_mobile_rounded,
                      label: context.l10n.installApk,
                      enabled: !busy,
                      onTap: () => onAction(_AndroidAction.installApk),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AdbQuickAction(
                      icon: Icons.screenshot_monitor_rounded,
                      label: context.l10n.takeScreenshot,
                      enabled: !busy,
                      onTap: () => onAction(_AndroidAction.screenshot),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.androidDeviceNavigation,
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
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onBack,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(context.l10n.androidBack),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onHome,
                      icon: const Icon(Icons.home_outlined, size: 18),
                      label: Text(context.l10n.androidHome),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onRecents,
                      icon: const Icon(Icons.crop_square_rounded, size: 18),
                      label: Text(context.l10n.androidRecents),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.androidGestureNavigationHint,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
              ),
              if (emu.isAvd) ...[
                const SizedBox(height: 14),
                Text(
                  context.l10n.androidClipboard,
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
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : onCopySelection,
                        icon: const Icon(Icons.content_copy_rounded, size: 17),
                        label: Text(context.l10n.androidCopySelection),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: busy ? null : onPasteClipboard,
                        icon: const Icon(
                          Icons.content_paste_go_rounded,
                          size: 17,
                        ),
                        label: Text(context.l10n.androidPasteHostClipboard),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.androidClipboardHint,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
                ),
                if (!emu.hardwareKeyboardEnabled) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                    decoration: BoxDecoration(
                      color: AppPalette.warningFor(
                        context,
                      ).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppPalette.warningFor(
                          context,
                        ).withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.keyboard_rounded,
                          size: 17,
                          color: AppPalette.warningFor(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.hardwareKeyboardDisabled,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: busy ? null : onEnableHardwareKeyboard,
                          child: Text(context.l10n.enableAndRestart),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              Divider(color: cs.outlineVariant.withValues(alpha: 0.6)),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: busy ? null : onDevMenu,
                    icon: const Icon(Icons.menu_open_rounded, size: 17),
                    label: Text(context.l10n.devMenu),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: busy ? null : onReload,
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: Text(context.l10n.reloadJs),
                  ),
                  if (emu.isAvd) ...[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: busy ? null : onShutdown,
                      icon: const Icon(Icons.stop_circle_outlined, size: 17),
                      label: Text(context.l10n.stop),
                      style: TextButton.styleFrom(foregroundColor: cs.error),
                    ),
                  ],
                ],
              ),
            ] else if (emu.isAvd)
              FilledButton.icon(
                onPressed: booting ? null : onBoot,
                icon: booting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(context.l10n.boot),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdbQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _AdbQuickAction({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
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
                  textAlign: TextAlign.center,
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
  final bool running;

  const _StatusChip({required this.running});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = running ? AppPalette.successFor(context) : cs.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            running ? context.l10n.running : context.l10n.shutdown,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum _AndroidAction { copySerial, shell, logcat, installApk, screenshot }

enum _AndroidMenuAction { copySerial, delete }

class _DeviceKindChip extends StatelessWidget {
  final bool isAvd;

  const _DeviceKindChip({required this.isAvd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isAvd ? cs.onSurfaceVariant : AppPalette.successFor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isAvd ? context.l10n.virtualDevice : context.l10n.physicalDevice,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AdbToolbar extends StatelessWidget {
  final bool restarting;
  final bool checkingConfiguration;
  final bool repairingConfiguration;
  final int runningCount;
  final int totalCount;
  final VoidCallback onRestart;
  final VoidCallback onCheckConfiguration;

  const _AdbToolbar({
    required this.restarting,
    required this.checkingConfiguration,
    required this.repairingConfiguration,
    required this.runningCount,
    required this.totalCount,
    required this.onRestart,
    required this.onCheckConfiguration,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.terminal_rounded, color: cs.onPrimary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      context.l10n.adbTools,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppPalette.successFor(
                          context,
                        ).withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppPalette.successFor(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            context.l10n.adbReady,
                            style: TextStyle(
                              color: AppPalette.successFor(context),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.adbDeviceSummary(runningCount, totalCount),
                  style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: checkingConfiguration || repairingConfiguration
                    ? null
                    : onCheckConfiguration,
                icon: checkingConfiguration || repairingConfiguration
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.health_and_safety_outlined, size: 18),
                label: Text(
                  repairingConfiguration
                      ? context.l10n.repairingEmulatorConfig
                      : checkingConfiguration
                      ? context.l10n.checkingEmulatorConfig
                      : context.l10n.checkEmulatorConfig,
                ),
              ),
              OutlinedButton.icon(
                onPressed: restarting ? null : onRestart,
                icon: restarting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restart_alt_rounded, size: 18),
                label: Text(context.l10n.restartAdb),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AndroidEmptyState extends StatelessWidget {
  final VoidCallback? onRestart;

  const _AndroidEmptyState({required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.phonelink_erase_rounded,
                size: 34,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.noAndroidVirtualDevices,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.adbToolsDescription,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: Text(context.l10n.restartAdb),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.android,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.androidSdkNotFound,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.androidSdkNotFoundDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
