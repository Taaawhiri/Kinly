import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_update_service.dart';
import '../../services/auth_service.dart';
import '../../services/background_tracking_settings.dart';
import '../../services/battery_optimization_service.dart';
import '../../services/biometric_lock_service.dart';
import '../../services/crash_detection_service.dart';
import '../../services/emergency_sms_settings.dart';
import '../../services/location_tracker.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_input_formatter.dart';
import '../circles/circles_screen.dart';
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

  String? _emergencySmsNumber;
  bool _crashDetectionEnabled = false;

  bool _checkingUpdate = false;

  LocationPermission? _locationPermission;
  bool? _notificationsEnabled;
  bool? _batteryOptimizationIgnored;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBiometric());
    unawaited(_loadBackgroundTracking());
    unawaited(_loadEmergencySettings());
    unawaited(_loadPermissionsStatus());
  }

  Future<void> _loadPermissionsStatus() async {
    final location = await Geolocator.checkPermission();
    bool? notifications;
    if (!kIsWeb) {
      try {
        final settings = await FirebaseMessaging.instance.getNotificationSettings();
        notifications = settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
      } catch (_) {
        // Firebase non configurato su questa build/piattaforma: niente riga
        // notifiche invece di un errore, coerente con PushNotificationService.
      }
    }
    bool? batteryIgnored;
    if (!kIsWeb && Platform.isAndroid) {
      batteryIgnored = await BatteryOptimizationService.instance.isIgnoringOptimizations();
    }
    if (mounted) {
      setState(() {
        _locationPermission = location;
        _notificationsEnabled = notifications;
        _batteryOptimizationIgnored = batteryIgnored;
      });
    }
  }

  /// A differenza di posizione/notifiche, qui non ha senso "disattivare":
  /// se Kinly è già esclusa dal risparmio energetico va bene così, altrimenti
  /// apriamo la richiesta di sistema (vedi BatteryOptimizationService).
  Future<void> _fixBatteryOptimization() async {
    final l10n = AppLocalizations.of(context)!;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.privacyBatteryOptimizationDialogTitle),
        content: Text(l10n.privacyBatteryOptimizationDialogBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonNotNow)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.privacyBatteryOptimizationOpen)),
        ],
      ),
    );
    if (proceed != true) return;
    await BatteryOptimizationService.instance.requestIgnoreOptimizations();
    await _loadPermissionsStatus();
  }

  /// Un'app non può disattivare da sola un permesso già concesso: se è già
  /// attivo, l'unica azione sensata è aprire le impostazioni di sistema
  /// (dove l'utente può revocarlo lui); se non lo è, proviamo a chiederlo.
  Future<void> _toggleLocationPermission(bool wantsOn) async {
    final granted = _locationPermission == LocationPermission.always || _locationPermission == LocationPermission.whileInUse;
    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.privacyPermissionDisableFromSystem)));
      await Geolocator.openAppSettings();
    } else {
      await Geolocator.requestPermission();
    }
    await _loadPermissionsStatus();
  }

  Future<void> _toggleNotificationsPermission(bool wantsOn) async {
    if (_notificationsEnabled == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.privacyPermissionDisableFromSystem)));
      await Geolocator.openAppSettings();
    } else {
      try {
        await FirebaseMessaging.instance.requestPermission();
      } catch (_) {
        // Va bene fallire in silenzio: la riga si limiterà a mostrare lo
        // stato invariato dopo il ricaricamento sotto.
      }
    }
    await _loadPermissionsStatus();
  }

  Future<void> _loadEmergencySettings() async {
    final number = await EmergencySmsSettings.instance.getNumber();
    final crashEnabled = await CrashDetectionService.instance.isEnabled();
    if (mounted) {
      setState(() {
        _emergencySmsNumber = number;
        _crashDetectionEnabled = crashEnabled;
      });
    }
  }

  Future<void> _editEmergencySmsNumber() async {
    final controller = TextEditingController(text: _emergencySmsNumber ?? '');
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.privacySosSmsNumberTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(hintText: l10n.privacyPhoneExampleHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(''), child: Text(l10n.commonRemove)),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: Text(l10n.commonSave)),
        ],
      ),
    );
    if (result == null) return;
    final value = result.isEmpty ? null : result;
    await EmergencySmsSettings.instance.setNumber(value);
    if (mounted) setState(() => _emergencySmsNumber = value);
  }

  Future<void> _toggleCrashDetection(bool value) async {
    if (value && !AppState.instance.isPremium) {
      final l10n = AppLocalizations.of(context)!;
      final goToPaywall = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(l10n.privacyPlusFeatureTitle),
          content: Text(l10n.privacyCrashDetectionPlusBody),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonNotNow)),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.circleMessagesDiscoverPlus)),
          ],
        ),
      );
      if (goToPaywall == true && mounted) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
      }
      return;
    }
    await CrashDetectionService.instance.setEnabled(value);
    if (mounted) setState(() => _crashDetectionEnabled = value);
  }

  Future<void> _loadBackgroundTracking() async {
    final enabled = await BackgroundTrackingSettings.instance.isEnabled();
    if (mounted) setState(() => _backgroundTrackingEnabled = enabled);
  }

  Future<void> _toggleBackgroundTracking(bool value) async {
    final l10n = AppLocalizations.of(context)!;
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
          title: Text(l10n.privacyPlusFeatureTitle),
          content: Text(l10n.privacyBackgroundTrackingPlusBody),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonNotNow)),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.circleMessagesDiscoverPlus)),
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
        title: Text(l10n.privacyEnableBackgroundTrackingTitle),
        content: Text(l10n.privacyEnableBackgroundTrackingBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonCancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.commonActivate)),
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
          title: Text(l10n.privacyExtraStepTitle),
          content: Text(l10n.privacyExtraStepBody),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonNotNow)),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.privacyOpenSettings)),
          ],
        ),
      );
      if (openSettings == true) await Geolocator.openAppSettings();
    } else if (result == BackgroundTrackingResult.locationPermissionDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.privacyGrantLocationFirst)),
      );
    } else if (result == BackgroundTrackingResult.enabled && Platform.isAndroid) {
      // Proprio il momento in cui conta di più: il tracciamento in
      // background serve a nulla se il telefono lo sospende comunque per
      // risparmiare batteria (vedi BatteryOptimizationService).
      final alreadyIgnored = await BatteryOptimizationService.instance.isIgnoringOptimizations();
      if (!alreadyIgnored && mounted) await _fixBatteryOptimization();
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.privacyBiometricAuthFailed)));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.privacyOtherDevicesSignedOut)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.privacyOperationFailed)));
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
    final existing = AppState.instance.me.birthday;
    final controller = TextEditingController(text: existing != null ? formatSlashDate(existing) : '');
    final l10n = AppLocalizations.of(context)!;
    String? error;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(l10n.privacyBirthdayTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, DateSlashFormatter()],
            decoration: InputDecoration(hintText: l10n.privacyDateHint, errorText: error),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonCancel)),
            FilledButton(
              onPressed: () {
                final date = parseSlashDate(controller.text);
                if (date == null) {
                  setDialogState(() => error = l10n.privacyInvalidDate);
                  return;
                }
                Navigator.of(context).pop(date);
              },
              child: Text(l10n.commonSave),
            ),
          ],
        ),
      ),
    );
    if (picked != null) await AppState.instance.setBirthday(picked);
  }

  Future<void> _editPaymentLink() async {
    final controller = TextEditingController(text: AppState.instance.me.paymentLink ?? '');
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.privacyPaymentLinkTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(hintText: l10n.privacyPaymentLinkHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(''), child: Text(l10n.commonRemove)),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: Text(l10n.commonSave)),
        ],
      ),
    );
    if (result == null) return;
    await AppState.instance.setPaymentLink(result.isEmpty ? null : result);
  }

  Future<void> _editPhoneNumber() async {
    final controller = TextEditingController(text: AppState.instance.me.phoneNumber ?? '');
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.privacyPhoneNumberTitle),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(hintText: l10n.privacyPhoneExampleHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(''), child: Text(l10n.commonRemove)),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: Text(l10n.commonSave)),
        ],
      ),
    );
    if (result == null) return;
    await AppState.instance.setPhoneNumber(result.isEmpty ? null : result);
  }

  Future<void> _checkForUpdate() async {
    setState(() => _checkingUpdate = true);
    final update = await AppUpdateService.instance.checkForUpdate();
    if (!mounted) return;
    setState(() => _checkingUpdate = false);
    final l10n = AppLocalizations.of(context)!;

    if (update == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.privacyUpToDate)));
      return;
    }

    final notes = update.notes?.trim();
    final download = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.privacyUpdateAvailableTitle(update.buildNumber)),
        content: Text((notes != null && notes.isNotEmpty) ? notes : l10n.privacyUpdateAvailableBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonNotNow)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.privacyDownloadUpdate)),
        ],
      ),
    );
    if (download == true && mounted) {
      await _downloadAndInstall(update.downloadUrl);
    }
  }

  /// Scarica l'APK QUI dentro l'app (invece di aprire il link nel browser
  /// di sistema, che restava bloccato al 99% su alcuni telefoni: un bug
  /// noto di Chrome per i download avviati da un'altra app, vedi
  /// AppUpdateService), poi lo apre con OpenFilex: quello fa comparire la
  /// schermata di installazione di Android, dove il tocco finale resta
  /// comunque dell'utente.
  Future<void> _downloadAndInstall(String url) async {
    final l10n = AppLocalizations.of(context)!;
    final progress = ValueNotifier<double>(0);
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.privacyDownloadingUpdate),
        content: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (context, value, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: value > 0 ? value : null),
              const SizedBox(height: 10),
              Text('${(value * 100).round()}%'),
            ],
          ),
        ),
      ),
    ));

    try {
      final path = await AppUpdateService.instance.downloadApk(url, onProgress: (p) => progress.value = p);
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.privacyUpdateInstallError)));
      }
    } catch (_) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.privacyUpdateDownloadError),
          action: SnackBarAction(label: l10n.privacyOpenInBrowser, onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final speedAlertEnabled = state.me.speedAlertKmh != null;
        final ghostScheduleEnabled = state.autoGhostStart != null && state.autoGhostEnd != null;
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.privacyTitle)),
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
                          l10n.privacyLocationVisibilityInfo,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(l10n.privacyPermissionsHeader, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  l10n.privacyPermissionsHint,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      _PermissionRow(
                        icon: Icons.location_on_outlined,
                        label: l10n.privacyPermissionLocation,
                        status: switch (_locationPermission) {
                          LocationPermission.always => l10n.privacyPermissionLocationAlways,
                          LocationPermission.whileInUse => l10n.privacyPermissionLocationWhileInUse,
                          _ => l10n.privacyPermissionLocationDenied,
                        },
                        value: _locationPermission == LocationPermission.always || _locationPermission == LocationPermission.whileInUse,
                        onChanged: _toggleLocationPermission,
                      ),
                      if (_notificationsEnabled != null) ...[
                        const Divider(height: 24),
                        _PermissionRow(
                          icon: Icons.notifications_outlined,
                          label: l10n.privacyPermissionNotifications,
                          status: _notificationsEnabled! ? l10n.privacyPermissionNotificationsOn : l10n.privacyPermissionNotificationsOff,
                          value: _notificationsEnabled!,
                          onChanged: _toggleNotificationsPermission,
                        ),
                      ],
                      if (_batteryOptimizationIgnored != null) ...[
                        const Divider(height: 24),
                        _PermissionRow(
                          icon: Icons.battery_saver_outlined,
                          label: l10n.privacyPermissionBattery,
                          status: _batteryOptimizationIgnored! ? l10n.privacyPermissionBatteryExempt : l10n.privacyPermissionBatteryRestricted,
                          value: _batteryOptimizationIgnored!,
                          onChanged: (_) => _fixBatteryOptimization(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(l10n.privacyAccountHeader, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.lock_outline_rounded,
                  label: l10n.privacyChangePassword,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.phonelink_erase_outlined,
                  label: l10n.privacySignOutOtherDevices,
                  loading: _signingOutOthers,
                  onTap: _signingOutOthers ? null : _signOutOthers,
                ),
                const SizedBox(height: 24),
                Text(l10n.privacyPersonalInfoHeader, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  l10n.privacyPersonalInfoHint,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.cake_outlined,
                  label: state.me.birthday == null
                      ? l10n.privacyAddBirthday
                      : l10n.privacyBirthdaySet('${state.me.birthday!.day.toString().padLeft(2, '0')}/${state.me.birthday!.month.toString().padLeft(2, '0')}'),
                  onTap: _pickBirthday,
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.payments_outlined,
                  label: state.me.paymentLink == null ? l10n.privacyAddPaymentLink : l10n.privacyPaymentLinkSet,
                  onTap: _editPaymentLink,
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.call_outlined,
                  label: state.me.phoneNumber == null ? l10n.privacyAddPhoneNumber : l10n.privacyPhoneNumberSet(state.me.phoneNumber!),
                  onTap: _editPhoneNumber,
                ),
                if (!_biometricLoading && _biometricSupported) ...[
                  const SizedBox(height: 24),
                  Text(l10n.privacyBiometricHeader, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  Text(
                    l10n.privacyBiometricHint,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(l10n.privacyBiometricUnlock, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
                        ),
                        Switch(value: _biometricEnabled, onChanged: _toggleBiometric),
                      ],
                    ),
                  ),
                ],
                if (!kIsWeb && Platform.isAndroid) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(l10n.privacyBackgroundTrackingHeader, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
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
                    l10n.privacyBackgroundTrackingHint,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(l10n.privacyEnableInBackground, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
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
                Text(l10n.privacyGhostScheduleHeader, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  l10n.privacyGhostScheduleHint,
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
                            child: Text(l10n.privacyLimitHours, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
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
                                label: l10n.privacyFrom,
                                time: state.autoGhostStart!,
                                onTap: () => _pickGhostTime(isStart: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TimeField(
                                label: l10n.privacyTo,
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
                Text(l10n.privacySosHeader, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  state.sosTrustedContactIds.isEmpty
                      ? l10n.privacySosAllCircles
                      : l10n.privacySosSelectedCount(state.sosTrustedContactIds.length),
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.emergency_outlined,
                  label: l10n.privacySosWhoToNotify,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SosContactsScreen())),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.sms_outlined,
                  label: _emergencySmsNumber == null
                      ? l10n.privacySosSmsNumberEmpty
                      : l10n.privacySosSmsNumberSet(_emergencySmsNumber!),
                  onTap: _editEmergencySmsNumber,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(l10n.privacyCrashDetectionTitle, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
                                ),
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
                            const SizedBox(height: 2),
                            Text(
                              l10n.privacyCrashDetectionDesc,
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      Switch(value: _crashDetectionEnabled, onChanged: _toggleCrashDetection),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(l10n.privacySpeedAlertHeader, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  l10n.privacySpeedAlertHint,
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
                            child: Text(l10n.privacyEnableAlert, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
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
                            Text(l10n.privacyThreshold, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            const Spacer(),
                            Text(l10n.privacySpeedKmh(_speedThreshold), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                          ],
                        ),
                        Slider(
                          value: _speedThreshold.toDouble(),
                          min: 30,
                          max: 200,
                          divisions: 34,
                          label: l10n.privacySpeedKmh(_speedThreshold),
                          onChanged: (v) => setState(() => _speedThreshold = v.round()),
                          onChangeEnd: (v) => AppState.instance.setSpeedAlert(v.round()),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(l10n.privacyWeeklySummaryHeader, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  l10n.privacyWeeklySummaryHint,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(l10n.privacyReceiveSummary, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
                      ),
                      Switch(
                        value: state.me.weeklySummaryEnabled,
                        onChanged: (v) => AppState.instance.setWeeklySummaryEnabled(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(l10n.privacyGuideHeader, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.help_outline_rounded,
                  label: l10n.privacyReviewCirclesGuide,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CirclesScreen(forceCoachMark: true)),
                  ),
                ),
                if (!kIsWeb && state.me.isBetaTester) ...[
                  const SizedBox(height: 24),
                  Text(l10n.privacyBetaHeader, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  Text(
                    l10n.privacyBetaHint,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  _ActionTile(
                    icon: Icons.system_update_rounded,
                    label: _checkingUpdate ? l10n.privacyCheckingUpdate : l10n.privacyCheckForUpdates,
                    loading: _checkingUpdate,
                    onTap: _checkingUpdate ? null : _checkForUpdate,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.icon, required this.label, required this.status, required this.value, required this.onChanged});
  final IconData icon;
  final String label;
  final String status;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppTheme.textPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              Text(status, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
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
