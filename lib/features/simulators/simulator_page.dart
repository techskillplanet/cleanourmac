import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/localization_extensions.dart';
import '../../core/widgets/app_page_title.dart';
import '../../domain/models/android_emulator.dart';
import '../../domain/models/simulator_device.dart';
import '../../providers/android_emulator_providers.dart';
import '../../providers/infra_providers.dart';
import '../../providers/simulator_providers.dart';
import 'android_emulator_panel.dart';
import 'ios_simulator_panel.dart';

class SimulatorPage extends ConsumerStatefulWidget {
  const SimulatorPage({super.key});

  @override
  ConsumerState<SimulatorPage> createState() => _SimulatorPageState();
}

class _SimulatorPageState extends ConsumerState<SimulatorPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final iosAsync = ref.watch(simulatorsProvider);
    final androidAsync = ref.watch(androidEmulatorsProvider);
    final androidSdk = ref.watch(androidEmulatorRepositoryProvider).isAvailable;

    if (iosAsync.isLoading || androidAsync.isLoading) {
      return Scaffold(
        appBar: _appBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (iosAsync.hasError && androidAsync.hasError) {
      return Scaffold(
        appBar: _appBar(),
        body: Center(child: Text(context.l10n.errorMessage(iosAsync.error!))),
      );
    }

    final ios = iosAsync.valueOrNull ?? const <SimulatorDevice>[];
    final android = androidAsync.valueOrNull ?? const <AndroidEmulator>[];
    final hasIos = ios.isNotEmpty;
    final hasAndroid = android.isNotEmpty || androidSdk;

    if (!hasIos && !hasAndroid) {
      return Scaffold(
        appBar: _appBar(),
        body: Center(
          child: Text(
            context.l10n.noSimulatorsFound,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    if (hasAndroid && hasIos) {
      return DefaultTabController(
        length: 2,
        initialIndex: _selectedTab,
        child: Scaffold(
          appBar: AppBar(
            title: AppPageTitle(
              title: context.l10n.simulators,
              subtitle: context.l10n.deviceLabSubtitle,
            ),
            actions: _refreshActions(),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(58),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: TabBar(
                    onTap: (index) => _selectedTab = index,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Theme.of(context).colorScheme.onPrimary,
                    unselectedLabelColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.android_rounded, size: 17),
                            const SizedBox(width: 7),
                            Text(context.l10n.androidTab(android.length)),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone_iphone_rounded, size: 17),
                            const SizedBox(width: 7),
                            Text(context.l10n.iosTab(ios.length)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: TabBarView(
            children: [
              AndroidEmulatorPanel(
                emulators: android,
                sdkAvailable: androidSdk,
              ),
              IosSimulatorPanel(devices: ios),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _appBar(),
      body: hasAndroid
          ? AndroidEmulatorPanel(emulators: android, sdkAvailable: androidSdk)
          : IosSimulatorPanel(devices: ios),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      title: AppPageTitle(
        title: context.l10n.simulators,
        subtitle: context.l10n.deviceLabSubtitle,
      ),
      actions: _refreshActions(),
    );
  }

  List<Widget> _refreshActions() {
    return [
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: TextButton.icon(
          onPressed: () {
            ref.invalidate(simulatorsProvider);
            ref.invalidate(androidEmulatorsProvider);
          },
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(context.l10n.refresh),
        ),
      ),
    ];
  }
}
