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

  /// No description provided for @circlesTitle.
  ///
  /// In it, this message translates to:
  /// **'Le tue cerchie'**
  String get circlesTitle;

  /// No description provided for @circlesAddTitle.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi una cerchia'**
  String get circlesAddTitle;

  /// No description provided for @circlesCreateNew.
  ///
  /// In it, this message translates to:
  /// **'Crea una nuova cerchia'**
  String get circlesCreateNew;

  /// No description provided for @circlesHaveInviteCode.
  ///
  /// In it, this message translates to:
  /// **'Ho un codice di invito'**
  String get circlesHaveInviteCode;

  /// No description provided for @circlesJoinedSnackbar.
  ///
  /// In it, this message translates to:
  /// **'Sei entrato in \"{name}\"'**
  String circlesJoinedSnackbar(String name);

  /// No description provided for @circlesYourModeInTitle.
  ///
  /// In it, this message translates to:
  /// **'La tua modalità in \"{name}\"'**
  String circlesYourModeInTitle(String name);

  /// No description provided for @circlesModeOverrideHint.
  ///
  /// In it, this message translates to:
  /// **'Vale solo per questa cerchia: nelle altre resta quella generale del tuo profilo.'**
  String get circlesModeOverrideHint;

  /// No description provided for @circlesUseGeneralMode.
  ///
  /// In it, this message translates to:
  /// **'Usa la modalità generale'**
  String get circlesUseGeneralMode;

  /// No description provided for @circlesGeneralModeDescription.
  ///
  /// In it, this message translates to:
  /// **'Quella scelta nel tuo profilo ({modeLabel}).'**
  String circlesGeneralModeDescription(String modeLabel);

  /// No description provided for @circlesAnomalyStillAt.
  ///
  /// In it, this message translates to:
  /// **'{name} è ancora {zoneName}'**
  String circlesAnomalyStillAt(String name, String zoneName);

  /// No description provided for @circlesAnomalyLate.
  ///
  /// In it, this message translates to:
  /// **'Di solito esce entro le {expected} · {minutes} min di ritardo'**
  String circlesAnomalyLate(String expected, int minutes);

  /// No description provided for @circlesInviteCodeCopied.
  ///
  /// In it, this message translates to:
  /// **'Codice invito copiato'**
  String get circlesInviteCodeCopied;

  /// No description provided for @circlesActionInvite.
  ///
  /// In it, this message translates to:
  /// **'Invita'**
  String get circlesActionInvite;

  /// No description provided for @circlesInviteShareMessage.
  ///
  /// In it, this message translates to:
  /// **'Entra nella mia cerchia \"{circleName}\" su Kinly!\n\nCodice di invito: {inviteCode}\n\nApri Kinly e tocca \"Ho un codice di invito\", oppure tocca: kinly://join/{inviteCode}'**
  String circlesInviteShareMessage(String circleName, String inviteCode);

  /// No description provided for @circlesActionSafeZones.
  ///
  /// In it, this message translates to:
  /// **'Aree sicure'**
  String get circlesActionSafeZones;

  /// No description provided for @circlesActionMeetingPoint.
  ///
  /// In it, this message translates to:
  /// **'Punto d\'incontro'**
  String get circlesActionMeetingPoint;

  /// No description provided for @circlesActionMessages.
  ///
  /// In it, this message translates to:
  /// **'Messaggi'**
  String get circlesActionMessages;

  /// No description provided for @circlesActionExpenses.
  ///
  /// In it, this message translates to:
  /// **'Spese'**
  String get circlesActionExpenses;

  /// No description provided for @circlesActionSummary.
  ///
  /// In it, this message translates to:
  /// **'Riepilogo'**
  String get circlesActionSummary;

  /// No description provided for @circlesActionYourMode.
  ///
  /// In it, this message translates to:
  /// **'La tua modalità'**
  String get circlesActionYourMode;

  /// No description provided for @circlesCoachStep1Title.
  ///
  /// In it, this message translates to:
  /// **'La tua cerchia'**
  String get circlesCoachStep1Title;

  /// No description provided for @circlesCoachStep1Body.
  ///
  /// In it, this message translates to:
  /// **'Ogni cerchia ha i suoi membri, la sua icona e le sue impostazioni: puoi averne più di una.'**
  String get circlesCoachStep1Body;

  /// No description provided for @circlesCoachStep2Title.
  ///
  /// In it, this message translates to:
  /// **'Le azioni della cerchia'**
  String get circlesCoachStep2Title;

  /// No description provided for @circlesCoachStep2Body.
  ///
  /// In it, this message translates to:
  /// **'Da qui gestisci aree sicure, punto d\'incontro, messaggi, spese di gruppo e il riepilogo settimanale.'**
  String get circlesCoachStep2Body;

  /// No description provided for @circlesCoachStep3Title.
  ///
  /// In it, this message translates to:
  /// **'Codice di invito'**
  String get circlesCoachStep3Title;

  /// No description provided for @circlesCoachStep3Body.
  ///
  /// In it, this message translates to:
  /// **'Tocca per copiarlo: solo chi lo riceve da te può entrare in questa cerchia.'**
  String get circlesCoachStep3Body;

  /// No description provided for @circlesCoachSkip.
  ///
  /// In it, this message translates to:
  /// **'Salta'**
  String get circlesCoachSkip;

  /// No description provided for @circlesCoachNext.
  ///
  /// In it, this message translates to:
  /// **'Avanti'**
  String get circlesCoachNext;

  /// No description provided for @circlesCoachFinish.
  ///
  /// In it, this message translates to:
  /// **'Fine'**
  String get circlesCoachFinish;

  /// No description provided for @meetingPointTitle.
  ///
  /// In it, this message translates to:
  /// **'Punto d\'incontro'**
  String get meetingPointTitle;

  /// No description provided for @meetingPointDeleteTooltip.
  ///
  /// In it, this message translates to:
  /// **'Elimina punto d\'incontro'**
  String get meetingPointDeleteTooltip;

  /// No description provided for @meetingPointCreateButton.
  ///
  /// In it, this message translates to:
  /// **'Crea punto'**
  String get meetingPointCreateButton;

  /// No description provided for @meetingPointEmptyTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessun punto d\'incontro'**
  String get meetingPointEmptyTitle;

  /// No description provided for @meetingPointEmptyMessage.
  ///
  /// In it, this message translates to:
  /// **'Proponi un luogo dove ritrovarvi: tutti vedranno la propria distanza in tempo reale, senza scriversi \"dove sei?\".'**
  String get meetingPointEmptyMessage;

  /// No description provided for @meetingPointMarkArrived.
  ///
  /// In it, this message translates to:
  /// **'Segna il mio arrivo'**
  String get meetingPointMarkArrived;

  /// No description provided for @meetingPointWhoArriving.
  ///
  /// In it, this message translates to:
  /// **'Chi sta arrivando'**
  String get meetingPointWhoArriving;

  /// No description provided for @meetingPointScheduledAt.
  ///
  /// In it, this message translates to:
  /// **'Ore {time} · {date}'**
  String meetingPointScheduledAt(String time, String date);

  /// No description provided for @meetingPointArrived.
  ///
  /// In it, this message translates to:
  /// **'Arrivato/a'**
  String get meetingPointArrived;

  /// No description provided for @meetingPointPositionUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Posizione non disponibile'**
  String get meetingPointPositionUnavailable;

  /// No description provided for @meetingPointEtaMinutes.
  ///
  /// In it, this message translates to:
  /// **'~{minutes} min in auto'**
  String meetingPointEtaMinutes(int minutes);

  /// No description provided for @meetingPointNewTitle.
  ///
  /// In it, this message translates to:
  /// **'Nuovo punto d\'incontro'**
  String get meetingPointNewTitle;

  /// No description provided for @meetingPointSearchHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca un luogo o un indirizzo…'**
  String get meetingPointSearchHint;

  /// No description provided for @meetingPointOr.
  ///
  /// In it, this message translates to:
  /// **'oppure'**
  String get meetingPointOr;

  /// No description provided for @meetingPointUseMyLocation.
  ///
  /// In it, this message translates to:
  /// **'Usa la mia posizione attuale'**
  String get meetingPointUseMyLocation;

  /// No description provided for @meetingPointPositionSet.
  ///
  /// In it, this message translates to:
  /// **'Posizione impostata'**
  String get meetingPointPositionSet;

  /// No description provided for @meetingPointNameHint.
  ///
  /// In it, this message translates to:
  /// **'Nome (es. Ingresso stadio, Bar Roma)'**
  String get meetingPointNameHint;

  /// No description provided for @meetingPointSetTime.
  ///
  /// In it, this message translates to:
  /// **'Imposta un orario (opzionale)'**
  String get meetingPointSetTime;

  /// No description provided for @meetingPointNoResultsFor.
  ///
  /// In it, this message translates to:
  /// **'Nessun risultato per \"{query}\".'**
  String meetingPointNoResultsFor(String query);

  /// No description provided for @meetingPointSearchFailed.
  ///
  /// In it, this message translates to:
  /// **'Ricerca non riuscita. Riprova.'**
  String get meetingPointSearchFailed;

  /// No description provided for @meetingPointLocationUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a rilevare la tua posizione.'**
  String get meetingPointLocationUnavailable;

  /// No description provided for @meetingPointChooseNameAndLocation.
  ///
  /// In it, this message translates to:
  /// **'Scegli un nome e una posizione.'**
  String get meetingPointChooseNameAndLocation;

  /// No description provided for @meetingPointCreateError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a creare il punto d\'incontro. Riprova.'**
  String get meetingPointCreateError;

  /// No description provided for @circleMessagesTitle.
  ///
  /// In it, this message translates to:
  /// **'Messaggi · {circleName}'**
  String circleMessagesTitle(String circleName);

  /// No description provided for @circleMessagesSendError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a inviare il messaggio. Riprova.'**
  String get circleMessagesSendError;

  /// No description provided for @circleMessagesDailyLimitTitle.
  ///
  /// In it, this message translates to:
  /// **'Limite giornaliero raggiunto'**
  String get circleMessagesDailyLimitTitle;

  /// No description provided for @circleMessagesDailyLimitBody.
  ///
  /// In it, this message translates to:
  /// **'Hai già inviato 5 messaggi oggi: è il limite del piano gratuito. Con Kinly+ puoi mandarne quanti vuoi.'**
  String get circleMessagesDailyLimitBody;

  /// No description provided for @circleMessagesGotIt.
  ///
  /// In it, this message translates to:
  /// **'Ho capito'**
  String get circleMessagesGotIt;

  /// No description provided for @circleMessagesDiscoverPlus.
  ///
  /// In it, this message translates to:
  /// **'Scopri Kinly+'**
  String get circleMessagesDiscoverPlus;

  /// No description provided for @circleMessagesHintPremium.
  ///
  /// In it, this message translates to:
  /// **'Solo per avvisi brevi e importanti. Per chiacchierare usa WhatsApp o un\'altra app di messaggistica.'**
  String get circleMessagesHintPremium;

  /// No description provided for @circleMessagesHintFree.
  ///
  /// In it, this message translates to:
  /// **'Solo per avvisi brevi e importanti (max 5 al giorno nel piano gratuito). Per chiacchierare usa WhatsApp o un\'altra app di messaggistica.'**
  String get circleMessagesHintFree;

  /// No description provided for @circleMessagesEmptyTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessun messaggio ancora'**
  String get circleMessagesEmptyTitle;

  /// No description provided for @circleMessagesEmptyMessage.
  ///
  /// In it, this message translates to:
  /// **'Manda il primo avviso qui sotto.'**
  String get circleMessagesEmptyMessage;

  /// No description provided for @circleMessagesTimeNow.
  ///
  /// In it, this message translates to:
  /// **'ora'**
  String get circleMessagesTimeNow;

  /// No description provided for @circleMessagesTimeMinutesAgo.
  ///
  /// In it, this message translates to:
  /// **'{minutes} min fa'**
  String circleMessagesTimeMinutesAgo(int minutes);

  /// No description provided for @circleMessagesTimeHoursAgo.
  ///
  /// In it, this message translates to:
  /// **'{hours} h fa'**
  String circleMessagesTimeHoursAgo(int hours);

  /// No description provided for @circleMessagesComposerHint.
  ///
  /// In it, this message translates to:
  /// **'Scrivi un avviso breve...'**
  String get circleMessagesComposerHint;

  /// No description provided for @quickMessage1.
  ///
  /// In it, this message translates to:
  /// **'Sto arrivando 🚗'**
  String get quickMessage1;

  /// No description provided for @quickMessage2.
  ///
  /// In it, this message translates to:
  /// **'Sono in ritardo ⏰'**
  String get quickMessage2;

  /// No description provided for @quickMessage3.
  ///
  /// In it, this message translates to:
  /// **'Sono arrivato/a 🏠'**
  String get quickMessage3;

  /// No description provided for @quickMessage4.
  ///
  /// In it, this message translates to:
  /// **'Tutto ok? 👋'**
  String get quickMessage4;

  /// No description provided for @quickMessage5.
  ///
  /// In it, this message translates to:
  /// **'Chiamami quando puoi 📞'**
  String get quickMessage5;

  /// No description provided for @quickMessage6.
  ///
  /// In it, this message translates to:
  /// **'Buongiorno ☀️'**
  String get quickMessage6;

  /// No description provided for @quickMessage7.
  ///
  /// In it, this message translates to:
  /// **'Buonanotte 🌙'**
  String get quickMessage7;

  /// No description provided for @quickMessage8.
  ///
  /// In it, this message translates to:
  /// **'Grazie! ❤️'**
  String get quickMessage8;

  /// No description provided for @expensesTitle.
  ///
  /// In it, this message translates to:
  /// **'Spese di gruppo'**
  String get expensesTitle;

  /// No description provided for @expensesNewButton.
  ///
  /// In it, this message translates to:
  /// **'Nuova spesa'**
  String get expensesNewButton;

  /// No description provided for @expensesEmptyTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessuna spesa'**
  String get expensesEmptyTitle;

  /// No description provided for @expensesEmptyMessage.
  ///
  /// In it, this message translates to:
  /// **'Tieni traccia di chi ha pagato cosa nella cerchia, senza scriverlo a memoria.'**
  String get expensesEmptyMessage;

  /// No description provided for @expensesBalancesTitle.
  ///
  /// In it, this message translates to:
  /// **'Saldi'**
  String get expensesBalancesTitle;

  /// No description provided for @expensesListTitle.
  ///
  /// In it, this message translates to:
  /// **'Spese'**
  String get expensesListTitle;

  /// No description provided for @expensesSetPaymentLinkHint.
  ///
  /// In it, this message translates to:
  /// **'Imposta il tuo link di pagamento in Privacy e sicurezza per farlo pagare più facilmente.'**
  String get expensesSetPaymentLinkHint;

  /// No description provided for @expensesLinkCopied.
  ///
  /// In it, this message translates to:
  /// **'Link di pagamento copiato: mandaglielo.'**
  String get expensesLinkCopied;

  /// No description provided for @expensesNoPaymentLink.
  ///
  /// In it, this message translates to:
  /// **'{name} non ha impostato un link di pagamento.'**
  String expensesNoPaymentLink(String name);

  /// No description provided for @expensesThisPerson.
  ///
  /// In it, this message translates to:
  /// **'Questa persona'**
  String get expensesThisPerson;

  /// No description provided for @expensesOwesYou.
  ///
  /// In it, this message translates to:
  /// **'{name} ti deve'**
  String expensesOwesYou(String name);

  /// No description provided for @expensesYouOwe.
  ///
  /// In it, this message translates to:
  /// **'Devi a {name}'**
  String expensesYouOwe(String name);

  /// No description provided for @expensesRequestBalance.
  ///
  /// In it, this message translates to:
  /// **'Chiedi il saldo'**
  String get expensesRequestBalance;

  /// No description provided for @expensesPay.
  ///
  /// In it, this message translates to:
  /// **'Paga'**
  String get expensesPay;

  /// No description provided for @expensesPaidBy.
  ///
  /// In it, this message translates to:
  /// **'Pagato da {name}'**
  String expensesPaidBy(String name);

  /// No description provided for @expensesFillFields.
  ///
  /// In it, this message translates to:
  /// **'Compila descrizione, importo e almeno una persona.'**
  String get expensesFillFields;

  /// No description provided for @expensesSaveError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a salvare la spesa. Riprova.'**
  String get expensesSaveError;

  /// No description provided for @expensesDailyLimitTitle.
  ///
  /// In it, this message translates to:
  /// **'Limite giornaliero raggiunto'**
  String get expensesDailyLimitTitle;

  /// No description provided for @expensesDailyLimitBody.
  ///
  /// In it, this message translates to:
  /// **'Hai già registrato 5 spese oggi: è il limite del piano gratuito. Con Kinly+ puoi registrarne quante vuoi.'**
  String get expensesDailyLimitBody;

  /// No description provided for @expensesSplitHint.
  ///
  /// In it, this message translates to:
  /// **'La paghi tu: la dividi tra le persone che selezioni qui sotto.'**
  String get expensesSplitHint;

  /// No description provided for @expensesDescriptionHint.
  ///
  /// In it, this message translates to:
  /// **'Descrizione (es. Cena, benzina)'**
  String get expensesDescriptionHint;

  /// No description provided for @expensesAmountHint.
  ///
  /// In it, this message translates to:
  /// **'Importo totale (€)'**
  String get expensesAmountHint;

  /// No description provided for @expensesSplitBetween.
  ///
  /// In it, this message translates to:
  /// **'Dividi tra'**
  String get expensesSplitBetween;

  /// No description provided for @expensesSaveButton.
  ///
  /// In it, this message translates to:
  /// **'Salva spesa'**
  String get expensesSaveButton;

  /// No description provided for @weeklySummaryTitle.
  ///
  /// In it, this message translates to:
  /// **'Riepilogo · {circleName}'**
  String weeklySummaryTitle(String circleName);

  /// No description provided for @weeklySummaryLoadError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a caricare il riepilogo.'**
  String get weeklySummaryLoadError;

  /// No description provided for @weeklySummaryRetry.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get weeklySummaryRetry;

  /// No description provided for @weeklySummaryLast7Days.
  ///
  /// In it, this message translates to:
  /// **'Ultimi 7 giorni'**
  String get weeklySummaryLast7Days;

  /// No description provided for @weeklySummaryActivityFor.
  ///
  /// In it, this message translates to:
  /// **'Attività di \"{circleName}\", visibile a tutti i membri.'**
  String weeklySummaryActivityFor(String circleName);

  /// No description provided for @weeklySummaryQuietWeek.
  ///
  /// In it, this message translates to:
  /// **'Settimana tranquilla: nessun evento da segnalare.'**
  String get weeklySummaryQuietWeek;

  /// No description provided for @weeklySummarySosActivated.
  ///
  /// In it, this message translates to:
  /// **'SOS attivati'**
  String get weeklySummarySosActivated;

  /// No description provided for @weeklySummaryHelpRequests.
  ///
  /// In it, this message translates to:
  /// **'Richieste di aiuto'**
  String get weeklySummaryHelpRequests;

  /// No description provided for @weeklySummarySafeZoneEntries.
  ///
  /// In it, this message translates to:
  /// **'Ingressi in aree sicure'**
  String get weeklySummarySafeZoneEntries;

  /// No description provided for @weeklySummarySpeedAlerts.
  ///
  /// In it, this message translates to:
  /// **'Avvisi di velocità'**
  String get weeklySummarySpeedAlerts;

  /// No description provided for @weeklySummaryPushHint.
  ///
  /// In it, this message translates to:
  /// **'Puoi ricevere questo riepilogo anche via notifica una volta a settimana: attivalo da Profilo → Privacy e sicurezza.'**
  String get weeklySummaryPushHint;

  /// No description provided for @requestsIncoming.
  ///
  /// In it, this message translates to:
  /// **'In arrivo'**
  String get requestsIncoming;

  /// No description provided for @requestsWaitingReply.
  ///
  /// In it, this message translates to:
  /// **'In attesa di risposta'**
  String get requestsWaitingReply;

  /// No description provided for @requestsHistory.
  ///
  /// In it, this message translates to:
  /// **'Storico'**
  String get requestsHistory;

  /// No description provided for @requestsWantsToSeeYou.
  ///
  /// In it, this message translates to:
  /// **'{name} vuole vedere dove sei'**
  String requestsWantsToSeeYou(String name);

  /// No description provided for @requestsReject.
  ///
  /// In it, this message translates to:
  /// **'Rifiuta'**
  String get requestsReject;

  /// No description provided for @requestsApprove.
  ///
  /// In it, this message translates to:
  /// **'Approva'**
  String get requestsApprove;

  /// No description provided for @requestsWaitingFor.
  ///
  /// In it, this message translates to:
  /// **'In attesa di {name}'**
  String requestsWaitingFor(String name);

  /// No description provided for @requestsNotifyOnReply.
  ///
  /// In it, this message translates to:
  /// **'Riceverai una notifica alla risposta'**
  String get requestsNotifyOnReply;

  /// No description provided for @requestsTheyAskedYou.
  ///
  /// In it, this message translates to:
  /// **'{name} ti ha chiesto la posizione'**
  String requestsTheyAskedYou(String name);

  /// No description provided for @requestsYouAsked.
  ///
  /// In it, this message translates to:
  /// **'Hai chiesto la posizione a {name}'**
  String requestsYouAsked(String name);

  /// No description provided for @requestsEmptyTitle.
  ///
  /// In it, this message translates to:
  /// **'Nessuna richiesta'**
  String get requestsEmptyTitle;

  /// No description provided for @requestsEmptyMessage.
  ///
  /// In it, this message translates to:
  /// **'Quando qualcuno vorrà vedere la tua posizione, o tu quella di qualcun altro, la richiesta apparirà qui.'**
  String get requestsEmptyMessage;
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
