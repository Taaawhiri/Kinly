import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../l10n/app_localizations.dart';
import '../models/meetup.dart';
import '../models/safe_zone.dart';
import '../state/app_state.dart';
import '../state/locale_controller.dart';
import '../utils/address_formatter.dart';
import 'background_tracking_settings.dart';
import 'ios_significant_location_bridge.dart';
import 'kinly_repository.dart';
import 'place_search_service.dart';
import 'push_notification_service.dart';
import 'walk_me_home_service.dart';

/// Esito del tentativo di attivare il tracciamento in background: usato
/// dalla UI per decidere quale messaggio mostrare.
enum BackgroundTrackingResult {
  /// Il permesso "sempre" è stato concesso e il servizio è ora attivo.
  enabled,

  /// Android richiede di concedere il permesso "sempre" dalle impostazioni
  /// di sistema (succede quasi sempre da Android 11 in poi).
  needsSystemSettings,

  /// Il permesso di base per la posizione non è ancora concesso.
  locationPermissionDenied,
}

/// Traccia la posizione reale del dispositivo e la carica su Supabase,
/// insieme al livello di batteria. La visibilità per gli altri è decisa dal
/// database (RLS) in base alla modalità di condivisione: qui ci limitiamo a
/// tenere aggiornati i nostri dati quando la modalità non è "sospesa".
class LocationTracker with WidgetsBindingObserver {
  LocationTracker._();
  static final instance = LocationTracker._();

  StreamSubscription<Position>? _positionSub;
  Timer? _batteryTimer;
  final _battery = Battery();

  /// "Sto ancora tracciando" a orologio, indipendente dal GPS: senza,
  /// restando fermi per un po' (distanceFilter = 30m: niente scatta finché
  /// non ci si muove abbastanza) l'ultimo aggiornamento diventerebbe
  /// vecchio pur essendo l'app perfettamente viva, indistinguibile da un
  /// vero "l'app è chiusa/il telefono ha smesso di tracciare". Riscrivere
  /// lo stesso punto con un orario fresco ogni tot minuti rende invece
  /// "ultimo aggiornamento recente" un segnale affidabile per il pallino
  /// verde "in linea" (vedi Person.isStale) — se anche il battito si ferma,
  /// vuol dire che l'app davvero non gira più.
  Timer? _heartbeatTimer;
  Position? _lastPosition;
  String? _lastAddress;
  static const _heartbeatInterval = Duration(minutes: 4);

  /// Riavvio dello stream dopo un errore/chiusura inattesa (vedi
  /// _handleStreamDown): su alcuni dispositivi, usare un'altra app che
  /// richiede il GPS (tipicamente un navigatore come Google Maps) può far
  /// morire in silenzio lo stream di posizione in background senza che
  /// Kinly se ne accorga da solo — prima restava così finché non si
  /// riapriva l'app a mano.
  Timer? _restartTimer;
  int _restartAttempts = 0;
  static const _maxRestartAttempts = 5;
  bool _observingLifecycle = false;
  // Evita che due percorsi (il timer di riavvio e il guardiano nel battito)
  // creino due stream di posizione in parallelo, con doppie scritture e un
  // listener che resta appeso senza mai essere cancellato.
  bool _subscribing = false;
  // Evita che due start() concorrenti (avvio app + ritorno in primo piano)
  // creino timer doppi prima che _positionSub sia impostato.
  bool _starting = false;

  /// Ultimo stato noto (dentro/fuori) per ogni area sicura, per capire
  /// quando avviene un ingresso o un'uscita senza avvisare al primo
  /// controllo dopo l'avvio (che non è una transizione reale).
  final Map<String, bool> _zoneInsideState = {};

  /// Se ero già sopra la mia soglia di velocità all'ultimo controllo, per
  /// registrare un avviso solo alla transizione sotto → sopra soglia.
  bool _wasOverSpeedLimit = false;

  /// Punti d'incontro per cui ho già registrato l'arrivo in questa sessione,
  /// per non richiamare il server ad ogni aggiornamento di posizione.
  final Set<String> _arrivedMeetingPointIds = {};

  /// Ritrovi per cui ho già confermato l'arrivo in questa sessione.
  final Set<String> _checkedInMeetupIds = {};

