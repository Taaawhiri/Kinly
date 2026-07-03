import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../l10n/app_localizations.dart';
import '../../services/biometric_lock_service.dart';
import '../../services/location_tracker.dart';
import '../../services/onboarding_settings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';

/// Breve introduzione mostrata una volta sola, prima di creare/entrare in
/// una cerchia: cosa fa Kinly, poi (se il dispositivo lo supporta) la
/// possibilità di attivare subito lo sblocco biometrico, senza dover andare
/// a cercarlo più tardi nelle impostazioni.
class OnboardingIntroScreen extends StatefulWidget {
  const OnboardingIntroScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<OnboardingIntroScreen> createState() => _OnboardingIntroScreenState();
}

class _OnboardingIntroScreenState extends State<OnboardingIntroScreen> {
  final _pageController = PageController();
  int _page = 0;
  bool _biometricSupported = false;
  bool _biometricEnabled = false;
  bool _biometricChecked = false;
  bool _locationGranted = false;
  bool _locationChecked = false;
  bool _locationRequesting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_checkBiometric());
    unawaited(_checkLocationPermission());
  }

  Future<void> _checkBiometric() async {
    final supported = await BiometricLockService.instance.isDeviceSupported();
    if (mounted) {
      setState(() {
        _biometricSupported = supported;
        _biometricChecked = true;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final confirmed = await BiometricLockService.instance.authenticate();
      if (!confirmed) return;
    }
    await BiometricLockService.instance.setEnabled(value);
    if (mounted) setState(() => _biometricEnabled = value);
  }

  /// Solo un controllo, non una richiesta: evita di mostrare il dialogo di
  /// sistema prima ancora che l'utente veda perché serve (vedi
  /// _requestLocation, chiamata invece dal pulsante di questa pagina).
  Future<void> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
      if (mounted) setState(() { _locationGranted = granted; _locationChecked = true; });
    } catch (_) {
      if (mounted) setState(() => _locationChecked = true);
    }
  }

  Future<void> _requestLocation() async {
    setState(() => _locationRequesting = true);
    try {
      final granted = await LocationTracker.instance.requestPermission();
      if (granted) unawaited(LocationTracker.instance.start());
      if (mounted) setState(() => _locationGranted = granted);
    } catch (_) {
      // Mai bloccare l'onboarding per un errore nel controllo del permesso.
    }
    if (mounted) setState(() => _locationRequesting = false);
  }

  int get _pageCount => 4 + (_biometricSupported ? 1 : 0);

  Future<void> _finish() async {
    await OnboardingSettings.instance.markIntroSeen();
    widget.onDone();
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_biometricChecked || !_locationChecked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _IntroPage(
                    icon: Icons.groups_rounded,
                    title: l10n.onboardingWelcomeTitle,
                    description: l10n.onboardingWelcomeDesc,
                  ),
                  _IntroPage(
                    icon: Icons.emergency_rounded,
                    title: l10n.onboardingSafeTitle,
                    description: l10n.onboardingSafeDesc,
                  ),
                  _IntroPage(
                    icon: Icons.forum_rounded,
                    title: l10n.onboardingContactTitle,
                    description: l10n.onboardingContactDesc,
                  ),
                  _LocationPermissionPage(
                    granted: _locationGranted,
                    requesting: _locationRequesting,
                    onRequest: _requestLocation,
                  ),
                  if (_biometricSupported)
                    _BiometricPage(enabled: _biometricEnabled, onChanged: _toggleBiometric),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pageCount; i++)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _page ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _page ? AppTheme.primary : AppTheme.divider,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                    child: Text(_page == _pageCount - 1 ? l10n.onboardingStart : l10n.commonContinue),
                  ),
                  if (_page < _pageCount - 1) ...[
                    const SizedBox(height: 10),
                    TextButton(onPressed: _finish, child: Text(l10n.onboardingSkip)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.icon, required this.title, required this.description});
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.12)),
            alignment: Alignment.center,
            child: Icon(icon, color: AppTheme.primary, size: 42),
          ),
          const SizedBox(height: 28),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, color: AppTheme.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _LocationPermissionPage extends StatelessWidget {
  const _LocationPermissionPage({required this.granted, required this.requesting, required this.onRequest});
  final bool granted;
  final bool requesting;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.12)),
            alignment: Alignment.center,
            child: Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 42),
          ),
          const SizedBox(height: 28),
          Text(l10n.onboardingLocationTitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingLocationDesc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          if (granted)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 20),
                  const SizedBox(width: 10),
                  Text(l10n.onboardingLocationGranted, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
                ],
              ),
            )
          else
            OutlinedButton(
              onPressed: requesting ? null : onRequest,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: requesting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                  : Text(l10n.onboardingLocationGrant),
            ),
        ],
      ),
    );
  }
}

class _BiometricPage extends StatelessWidget {
  const _BiometricPage({required this.enabled, required this.onChanged});
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const KinlyLogo(size: 72),
          const SizedBox(height: 24),
          Text(l10n.onboardingBiometricTitle, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingBiometricDesc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, color: AppTheme.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.privacyBiometricUnlock, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
                ),
                Switch(value: enabled, onChanged: onChanged),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
