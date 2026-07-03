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

  /// No description provided for @languagePickerTitle.
  ///
  /// In it, this message translates to:
  /// **'Scegli la lingua'**
  String get languagePickerTitle;

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

  /// No description provided for @commonSave.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get commonSave;

  /// No description provided for @commonRemove.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi'**
  String get commonRemove;

  /// No description provided for @commonNotNow.
  ///
  /// In it, this message translates to:
  /// **'Non ora'**
  String get commonNotNow;

  /// No description provided for @commonActivate.
  ///
  /// In it, this message translates to:
  /// **'Attiva'**
  String get commonActivate;

  /// No description provided for @commonDone.
  ///
  /// In it, this message translates to:
  /// **'Fatto'**
  String get commonDone;

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
  /// **'Stai usando la versione web (compagna) di Kinly: qui la posizione si aggiorna solo mentre questa scheda è aperta.'**
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

  /// No description provided for @profileStatusFriends.
  ///
  /// In it, this message translates to:
  /// **'Con amici'**
  String get profileStatusFriends;

  /// No description provided for @profileStatusHome.
  ///
  /// In it, this message translates to:
  /// **'A casa'**
  String get profileStatusHome;

  /// No description provided for @profileStatusFree.
  ///
  /// In it, this message translates to:
  /// **'Libero/a'**
  String get profileStatusFree;

  /// No description provided for @profileStatusBusyDay.
  ///
  /// In it, this message translates to:
  /// **'Giornata pesante'**
  String get profileStatusBusyDay;

  /// No description provided for @profileStatusPickerTitle.
  ///
  /// In it, this message translates to:
  /// **'Il tuo stato di oggi'**
  String get profileStatusPickerTitle;

  /// No description provided for @profileStatusPickerHint.
  ///
  /// In it, this message translates to:
  /// **'Visibile alla tua cerchia sulla mappa fino a stanotte.'**
  String get profileStatusPickerHint;

  /// No description provided for @profileStatusCustomHint.
  ///
  /// In it, this message translates to:
  /// **'Oppure scrivi il tuo (con emoji 🙂)'**
  String get profileStatusCustomHint;

  /// No description provided for @profileRemoveStatus.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi stato'**
  String get profileRemoveStatus;

  /// No description provided for @profileActiveCircles.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{{count} cerchia attiva} other{{count} cerchie attive}}'**
  String profileActiveCircles(int count);

  /// No description provided for @profileYourStatus.
  ///
  /// In it, this message translates to:
  /// **'Il tuo stato'**
  String get profileYourStatus;

  /// No description provided for @profileAppearance.
  ///
  /// In it, this message translates to:
  /// **'Aspetto'**
  String get profileAppearance;

  /// No description provided for @profileThemeLight.
  ///
  /// In it, this message translates to:
  /// **'Chiaro'**
  String get profileThemeLight;

  /// No description provided for @profileThemeDark.
  ///
  /// In it, this message translates to:
  /// **'Scuro'**
  String get profileThemeDark;

  /// No description provided for @profileSharingModeHeader.
  ///
  /// In it, this message translates to:
  /// **'Modalità di condivisione'**
  String get profileSharingModeHeader;

  /// No description provided for @profileYourCirclesHeader.
  ///
  /// In it, this message translates to:
  /// **'Le tue cerchie'**
  String get profileYourCirclesHeader;

  /// No description provided for @profileCirclesManage.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{{count} cerchia · gestisci membri e inviti} other{{count} cerchie · gestisci membri e inviti}}'**
  String profileCirclesManage(int count);

  /// No description provided for @profileKinlyPlusHeader.
  ///
  /// In it, this message translates to:
  /// **'Kinly+'**
  String get profileKinlyPlusHeader;

  /// No description provided for @profileActive.
  ///
  /// In it, this message translates to:
  /// **'Attivo'**
  String get profileActive;

  /// No description provided for @profileNotActive.
  ///
  /// In it, this message translates to:
  /// **'Non attivo'**
  String get profileNotActive;

  /// No description provided for @profileManageSubscription.
  ///
  /// In it, this message translates to:
  /// **'Gestisci abbonamento Kinly+'**
  String get profileManageSubscription;

  /// No description provided for @profileOtherHeader.
  ///
  /// In it, this message translates to:
  /// **'Altro'**
  String get profileOtherHeader;

  /// No description provided for @profilePrivacySecurity.
  ///
  /// In it, this message translates to:
  /// **'Privacy e sicurezza'**
  String get profilePrivacySecurity;

  /// No description provided for @profileHelpSupport.
  ///
  /// In it, this message translates to:
  /// **'Aiuto e assistenza'**
  String get profileHelpSupport;

  /// No description provided for @profileAdminSupport.
  ///
  /// In it, this message translates to:
  /// **'Assistenza · admin'**
  String get profileAdminSupport;

  /// No description provided for @profileReviewOnboarding.
  ///
  /// In it, this message translates to:
  /// **'Rivedi onboarding · admin (test)'**
  String get profileReviewOnboarding;

  /// No description provided for @profileLogout.
  ///
  /// In it, this message translates to:
  /// **'Esci'**
  String get profileLogout;

  /// No description provided for @profileFeatureLocationHistoryTitle.
  ///
  /// In it, this message translates to:
  /// **'Cronologia posizioni'**
  String get profileFeatureLocationHistoryTitle;

  /// No description provided for @profileFeatureLocationHistoryDesc.
  ///
  /// In it, this message translates to:
  /// **'Rivedi dove sono stati i membri della cerchia nei giorni passati.'**
  String get profileFeatureLocationHistoryDesc;

  /// No description provided for @profileFeatureSafeZonesTitle.
  ///
  /// In it, this message translates to:
  /// **'Aree sicure'**
  String get profileFeatureSafeZonesTitle;

  /// No description provided for @profileFeatureSafeZonesDesc.
  ///
  /// In it, this message translates to:
  /// **'Casa, lavoro, scuola: notifica personalizzata a ogni arrivo o uscita.'**
  String get profileFeatureSafeZonesDesc;

  /// No description provided for @profileFeatureDrivingAlertsTitle.
  ///
  /// In it, this message translates to:
  /// **'Avvisi di guida'**
  String get profileFeatureDrivingAlertsTitle;

  /// No description provided for @profileFeatureDrivingAlertsDesc.
  ///
  /// In it, this message translates to:
  /// **'Sappi quando chi guida supera un limite di velocità impostato.'**
  String get profileFeatureDrivingAlertsDesc;

  /// No description provided for @profileFeatureBackgroundTrackingTitle.
  ///
  /// In it, this message translates to:
  /// **'Tracciamento in background'**
  String get profileFeatureBackgroundTrackingTitle;

  /// No description provided for @profileFeatureBackgroundTrackingDesc.
  ///
  /// In it, this message translates to:
  /// **'La posizione continua ad aggiornarsi anche con l\'app chiusa.'**
  String get profileFeatureBackgroundTrackingDesc;

  /// No description provided for @profileFeatureUnlimitedTitle.
  ///
  /// In it, this message translates to:
  /// **'Messaggi, ping e spese illimitati'**
  String get profileFeatureUnlimitedTitle;

  /// No description provided for @profileFeatureUnlimitedDesc.
  ///
  /// In it, this message translates to:
  /// **'Manda quanti messaggi, ping e spese vuoi, senza limiti.'**
  String get profileFeatureUnlimitedDesc;

  /// No description provided for @profileFeatureShoppingTitle.
  ///
  /// In it, this message translates to:
  /// **'Portami qualcosa'**
  String get profileFeatureShoppingTitle;

  /// No description provided for @profileFeatureShoppingDesc.
  ///
  /// In it, this message translates to:
  /// **'Segnala alla cerchia quando sei al supermercato o al bar.'**
  String get profileFeatureShoppingDesc;

  /// No description provided for @profileFeaturePrioritySupportTitle.
  ///
  /// In it, this message translates to:
  /// **'Assistenza prioritaria'**
  String get profileFeaturePrioritySupportTitle;

  /// No description provided for @profileFeaturePrioritySupportDesc.
  ///
  /// In it, this message translates to:
  /// **'Supporto dedicato per la tua cerchia, 7 giorni su 7.'**
  String get profileFeaturePrioritySupportDesc;

  /// No description provided for @privacyTitle.
  ///
  /// In it, this message translates to:
  /// **'Privacy e sicurezza'**
  String get privacyTitle;

  /// No description provided for @privacyLocationVisibilityInfo.
  ///
  /// In it, this message translates to:
  /// **'La tua posizione è visibile solo a chi fa parte di una tua cerchia, e solo secondo la modalità di condivisione che scegli dal profilo (automatica, su richiesta o sospesa).'**
  String get privacyLocationVisibilityInfo;

  /// No description provided for @privacySosSmsNumberTitle.
  ///
  /// In it, this message translates to:
  /// **'Numero SOS via SMS'**
  String get privacySosSmsNumberTitle;

  /// No description provided for @privacyPhoneExampleHint.
  ///
  /// In it, this message translates to:
  /// **'Es. +39 333 1234567'**
  String get privacyPhoneExampleHint;

  /// No description provided for @privacyPlusFeatureTitle.
  ///
  /// In it, this message translates to:
  /// **'Funzione Kinly+'**
  String get privacyPlusFeatureTitle;

  /// No description provided for @privacyCrashDetectionPlusBody.
  ///
  /// In it, this message translates to:
  /// **'Il rilevamento incidenti (SOS automatico dopo un urto violento in auto) è un vantaggio Kinly+.'**
  String get privacyCrashDetectionPlusBody;

  /// No description provided for @privacyBackgroundTrackingPlusBody.
  ///
  /// In it, this message translates to:
  /// **'Il tracciamento in background (la posizione continua ad aggiornarsi anche con l\'app chiusa) è un vantaggio Kinly+.'**
  String get privacyBackgroundTrackingPlusBody;

  /// No description provided for @privacyEnableBackgroundTrackingTitle.
  ///
  /// In it, this message translates to:
  /// **'Attivare il tracciamento in background?'**
  String get privacyEnableBackgroundTrackingTitle;

  /// No description provided for @privacyEnableBackgroundTrackingBody.
  ///
  /// In it, this message translates to:
  /// **'La tua posizione continuerà ad aggiornarsi anche quando Kinly non è in primo piano. Consuma più batteria e mostra sempre una notifica fissa mentre è attivo, come richiesto da Android.'**
  String get privacyEnableBackgroundTrackingBody;

  /// No description provided for @privacyExtraStepTitle.
  ///
  /// In it, this message translates to:
  /// **'Serve un passaggio in più'**
  String get privacyExtraStepTitle;

  /// No description provided for @privacyExtraStepBody.
  ///
  /// In it, this message translates to:
  /// **'Il tuo Android richiede di attivare a mano il permesso di posizione \"Consenti sempre\" dalle impostazioni di sistema, poi torna qui e riattiva l\'interruttore.'**
  String get privacyExtraStepBody;

  /// No description provided for @privacyOpenSettings.
  ///
  /// In it, this message translates to:
  /// **'Apri impostazioni'**
  String get privacyOpenSettings;

  /// No description provided for @privacyGrantLocationFirst.
  ///
  /// In it, this message translates to:
  /// **'Prima serve concedere il permesso di posizione a Kinly.'**
  String get privacyGrantLocationFirst;

  /// No description provided for @privacyBiometricAuthFailed.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a verificare la tua identità.'**
  String get privacyBiometricAuthFailed;

  /// No description provided for @privacyOtherDevicesSignedOut.
  ///
  /// In it, this message translates to:
  /// **'Tutti gli altri dispositivi sono stati disconnessi.'**
  String get privacyOtherDevicesSignedOut;

  /// No description provided for @privacyOperationFailed.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a completare l\'operazione. Riprova.'**
  String get privacyOperationFailed;

  /// No description provided for @privacyBirthdayTitle.
  ///
  /// In it, this message translates to:
  /// **'Data di nascita'**
  String get privacyBirthdayTitle;

  /// No description provided for @privacyDateHint.
  ///
  /// In it, this message translates to:
  /// **'GG/MM/AAAA'**
  String get privacyDateHint;

  /// No description provided for @privacyInvalidDate.
  ///
  /// In it, this message translates to:
  /// **'Data non valida'**
  String get privacyInvalidDate;

  /// No description provided for @privacyPaymentLinkTitle.
  ///
  /// In it, this message translates to:
  /// **'Link di pagamento'**
  String get privacyPaymentLinkTitle;

  /// No description provided for @privacyPaymentLinkHint.
  ///
  /// In it, this message translates to:
  /// **'Es. link Satispay, PayPal.me/...'**
  String get privacyPaymentLinkHint;

  /// No description provided for @privacyPhoneNumberTitle.
  ///
  /// In it, this message translates to:
  /// **'Numero di telefono'**
  String get privacyPhoneNumberTitle;

  /// No description provided for @privacyAccountHeader.
  ///
  /// In it, this message translates to:
  /// **'Account'**
  String get privacyAccountHeader;

  /// No description provided for @privacyPersonalInfoHeader.
  ///
  /// In it, this message translates to:
  /// **'Info personali'**
  String get privacyPersonalInfoHeader;

  /// No description provided for @privacyBiometricHeader.
  ///
  /// In it, this message translates to:
  /// **'Accesso biometrico'**
  String get privacyBiometricHeader;

  /// No description provided for @privacyBackgroundTrackingHeader.
  ///
  /// In it, this message translates to:
  /// **'Tracciamento in background'**
  String get privacyBackgroundTrackingHeader;

  /// No description provided for @privacyGhostScheduleHeader.
  ///
  /// In it, this message translates to:
  /// **'Orario di reperibilità'**
  String get privacyGhostScheduleHeader;

  /// No description provided for @privacySosHeader.
  ///
  /// In it, this message translates to:
  /// **'SOS'**
  String get privacySosHeader;

  /// No description provided for @privacySpeedAlertHeader.
  ///
  /// In it, this message translates to:
  /// **'Avviso di velocità'**
  String get privacySpeedAlertHeader;

  /// No description provided for @privacyWeeklySummaryHeader.
  ///
  /// In it, this message translates to:
  /// **'Riepilogo settimanale'**
  String get privacyWeeklySummaryHeader;

  /// No description provided for @privacyGuideHeader.
  ///
  /// In it, this message translates to:
  /// **'Guida'**
  String get privacyGuideHeader;

  /// No description provided for @privacyChangePassword.
  ///
  /// In it, this message translates to:
  /// **'Cambia password'**
  String get privacyChangePassword;

  /// No description provided for @privacySignOutOtherDevices.
  ///
  /// In it, this message translates to:
  /// **'Esci dagli altri dispositivi'**
  String get privacySignOutOtherDevices;

  /// No description provided for @privacyPersonalInfoHint.
  ///
  /// In it, this message translates to:
  /// **'Facoltative: usate solo per un\'iconcina di compleanno tra i membri della cerchia, per aprire un pagamento diretto dalle spese di gruppo e per farti chiamare da chi riceve un tuo SOS o richiesta di aiuto.'**
  String get privacyPersonalInfoHint;

  /// No description provided for @privacyAddBirthday.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi data di nascita'**
  String get privacyAddBirthday;

  /// No description provided for @privacyBirthdaySet.
  ///
  /// In it, this message translates to:
  /// **'Compleanno: {date}'**
  String privacyBirthdaySet(String date);

  /// No description provided for @privacyAddPaymentLink.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi link di pagamento'**
  String get privacyAddPaymentLink;

  /// No description provided for @privacyPaymentLinkSet.
  ///
  /// In it, this message translates to:
  /// **'Link di pagamento impostato'**
  String get privacyPaymentLinkSet;

  /// No description provided for @privacyAddPhoneNumber.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi numero di telefono'**
  String get privacyAddPhoneNumber;

  /// No description provided for @privacyPhoneNumberSet.
  ///
  /// In it, this message translates to:
  /// **'Numero: {phone}'**
  String privacyPhoneNumberSet(String phone);

  /// No description provided for @privacyBiometricHint.
  ///
  /// In it, this message translates to:
  /// **'Richiedi impronta, volto o codice del dispositivo ogni volta che apri Kinly.'**
  String get privacyBiometricHint;

  /// No description provided for @privacyBiometricUnlock.
  ///
  /// In it, this message translates to:
  /// **'Sblocco biometrico'**
  String get privacyBiometricUnlock;

  /// No description provided for @privacyBackgroundTrackingHint.
  ///
  /// In it, this message translates to:
  /// **'Per impostazione predefinita Kinly aggiorna la tua posizione solo mentre è aperta. Attivalo per farla continuare anche in background: consuma più batteria e mostra sempre una notifica fissa mentre è attivo.'**
  String get privacyBackgroundTrackingHint;

  /// No description provided for @privacyEnableInBackground.
  ///
  /// In it, this message translates to:
  /// **'Attiva in background'**
  String get privacyEnableInBackground;

  /// No description provided for @privacyGhostScheduleHint.
  ///
  /// In it, this message translates to:
  /// **'Utile per il lavoro: fuori da questa fascia oraria nessuno vede la tua posizione, in nessuna delle tue cerchie (\"clock-out\" automatico).'**
  String get privacyGhostScheduleHint;

  /// No description provided for @privacyLimitHours.
  ///
  /// In it, this message translates to:
  /// **'Limita l\'orario'**
  String get privacyLimitHours;

  /// No description provided for @privacyFrom.
  ///
  /// In it, this message translates to:
  /// **'Dalle'**
  String get privacyFrom;

  /// No description provided for @privacyTo.
  ///
  /// In it, this message translates to:
  /// **'Alle'**
  String get privacyTo;

  /// No description provided for @privacySosAllCircles.
  ///
  /// In it, this message translates to:
  /// **'Per ora avvisa tutte le tue cerchie. Puoi scegliere solo alcune persone.'**
  String get privacySosAllCircles;

  /// No description provided for @privacySosSelectedCount.
  ///
  /// In it, this message translates to:
  /// **'Avvisa solo {count} persone scelte, non tutta la cerchia.'**
  String privacySosSelectedCount(int count);

  /// No description provided for @privacySosWhoToNotify.
  ///
  /// In it, this message translates to:
  /// **'Chi avvisare in caso di SOS'**
  String get privacySosWhoToNotify;

  /// No description provided for @privacySosSmsNumberEmpty.
  ///
  /// In it, this message translates to:
  /// **'Numero SOS via SMS (se sei offline)'**
  String get privacySosSmsNumberEmpty;

  /// No description provided for @privacySosSmsNumberSet.
  ///
  /// In it, this message translates to:
  /// **'SOS via SMS: {number}'**
  String privacySosSmsNumberSet(String number);

  /// No description provided for @privacyCrashDetectionTitle.
  ///
  /// In it, this message translates to:
  /// **'Rilevamento incidenti'**
  String get privacyCrashDetectionTitle;

  /// No description provided for @privacyCrashDetectionDesc.
  ///
  /// In it, this message translates to:
  /// **'Dopo un urto violento mentre sei in auto, parte un conto alla rovescia: se non lo annulli, SOS automatico.'**
  String get privacyCrashDetectionDesc;

  /// No description provided for @privacySpeedAlertHint.
  ///
  /// In it, this message translates to:
  /// **'Imposta una tua soglia: chi ha Kinly+ nella tua cerchia riceve un avviso se la superi guidando.'**
  String get privacySpeedAlertHint;

  /// No description provided for @privacyEnableAlert.
  ///
  /// In it, this message translates to:
  /// **'Attiva avviso'**
  String get privacyEnableAlert;

  /// No description provided for @privacyThreshold.
  ///
  /// In it, this message translates to:
  /// **'Soglia'**
  String get privacyThreshold;

  /// No description provided for @privacySpeedKmh.
  ///
  /// In it, this message translates to:
  /// **'{speed} km/h'**
  String privacySpeedKmh(int speed);

  /// No description provided for @privacyWeeklySummaryHint.
  ///
  /// In it, this message translates to:
  /// **'Una notifica alla settimana con l\'attività della cerchia: SOS, richieste di aiuto, ingressi in aree sicure, avvisi di velocità.'**
  String get privacyWeeklySummaryHint;

  /// No description provided for @privacyReceiveSummary.
  ///
  /// In it, this message translates to:
  /// **'Ricevi il riepilogo'**
  String get privacyReceiveSummary;

  /// No description provided for @privacyReviewCirclesGuide.
  ///
  /// In it, this message translates to:
  /// **'Rivedi la guida delle cerchie'**
  String get privacyReviewCirclesGuide;

  /// No description provided for @changePasswordMismatch.
  ///
  /// In it, this message translates to:
  /// **'Le due password non coincidono.'**
  String get changePasswordMismatch;

  /// No description provided for @changePasswordGenericError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a cambiare la password. Riprova.'**
  String get changePasswordGenericError;

  /// No description provided for @changePasswordDoneTitle.
  ///
  /// In it, this message translates to:
  /// **'Password aggiornata'**
  String get changePasswordDoneTitle;

  /// No description provided for @changePasswordDoneBody.
  ///
  /// In it, this message translates to:
  /// **'D\'ora in poi usa la nuova password per accedere.'**
  String get changePasswordDoneBody;

  /// No description provided for @changePasswordNew.
  ///
  /// In it, this message translates to:
  /// **'Nuova password'**
  String get changePasswordNew;

  /// No description provided for @changePasswordMinChars.
  ///
  /// In it, this message translates to:
  /// **'Almeno 6 caratteri.'**
  String get changePasswordMinChars;

  /// No description provided for @changePasswordConfirmHint.
  ///
  /// In it, this message translates to:
  /// **'Conferma password'**
  String get changePasswordConfirmHint;

  /// No description provided for @helpFaqsTitle.
  ///
  /// In it, this message translates to:
  /// **'Domande frequenti'**
  String get helpFaqsTitle;

  /// No description provided for @helpFaq1Q.
  ///
  /// In it, this message translates to:
  /// **'Chi vede la mia posizione?'**
  String get helpFaq1Q;

  /// No description provided for @helpFaq1A.
  ///
  /// In it, this message translates to:
  /// **'Solo chi fa parte di una tua cerchia, e solo se la tua modalità di condivisione lo permette (automatica, su richiesta o sospesa). Puoi cambiarla in ogni momento dal tuo profilo.'**
  String get helpFaq1A;

  /// No description provided for @helpFaq2Q.
  ///
  /// In it, this message translates to:
  /// **'Come invito qualcuno in una cerchia?'**
  String get helpFaq2Q;

  /// No description provided for @helpFaq2A.
  ///
  /// In it, this message translates to:
  /// **'Crea una cerchia dalla scheda \"Cerchie\" e condividi il codice invito che ti viene mostrato: chi lo inserisce entra subito a farne parte.'**
  String get helpFaq2A;

  /// No description provided for @helpFaq3Q.
  ///
  /// In it, this message translates to:
  /// **'Cosa cambia con Kinly+?'**
  String get helpFaq3Q;

  /// No description provided for @helpFaq3A.
  ///
  /// In it, this message translates to:
  /// **'Il piano gratuito ha un limite di 2 cerchie e 6 persone per cerchia. Kinly+ toglie i limiti e sblocca cronologia posizioni, aree sicure e avvisi di guida.'**
  String get helpFaq3A;

  /// No description provided for @helpFaq4Q.
  ///
  /// In it, this message translates to:
  /// **'Come cancello un\'area sicura o esco da una cerchia?'**
  String get helpFaq4Q;

  /// No description provided for @helpFaq4A.
  ///
  /// In it, this message translates to:
  /// **'Le aree sicure si eliminano dalla schermata \"Aree sicure\" di una cerchia (icona del cestino). Per uscire da una cerchia scrivici da qui: te ne aiutiamo a occupare a mano finché non aggiungiamo il pulsante in app.'**
  String get helpFaq4A;

  /// No description provided for @helpWriteToUs.
  ///
  /// In it, this message translates to:
  /// **'Scrivici'**
  String get helpWriteToUs;

  /// No description provided for @helpPriorityBadge.
  ///
  /// In it, this message translates to:
  /// **'Priorità Kinly+'**
  String get helpPriorityBadge;

  /// No description provided for @helpPriorityHint.
  ///
  /// In it, this message translates to:
  /// **'Come abbonato Kinly+ la tua richiesta viene messa in coda prioritaria.'**
  String get helpPriorityHint;

  /// No description provided for @helpNormalHint.
  ///
  /// In it, this message translates to:
  /// **'La tua richiesta resta qui, la leggiamo appena possibile.'**
  String get helpNormalHint;

  /// No description provided for @helpDescribeHint.
  ///
  /// In it, this message translates to:
  /// **'Descrivi il problema o la domanda...'**
  String get helpDescribeHint;

  /// No description provided for @helpSend.
  ///
  /// In it, this message translates to:
  /// **'Invia'**
  String get helpSend;

  /// No description provided for @helpSentSnackbar.
  ///
  /// In it, this message translates to:
  /// **'Messaggio inviato: lo trovi qui sotto tra le tue richieste.'**
  String get helpSentSnackbar;

  /// No description provided for @helpSendError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a inviare il messaggio. Riprova.'**
  String get helpSendError;

  /// No description provided for @helpYourRequests.
  ///
  /// In it, this message translates to:
  /// **'Le tue richieste'**
  String get helpYourRequests;

  /// No description provided for @helpNoRequestsYet.
  ///
  /// In it, this message translates to:
  /// **'Non hai ancora inviato nessuna richiesta.'**
  String get helpNoRequestsYet;

  /// No description provided for @helpStatusAnswered.
  ///
  /// In it, this message translates to:
  /// **'Risposto'**
  String get helpStatusAnswered;

  /// No description provided for @helpStatusClosed.
  ///
  /// In it, this message translates to:
  /// **'Chiuso'**
  String get helpStatusClosed;

  /// No description provided for @helpStatusInProgress.
  ///
  /// In it, this message translates to:
  /// **'In corso'**
  String get helpStatusInProgress;

  /// No description provided for @adminSupportNoMessages.
  ///
  /// In it, this message translates to:
  /// **'Nessun messaggio.'**
  String get adminSupportNoMessages;

  /// No description provided for @adminSupportPriority.
  ///
  /// In it, this message translates to:
  /// **'Priorità'**
  String get adminSupportPriority;

  /// No description provided for @adminSupportRepliedWith.
  ///
  /// In it, this message translates to:
  /// **'Risposto: {reply}'**
  String adminSupportRepliedWith(String reply);

  /// No description provided for @adminSupportReplyError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a inviare la risposta. Riprova.'**
  String get adminSupportReplyError;

  /// No description provided for @adminSupportReplyTitle.
  ///
  /// In it, this message translates to:
  /// **'Rispondi'**
  String get adminSupportReplyTitle;

  /// No description provided for @adminSupportReplyHint.
  ///
  /// In it, this message translates to:
  /// **'Scrivi la risposta...'**
  String get adminSupportReplyHint;

  /// No description provided for @adminSupportSendReply.
  ///
  /// In it, this message translates to:
  /// **'Invia risposta'**
  String get adminSupportSendReply;

  /// No description provided for @avatarUploadError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a caricare la foto. Riprova.'**
  String get avatarUploadError;

  /// No description provided for @avatarChooseFromGallery.
  ///
  /// In it, this message translates to:
  /// **'Scegli dalla galleria'**
  String get avatarChooseFromGallery;

  /// No description provided for @avatarTakePhoto.
  ///
  /// In it, this message translates to:
  /// **'Scatta una foto'**
  String get avatarTakePhoto;

  /// No description provided for @avatarRemovePhoto.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi foto'**
  String get avatarRemovePhoto;

  /// No description provided for @avatarPickerTitle.
  ///
  /// In it, this message translates to:
  /// **'Scegli il tuo avatar'**
  String get avatarPickerTitle;

  /// No description provided for @avatarChangePhoto.
  ///
  /// In it, this message translates to:
  /// **'Cambia foto'**
  String get avatarChangePhoto;

  /// No description provided for @avatarUploadPhoto.
  ///
  /// In it, this message translates to:
  /// **'Carica una foto'**
  String get avatarUploadPhoto;

  /// No description provided for @avatarThemedTitle.
  ///
  /// In it, this message translates to:
  /// **'Avatar a tema'**
  String get avatarThemedTitle;

  /// No description provided for @avatarThemedHint.
  ///
  /// In it, this message translates to:
  /// **'Usati quando non hai caricato una foto.'**
  String get avatarThemedHint;

  /// No description provided for @avatarUseInitials.
  ///
  /// In it, this message translates to:
  /// **'Usa le iniziali'**
  String get avatarUseInitials;

  /// No description provided for @personLocationNotShared.
  ///
  /// In it, this message translates to:
  /// **'Posizione non condivisa'**
  String get personLocationNotShared;

  /// No description provided for @personBirthdayToday.
  ///
  /// In it, this message translates to:
  /// **'🎂 Oggi è il suo compleanno!'**
  String get personBirthdayToday;

  /// No description provided for @personUpdatedAt.
  ///
  /// In it, this message translates to:
  /// **'Aggiornato {label}'**
  String personUpdatedAt(String label);

  /// No description provided for @personBatteryPercent.
  ///
  /// In it, this message translates to:
  /// **'Batteria {percent}%'**
  String personBatteryPercent(int percent);

  /// No description provided for @personRadarLink.
  ///
  /// In it, this message translates to:
  /// **'Radar di prossimità'**
  String get personRadarLink;

  /// No description provided for @personLocationHistoryLink.
  ///
  /// In it, this message translates to:
  /// **'Cronologia posizioni'**
  String get personLocationHistoryLink;

  /// No description provided for @personStatisticsLink.
  ///
  /// In it, this message translates to:
  /// **'Statistiche e itinerari'**
  String get personStatisticsLink;

  /// No description provided for @personDrivingAlertsLink.
  ///
  /// In it, this message translates to:
  /// **'Avvisi di guida'**
  String get personDrivingAlertsLink;

  /// No description provided for @personSharingWithYou.
  ///
  /// In it, this message translates to:
  /// **'Sta condividendo la posizione con te.'**
  String get personSharingWithYou;

  /// No description provided for @personGhostMode.
  ///
  /// In it, this message translates to:
  /// **'È in modalità fantasma: non può ricevere richieste in questo momento.'**
  String get personGhostMode;

  /// No description provided for @personRequestSent.
  ///
  /// In it, this message translates to:
  /// **'Richiesta inviata'**
  String get personRequestSent;

  /// No description provided for @personRequestLocation.
  ///
  /// In it, this message translates to:
  /// **'Richiedi posizione'**
  String get personRequestLocation;

  /// No description provided for @personPingDailyLimitTitle.
  ///
  /// In it, this message translates to:
  /// **'Limite giornaliero raggiunto'**
  String get personPingDailyLimitTitle;

  /// No description provided for @personPingDailyLimitBody.
  ///
  /// In it, this message translates to:
  /// **'Hai già mandato 5 ping oggi: è il limite del piano gratuito. Con Kinly+ puoi mandarne quanti vuoi.'**
  String get personPingDailyLimitBody;

  /// No description provided for @personPingSent.
  ///
  /// In it, this message translates to:
  /// **'Inviato'**
  String get personPingSent;

  /// No description provided for @sosAlertTitle.
  ///
  /// In it, this message translates to:
  /// **'SOS · {name}'**
  String sosAlertTitle(String name);

  /// No description provided for @sosAlertCancelError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti ad annullare l\'SOS. Riprova.'**
  String get sosAlertCancelError;

  /// No description provided for @sosYourAlertActive.
  ///
  /// In it, this message translates to:
  /// **'Il tuo SOS è attivo'**
  String get sosYourAlertActive;

  /// No description provided for @sosPersonActivated.
  ///
  /// In it, this message translates to:
  /// **'{name} ha attivato l\'SOS'**
  String sosPersonActivated(String name);

  /// No description provided for @sosActivatedAt.
  ///
  /// In it, this message translates to:
  /// **'Attivato alle {time}'**
  String sosActivatedAt(String time);

  /// No description provided for @sosWaitingAddress.
  ///
  /// In it, this message translates to:
  /// **'In attesa dell\'indirizzo...'**
  String get sosWaitingAddress;

  /// No description provided for @sosEmergencyHint.
  ///
  /// In it, this message translates to:
  /// **'In caso di reale emergenza chiama il 112. Kinly condivide solo la posizione: nessuna registrazione audio.'**
  String get sosEmergencyHint;

  /// No description provided for @sosCallPerson.
  ///
  /// In it, this message translates to:
  /// **'Chiama {name}'**
  String sosCallPerson(String name);

  /// No description provided for @sosImSafeCancelSos.
  ///
  /// In it, this message translates to:
  /// **'Sono al sicuro, annulla SOS'**
  String get sosImSafeCancelSos;

  /// No description provided for @helpRequestTitle.
  ///
  /// In it, this message translates to:
  /// **'Aiuto · {name}'**
  String helpRequestTitle(String name);

  /// No description provided for @helpRequestCloseError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a chiudere la richiesta. Riprova.'**
  String get helpRequestCloseError;

  /// No description provided for @helpRequestYouAsked.
  ///
  /// In it, this message translates to:
  /// **'Hai chiesto aiuto: {reason}'**
  String helpRequestYouAsked(String reason);

  /// No description provided for @helpRequestPersonNeeds.
  ///
  /// In it, this message translates to:
  /// **'{name} ha bisogno di aiuto: {reason}'**
  String helpRequestPersonNeeds(String name, String reason);

  /// No description provided for @helpRequestRequestedAt.
  ///
  /// In it, this message translates to:
  /// **'Richiesto alle {time}'**
  String helpRequestRequestedAt(String time);

  /// No description provided for @helpRequestCloseButton.
  ///
  /// In it, this message translates to:
  /// **'Va tutto bene, chiudi richiesta'**
  String get helpRequestCloseButton;

  /// No description provided for @sosContactsTitle.
  ///
  /// In it, this message translates to:
  /// **'Contatti SOS'**
  String get sosContactsTitle;

  /// No description provided for @sosContactsNoneSelected.
  ///
  /// In it, this message translates to:
  /// **'Nessuno selezionato: l\'SOS avviserà tutte le persone delle tue cerchie.'**
  String get sosContactsNoneSelected;

  /// No description provided for @sosContactsSelectedCount.
  ///
  /// In it, this message translates to:
  /// **'L\'SOS avviserà solo le {count} persone selezionate, non tutta la cerchia.'**
  String sosContactsSelectedCount(int count);

  /// No description provided for @sosContactsEmpty.
  ///
  /// In it, this message translates to:
  /// **'Non hai ancora nessuno nelle tue cerchie.'**
  String get sosContactsEmpty;

  /// No description provided for @radarTitle.
  ///
  /// In it, this message translates to:
  /// **'Radar · {name}'**
  String radarTitle(String name);

  /// No description provided for @radarPermissionNeeded.
  ///
  /// In it, this message translates to:
  /// **'Serve il permesso di localizzazione per usare il radar.'**
  String get radarPermissionNeeded;

  /// No description provided for @radarPersonNotSharing.
  ///
  /// In it, this message translates to:
  /// **'{name} non sta condividendo la posizione al momento.'**
  String radarPersonNotSharing(String name);

  /// No description provided for @radarCompassUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Bussola non disponibile su questo dispositivo. Usa la mappa per orientarti.'**
  String get radarCompassUnavailable;

  /// No description provided for @radarVeryClose.
  ///
  /// In it, this message translates to:
  /// **'Sei vicinissimo!'**
  String get radarVeryClose;

  /// No description provided for @radarFollowArrow.
  ///
  /// In it, this message translates to:
  /// **'Segui la freccia per raggiungere {name}'**
  String radarFollowArrow(String name);

  /// No description provided for @paywallFeatureLocationHistoryTitle.
  ///
  /// In it, this message translates to:
  /// **'Cronologia posizioni'**
  String get paywallFeatureLocationHistoryTitle;

  /// No description provided for @paywallFeatureLocationHistoryDesc.
  ///
  /// In it, this message translates to:
  /// **'Rivedi dove sono stati i membri della cerchia nei giorni passati.'**
  String get paywallFeatureLocationHistoryDesc;

  /// No description provided for @paywallFeatureStatsTitle.
  ///
  /// In it, this message translates to:
  /// **'Statistiche e itinerari'**
  String get paywallFeatureStatsTitle;

  /// No description provided for @paywallFeatureStatsDesc.
  ///
  /// In it, this message translates to:
  /// **'Distanza percorsa e mappa dei tragitti fatti, ricostruiti dallo storico.'**
  String get paywallFeatureStatsDesc;

  /// No description provided for @paywallFeatureSafeZonesTitle.
  ///
  /// In it, this message translates to:
  /// **'Aree sicure'**
  String get paywallFeatureSafeZonesTitle;

  /// No description provided for @paywallFeatureSafeZonesDesc.
  ///
  /// In it, this message translates to:
  /// **'Casa, lavoro, scuola: ricevi una notifica personalizzata quando qualcuno arriva o esce.'**
  String get paywallFeatureSafeZonesDesc;

  /// No description provided for @paywallFeatureUnlimitedCirclesTitle.
  ///
  /// In it, this message translates to:
  /// **'Cerchie senza limiti'**
  String get paywallFeatureUnlimitedCirclesTitle;

  /// No description provided for @paywallFeatureUnlimitedCirclesDesc.
  ///
  /// In it, this message translates to:
  /// **'Nessun limite al numero di cerchie o di persone per cerchia.'**
  String get paywallFeatureUnlimitedCirclesDesc;

  /// No description provided for @paywallFeatureDrivingTitle.
  ///
  /// In it, this message translates to:
  /// **'Avvisi di guida'**
  String get paywallFeatureDrivingTitle;

  /// No description provided for @paywallFeatureDrivingDesc.
  ///
  /// In it, this message translates to:
  /// **'Sappi quando chi guida supera un limite di velocità impostato.'**
  String get paywallFeatureDrivingDesc;

  /// No description provided for @paywallFeatureBackgroundTitle.
  ///
  /// In it, this message translates to:
  /// **'Tracciamento in background'**
  String get paywallFeatureBackgroundTitle;

  /// No description provided for @paywallFeatureBackgroundDesc.
  ///
  /// In it, this message translates to:
  /// **'La posizione continua ad aggiornarsi anche con l\'app chiusa.'**
  String get paywallFeatureBackgroundDesc;

  /// No description provided for @paywallFeatureUnlimitedMsgTitle.
  ///
  /// In it, this message translates to:
  /// **'Messaggi, ping e spese illimitati'**
  String get paywallFeatureUnlimitedMsgTitle;

  /// No description provided for @paywallFeatureUnlimitedMsgDesc.
  ///
  /// In it, this message translates to:
  /// **'Manda quanti messaggi, ping e spese vuoi, senza il limite giornaliero.'**
  String get paywallFeatureUnlimitedMsgDesc;

  /// No description provided for @paywallFeatureShoppingTitle.
  ///
  /// In it, this message translates to:
  /// **'Portami qualcosa'**
  String get paywallFeatureShoppingTitle;

  /// No description provided for @paywallFeatureShoppingDesc.
  ///
  /// In it, this message translates to:
  /// **'Segnala alla cerchia quando sei al supermercato o al bar, per farti chiedere qualcosa al volo.'**
  String get paywallFeatureShoppingDesc;

  /// No description provided for @paywallFeaturePriorityTitle.
  ///
  /// In it, this message translates to:
  /// **'Assistenza prioritaria'**
  String get paywallFeaturePriorityTitle;

  /// No description provided for @paywallFeaturePriorityDesc.
  ///
  /// In it, this message translates to:
  /// **'Supporto dedicato per la tua cerchia, 7 giorni su 7.'**
  String get paywallFeaturePriorityDesc;

  /// No description provided for @paywallRequestError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a inviare la richiesta. Riprova.'**
  String get paywallRequestError;

  /// No description provided for @paywallCancelMessage.
  ///
  /// In it, this message translates to:
  /// **'Vorrei annullare il mio abbonamento Kinly+.'**
  String get paywallCancelMessage;

  /// No description provided for @paywallUpgradeMessage.
  ///
  /// In it, this message translates to:
  /// **'Vorrei attivare il piano Kinly+ {plan}.'**
  String paywallUpgradeMessage(String plan);

  /// No description provided for @paywallComingSoonTitle.
  ///
  /// In it, this message translates to:
  /// **'In arrivo'**
  String get paywallComingSoonTitle;

  /// No description provided for @paywallComingSoonBody.
  ///
  /// In it, this message translates to:
  /// **'I pagamenti Kinly+ non sono ancora attivi: abbiamo registrato la tua richiesta, ti attiveremo il piano a mano.'**
  String get paywallComingSoonBody;

  /// No description provided for @paywallFamilyActive.
  ///
  /// In it, this message translates to:
  /// **'Kinly+ Family attivo'**
  String get paywallFamilyActive;

  /// No description provided for @paywallIndividualActive.
  ///
  /// In it, this message translates to:
  /// **'Kinly+ Individual attivo'**
  String get paywallIndividualActive;

  /// No description provided for @paywallIncluded.
  ///
  /// In it, this message translates to:
  /// **'Kinly+ incluso'**
  String get paywallIncluded;

  /// No description provided for @paywallIncludedInFamilyOf.
  ///
  /// In it, this message translates to:
  /// **'Incluso nel piano Family di {name}'**
  String paywallIncludedInFamilyOf(String name);

  /// No description provided for @paywallYourSubscriptionActive.
  ///
  /// In it, this message translates to:
  /// **'Il tuo abbonamento è attivo'**
  String get paywallYourSubscriptionActive;

  /// No description provided for @paywallMorePeaceOfMind.
  ///
  /// In it, this message translates to:
  /// **'Più tranquillità per tutta la cerchia'**
  String get paywallMorePeaceOfMind;

  /// No description provided for @paywallFamilyIncludedHint.
  ///
  /// In it, this message translates to:
  /// **'Finché fai parte della sua cerchia, hai tutti i vantaggi Kinly+ senza pagare nulla.'**
  String get paywallFamilyIncludedHint;

  /// No description provided for @paywallAllUnlockedHint.
  ///
  /// In it, this message translates to:
  /// **'Tutti i vantaggi qui sotto sono sbloccati per te e per le tue cerchie.'**
  String get paywallAllUnlockedHint;

  /// No description provided for @paywallChooseTierHint.
  ///
  /// In it, this message translates to:
  /// **'Un piano Individual sblocca i vantaggi solo per te; un piano Family li estende a chi inviti.'**
  String get paywallChooseTierHint;

  /// No description provided for @paywallWhatIncludes.
  ///
  /// In it, this message translates to:
  /// **'Cosa include'**
  String get paywallWhatIncludes;

  /// No description provided for @paywallComparePlans.
  ///
  /// In it, this message translates to:
  /// **'Confronta i piani'**
  String get paywallComparePlans;

  /// No description provided for @paywallFamilyMemberHint.
  ///
  /// In it, this message translates to:
  /// **'Non paghi nulla: chi ha creato quella cerchia con il piano Family ha esteso Kinly+ a te e agli altri primi membri (fino a 6).'**
  String get paywallFamilyMemberHint;

  /// No description provided for @paywallYourFamilyPlan.
  ///
  /// In it, this message translates to:
  /// **'Il tuo piano Family'**
  String get paywallYourFamilyPlan;

  /// No description provided for @paywallFamilyOwnerHint.
  ///
  /// In it, this message translates to:
  /// **'Chi entra in una cerchia che hai creato (fino a 6 persone, in base a quando sono entrate) ha Kinly+ incluso, senza pagare nulla.'**
  String get paywallFamilyOwnerHint;

  /// No description provided for @paywallRequestSent.
  ///
  /// In it, this message translates to:
  /// **'Richiesta inviata.'**
  String get paywallRequestSent;

  /// No description provided for @paywallRequestCancellation.
  ///
  /// In it, this message translates to:
  /// **'Richiedi annullamento'**
  String get paywallRequestCancellation;

  /// No description provided for @paywallManageSubscription.
  ///
  /// In it, this message translates to:
  /// **'Gestisci abbonamento'**
  String get paywallManageSubscription;

  /// No description provided for @paywallIndividualCancelHint.
  ///
  /// In it, this message translates to:
  /// **'Il tuo Kinly+ non è ancora collegato a un pagamento reale. Per disattivarlo, invia una richiesta: te lo disattiviamo a mano.'**
  String get paywallIndividualCancelHint;

  /// No description provided for @paywallSwitchToFamily.
  ///
  /// In it, this message translates to:
  /// **'Passa a Family'**
  String get paywallSwitchToFamily;

  /// No description provided for @paywallFamilyPrice.
  ///
  /// In it, this message translates to:
  /// **'9,90 €'**
  String get paywallFamilyPrice;

  /// No description provided for @paywallIndividualPrice.
  ///
  /// In it, this message translates to:
  /// **'3,90 €'**
  String get paywallIndividualPrice;

  /// No description provided for @paywallFamilyUpgradeDesc.
  ///
  /// In it, this message translates to:
  /// **'Estendi Kinly+ anche a chi inviti nelle cerchie che crei (fino a 6 persone), non solo a te.'**
  String get paywallFamilyUpgradeDesc;

  /// No description provided for @paywallIndividualTitle.
  ///
  /// In it, this message translates to:
  /// **'Individual'**
  String get paywallIndividualTitle;

  /// No description provided for @paywallIndividualDesc.
  ///
  /// In it, this message translates to:
  /// **'Sblocca tutti i vantaggi Kinly+ per te, in tutte le tue cerchie.'**
  String get paywallIndividualDesc;

  /// No description provided for @paywallSwitchToIndividual.
  ///
  /// In it, this message translates to:
  /// **'Passa a Individual'**
  String get paywallSwitchToIndividual;

  /// No description provided for @paywallFamilyTitle.
  ///
  /// In it, this message translates to:
  /// **'Family'**
  String get paywallFamilyTitle;

  /// No description provided for @paywallFamilyDesc.
  ///
  /// In it, this message translates to:
  /// **'Un solo abbonamento: chi entra in una cerchia che crei (fino a 6 persone) ha Kinly+ incluso.'**
  String get paywallFamilyDesc;

  /// No description provided for @paywallDesignPreviewHint.
  ///
  /// In it, this message translates to:
  /// **'Anteprima del design: i pagamenti non sono ancora attivi.'**
  String get paywallDesignPreviewHint;

  /// No description provided for @paywallPerMonth.
  ///
  /// In it, this message translates to:
  /// **' / mese'**
  String get paywallPerMonth;

  /// No description provided for @paywallCompareCirclesMembers.
  ///
  /// In it, this message translates to:
  /// **'Cerchie e membri'**
  String get paywallCompareCirclesMembers;

  /// No description provided for @paywallCompareFreeCircleLimit.
  ///
  /// In it, this message translates to:
  /// **'Fino a 2 / 6'**
  String get paywallCompareFreeCircleLimit;

  /// No description provided for @paywallCompareUnlimited.
  ///
  /// In it, this message translates to:
  /// **'Illimitati'**
  String get paywallCompareUnlimited;

  /// No description provided for @paywallCompareMessagesPingExpenses.
  ///
  /// In it, this message translates to:
  /// **'Messaggi, ping, spese'**
  String get paywallCompareMessagesPingExpenses;

  /// No description provided for @paywallCompare5PerDay.
  ///
  /// In it, this message translates to:
  /// **'5 al giorno'**
  String get paywallCompare5PerDay;

  /// No description provided for @paywallCompareSafeZonesCreate.
  ///
  /// In it, this message translates to:
  /// **'Aree sicure (creare)'**
  String get paywallCompareSafeZonesCreate;

  /// No description provided for @paywallCompareWhoBenefits.
  ///
  /// In it, this message translates to:
  /// **'Chi beneficia'**
  String get paywallCompareWhoBenefits;

  /// No description provided for @paywallCompareOnlyYou.
  ///
  /// In it, this message translates to:
  /// **'Solo tu'**
  String get paywallCompareOnlyYou;

  /// No description provided for @paywallCompareUpTo6People.
  ///
  /// In it, this message translates to:
  /// **'Fino a 6 persone'**
  String get paywallCompareUpTo6People;

  /// No description provided for @paywallComparePrice.
  ///
  /// In it, this message translates to:
  /// **'Prezzo'**
  String get paywallComparePrice;

  /// No description provided for @paywallCompareFree.
  ///
  /// In it, this message translates to:
  /// **'Gratis'**
  String get paywallCompareFree;

  /// No description provided for @paywallCompareIndividualPricePerMonth.
  ///
  /// In it, this message translates to:
  /// **'3,90 €/mese'**
  String get paywallCompareIndividualPricePerMonth;

  /// No description provided for @paywallCompareFamilyPricePerMonth.
  ///
  /// In it, this message translates to:
  /// **'9,90 €/mese'**
  String get paywallCompareFamilyPricePerMonth;

  /// No description provided for @paywallTierFree.
  ///
  /// In it, this message translates to:
  /// **'Free'**
  String get paywallTierFree;

  /// No description provided for @paywallPlanLabelIndividual.
  ///
  /// In it, this message translates to:
  /// **'Individual (3,90€/mese)'**
  String get paywallPlanLabelIndividual;

  /// No description provided for @paywallPlanLabelFamily.
  ///
  /// In it, this message translates to:
  /// **'Family (9,90€/mese)'**
  String get paywallPlanLabelFamily;

  /// No description provided for @safeZonesTitle.
  ///
  /// In it, this message translates to:
  /// **'Aree sicure · {circle}'**
  String safeZonesTitle(String circle);

  /// No description provided for @safeZonesEmptyTitleFree.
  ///
  /// In it, this message translates to:
  /// **'Nessuna area sicura'**
  String get safeZonesEmptyTitleFree;

  /// No description provided for @safeZonesEmptyMessagePremium.
  ///
  /// In it, this message translates to:
  /// **'Crea un\'area (ad esempio casa o scuola) per ricevere una notifica quando qualcuno entra o esce.'**
  String get safeZonesEmptyMessagePremium;

  /// No description provided for @safeZonesEmptyMessageFree.
  ///
  /// In it, this message translates to:
  /// **'Passa a Kinly+ per creare aree sicure e ricevere una notifica quando qualcuno arriva o esce da un luogo.'**
  String get safeZonesEmptyMessageFree;

  /// No description provided for @safeZonesCreateFirst.
  ///
  /// In it, this message translates to:
  /// **'Crea la prima area'**
  String get safeZonesCreateFirst;

  /// No description provided for @safeZonesSuggestedForYou.
  ///
  /// In it, this message translates to:
  /// **'Suggerite per te'**
  String get safeZonesSuggestedForYou;

  /// No description provided for @safeZonesFrequentVisit.
  ///
  /// In it, this message translates to:
  /// **'Ci vai spesso ({days} giorni diversi) · tocca per creare un\'area'**
  String safeZonesFrequentVisit(int days);

  /// No description provided for @safeZonesKindRadius.
  ///
  /// In it, this message translates to:
  /// **'{kindLabel} · Raggio {radius} m'**
  String safeZonesKindRadius(String kindLabel, int radius);

  /// No description provided for @safeZonesEditTooltip.
  ///
  /// In it, this message translates to:
  /// **'Modifica area'**
  String get safeZonesEditTooltip;

  /// No description provided for @safeZonesDeleteTooltip.
  ///
  /// In it, this message translates to:
  /// **'Elimina area'**
  String get safeZonesDeleteTooltip;

  /// No description provided for @safeZonesLastEntry.
  ///
  /// In it, this message translates to:
  /// **'Ultimo ingresso registrato'**
  String get safeZonesLastEntry;

  /// No description provided for @safeZonesLastExit.
  ///
  /// In it, this message translates to:
  /// **'Ultima uscita registrata'**
  String get safeZonesLastExit;

  /// No description provided for @safeZonesEditTitle.
  ///
  /// In it, this message translates to:
  /// **'Modifica area sicura'**
  String get safeZonesEditTitle;

  /// No description provided for @safeZonesNewTitle.
  ///
  /// In it, this message translates to:
  /// **'Nuova area sicura'**
  String get safeZonesNewTitle;

  /// No description provided for @safeZonesNameHint.
  ///
  /// In it, this message translates to:
  /// **'Nome (es. Casa, Scuola)'**
  String get safeZonesNameHint;

  /// No description provided for @safeZonesPlaceType.
  ///
  /// In it, this message translates to:
  /// **'Tipo di luogo'**
  String get safeZonesPlaceType;

  /// No description provided for @safeZonesRadiusMeters.
  ///
  /// In it, this message translates to:
  /// **'Raggio: {radius} m'**
  String safeZonesRadiusMeters(int radius);

  /// No description provided for @safeZonesRadiusValue.
  ///
  /// In it, this message translates to:
  /// **'{radius} m'**
  String safeZonesRadiusValue(int radius);

  /// No description provided for @safeZonesOrEnterAddress.
  ///
  /// In it, this message translates to:
  /// **'Oppure inserisci un indirizzo'**
  String get safeZonesOrEnterAddress;

  /// No description provided for @safeZonesAddressNotFound.
  ///
  /// In it, this message translates to:
  /// **'Indirizzo non trovato. Prova a essere più preciso.'**
  String get safeZonesAddressNotFound;

  /// No description provided for @safeZonesAddressSearchError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a cercare questo indirizzo. Riprova.'**
  String get safeZonesAddressSearchError;

  /// No description provided for @safeZonesPlusOnly.
  ///
  /// In it, this message translates to:
  /// **'Le aree sicure sono una funzione Kinly+.'**
  String get safeZonesPlusOnly;

  /// No description provided for @safeZonesSaveChangesError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a salvare le modifiche. Riprova.'**
  String get safeZonesSaveChangesError;

  /// No description provided for @safeZonesCreateError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a creare l\'area. Riprova.'**
  String get safeZonesCreateError;

  /// No description provided for @safeZonesSaveChanges.
  ///
  /// In it, this message translates to:
  /// **'Salva modifiche'**
  String get safeZonesSaveChanges;

  /// No description provided for @safeZonesCreateButton.
  ///
  /// In it, this message translates to:
  /// **'Crea area'**
  String get safeZonesCreateButton;

  /// No description provided for @historyDeleteConfirmTitle.
  ///
  /// In it, this message translates to:
  /// **'Cancellare la cronologia?'**
  String get historyDeleteConfirmTitle;

  /// No description provided for @historyDeleteConfirmBody.
  ///
  /// In it, this message translates to:
  /// **'Elimina tutti i punti registrati finora, incluse le statistiche di itinerari già calcolate da questi dati. Non si può annullare.'**
  String get historyDeleteConfirmBody;

  /// No description provided for @historyDeleteButton.
  ///
  /// In it, this message translates to:
  /// **'Cancella'**
  String get historyDeleteButton;

  /// No description provided for @historyDeletedSnackbar.
  ///
  /// In it, this message translates to:
  /// **'Cronologia cancellata.'**
  String get historyDeletedSnackbar;

  /// No description provided for @historyDeleteError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a cancellare la cronologia. Riprova.'**
  String get historyDeleteError;

  /// No description provided for @historyTitle.
  ///
  /// In it, this message translates to:
  /// **'Cronologia · {name}'**
  String historyTitle(String name);

  /// No description provided for @historyDeleteTooltip.
  ///
  /// In it, this message translates to:
  /// **'Cancella cronologia'**
  String get historyDeleteTooltip;

  /// No description provided for @historyUpsellMessage.
  ///
  /// In it, this message translates to:
  /// **'Passa a Kinly+ per rivedere dove sono stati i membri della cerchia nei giorni passati.'**
  String get historyUpsellMessage;

  /// No description provided for @historyEmpty.
  ///
  /// In it, this message translates to:
  /// **'Ancora nessuno storico disponibile.'**
  String get historyEmpty;

  /// No description provided for @historyToday.
  ///
  /// In it, this message translates to:
  /// **'Oggi, {time}'**
  String historyToday(String time);

  /// No description provided for @statsTitle.
  ///
  /// In it, this message translates to:
  /// **'Statistiche · {name}'**
  String statsTitle(String name);

  /// No description provided for @statsUpsellMessage.
  ///
  /// In it, this message translates to:
  /// **'Passa a Kinly+ per vedere quanta strada avete fatto e rivedere gli itinerari percorsi.'**
  String get statsUpsellMessage;

  /// No description provided for @statsNoTripsYet.
  ///
  /// In it, this message translates to:
  /// **'Ancora nessun itinerario disponibile: torna qui dopo qualche spostamento.'**
  String get statsNoTripsYet;

  /// No description provided for @statsLast7Days.
  ///
  /// In it, this message translates to:
  /// **'Ultimi 7 giorni'**
  String get statsLast7Days;

  /// No description provided for @statsLast30Days.
  ///
  /// In it, this message translates to:
  /// **'Ultimi 30 giorni'**
  String get statsLast30Days;

  /// No description provided for @statsWeeklySummary.
  ///
  /// In it, this message translates to:
  /// **'Riepilogo settimanale'**
  String get statsWeeklySummary;

  /// No description provided for @statsTripCount.
  ///
  /// In it, this message translates to:
  /// **'{count, plural, one{{count} tragitto} other{{count} tragitti}}'**
  String statsTripCount(int count);

  /// No description provided for @statsRecentTrips.
  ///
  /// In it, this message translates to:
  /// **'Itinerari recenti'**
  String get statsRecentTrips;

  /// No description provided for @statsTripLabel.
  ///
  /// In it, this message translates to:
  /// **'Itinerario'**
  String get statsTripLabel;

  /// No description provided for @statsDeparture.
  ///
  /// In it, this message translates to:
  /// **'Partenza'**
  String get statsDeparture;

  /// No description provided for @statsArrival.
  ///
  /// In it, this message translates to:
  /// **'Arrivo'**
  String get statsArrival;

  /// No description provided for @statsDistance.
  ///
  /// In it, this message translates to:
  /// **'Distanza'**
  String get statsDistance;

  /// No description provided for @statsDuration.
  ///
  /// In it, this message translates to:
  /// **'Durata'**
  String get statsDuration;

  /// No description provided for @statsMinutes.
  ///
  /// In it, this message translates to:
  /// **'{minutes} min'**
  String statsMinutes(int minutes);

  /// No description provided for @statsDateAndMinutes.
  ///
  /// In it, this message translates to:
  /// **'{date} · {minutes} min'**
  String statsDateAndMinutes(String date, int minutes);

  /// No description provided for @statsDayMon.
  ///
  /// In it, this message translates to:
  /// **'L'**
  String get statsDayMon;

  /// No description provided for @statsDayTue.
  ///
  /// In it, this message translates to:
  /// **'M'**
  String get statsDayTue;

  /// No description provided for @statsDayWed.
  ///
  /// In it, this message translates to:
  /// **'M'**
  String get statsDayWed;

  /// No description provided for @statsDayThu.
  ///
  /// In it, this message translates to:
  /// **'G'**
  String get statsDayThu;

  /// No description provided for @statsDayFri.
  ///
  /// In it, this message translates to:
  /// **'V'**
  String get statsDayFri;

  /// No description provided for @statsDaySat.
  ///
  /// In it, this message translates to:
  /// **'S'**
  String get statsDaySat;

  /// No description provided for @statsDaySun.
  ///
  /// In it, this message translates to:
  /// **'D'**
  String get statsDaySun;

  /// No description provided for @speedAlertsTitle.
  ///
  /// In it, this message translates to:
  /// **'Avvisi di guida · {name}'**
  String speedAlertsTitle(String name);

  /// No description provided for @speedAlertsUpsellMessage.
  ///
  /// In it, this message translates to:
  /// **'Passa a Kinly+ per sapere quando chi guida supera il limite di velocità che si è impostato.'**
  String get speedAlertsUpsellMessage;

  /// No description provided for @speedAlertsEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessun avviso registrato: questa persona non ha ancora superato la soglia di velocità impostata (o non l\'ha impostata).'**
  String get speedAlertsEmpty;

  /// No description provided for @speedAlertsKmhLimit.
  ///
  /// In it, this message translates to:
  /// **'{speed} km/h (limite {threshold} km/h)'**
  String speedAlertsKmhLimit(int speed, int threshold);

  /// No description provided for @commonRetry.
  ///
  /// In it, this message translates to:
  /// **'Riprova'**
  String get commonRetry;

  /// No description provided for @commonContinue.
  ///
  /// In it, this message translates to:
  /// **'Continua'**
  String get commonContinue;

  /// No description provided for @biometricLockedTitle.
  ///
  /// In it, this message translates to:
  /// **'Kinly è bloccata'**
  String get biometricLockedTitle;

  /// No description provided for @biometricLockedMessage.
  ///
  /// In it, this message translates to:
  /// **'Sblocca con l\'impronta, il volto o il codice del dispositivo per continuare.'**
  String get biometricLockedMessage;

  /// No description provided for @biometricUnlockButton.
  ///
  /// In it, this message translates to:
  /// **'Sblocca'**
  String get biometricUnlockButton;

  /// No description provided for @splashConnectionError.
  ///
  /// In it, this message translates to:
  /// **'Non riusciamo a contattare Kinly. Controlla la connessione e riprova.'**
  String get splashConnectionError;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In it, this message translates to:
  /// **'Benvenuto in Kinly'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeDesc.
  ///
  /// In it, this message translates to:
  /// **'Condividi la tua posizione solo con chi conta davvero: famiglia, amici, colleghi. Accesso sempre su invito, mai pubblico.'**
  String get onboardingWelcomeDesc;

  /// No description provided for @onboardingSafeTitle.
  ///
  /// In it, this message translates to:
  /// **'Sempre al sicuro'**
  String get onboardingSafeTitle;

  /// No description provided for @onboardingSafeDesc.
  ///
  /// In it, this message translates to:
  /// **'SOS e \"Chiedi aiuto\" avvisano subito la tua cerchia in caso di bisogno. Le aree sicure ti dicono quando qualcuno arriva o esce da casa, lavoro o scuola.'**
  String get onboardingSafeDesc;

  /// No description provided for @onboardingContactTitle.
  ///
  /// In it, this message translates to:
  /// **'Restate in contatto'**
  String get onboardingContactTitle;

  /// No description provided for @onboardingContactDesc.
  ///
  /// In it, this message translates to:
  /// **'Messaggi rapidi, punto d\'incontro condiviso e meteo della zona: tutto in un posto solo, senza dover chiedere \"dove sei?\".'**
  String get onboardingContactDesc;

  /// No description provided for @onboardingStart.
  ///
  /// In it, this message translates to:
  /// **'Inizia'**
  String get onboardingStart;

  /// No description provided for @onboardingSkip.
  ///
  /// In it, this message translates to:
  /// **'Salta'**
  String get onboardingSkip;

  /// No description provided for @onboardingBiometricTitle.
  ///
  /// In it, this message translates to:
  /// **'Proteggi l\'accesso'**
  String get onboardingBiometricTitle;

  /// No description provided for @onboardingBiometricDesc.
  ///
  /// In it, this message translates to:
  /// **'Attiva subito lo sblocco con impronta, volto o codice del dispositivo: un livello in più oltre alla password, verificato dal sistema (Kinly non vede mai i tuoi dati biometrici).'**
  String get onboardingBiometricDesc;

  /// No description provided for @createCircleTitle.
  ///
  /// In it, this message translates to:
  /// **'Crea la tua cerchia'**
  String get createCircleTitle;

  /// No description provided for @circleLimitCirclesMessage.
  ///
  /// In it, this message translates to:
  /// **'Nel piano gratuito puoi far parte di massimo 2 cerchie. Passa a Kinly+ per non avere limiti.'**
  String get circleLimitCirclesMessage;

  /// No description provided for @createCircleError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a creare la cerchia. Riprova.'**
  String get createCircleError;

  /// No description provided for @createCircleNameQuestion.
  ///
  /// In it, this message translates to:
  /// **'Come si chiama?'**
  String get createCircleNameQuestion;

  /// No description provided for @createCircleNameHint.
  ///
  /// In it, this message translates to:
  /// **'Ad esempio \"Famiglia\" o \"Weekend in montagna\".'**
  String get createCircleNameHint;

  /// No description provided for @createCircleNameField.
  ///
  /// In it, this message translates to:
  /// **'Nome della cerchia'**
  String get createCircleNameField;

  /// No description provided for @createCircleIconLabel.
  ///
  /// In it, this message translates to:
  /// **'Icona'**
  String get createCircleIconLabel;

  /// No description provided for @createCircleColorLabel.
  ///
  /// In it, this message translates to:
  /// **'Colore'**
  String get createCircleColorLabel;

  /// No description provided for @createCircleSubmit.
  ///
  /// In it, this message translates to:
  /// **'Crea la cerchia'**
  String get createCircleSubmit;

  /// No description provided for @createCircleSuccessTitle.
  ///
  /// In it, this message translates to:
  /// **'\"{name}\" è pronta!'**
  String createCircleSuccessTitle(String name);

  /// No description provided for @createCircleSuccessMessage.
  ///
  /// In it, this message translates to:
  /// **'Condividi questo codice con chi vuoi invitare. Solo chi lo ha può entrare.'**
  String get createCircleSuccessMessage;

  /// No description provided for @createCircleCodeCopied.
  ///
  /// In it, this message translates to:
  /// **'Codice copiato'**
  String get createCircleCodeCopied;

  /// No description provided for @createCircleCopyCode.
  ///
  /// In it, this message translates to:
  /// **'Copia codice'**
  String get createCircleCopyCode;

  /// No description provided for @joinCircleTitle.
  ///
  /// In it, this message translates to:
  /// **'Entra in una cerchia'**
  String get joinCircleTitle;

  /// No description provided for @joinCircleQuestion.
  ///
  /// In it, this message translates to:
  /// **'Inserisci il codice di invito'**
  String get joinCircleQuestion;

  /// No description provided for @joinCircleHint.
  ///
  /// In it, this message translates to:
  /// **'Te lo manda chi ha creato la cerchia, ad esempio via messaggio.'**
  String get joinCircleHint;

  /// No description provided for @joinCircleInvalidCode.
  ///
  /// In it, this message translates to:
  /// **'Codice non valido. Chiedi a chi ti ha invitato di controllarlo.'**
  String get joinCircleInvalidCode;

  /// No description provided for @joinCircleMemberLimitMessage.
  ///
  /// In it, this message translates to:
  /// **'Questa cerchia ha già raggiunto il limite di 6 persone del piano gratuito.'**
  String get joinCircleMemberLimitMessage;

  /// No description provided for @joinCircleError.
  ///
  /// In it, this message translates to:
  /// **'Non siamo riusciti a verificare il codice. Riprova.'**
  String get joinCircleError;

  /// No description provided for @joinCircleSubmit.
  ///
  /// In it, this message translates to:
  /// **'Entra'**
  String get joinCircleSubmit;

  /// No description provided for @joinCircleFormatHint.
  ///
  /// In it, this message translates to:
  /// **'Chiedi il codice a chi ha creato la cerchia: ha il formato XXX-0000.'**
  String get joinCircleFormatHint;

  /// No description provided for @sharingModeAutomatic.
  ///
  /// In it, this message translates to:
  /// **'Automatica'**
  String get sharingModeAutomatic;

  /// No description provided for @sharingModeOnRequest.
  ///
  /// In it, this message translates to:
  /// **'Su richiesta'**
  String get sharingModeOnRequest;

  /// No description provided for @sharingModePaused.
  ///
  /// In it, this message translates to:
  /// **'Sospesa'**
  String get sharingModePaused;

  /// No description provided for @sharingModeFuzzy.
  ///
  /// In it, this message translates to:
  /// **'Approssimativa'**
  String get sharingModeFuzzy;

  /// No description provided for @sharingModeAutomaticDesc.
  ///
  /// In it, this message translates to:
  /// **'La tua posizione è sempre visibile alla tua cerchia, in tempo reale.'**
  String get sharingModeAutomaticDesc;

  /// No description provided for @sharingModeOnRequestDesc.
  ///
  /// In it, this message translates to:
  /// **'Nessuno vede la tua posizione finché non approvi una richiesta.'**
  String get sharingModeOnRequestDesc;

  /// No description provided for @sharingModePausedDesc.
  ///
  /// In it, this message translates to:
  /// **'Modalità fantasma: sei invisibile, nessuno può chiedere dove sei.'**
  String get sharingModePausedDesc;

  /// No description provided for @sharingModeFuzzyDesc.
  ///
  /// In it, this message translates to:
  /// **'La tua cerchia vede solo la zona (circa 1 km), mai il punto esatto.'**
  String get sharingModeFuzzyDesc;

  /// No description provided for @ghostModeTitle.
  ///
  /// In it, this message translates to:
  /// **'Ghost Mode temporaneo'**
  String get ghostModeTitle;

  /// No description provided for @ghostModeDesc.
  ///
  /// In it, this message translates to:
  /// **'Nasconditi del tutto per 2 ore, poi torni visibile da solo.'**
  String get ghostModeDesc;

  /// No description provided for @ghostModePlusTeaser.
  ///
  /// In it, this message translates to:
  /// **'Nasconditi del tutto per un tempo limitato. Funzione Kinly+.'**
  String get ghostModePlusTeaser;

  /// No description provided for @ghostModeActiveTitle.
  ///
  /// In it, this message translates to:
  /// **'Ghost Mode attivo'**
  String get ghostModeActiveTitle;

  /// No description provided for @ghostModeActiveUntil.
  ///
  /// In it, this message translates to:
  /// **'Torni visibile alle {time}'**
  String ghostModeActiveUntil(String time);

  /// No description provided for @ghostModeActivate.
  ///
  /// In it, this message translates to:
  /// **'Attiva'**
  String get ghostModeActivate;

  /// No description provided for @ghostModeEndNow.
  ///
  /// In it, this message translates to:
  /// **'Termina ora'**
  String get ghostModeEndNow;

  /// No description provided for @helpReqReasonFlatTire.
  ///
  /// In it, this message translates to:
  /// **'Gomma bucata'**
  String get helpReqReasonFlatTire;

  /// No description provided for @helpReqReasonAccident.
  ///
  /// In it, this message translates to:
  /// **'Incidente'**
  String get helpReqReasonAccident;

  /// No description provided for @helpReqReasonFollowed.
  ///
  /// In it, this message translates to:
  /// **'Mi sento seguito/a'**
  String get helpReqReasonFollowed;

  /// No description provided for @helpReqReasonLowBattery.
  ///
  /// In it, this message translates to:
  /// **'Batteria scarica'**
  String get helpReqReasonLowBattery;

  /// No description provided for @helpReqReasonOther.
  ///
  /// In it, this message translates to:
  /// **'Altro'**
  String get helpReqReasonOther;

  /// No description provided for @pingKindCoffee.
  ///
  /// In it, this message translates to:
  /// **'Un caffè?'**
  String get pingKindCoffee;

  /// No description provided for @pingKindTraffic.
  ///
  /// In it, this message translates to:
  /// **'Occhio al traffico'**
  String get pingKindTraffic;

  /// No description provided for @pingKindHighFive.
  ///
  /// In it, this message translates to:
  /// **'High five'**
  String get pingKindHighFive;

  /// No description provided for @safeZoneKindHome.
  ///
  /// In it, this message translates to:
  /// **'Casa'**
  String get safeZoneKindHome;

  /// No description provided for @safeZoneKindWork.
  ///
  /// In it, this message translates to:
  /// **'Lavoro'**
  String get safeZoneKindWork;

  /// No description provided for @safeZoneKindSchool.
  ///
  /// In it, this message translates to:
  /// **'Scuola'**
  String get safeZoneKindSchool;

  /// No description provided for @safeZoneKindOther.
  ///
  /// In it, this message translates to:
  /// **'Altro'**
  String get safeZoneKindOther;

  /// No description provided for @personLastUpdateNow.
  ///
  /// In it, this message translates to:
  /// **'Proprio ora'**
  String get personLastUpdateNow;

  /// No description provided for @personLastUpdateMinutes.
  ///
  /// In it, this message translates to:
  /// **'{minutes} min fa'**
  String personLastUpdateMinutes(int minutes);

  /// No description provided for @personLastUpdateHours.
  ///
  /// In it, this message translates to:
  /// **'{hours} h fa'**
  String personLastUpdateHours(int hours);

  /// No description provided for @personLastUpdateDays.
  ///
  /// In it, this message translates to:
  /// **'{days} g fa'**
  String personLastUpdateDays(int days);

  /// No description provided for @weatherClear.
  ///
  /// In it, this message translates to:
  /// **'Sereno'**
  String get weatherClear;

  /// No description provided for @weatherPartlyCloudy.
  ///
  /// In it, this message translates to:
  /// **'Poco nuvoloso'**
  String get weatherPartlyCloudy;

  /// No description provided for @weatherOvercast.
  ///
  /// In it, this message translates to:
  /// **'Coperto'**
  String get weatherOvercast;

  /// No description provided for @weatherFog.
  ///
  /// In it, this message translates to:
  /// **'Nebbia'**
  String get weatherFog;

  /// No description provided for @weatherDrizzle.
  ///
  /// In it, this message translates to:
  /// **'Pioggerella'**
  String get weatherDrizzle;

  /// No description provided for @weatherRain.
  ///
  /// In it, this message translates to:
  /// **'Pioggia'**
  String get weatherRain;

  /// No description provided for @weatherSnow.
  ///
  /// In it, this message translates to:
  /// **'Neve'**
  String get weatherSnow;

  /// No description provided for @weatherShowers.
  ///
  /// In it, this message translates to:
  /// **'Rovesci'**
  String get weatherShowers;

  /// No description provided for @weatherSnowShowers.
  ///
  /// In it, this message translates to:
  /// **'Rovesci di neve'**
  String get weatherSnowShowers;

  /// No description provided for @weatherStorm.
  ///
  /// In it, this message translates to:
  /// **'Temporale'**
  String get weatherStorm;

  /// No description provided for @weatherNow.
  ///
  /// In it, this message translates to:
  /// **'Al momento'**
  String get weatherNow;

  /// No description provided for @tripReplayPause.
  ///
  /// In it, this message translates to:
  /// **'Pausa'**
  String get tripReplayPause;

  /// No description provided for @tripReplayWatch.
  ///
  /// In it, this message translates to:
  /// **'Rivedi il tragitto'**
  String get tripReplayWatch;

  /// No description provided for @mapWaitingForLocation.
  ///
  /// In it, this message translates to:
  /// **'In attesa della posizione…'**
  String get mapWaitingForLocation;

  /// No description provided for @pwaInstallTitle.
  ///
  /// In it, this message translates to:
  /// **'Installa Kinly'**
  String get pwaInstallTitle;

  /// No description provided for @pwaInstallAndroidBody.
  ///
  /// In it, this message translates to:
  /// **'Aggiungila alla schermata Home: si apre più veloce e non occupa spazio extra.'**
  String get pwaInstallAndroidBody;

  /// No description provided for @pwaInstallButton.
  ///
  /// In it, this message translates to:
  /// **'Installa'**
  String get pwaInstallButton;

  /// No description provided for @pwaInstallIosBody.
  ///
  /// In it, this message translates to:
  /// **'Tocca Condividi, poi \"Aggiungi alla schermata Home\".'**
  String get pwaInstallIosBody;
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
