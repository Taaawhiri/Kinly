import 'package:flutter/material.dart';

/// Palette e tema di Kinly: chiaro, morbido, moderno — l'opposto del
/// "notte da gioco di carte": qui deve sembrare un'app di fiducia che usi
/// ogni giorno con la famiglia. Esiste anche una variante scura.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF4A63E7);
  static const Color primaryDark = Color(0xFF2F3FAE);
  static const Color accentCoral = Color(0xFFFF6B6B);
  static const Color accentGreen = Color(0xFF23C16B);
  static const Color accentAmber = Color(0xFFFFB020);

  static const Color _lightBackground = Color(0xFFF4F6FB);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceAlt = Color(0xFFEDF0F9);
  static const Color _lightTextPrimary = Color(0xFF1F2430);
  static const Color _lightTextSecondary = Color(0xFF6B7280);
  static const Color _lightDivider = Color(0xFFE3E7F1);

  static const Color _darkBackground = Color(0xFF12141C);
  static const Color _darkSurface = Color(0xFF1C202C);
  static const Color _darkSurfaceAlt = Color(0xFF272C3B);
  static const Color _darkTextPrimary = Color(0xFFF1F2F6);
  static const Color _darkTextSecondary = Color(0xFFA2A8BC);
  static const Color _darkDivider = Color(0xFF343A4C);

  /// Aggiornato da KinlyApp ad ogni build in base al tema effettivamente
  /// risolto (chiaro/scuro/sistema): i widget che usano questi colori
  /// direttamente (senza passare da Theme.of(context)) restano coerenti.
  static bool isDark = false;

  static Color get background => isDark ? _darkBackground : _lightBackground;
  static Color get surface => isDark ? _darkSurface : _lightSurface;
  static Color get surfaceAlt => isDark ? _darkSurfaceAlt : _lightSurfaceAlt;
  static Color get textPrimary => isDark ? _darkTextPrimary : _lightTextPrimary;
  static Color get textSecondary => isDark ? _darkTextSecondary : _lightTextSecondary;
  static Color get divider => isDark ? _darkDivider : _lightDivider;

  static ThemeData get light => _themeFor(Brightness.light);
  static ThemeData get dark => _themeFor(Brightness.dark);

  static ThemeData _themeFor(Brightness brightness) {
    final darkTheme = brightness == Brightness.dark;
    final bg = darkTheme ? _darkBackground : _lightBackground;
    final surf = darkTheme ? _darkSurface : _lightSurface;
    final textP = darkTheme ? _darkTextPrimary : _lightTextPrimary;
    final textS = darkTheme ? _darkTextSecondary : _lightTextSecondary;
    final div = darkTheme ? _darkDivider : _lightDivider;

    final base = ThemeData(brightness: brightness, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: accentGreen,
        surface: surf,
        error: accentCoral,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textP,
        displayColor: textP,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textP,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surf,
        indicatorColor: primary.withOpacity(0.12),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : textS,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: div, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      dividerTheme: DividerThemeData(color: div, thickness: 1, space: 1),
    );
  }
}
