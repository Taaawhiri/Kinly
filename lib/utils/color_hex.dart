import 'package:flutter/material.dart';

/// Conversione tra `Color` e la stringa esadecimale salvata su Supabase
/// (es. "#4A63E7").
extension ColorHex on Color {
  String toHex() => '#${(toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static Color fromHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}
