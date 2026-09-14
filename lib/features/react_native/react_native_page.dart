import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/localization_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_page_title.dart';
import '../../core/widgets/react_native_icon.dart';
import '../../domain/models/android_emulator.dart';
import '../../domain/models/react_native_project.dart';
import '../../domain/models/simulator_device.dart';
import '../../providers/android_emulator_providers.dart';
import '../../providers/infra_providers.dart';
import '../../providers/react_native_providers.dart';
import '../../providers/simulator_providers.dart';

class ReactNativePage extends ConsumerStatefulWidget {
  const ReactNativePage({super.key});

  @override
  ConsumerState<ReactNativePage> createState() => _ReactNativePageState();
}

class _ReactNativePageState extends ConsumerState<ReactNativePage> {
  String? _androidSerial;
  String? _iosUdid;
  bool? _monitoringEnabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = TickerMode.valuesOf(context).enabled;
    if (_monitoringEnabled == enabled) return;
    _monitoringEnabled = enabled;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(reactNativeWorkspaceProvider.notifier).setMonitoring(enabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reactNativeWorkspaceProvider);
    final notifier = ref.read(reactNativeWorkspaceProvider.notifier);
    final androidDevices =
        ref.watch(androidEmulatorsProvider).valueOrNull ?? [];
    final iosDevices = ref.watch(simulatorsProvider).valueOrNull ?? [];
    final runningAndroid = androidDevices
        .where((device) => device.isRunning && device.serial != null)
        .toList();
    final bootedIos = iosDevices.where((device) => device.isBooted).toList();
    final project = state.selectedProject;

