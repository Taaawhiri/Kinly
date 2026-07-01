import 'package:shared_preferences/shared_preferences.dart';

/// Numero di telefono per l'SOS via SMS: usato solo quando l'SOS normale
/// fallisce perché non c'è internet — in quel caso l'app prepara un SMS con
/// le coordinate verso questo numero (l'invio lo confermi tu dall'app SMS).
/// Salvato solo su questo dispositivo, mai su Supabase.
class EmergencySmsSettings {
  EmergencySmsSettings._();
  static final instance = EmergencySmsSettings._();

  static const _prefKey = 'emergency_sms_number';

  Future<String?> getNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> setNumber(String? number) async {
    final prefs = await SharedPreferences.getInstance();
    if (number == null || number.isEmpty) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, number);
    }
  }
}
