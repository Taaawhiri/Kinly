import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lingua salvata sul dispositivo: sempre una scelta esplicita tra quelle
/// che offriamo davvero (mai "segui il sistema", che su un telefono in una
/// lingua che non supportiamo darebbe un risultato ambiguo). Al primo
/// avvio si prova comunque a indovinare dalla lingua del dispositivo, ma
/// da li' in poi resta quella scelta finche' l'utente non la cambia.
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final instance = LocaleController._();

  static const _prefKey = 'locale_preference';
  static const supportedLocales = [Locale('it'), Locale('en')];

  late Locale _locale;
  Locale get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      _locale = Locale(saved);
    } else {
      final deviceCode = PlatformDispatcher.instance.locale.languageCode;
      _locale = supportedLocales.firstWhere(
        (l) => l.languageCode == deviceCode,
        orElse: () => const Locale('it'),
      );
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }
}
