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
  String get authPasswordTooShort => 'La password deve avere almeno 6 caratteri.';

  @override
  String get authAccountCreated => 'Account creato: controlla la tua email per confermarlo prima di accedere.';

  @override
  String authGenericError(String error) {
    return 'Qualcosa è andato storto. Riprova.\n$error';
  }

  @override
  String get authPrivacyHint => 'Nessuno vede la tua posizione senza il tuo permesso.';

  @override
  String get authBackToWebsite => 'Torna al sito Kinly';

  @override
  String get welcomeCreateCircle => 'Crea la tua cerchia';

  @override
  String get welcomeJoinCircle => 'Ho un codice di invito';

  @override
  String get welcomeInviteOnlyHint => 'Accesso solo su invito. Nessuno vede la tua posizione senza il tuo permesso.';

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
  String get commonCancel => 'Annulla';

  @override
  String get commonClose => 'Chiudi';

  @override
  String get commonNo => 'No';

  @override
  String get commonSomeone => 'Qualcuno';

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
  String get mapLocationUnavailable => 'Non siamo riusciti a rilevare la tua posizione.';

  @override
  String get mapSosConfirmTitle => 'Attivare l\'SOS?';

  @override
  String get mapSosConfirmBody => 'La tua posizione esatta verrà condivisa subito con tutte le tue cerchie, anche se hai una modalità di condivisione ridotta. Nessuna registrazione audio: solo posizione.';

  @override
  String get mapActivateSos => 'Attiva SOS';

  @override
  String get mapLocationUnavailableForSos => 'Non siamo riusciti a rilevare la tua posizione per l\'SOS.';

  @override
  String get mapSosNotSentOffline => 'SOS non inviato (sei offline?). Imposta un numero SOS via SMS in Privacy e sicurezza per avere un piano B.';

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
  String get mapWalkMeHomeDescription => 'Scegli in quanto tempo prevedi di arrivare: se non confermi entro quel tempo (o non entri in un\'area Casa), la tua cerchia riceve automaticamente un avviso con la tua posizione.';

  @override
  String mapWalkMeHomeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get mapWalkMeHomeNote => 'Nota: se il telefono chiude del tutto l\'app prima della scadenza, l\'avviso automatico potrebbe non partire.';

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
  String get mapShareLocationLinkBody => 'Chi riceve il link vede la tua posizione live dal browser, anche senza l\'app. Il link scade da solo.';

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
  String get mapLinkCreateError => 'Non siamo riusciti a creare il link. Riprova.';

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
  String get mapEmptyCircleMessage => 'Invita una persona nella cerchia per vederla sulla mappa.';

  @override
  String get mapAllCirclesChip => 'Tutte';

  @override
  String get mapWebNotice => 'Stai usando la versione web di Kinly: qui la posizione si aggiorna solo mentre questa scheda è aperta. Per il tracciamento continuo, notifiche push e sblocco biometrico serve l\'app.';

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
  String get mapHelpRequestDescription => 'Avvisa la tua cerchia con un motivo e la tua posizione attuale. A differenza dell\'SOS, non cambia la tua modalità di condivisione.';

  @override
  String get mapCircleLabel => 'Cerchia';

  @override
  String get mapReasonLabel => 'Motivo';

  @override
  String get mapNoteHint => 'Aggiungi un dettaglio (opzionale)';

  @override
  String get mapSendRequest => 'Invia richiesta';

  @override
  String get mapNeedCircleForHelp => 'Crea o entra in una cerchia prima di chiedere aiuto.';

  @override
  String get mapHelpRequestSendError => 'Non siamo riusciti a inviare la richiesta. Riprova.';

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
  String get circlesModeOverrideHint => 'Vale solo per questa cerchia: nelle altre resta quella generale del tuo profilo.';

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
  String get circlesCoachStep1Body => 'Ogni cerchia ha i suoi membri, la sua icona e le sue impostazioni: puoi averne più di una.';

  @override
  String get circlesCoachStep2Title => 'Le azioni della cerchia';

  @override
  String get circlesCoachStep2Body => 'Da qui gestisci aree sicure, punto d\'incontro, messaggi, spese di gruppo e il riepilogo settimanale.';

  @override
  String get circlesCoachStep3Title => 'Codice di invito';

  @override
  String get circlesCoachStep3Body => 'Tocca per copiarlo: solo chi lo riceve da te può entrare in questa cerchia.';

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
  String get meetingPointEmptyMessage => 'Proponi un luogo dove ritrovarvi: tutti vedranno la propria distanza in tempo reale, senza scriversi \"dove sei?\".';

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
  String get meetingPointLocationUnavailable => 'Non siamo riusciti a rilevare la tua posizione.';

  @override
  String get meetingPointChooseNameAndLocation => 'Scegli un nome e una posizione.';

  @override
  String get meetingPointCreateError => 'Non siamo riusciti a creare il punto d\'incontro. Riprova.';

  @override
  String circleMessagesTitle(String circleName) {
    return 'Messaggi · $circleName';
  }

  @override
  String get circleMessagesSendError => 'Non siamo riusciti a inviare il messaggio. Riprova.';

  @override
  String get circleMessagesDailyLimitTitle => 'Limite giornaliero raggiunto';

  @override
  String get circleMessagesDailyLimitBody => 'Hai già inviato 5 messaggi oggi: è il limite del piano gratuito. Con Kinly+ puoi mandarne quanti vuoi.';

  @override
  String get circleMessagesGotIt => 'Ho capito';

  @override
  String get circleMessagesDiscoverPlus => 'Scopri Kinly+';

  @override
  String get circleMessagesHintPremium => 'Solo per avvisi brevi e importanti. Per chiacchierare usa WhatsApp o un\'altra app di messaggistica.';

  @override
  String get circleMessagesHintFree => 'Solo per avvisi brevi e importanti (max 5 al giorno nel piano gratuito). Per chiacchierare usa WhatsApp o un\'altra app di messaggistica.';

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
  String get expensesEmptyMessage => 'Tieni traccia di chi ha pagato cosa nella cerchia, senza scriverlo a memoria.';

  @override
  String get expensesBalancesTitle => 'Saldi';

  @override
  String get expensesListTitle => 'Spese';

  @override
  String get expensesSetPaymentLinkHint => 'Imposta il tuo link di pagamento in Privacy e sicurezza per farlo pagare più facilmente.';

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
  String get expensesFillFields => 'Compila descrizione, importo e almeno una persona.';

  @override
  String get expensesSaveError => 'Non siamo riusciti a salvare la spesa. Riprova.';

  @override
  String get expensesDailyLimitTitle => 'Limite giornaliero raggiunto';

  @override
  String get expensesDailyLimitBody => 'Hai già registrato 5 spese oggi: è il limite del piano gratuito. Con Kinly+ puoi registrarne quante vuoi.';

  @override
  String get expensesSplitHint => 'La paghi tu: la dividi tra le persone che selezioni qui sotto.';

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
  String get weeklySummaryLoadError => 'Non siamo riusciti a caricare il riepilogo.';

  @override
  String get weeklySummaryRetry => 'Riprova';

  @override
  String get weeklySummaryLast7Days => 'Ultimi 7 giorni';

  @override
  String weeklySummaryActivityFor(String circleName) {
    return 'Attività di \"$circleName\", visibile a tutti i membri.';
  }

  @override
  String get weeklySummaryQuietWeek => 'Settimana tranquilla: nessun evento da segnalare.';

  @override
  String get weeklySummarySosActivated => 'SOS attivati';

  @override
  String get weeklySummaryHelpRequests => 'Richieste di aiuto';

  @override
  String get weeklySummarySafeZoneEntries => 'Ingressi in aree sicure';

  @override
  String get weeklySummarySpeedAlerts => 'Avvisi di velocità';

  @override
  String get weeklySummaryPushHint => 'Puoi ricevere questo riepilogo anche via notifica una volta a settimana: attivalo da Profilo → Privacy e sicurezza.';
}