    return Scaffold(
      appBar: AppBar(
        title: AppPageTitle(
          title: context.l10n.reactNative,
          subtitle: context.l10n.reactNativeSubtitle,
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _addProject(context),
            icon: const Icon(Icons.create_new_folder_outlined, size: 18),
            label: Text(context.l10n.addRnProject),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: state.loading ? null : notifier.refresh,
              icon: state.loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.refresh),
            ),
          ),
        ],
      ),
      body: state.loading && state.projects.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? _ErrorState(error: state.error!, onRetry: notifier.refresh)
          : project == null
          ? _EmptyState(onAdd: () => _addProject(context))
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              children: [
                _ProjectSelector(
                  projects: state.projects,
                  selected: project,
                  onSelected: notifier.selectProject,
                  openOptions: state.openOptions,
                  onOpen: (target) => _openProject(project, target),
                ),
                const SizedBox(height: 14),
                _MetroCard(
                  project: project,
                  status: state.metro,
                  onStart: project.hasScript('start')
                      ? () => _runScript('start')
                      : null,
                  onReset: project.hasScript('start')
                      ? () => _runAction(
                          context.l10n.resetMetroCache,
                          notifier.resetMetro,
                        )
                      : null,
                  onDevTools: state.metro.running
                      ? () => _runAction(
                          context.l10n.openRnDevTools,
                          notifier.openDevTools,
                        )
                      : null,
                  onRefresh: notifier.refreshMetro,
                ),
                const SizedBox(height: 14),
                _CommandCard(project: project, onRun: _runScript),
                const SizedBox(height: 14),
                _DeviceToolsCard(
                  runningAndroid: runningAndroid,
                  bootedIos: bootedIos,
                  selectedAndroidSerial: _androidSerial,
                  selectedIosUdid: _iosUdid,
                  onAndroidSelected: (serial) =>
                      setState(() => _androidSerial = serial),
                  onIosSelected: (udid) => setState(() => _iosUdid = udid),
                  onAndroidDevMenu: () => _androidAction(
                    runningAndroid,
                    (device) => ref
                        .read(androidEmulatorRepositoryProvider)
                        .openDevMenu(device.serial!),
                    context.l10n.androidDevMenu,
                  ),
                  onAndroidReload: () => _androidAction(
                    runningAndroid,
                    (device) => ref
                        .read(androidEmulatorRepositoryProvider)
                        .reloadJs(device.serial!),
                    context.l10n.androidReload,
                  ),
                  onAndroidReverse: () => _androidAction(
                    runningAndroid,
                    (device) async {
                      final successMessage = context.l10n.metroReverseDone(
                        device.name,
                        project.metroPort,
                      );
                      await ref
                          .read(androidEmulatorRepositoryProvider)
                          .reversePort(device.serial!, project.metroPort);
                      if (mounted) {
                        _showMessage(successMessage);
                      }
                    },
                    context.l10n.androidMetroReverse,
                    showSuccess: false,
                  ),
                  onIosDevMenu: () => _iosAction(
                    bootedIos,
                    (device) => ref
                        .read(simulatorRepositoryProvider)
                        .openReactNativeDevMenu(device.udid),
                    context.l10n.iosDevMenu,
                  ),
                  onIosReload: () => _iosAction(
                    bootedIos,
                    (device) => ref
                        .read(simulatorRepositoryProvider)
                        .reloadReactNative(device.udid),
                    context.l10n.iosReload,
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _addProject(BuildContext context) async {
    final repository = ref.read(reactNativeRepositoryProvider);
    final settings = ref.read(settingsProvider);
    final l10n = context.l10n;
    final prompt = l10n.chooseRnProject;
    final invalidProject = l10n.invalidRnProject;
    final addProjectLabel = l10n.addRnProject;
    try {
      final path = await repository.chooseProject(prompt);
      if (path == null || !mounted) return;
      final project = await repository.loadProject(
        path,
        defaultMetroPort: settings.metroPort,
      );
      if (project == null) {
        _showError(invalidProject, 'package.json');
        return;
      }
      final addedMessage = l10n.projectAdded(project.name);
      if (!settings.reactNativeRoots.contains(project.path)) {
        await ref
            .read(settingsProvider.notifier)
            .update(
              settings.copyWith(
                reactNativeRoots: [...settings.reactNativeRoots, project.path],
              ),
            );
      }
      if (!mounted) return;
      ref.invalidate(reactNativeWorkspaceProvider);
      _showMessage(addedMessage);
    } catch (error) {
      if (mounted) _showError(addProjectLabel, error);
    }
  }

  Future<void> _runScript(String script) async {
    final project = ref.read(reactNativeWorkspaceProvider).selectedProject;
    final command = project == null
        ? script
        : '${project.packageManagerLabel.toLowerCase()} $script';
    await _runAction(
      script,
      () => ref.read(reactNativeWorkspaceProvider.notifier).runScript(script),
      success: context.l10n.commandStarted(command),
    );
  }

  Future<void> _openProject(
    ReactNativeProject project,
    ProjectOpenTarget target,
  ) async {
    final label = context.l10n.projectOpenTargetLabel(target);
    await _runAction(
      label,
      () => ref.read(reactNativeWorkspaceProvider.notifier).openProject(target),
      success: context.l10n.projectOpenedWith(project.name, label),
    );
  }

  Future<void> _androidAction(
    List<AndroidEmulator> devices,
    Future<void> Function(AndroidEmulator device) action,
    String label, {
    bool showSuccess = true,
  }) async {
    if (devices.isEmpty) {
      _showError(label, context.l10n.noRunningAndroid);
      return;
    }
    final device = devices.firstWhere(
      (item) => item.serial == _androidSerial,
      orElse: () => devices.first,
    );
    await _runAction(
      label,
      () => action(device),
      success: showSuccess
          ? context.l10n.emulatorActionSent(label, device.name)
          : null,
    );
  }

  Future<void> _iosAction(
    List<SimulatorDevice> devices,
    Future<void> Function(SimulatorDevice device) action,
    String label,
  ) async {
    if (devices.isEmpty) {
      _showError(label, context.l10n.noBootedIos);
      return;
    }
    final device = devices.firstWhere(
      (item) => item.udid == _iosUdid,
      orElse: () => devices.first,
    );
    await _runAction(
      label,
      () => action(device),
      success: context.l10n.emulatorActionSent(label, device.name),
    );
  }

  Future<void> _runAction(
    String label,
    Future<void> Function() action, {
    String? success,
  }) async {
    try {
      await action();
      if (mounted && success != null) _showMessage(success);
    } catch (error) {
      if (mounted) _showError(label, error);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String title, Object error) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.operationError(title, error))),
      );
  }
}

class _ProjectSelector extends StatelessWidget {
  final List<ReactNativeProject> projects;
  final ReactNativeProject selected;
  final ValueChanged<String> onSelected;
  final List<ProjectOpenOption> openOptions;
  final ValueChanged<ProjectOpenTarget> onOpen;

