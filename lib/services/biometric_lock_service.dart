import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sblocco biometrico dell'app: un livello in più oltre alla password
/// dell'account, verificato dal sistema operativo (non da Kinly, che non
/// vede mai l'impronta o il volto). La preferenza è salvata solo su questo
/// dispositivo.
class BiometricLockService {
  BiometricLockService._();
  static final instance = BiometricLockService._();

  static const _prefKey = 'biometric_unlock_enabled';
  final _localAuth = LocalAuthentication();

  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported() && await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }

  /// True se il sistema conferma l'identità (biometria o, in mancanza,
  /// il PIN/sequenza del dispositivo).
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Sblocca Kinly per continuare',
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
