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

  @override
  String get languagePickerTitle => 'Scegli la lingua';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonClose => 'Chiudi';

  @override
  String get commonNo => 'No';

  @override
  String get commonSomeone => 'Qualcuno';

  @override
  String get commonSave => 'Salva';

  @override
  String get commonRemove => 'Rimuovi';

  @override
  String get commonNotNow => 'Non ora';

  @override
  String get commonActivate => 'Attiva';

  @override
  String get commonDone => 'Fatto';

  @override
  String get mapNeedCircleFirst => 'Crea o entra in una cerchia prima.';

  @override
  String get mapWhichCircleTitle => 'In quale cerchia?';

  @override
  String mapMeetingPointAdded(String name) {
    return '\"$name\" aggiunto come punto d\'incontro.';
  }

  @override
  String get mapSearchHint => 'Cerca un indirizzo o un negozio…';

  @override
  String get mapMakeMeetingPoint => 'Rendi punto d\'incontro';

  @override
  String get mapLocationUnavailable =>
      'Non siamo riusciti a rilevare la tua posizione.';

  @override
  String get mapSosConfirmTitle => 'Attivare l\'SOS?';

  @override
  String get mapSosConfirmBody =>
      'La tua posizione esatta verrà condivisa subito con tutte le tue cerchie, anche se hai una modalità di condivisione ridotta. Nessuna registrazione audio: solo posizione.';

  @override
  String get mapActivateSos => 'Attiva SOS';

  @override
  String get mapLocationUnavailableForSos =>
      'Non siamo riusciti a rilevare la tua posizione per l\'SOS.';

  @override
  String get mapSosNotSentOffline =>
      'SOS non inviato (sei offline?). Imposta un numero SOS via SMS in Privacy e sicurezza per avere un piano B.';

  @override
  String get mapNoInternetSosSmsTitle => 'Niente internet: SOS via SMS?';

  @override
  String mapNoInternetSosSmsBody(String number) {
    return 'Non siamo riusciti a inviare l\'SOS online. Vuoi mandare un SMS con la tua posizione a $number?';
  }

  @override
  String get mapPrepareSms => 'Prepara SMS';

  @override
  String get mapWalkMeHomeActiveTitle => 'Accompagnami attivo';

  @override
  String mapWalkMeHomeActiveBody(int minutes) {
    return 'Se non confermi entro ~$minutes min, la tua cerchia riceve un avviso con la tua posizione.';
  }

  @override
  String get mapArrived => 'Sono arrivato/a';

  @override
  String get mapWalkMeHomeTitle => 'Accompagnami';

  @override
  String get mapWalkMeHomeDescription =>
      'Scegli in quanto tempo prevedi di arrivare: se non confermi entro quel tempo (o non entri in un\'area Casa), la tua cerchia riceve automaticamente un avviso con la tua posizione.';

  @override
  String mapWalkMeHomeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get mapWalkMeHomeNote =>
      'Nota: se il telefono chiude del tutto l\'app prima della scadenza, l\'avviso automatico potrebbe non partire.';

  @override
  String get mapCrashDetectedTitle => 'Possibile incidente rilevato';

  @override
  String mapCrashDetectedBody(int secondsLeft) {
    return 'SOS automatico tra $secondsLeft secondi. Stai bene? Annulla se è un falso allarme.';
  }

  @override
  String get mapImFine => 'Sto bene, annulla';

  @override
  String get mapShareLocationLinkTitle => 'Condividi la posizione con un link';

  @override
  String get mapShareLocationLinkBody =>
      'Chi riceve il link vede la tua posizione live dal browser, anche senza l\'app. Il link scade da solo.';

  @override
  String get mapDuration1h => '1 ora';

  @override
  String get mapDuration3h => '3 ore';

  @override
  String get mapDuration24h => '24 ore';

  @override
  String mapShareLiveMessage(String label, String url) {
    return 'Segui la mia posizione live su Kinly (valido $label): $url';
  }

  @override
  String get mapLinkCreateError =>
      'Non siamo riusciti a creare il link. Riprova.';

  @override
  String get mapWhichCircleForMeetingPoint => 'Per quale cerchia?';

  @override
  String get mapManageSafeZones => 'Gestisci aree sicure';

  @override
  String get mapYourCircle => 'La tua cerchia';

  @override
  String mapPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persone',
      one: '$count persona',
    );
    return '$_temp0';
  }

  @override
  String get mapNewMeetingPointTooltip => 'Nuovo punto d\'incontro';

  @override
  String get mapShareLocationLinkTooltip => 'Condividi posizione con un link';

  @override
  String get mapEmptyCircleTitle => 'Nessuno da vedere qui ancora';

  @override
  String get mapEmptyCircleMessage =>
      'Invita una persona nella cerchia per vederla sulla mappa.';

  @override
  String get mapAllCirclesChip => 'Tutte';

  @override
  String get mapWebNotice =>
      'Stai usando la versione web (compagna) di Kinly: qui la posizione si aggiorna solo mentre questa scheda è aperta.';

  @override
  String get mapSosActiveLabel => 'SOS attivo';

  @override
  String get mapActivateSosSemantic => 'Attiva SOS';

  @override
  String get mapHelpRequestedLabel => 'Aiuto richiesto';

  @override
  String get mapAskForHelp => 'Chiedi aiuto';

  @override
  String get mapWalkMeHomeActiveLabel => 'Accompagnami attivo';

  @override
  String get mapWalkMeHomeSemantic => 'Accompagnami';

  @override
  String mapSosBannerText(String personName) {
    return '$personName ha attivato l\'SOS · tocca per vedere dove si trova';
  }

  @override
  String mapHelpBannerText(String personName, String reason) {
    return '$personName ha bisogno di aiuto ($reason) · tocca per i dettagli';
  }

  @override
  String mapWalkMeHomeBannerText(int minutes) {
    return 'Accompagnami attivo · conferma entro ~$minutes min';
  }

  @override
  String get mapHighFive => 'High five';

  @override
  String mapEncounterText(String personName) {
    return 'Ti sei incrociato con $personName!';
  }

  @override
  String mapShoppingAtStore(String personName, String place) {
    return '$personName è al negozio$place';
  }

  @override
  String get mapAskSomething => 'Chiedi qualcosa';

  @override
  String get mapShoppingHint => 'Es. Latte!';

  @override
  String get mapTheyAskedFor => 'Ti hanno chiesto:';

  @override
  String mapShoppingRequestLine(String name, String note) {
    return '$name: $note';
  }

  @override
  String get mapHelpRequestDescription =>
      'Avvisa la tua cerchia con un motivo e la tua posizione attuale. A differenza dell\'SOS, non cambia la tua modalità di condivisione.';

  @override
  String get mapCircleLabel => 'Cerchia';

  @override
  String get mapReasonLabel => 'Motivo';

  @override
  String get mapNoteHint => 'Aggiungi un dettaglio (opzionale)';

  @override
  String get mapSendRequest => 'Invia richiesta';

  @override
  String get mapNeedCircleForHelp =>
      'Crea o entra in una cerchia prima di chiedere aiuto.';

  @override
  String get mapHelpRequestSendError =>
      'Non siamo riusciti a inviare la richiesta. Riprova.';

  @override
  String mapSafeZoneLabelAndRadius(String kindLabel, int radius) {
    return '$kindLabel · raggio $radius m';
  }

  @override
  String get circlesTitle => 'Le tue cerchie';

  @override
  String get circlesAddTitle => 'Aggiungi una cerchia';

  @override
  String get circlesCreateNew => 'Crea una nuova cerchia';

  @override
  String get circlesHaveInviteCode => 'Ho un codice di invito';

  @override
  String circlesJoinedSnackbar(String name) {
    return 'Sei entrato in \"$name\"';
  }

  @override
  String circlesYourModeInTitle(String name) {
    return 'La tua modalità in \"$name\"';
  }

  @override
  String get circlesModeOverrideHint =>
      'Vale solo per questa cerchia: nelle altre resta quella generale del tuo profilo.';

  @override
  String get circlesUseGeneralMode => 'Usa la modalità generale';

  @override
  String circlesGeneralModeDescription(String modeLabel) {
    return 'Quella scelta nel tuo profilo ($modeLabel).';
  }

  @override
  String circlesAnomalyStillAt(String name, String zoneName) {
    return '$name è ancora $zoneName';
  }

  @override
  String circlesAnomalyLate(String expected, int minutes) {
    return 'Di solito esce entro le $expected · $minutes min di ritardo';
  }

  @override
  String get circlesInviteCodeCopied => 'Codice invito copiato';

  @override
  String get circlesActionInvite => 'Invita';

  @override
  String circlesInviteShareMessage(String circleName, String inviteCode) {
    return 'Entra nella mia cerchia \"$circleName\" su Kinly!\n\nCodice di invito: $inviteCode\n\nApri Kinly e tocca \"Ho un codice di invito\", oppure tocca: kinly://join/$inviteCode';
  }

  @override
  String get circlesActionSafeZones => 'Aree sicure';

  @override
  String get circlesActionMeetingPoint => 'Punto d\'incontro';

  @override
  String get circlesActionMessages => 'Messaggi';

  @override
  String get circlesActionExpenses => 'Spese';

  @override
  String get circlesActionSummary => 'Riepilogo';

  @override
  String get circlesActionYourMode => 'La tua modalità';

  @override
  String get circlesCoachStep1Title => 'La tua cerchia';

  @override
  String get circlesCoachStep1Body =>
      'Ogni cerchia ha i suoi membri, la sua icona e le sue impostazioni: puoi averne più di una.';

  @override
  String get circlesCoachStep2Title => 'Le azioni della cerchia';

  @override
  String get circlesCoachStep2Body =>
      'Da qui gestisci aree sicure, punto d\'incontro, messaggi, spese di gruppo e il riepilogo settimanale.';

  @override
  String get circlesCoachStep3Title => 'Codice di invito';

  @override
  String get circlesCoachStep3Body =>
      'Tocca per copiarlo: solo chi lo riceve da te può entrare in questa cerchia.';

  @override
  String get circlesCoachSkip => 'Salta';

  @override
  String get circlesCoachNext => 'Avanti';

  @override
  String get circlesCoachFinish => 'Fine';

  @override
  String get meetingPointTitle => 'Punto d\'incontro';

  @override
  String get meetingPointDeleteTooltip => 'Elimina punto d\'incontro';

  @override
  String get meetingPointCreateButton => 'Crea punto';

  @override
  String get meetingPointEmptyTitle => 'Nessun punto d\'incontro';

  @override
  String get meetingPointEmptyMessage =>
      'Proponi un luogo dove ritrovarvi: tutti vedranno la propria distanza in tempo reale, senza scriversi \"dove sei?\".';

  @override
  String get meetingPointMarkArrived => 'Segna il mio arrivo';

  @override
  String get meetingPointWhoArriving => 'Chi sta arrivando';

  @override
  String meetingPointScheduledAt(String time, String date) {
    return 'Ore $time · $date';
  }

  @override
  String get meetingPointArrived => 'Arrivato/a';

  @override
  String get meetingPointPositionUnavailable => 'Posizione non disponibile';

  @override
  String meetingPointEtaMinutes(int minutes) {
    return '~$minutes min in auto';
  }

  @override
  String get meetingPointNewTitle => 'Nuovo punto d\'incontro';

  @override
  String get meetingPointSearchHint => 'Cerca un luogo o un indirizzo…';

  @override
  String get meetingPointOr => 'oppure';

  @override
  String get meetingPointUseMyLocation => 'Usa la mia posizione attuale';

  @override
  String get meetingPointPositionSet => 'Posizione impostata';

  @override
  String get meetingPointNameHint => 'Nome (es. Ingresso stadio, Bar Roma)';

  @override
  String get meetingPointSetTime => 'Imposta un orario (opzionale)';

  @override
  String meetingPointNoResultsFor(String query) {
    return 'Nessun risultato per \"$query\".';
  }

  @override
  String get meetingPointSearchFailed => 'Ricerca non riuscita. Riprova.';

  @override
  String get meetingPointLocationUnavailable =>
      'Non siamo riusciti a rilevare la tua posizione.';

  @override
  String get meetingPointChooseNameAndLocation =>
      'Scegli un nome e una posizione.';

  @override
  String get meetingPointCreateError =>
      'Non siamo riusciti a creare il punto d\'incontro. Riprova.';

  @override
  String circleMessagesTitle(String circleName) {
    return 'Messaggi · $circleName';
  }

  @override
  String get circleMessagesSendError =>
      'Non siamo riusciti a inviare il messaggio. Riprova.';

  @override
  String get circleMessagesDailyLimitTitle => 'Limite giornaliero raggiunto';

  @override
  String get circleMessagesDailyLimitBody =>
      'Hai già inviato 5 messaggi oggi: è il limite del piano gratuito. Con Kinly+ puoi mandarne quanti vuoi.';

  @override
  String get circleMessagesGotIt => 'Ho capito';

  @override
  String get circleMessagesDiscoverPlus => 'Scopri Kinly+';

  @override
  String get circleMessagesHintPremium =>
      'Solo per avvisi brevi e importanti. Per chiacchierare usa WhatsApp o un\'altra app di messaggistica.';

  @override
  String get circleMessagesHintFree =>
      'Solo per avvisi brevi e importanti (max 5 al giorno nel piano gratuito). Per chiacchierare usa WhatsApp o un\'altra app di messaggistica.';

  @override
  String get circleMessagesEmptyTitle => 'Nessun messaggio ancora';

  @override
  String get circleMessagesEmptyMessage => 'Manda il primo avviso qui sotto.';

  @override
  String get circleMessagesTimeNow => 'ora';

  @override
  String circleMessagesTimeMinutesAgo(int minutes) {
    return '$minutes min fa';
  }

  @override
  String circleMessagesTimeHoursAgo(int hours) {
    return '$hours h fa';
  }

  @override
  String get circleMessagesComposerHint => 'Scrivi un avviso breve...';

  @override
  String get quickMessage1 => 'Sto arrivando 🚗';

  @override
  String get quickMessage2 => 'Sono in ritardo ⏰';

  @override
  String get quickMessage3 => 'Sono arrivato/a 🏠';

  @override
  String get quickMessage4 => 'Tutto ok? 👋';

  @override
  String get quickMessage5 => 'Chiamami quando puoi 📞';

  @override
  String get quickMessage6 => 'Buongiorno ☀️';

  @override
  String get quickMessage7 => 'Buonanotte 🌙';

  @override
  String get quickMessage8 => 'Grazie! ❤️';

  @override
  String get expensesTitle => 'Spese di gruppo';

  @override
  String get expensesNewButton => 'Nuova spesa';

  @override
  String get expensesEmptyTitle => 'Nessuna spesa';

  @override
  String get expensesEmptyMessage =>
      'Tieni traccia di chi ha pagato cosa nella cerchia, senza scriverlo a memoria.';

  @override
  String get expensesBalancesTitle => 'Saldi';

  @override
  String get expensesListTitle => 'Spese';

  @override
  String get expensesSetPaymentLinkHint =>
      'Imposta il tuo link di pagamento in Privacy e sicurezza per farlo pagare più facilmente.';

  @override
  String get expensesLinkCopied => 'Link di pagamento copiato: mandaglielo.';

  @override
  String expensesNoPaymentLink(String name) {
    return '$name non ha impostato un link di pagamento.';
  }

  @override
  String get expensesThisPerson => 'Questa persona';

  @override
  String expensesOwesYou(String name) {
    return '$name ti deve';
  }

  @override
  String expensesYouOwe(String name) {
    return 'Devi a $name';
  }

  @override
  String get expensesRequestBalance => 'Chiedi il saldo';

  @override
  String get expensesPay => 'Paga';

  @override
  String expensesPaidBy(String name) {
    return 'Pagato da $name';
  }

  @override
  String get expensesFillFields =>
      'Compila descrizione, importo e almeno una persona.';

  @override
  String get expensesSaveError =>
      'Non siamo riusciti a salvare la spesa. Riprova.';

  @override
  String get expensesDailyLimitTitle => 'Limite giornaliero raggiunto';

  @override
  String get expensesDailyLimitBody =>
      'Hai già registrato 5 spese oggi: è il limite del piano gratuito. Con Kinly+ puoi registrarne quante vuoi.';

  @override
  String get expensesSplitHint =>
      'La paghi tu: la dividi tra le persone che selezioni qui sotto.';

  @override
  String get expensesDescriptionHint => 'Descrizione (es. Cena, benzina)';

  @override
  String get expensesAmountHint => 'Importo totale (€)';

  @override
  String get expensesSplitBetween => 'Dividi tra';

  @override
  String get expensesSaveButton => 'Salva spesa';

  @override
  String weeklySummaryTitle(String circleName) {
    return 'Riepilogo · $circleName';
  }

  @override
  String get weeklySummaryLoadError =>
      'Non siamo riusciti a caricare il riepilogo.';

  @override
  String get weeklySummaryRetry => 'Riprova';

  @override
  String get weeklySummaryLast7Days => 'Ultimi 7 giorni';

  @override
  String weeklySummaryActivityFor(String circleName) {
    return 'Attività di \"$circleName\", visibile a tutti i membri.';
  }

  @override
  String get weeklySummaryQuietWeek =>
      'Settimana tranquilla: nessun evento da segnalare.';

  @override
  String get weeklySummarySosActivated => 'SOS attivati';

  @override
  String get weeklySummaryHelpRequests => 'Richieste di aiuto';

  @override
  String get weeklySummarySafeZoneEntries => 'Ingressi in aree sicure';

  @override
  String get weeklySummarySpeedAlerts => 'Avvisi di velocità';

  @override
  String get weeklySummaryPushHint =>
      'Puoi ricevere questo riepilogo anche via notifica una volta a settimana: attivalo da Profilo → Privacy e sicurezza.';

  @override
  String get requestsIncoming => 'In arrivo';

  @override
  String get requestsWaitingReply => 'In attesa di risposta';

  @override
  String get requestsHistory => 'Storico';

  @override
  String requestsWantsToSeeYou(String name) {
    return '$name vuole vedere dove sei';
  }

  @override
  String get requestsReject => 'Rifiuta';

  @override
  String get requestsApprove => 'Approva';

  @override
  String requestsWaitingFor(String name) {
    return 'In attesa di $name';
  }

  @override
  String get requestsNotifyOnReply => 'Riceverai una notifica alla risposta';

  @override
  String requestsTheyAskedYou(String name) {
    return '$name ti ha chiesto la posizione';
  }

  @override
  String requestsYouAsked(String name) {
    return 'Hai chiesto la posizione a $name';
  }

  @override
  String get requestsEmptyTitle => 'Nessuna richiesta';

  @override
  String get requestsEmptyMessage =>
      'Quando qualcuno vorrà vedere la tua posizione, o tu quella di qualcun altro, la richiesta apparirà qui.';

  @override
  String get profileStatusFriends => 'Con amici';

  @override
  String get profileStatusHome => 'A casa';

  @override
  String get profileStatusFree => 'Libero/a';

  @override
  String get profileStatusBusyDay => 'Giornata pesante';

  @override
  String get profileStatusPickerTitle => 'Il tuo stato di oggi';

  @override
  String get profileStatusPickerHint =>
      'Visibile alla tua cerchia sulla mappa fino a stanotte.';

  @override
  String get profileStatusCustomHint => 'Oppure scrivi il tuo (con emoji 🙂)';

  @override
  String get profileRemoveStatus => 'Rimuovi stato';

  @override
  String profileActiveCircles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cerchie attive',
      one: '$count cerchia attiva',
    );
    return '$_temp0';
  }

  @override
  String get profileYourStatus => 'Il tuo stato';

  @override
  String get profileAppearance => 'Aspetto';

  @override
  String get profileThemeLight => 'Chiaro';

  @override
  String get profileThemeDark => 'Scuro';

  @override
  String get profileSharingModeHeader => 'Modalità di condivisione';

  @override
  String get profileYourCirclesHeader => 'Le tue cerchie';

  @override
  String profileCirclesManage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cerchie · gestisci membri e inviti',
      one: '$count cerchia · gestisci membri e inviti',
    );
    return '$_temp0';
  }

  @override
  String get profileKinlyPlusHeader => 'Kinly+';

  @override
  String get profileActive => 'Attivo';

  @override
  String get profileNotActive => 'Non attivo';

  @override
  String get profileManageSubscription => 'Gestisci abbonamento Kinly+';

  @override
  String get profileOtherHeader => 'Altro';

  @override
  String get profilePrivacySecurity => 'Privacy e sicurezza';

  @override
  String get profileHelpSupport => 'Aiuto e assistenza';

  @override
  String get profileAdminSupport => 'Assistenza · admin';

  @override
  String get profileReviewOnboarding => 'Rivedi onboarding · admin (test)';

  @override
  String get profileLogout => 'Esci';

  @override
  String get profileFeatureLocationHistoryTitle => 'Cronologia posizioni';

  @override
  String get profileFeatureLocationHistoryDesc =>
      'Rivedi dove sono stati i membri della cerchia nei giorni passati.';

  @override
  String get profileFeatureSafeZonesTitle => 'Aree sicure';

  @override
  String get profileFeatureSafeZonesDesc =>
      'Casa, lavoro, scuola: notifica personalizzata a ogni arrivo o uscita.';

  @override
  String get profileFeatureDrivingAlertsTitle => 'Avvisi di guida';

  @override
  String get profileFeatureDrivingAlertsDesc =>
      'Sappi quando chi guida supera un limite di velocità impostato.';

  @override
  String get profileFeatureBackgroundTrackingTitle =>
      'Tracciamento in background';

  @override
  String get profileFeatureBackgroundTrackingDesc =>
      'La posizione continua ad aggiornarsi anche con l\'app chiusa.';

  @override
  String get profileFeatureUnlimitedTitle =>
      'Messaggi, ping e spese illimitati';

  @override
  String get profileFeatureUnlimitedDesc =>
      'Manda quanti messaggi, ping e spese vuoi, senza limiti.';

  @override
  String get profileFeatureShoppingTitle => 'Portami qualcosa';

  @override
  String get profileFeatureShoppingDesc =>
      'Segnala alla cerchia quando sei al supermercato o al bar.';

  @override
  String get profileFeaturePrioritySupportTitle => 'Assistenza prioritaria';

  @override
  String get profileFeaturePrioritySupportDesc =>
      'Supporto dedicato per la tua cerchia, 7 giorni su 7.';

  @override
  String get privacyTitle => 'Privacy e sicurezza';

  @override
  String get privacyLocationVisibilityInfo =>
      'La tua posizione è visibile solo a chi fa parte di una tua cerchia, e solo secondo la modalità di condivisione che scegli dal profilo (automatica, su richiesta o sospesa).';

  @override
  String get privacySosSmsNumberTitle => 'Numero SOS via SMS';

  @override
  String get privacyPhoneExampleHint => 'Es. +39 333 1234567';

  @override
  String get privacyPlusFeatureTitle => 'Funzione Kinly+';

  @override
  String get privacyCrashDetectionPlusBody =>
      'Il rilevamento incidenti (SOS automatico dopo un urto violento in auto) è un vantaggio Kinly+.';

  @override
  String get privacyBackgroundTrackingPlusBody =>
      'Il tracciamento in background (la posizione continua ad aggiornarsi anche con l\'app chiusa) è un vantaggio Kinly+.';

  @override
  String get privacyEnableBackgroundTrackingTitle =>
      'Attivare il tracciamento in background?';

  @override
  String get privacyEnableBackgroundTrackingBody =>
      'La tua posizione continuerà ad aggiornarsi anche quando Kinly non è in primo piano. Consuma più batteria e mostra sempre una notifica fissa mentre è attivo, come richiesto da Android.';

  @override
  String get privacyExtraStepTitle => 'Serve un passaggio in più';

  @override
  String get privacyExtraStepBody =>
      'Il tuo Android richiede di attivare a mano il permesso di posizione \"Consenti sempre\" dalle impostazioni di sistema, poi torna qui e riattiva l\'interruttore.';

  @override
  String get privacyOpenSettings => 'Apri impostazioni';

  @override
  String get privacyGrantLocationFirst =>
      'Prima serve concedere il permesso di posizione a Kinly.';

  @override
  String get privacyBiometricAuthFailed =>
      'Non siamo riusciti a verificare la tua identità.';

  @override
  String get privacyOtherDevicesSignedOut =>
      'Tutti gli altri dispositivi sono stati disconnessi.';

  @override
  String get privacyOperationFailed =>
      'Non siamo riusciti a completare l\'operazione. Riprova.';

  @override
  String get privacyBirthdayTitle => 'Data di nascita';

  @override
  String get privacyDateHint => 'GG/MM/AAAA';

  @override
  String get privacyInvalidDate => 'Data non valida';

  @override
  String get privacyPaymentLinkTitle => 'Link di pagamento';

  @override
  String get privacyPaymentLinkHint => 'Es. link Satispay, PayPal.me/...';

  @override
  String get privacyPhoneNumberTitle => 'Numero di telefono';

  @override
  String get privacyAccountHeader => 'Account';

  @override
  String get privacyPersonalInfoHeader => 'Info personali';

  @override
  String get privacyBiometricHeader => 'Accesso biometrico';

  @override
  String get privacyBackgroundTrackingHeader => 'Tracciamento in background';

  @override
  String get privacyGhostScheduleHeader => 'Orario di reperibilità';

  @override
  String get privacySosHeader => 'SOS';

  @override
  String get privacySpeedAlertHeader => 'Avviso di velocità';

  @override
  String get privacyWeeklySummaryHeader => 'Riepilogo settimanale';

  @override
  String get privacyGuideHeader => 'Guida';

  @override
  String get privacyChangePassword => 'Cambia password';

  @override
  String get privacySignOutOtherDevices => 'Esci dagli altri dispositivi';

  @override
  String get privacyPersonalInfoHint =>
      'Facoltative: usate solo per un\'iconcina di compleanno tra i membri della cerchia, per aprire un pagamento diretto dalle spese di gruppo e per farti chiamare da chi riceve un tuo SOS o richiesta di aiuto.';

  @override
  String get privacyAddBirthday => 'Aggiungi data di nascita';

  @override
  String privacyBirthdaySet(String date) {
    return 'Compleanno: $date';
  }

  @override
  String get privacyAddPaymentLink => 'Aggiungi link di pagamento';

  @override
  String get privacyPaymentLinkSet => 'Link di pagamento impostato';

  @override
  String get privacyAddPhoneNumber => 'Aggiungi numero di telefono';

  @override
  String privacyPhoneNumberSet(String phone) {
    return 'Numero: $phone';
  }

  @override
  String get privacyBiometricHint =>
      'Richiedi impronta, volto o codice del dispositivo ogni volta che apri Kinly.';

  @override
  String get privacyBiometricUnlock => 'Sblocco biometrico';

  @override
  String get privacyBackgroundTrackingHint =>
      'Per impostazione predefinita Kinly aggiorna la tua posizione solo mentre è aperta. Attivalo per farla continuare anche in background: consuma più batteria e mostra sempre una notifica fissa mentre è attivo.';

  @override
  String get privacyEnableInBackground => 'Attiva in background';

  @override
  String get privacyGhostScheduleHint =>
      'Utile per il lavoro: fuori da questa fascia oraria nessuno vede la tua posizione, in nessuna delle tue cerchie (\"clock-out\" automatico).';

  @override
  String get privacyLimitHours => 'Limita l\'orario';

  @override
  String get privacyFrom => 'Dalle';

  @override
  String get privacyTo => 'Alle';

  @override
  String get privacySosAllCircles =>
      'Per ora avvisa tutte le tue cerchie. Puoi scegliere solo alcune persone.';

  @override
  String privacySosSelectedCount(int count) {
    return 'Avvisa solo $count persone scelte, non tutta la cerchia.';
  }

  @override
  String get privacySosWhoToNotify => 'Chi avvisare in caso di SOS';

  @override
  String get privacySosSmsNumberEmpty => 'Numero SOS via SMS (se sei offline)';

  @override
  String privacySosSmsNumberSet(String number) {
    return 'SOS via SMS: $number';
  }

  @override
  String get privacyCrashDetectionTitle => 'Rilevamento incidenti';

  @override
  String get privacyCrashDetectionDesc =>
      'Dopo un urto violento mentre sei in auto, parte un conto alla rovescia: se non lo annulli, SOS automatico.';

  @override
  String get privacySpeedAlertHint =>
      'Imposta una tua soglia: chi ha Kinly+ nella tua cerchia riceve un avviso se la superi guidando.';

  @override
  String get privacyEnableAlert => 'Attiva avviso';

  @override
  String get privacyThreshold => 'Soglia';

  @override
  String privacySpeedKmh(int speed) {
    return '$speed km/h';
  }

  @override
  String get privacyWeeklySummaryHint =>
      'Una notifica alla settimana con l\'attività della cerchia: SOS, richieste di aiuto, ingressi in aree sicure, avvisi di velocità.';

  @override
  String get privacyReceiveSummary => 'Ricevi il riepilogo';

  @override
  String get privacyReviewCirclesGuide => 'Rivedi la guida delle cerchie';

  @override
  String get changePasswordMismatch => 'Le due password non coincidono.';

  @override
  String get changePasswordGenericError =>
      'Non siamo riusciti a cambiare la password. Riprova.';

  @override
  String get changePasswordDoneTitle => 'Password aggiornata';

  @override
  String get changePasswordDoneBody =>
      'D\'ora in poi usa la nuova password per accedere.';

  @override
  String get changePasswordNew => 'Nuova password';

  @override
  String get changePasswordMinChars => 'Almeno 6 caratteri.';

  @override
  String get changePasswordConfirmHint => 'Conferma password';

  @override
  String get helpFaqsTitle => 'Domande frequenti';

  @override
  String get helpFaq1Q => 'Chi vede la mia posizione?';

  @override
  String get helpFaq1A =>
      'Solo chi fa parte di una tua cerchia, e solo se la tua modalità di condivisione lo permette (automatica, su richiesta o sospesa). Puoi cambiarla in ogni momento dal tuo profilo.';

  @override
  String get helpFaq2Q => 'Come invito qualcuno in una cerchia?';

  @override
  String get helpFaq2A =>
      'Crea una cerchia dalla scheda \"Cerchie\" e condividi il codice invito che ti viene mostrato: chi lo inserisce entra subito a farne parte.';

  @override
  String get helpFaq3Q => 'Cosa cambia con Kinly+?';

  @override
  String get helpFaq3A =>
      'Il piano gratuito ha un limite di 2 cerchie e 6 persone per cerchia. Kinly+ toglie i limiti e sblocca cronologia posizioni, aree sicure e avvisi di guida.';

  @override
  String get helpFaq4Q =>
      'Come cancello un\'area sicura o esco da una cerchia?';

  @override
  String get helpFaq4A =>
      'Le aree sicure si eliminano dalla schermata \"Aree sicure\" di una cerchia (icona del cestino). Per uscire da una cerchia scrivici da qui: te ne aiutiamo a occupare a mano finché non aggiungiamo il pulsante in app.';

  @override
  String get helpWriteToUs => 'Scrivici';

  @override
  String get helpPriorityBadge => 'Priorità Kinly+';

  @override
  String get helpPriorityHint =>
      'Come abbonato Kinly+ la tua richiesta viene messa in coda prioritaria.';

  @override
  String get helpNormalHint =>
      'La tua richiesta resta qui, la leggiamo appena possibile.';

  @override
  String get helpDescribeHint => 'Descrivi il problema o la domanda...';

  @override
  String get helpSend => 'Invia';

  @override
  String get helpSentSnackbar =>
      'Messaggio inviato: lo trovi qui sotto tra le tue richieste.';

  @override
  String get helpSendError =>
      'Non siamo riusciti a inviare il messaggio. Riprova.';

  @override
  String get helpYourRequests => 'Le tue richieste';

  @override
  String get helpNoRequestsYet => 'Non hai ancora inviato nessuna richiesta.';

  @override
  String get helpStatusAnswered => 'Risposto';

  @override
  String get helpStatusClosed => 'Chiuso';

  @override
  String get helpStatusInProgress => 'In corso';

  @override
  String get adminSupportNoMessages => 'Nessun messaggio.';

  @override
  String get adminSupportPriority => 'Priorità';

  @override
  String adminSupportRepliedWith(String reply) {
    return 'Risposto: $reply';
  }

  @override
  String get adminSupportReplyError =>
      'Non siamo riusciti a inviare la risposta. Riprova.';

  @override
  String get adminSupportReplyTitle => 'Rispondi';

  @override
  String get adminSupportReplyHint => 'Scrivi la risposta...';

  @override
  String get adminSupportSendReply => 'Invia risposta';

  @override
  String get avatarUploadError =>
      'Non siamo riusciti a caricare la foto. Riprova.';

  @override
  String get avatarChooseFromGallery => 'Scegli dalla galleria';

  @override
  String get avatarTakePhoto => 'Scatta una foto';

  @override
  String get avatarRemovePhoto => 'Rimuovi foto';

  @override
  String get avatarPickerTitle => 'Scegli il tuo avatar';

  @override
  String get avatarChangePhoto => 'Cambia foto';

  @override
  String get avatarUploadPhoto => 'Carica una foto';

  @override
  String get avatarThemedTitle => 'Avatar a tema';

  @override
  String get avatarThemedHint => 'Usati quando non hai caricato una foto.';

  @override
  String get avatarUseInitials => 'Usa le iniziali';

  @override
  String get personLocationNotShared => 'Posizione non condivisa';

  @override
  String get personBirthdayToday => '🎂 Oggi è il suo compleanno!';

  @override
  String personUpdatedAt(String label) {
    return 'Aggiornato $label';
  }

  @override
  String personBatteryPercent(int percent) {
    return 'Batteria $percent%';
  }

  @override
  String get personRadarLink => 'Radar di prossimità';

  @override
  String get personLocationHistoryLink => 'Cronologia posizioni';

  @override
  String get personStatisticsLink => 'Statistiche e itinerari';

  @override
  String get personDrivingAlertsLink => 'Avvisi di guida';

  @override
  String get personSharingWithYou => 'Sta condividendo la posizione con te.';

  @override
  String get personGhostMode =>
      'È in modalità fantasma: non può ricevere richieste in questo momento.';

  @override
  String get personRequestSent => 'Richiesta inviata';

  @override
  String get personRequestLocation => 'Richiedi posizione';

  @override
  String get personPingDailyLimitTitle => 'Limite giornaliero raggiunto';

  @override
  String get personPingDailyLimitBody =>
      'Hai già mandato 5 ping oggi: è il limite del piano gratuito. Con Kinly+ puoi mandarne quanti vuoi.';

  @override
  String get personPingSent => 'Inviato';

  @override
  String sosAlertTitle(String name) {
    return 'SOS · $name';
  }

  @override
  String get sosAlertCancelError =>
      'Non siamo riusciti ad annullare l\'SOS. Riprova.';

  @override
  String get sosYourAlertActive => 'Il tuo SOS è attivo';

  @override
  String sosPersonActivated(String name) {
    return '$name ha attivato l\'SOS';
  }

  @override
  String sosActivatedAt(String time) {
    return 'Attivato alle $time';
  }

  @override
  String get sosWaitingAddress => 'In attesa dell\'indirizzo...';

  @override
  String get sosEmergencyHint =>
      'In caso di reale emergenza chiama il 112. Kinly condivide solo la posizione: nessuna registrazione audio.';

  @override
  String sosCallPerson(String name) {
    return 'Chiama $name';
  }

  @override
  String get sosImSafeCancelSos => 'Sono al sicuro, annulla SOS';

  @override
  String helpRequestTitle(String name) {
    return 'Aiuto · $name';
  }

  @override
  String get helpRequestCloseError =>
      'Non siamo riusciti a chiudere la richiesta. Riprova.';

  @override
  String helpRequestYouAsked(String reason) {
    return 'Hai chiesto aiuto: $reason';
  }

  @override
  String helpRequestPersonNeeds(String name, String reason) {
    return '$name ha bisogno di aiuto: $reason';
  }

  @override
  String helpRequestRequestedAt(String time) {
    return 'Richiesto alle $time';
  }

  @override
  String get helpRequestCloseButton => 'Va tutto bene, chiudi richiesta';

  @override
  String get sosContactsTitle => 'Contatti SOS';

  @override
  String get sosContactsNoneSelected =>
      'Nessuno selezionato: l\'SOS avviserà tutte le persone delle tue cerchie.';

  @override
  String sosContactsSelectedCount(int count) {
    return 'L\'SOS avviserà solo le $count persone selezionate, non tutta la cerchia.';
  }

  @override
  String get sosContactsEmpty => 'Non hai ancora nessuno nelle tue cerchie.';

  @override
  String radarTitle(String name) {
    return 'Radar · $name';
  }

  @override
  String get radarPermissionNeeded =>
      'Serve il permesso di localizzazione per usare il radar.';

  @override
  String radarPersonNotSharing(String name) {
    return '$name non sta condividendo la posizione al momento.';
  }

  @override
  String get radarCompassUnavailable =>
      'Bussola non disponibile su questo dispositivo. Usa la mappa per orientarti.';

  @override
  String get radarVeryClose => 'Sei vicinissimo!';

  @override
  String radarFollowArrow(String name) {
    return 'Segui la freccia per raggiungere $name';
  }

  @override
  String get paywallFeatureLocationHistoryTitle => 'Cronologia posizioni';

  @override
  String get paywallFeatureLocationHistoryDesc =>
      'Rivedi dove sono stati i membri della cerchia nei giorni passati.';

  @override
  String get paywallFeatureStatsTitle => 'Statistiche e itinerari';

  @override
  String get paywallFeatureStatsDesc =>
      'Distanza percorsa e mappa dei tragitti fatti, ricostruiti dallo storico.';

  @override
  String get paywallFeatureSafeZonesTitle => 'Aree sicure';

  @override
  String get paywallFeatureSafeZonesDesc =>
      'Casa, lavoro, scuola: ricevi una notifica personalizzata quando qualcuno arriva o esce.';

  @override
  String get paywallFeatureUnlimitedCirclesTitle => 'Cerchie senza limiti';

  @override
  String get paywallFeatureUnlimitedCirclesDesc =>
      'Nessun limite al numero di cerchie o di persone per cerchia.';

  @override
  String get paywallFeatureDrivingTitle => 'Avvisi di guida';

  @override
  String get paywallFeatureDrivingDesc =>
      'Sappi quando chi guida supera un limite di velocità impostato.';

  @override
  String get paywallFeatureBackgroundTitle => 'Tracciamento in background';

  @override
  String get paywallFeatureBackgroundDesc =>
      'La posizione continua ad aggiornarsi anche con l\'app chiusa.';

  @override
  String get paywallFeatureUnlimitedMsgTitle =>
      'Messaggi, ping e spese illimitati';

  @override
  String get paywallFeatureUnlimitedMsgDesc =>
      'Manda quanti messaggi, ping e spese vuoi, senza il limite giornaliero.';

  @override
  String get paywallFeatureShoppingTitle => 'Portami qualcosa';

  @override
  String get paywallFeatureShoppingDesc =>
      'Segnala alla cerchia quando sei al supermercato o al bar, per farti chiedere qualcosa al volo.';

  @override
  String get paywallFeaturePriorityTitle => 'Assistenza prioritaria';

  @override
  String get paywallFeaturePriorityDesc =>
      'Supporto dedicato per la tua cerchia, 7 giorni su 7.';

  @override
  String get paywallRequestError =>
      'Non siamo riusciti a inviare la richiesta. Riprova.';

  @override
  String get paywallCancelMessage =>
      'Vorrei annullare il mio abbonamento Kinly+.';

  @override
  String paywallUpgradeMessage(String plan) {
    return 'Vorrei attivare il piano Kinly+ $plan.';
  }

  @override
  String get paywallComingSoonTitle => 'In arrivo';

  @override
  String get paywallComingSoonBody =>
      'I pagamenti Kinly+ non sono ancora attivi: abbiamo registrato la tua richiesta, ti attiveremo il piano a mano.';

  @override
  String get paywallFamilyActive => 'Kinly+ Family attivo';

  @override
  String get paywallIndividualActive => 'Kinly+ Individual attivo';

  @override
  String get paywallIncluded => 'Kinly+ incluso';

  @override
  String paywallIncludedInFamilyOf(String name) {
    return 'Incluso nel piano Family di $name';
  }

  @override
  String get paywallYourSubscriptionActive => 'Il tuo abbonamento è attivo';

  @override
  String get paywallMorePeaceOfMind => 'Più tranquillità per tutta la cerchia';

  @override
  String get paywallFamilyIncludedHint =>
      'Finché fai parte della sua cerchia, hai tutti i vantaggi Kinly+ senza pagare nulla.';

  @override
  String get paywallAllUnlockedHint =>
      'Tutti i vantaggi qui sotto sono sbloccati per te e per le tue cerchie.';

  @override
  String get paywallChooseTierHint =>
      'Un piano Individual sblocca i vantaggi solo per te; un piano Family li estende a chi inviti.';

  @override
  String get paywallWhatIncludes => 'Cosa include';

  @override
  String get paywallComparePlans => 'Confronta i piani';

  @override
  String get paywallFamilyMemberHint =>
      'Non paghi nulla: chi ha creato quella cerchia con il piano Family ha esteso Kinly+ a te e agli altri primi membri (fino a 6).';

  @override
  String get paywallYourFamilyPlan => 'Il tuo piano Family';

  @override
  String get paywallFamilyOwnerHint =>
      'Chi entra in una cerchia che hai creato (fino a 6 persone, in base a quando sono entrate) ha Kinly+ incluso, senza pagare nulla.';

  @override
  String get paywallRequestSent => 'Richiesta inviata.';

  @override
  String get paywallRequestCancellation => 'Richiedi annullamento';

  @override
  String get paywallManageSubscription => 'Gestisci abbonamento';

  @override
  String get paywallIndividualCancelHint =>
      'Il tuo Kinly+ non è ancora collegato a un pagamento reale. Per disattivarlo, invia una richiesta: te lo disattiviamo a mano.';

  @override
  String get paywallSwitchToFamily => 'Passa a Family';

  @override
  String get paywallFamilyPrice => '9,90 €';

  @override
  String get paywallIndividualPrice => '3,90 €';

  @override
  String get paywallFamilyUpgradeDesc =>
      'Estendi Kinly+ anche a chi inviti nelle cerchie che crei (fino a 6 persone), non solo a te.';

  @override
  String get paywallIndividualTitle => 'Individual';

  @override
  String get paywallIndividualDesc =>
      'Sblocca tutti i vantaggi Kinly+ per te, in tutte le tue cerchie.';

  @override
  String get paywallSwitchToIndividual => 'Passa a Individual';

  @override
  String get paywallFamilyTitle => 'Family';

  @override
  String get paywallFamilyDesc =>
      'Un solo abbonamento: chi entra in una cerchia che crei (fino a 6 persone) ha Kinly+ incluso.';

  @override
  String get paywallDesignPreviewHint =>
      'Anteprima del design: i pagamenti non sono ancora attivi.';

  @override
  String get paywallPerMonth => ' / mese';

  @override
  String get paywallCompareCirclesMembers => 'Cerchie e membri';

  @override
  String get paywallCompareFreeCircleLimit => 'Fino a 2 / 6';

  @override
  String get paywallCompareUnlimited => 'Illimitati';

  @override
  String get paywallCompareMessagesPingExpenses => 'Messaggi, ping, spese';

  @override
  String get paywallCompare5PerDay => '5 al giorno';

  @override
  String get paywallCompareSafeZonesCreate => 'Aree sicure (creare)';

  @override
  String get paywallCompareWhoBenefits => 'Chi beneficia';

  @override
  String get paywallCompareOnlyYou => 'Solo tu';

  @override
  String get paywallCompareUpTo6People => 'Fino a 6 persone';

  @override
  String get paywallComparePrice => 'Prezzo';

  @override
  String get paywallCompareFree => 'Gratis';

  @override
  String get paywallCompareIndividualPricePerMonth => '3,90 €/mese';

  @override
  String get paywallCompareFamilyPricePerMonth => '9,90 €/mese';

  @override
  String get paywallTierFree => 'Free';

  @override
  String get paywallPlanLabelIndividual => 'Individual (3,90€/mese)';

  @override
  String get paywallPlanLabelFamily => 'Family (9,90€/mese)';

  @override
  String safeZonesTitle(String circle) {
    return 'Aree sicure · $circle';
  }

  @override
  String get safeZonesEmptyTitleFree => 'Nessuna area sicura';

  @override
  String get safeZonesEmptyMessagePremium =>
      'Crea un\'area (ad esempio casa o scuola) per ricevere una notifica quando qualcuno entra o esce.';

  @override
  String get safeZonesEmptyMessageFree =>
      'Passa a Kinly+ per creare aree sicure e ricevere una notifica quando qualcuno arriva o esce da un luogo.';

  @override
  String get safeZonesCreateFirst => 'Crea la prima area';

  @override
  String get safeZonesSuggestedForYou => 'Suggerite per te';

  @override
  String safeZonesFrequentVisit(int days) {
    return 'Ci vai spesso ($days giorni diversi) · tocca per creare un\'area';
  }

  @override
  String safeZonesKindRadius(String kindLabel, int radius) {
    return '$kindLabel · Raggio $radius m';
  }

  @override
  String get safeZonesEditTooltip => 'Modifica area';

  @override
  String get safeZonesDeleteTooltip => 'Elimina area';

  @override
  String get safeZonesLastEntry => 'Ultimo ingresso registrato';

  @override
  String get safeZonesLastExit => 'Ultima uscita registrata';

  @override
  String get safeZonesEditTitle => 'Modifica area sicura';

  @override
  String get safeZonesNewTitle => 'Nuova area sicura';

  @override
  String get safeZonesNameHint => 'Nome (es. Casa, Scuola)';

  @override
  String get safeZonesPlaceType => 'Tipo di luogo';

  @override
  String safeZonesRadiusMeters(int radius) {
    return 'Raggio: $radius m';
  }

  @override
  String safeZonesRadiusValue(int radius) {
    return '$radius m';
  }

  @override
  String get safeZonesOrEnterAddress => 'Oppure inserisci un indirizzo';

  @override
  String get safeZonesAddressNotFound =>
      'Indirizzo non trovato. Prova a essere più preciso.';

  @override
  String get safeZonesAddressSearchError =>
      'Non siamo riusciti a cercare questo indirizzo. Riprova.';

  @override
  String get safeZonesPlusOnly => 'Le aree sicure sono una funzione Kinly+.';

  @override
  String get safeZonesSaveChangesError =>
      'Non siamo riusciti a salvare le modifiche. Riprova.';

  @override
  String get safeZonesCreateError =>
      'Non siamo riusciti a creare l\'area. Riprova.';

  @override
  String get safeZonesSaveChanges => 'Salva modifiche';

  @override
  String get safeZonesCreateButton => 'Crea area';

  @override
  String get historyDeleteConfirmTitle => 'Cancellare la cronologia?';

  @override
  String get historyDeleteConfirmBody =>
      'Elimina tutti i punti registrati finora, incluse le statistiche di itinerari già calcolate da questi dati. Non si può annullare.';

  @override
  String get historyDeleteButton => 'Cancella';

  @override
  String get historyDeletedSnackbar => 'Cronologia cancellata.';

  @override
  String get historyDeleteError =>
      'Non siamo riusciti a cancellare la cronologia. Riprova.';

  @override
  String historyTitle(String name) {
    return 'Cronologia · $name';
  }

  @override
  String get historyDeleteTooltip => 'Cancella cronologia';

  @override
  String get historyUpsellMessage =>
      'Passa a Kinly+ per rivedere dove sono stati i membri della cerchia nei giorni passati.';

  @override
  String get historyEmpty => 'Ancora nessuno storico disponibile.';

  @override
  String historyToday(String time) {
    return 'Oggi, $time';
  }

  @override
  String statsTitle(String name) {
    return 'Statistiche · $name';
  }

  @override
  String get statsUpsellMessage =>
      'Passa a Kinly+ per vedere quanta strada avete fatto e rivedere gli itinerari percorsi.';

  @override
  String get statsNoTripsYet =>
      'Ancora nessun itinerario disponibile: torna qui dopo qualche spostamento.';

  @override
  String get statsLast7Days => 'Ultimi 7 giorni';

  @override
  String get statsLast30Days => 'Ultimi 30 giorni';

  @override
  String get statsWeeklySummary => 'Riepilogo settimanale';

  @override
  String statsTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tragitti',
      one: '$count tragitto',
    );
    return '$_temp0';
  }

  @override
  String get statsRecentTrips => 'Itinerari recenti';

  @override
  String get statsTripLabel => 'Itinerario';

  @override
  String get statsDeparture => 'Partenza';

  @override
  String get statsArrival => 'Arrivo';

  @override
  String get statsDistance => 'Distanza';

  @override
  String get statsDuration => 'Durata';

  @override
  String statsMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String statsDateAndMinutes(String date, int minutes) {
    return '$date · $minutes min';
  }

  @override
  String get statsDayMon => 'L';

  @override
  String get statsDayTue => 'M';

  @override
  String get statsDayWed => 'M';

  @override
  String get statsDayThu => 'G';

  @override
  String get statsDayFri => 'V';

  @override
  String get statsDaySat => 'S';

  @override
  String get statsDaySun => 'D';

  @override
  String speedAlertsTitle(String name) {
    return 'Avvisi di guida · $name';
  }

  @override
  String get speedAlertsUpsellMessage =>
      'Passa a Kinly+ per sapere quando chi guida supera il limite di velocità che si è impostato.';

  @override
  String get speedAlertsEmpty =>
      'Nessun avviso registrato: questa persona non ha ancora superato la soglia di velocità impostata (o non l\'ha impostata).';

  @override
  String speedAlertsKmhLimit(int speed, int threshold) {
    return '$speed km/h (limite $threshold km/h)';
  }

  @override
  String get commonRetry => 'Riprova';

  @override
  String get commonContinue => 'Continua';

  @override
  String get biometricLockedTitle => 'Kinly è bloccata';

  @override
  String get biometricLockedMessage =>
      'Sblocca con l\'impronta, il volto o il codice del dispositivo per continuare.';

  @override
  String get biometricUnlockButton => 'Sblocca';

  @override
  String get splashConnectionError =>
      'Non riusciamo a contattare Kinly. Controlla la connessione e riprova.';

  @override
  String get onboardingWelcomeTitle => 'Benvenuto in Kinly';

  @override
  String get onboardingWelcomeDesc =>
      'Condividi la tua posizione solo con chi conta davvero: famiglia, amici, colleghi. Accesso sempre su invito, mai pubblico.';

  @override
  String get onboardingSafeTitle => 'Sempre al sicuro';

  @override
  String get onboardingSafeDesc =>
      'SOS e \"Chiedi aiuto\" avvisano subito la tua cerchia in caso di bisogno. Le aree sicure ti dicono quando qualcuno arriva o esce da casa, lavoro o scuola.';

  @override
  String get onboardingContactTitle => 'Restate in contatto';

  @override
  String get onboardingContactDesc =>
      'Messaggi rapidi, punto d\'incontro condiviso e meteo della zona: tutto in un posto solo, senza dover chiedere \"dove sei?\".';

  @override
  String get onboardingStart => 'Inizia';

  @override
  String get onboardingSkip => 'Salta';

  @override
  String get onboardingBiometricTitle => 'Proteggi l\'accesso';

  @override
  String get onboardingBiometricDesc =>
      'Attiva subito lo sblocco con impronta, volto o codice del dispositivo: un livello in più oltre alla password, verificato dal sistema (Kinly non vede mai i tuoi dati biometrici).';

  @override
  String get createCircleTitle => 'Crea la tua cerchia';

  @override
  String get circleLimitCirclesMessage =>
      'Nel piano gratuito puoi far parte di massimo 2 cerchie. Passa a Kinly+ per non avere limiti.';

  @override
  String get createCircleError =>
      'Non siamo riusciti a creare la cerchia. Riprova.';

  @override
  String get createCircleNameQuestion => 'Come si chiama?';

  @override
  String get createCircleNameHint =>
      'Ad esempio \"Famiglia\" o \"Weekend in montagna\".';

  @override
  String get createCircleNameField => 'Nome della cerchia';

  @override
  String get createCircleIconLabel => 'Icona';

  @override
  String get createCircleColorLabel => 'Colore';

  @override
  String get createCircleSubmit => 'Crea la cerchia';

  @override
  String createCircleSuccessTitle(String name) {
    return '\"$name\" è pronta!';
  }

  @override
  String get createCircleSuccessMessage =>
      'Condividi questo codice con chi vuoi invitare. Solo chi lo ha può entrare.';

  @override
  String get createCircleCodeCopied => 'Codice copiato';

  @override
  String get createCircleCopyCode => 'Copia codice';

  @override
  String get joinCircleTitle => 'Entra in una cerchia';

  @override
  String get joinCircleQuestion => 'Inserisci il codice di invito';

  @override
  String get joinCircleHint =>
      'Te lo manda chi ha creato la cerchia, ad esempio via messaggio.';

  @override
  String get joinCircleInvalidCode =>
      'Codice non valido. Chiedi a chi ti ha invitato di controllarlo.';

  @override
  String get joinCircleMemberLimitMessage =>
      'Questa cerchia ha già raggiunto il limite di 6 persone del piano gratuito.';

  @override
  String get joinCircleError =>
      'Non siamo riusciti a verificare il codice. Riprova.';

  @override
  String get joinCircleSubmit => 'Entra';

  @override
  String get joinCircleFormatHint =>
      'Chiedi il codice a chi ha creato la cerchia: ha il formato XXX-0000.';

  @override
  String get sharingModeAutomatic => 'Automatica';

  @override
  String get sharingModeOnRequest => 'Su richiesta';

  @override
  String get sharingModePaused => 'Sospesa';

  @override
  String get sharingModeFuzzy => 'Approssimativa';

  @override
  String get sharingModeAutomaticDesc =>
      'La tua posizione è sempre visibile alla tua cerchia, in tempo reale.';

  @override
  String get sharingModeOnRequestDesc =>
      'Nessuno vede la tua posizione finché non approvi una richiesta.';

  @override
  String get sharingModePausedDesc =>
      'Modalità fantasma: sei invisibile, nessuno può chiedere dove sei.';

  @override
  String get sharingModeFuzzyDesc =>
      'La tua cerchia vede solo la zona (circa 1 km), mai il punto esatto.';

  @override
  String get helpReqReasonFlatTire => 'Gomma bucata';

  @override
  String get helpReqReasonAccident => 'Incidente';

  @override
  String get helpReqReasonFollowed => 'Mi sento seguito/a';

  @override
  String get helpReqReasonLowBattery => 'Batteria scarica';

  @override
  String get helpReqReasonOther => 'Altro';

  @override
  String get pingKindCoffee => 'Un caffè?';

  @override
  String get pingKindTraffic => 'Occhio al traffico';

  @override
  String get pingKindHighFive => 'High five';

  @override
  String get safeZoneKindHome => 'Casa';

  @override
  String get safeZoneKindWork => 'Lavoro';

  @override
  String get safeZoneKindSchool => 'Scuola';

  @override
  String get safeZoneKindOther => 'Altro';

  @override
  String get personLastUpdateNow => 'Proprio ora';

  @override
  String personLastUpdateMinutes(int minutes) {
    return '$minutes min fa';
  }

  @override
  String personLastUpdateHours(int hours) {
    return '$hours h fa';
  }

  @override
  String personLastUpdateDays(int days) {
    return '$days g fa';
  }

  @override
  String get weatherClear => 'Sereno';

  @override
  String get weatherPartlyCloudy => 'Poco nuvoloso';

  @override
  String get weatherOvercast => 'Coperto';

  @override
  String get weatherFog => 'Nebbia';

  @override
  String get weatherDrizzle => 'Pioggerella';

  @override
  String get weatherRain => 'Pioggia';

  @override
  String get weatherSnow => 'Neve';

  @override
  String get weatherShowers => 'Rovesci';

  @override
  String get weatherSnowShowers => 'Rovesci di neve';

  @override
  String get weatherStorm => 'Temporale';

  @override
  String get weatherNow => 'Al momento';

  @override
  String get tripReplayPause => 'Pausa';

  @override
  String get tripReplayWatch => 'Rivedi il tragitto';

  @override
  String get mapWaitingForLocation => 'In attesa della posizione…';

  @override
  String get pwaInstallTitle => 'Installa Kinly';

  @override
  String get pwaInstallAndroidBody =>
      'Aggiungila alla schermata Home: si apre più veloce e non occupa spazio extra.';

  @override
  String get pwaInstallButton => 'Installa';

  @override
  String get pwaInstallIosBody =>
      'Tocca Condividi, poi \"Aggiungi alla schermata Home\".';
}
