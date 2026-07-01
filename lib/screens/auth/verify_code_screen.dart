import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// Inserimento del codice a 6 cifre ricevuto via email.
class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key, required this.email});
  final String email;

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _codeController = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await AuthService.instance.verifyOtp(email: widget.email, token: code);
      if (!mounted) return;
      // L'AuthGate alla radice reagisce al cambio di sessione e mostra la
      // schermata giusta: basta tornare in cima allo stack di navigazione.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Codice non valido o scaduto. Riprova.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await AuthService.instance.sendOtp(email: widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Codice inviato di nuovo')));
      }
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controlla la tua email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Abbiamo mandato un codice a ${widget.email}',
                style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                autofocus: true,
                onSubmitted: (_) => _verify(),
                decoration: InputDecoration(
                  hintText: '123456',
                  filled: true,
                  fillColor: AppTheme.surface,
                  errorText: _error,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 4),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _verifying ? null : _verify,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                child: _verifying
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Verifica'),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _resending ? null : _resend,
                  child: Text(_resending ? 'Invio...' : 'Non ho ricevuto il codice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