  const _ProjectSelector({
    required this.projects,
    required this.selected,
    required this.onSelected,
    required this.openOptions,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ReactNativeIcon(size: 22, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selected.path,
                  isExpanded: true,
                  items: projects
                      .map(
                        (project) => DropdownMenuItem(
                          value: project.path,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${project.packageManagerLabel} · ${project.path}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onSelected(value);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            PopupMenuButton<ProjectOpenTarget>(
              tooltip: context.l10n.openProjectHint,
              onSelected: onOpen,
              itemBuilder: (_) => openOptions
                  .map(
                    (option) => PopupMenuItem(
                      value: option.target,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(_openTargetIcon(option.target), size: 18),
                        title: Text(
                          context.l10n.projectOpenTargetLabel(option.target),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              child: IgnorePointer(
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: Text(context.l10n.openProject),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _openTargetIcon(ProjectOpenTarget target) {
    return switch (target) {
      ProjectOpenTarget.codexDesktop => Icons.hub_outlined,
      ProjectOpenTarget.codexCli => Icons.terminal_rounded,
      ProjectOpenTarget.cursor => Icons.mouse_rounded,
      ProjectOpenTarget.visualStudioCode => Icons.code_rounded,
      ProjectOpenTarget.androidStudio => Icons.android_rounded,
      ProjectOpenTarget.xcode => Icons.phone_iphone_rounded,
      ProjectOpenTarget.qoder => Icons.integration_instructions_rounded,
      ProjectOpenTarget.trae => Icons.architecture_rounded,
      ProjectOpenTarget.webStorm => Icons.language_rounded,
      ProjectOpenTarget.zed => Icons.edit_note_rounded,
      ProjectOpenTarget.windsurf => Icons.air_rounded,
      ProjectOpenTarget.finder => Icons.folder_open_rounded,
      ProjectOpenTarget.terminal => Icons.terminal_rounded,
    };
  }
}

class _MetroCard extends StatelessWidget {
  final ReactNativeProject project;
  final MetroStatus status;
  final VoidCallback? onStart;
  final VoidCallback? onReset;
  final VoidCallback? onDevTools;
  final VoidCallback onRefresh;

  const _MetroCard({
    required this.project,
    required this.status,
    required this.onStart,
    required this.onReset,
    required this.onDevTools,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = status.running ? AppPalette.successFor(context) : cs.outline;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.router_outlined, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.metroService,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        status.running
                            ? context.l10n.metroRunning(status.port)
                            : context.l10n.metroStopped(status.port),
                        style: TextStyle(color: color, fontSize: 12),
                      ),
                      if (status.running && status.pid != null)
                        Text(
                          context.l10n.metroProcess(
                            status.pid!,
                            status.processName ?? 'node',
                          ),
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 10.5,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  context.l10n.metroWatching,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
                ),
                IconButton(
                  tooltip: context.l10n.refresh,
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: status.running ? null : onStart,
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(context.l10n.startMetro),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: Text(context.l10n.resetMetroCache),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDevTools,
                    icon: const Icon(Icons.bug_report_outlined, size: 18),
                    label: Text(context.l10n.openRnDevTools),
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

class _CommandCard extends StatelessWidget {
  static const commonScripts = ['android', 'ios', 'charles', 'runios'];

  final ReactNativeProject project;
  final ValueChanged<String> onRun;

  const _CommandCard({required this.project, required this.onRun});

  @override
  Widget build(BuildContext context) {
    final available = commonScripts.where(project.hasScript).toList();
    final remaining =
        project.scripts.keys
            .where((script) => script != 'start' && !available.contains(script))
            .toList()
          ..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.terminal_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.quickCommands,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (remaining.isNotEmpty)
                  PopupMenuButton<String>(
                    tooltip: context.l10n.moreScripts,
                    onSelected: onRun,
                    itemBuilder: (_) => remaining
                        .map(
                          (script) => PopupMenuItem(
                            value: script,
                            child: Text(
                              '${project.packageManagerLabel.toLowerCase()} $script',
                            ),
                          ),
                        )
                        .toList(),
                    child: Row(
                      children: [
                        Text(
                          context.l10n.moreScripts,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: available.map((script) {
                final presentation = _scriptPresentation(context, script);
                return OutlinedButton.icon(
                  onPressed: () => onRun(script),
                  icon: Icon(presentation.$1, size: 18),
                  label: Text(presentation.$2),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, String) _scriptPresentation(BuildContext context, String script) {
    return switch (script) {
      'android' => (Icons.android_rounded, context.l10n.runAndroid),
      'ios' => (Icons.phone_iphone_rounded, context.l10n.runIos),
      'runios' => (Icons.rocket_launch_rounded, context.l10n.runIosSetup),
      'charles' => (Icons.network_check_rounded, context.l10n.runCharles),
      _ => (Icons.play_arrow_rounded, script),
    };
  }
}

class _DeviceToolsCard extends StatelessWidget {
  final List<AndroidEmulator> runningAndroid;
  final List<SimulatorDevice> bootedIos;
  final String? selectedAndroidSerial;
  final String? selectedIosUdid;
  final ValueChanged<String?> onAndroidSelected;
  final ValueChanged<String?> onIosSelected;
  final VoidCallback onAndroidDevMenu;
  final VoidCallback onAndroidReload;
  final VoidCallback onAndroidReverse;
  final VoidCallback onIosDevMenu;
  final VoidCallback onIosReload;

  const _DeviceToolsCard({
    required this.runningAndroid,
    required this.bootedIos,
    required this.selectedAndroidSerial,
    required this.selectedIosUdid,
    required this.onAndroidSelected,
    required this.onIosSelected,
    required this.onAndroidDevMenu,
    required this.onAndroidReload,
    required this.onAndroidReverse,
    required this.onIosDevMenu,
    required this.onIosReload,
  });

  @override
  Widget build(BuildContext context) {
    final androidValue =
        runningAndroid.any((item) => item.serial == selectedAndroidSerial)
        ? selectedAndroidSerial
        : runningAndroid.isEmpty
        ? null
        : runningAndroid.first.serial;
    final iosValue = bootedIos.any((item) => item.udid == selectedIosUdid)
        ? selectedIosUdid
        : bootedIos.isEmpty
        ? null
        : bootedIos.first.udid;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.devices_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.rnDeviceTools,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DeviceToolRow(
              icon: Icons.android_rounded,
              label: 'Android',
              devices: runningAndroid
                  .map((device) => MapEntry(device.serial!, device.name))
                  .toList(),
              selected: androidValue,
              emptyLabel: context.l10n.noRunningAndroid,
              onSelected: onAndroidSelected,
              actions: [
                (context.l10n.androidMetroReverse, onAndroidReverse),
                (context.l10n.androidDevMenu, onAndroidDevMenu),
                (context.l10n.androidReload, onAndroidReload),
              ],
            ),
            const Divider(height: 26),
            _DeviceToolRow(
              icon: Icons.phone_iphone_rounded,
              label: 'iOS',
              devices: bootedIos
                  .map((device) => MapEntry(device.udid, device.name))
                  .toList(),
              selected: iosValue,
              emptyLabel: context.l10n.noBootedIos,
              onSelected: onIosSelected,
              actions: [
                (context.l10n.iosDevMenu, onIosDevMenu),
                (context.l10n.iosReload, onIosReload),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.iosRnShortcutHint,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceToolRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<MapEntry<String, String>> devices;
  final String? selected;
  final String emptyLabel;
  final ValueChanged<String?> onSelected;
  final List<(String, VoidCallback)> actions;

  const _DeviceToolRow({
    required this.icon,
    required this.label,
    required this.devices,
    required this.selected,
    required this.emptyLabel,
    required this.onSelected,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = devices.isNotEmpty;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Row(
            children: [
              Icon(icon, size: 19),
              const SizedBox(width: 7),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        SizedBox(
          width: 190,
          child: enabled
              ? DropdownButtonFormField<String>(
                  initialValue: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                  ),
                  items: devices
                      .map(
                        (device) => DropdownMenuItem(
                          value: device.key,
                          child: Text(
                            device.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onSelected,
                )
              : Text(
                  emptyLabel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 7,
            runSpacing: 7,
            alignment: WrapAlignment.end,
            children: actions
                .map(
                  (action) => OutlinedButton(
                    onPressed: enabled ? action.$2 : null,
                    child: Text(action.$1),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReactNativeIcon(
            size: 58,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.noRnProjects,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 430,
            child: Text(
              context.l10n.noRnProjectsDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.create_new_folder_outlined),
            label: Text(context.l10n.addRnProject),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.errorMessage(error)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.refresh),
          ),
        ],
      ),
    );
  }
}
