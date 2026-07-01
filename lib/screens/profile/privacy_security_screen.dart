import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/auth_service.dart';
import '../../services/background_tracking_settings.dart';
import '../../services/biometric_lock_service.dart';
import '../../services/location_tracker.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../people/sos_contacts_screen.dart';
import '../premium/paywall_screen.dart';
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

  bool _backgroundTrackingEnabled = false;
  bool _backgroundTrackingBusy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBiometric());
    unawaited(_loadBackgroundTracking());
  }

  Future<void> _loadBackgroundTracking() async {
    final enabled = await BackgroundTrackingSettings.instance.isEnabled();
    if (mounted) setState(() => _backgroundTrackingEnabled = enabled);
  }

  Future<void> _toggleBackgroundTracking(bool value) async {
    if (!value) {
      setState(() => _backgroundTrackingEnabled = false);
      await LocationTracker.instance.disableBackgroundTracking();
      return;
    }

    if (!AppState.instance.isPremium) {
      final goToPaywall = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Funzione Kinly+'),
          content: const Text(
            'Il tracciamento in background (la posizione continua ad aggiornarsi anche con l\'app chiusa) è un vantaggio Kinly+.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Non ora')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Scopri Kinly+')),
          ],
        ),
      );
      if (goToPaywall == true && mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Attivare il tracciamento in background?'),
        content: const Text(
          'La tua posizione continuerà ad aggiornarsi anche quando Kinly non è in primo piano. '
          'Consuma più batteria e mostra sempre una notifica fissa mentre è attivo, come richiesto da Android.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Attiva')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _backgroundTrackingBusy = true);
    final result = await LocationTracker.instance.enableBackgroundTracking();
    if (!mounted) return;
    setState(() {
      _backgroundTrackingBusy = false;
      _backgroundTrackingEnabled = result == BackgroundTrackingResult.enabled;
    });

    if (result == BackgroundTrackingResult.needsSystemSettings) {
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Serve un passaggio in più'),
          content: const Text(
            'Il tuo Android richiede di attivare a mano il permesso di posizione "Consenti sempre" dalle impostazioni di sistema, poi torna qui e riattiva l\'interruttore.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Non ora')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Apri impostazioni')),
          ],
        ),
      );
      if (openSettings == true) await Geolocator.openAppSettings();
    } else if (result == BackgroundTrackingResult.locationPermissionDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prima serve concedere il permesso di posizione a Kinly.')),
      );
    }
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

  Future<void> _pickGhostTime({required bool isStart}) async {
    final state = AppState.instance;
    final initial = (isStart ? state.autoGhostStart : state.autoGhostEnd) ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final start = isStart ? picked : (state.autoGhostStart ?? const TimeOfDay(hour: 9, minute: 0));
    final end = isStart ? (state.autoGhostEnd ?? const TimeOfDay(hour: 18, minute: 0)) : picked;
    await state.setAutoGhostSchedule(start, end);
  }

  Future<void> _toggleGhostSchedule(bool enabled) async {
    if (!enabled) {
      await AppState.instance.setAutoGhostSchedule(null, null);
      return;
    }
    await AppState.instance.setAutoGhostSchedule(const TimeOfDay(hour: 9, minute: 0), const TimeOfDay(hour: 18, minute: 0));
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: AppState.instance.me.birthday ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 110),
      lastDate: now,
    );
    if (picked != null) await AppState.instance.setBirthday(picked);
  }

  Future<void> _editPaymentLink() async {
    final controller = TextEditingController(text: AppState.instance.me.paymentLink ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Link di pagamento'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'Es. link Satispay, PayPal.me/...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(''), child: const Text('Rimuovi')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Salva')),
        ],
      ),
    );
    if (result == null) return;
    await AppState.instance.setPaymentLink(result.isEmpty ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final speedAlertEnabled = state.me.speedAlertKmh != null;
        final ghostScheduleEnabled = state.autoGhostStart != null && state.autoGhostEnd != null;
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
                const SizedBox(height: 24),
                Text('Info personali', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  'Facoltative: usate solo per un\'iconcina di compleanno tra i membri della cerchia e per aprire un pagamento diretto dalle spese di gruppo.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.cake_outlined,
                  label: state.me.birthday == null
                      ? 'Aggiungi data di nascita'
                      : 'Compleanno: ${state.me.birthday!.day.toString().padLeft(2, '0')}/${state.me.birthday!.month.toString().padLeft(2, '0')}',
                  onTap: _pickBirthday,
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.payments_outlined,
                  label: state.me.paymentLink == null ? 'Aggiungi link di pagamento' : 'Link di pagamento impostato',
                  onTap: _editPaymentLink,
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
                if (Platform.isAndroid) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Tracciamento in background', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                      if (!AppState.instance.isPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.accentAmber.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                          child: const Text('Kinly+', style: TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.w700, fontSize: 10.5)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Per impostazione predefinita Kinly aggiorna la tua posizione solo mentre è aperta. Attivalo per farla continuare anche in background: consuma più batteria e mostra sempre una notifica fissa mentre è attivo.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Attiva in background', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
                        ),
                        if (_backgroundTrackingBusy)
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2))
                        else
                          Switch(value: _backgroundTrackingEnabled, onChanged: _toggleBackgroundTracking),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text('Orario di reperibilità', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  'Utile per il lavoro: fuori da questa fascia oraria nessuno vede la tua posizione, in nessuna delle tue cerchie ("clock-out" automatico).',
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
                            child: Text('Limita l\'orario', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
                          ),
                          Switch(value: ghostScheduleEnabled, onChanged: _toggleGhostSchedule),
                        ],
                      ),
                      if (ghostScheduleEnabled) ...[
                        const Divider(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _TimeField(
                                label: 'Dalle',
                                time: state.autoGhostStart!,
                                onTap: () => _pickGhostTime(isStart: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TimeField(
                                label: 'Alle',
                                time: state.autoGhostEnd!,
                                onTap: () => _pickGhostTime(isStart: false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('SOS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  state.sosTrustedContactIds.isEmpty
                      ? 'Per ora avvisa tutte le tue cerchie. Puoi scegliere solo alcune persone.'
                      : 'Avvisa solo ${state.sosTrustedContactIds.length} persone scelte, non tutta la cerchia.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.emergency_outlined,
                  label: 'Chi avvisare in caso di SOS',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SosContactsScreen())),
                ),
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

class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.time, required this.onTap});
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              time.format(context),
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
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
