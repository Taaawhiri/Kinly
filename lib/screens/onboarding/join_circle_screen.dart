import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../root_shell.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final circle = AppState.instance.joinCircleByCode(_controller.text);
    if (circle == null) {
      setState(() => _error = 'Codice non valido. Chiedi a chi ti ha invitato di controllarlo.');
      return;
    }
    if (widget.isOnboarding) {
      AppState.instance.completeOnboarding();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootShell()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pop(circle);
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
              const Text(
                'Inserisci il codice di invito',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
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
                onPressed: _submit,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                child: const Text('Entra'),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(14)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppTheme.textSecondary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Per la demo prova con uno di questi: FAM-7Q2K, AMI-P91X, LAV-3T5B',
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
