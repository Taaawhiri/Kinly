import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferenza locale (non condivisa con nessuno) che sostituisce la home a
/// mappa con la "Modalità Rapida": stessa app, meno rumore visivo, testo più
/// leggibile e una sola azione ovvia per riga. È solo un modo di vedere la
/// prima schermata — non cambia cosa condividi né cosa vedono gli altri —
/// quindi vive sul dispositivo (come il tema), non sul profilo Supabase.
class SimpleModeController extends ChangeNotifier {
  SimpleModeController._();
  static final instance = SimpleModeController._();

  static const _prefKey = 'simple_mode_enabled';

  bool _enabled = false;
  bool get enabled => _enabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefKey) ?? false;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  Future<void> toggle() => setEnabled(!_enabled);
}
