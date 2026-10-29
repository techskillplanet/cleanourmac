import 'package:flutter/material.dart';
import '../ai_agents/ai_agent_cache_page.dart';
import '../fcm/fcm_push_page.dart';
import '../react_native/react_native_page.dart';
import 'sidebar.dart';
import '../dashboard/dashboard_page.dart';
import '../scanner/scan_page.dart';
import '../large_files/large_files_page.dart';
import '../simulators/simulator_page.dart';
import '../project_caches/project_cache_page.dart';
import '../settings/settings_page.dart';
import '../jwt/jwt_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final List<Widget?> _pageCache = List<Widget?>.filled(10, null);

  Widget _createPage(int index) {
    return switch (index) {
      0 => DashboardPage(
        onOpenDevices: () => _selectPage(3),
        onStartScan: () => _selectPage(5),
      ),
      1 => const JwtPage(),
      2 => const FcmPushPage(),
      3 => const SimulatorPage(),
      4 => const ReactNativePage(),
      5 => const ScanPage(),
      6 => const ProjectCachePage(),
      7 => const AiAgentCachePage(),
      8 => const LargeFilesPage(),
      9 => const SettingsPage(),
      _ => const SizedBox.shrink(),
    };
  }

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    _pageCache[_selectedIndex] ??= _createPage(_selectedIndex);

    return Scaffold(
      body: Row(
        children: [
          Sidebar(selectedIndex: _selectedIndex, onSelected: _selectPage),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: List.generate(
                _pageCache.length,
                (index) => TickerMode(
                  enabled: index == _selectedIndex,
                  child: _pageCache[index] ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
