// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTagline =>
      'Your location, only with the people who really matter.';

  @override
  String get authModeSignUp => 'Create account';

  @override
  String get authModeSignIn => 'Sign in';

  @override
  String get authNameHint => 'Your name';

  @override
  String get authEmailHint => 'Your email';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authInvalidEmail => 'Enter a valid email address.';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters.';

  @override
  String get authAccountCreated =>
      'Account created: check your email to confirm it before signing in.';

  @override
  String authGenericError(String error) {
    return 'Something went wrong. Please try again.\n$error';
  }

  @override
  String get authPrivacyHint =>
      'No one sees your location without your permission.';

  @override
  String get authBackToWebsite => 'Back to the Kinly website';

  @override
  String get welcomeCreateCircle => 'Create your circle';

  @override
  String get welcomeJoinCircle => 'I have an invite code';

  @override
  String get welcomeInviteOnlyHint =>
      'Invite-only access. No one sees your location without your permission.';

  @override
  String get navMap => 'Map';

  @override
  String get navCircles => 'Circles';

  @override
  String get navRequests => 'Requests';

  @override
  String get navProfile => 'Profile';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageEnglish => 'English';
}
