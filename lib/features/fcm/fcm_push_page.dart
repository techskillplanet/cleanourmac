import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/localization_extensions.dart';
import '../../core/widgets/app_page_title.dart';
import '../../data/fcm/fcm_push_client.dart';
import '../../domain/models/fcm_models.dart';
import '../../providers/fcm_providers.dart';

class FcmPushPage extends ConsumerStatefulWidget {
  const FcmPushPage({super.key});

  @override
  ConsumerState<FcmPushPage> createState() => _FcmPushPageState();
}

class _FcmPushPageState extends ConsumerState<FcmPushPage> {
  late final TextEditingController _jsonImportController;
  late final TextEditingController _tokenController;
  late final TextEditingController _batchController;
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _imageController;
  late final TextEditingController _dataController;
  late final TextEditingController _fullJsonController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(fcmPushProvider);
    _jsonImportController = TextEditingController();
    _tokenController = TextEditingController(text: state.deviceToken);
    _batchController = TextEditingController();
    _titleController = TextEditingController(text: state.title);
    _bodyController = TextEditingController(text: state.body);
    _imageController = TextEditingController(text: state.imageUrl);
    _dataController = TextEditingController(text: state.dataJson);
    _fullJsonController = TextEditingController(text: state.fullJson);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fcmPushProvider.notifier).ensureDefaultAccountLoaded();
    });
  }

  @override
  void dispose() {
    _jsonImportController.dispose();
    _tokenController.dispose();
    _batchController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _imageController.dispose();
    _dataController.dispose();
    _fullJsonController.dispose();
    super.dispose();
  }

  void _syncSimpleToProvider() {
    ref
        .read(fcmPushProvider.notifier)
        .updateSimpleFields(
          deviceToken: _tokenController.text,
          title: _titleController.text,
          body: _bodyController.text,
          imageUrl: _imageController.text,
          dataJson: _dataController.text,
        );
  }

  Future<void> _pickFile() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (file == null) return;
    final error = await ref
        .read(fcmPushProvider.notifier)
        .importServiceAccountFile(file.path);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _confirmBatch() async {
    _syncSimpleToProvider();
    ref.read(fcmPushProvider.notifier).updateFullJson(_fullJsonController.text);
    final tokens = FcmPushClient.parseDeviceTokens(_batchController.text);
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.fcmBatchConfirmTitle),
        content: Text(l10n.fcmBatchConfirmBody(tokens.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.fcmSendBatch),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(fcmPushProvider.notifier).sendBatch(_batchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(fcmPushProvider);
    final notifier = ref.read(fcmPushProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: AppPageTitle(
          title: l10n.fcmPush,
          subtitle: l10n.fcmPushSubtitle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(l10n.fcmMemoryOnly),
            ),
          ),
        ],
      ),
      body: state.busy
          ? Center(child: Text(l10n.fcmBusy))
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1100;
                final left = _buildConfigAndMessage(context, state, notifier);
                final right = _buildResultAndHistory(context, state);
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: left),
                            const SizedBox(width: 16),
                            Expanded(flex: 4, child: right),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [left, const SizedBox(height: 16), right],
                        ),
                );
              },
            ),
    );
  }

  Widget _buildConfigAndMessage(
    BuildContext context,
    FcmPushState state,
    FcmPushNotifier notifier,
  ) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FcmCard(
          title: l10n.fcmConfigSection,
          icon: Icons.badge_outlined,
          description: l10n.fcmConfigHint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _jsonImportController,
                minLines: 5,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: l10n.fcmPasteJson,
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      final error = notifier.importServiceAccountJson(
                        _jsonImportController.text,
                      );
                      if (error != null && mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error)));
                      }
                    },
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: Text(l10n.fcmImportJson),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.folder_open_outlined, size: 18),
                    label: Text(l10n.fcmPickFile),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        notifier.ensureDefaultAccountLoaded(force: true),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: Text(l10n.fcmReloadDefault),
                  ),
                  OutlinedButton.icon(
                    onPressed: state.accounts.isEmpty
                        ? null
                        : notifier.clearAccounts,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(l10n.fcmClearAccounts),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state.accounts.isEmpty)
                Text(l10n.fcmNoAccount)
              else
                DropdownButtonFormField<String>(
                  key: ValueKey(state.selectedAccountId),
                  initialValue: state.selectedAccountId,
                  decoration: InputDecoration(labelText: l10n.fcmSelectedProject),
                  items: state.accounts
                      .map(
                        (account) => DropdownMenuItem(
                          value: account.id,
                          child: Text(
                            account.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) notifier.selectAccount(value);
                  },
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: state.selectedAccount == null
                        ? null
                        : notifier.generateAccessToken,
                    icon: const Icon(Icons.key_outlined, size: 18),
                    label: Text(l10n.fcmGenerateToken),
                  ),
                ],
              ),
              if (state.accessTokenPreview != null) ...[
                const SizedBox(height: 8),
                Text('${l10n.fcmTokenPreview}: ${state.accessTokenPreview}'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _FcmCard(
          title: l10n.fcmMessageSection,
          icon: Icons.sms_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<FcmSendMode>(
                segments: [
                  ButtonSegment(
                    value: FcmSendMode.simple,
                    label: Text(l10n.fcmModeSimple),
                  ),
                  ButtonSegment(
                    value: FcmSendMode.fullJson,
                    label: Text(l10n.fcmModeJson),
                  ),
                ],
                selected: {state.mode},
                onSelectionChanged: (values) {
                  notifier.setMode(values.first);
                },
              ),
              const SizedBox(height: 12),
              if (state.mode == FcmSendMode.simple) ...[
                TextField(
                  controller: _tokenController,
                  decoration: InputDecoration(labelText: l10n.fcmDeviceToken),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: l10n.fcmTitle),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _bodyController,
                  decoration: InputDecoration(labelText: l10n.fcmBody),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _imageController,
                  decoration: InputDecoration(labelText: l10n.fcmImageUrl),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _dataController,
                  decoration: InputDecoration(labelText: l10n.fcmDataJson),
                  minLines: 4,
                  maxLines: 8,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ] else
                TextField(
                  controller: _fullJsonController,
                  decoration: InputDecoration(labelText: l10n.fcmFullJson),
                  minLines: 14,
                  maxLines: 24,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: _batchController,
                decoration: InputDecoration(labelText: l10n.fcmBatchTokens),
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      notifier.loadDemoPayload();
                      final s = ref.read(fcmPushProvider);
                      _tokenController.text = s.deviceToken;
                      _titleController.text = s.title;
                      _bodyController.text = s.body;
                      _imageController.text = s.imageUrl;
                      _dataController.text = s.dataJson;
                      _fullJsonController.text = s.fullJson;
                    },
                    icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: Text(l10n.fcmLoadDemo),
                  ),
                  FilledButton.icon(
                    onPressed: state.selectedAccount == null
                        ? null
                        : () async {
                            _syncSimpleToProvider();
                            notifier.updateFullJson(_fullJsonController.text);
                            await notifier.sendSingle();
                          },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(l10n.fcmSend),
                  ),
                  OutlinedButton.icon(
                    onPressed: state.selectedAccount == null
                        ? null
                        : _confirmBatch,
                    icon: const Icon(Icons.outbound_outlined, size: 18),
                    label: Text(l10n.fcmSendBatch),
                  ),
                ],
              ),
              if (state.selectedAccount == null) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.fcmSendDisabledHint,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.fcmCopied)));
  }

  Widget _buildResultAndHistory(BuildContext context, FcmPushState state) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final resultText = [
      if (state.lastResult != null) state.lastResult!,
      if (state.error != null) state.error!,
    ].join('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FcmCard(
          title: l10n.fcmResultSection,
          icon: Icons.receipt_long_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (resultText.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _copyText(resultText),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: Text(l10n.copy),
                  ),
                ),
                SelectableText(
                  resultText,
                  style: TextStyle(
                    color: state.error != null ? cs.error : cs.primary,
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ] else
                Text(l10n.fcmHistoryEmpty),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _FcmCard(
          title: l10n.fcmHistorySection,
          icon: Icons.history_rounded,
          child: state.history.isEmpty
              ? Text(l10n.fcmHistoryEmpty)
              : Column(
                  children: state.history.map((record) {
                    final subtitle = record.success
                        ? (record.messageId ??
                              '${record.batchSuccess}/${record.batchTotal}')
                        : (record.errorSummary ?? 'failed');
                    final line =
                        '${record.at.toLocal()} · ${record.projectId} · ${record.mode.name} · $subtitle';
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        record.success
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: record.success ? cs.primary : cs.error,
                      ),
                      title: SelectableText(
                        '${record.projectId} · ${record.mode.name}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: SelectableText(
                        '${record.at.toLocal()} · $subtitle',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: IconButton(
                        tooltip: l10n.copy,
                        onPressed: () => _copyText(line),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _FcmCard extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final Widget child;

  const _FcmCard({
    required this.title,
    required this.icon,
    required this.child,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(
              description!,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
