import 'package:flutter/material.dart';

import '../../core/l10n/localization_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/react_native_icon.dart';

class _SidebarItem {
  final IconData? icon;
  final bool isReactNative;

  const _SidebarItem.icon(this.icon) : isReactNative = false;
  const _SidebarItem.reactNative() : icon = null, isReactNative = true;
}

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _items = [
    _SidebarItem.icon(Icons.space_dashboard_rounded),
    _SidebarItem.icon(Icons.devices_rounded),
    _SidebarItem.reactNative(),
    _SidebarItem.icon(Icons.auto_delete_rounded),
    _SidebarItem.icon(Icons.folder_special_outlined),
    _SidebarItem.icon(Icons.smart_toy_outlined),
    _SidebarItem.icon(Icons.folder_copy_rounded),
    _SidebarItem.icon(Icons.data_object_rounded),
    _SidebarItem.icon(Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = cs.brightness == Brightness.dark;
    final l10n = context.l10n;
    final labels = [
      l10n.overview,
      l10n.simulators,
      l10n.reactNative,
      l10n.scanAndClean,
      l10n.projectCaches,
      l10n.aiAgentCaches,
      l10n.largeFiles,
      l10n.nodeModules,
      l10n.settings,
    ];
    return SizedBox(
      width: 224,
      child: Container(
        decoration: BoxDecoration(
          color: dark ? cs.surface : null,
          gradient: dark
              ? null
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF1F2F4),
                    AppPalette.sidebar,
                    Color(0xFFEAEDF0),
                  ],
                  stops: [0, 0.58, 1],
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.asset(
                      'assets/brand/mobile_dev_assistant_mark.png',
                      width: 38,
                      height: 38,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.25,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.brandEdition,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.85,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _items.asMap().entries.map((e) {
                  final selected = e.key == selectedIndex;
                  return _SidebarTile(
                    item: e.value,
                    label: labels[e.key],
                    selected: selected,
                    onTap: () => onSelected(e.key),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: dark ? cs.surfaceContainer : const Color(0xFFF7F8F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.localPrivate,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _SidebarItem item;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = cs.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? (dark ? cs.surfaceContainerHigh : const Color(0xFFFAFBFC))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? cs.outline : Colors.transparent),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.24 : 0.06),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: selected
                          ? cs.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: item.isReactNative
                        ? ReactNativeIcon(
                            size: 19,
                            color: selected ? cs.primary : cs.onSurfaceVariant,
                          )
                        : Icon(
                            item.icon,
                            size: 19,
                            color: selected ? cs.primary : cs.onSurfaceVariant,
                          ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? cs.primary : cs.onSurfaceVariant,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