  // Il piano gratuito di Supabase ha limiti reali su scritture/banda: senza
  // queste soglie, muoversi (specie in auto) genera un aggiornamento ogni
  // pochi secondi, che a sua volta fa ripartire un refresh completo su
  // TUTTI i dispositivi della cerchia (vedi AppState._scheduleRefresh).
  // Limitiamo quindi la frequenza effettiva di scrittura, non solo la
  // distanza minima già imposta dal LocationSettings.
  static const _minProcessInterval = Duration(seconds: 12);
  static const _minHistoryInterval = Duration(minutes: 3);
  DateTime? _lastProcessedAt;
  DateTime? _lastHistoryAppendAt;

  /// Un fix con un raggio di incertezza oltre questa soglia (~5 km) non
  /// viene considerato attendibile e si scarta, invece di essere condiviso
  /// con la cerchia o salvato nello storico. Serve soprattutto su web/
  /// desktop: senza un GPS vero, il browser stima la posizione da Wi-Fi o
  /// perfino dal solo indirizzo IP, e quest'ultimo può sbagliare di decine
  /// di km (da qui una posizione mostrata a citta' di distanza da quella
  /// reale). Su GPS vero l'accuratezza è quasi sempre ben sotto questa soglia.
  static const _maxAcceptableAccuracyMeters = 5000;

  /// "Portami qualcosa": ultimo controllo del punto di interesse, per non
  /// richiamare Nominatim (o anche solo la cache Supabase) ad ogni singolo
  /// aggiornamento di posizione.
  DateTime? _lastPoiCheckAt;
  DateTime? _lastShoppingStopRecordedAt;
  static const _shoppingCategories = {'supermarket', 'fast_food', 'cafe'};

  bool get isTracking => _positionSub != null;

