import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/localization_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_page_title.dart';
import '../../data/jwt/jwt_defaults.dart';
import '../../data/jwt/jwt_service.dart';

class JwtPage extends StatefulWidget {
  const JwtPage({super.key});

  @override
  State<JwtPage> createState() => _JwtPageState();
}

class _JwtPageState extends State<JwtPage> {
  late final TextEditingController _headerController;
  late final TextEditingController _payloadController;
  late final TextEditingController _privateKeyController;
  late final TextEditingController _publicKeyController;
  late final TextEditingController _jwtController;
  final _service = JwtService();

  String _algorithm = 'RS256';
  _JwtMessage? _timeMessage;
  _JwtMessage? _verifyMessage;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _headerController = TextEditingController(text: JwtDefaults.headerJson);
    _payloadController = TextEditingController(text: JwtDefaults.payloadJson);
    _privateKeyController = TextEditingController(text: JwtDefaults.privateKey);
    _publicKeyController = TextEditingController(text: JwtDefaults.publicKey);
    _jwtController = TextEditingController();
    _jwtController.addListener(_handleTokenChanged);
  }

  @override
  void dispose() {
    _headerController.dispose();
    _payloadController.dispose();
    _privateKeyController.dispose();
    _publicKeyController.dispose();
    _jwtController.removeListener(_handleTokenChanged);
    _jwtController.dispose();
    super.dispose();
  }

  void _handleTokenChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: AppPageTitle(
          title: l10n.jwtTools,
          subtitle: l10n.jwtToolsSubtitle,
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
              label: Text(l10n.jwtLocalOnly),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1080;
          final content = [
            _buildInputColumn(context),
            _buildOutputColumn(context),
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: content[0]),
                      const SizedBox(width: 16),
                      Expanded(child: content[1]),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: content,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildInputColumn(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _JwtCard(
          title: l10n.jwtHeader,
          icon: Icons.data_object_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _algorithm,
                decoration: InputDecoration(
                  labelText: l10n.jwtAlgorithm,
                  prefixIcon: const Icon(Icons.tune_rounded),
                ),
                items:
                    const [
                      'RS256',
                      'RS384',
                      'RS512',
                      'HS256',
                      'HS384',
                      'HS512',
                    ].map((value) {
                      return DropdownMenuItem(value: value, child: Text(value));
                    }).toList(),
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _algorithm = value);
                        _setHeaderAlgorithm(value);
                      },
              ),
              const SizedBox(height: 12),
              _jsonField(
                controller: _headerController,
                label: l10n.jwtHeaderJson,
                minLines: 4,
                maxLines: 7,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _JwtCard(
          title: l10n.jwtPayload,
          icon: Icons.subject_rounded,
          child: _jsonField(
            controller: _payloadController,
            label: l10n.jwtPayloadJson,
            minLines: 12,
            maxLines: 18,
          ),
        ),
        const SizedBox(height: 14),
        _JwtCard(
          title: l10n.jwtPrivateKey,
          icon: Icons.key_rounded,
          description: l10n.jwtPrivateKeyHint,
          child: _keyField(_privateKeyController, l10n.jwtPrivateKey),
        ),
        const SizedBox(height: 14),
        _JwtCard(
          title: l10n.jwtPublicKey,
          icon: Icons.vpn_key_outlined,
          description: l10n.jwtPublicKeyHint,
          child: _keyField(_publicKeyController, l10n.jwtPublicKey),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : _generate,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(l10n.jwtGenerate),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _refreshTime,
              icon: const Icon(Icons.schedule_rounded, size: 18),
              label: Text(l10n.jwtRefreshTime),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _verify,
              icon: const Icon(Icons.verified_outlined, size: 18),
              label: Text(l10n.jwtVerify),
            ),
          ],
        ),
        if (_timeMessage != null) ...[
          const SizedBox(height: 14),
          _MessagePanel(message: _timeMessage!),
        ],
      ],
    );
  }

  Widget _buildOutputColumn(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _JwtCard(
          title: l10n.jwtOutput,
          icon: Icons.token_rounded,
          trailing: IconButton(
            tooltip: l10n.copy,
            onPressed: _jwtController.text.trim().isEmpty ? null : _copyJwt,
            icon: const Icon(Icons.copy_rounded),
          ),
          child: TextField(
            controller: _jwtController,
            minLines: 12,
            maxLines: 20,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.45,
            ),
            decoration: InputDecoration(
              hintText: l10n.jwtOutputPlaceholder,
              suffixIcon: _jwtController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.copy,
                      onPressed: _copyJwt,
                      icon: const Icon(Icons.content_copy_rounded),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_verifyMessage != null)
          _MessagePanel(message: _verifyMessage!)
        else
          _JwtCard(
            title: l10n.jwtVerify,
            icon: Icons.fact_check_outlined,
            child: Text(
              l10n.jwtVerifyHint,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 14),
        _JwtCard(
          title: l10n.jwtSafetyTitle,
          icon: Icons.shield_outlined,
          child: Text(
            l10n.jwtSafetyDescription,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _jsonField({
    required TextEditingController controller,
    required String label,
    required int minLines,
    required int maxLines,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _keyField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      minLines: 6,
      maxLines: 14,
      keyboardType: TextInputType.multiline,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        hintText: '-----BEGIN ... KEY-----',
      ),
    );
  }

  Future<void> _generate() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final header = _readObject(_headerController.text, l10n.jwtHeader);
      final payload = _readJson(_payloadController.text, l10n.jwtPayload);
      final algorithm = ((header['alg'] as String?) ?? _algorithm)
          .toUpperCase();
      final key = _privateKeyController.text.trim();
      if (!algorithm.startsWith('HS') && key.isEmpty) {
        throw StateError(l10n.jwtPrivateKeyRequired);
      }
      final timeMessage = _checkTime(payload);
      final token = await _service.sign(
        algorithm: algorithm,
        header: header,
        payload: payload,
        key: key,
      );
      if (!mounted) return;
      setState(() {
        _jwtController.text = token;
        _algorithm = algorithm;
        _timeMessage = timeMessage;
        _verifyMessage = null;
      });
    } catch (error) {
      if (mounted) _showError(l10n.jwtGenerateFailed, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _refreshTime() {
    final l10n = context.l10n;
    try {
      final payload = _readObject(_payloadController.text, l10n.jwtPayload);
      final iat = DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60;
      final exp = iat + 3600 * 24 * 30;
      final jti =
          '${DateTime.now().millisecondsSinceEpoch}${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
      payload['iat'] = iat;
      payload['exp'] = exp;
      payload['jti'] = jti;
      _payloadController.text = const JsonEncoder.withIndent(
        '  ',
      ).convert(payload);
      setState(
        () => _timeMessage = _JwtMessage(
          l10n.jwtTimeRefreshed(
            _formatTimestamp(iat),
            _formatTimestamp(exp),
            jti,
          ),
          _JwtMessageKind.success,
        ),
      );
    } catch (error) {
      _showError(l10n.jwtRefreshFailed, error);
    }
  }

  Future<void> _verify() async {
    final l10n = context.l10n;
    final token = _jwtController.text.trim();
    if (token.isEmpty) {
      setState(
        () => _verifyMessage = _JwtMessage(
          l10n.jwtMissingToken,
          _JwtMessageKind.warning,
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw const FormatException('Invalid JWT');
      final header =
          jsonDecode(utf8.decode(_decodeBase64(parts[0])))
              as Map<String, dynamic>;
      final tokenAlgorithm = (header['alg'] as String? ?? '').toUpperCase();
      if (tokenAlgorithm != _algorithm) {
        throw StateError(
          '${l10n.jwtAlgorithm}: $tokenAlgorithm != $_algorithm',
        );
      }
      final key = _algorithm.startsWith('HS')
          ? _privateKeyController.text.trim()
          : _publicKeyController.text.trim();
      if (key.isEmpty) {
        throw StateError(
          _algorithm.startsWith('HS')
              ? l10n.jwtPrivateKeyRequired
              : l10n.jwtPublicKeyRequired,
        );
      }
      final result = await _service.verify(
        token: token,
        key: key,
        acceptedAlgorithms: [_algorithm],
      );
      if (!mounted) return;
      final payload = result.payload is Map<String, dynamic>
          ? result.payload as Map<String, dynamic>
          : const <String, dynamic>{};
      final exp = _asInt(payload['exp']);
      final text = [
        '${l10n.jwtSignature}: ${result.signatureValid ? l10n.jwtPassed : l10n.jwtFailed}',
        if (exp != null) '${l10n.jwtExpires}: ${_formatTimestamp(exp)}',
        if (result.expirationValid == false) l10n.jwtExpired,
        if (result.notBeforeValid == false) l10n.jwtNotYetValid,
        if (result.issuedAtValid == false) l10n.jwtFutureIat,
      ].join('\n');
      setState(
        () => _verifyMessage = _JwtMessage(
          result.error == null ? text : '${result.error}\n$text',
          result.tokenValid == true
              ? _JwtMessageKind.success
              : _JwtMessageKind.error,
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _verifyMessage = _JwtMessage(
            '${l10n.jwtVerifyFailed}: $error',
            _JwtMessageKind.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setHeaderAlgorithm(String value) {
    try {
      final header = _readObject(
        _headerController.text,
        context.l10n.jwtHeader,
      );
      header['alg'] = value;
      _headerController.text = const JsonEncoder.withIndent(
        '  ',
      ).convert(header);
    } catch (_) {
      // The next generate action reports malformed JSON with a useful label.
    }
  }

  Map<String, dynamic> _readObject(String value, String label) {
    final result = _readJson(value, label);
    if (result is! Map<String, dynamic>) {
      throw FormatException('$label must be a JSON object');
    }
    return result;
  }

  dynamic _readJson(String value, String label) {
    try {
      return jsonDecode(value);
    } catch (error) {
      throw FormatException('$label JSON is invalid: $error');
    }
  }

  _JwtMessage _checkTime(dynamic payload) {
    final l10n = context.l10n;
    if (payload is! Map<String, dynamic>) {
      return _JwtMessage(l10n.jwtTimeSkipped, _JwtMessageKind.warning);
    }
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final iat = _asInt(payload['iat']);
    final exp = _asInt(payload['exp']);
    final lines = <String>[];
    var valid = true;
    if (iat == null) {
      lines.add(l10n.jwtMissingIat);
    } else if (iat > now + 60) {
      lines.add('${l10n.jwtFutureIat}: ${_formatTimestamp(iat)}');
      valid = false;
    } else {
      lines.add('${l10n.jwtValidIat}: ${_formatTimestamp(iat)}');
    }
    if (exp == null) {
      lines.add(l10n.jwtMissingExp);
    } else if (exp < now) {
      lines.add('${l10n.jwtExpired}: ${_formatTimestamp(exp)}');
      valid = false;
    } else {
      lines.add('${l10n.jwtValidExp}: ${_formatTimestamp(exp)}');
    }
    return _JwtMessage(
      lines.join('\n'),
      valid ? _JwtMessageKind.success : _JwtMessageKind.error,
    );
  }

  Future<void> _copyJwt() async {
    await Clipboard.setData(ClipboardData(text: _jwtController.text));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.jwtCopied)));
    }
  }

  void _showError(String title, Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title: $error')));
  }

  String _formatTimestamp(int value) {
    final date = DateTime.fromMillisecondsSinceEpoch(value * 1000).toLocal();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')} ($value)';
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  List<int> _decodeBase64(String value) {
    final normalized = value.replaceAll('-', '+').replaceAll('_', '/');
    final padded = '$normalized${'=' * ((4 - normalized.length % 4) % 4)}';
    return base64.decode(padded);
  }
}

class _JwtCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? description;
  final Widget? trailing;
  final Widget child;

  const _JwtCard({
    required this.title,
    required this.icon,
    required this.child,
    this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ?trailing,
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 5),
              Text(
                description!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  final _JwtMessage message;

  const _MessagePanel({required this.message});

  @override
  Widget build(BuildContext context) {
    final color = switch (message.kind) {
      _JwtMessageKind.success => AppPalette.successFor(context),
      _JwtMessageKind.warning => AppPalette.warningFor(context),
      _JwtMessageKind.error => AppPalette.dangerFor(context),
    };
    final icon = switch (message.kind) {
      _JwtMessageKind.success => Icons.check_circle_outline_rounded,
      _JwtMessageKind.warning => Icons.warning_amber_rounded,
      _JwtMessageKind.error => Icons.error_outline_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message.text,
              style: TextStyle(color: color, height: 1.5, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

enum _JwtMessageKind { success, warning, error }

class _JwtMessage {
  final String text;
  final _JwtMessageKind kind;

  const _JwtMessage(this.text, this.kind);
}
