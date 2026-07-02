import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it')
  ];

  /// Frase sotto il logo Kinly, in accesso e nella schermata di benvenuto.
  ///
  /// In it, this message translates to:
  /// **'La tua posizione, solo con chi conta davvero.'**
  String get appTagline;

  /// No description provided for @authModeSignUp.
  ///
  /// In it, this message translates to:
  /// **'Crea account'**
  String get authModeSignUp;

  /// No description provided for @authModeSignIn.
  ///
  /// In it, this message translates to:
  /// **'Accedi'**
  String get authModeSignIn;

  /// No description provided for @authNameHint.
  ///
  /// In it, this message translates to:
  /// **'Il tuo nome'**
  String get authNameHint;

  /// No description provided for @authEmailHint.
  ///
  /// In it, this message translates to:
  /// **'La tua email'**
  String get authEmailHint;

  /// No description provided for @authPasswordHint.
  ///
  /// In it, this message translates to:
  /// **'Password'**
  String get authPasswordHint;

  /// No description provided for @authInvalidEmail.
  ///
  /// In it, this message translates to:
  /// **'Inserisci un indirizzo email valido.'**
  String get authInvalidEmail;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In it, this message translates to:
  /// **'La password deve avere almeno 6 caratteri.'**
  String get authPasswordTooShort;

  /// No description provided for @authAccountCreated.
  ///
  /// In it, this message translates to:
  /// **'Account creato: controlla la tua email per confermarlo prima di accedere.'**
  String get authAccountCreated;

  /// No description provided for @authGenericError.
  ///
  /// In it, this message translates to:
  /// **'Qualcosa è andato storto. Riprova.\n{error}'**
  String authGenericError(String error);

  /// No description provided for @authPrivacyHint.
  ///
  /// In it, this message translates to:
  /// **'Nessuno vede la tua posizione senza il tuo permesso.'**
  String get authPrivacyHint;

  /// No description provided for @authBackToWebsite.
  ///
  /// In it, this message translates to:
  /// **'Torna al sito Kinly'**
  String get authBackToWebsite;

  /// No description provided for @welcomeCreateCircle.
  ///
  /// In it, this message translates to:
  /// **'Crea la tua cerchia'**
  String get welcomeCreateCircle;

  /// No description provided for @welcomeJoinCircle.
  ///
  /// In it, this message translates to:
  /// **'Ho un codice di invito'**
  String get welcomeJoinCircle;

  /// No description provided for @welcomeInviteOnlyHint.
  ///
  /// In it, this message translates to:
  /// **'Accesso solo su invito. Nessuno vede la tua posizione senza il tuo permesso.'**
  String get welcomeInviteOnlyHint;

  /// No description provided for @navMap.
  ///
  /// In it, this message translates to:
  /// **'Mappa'**
  String get navMap;

  /// No description provided for @navCircles.
  ///
  /// In it, this message translates to:
  /// **'Cerchie'**
  String get navCircles;

  /// No description provided for @navRequests.
  ///
  /// In it, this message translates to:
  /// **'Richieste'**
  String get navRequests;

  /// No description provided for @navProfile.
  ///
  /// In it, this message translates to:
  /// **'Profilo'**
  String get navProfile;

  /// No description provided for @languageSectionTitle.
  ///
  /// In it, this message translates to:
  /// **'Lingua'**
  String get languageSectionTitle;

  /// No description provided for @languageSystem.
  ///
  /// In it, this message translates to:
  /// **'Sistema'**
  String get languageSystem;

  /// No description provided for @languageItalian.
  ///
  /// In it, this message translates to:
  /// **'Italiano'**
  String get languageItalian;

  /// No description provided for @languageEnglish.
  ///
  /// In it, this message translates to:
  /// **'English'**
  String get languageEnglish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