  /// Chiede i permessi di localizzazione al sistema. Ritorna true se
  /// concessi (almeno "quando in uso").
  Future<bool> requestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<void> start() async {
    if (!_observingLifecycle) {
      // Ogni volta che si torna in primo piano verifichiamo che il
      // tracciamento sia ancora vivo (vedi didChangeAppLifecycleState):
      // così tornare su Kinly dopo aver usato un'altra app lo rimette in
      // moto da solo, invece di restare fermo finché non si riavvia l'app.
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;

      // Le posizioni che arrivano dal Significant Location Change Service
      // nativo (vedi ios_significant_location_bridge.dart) passano dalla
      // STESSA pipeline di un fix GPS normale, force:true perché possono
      // distare minuti/ore l'una dall'altra (niente soglia di frequenza).
      if (!kIsWeb && Platform.isIOS) {
        IosSignificantLocationBridge.instance.ensureInitialized();
        IosSignificantLocationBridge.instance.onPosition = (position) => _onPosition(position, force: true);
        // Recupera un'eventuale posizione arrivata mentre l'app era
        // terminata, prima che questo handler fosse pronto ad ascoltare
        // (vedi il commento su consumePending).
        unawaited(IosSignificantLocationBridge.instance.consumePending());
      }
    }
    if (isTracking || _starting) return;
    _starting = true;
    try {
      final granted = await requestPermission();
      if (!granted) return;

      _restartAttempts = 0;
      await _subscribe();

      // Riprende anche il Significant Location Change Service se era già
      // stato attivato in una sessione precedente: senza questo, solo
      // riaprendo la schermata "Tracciamento in background" e ritoccando
      // l'interruttore lo si sarebbe fatto ripartire dopo un riavvio
      // dell'app o del telefono.
      if (!kIsWeb &&
          Platform.isIOS &&
          await BackgroundTrackingSettings.instance.isEnabled() &&
          await Geolocator.checkPermission() == LocationPermission.always) {
        unawaited(IosSignificantLocationBridge.instance.start());
      }

      _updateBattery();
      // cancel-before-assign su TUTTI i timer: se start() gira mentre un
      // vecchio timer è ancora vivo (es. lo stream era morto ma il timer
      // batteria continuava), non ne resta uno orfano a raddoppiare le
      // scritture.
      _batteryTimer?.cancel();
      _batteryTimer = Timer.periodic(const Duration(minutes: 5), (_) => _updateBattery());
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) => unawaited(_sendHeartbeat()));
    } finally {
      _starting = false;
    }

    try {
      final current = await Geolocator.getCurrentPosition();
      _onPosition(current);
    } catch (_) {
      // Se non è disponibile una posizione immediata, arriverà dallo stream.
    }
  }

  /// Riscrive l'ultima posizione nota con un orario fresco, senza aspettare
  /// un vero nuovo fix GPS: vedi il commento su _heartbeatTimer per il
  /// perché. Fa anche da guardiano: se lo stream di posizione si è fermato
  /// (es. dopo aver esaurito i tentativi rapidi di riavvio in
  /// _handleStreamDown), prova a riaccenderlo qui, così ogni pochi minuti
  /// c'è comunque un tentativo di ripresa invece di restare morti fino al
  /// prossimo ritorno in primo piano dell'app.
  Future<void> _sendHeartbeat() async {
    if (!isTracking) {
      _restartAttempts = 0;
      unawaited(_subscribe());
    }
    final position = _lastPosition;
    if (position == null) return;
    try {
      await KinlyRepository.instance.upsertMyLocation(
        lat: position.latitude,
        lng: position.longitude,
        address: _lastAddress,
        speedKmh: null,
      );
    } catch (_) {
      // Un battito mancato non è grave: il prossimo tra qualche minuto
      // (o un vero aggiornamento di posizione) rimedia da solo.
    }
  }

  Future<void> _subscribe() async {
    // Un solo abbonamento alla volta: se un'altra chiamata è già in corso
    // esco, e cancello sempre quello vecchio (e l'eventuale riavvio in
    // sospeso) prima di crearne uno nuovo, così non restano stream doppi.
    if (_subscribing) return;
    _subscribing = true;
    try {
      _restartTimer?.cancel();
      _restartTimer = null;
      await _positionSub?.cancel();
      _positionSub = null;
      final settings = await _buildLocationSettings();
      _positionSub = Geolocator.getPositionStream(locationSettings: settings)
          .listen(_onPosition, onError: (_) => _handleStreamDown(), onDone: _handleStreamDown);
    } finally {
      _subscribing = false;
    }
  }

  /// Lo stream di posizione può interrompersi da solo senza un errore Dart
  /// vero e proprio (es. Play Services riavviato in background da
  /// un'altra app che chiede il GPS, tipicamente un navigatore): senza
  /// questo, Kinly restava silenzioso finché non si riapriva l'app a mano.
  /// Qualche tentativo con una pausa breve invece di ritentare all'infinito
  /// se il problema è persistente (es. permesso revocato davvero).
  void _handleStreamDown() {
    // Su onError lo stream può essere ancora vivo: cancellalo prima di
    // perderne il riferimento, altrimenti resta un listener orfano che può
    // continuare a consegnare posizioni in parallelo al nuovo stream.
    final sub = _positionSub;
    _positionSub = null;
    unawaited(sub?.cancel());
    if (_restartAttempts >= _maxRestartAttempts) return;
    _restartAttempts++;
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(seconds: 10), () => unawaited(_subscribe()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !isTracking) {
      unawaited(start());
    }
  }

  /// Le impostazioni normali funzionano solo mentre Kinly è in primo piano.
  /// Chi ha attivato "Tracciamento in background" (e ha concesso il
  /// permesso di posizione "sempre") ottiene impostazioni specifiche per
  /// piattaforma che aumentano la probabilità che la posizione continui ad
  /// aggiornarsi anche quando l'app non è aperta, senza garantirlo al 100%
  /// se l'app viene chiusa a forza (dipende anche dal produttore/versione).
  ///
  /// Su Android è un vero servizio in primo piano, con una notifica fissa
  /// obbligatoria dal sistema. Su iOS non esiste un equivalente: si chiede
  /// invece a CLLocationManager di continuare ad aggiornare in background
  /// (allowBackgroundLocationUpdates), che richiede sia il permesso "Sempre"
  /// sia la chiave UIBackgroundModes con valore "location" in Info.plist —
  /// senza quest'ultima l'opzione qui sotto non ha alcun effetto e iOS
  /// sospende comunque l'app.
  Future<LocationSettings> _buildLocationSettings() async {
    const base = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 30);
    // kIsWeb prima di Platform.isAndroid/isIOS: dart:io.Platform non e'
    // disponibile sul web e solleverebbe un'eccezione appena chiamato.
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return base;
    if (!await BackgroundTrackingSettings.instance.isEnabled()) return base;
    if (await Geolocator.checkPermission() != LocationPermission.always) return base;

    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 30,
        pauseLocationUpdatesAutomatically: false,
        // La "barra blu" che iOS mostra quando un'app legge la posizione in
        // background: è l'unico avviso persistente che l'utente vede su
        // questa piattaforma, equivalente alla notifica fissa di Android.
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }

    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 30,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Kinly sta condividendo la tua posizione',
        notificationText: 'Attivo anche quando l\'app non è in primo piano.',
        notificationChannelName: 'Tracciamento posizione',
        enableWifiLock: true,
      ),
    );
  }

  /// Da chiamare quando l'utente attiva "Tracciamento in background" dalle
  /// impostazioni, DOPO aver mostrato l'avviso sul consumo di batteria.
  /// Riavvia il tracciamento con le nuove impostazioni se il permesso viene
  /// concesso subito.
  Future<BackgroundTrackingResult> enableBackgroundTracking() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return BackgroundTrackingResult.locationPermissionDenied;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
      return BackgroundTrackingResult.locationPermissionDenied;
    }

    if (permission != LocationPermission.always) {
      // Sia Android (dalla versione 11) sia iOS mostrano il permesso
      // "sempre" solo con una richiesta separata, dopo quello base: bisogna
      // chiederlo di nuovo, e se il sistema non lo concede subito va
      // attivato a mano dalle impostazioni dell'app.
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always) {
      return BackgroundTrackingResult.needsSystemSettings;
    }

    await BackgroundTrackingSettings.instance.setEnabled(true);
    await _restart();
    // Rete di sicurezza oltre al GPS continuo (vedi _buildLocationSettings):
    // se iOS sospende comunque l'app per inattività o memoria, il
    // Significant Location Change Service la risveglia comunque al
    // prossimo spostamento importante.
    if (!kIsWeb && Platform.isIOS) unawaited(IosSignificantLocationBridge.instance.start());
    return BackgroundTrackingResult.enabled;
  }

  Future<void> disableBackgroundTracking() async {
    await BackgroundTrackingSettings.instance.setEnabled(false);
    await _restart();
    if (!kIsWeb && Platform.isIOS) unawaited(IosSignificantLocationBridge.instance.stop());
  }

  Future<void> _restart() async {
    if (!isTracking) return;
    await stop();
    await start();
  }

  Future<void> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _subscribing = false;
    _batteryTimer?.cancel();
    _batteryTimer = null;
    _restartTimer?.cancel();
    _restartTimer = null;
    _restartAttempts = 0;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _lastPosition = null;
    _lastAddress = null;
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _observingLifecycle = false;
    }
    _zoneInsideState.clear();
    _wasOverSpeedLimit = false;
    _arrivedMeetingPointIds.clear();
    _checkedInMeetupIds.clear();
    _lastProcessedAt = null;
    _lastHistoryAppendAt = null;
    _lastPoiCheckAt = null;
    _lastShoppingStopRecordedAt = null;
  }

  /// Forza subito l'aggiornamento della mia posizione, saltando la soglia
  /// di frequenza: usato dal pulsante "centra su di me", che deve muovere
  /// il mio pin all'istante anche se ero fermo o mi sono spostato poco
  /// (prima la mappa si spostava dove ero davvero ma il pin restava fermo
  /// sull'ultima posizione salvata, sotto la soglia di scrittura).
  Future<Position?> forceRefresh() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      await _onPosition(position, force: true);
      return position;
    } catch (_) {
      return null;
    }
  }

  Future<void> _onPosition(Position position, {bool force = false}) async {
    // Un fix vero prova che lo stream è di nuovo sano: azzera il contatore
    // di tentativi di riavvio (vedi _handleStreamDown), così un problema
    // futuro riparte con lo stesso margine di tentativi invece di trovarlo
    // già esaurito da un problema passato e risolto da tempo.
    _restartAttempts = 0;

    // Un fix troppo impreciso (tipicamente stima via IP su desktop/browser
    // senza Wi-Fi scan) e' peggio che inutile: meglio restare senza un
    // aggiornamento che condividerne uno sbagliato di decine di km.
    if (position.accuracy.isFinite && position.accuracy > _maxAcceptableAccuracyMeters) return;

    final now = DateTime.now();
    if (!force && _lastProcessedAt != null && now.difference(_lastProcessedAt!) < _minProcessInterval) return;
    _lastProcessedAt = now;

    final address = await _reverseGeocode(position.latitude, position.longitude);
    _lastPosition = position;
    _lastAddress = address;
    // Position.speed è in m/s e può essere impreciso/negativo da fermi:
    // lo consideriamo solo se il GPS lo ritiene valido (>= 0).
    final speedKmh = (position.speed.isFinite && position.speed >= 0) ? position.speed * 3.6 : null;
    // Sposta subito il mio pin sulla mappa, senza aspettare l'eco realtime
    // dal server (vedi AppState.updateMyLocationOptimistic).
    AppState.instance.updateMyLocationOptimistic(
      lat: position.latitude,
      lng: position.longitude,
      address: address,
      speedKmh: speedKmh,
    );
    await KinlyRepository.instance.upsertMyLocation(
      lat: position.latitude,
      lng: position.longitude,
      address: address,
      speedKmh: speedKmh,
    );

    // Lo storico serve per rivedere gli spostamenti passati, non per una
    // traccia GPS continua: una riga ogni pochi minuti basta e riduce
    // parecchio la crescita della tabella.
    if (_lastHistoryAppendAt == null || now.difference(_lastHistoryAppendAt!) >= _minHistoryInterval) {
      _lastHistoryAppendAt = now;
      unawaited(KinlyRepository.instance.appendLocationHistory(lat: position.latitude, lng: position.longitude, address: address));
    }

    unawaited(_checkSafeZones(position));
    unawaited(_checkMeetingPoints(position));
    unawaited(_checkMeetups(position));
    if (speedKmh != null) unawaited(_checkSpeedAlert(speedKmh));
    unawaited(_checkPoi(position, speedKmh));
  }

  /// "Portami qualcosa": se sono fermo/a da un po' (probabilmente in un
  /// negozio), guarda che tipo di posto è — prima nella cache condivisa,
  /// poi via Nominatim solo se non l'ha ancora vista nessuno — e se è un
  /// supermercato/bar/fast-food segnala una sosta alla cerchia.
  Future<void> _checkPoi(Position position, double? speedKmh) async {
    // Ogni controllo può generare una chiamata a Nominatim (limiti d'uso
    // gratuiti condivisi con tutta l'app) e una notifica push alla cerchia:
    // per contenere il costo, è un vantaggio Kinly+ come il tracciamento
    // in background.
    if (!AppState.instance.isPremium) return;

    final isStationary = speedKmh == null || speedKmh < 3;
    if (!isStationary) return;

    final now = DateTime.now();
    if (_lastPoiCheckAt != null && now.difference(_lastPoiCheckAt!) < const Duration(minutes: 10)) return;
    _lastPoiCheckAt = now;

    if (_lastShoppingStopRecordedAt != null && now.difference(_lastShoppingStopRecordedAt!) < const Duration(minutes: 30)) return;

    try {
      final repo = KinlyRepository.instance;
      final cellKey = repo.poiCellKey(position.latitude, position.longitude);
      final cached = await repo.fetchPoiCache(cellKey);

      String category;
      String? placeName;
      if (cached != null && now.difference(DateTime.parse(cached['fetched_at'] as String)) < const Duration(days: 7)) {
        category = cached['category'] as String;
        placeName = cached['place_name'] as String?;
      } else {
        final result = await _reverseGeocodePoi(position.latitude, position.longitude);
        category = result?.$1 ?? 'other';
        placeName = result?.$2;
        unawaited(repo.upsertPoiCache(cellKey: cellKey, category: category, placeName: placeName));
      }

      if (_shoppingCategories.contains(category)) {
        _lastShoppingStopRecordedAt = now;
        // Solo cerchie 'family': una sosta rivela un negozio specifico, la
        // RLS blocca comunque l'inserimento in una Cerchia Eventi, ma
        // filtrare qui evita che il rifiuto interrompa il ciclo prima di
        // registrare la sosta nelle altre cerchie family dell'utente.
        for (final circle in AppState.instance.circles.where((c) => !c.isEventsCircle)) {
          await repo.recordShoppingStop(
            circleId: circle.id,
            category: category,
            placeName: placeName,
            lat: position.latitude,
            lng: position.longitude,
          );
        }
      }
    } catch (_) {
      // Non bloccare il tracciamento se il rilevamento del punto di
      // interesse fallisce (es. Nominatim non raggiungibile).
    }
  }

  /// Interroga Nominatim per la categoria del luogo a queste coordinate.
  /// Torna (categoria, nome del luogo) oppure null se non determinabile.
  Future<(String, String?)?> _reverseGeocodePoi(double lat, double lng) async {
    final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse').replace(queryParameters: {
      'lat': lat.toString(),
      'lon': lng.toString(),
      'format': 'jsonv2',
      'zoom': '18',
    });
    final response = await http.get(uri, headers: {'User-Agent': 'KinlyApp/1.0'});
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final osmCategory = data['category'] as String?;
    final osmType = data['type'] as String?;
    final name = data['name'] as String?;

    String category;
    if (osmCategory == 'shop' && (osmType == 'supermarket' || osmType == 'convenience' || osmType == 'grocery')) {
      category = 'supermarket';
    } else if (osmCategory == 'amenity' && osmType == 'fast_food') {
      category = 'fast_food';
    } else if (osmCategory == 'amenity' && osmType == 'cafe') {
      category = 'cafe';
    } else {
      category = 'other';
    }
    return (category, name);
  }

  /// Confronta la velocità attuale con la mia soglia impostata e registra
  /// un avviso solo quando la supero (non ad ogni aggiornamento).
  Future<void> _checkSpeedAlert(double speedKmh) async {
    final threshold = AppState.instance.me.speedAlertKmh;
    if (threshold == null) {
      _wasOverSpeedLimit = false;
      return;
    }
    final isOver = speedKmh > threshold;
    if (isOver && !_wasOverSpeedLimit) {
      try {
        await KinlyRepository.instance.recordSpeedEvent(speedKmh: speedKmh, thresholdKmh: threshold.toDouble());
      } catch (_) {
        // Non bloccare il tracciamento se la registrazione dell'evento fallisce.
      }
    }
    _wasOverSpeedLimit = isOver;
  }

  /// Confronta la posizione attuale con le aree sicure delle mie cerchie e,
  /// se rilevo un ingresso o un'uscita, la registra. Le aree sono un
  /// beneficio Kinly+ della cerchia (le crea chi è abbonato), ma il
  /// rilevamento vale per tutti i membri.
  Future<void> _checkSafeZones(Position position) async {
    for (final zone in AppState.instance.safeZones) {
      final distance = Geolocator.distanceBetween(position.latitude, position.longitude, zone.lat, zone.lng);
      final isInside = distance <= zone.radiusMeters;
      final wasInside = _zoneInsideState[zone.id];
      _zoneInsideState[zone.id] = isInside;
      if (wasInside != null && wasInside != isInside) {
        try {
          await KinlyRepository.instance.recordSafeZoneEvent(zoneId: zone.id, entering: isInside);
        } catch (_) {
          // Non bloccare il tracciamento se la registrazione dell'evento fallisce.
        }
        // "Ping d'arrivo": oltre all'evento automatico sopra (silenzioso),
        // una notifica con un pulsante per avvisare subito la cerchia con
        // un messaggio, senza dover aprire l'app. Solo Android per ora, e
        // solo per le aree sicure: per una zona pericolosa l'obiettivo è
        // avvisare gli altri, non offrire a chi vi è appena entrato un
        // pulsante "sono arrivato" che non avrebbe senso lì.
        if (isInside && zone.zoneType == SafeZoneType.safe) {
          final l10n = lookupAppLocalizations(LocaleController.instance.locale);
          unawaited(PushNotificationService.instance.showArrivalPrompt(
            zoneId: zone.id,
            zoneLabel: l10n.arrivalPromptTitle(zone.name),
            actionLabel: l10n.arrivalPromptAction,
          ));
        }
      }
      // "Accompagnami": entrare in un'area Casa conferma automaticamente
      // l'arrivo, senza dover ricordarsi di toccare il pulsante.
      if (isInside && zone.kind == SafeZoneKind.home && WalkMeHomeService.instance.isActive) {
        unawaited(WalkMeHomeService.instance.confirmArrival());
      }
    }
  }

  /// Segna automaticamente l'arrivo a un punto d'incontro quando ci si
  /// avvicina a meno di 100 metri, senza bisogno di aprire l'app.
  static const _meetingPointArrivalRadiusMeters = 100;

  Future<void> _checkMeetingPoints(Position position) async {
    for (final point in AppState.instance.meetingPoints) {
      if (point.isExpired || _arrivedMeetingPointIds.contains(point.id)) continue;
      final distance = Geolocator.distanceBetween(position.latitude, position.longitude, point.lat, point.lng);
      if (distance <= _meetingPointArrivalRadiusMeters) {
        _arrivedMeetingPointIds.add(point.id);
        try {
          await KinlyRepository.instance.recordMeetingPointArrival(point.id);
        } catch (_) {
          _arrivedMeetingPointIds.remove(point.id);
        }
      }
    }
  }

  /// Conferma automaticamente l'arrivo a un Ritrovo a cui ho risposto "Ci
  /// siamo!" quando mi avvicino a meno di 100 metri dallo spot: stesso
  /// meccanismo del punto d'incontro, un solo evento booleano "sono
  /// arrivato", mai una posizione continua o un tragitto. Non tocca gli
  /// eventuali check-in "chi c'è ora" (ambientali, senza un ritrovo
  /// associato): quelli restano una scelta esplicita della persona.
  static const _meetupArrivalRadiusMeters = 100;

  Future<void> _checkMeetups(Position position) async {
    final state = AppState.instance;
    for (final meetup in state.meetups) {
      if (meetup.isPast || _checkedInMeetupIds.contains(meetup.id)) continue;
      if (state.myRsvpFor(meetup.id) != MeetupRsvpResponse.yes) continue;
      if (state.hasCheckedInTo(meetup.id)) {
        _checkedInMeetupIds.add(meetup.id);
        continue;
      }
      final spot = state.meetupSpotById(meetup.spotId);
      if (spot == null) continue;
      final distance = Geolocator.distanceBetween(position.latitude, position.longitude, spot.lat, spot.lng);
      if (distance <= _meetupArrivalRadiusMeters) {
        _checkedInMeetupIds.add(meetup.id);
        try {
          await KinlyRepository.instance.recordMeetupCheckin(spotId: spot.id, meetupId: meetup.id, circleId: meetup.circleId);
        } catch (_) {
          _checkedInMeetupIds.remove(meetup.id);
        }
      }
    }
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    // Su web il pacchetto nativo `geocoding` non ha alcuna implementazione:
    // fallirebbe sempre, quindi lì saltiamo dritti a Nominatim (una pura
    // chiamata HTTP, funziona ovunque) invece di tentarlo inutilmente.
    if (!kIsWeb) {
      try {
        final placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final formatted = formatPlacemarkAddress(placemarks.first);
          if (formatted != null) return formatted;
        }
      } catch (_) {
        // Va bene provare comunque con Nominatim invece di restare senza
        // indirizzo leggibile.
      }
    }
    return PlaceSearchService.instance.reverseGeocode(lat, lng);
  }

  /// Sotto questa soglia avviso la cerchia una volta sola per "carica":
  /// niente notifiche ripetute ad ogni controllo (ogni 5 minuti) finché
  /// resto sotto soglia. Il margine tra le due soglie evita di riavvisare
  /// per un rimbalzo di un punto percentuale intorno al 10%.
  static const _lowBatteryThreshold = 10;
  static const _lowBatteryResetThreshold = 20;
  bool _lowBatteryAlerted = false;

  Future<void> _updateBattery() async {
    try {
      final level = await _battery.batteryLevel;
      await KinlyRepository.instance.updateBatteryPercent(level);
      if (level <= _lowBatteryThreshold && !_lowBatteryAlerted) {
        _lowBatteryAlerted = true;
        unawaited(KinlyRepository.instance.recordBatteryAlert(level));
      } else if (level > _lowBatteryResetThreshold) {
        _lowBatteryAlerted = false;
      }
    } catch (_) {
      // Ignorato: la batteria non è essenziale al funzionamento dell'app.
    }
  }
}
