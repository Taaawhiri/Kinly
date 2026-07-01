import 'package:flutter/services.dart';

/// Inserisce automaticamente le "/" mentre si digita una data nel formato
/// GG/MM/AAAA, così non serve scriverle a mano.
class DateSlashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll('/', '');
    if (digits.length > 8) digits = digits.substring(0, 8);

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 1 || i == 3) buffer.write('/');
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Converte "GG/MM/AAAA" in una data valida, o null se il formato/i valori
/// non sono corretti (es. 31/02/2024).
DateTime? parseSlashDate(String input) {
  final digits = input.replaceAll('/', '');
  if (digits.length != 8) return null;
  final day = int.tryParse(digits.substring(0, 2));
  final month = int.tryParse(digits.substring(2, 4));
  final year = int.tryParse(digits.substring(4, 8));
  if (day == null || month == null || year == null) return null;
  if (year < 1900 || year > DateTime.now().year) return null;

  final date = DateTime(year, month, day);
  // DateTime normalizza automaticamente i valori fuori range (es. giorno 32
  // diventa il giorno 1 del mese dopo): se non torna lo stesso giorno/mese
  // richiesti, l'input non era una data valida.
  if (date.day != day || date.month != month || date.year != year) return null;
  return date;
}

/// Formatta una data come "GG/MM/AAAA" per precompilare il campo.
String formatSlashDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
