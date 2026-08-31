import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/infra_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Scan Thresholds', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _SliderTile(
            label: 'Large file threshold',
            value: settings.largeFileThresholdMB.toDouble(),
            min: 50,
            max: 1000,
            divisions: 19,
            format: (v) => '${v.round()} MB',
            onChanged: (v) => notifier.update(settings.copyWith(largeFileThresholdMB: v.round())),
          ),
          const SizedBox(height: 16),
          _SliderTile(
            label: 'Simulator stale threshold',
            value: settings.simulatorStaleDays.toDouble(),
            min: 7,
            max: 180,
            divisions: 24,
            format: (v) => '${v.round()} days',
            onChanged: (v) => notifier.update(settings.copyWith(simulatorStaleDays: v.round())),
          ),
          const SizedBox(height: 32),
          Text('Excluded Paths', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'These paths are never deleted, even if selected.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          _ExclusionList(
            paths: settings.excludedPaths,
            onAdd: (path) => notifier.update(
                settings.copyWith(excludedPaths: [...settings.excludedPaths, path])),
            onRemove: (path) => notifier.update(settings.copyWith(
                excludedPaths: settings.excludedPaths.where((p) => p != path).toList())),
          ),
          const SizedBox(height: 32),
          Text('Node Modules Roots', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Folders scanned for node_modules. Leave empty to scan your home directory.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          _ExclusionList(
            paths: settings.nodeModulesRoots,
            onAdd: (path) => notifier.update(
                settings.copyWith(nodeModulesRoots: [...settings.nodeModulesRoots, path])),
            onRemove: (path) => notifier.update(settings.copyWith(
                nodeModulesRoots:
                    settings.nodeModulesRoots.where((p) => p != path).toList())),
          ),
        ],
      ),
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
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(format(value), style: const TextStyle(fontWeight: FontWeight.w700)),
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
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const _ExclusionList({required this.paths, required this.onAdd, required this.onRemove});

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
                decoration: const InputDecoration(
                  hintText: 'e.g. /Users/you/projects/my-app',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        ...widget.paths.map((p) => ListTile(
              dense: true,
              title: Text(p, style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                onPressed: () => widget.onRemove(p),
              ),
            )),
      ],
    );
  }
}
