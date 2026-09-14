import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/byte_format.dart';
import '../../core/l10n/localization_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_page_title.dart';
import '../../domain/models/ai_agent_cache.dart';
import '../../providers/ai_agent_cache_providers.dart';

class AiAgentCachePage extends ConsumerWidget {
  const AiAgentCachePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiAgentCacheProvider);
    final notifier = ref.read(aiAgentCacheProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: AppPageTitle(
          title: context.l10n.aiAgentCaches,
          subtitle: context.l10n.aiAgentCachesSubtitle,
        ),
        actions: [
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
              label: Text(
                state.scanning
                    ? context.l10n.scanningCaches
                    : context.l10n.detectCaches,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.scanning) const LinearProgressIndicator(),
          if (state.lastResult != null)
            _CleanupResultBanner(result: state.lastResult!),
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
                      const _PrivacyNotice(),
                      const SizedBox(height: 16),
                      _SummaryCard(state: state, notifier: notifier),
                      const SizedBox(height: 16),
                      ...AiAgentKind.values.map((agent) {
                        final items = state.items
                            .where((item) => item.target.agent == agent)
                            .toList();
                        if (items.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AgentGroup(
                            agent: agent,
                            items: items,
                            onToggle: notifier.toggle,
                            onToggleAll: (selected) =>
                                notifier.toggleAgent(agent, selected),
                          ),
                        );
                      }),
                    ],
                  ),
          ),
          if (state.selectedCount > 0)
            _CleanupBar(
              state: state,
              onClean: () => _confirmCleanup(context, notifier, state),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmCleanup(
    BuildContext context,
    AiAgentCacheNotifier notifier,
    AiAgentCacheState state,
  ) async {
    final selected = state.items.where((item) => item.selected).toList();
    var consent = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.confirmAiCacheCleanTitle),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.confirmAiCacheCleanDescription),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppPalette.warningFor(
                      context,
                    ).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppPalette.warningFor(
                        context,
                      ).withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppPalette.warningFor(context),
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          context.l10n.aiCacheCloseAppsHint,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: (selected.length * 58.0).clamp(58.0, 220.0),
                  child: ListView.separated(
                    itemCount: selected.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = selected[index];
                      return Row(
                        children: [
                          Icon(
                            _agentIcon(item.target.agent),
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${context.l10n.aiAgentName(item.target.agent)} · '
                                  '${context.l10n.aiAgentCacheKindLabel(item.target.kind)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.target.path,
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
                          const SizedBox(width: 12),
                          Text(
                            formatBytes(
                              item.sizeBytes,
                              locale: context.localeName,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: consent,
                  onChanged: (value) =>
                      setDialogState(() => consent = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    context.l10n.aiCacheConsentLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  subtitle: consent
                      ? null
                      : Text(
                          context.l10n.aiCacheConsentRequired,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 11,
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
              icon: const Icon(Icons.cleaning_services_rounded, size: 18),
              label: Text(context.l10n.clearCaches),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await notifier.cleanSelected();
    }
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

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
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.verified_user_outlined, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.aiCachePrivacyTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.aiCachePrivacyDescription,
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

class _SummaryCard extends StatelessWidget {
  final AiAgentCacheState state;
  final AiAgentCacheNotifier notifier;

  const _SummaryCard({required this.state, required this.notifier});

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
              child: Icon(Icons.smart_toy_outlined, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.aiCacheDetectedSummary(
                      state.agentCount,
                      state.items.length,
                      formatBytes(state.totalBytes, locale: context.localeName),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.l10n.aiCacheCloseAppsHint,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11.5,
                    ),
                  ),
                ],
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

class _AgentGroup extends StatelessWidget {
  final AiAgentKind agent;
  final List<AiAgentCacheItem> items;
  final void Function(String id, bool selected) onToggle;
  final ValueChanged<bool> onToggleAll;

  const _AgentGroup({
    required this.agent,
    required this.items,
    required this.onToggle,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = items.fold<int>(0, (sum, item) => sum + item.sizeBytes);
    final allSelected = items.every((item) => item.selected);

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_agentIcon(agent), size: 19, color: cs.primary),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.aiAgentName(agent),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${context.l10n.aiCachePathCount(items.length)} · '
                        '${formatBytes(total, locale: context.localeName)}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: context.l10n.selectAgentCaches,
                  child: Checkbox(
                    tristate: true,
                    value: allSelected
                        ? true
                        : items.any((item) => item.selected)
                        ? null
                        : false,
                    onChanged: (value) => onToggleAll(value ?? !allSelected),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ...items.map(
            (item) => CheckboxListTile(
              value: item.selected,
              onChanged: (value) => onToggle(item.target.id, value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.aiAgentCacheKindLabel(item.target.kind),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.successFor(
                        context,
                      ).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      context.l10n.aiCacheRebuildable,
                      style: TextStyle(
                        color: AppPalette.successFor(context),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                item.target.path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                  color: cs.onSurfaceVariant,
                ),
              ),
              secondary: Text(
                formatBytes(item.sizeBytes, locale: context.localeName),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanupBar extends StatelessWidget {
  final AiAgentCacheState state;
  final VoidCallback onClean;

  const _CleanupBar({required this.state, required this.onClean});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F17212A),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: cs.primary),
          const SizedBox(width: 10),
          Text(
            context.l10n.aiCacheSelectedSummary(
              state.selectedCount,
              formatBytes(state.selectedBytes, locale: context.localeName),
            ),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: state.cleaning ? null : onClean,
            icon: state.cleaning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cleaning_services_rounded, size: 18),
            label: Text(context.l10n.cleanSelectedCaches),
          ),
        ],
      ),
    );
  }
}

class _CleanupResultBanner extends StatelessWidget {
  final AiAgentCleanupResult result;

  const _CleanupResultBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      color: AppPalette.successFor(context).withValues(alpha: 0.09),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: AppPalette.successFor(context),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            context.l10n.aiCacheCleaned(
              result.cleanedCount,
              formatBytes(result.reclaimedBytes, locale: context.localeName),
            ),
            style: TextStyle(
              color: AppPalette.successFor(context),
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_outlined, size: 58, color: cs.outline),
            const SizedBox(height: 14),
            Text(
              context.l10n.noAiCachesFound,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.noAiCachesFoundDescription,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.detectCaches),
            ),
          ],
        ),
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
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(context.l10n.errorMessage(error)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.detectCaches),
          ),
        ],
      ),
    );
  }
}

IconData _agentIcon(AiAgentKind agent) {
  return switch (agent) {
    AiAgentKind.claudeCode => Icons.auto_awesome_rounded,
    AiAgentKind.openCode => Icons.terminal_rounded,
    AiAgentKind.trae => Icons.architecture_rounded,
    AiAgentKind.qoder => Icons.integration_instructions_rounded,
    AiAgentKind.codex => Icons.hub_outlined,
    AiAgentKind.cursor => Icons.mouse_rounded,
  };
}
