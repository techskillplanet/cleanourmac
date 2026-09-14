import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/byte_format.dart';
import '../../core/l10n/localization_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_page_title.dart';
import '../../domain/models/project_cache.dart';
import '../../providers/infra_providers.dart';
import '../../providers/project_cache_providers.dart';

class ProjectCachePage extends ConsumerWidget {
  const ProjectCachePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectCacheProvider);
    final notifier = ref.read(projectCacheProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: AppPageTitle(
          title: context.l10n.projectCaches,
          subtitle: context.l10n.projectCachesSubtitle,
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _addRoot(context, ref),
            icon: const Icon(Icons.create_new_folder_outlined, size: 18),
            label: Text(context.l10n.addRnProject),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: state.scanning ? null : notifier.scan,
              icon: state.scanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.detectCaches),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.scanning) const LinearProgressIndicator(),
          if (state.lastResult != null)
            _ResultBanner(result: state.lastResult!),
          Expanded(
            child: state.scanning && state.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                ? _ErrorState(error: state.error!, onRetry: notifier.scan)
                : state.items.isEmpty
                ? _EmptyState(onRetry: notifier.scan)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 110),
                    children: [
                      const _SafetyNotice(),
                      const SizedBox(height: 14),
                      _Summary(state: state, notifier: notifier),
                      const SizedBox(height: 14),
                      ..._groupByProject(state.items).entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ProjectGroup(
                            items: entry.value,
                            onToggle: notifier.toggle,
                            onToggleAll: (selected) =>
                                notifier.toggleProject(entry.key, selected),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          if (state.selectedCount > 0)
            _CleanBar(
              state: state,
              onClean: () => _confirmClean(context, notifier, state),
            ),
        ],
      ),
    );
  }

  Future<void> _addRoot(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      final path = await ref
          .read(projectCacheRepositoryProvider)
          .chooseRoot(l10n.developmentRoots);
      if (path == null || !context.mounted) return;
      final settings = ref.read(settingsProvider);
      if (!settings.developmentRoots.contains(path)) {
        await ref
            .read(settingsProvider.notifier)
            .update(
              settings.copyWith(
                developmentRoots: [...settings.developmentRoots, path],
              ),
            );
      }
      ref.invalidate(projectCacheProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.errorMessage(error))));
    }
  }

  Future<void> _confirmClean(
    BuildContext context,
    ProjectCacheNotifier notifier,
    ProjectCacheState state,
  ) async {
    final selected = state.items.where((item) => item.selected).toList();
    var consent = false;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.confirmProjectCacheCleanTitle),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.confirmProjectCacheCleanDescription),
                const SizedBox(height: 12),
                SizedBox(
                  height: (selected.length * 56.0).clamp(70.0, 260.0),
                  child: ListView.separated(
                    itemCount: selected.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = selected[index];
                      return Row(
                        children: [
                          Icon(_ecosystemIcon(item.ecosystem), size: 18),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.projectName} · '
                                  '${context.l10n.projectCacheKindLabel(item.kind)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  item.path,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatBytes(
                              item.sizeBytes,
                              locale: context.localeName,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                CheckboxListTile(
                  value: consent,
                  onChanged: (value) =>
                      setDialogState(() => consent = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    context.l10n.projectCacheConsentLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton.icon(
              onPressed: consent
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              icon: const Icon(Icons.delete_sweep_outlined, size: 18),
              label: Text(context.l10n.clearCaches),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) await notifier.cleanSelected();
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: cs.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.projectCacheSafetyTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.projectCacheSafetyDescription,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final ProjectCacheState state;
  final ProjectCacheNotifier notifier;

  const _Summary({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Icon(
              Icons.folder_special_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.l10n.projectCacheSummary(
                  state.items.length,
                  state.projectCount,
                  formatBytes(state.totalBytes, locale: context.localeName),
                ),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => notifier.toggleAll(true),
              child: Text(context.l10n.selectAll),
            ),
            TextButton(
              onPressed: () => notifier.toggleAll(false),
              child: Text(context.l10n.deselectAll),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectGroup extends StatelessWidget {
  final List<ProjectCacheItem> items;
  final void Function(String id, bool selected) onToggle;
  final ValueChanged<bool> onToggleAll;

  const _ProjectGroup({
    required this.items,
    required this.onToggle,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    final first = items.first;
    final total = items.fold<int>(0, (sum, item) => sum + item.sizeBytes);
    final allSelected = items.every((item) => item.selected);
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 10, 11),
            child: Row(
              children: [
                Icon(
                  _ecosystemIcon(first.ecosystem),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        first.projectName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${context.l10n.projectCacheEcosystemLabel(first.ecosystem)} · '
                        '${items.length} · '
                        '${formatBytes(total, locale: context.localeName)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  tristate: true,
                  value: allSelected
                      ? true
                      : items.any((item) => item.selected)
                      ? null
                      : false,
                  onChanged: (value) => onToggleAll(value ?? !allSelected),
                ),
              ],
            ),
          ),
          const Divider(),
          ...items.map(
            (item) => CheckboxListTile(
              value: item.selected,
              onChanged: (value) => onToggle(item.id, value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              title: Text(
                context.l10n.projectCacheKindLabel(item.kind),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                item.path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                ),
              ),
              secondary: Text(
                formatBytes(item.sizeBytes, locale: context.localeName),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanBar extends StatelessWidget {
  final ProjectCacheState state;
  final VoidCallback onClean;

  const _CleanBar({required this.state, required this.onClean});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Text(
            context.l10n.selectedSummary(
              state.selectedCount,
              formatBytes(state.selectedBytes, locale: context.localeName),
            ),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: state.cleaning ? null : onClean,
            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
            label: Text(context.l10n.cleanSelectedCaches),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final ProjectCacheCleanupResult result;

  const _ResultBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppPalette.successFor(context).withValues(alpha: 0.09),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Text(
        context.l10n.projectCacheCleaned(
          result.cleanedCount,
          formatBytes(result.reclaimedBytes, locale: context.localeName),
        ),
        style: TextStyle(
          color: AppPalette.successFor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.folder_off_outlined,
          size: 54,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.projectCacheEmpty,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.projectCacheEmptyDescription,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.l10n.detectCaches),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.errorMessage(error)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: Text(context.l10n.refresh)),
      ],
    ),
  );
}

Map<String, List<ProjectCacheItem>> _groupByProject(
  List<ProjectCacheItem> items,
) {
  final result = <String, List<ProjectCacheItem>>{};
  for (final item in items) {
    result.putIfAbsent(item.projectRoot, () => []).add(item);
  }
  return result;
}

IconData _ecosystemIcon(ProjectCacheEcosystem ecosystem) => switch (ecosystem) {
  ProjectCacheEcosystem.flutter => Icons.flutter_dash_rounded,
  ProjectCacheEcosystem.android => Icons.android_rounded,
  ProjectCacheEcosystem.ios => Icons.phone_iphone_rounded,
  ProjectCacheEcosystem.reactNative => Icons.device_hub_rounded,
  ProjectCacheEcosystem.web => Icons.language_rounded,
};
