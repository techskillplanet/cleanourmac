import 'package:flutter/material.dart';

import '../../core/l10n/localization_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/android_emulator_config.dart';

Future<Set<String>?> showAndroidEmulatorConfigCheckDialog(
  BuildContext context,
  AndroidEmulatorConfigReport report,
) {
  final selectedIds = report.repairableIssues.map((issue) => issue.id).toSet();
  return showDialog<Set<String>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final allSelected =
            report.repairableIssues.isNotEmpty &&
            report.repairableIssues.every(
              (issue) => selectedIds.contains(issue.id),
            );
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DialogHeader(
                    title: context.l10n.emulatorConfigCheckTitle,
                    subtitle: context.l10n.emulatorConfigCheckSubtitle,
                    icon: Icons.health_and_safety_outlined,
                  ),
                  const SizedBox(height: 16),
                  _SafetyNote(text: context.l10n.emulatorConfigSafetyNote),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.emulatorConfigSummary(
                      report.avdCount,
                      report.issues.length,
                      report.repairableCount,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (report.avdCount == 0 && report.issues.isEmpty)
                    Expanded(
                      child: _EmptyResult(
                        icon: Icons.phone_android_rounded,
                        title: context.l10n.emulatorConfigNoAvds,
                        description:
                            context.l10n.emulatorConfigNoAvdsDescription,
                      ),
                    )
                  else if (report.isHealthy)
                    Expanded(
                      child: _EmptyResult(
                        icon: Icons.verified_rounded,
                        title: context.l10n.emulatorConfigHealthy,
                        description:
                            context.l10n.emulatorConfigHealthyDescription,
                        success: true,
                      ),
                    )
                  else ...[
                    if (report.repairableIssues.isNotEmpty)
                      CheckboxListTile(
                        value: allSelected,
                        onChanged: (selected) {
                          setDialogState(() {
                            if (selected == true) {
                              selectedIds.addAll(
                                report.repairableIssues.map(
                                  (issue) => issue.id,
                                ),
                              );
                            } else {
                              selectedIds.clear();
                            }
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(context.l10n.selectAllRepairable),
                      ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: report.issues.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final issue = report.issues[index];
                          return _IssueTile(
                            issue: issue,
                            selected: selectedIds.contains(issue.id),
                            onSelected: issue.repairable
                                ? (selected) {
                                    setDialogState(() {
                                      if (selected) {
                                        selectedIds.add(issue.id);
                                      } else {
                                        selectedIds.remove(issue.id);
                                      }
                                    });
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(context.l10n.dismiss),
                      ),
                      if (!report.isHealthy &&
                          report.repairableIssues.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: selectedIds.isEmpty
                              ? null
                              : () => Navigator.pop(
                                  dialogContext,
                                  Set.unmodifiable(selectedIds),
                                ),
                          icon: const Icon(Icons.build_circle_outlined),
                          label: Text(
                            context.l10n.repairSelectedIssues(
                              selectedIds.length,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> showAndroidEmulatorConfigRepairResult(
  BuildContext context,
  AndroidEmulatorConfigRepairResult result,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.task_alt_rounded, color: AppPalette.successFor(context)),
          const SizedBox(width: 10),
          Expanded(child: Text(context.l10n.emulatorConfigRepairComplete)),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.emulatorConfigRepairSummary(
                result.repairedCount,
                result.report.issues.length,
              ),
            ),
            if (result.skippedCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.emulatorConfigRepairSkipped(result.skippedCount),
              ),
            ],
            if (result.backupDirectory != null) ...[
              const SizedBox(height: 12),
              _ResultNote(
                icon: Icons.inventory_2_outlined,
                text: context.l10n.emulatorConfigBackupSaved(
                  result.backupDirectory!,
                ),
                monospace: true,
              ),
            ],
            if (result.restartRequiredAvds.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ResultNote(
                icon: Icons.restart_alt_rounded,
                text: context.l10n.restartRequiredAvds(
                  result.restartRequiredAvds.join(', '),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(context.l10n.dismiss),
        ),
      ],
    ),
  );
}

class _DialogHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _DialogHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SafetyNote extends StatelessWidget {
  final String text;

  const _SafetyNote({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppPalette.successFor(context).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppPalette.successFor(context).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 18,
            color: AppPalette.successFor(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool success;

  const _EmptyResult({
    required this.icon,
    required this.title,
    required this.description,
    this.success = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = success
        ? AppPalette.successFor(context)
        : cs.onSurfaceVariant;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _IssueTile extends StatelessWidget {
  final AndroidEmulatorConfigIssue issue;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  const _IssueTile({
    required this.issue,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final error = issue.severity == AndroidEmulatorConfigIssueSeverity.error;
    final color = error
        ? AppPalette.dangerFor(context)
        : AppPalette.warningFor(context);
    final copy = _issueCopy(context, issue);

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onSelected == null ? null : () => onSelected!(!selected),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onSelected != null)
                Checkbox(
                  value: selected,
                  onChanged: (value) => onSelected!(value == true),
                  visualDensity: VisualDensity.compact,
                )
              else
                Padding(
                  padding: const EdgeInsets.all(9),
                  child: Icon(
                    Icons.report_problem_outlined,
                    color: color,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            copy.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _Tag(
                          text: issue.repairable
                              ? context.l10n.repairableIssue
                              : context.l10n.manualActionRequired,
                          color: issue.repairable
                              ? AppPalette.successFor(context)
                              : color,
                        ),
                        if (issue.requiresRestart) ...[
                          const SizedBox(width: 6),
                          _Tag(
                            text: context.l10n.restartRequired,
                            color: AppPalette.warningFor(context),
                          ),
                        ],
                      ],
                    ),
                    if (issue.avdName.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        issue.avdName,
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      copy.description,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    if (issue.currentValue != null) ...[
                      const SizedBox(height: 6),
                      _MonoText(
                        context.l10n.currentConfigValue(issue.currentValue!),
                      ),
                    ],
                    if (issue.suggestedValue != null) ...[
                      const SizedBox(height: 3),
                      _MonoText(
                        context.l10n.suggestedConfigValue(
                          issue.suggestedValue!,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MonoText extends StatelessWidget {
  final String text;

  const _MonoText(this.text);

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontFamily: 'monospace',
        fontSize: 9.5,
      ),
    );
  }
}

class _ResultNote extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool monospace;

  const _ResultNote({
    required this.icon,
    required this.text,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              text,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 11,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

({String title, String description}) _issueCopy(
  BuildContext context,
  AndroidEmulatorConfigIssue issue,
) {
  return switch (issue.kind) {
    AndroidEmulatorConfigIssueKind.avdHomeMissing => (
      title: context.l10n.avdHomeMissingIssue,
      description: context.l10n.avdHomeMissingDescription(
        issue.path.isEmpty ? '~/.android/avd' : issue.path,
      ),
    ),
    AndroidEmulatorConfigIssueKind.descriptorMissing => (
      title: context.l10n.avdDescriptorMissingIssue,
      description: context.l10n.avdDescriptorMissingDescription(issue.avdName),
    ),
    AndroidEmulatorConfigIssueKind.descriptorPathMismatch => (
      title: context.l10n.avdDescriptorPathIssue,
      description: context.l10n.avdDescriptorPathDescription(issue.avdName),
    ),
    AndroidEmulatorConfigIssueKind.avdDirectoryMissing => (
      title: context.l10n.avdDirectoryMissingIssue,
      description: context.l10n.avdDirectoryMissingDescription(
        issue.avdName,
        issue.path,
      ),
    ),
    AndroidEmulatorConfigIssueKind.configMissing => (
      title: context.l10n.avdConfigMissingIssue,
      description: context.l10n.avdConfigMissingDescription(
        issue.avdName,
        issue.path,
      ),
    ),
    AndroidEmulatorConfigIssueKind.systemImagePathMissing => (
      title: context.l10n.systemImagePathMissingIssue,
      description: context.l10n.systemImagePathMissingDescription(
        issue.avdName,
      ),
    ),
    AndroidEmulatorConfigIssueKind.systemImageMissing => (
      title: context.l10n.systemImageMissingIssue,
      description: context.l10n.systemImageMissingDescription(
        issue.avdName,
        issue.path,
      ),
    ),
    AndroidEmulatorConfigIssueKind.systemImagePathMismatch => (
      title: context.l10n.systemImagePathIssue,
      description: context.l10n.systemImagePathDescription(issue.avdName),
    ),
    AndroidEmulatorConfigIssueKind.hardwareKeyboardDisabled => (
      title: context.l10n.hardwareKeyboardIssue,
      description: context.l10n.hardwareKeyboardIssueDescription(issue.avdName),
    ),
    AndroidEmulatorConfigIssueKind.staleLockFiles => (
      title: context.l10n.staleLockIssue,
      description: context.l10n.staleLockDescription(
        issue.relatedPaths.length,
        issue.avdName,
      ),
    ),
  };
}
