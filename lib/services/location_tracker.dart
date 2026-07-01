import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
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
  }

  Future<void> _onPosition(Position position) async {
    final address = await _reverseGeocode(position.latitude, position.longitude);
    await KinlyRepository.instance.upsertMyLocation(lat: position.latitude, lng: position.longitude, address: address);
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
