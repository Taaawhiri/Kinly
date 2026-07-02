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
}
