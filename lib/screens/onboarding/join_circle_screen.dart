import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../services/kinly_repository.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../premium/paywall_screen.dart';

class JoinCircleScreen extends StatefulWidget {
  const JoinCircleScreen({super.key, this.isOnboarding = true, this.initialCode});

  /// Se true (primo avvio) termina l'onboarding e apre la Home. Se false
  /// (si entra in una nuova cerchia da dentro l'app) torna semplicemente
  /// alla schermata precedente.
  final bool isOnboarding;

  /// Codice già compilato (arriva da un link di invito kinly://join/CODICE).
  final String? initialCode;

  @override
  State<JoinCircleScreen> createState() => _JoinCircleScreenState();
}

class _JoinCircleScreenState extends State<JoinCircleScreen> {
  late final _controller = TextEditingController(text: widget.initialCode ?? '');
  String? _error;
  bool _joining = false;
  bool _limitReached = false;

  /// Formato dei codici invito (es. FAM-7Q2K): usato per riconoscerne uno
  /// negli appunti e proporlo, senza doverlo ridigitare a mano.
  static final _codePattern = RegExp(r'^[A-Z]{1,3}-[0-9A-Z]{4}$');

  @override
  void initState() {
    super.initState();
    if (widget.initialCode == null) unawaited(_prefillFromClipboard());
  }

  Future<void> _prefillFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim().toUpperCase() ?? '';
      if (_codePattern.hasMatch(text) && mounted && _controller.text.isEmpty) {
        setState(() => _controller.text = text);
      }
    } catch (_) {
      // Appunti non leggibili: si digita a mano, come prima.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _joining = true;
      _error = null;
      _limitReached = false;
    });
    try {
      final circle = await AppState.instance.joinCircleByCode(_controller.text);
      if (!mounted) return;
      if (circle == null) {
        setState(() => _error = AppLocalizations.of(context)!.joinCircleInvalidCode);
        return;
      }
      if (widget.isOnboarding) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Navigator.of(context).pop(circle);
      }
    } on FreeLimitException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _limitReached = true;
        _error = e.kind == FreeLimitKind.tooManyCircles ? l10n.circleLimitCirclesMessage : l10n.joinCircleMemberLimitMessage;
      });
    } catch (e) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.joinCircleError);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.joinCircleTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.joinCircleQuestion,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.joinCircleHint,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                autofocus: true,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'FAM-7Q2K',
                  filled: true,
                  fillColor: AppTheme.surface,
                  errorText: _error,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1.2),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _joining ? null : _submit,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                child: _joining
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(l10n.joinCircleSubmit),
              ),
              if (_limitReached) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                  child: Text(l10n.circleMessagesDiscoverPlus),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppTheme.textSecondary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.joinCircleFormatHint,
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
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
