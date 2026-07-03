import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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

  String label(AppLocalizations l10n) {
    switch (this) {
      case SharingMode.automatic:
        return l10n.sharingModeAutomatic;
      case SharingMode.onRequest:
        return l10n.sharingModeOnRequest;
      case SharingMode.paused:
        return l10n.sharingModePaused;
      case SharingMode.fuzzy:
        return l10n.sharingModeFuzzy;
    }
  }

  String description(AppLocalizations l10n) {
    switch (this) {
      case SharingMode.automatic:
        return l10n.sharingModeAutomaticDesc;
      case SharingMode.onRequest:
        return l10n.sharingModeOnRequestDesc;
      case SharingMode.paused:
        return l10n.sharingModePausedDesc;
      case SharingMode.fuzzy:
        return l10n.sharingModeFuzzyDesc;
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
