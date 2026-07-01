import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferenza di aspetto salvata sul dispositivo: segue il sistema per
/// impostazione predefinita, ma si può forzare chiaro o scuro.
enum AppThemePreference { system, light, dark }

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final instance = ThemeController._();

  static const _prefKey = 'theme_preference';

  AppThemePreference _preference = AppThemePreference.system;
  AppThemePreference get preference => _preference;

  ThemeMode get themeMode => switch (_preference) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    _preference = AppThemePreference.values.firstWhere(
      (p) => p.name == saved,
      orElse: () => AppThemePreference.system,
    );
    notifyListeners();
  }

  Future<void> setPreference(AppThemePreference preference) async {
    if (preference == _preference) return;
    _preference = preference;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, preference.name);
  }
}
