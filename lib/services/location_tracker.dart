import 'dart:async';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../state/app_state.dart';
import 'background_tracking_settings.dart';
import 'kinly_repository.dart';

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
class LocationTracker {
  LocationTracker._();
  static final instance = LocationTracker._();

  StreamSubscription<Position>? _positionSub;
  Timer? _batteryTimer;
  final _battery = Battery();

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
    if (isTracking) return;
    final granted = await requestPermission();
    if (!granted) return;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: await _buildLocationSettings(),
    ).listen(_onPosition, onError: (_) {});

    _updateBattery();
    _batteryTimer = Timer.periodic(const Duration(minutes: 5), (_) => _updateBattery());

    try {
      final current = await Geolocator.getCurrentPosition();
      _onPosition(current);
    } catch (_) {
      // Se non è disponibile una posizione immediata, arriverà dallo stream.
    }
  }

  /// Le impostazioni normali funzionano solo mentre Kinly è in primo piano.
  /// Chi ha attivato "Tracciamento in background" (e ha concesso il
  /// permesso di posizione "sempre") ottiene invece un vero servizio in
  /// primo piano Android, con una notifica fissa obbligatoria dal sistema:
  /// aumenta la probabilità che la posizione continui ad aggiornarsi anche
  /// quando l'app non è aperta, ma non lo garantisce al 100% se l'app viene
  /// chiusa a forza (dipende anche dal produttore del telefono).
  Future<LocationSettings> _buildLocationSettings() async {
    const base = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 30);
    if (!Platform.isAndroid) return base;
    if (!await BackgroundTrackingSettings.instance.isEnabled()) return base;
    if (await Geolocator.checkPermission() != LocationPermission.always) return base;

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
    if (!Platform.isAndroid) return BackgroundTrackingResult.locationPermissionDenied;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
      return BackgroundTrackingResult.locationPermissionDenied;
    }

    if (permission != LocationPermission.always) {
      // Da Android 11 in poi il sistema non mostra più un dialogo per il
      // permesso "sempre" insieme a quello base: bisogna chiederlo di
      // nuovo, e se il sistema non lo concede subito va attivato a mano
      // dalle impostazioni dell'app.
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always) {
      return BackgroundTrackingResult.needsSystemSettings;
    }

    await BackgroundTrackingSettings.instance.setEnabled(true);
    await _restart();
    return BackgroundTrackingResult.enabled;
  }

  Future<void> disableBackgroundTracking() async {
    await BackgroundTrackingSettings.instance.setEnabled(false);
    await _restart();
  }

  Future<void> _restart() async {
    if (!isTracking) return;
    await stop();
    await start();
  }

  Future<void> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _batteryTimer?.cancel();
    _batteryTimer = null;
    _zoneInsideState.clear();
    _wasOverSpeedLimit = false;
    _arrivedMeetingPointIds.clear();
    _lastProcessedAt = null;
    _lastHistoryAppendAt = null;
  }

  Future<void> _onPosition(Position position) async {
    final now = DateTime.now();
    if (_lastProcessedAt != null && now.difference(_lastProcessedAt!) < _minProcessInterval) return;
    _lastProcessedAt = now;

    final address = await _reverseGeocode(position.latitude, position.longitude);
    // Position.speed è in m/s e può essere impreciso/negativo da fermi:
    // lo consideriamo solo se il GPS lo ritiene valido (>= 0).
    final speedKmh = (position.speed.isFinite && position.speed >= 0) ? position.speed * 3.6 : null;
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
    if (speedKmh != null) unawaited(_checkSpeedAlert(speedKmh));
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

  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = [
        if ((p.street ?? '').isNotEmpty) p.street,
        if ((p.locality ?? '').isNotEmpty) p.locality,
      ];
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      // La geocodifica nativa non è disponibile su tutte le piattaforme
      // (es. web/desktop): in quel caso restiamo senza indirizzo leggibile.
      return null;
    }
  }

  Future<void> _updateBattery() async {
    try {
      final level = await _battery.batteryLevel;
      await KinlyRepository.instance.updateBatteryPercent(level);
    } catch (_) {
      // Ignorato: la batteria non è essenziale al funzionamento dell'app.
    }
  }
}
