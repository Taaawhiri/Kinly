// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTagline => 'La tua posizione, solo con chi conta davvero.';

  @override
  String get authModeSignUp => 'Crea account';

  @override
  String get authModeSignIn => 'Accedi';

  @override
  String get authNameHint => 'Il tuo nome';

  @override
  String get authEmailHint => 'La tua email';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authInvalidEmail => 'Inserisci un indirizzo email valido.';

  @override
  String get authPasswordTooShort =>
      'La password deve avere almeno 6 caratteri.';

  @override
  String get authAccountCreated =>
      'Account creato: controlla la tua email per confermarlo prima di accedere.';

  @override
  String authGenericError(String error) {
    return 'Qualcosa è andato storto. Riprova.\n$error';
  }

  @override
  String get authPrivacyHint =>
      'Nessuno vede la tua posizione senza il tuo permesso.';

  @override
  String get authBackToWebsite => 'Torna al sito Kinly';

  @override
  String get welcomeCreateCircle => 'Crea la tua cerchia';

  @override
  String get welcomeJoinCircle => 'Ho un codice di invito';

  @override
  String get welcomeInviteOnlyHint =>
      'Accesso solo su invito. Nessuno vede la tua posizione senza il tuo permesso.';

  @override
  String get navMap => 'Mappa';

  @override
  String get navCircles => 'Cerchie';

  @override
  String get navRequests => 'Richieste';

  @override
  String get navProfile => 'Profilo';

  @override
  String get languageSectionTitle => 'Lingua';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageEnglish => 'English';
}
