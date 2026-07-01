import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_lock_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'change_password_screen.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  int _speedThreshold = AppState.instance.me.speedAlertKmh ?? 130;
  bool _signingOutOthers = false;

  bool _biometricSupported = false;
  bool _biometricEnabled = false;
  bool _biometricLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBiometric());
  }

  Future<void> _loadBiometric() async {
    final supported = await BiometricLockService.instance.isDeviceSupported();
    final enabled = await BiometricLockService.instance.isEnabled();
    if (mounted) {
      setState(() {
        _biometricSupported = supported;
        _biometricEnabled = enabled;
        _biometricLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final confirmed = await BiometricLockService.instance.authenticate();
      if (!confirmed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non siamo riusciti a verificare la tua identità.')));
        }
        return;
      }
    }
    await BiometricLockService.instance.setEnabled(value);
    if (mounted) setState(() => _biometricEnabled = value);
  }

  Future<void> _signOutOthers() async {
    setState(() => _signingOutOthers = true);
    try {
      await AuthService.instance.signOutOtherSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tutti gli altri dispositivi sono stati disconnessi.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non siamo riusciti a completare l\'operazione. Riprova.')));
      }
    } finally {
      if (mounted) setState(() => _signingOutOthers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final speedAlertEnabled = AppState.instance.me.speedAlertKmh != null;
        return Scaffold(
          appBar: AppBar(title: const Text('Privacy e sicurezza')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.textSecondary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'La tua posizione è visibile solo a chi fa parte di una tua cerchia, e solo secondo la modalità di condivisione che scegli dal profilo (automatica, su richiesta o sospesa).',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.lock_outline_rounded,
                  label: 'Cambia password',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.phonelink_erase_outlined,
                  label: 'Esci dagli altri dispositivi',
                  loading: _signingOutOthers,
                  onTap: _signingOutOthers ? null : _signOutOthers,
                ),
                if (!_biometricLoading && _biometricSupported) ...[
                  const SizedBox(height: 24),
                  Text('Accesso biometrico', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  Text(
                    'Richiedi impronta, volto o codice del dispositivo ogni volta che apri Kinly.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Sblocco biometrico', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
                        ),
                        Switch(value: _biometricEnabled, onChanged: _toggleBiometric),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text('Avviso di velocità', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  'Imposta una tua soglia: chi ha Kinly+ nella tua cerchia riceve un avviso se la superi guidando.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Attiva avviso', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
                          ),
                          Switch(
                            value: speedAlertEnabled,
                            onChanged: (enabled) => AppState.instance.setSpeedAlert(enabled ? _speedThreshold : null),
                          ),
                        ],
                      ),
                      if (speedAlertEnabled) ...[
                        const Divider(height: 24),
                        Row(
                          children: [
                            Text('Soglia', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            const Spacer(),
                            Text('$_speedThreshold km/h', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                          ],
                        ),
                        Slider(
                          value: _speedThreshold.toDouble(),
                          min: 30,
                          max: 200,
                          divisions: 34,
                          label: '$_speedThreshold km/h',
                          onChanged: (v) => setState(() => _speedThreshold = v.round()),
                          onChangeEnd: (v) => AppState.instance.setSpeedAlert(v.round()),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap, this.loading = false});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppTheme.textPrimary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13.5))),
            if (loading)
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
            else
              Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
