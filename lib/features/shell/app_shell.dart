import 'package:flutter/material.dart';
import 'sidebar.dart';
import '../dashboard/dashboard_page.dart';
import '../scanner/scan_page.dart';
import '../large_files/large_files_page.dart';
import '../simulators/simulator_page.dart';
import '../node_modules/node_modules_page.dart';
import '../settings/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _pages = [
    DashboardPage(),
    ScanPage(),
    LargeFilesPage(),
    NodeModulesPage(),
    SimulatorPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onSelected: (i) => setState(() => _selectedIndex = i),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
