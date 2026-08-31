import 'package:flutter/material.dart';

class _SidebarItem {
  final IconData icon;
  final String label;
  const _SidebarItem(this.icon, this.label);
}

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const Sidebar({super.key, required this.selectedIndex, required this.onSelected});

  static const _items = [
    _SidebarItem(Icons.dashboard_rounded, 'Overview'),
    _SidebarItem(Icons.search_rounded, 'Scan & Clean'),
    _SidebarItem(Icons.folder_open_rounded, 'Large Files'),
    _SidebarItem(Icons.folder_rounded, 'Node Modules'),
    _SidebarItem(Icons.devices_rounded, 'Simulators'),
    _SidebarItem(Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 200,
      child: Container(
        color: cs.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.cleaning_services_rounded, color: cs.primary, size: 28),
                  const SizedBox(width: 8),
                  Text('Mac Tool', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ..._items.asMap().entries.map((e) {
              final selected = e.key == selectedIndex;
              return _SidebarTile(
                item: e.value,
                selected: selected,
                onTap: () => onSelected(e.key),
              );
            }),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _SidebarItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? cs.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(item.icon,
                    size: 20,
                    color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
