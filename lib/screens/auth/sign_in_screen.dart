import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';

/// Primo schermo che si vede: si crea un account o si accede con email e
/// password. L'accesso "solo su invito" riguarda le cerchie, non l'account.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = true;
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Inserisci un indirizzo email valido.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'La password deve avere almeno 6 caratteri.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      if (_isSignUp) {
        final response = await AuthService.instance.signUp(email: email, password: password, name: _nameController.text);
        if (response.session == null && mounted) {
          setState(() => _info = 'Account creato: controlla la tua email per confermarlo prima di accedere.');
        }
      } else {
        await AuthService.instance.signIn(email: email, password: password);
      }
      // Se la sessione è attiva, l'AuthGate alla radice se ne accorge da
      // solo e mostra la schermata giusta: non serve navigare esplicitamente.
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Qualcosa è andato storto. Riprova.\n$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const KinlyLogo(size: 96),
              const SizedBox(height: 24),
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
              const SizedBox(height: 28),
              _ModeToggle(
                isSignUp: _isSignUp,
                onChanged: (value) => setState(() {
                  _isSignUp = value;
                  _error = null;
                  _info = null;
                }),
              ),
              const SizedBox(height: 20),
              if (_isSignUp) ...[
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
              ],
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  hintText: 'La tua email',
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                autofillHints: [_isSignUp ? AutofillHints.newPassword : AutofillHints.password],
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: AppTheme.surface,
                  errorText: _error,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              if (_info != null) ...[
                const SizedBox(height: 12),
                Text(_info!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.accentGreen, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : Text(_isSignUp ? 'Crea account' : 'Accedi'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 15, color: AppTheme.textSecondary.withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Nessuno vede la tua posizione senza il tuo permesso.',
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

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.isSignUp, required this.onChanged});
  final bool isSignUp;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(child: _ToggleButton(label: 'Crea account', selected: isSignUp, onTap: () => onChanged(true))),
          Expanded(child: _ToggleButton(label: 'Accedi', selected: !isSignUp, onTap: () => onChanged(false))),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: selected ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
