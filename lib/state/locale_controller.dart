import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lingua salvata sul dispositivo: segue il sistema per impostazione
/// predefinita (se supportata, altrimenti italiano), ma si può forzare
/// italiano o inglese indipendentemente dalla lingua del telefono.
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final instance = LocaleController._();

  static const _prefKey = 'locale_preference';

  /// null = segui il sistema.
  Locale? _locale;
  Locale? get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    _locale = (saved == null) ? null : Locale(saved);
    notifyListeners();
  }

  /// Passa null per tornare a seguire la lingua di sistema.
  Future<void> setLocale(Locale? locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, locale.languageCode);
    }
  }
}
