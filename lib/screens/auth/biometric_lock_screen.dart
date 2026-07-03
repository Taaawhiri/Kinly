import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/biometric_lock_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';

/// Schermata di blocco mostrata all'avvio quando l'utente ha attivato
/// l'accesso biometrico dal profilo (Privacy e sicurezza).
class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key, required this.onUnlocked});
  final VoidCallback onUnlocked;

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _authenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryUnlock());
  }

  Future<void> _tryUnlock() async {
    setState(() {
      _authenticating = true;
      _error = null;
    });
    final ok = await BiometricLockService.instance.authenticate();
    if (!mounted) return;
    setState(() => _authenticating = false);
    if (ok) {
      widget.onUnlocked();
    } else {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.privacyBiometricAuthFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const KinlyLogo(size: 72),
                const SizedBox(height: 24),
                Text(l10n.biometricLockedTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  l10n.biometricLockedMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.4),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppTheme.accentCoral, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                if (_authenticating)
                  const CircularProgressIndicator()
                else
                  FilledButton.icon(
                    onPressed: _tryUnlock,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: Text(l10n.biometricUnlockButton),
                    style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
