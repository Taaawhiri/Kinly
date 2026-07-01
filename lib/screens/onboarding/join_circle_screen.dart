import 'package:flutter/material.dart';
import '../../services/kinly_repository.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../premium/paywall_screen.dart';

class JoinCircleScreen extends StatefulWidget {
  const JoinCircleScreen({super.key, this.isOnboarding = true});

  /// Se true (primo avvio) termina l'onboarding e apre la Home. Se false
  /// (si entra in una nuova cerchia da dentro l'app) torna semplicemente
  /// alla schermata precedente.
  final bool isOnboarding;

  @override
  State<JoinCircleScreen> createState() => _JoinCircleScreenState();
}

class _JoinCircleScreenState extends State<JoinCircleScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _joining = false;
  bool _limitReached = false;

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
        setState(() => _error = 'Codice non valido. Chiedi a chi ti ha invitato di controllarlo.');
        return;
      }
      if (widget.isOnboarding) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Navigator.of(context).pop(circle);
      }
    } on FreeLimitException catch (e) {
      if (!mounted) return;
      setState(() {
        _limitReached = true;
        _error = e.kind == FreeLimitKind.tooManyCircles
            ? 'Nel piano gratuito puoi far parte di massimo 2 cerchie. Passa a Kinly+ per non avere limiti.'
            : 'Questa cerchia ha già raggiunto il limite di 6 persone del piano gratuito.';
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Non siamo riusciti a verificare il codice. Riprova.');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entra in una cerchia')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inserisci il codice di invito',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Te lo manda chi ha creato la cerchia, ad esempio via messaggio.',
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
                    : const Text('Entra'),
              ),
              if (_limitReached) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                  child: const Text('Scopri Kinly+'),
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
                        'Chiedi il codice a chi ha creato la cerchia: ha il formato XXX-0000.',
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
