import 'package:shared_preferences/shared_preferences.dart';

/// Se l'onboarding introduttivo è già stato mostrato su questo dispositivo.
/// Locale, non sincronizzato: un nuovo account su un altro dispositivo lo
/// rivede, ma è comunque mostrato solo a chi non ha ancora nessuna cerchia
/// (vedi AuthGate), quindi non disturba mai chi usa già l'app.
class OnboardingSettings {
  OnboardingSettings._();
  static final instance = OnboardingSettings._();

  static const _prefKey = 'onboarding_intro_seen';

  Future<bool> hasSeenIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  Future<void> markIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }
}
