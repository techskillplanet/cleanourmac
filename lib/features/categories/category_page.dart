import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/format/byte_format.dart';
import '../../core/l10n/localization_extensions.dart';
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
        appBar: AppBar(title: Text(context.l10n.category)),
        body: Center(child: Text(context.l10n.notFound)),
      );
    }

    final notifier = ref.read(scanProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.cleanupTargetLabel(
            summary.target.id,
            fallback: summary.target.label,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => notifier.toggleCategory(categoryId, true),
            child: Text(context.l10n.selectAll),
          ),
          TextButton(
            onPressed: () => notifier.toggleCategory(categoryId, false),
            child: Text(context.l10n.deselectAll),
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
                ? Center(
                    child: Text(
                      context.l10n.noItemsFound,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: summary.items.length,
                    itemBuilder: (ctx, i) {
                      final item = summary.items[i];
                      return _ItemTile(
                        categoryId: categoryId,
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
      SafetyLevel.safe => SafetyColors.safeFor(context),
      SafetyLevel.caution => SafetyColors.cautionFor(context),
      SafetyLevel.danger => SafetyColors.dangerFor(context),
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
                  context.l10n.safetyLabel(
                    summary.target.safety as SafetyLevel,
                  ),
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
                formatBytes(
                  summary.totalBytes as int,
                  locale: context.localeName,
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              Text(
                context.l10n.itemCount((summary.items as List).length),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final String categoryId;
  final ScanItem item;
  final ValueChanged<bool> onToggle;

  const _ItemTile({
    required this.categoryId,
    required this.item,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final detail = context.l10n.localizedScanItemDetail(item);

    return CheckboxListTile(
      value: item.selected,
      onChanged: (v) => onToggle(v ?? false),
      title: Text(
        context.l10n.localizedScanItemName(categoryId, item),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        detail == null ? item.path : '$detail\n${item.path}',
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        maxLines: detail == null ? 1 : 2,
        overflow: TextOverflow.ellipsis,
      ),
      secondary: Text(
        formatBytes(item.sizeBytes, locale: context.localeName),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
