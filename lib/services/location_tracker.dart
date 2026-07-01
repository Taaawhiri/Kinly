import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../state/app_state.dart';
import 'kinly_repository.dart';

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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 30),
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

  Future<void> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _batteryTimer?.cancel();
    _batteryTimer = null;
    _zoneInsideState.clear();
  }

  Future<void> _onPosition(Position position) async {
    final address = await _reverseGeocode(position.latitude, position.longitude);
    await KinlyRepository.instance.upsertMyLocation(lat: position.latitude, lng: position.longitude, address: address);
    unawaited(KinlyRepository.instance.appendLocationHistory(lat: position.latitude, lng: position.longitude, address: address));
    unawaited(_checkSafeZones(position));
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
