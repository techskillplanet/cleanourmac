import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format/byte_format.dart';
import '../../core/theme/safety_colors.dart';
import '../../domain/models/cleanup_target.dart';
import '../../domain/models/scan_item.dart';
import '../../providers/scan_providers.dart';

class CategoryDetailPage extends ConsumerWidget {
  final String categoryId;
  const CategoryDetailPage({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanProvider);
    final summary = scan.categories[categoryId];

    if (summary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Category')),
        body: const Center(child: Text('Not found')),
      );
    }

    final notifier = ref.read(scanProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(summary.target.label),
        actions: [
          TextButton(
            onPressed: () => notifier.toggleCategory(categoryId, true),
            child: const Text('Select All'),
          ),
          TextButton(
            onPressed: () => notifier.toggleCategory(categoryId, false),
            child: const Text('Deselect All'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(summary: summary),
          const Divider(height: 1),
          Expanded(
            child: summary.items.isEmpty
                ? const Center(
                    child: Text(
                      'No items found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: summary.items.length,
                    itemBuilder: (ctx, i) {
                      final item = summary.items[i];
                      return _ItemTile(
                        item: item,
                        onToggle: (v) =>
                            notifier.toggleItem(categoryId, item.path, v),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final dynamic summary;
  const _Header({required this.summary});

  @override
  Widget build(BuildContext context) {
    final safeColor = switch (summary.target.safety as SafetyLevel) {
      SafetyLevel.safe => SafetyColors.safe,
      SafetyLevel.caution => SafetyColors.caution,
      SafetyLevel.danger => SafetyColors.danger,
    };

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: safeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, size: 14, color: safeColor),
                const SizedBox(width: 4),
                Text(
                  switch (summary.target.safety as SafetyLevel) {
                    SafetyLevel.safe => 'Safe to clean',
                    SafetyLevel.caution => 'Caution',
                    SafetyLevel.danger => 'Danger',
                  },
                  style: TextStyle(
                    fontSize: 12,
                    color: safeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatBytes(summary.totalBytes as int),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              Text(
                '${(summary.items as List).length} items',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ScanItem item;
  final ValueChanged<bool> onToggle;

  const _ItemTile({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: item.selected,
      onChanged: (v) => onToggle(v ?? false),
      title: Text(
        item.name,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        item.detail == null ? item.path : '${item.detail}\n${item.path}',
        style: const TextStyle(fontSize: 11, color: Colors.grey),
        maxLines: item.detail == null ? 1 : 2,
        overflow: TextOverflow.ellipsis,
      ),
      secondary: Text(
        formatBytes(item.sizeBytes),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
