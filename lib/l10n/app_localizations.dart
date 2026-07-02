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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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

  /// No description provided for @commonCancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In it, this message translates to:
  /// **'Chiudi'**
  String get commonClose;

  /// No description provided for @commonNo.
  ///
  /// In it, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonSomeone.
  ///
  /// In it, this message translates to:
  /// **'Qualcuno'**
  String get commonSomeone;

  /// No description provided for @mapNeedCircleFirst.
  ///
  /// In it, this message translates to:
  /// **'Crea o entra in una cerchia prima.'**
  String get mapNeedCircleFirst;

  /// No description provided for @mapWhichCircleTitle.
  ///
  /// In it, this message translates to:
  /// **'In quale cerchia?'**
  String get mapWhichCircleTitle;

  /// No description provided for @mapMeetingPointAdded.
  ///
  /// In it, this message translates to:
  /// **'\"{name}\" aggiunto come punto d\'incontro.'**
  String mapMeetingPointAdded(String name);

  /// No description provided for @mapSearchHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca un indirizzo o un negozio…'**
  String get mapSearchHint;

  /// No description provided for @mapMakeMeetingPoint.
  ///
  /// In it, this message translates to:
  /// **'Rendi punto d\'incontro'**
  String get mapMakeMeetingPoint;

  /// No description provided for @mapLocationUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a rilevare la tua posizione.'**
  String get mapLocationUnavailable;

  /// No description provided for @mapSosConfirmTitle.
  ///
  /// In it, this message translates to:
  /// **'Attivare l\'SOS?'**
  String get mapSosConfirmTitle;

  /// No description provided for @mapSosConfirmBody.
  ///
  /// In it, this message translates to:
  /// **'La tua posizione esatta verrà condivisa subito con tutte le tue cerchie, anche se hai una modalità di condivisione ridotta. Nessuna registrazione audio: solo posizione.'**
  String get mapSosConfirmBody;

  /// No description provided for @mapActivateSos.
  ///
  /// In it, this message translates to:
  /// **'Attiva SOS'**
  String get mapActivateSos;

  /// No description provided for @mapLocationUnavailableForSos.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a rilevare la tua posizione per l\'SOS.'**
  String get mapLocationUnavailableForSos;

  /// No description provided for @mapSosNotSentOffline.
  ///
  /// In it, this message translates to:
  /// **'SOS non inviato (sei offline?). Imposta un numero SOS via SMS in Privacy e sicurezza per avere un piano B.'**
  String get mapSosNotSentOffline;

  /// No description provided for @mapNoInternetSosSmsTitle.
  ///
  /// In it, this message translates to:
  /// **'Niente internet: SOS via SMS?'**
  String get mapNoInternetSosSmsTitle;

  /// No description provided for @mapNoInternetSosSmsBody.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a inviare l\'SOS online. Vuoi mandare un SMS con la tua posizione a {number}?'**
  String mapNoInternetSosSmsBody(String number);

  /// No description provided for @mapPrepareSms.
  ///
  /// In it, this message translates to:
  /// **'Prepara SMS'**
  String get mapPrepareSms;

  /// No description provided for @mapWalkMeHomeActiveTitle.
  ///
  /// In it, this message translates to:
  /// **'Accompagnami attivo'**
  String get mapWalkMeHomeActiveTitle;

  /// No description provided for @mapWalkMeHomeActiveBody.
  ///
  /// In it, this message translates to:
  /// **'Se non confermi entro ~{minutes} min, la tua cerchia riceve un avviso con la tua posizione.'**
  String mapWalkMeHomeActiveBody(int minutes);

  /// No description provided for @mapArrived.
  ///
  /// In it, this message translates to:
  /// **'Sono arrivato/a'**
  String get mapArrived;

  /// No description provided for @mapWalkMeHomeTitle.
  ///
  /// In it, this message translates to:
  /// **'Accompagnami'**
  String get mapWalkMeHomeTitle;

  /// No description provided for @mapWalkMeHomeDescription.
  ///
  /// In it, this message translates to:
  /// **'Scegli in quanto tempo prevedi di arrivare: se non confermi entro quel tempo (o non entri in un\'area Casa), la tua cerchia riceve automaticamente un avviso con la tua posizione.'**
  String get mapWalkMeHomeDescription;

  /// No description provided for @mapWalkMeHomeMinutes.
  ///
  /// In it, this message translates to:
  /// **'{minutes} min'**
  String mapWalkMeHomeMinutes(int minutes);

  /// No description provided for @mapWalkMeHomeNote.
  ///
  /// In it, this message translates to:
  /// **'Nota: se il telefono chiude del tutto l\'app prima della scadenza, l\'avviso automatico potrebbe non partire.'**
  String get mapWalkMeHomeNote;

  /// No description provided for @mapCrashDetectedTitle.
  ///
  /// In it, this message translates to:
  /// **'Possibile incidente rilevato'**
  String get mapCrashDetectedTitle;

  /// No description provided for @mapCrashDetectedBody.
  ///
  /// In it, this message translates to:
  /// **'SOS automatico tra {secondsLeft} secondi. Stai bene? Annulla se è un falso allarme.'**
  String mapCrashDetectedBody(int secondsLeft);

  /// No description provided for @mapImFine.
  ///
  /// In it, this message translates to:
  /// **'Sto bene, annulla'**
  String get mapImFine;

  /// No description provided for @mapShareLocationLinkTitle.
  ///
  /// In it, this message translates to:
  /// **'Condividi la posizione con un link'**
  String get mapShareLocationLinkTitle;

  /// No description provided for @mapShareLocationLinkBody.
  ///
  /// In it, this message translates to:
  /// **'Chi riceve il link vede la tua posizione live dal browser, anche senza l\'app. Il link scade da solo.'**
  String get mapShareLocationLinkBody;

  /// No description provided for @mapDuration1h.
  ///
  /// In it, this message translates to:
  /// **'1 ora'**
  String get mapDuration1h;

  /// No description provided for @mapDuration3h.
  ///
  /// In it, this message translates to:
  /// **'3 ore'**
  String get mapDuration3h;

  /// No description provided for @mapDuration24h.
  ///
  /// In it, this message translates to:
  /// **'24 ore'**
  String get mapDuration24h;

  /// No description provided for @mapShareLiveMessage.
  ///
  /// In it, this message translates to:
  /// **'Segui la mia posizione live su Kinly (valido {label}): {url}'**
  String mapShareLiveMessage(String label, String url);

  /// No description provided for @mapLinkCreateError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a creare il link. Riprova.'**
  String get mapLinkCreateError;

  /// No description provided for @mapWhichCircleForMeetingPoint.
  ///
  /// In it, this message translates to:
  /// **'Per quale cerchia?'**
  String get mapWhichCircleForMeetingPoint;

  /// No description provided for @mapManageSafeZones.
  ///
  /// In it, this message translates to:
  /// **'Gestisci aree sicure'**
  String get mapManageSafeZones;

  /// No description provided for @mapYourCircle.
  ///
  /// In it, this message translates to:
  /// **'La tua cerchia'**
  String get mapYourCircle;

  /// No description provided for @mapPeopleCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{{count} persona} other{{count} persone}}'**
  String mapPeopleCount(int count);

  /// No description provided for @mapNewMeetingPointTooltip.
  ///
  /// In it, this message translates to:
  /// **'Nuovo punto d\'incontro'**
  String get mapNewMeetingPointTooltip;

  /// No description provided for @mapShareLocationLinkTooltip.
  ///
  /// In it, this message translates to:
  /// **'Condividi posizione con un link'**
  String get mapShareLocationLinkTooltip;

  /// No description provided for @mapEmptyCircleTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessuno da vedere qui ancora'**
  String get mapEmptyCircleTitle;

  /// No description provided for @mapEmptyCircleMessage.
  ///
  /// In it, this message translates to:
  /// **'Invita una persona nella cerchia per vederla sulla mappa.'**
  String get mapEmptyCircleMessage;

  /// No description provided for @mapAllCirclesChip.
  ///
  /// In it, this message translates to:
  /// **'Tutte'**
  String get mapAllCirclesChip;

  /// No description provided for @mapWebNotice.
  ///
  /// In it, this message translates to:
  /// **'Stai usando la versione web di Kinly: qui la posizione si aggiorna solo mentre questa scheda è aperta. Per il tracciamento continuo, notifiche push e sblocco biometrico serve l\'app.'**
  String get mapWebNotice;

  /// No description provided for @mapSosActiveLabel.
  ///
  /// In it, this message translates to:
  /// **'SOS attivo'**
  String get mapSosActiveLabel;

  /// No description provided for @mapActivateSosSemantic.
  ///
  /// In it, this message translates to:
  /// **'Attiva SOS'**
  String get mapActivateSosSemantic;

  /// No description provided for @mapHelpRequestedLabel.
  ///
  /// In it, this message translates to:
  /// **'Aiuto richiesto'**
  String get mapHelpRequestedLabel;

  /// No description provided for @mapAskForHelp.
  ///
  /// In it, this message translates to:
  /// **'Chiedi aiuto'**
  String get mapAskForHelp;

  /// No description provided for @mapWalkMeHomeActiveLabel.
  ///
  /// In it, this message translates to:
  /// **'Accompagnami attivo'**
  String get mapWalkMeHomeActiveLabel;

  /// No description provided for @mapWalkMeHomeSemantic.
  ///
  /// In it, this message translates to:
  /// **'Accompagnami'**
  String get mapWalkMeHomeSemantic;

  /// No description provided for @mapSosBannerText.
  ///
  /// In it, this message translates to:
  /// **'{personName} ha attivato l\'SOS · tocca per vedere dove si trova'**
  String mapSosBannerText(String personName);

  /// No description provided for @mapHelpBannerText.
  ///
  /// In it, this message translates to:
  /// **'{personName} ha bisogno di aiuto ({reason}) · tocca per i dettagli'**
  String mapHelpBannerText(String personName, String reason);

  /// No description provided for @mapWalkMeHomeBannerText.
  ///
  /// In it, this message translates to:
  /// **'Accompagnami attivo · conferma entro ~{minutes} min'**
  String mapWalkMeHomeBannerText(int minutes);

  /// No description provided for @mapHighFive.
  ///
  /// In it, this message translates to:
  /// **'High five'**
  String get mapHighFive;

  /// No description provided for @mapEncounterText.
  ///
  /// In it, this message translates to:
  /// **'Ti sei incrociato con {personName}!'**
  String mapEncounterText(String personName);

  /// No description provided for @mapShoppingAtStore.
  ///
  /// In it, this message translates to:
  /// **'{personName} è al negozio{place}'**
  String mapShoppingAtStore(String personName, String place);

  /// No description provided for @mapAskSomething.
  ///
  /// In it, this message translates to:
  /// **'Chiedi qualcosa'**
  String get mapAskSomething;

  /// No description provided for @mapShoppingHint.
  ///
  /// In it, this message translates to:
  /// **'Es. Latte!'**
  String get mapShoppingHint;

  /// No description provided for @mapTheyAskedFor.
  ///
  /// In it, this message translates to:
  /// **'Ti hanno chiesto:'**
  String get mapTheyAskedFor;

  /// No description provided for @mapShoppingRequestLine.
  ///
  /// In it, this message translates to:
  /// **'{name}: {note}'**
  String mapShoppingRequestLine(String name, String note);

  /// No description provided for @mapHelpRequestDescription.
  ///
  /// In it, this message translates to:
  /// **'Avvisa la tua cerchia con un motivo e la tua posizione attuale. A differenza dell\'SOS, non cambia la tua modalità di condivisione.'**
  String get mapHelpRequestDescription;

  /// No description provided for @mapCircleLabel.
  ///
  /// In it, this message translates to:
  /// **'Cerchia'**
  String get mapCircleLabel;

  /// No description provided for @mapReasonLabel.
  ///
  /// In it, this message translates to:
  /// **'Motivo'**
  String get mapReasonLabel;

  /// No description provided for @mapNoteHint.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi un dettaglio (opzionale)'**
  String get mapNoteHint;

  /// No description provided for @mapSendRequest.
  ///
  /// In it, this message translates to:
  /// **'Invia richiesta'**
  String get mapSendRequest;

  /// No description provided for @mapNeedCircleForHelp.
  ///
  /// In it, this message translates to:
  /// **'Crea o entra in una cerchia prima di chiedere aiuto.'**
  String get mapNeedCircleForHelp;

  /// No description provided for @mapHelpRequestSendError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a inviare la richiesta. Riprova.'**
  String get mapHelpRequestSendError;

  /// No description provided for @mapSafeZoneLabelAndRadius.
  ///
  /// In it, this message translates to:
  /// **'{kindLabel} · raggio {radius} m'**
  String mapSafeZoneLabelAndRadius(String kindLabel, int radius);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'it': return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
