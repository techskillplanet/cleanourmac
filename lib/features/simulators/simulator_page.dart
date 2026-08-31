import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        body: Center(child: Text('Error: ${iosAsync.error}')),
      );
    }

    final ios = iosAsync.valueOrNull ?? const <SimulatorDevice>[];
    final android = androidAsync.valueOrNull ?? const <AndroidEmulator>[];

    // Show platform when devices exist; keep Android visible if SDK is installed.
    final hasIos = ios.isNotEmpty;
    final hasAndroid = android.isNotEmpty || androidSdk;

    if (!hasIos && !hasAndroid) {
      return Scaffold(
        appBar: _appBar(),
        body: const Center(
          child: Text(
            'No simulators found',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if (hasIos && hasAndroid) {
      return DefaultTabController(
        length: 2,
        initialIndex: _selectedTab,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Simulators'),
            elevation: 0,
            actions: _refreshActions(),
            bottom: TabBar(
              onTap: (index) => _selectedTab = index,
              tabs: const [
                Tab(
                  icon: Icon(Icons.phone_iphone_rounded, size: 18),
                  text: 'iOS',
                ),
                Tab(icon: Icon(Icons.android, size: 18), text: 'Android'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              IosSimulatorPanel(devices: ios),
              AndroidEmulatorPanel(
                emulators: android,
                sdkAvailable: androidSdk,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(hasIos ? 'iOS Simulators' : 'Android Emulators'),
        elevation: 0,
        actions: _refreshActions(),
      ),
      body: hasIos
          ? IosSimulatorPanel(devices: ios)
          : AndroidEmulatorPanel(emulators: android, sdkAvailable: androidSdk),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      title: const Text('Simulators'),
      elevation: 0,
      actions: _refreshActions(),
    );
  }

  List<Widget> _refreshActions() {
    return [
      TextButton.icon(
        onPressed: () {
          ref.invalidate(simulatorsProvider);
          ref.invalidate(androidEmulatorsProvider);
        },
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Refresh'),
      ),
      const SizedBox(width: 8),
    ];
  }
}
