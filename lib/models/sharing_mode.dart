import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Come una persona condivide (o non condivide) la propria posizione.
enum SharingMode { automatic, onRequest, paused, fuzzy }

extension SharingModeData on SharingMode {
  /// Valore salvato in `profiles.sharing_mode` su Supabase.
  String get dbValue {
    switch (this) {
      case SharingMode.automatic:
        return 'automatic';
      case SharingMode.onRequest:
        return 'on_request';
      case SharingMode.paused:
        return 'paused';
      case SharingMode.fuzzy:
        return 'fuzzy';
    }
  }

  static SharingMode fromDb(String value) {
    switch (value) {
      case 'on_request':
        return SharingMode.onRequest;
      case 'paused':
        return SharingMode.paused;
      case 'fuzzy':
        return SharingMode.fuzzy;
      case 'automatic':
      default:
        return SharingMode.automatic;
    }
  }

  String get label {
    switch (this) {
      case SharingMode.automatic:
        return 'Automatica';
      case SharingMode.onRequest:
        return 'Su richiesta';
      case SharingMode.paused:
        return 'Sospesa';
      case SharingMode.fuzzy:
        return 'Approssimativa';
    }
  }

  String get description {
    switch (this) {
      case SharingMode.automatic:
        return 'La tua posizione è sempre visibile alla tua cerchia, in tempo reale.';
      case SharingMode.onRequest:
        return 'Nessuno vede la tua posizione finché non approvi una richiesta.';
      case SharingMode.paused:
        return 'Modalità fantasma: sei invisibile, nessuno può chiedere dove sei.';
      case SharingMode.fuzzy:
        return 'La tua cerchia vede solo la zona (circa 1 km), mai il punto esatto.';
    }
  }

  IconData get icon {
    switch (this) {
      case SharingMode.automatic:
        return Icons.my_location;
      case SharingMode.onRequest:
        return Icons.mail_outline;
      case SharingMode.paused:
        return Icons.visibility_off_outlined;
      case SharingMode.fuzzy:
        return Icons.blur_on_rounded;
    }
  }

  Color get color {
    switch (this) {
      case SharingMode.automatic:
        return AppTheme.accentGreen;
      case SharingMode.onRequest:
        return AppTheme.accentAmber;
      case SharingMode.paused:
        return AppTheme.textSecondary;
      case SharingMode.fuzzy:
        return AppTheme.primary;
    }
  }
}
