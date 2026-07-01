import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import 'verify_code_screen.dart';

/// Primo schermo che si vede: l'accesso all'account avviene con un codice
/// mandato via email (nessuna password). L'accesso "solo su invito" riguarda
/// le cerchie, non l'account in sé.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Inserisci un indirizzo email valido.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await AuthService.instance.sendOtp(email: email, name: _nameController.text);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => VerifyCodeScreen(email: email)));
    } catch (e) {
      setState(() => _error = 'Non siamo riusciti a inviare il codice. Riprova tra poco.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: Column(
            children: [
              const Spacer(),
              const KinlyLogo(size: 108),
              const SizedBox(height: 28),
              const Text(
                'Kinly',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.5),
              ),
              const SizedBox(height: 10),
              const Text(
                'La tua posizione, solo con chi conta davvero.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15.5, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Il tuo nome',
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                onSubmitted: (_) => _sendCode(),
                decoration: InputDecoration(
                  hintText: 'La tua email',
                  filled: true,
                  fillColor: AppTheme.surface,
                  errorText: _error,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _sending ? null : _sendCode,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                child: _sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Continua con l\'email'),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 15, color: AppTheme.textSecondary.withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Ti mandiamo un codice via email: niente password da ricordare.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withOpacity(0.85), height: 1.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
