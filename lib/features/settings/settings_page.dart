import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/localization_extensions.dart';
import '../../core/widgets/app_page_title.dart';
import '../../core/widgets/react_native_icon.dart';
import '../../providers/infra_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: AppPageTitle(
          title: l10n.settings,
          subtitle: l10n.settingsSubtitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    icon: Icons.translate_rounded,
                    title: l10n.language,
                    description: l10n.languageDescription,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'zh',
                          label: Text(l10n.languageChinese),
                          icon: const Icon(Icons.translate_rounded),
                        ),
                        ButtonSegment(
                          value: 'en',
                          label: Text(l10n.languageEnglish),
                          icon: const Icon(Icons.language_rounded),
                        ),
                      ],
                      selected: {settings.localeCode},
                      onSelectionChanged: (selection) => notifier.update(
                        settings.copyWith(localeCode: selection.first),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _SectionTitle(icon: Icons.tune_rounded, title: l10n.scanThresholds),
          const SizedBox(height: 16),
          _SliderTile(
            label: l10n.largeFileThreshold,
            value: settings.largeFileThresholdMB.toDouble(),
            min: 50,
            max: 1000,
            divisions: 19,
            format: (v) => '${v.round()} MB',
            onChanged: (v) => notifier.update(
              settings.copyWith(largeFileThresholdMB: v.round()),
            ),
          ),
          const SizedBox(height: 16),
          _SliderTile(
            label: l10n.simulatorStaleThreshold,
            value: settings.simulatorStaleDays.toDouble(),
            min: 7,
            max: 180,
            divisions: 24,
            format: (v) => l10n.days(v.round()),
            onChanged: (v) => notifier.update(
              settings.copyWith(simulatorStaleDays: v.round()),
            ),
          ),
          const SizedBox(height: 16),
          _SliderTile(
            label: l10n.metroPort,
            value: settings.metroPort.toDouble(),
            min: 8081,
            max: 8099,
            divisions: 18,
            format: (v) => v.round().toString(),
            onChanged: (v) =>
                notifier.update(settings.copyWith(metroPort: v.round())),
          ),
          const SizedBox(height: 32),
          _SectionTitle(
            icon: Icons.shield_outlined,
            title: l10n.excludedPaths,
            description: l10n.excludedPathsDescription,
          ),
          const SizedBox(height: 12),
          _ExclusionList(
            paths: settings.excludedPaths,
            hintText: l10n.pathExample,
            onAdd: (path) => notifier.update(
              settings.copyWith(
                excludedPaths: [...settings.excludedPaths, path],
              ),
            ),
            onRemove: (path) => notifier.update(
              settings.copyWith(
                excludedPaths: settings.excludedPaths
                    .where((p) => p != path)
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _SectionTitle(
            icon: Icons.account_tree_outlined,
            title: l10n.nodeModulesRoots,
            description: l10n.nodeModulesRootsDescription,
          ),
          const SizedBox(height: 12),
          _ExclusionList(
            paths: settings.nodeModulesRoots,
            hintText: l10n.pathExample,
            onAdd: (path) => notifier.update(
              settings.copyWith(
                nodeModulesRoots: [...settings.nodeModulesRoots, path],
              ),
            ),
            onRemove: (path) => notifier.update(
              settings.copyWith(
                nodeModulesRoots: settings.nodeModulesRoots
                    .where((p) => p != path)
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _SectionTitle(
            customIcon: const ReactNativeIcon(size: 18),
            title: l10n.rnProjectRoots,
            description: l10n.rnProjectRootsDescription,
          ),
          const SizedBox(height: 12),
          _ExclusionList(
            paths: settings.reactNativeRoots,
            hintText: l10n.pathExample,
            onAdd: (path) => notifier.update(
              settings.copyWith(
                reactNativeRoots: [...settings.reactNativeRoots, path],
              ),
            ),
            onRemove: (path) => notifier.update(
              settings.copyWith(
                reactNativeRoots: settings.reactNativeRoots
                    .where((item) => item != path)
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _SectionTitle(
            icon: Icons.folder_special_outlined,
            title: l10n.developmentRoots,
            description: l10n.developmentRootsDescription,
          ),
          const SizedBox(height: 12),
          _ExclusionList(
            paths: settings.developmentRoots,
            hintText: l10n.pathExample,
            onAdd: (path) => notifier.update(
              settings.copyWith(
                developmentRoots: [...settings.developmentRoots, path],
              ),
            ),
            onRemove: (path) => notifier.update(
              settings.copyWith(
                developmentRoots: settings.developmentRoots
                    .where((item) => item != path)
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData? icon;
  final Widget? customIcon;
  final String title;
  final String? description;

  const _SectionTitle({
    this.icon,
    this.customIcon,
    required this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: customIcon ?? Icon(icon, color: cs.primary, size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (description != null) ...[
                const SizedBox(height: 3),
                Text(
                  description!,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Text(
                  format(value),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExclusionList extends StatefulWidget {
  final List<String> paths;
  final String hintText;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const _ExclusionList({
    required this.paths,
    required this.hintText,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_ExclusionList> createState() => _ExclusionListState();
}

class _ExclusionListState extends State<_ExclusionList> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    widget.onAdd(v.trim());
                    _ctrl.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () {
                if (_ctrl.text.trim().isNotEmpty) {
                  widget.onAdd(_ctrl.text.trim());
                  _ctrl.clear();
                }
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.paths.map(
          (p) => ListTile(
            dense: true,
            title: Text(
              p,
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 18),
              onPressed: () => widget.onRemove(p),
            ),
          ),
        ),
      ],
    );
  }
}
