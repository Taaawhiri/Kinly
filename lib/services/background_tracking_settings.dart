import 'package:shared_preferences/shared_preferences.dart';

/// Preferenza locale (per dispositivo, non sincronizzata su Supabase) per
/// tenere attivo il tracciamento della posizione anche quando Kinly non è
/// in primo piano. Disattivata di default: ha un costo reale in autonomia
/// della batteria, quindi va scelta esplicitamente da chi la vuole.
class BackgroundTrackingSettings {
  BackgroundTrackingSettings._();
  static final instance = BackgroundTrackingSettings._();

  static const _prefKey = 'background_tracking_enabled';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }
}
