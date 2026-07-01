import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.length < 6) {
      setState(() => _error = 'La password deve avere almeno 6 caratteri.');
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _error = 'Le due password non coincidono.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AuthService.instance.updatePassword(password);
      if (!mounted) return;
      setState(() => _done = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Non siamo riusciti a cambiare la password. Riprova.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambia password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: _done ? _buildDone() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildDone() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentGreen.withOpacity(0.12)),
          alignment: Alignment.center,
          child: const Icon(Icons.check_rounded, color: AppTheme.accentGreen, size: 34),
        ),
        const SizedBox(height: 20),
        Text('Password aggiornata', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Text(
          'D\'ora in poi usa la nuova password per accedere.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Fatto'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nuova password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Text('Almeno 6 caratteri.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5)),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nuova password',
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmController,
          obscureText: true,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'Conferma password',
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppTheme.accentCoral, fontSize: 13)),
        ],
        const Spacer(),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
              : const Text('Salva'),
        ),
      ],
    );
  }
}
