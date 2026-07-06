import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

/// Ponte verso il monitoraggio "vero" in background su iOS, implementato
/// nativamente in AppDelegate.swift con Significant Location Change Service
/// + CoreMotion (vedi commenti lì per i dettagli). A differenza di
/// AppleSettings.allowBackgroundLocationUpdates (GPS continuo, ma solo
/// finché iOS non sospende l'app per inattività o pressione di memoria —
/// il limite già documentato in LocationTracker._buildLocationSettings),
/// il Significant Location Change Service continua a svegliare l'app anche
/// dopo che è stata sospesa o addirittura terminata dal sistema (NON se
/// l'utente la chiude a forza: quello resta un limite di iOS impossibile
/// da aggirare da nessuna app), ogni volta che il dispositivo si sposta di
/// alcune centinaia di metri — con un consumo di batteria molto più basso
/// perché usa le celle telefoniche invece del GPS continuo. Le due strade
/// lavorano insieme: quella "normale" copre il caso comune (posizione
/// aggiornata spesso, con precisione), questa è la rete di sicurezza per
/// quando il sistema ha comunque sospeso tutto il resto.
class IosSignificantLocationBridge {
  IosSignificantLocationBridge._();
  static final instance = IosSignificantLocationBridge._();

  static const _channel = MethodChannel('kinly/background_location');
  bool _initialized = false;

  /// Chiamato da LocationTracker con la stessa pipeline usata per un fix
  /// GPS normale (_onPosition), così zone sicure, stato dinamico, storico
  /// ecc. restano coerenti indipendentemente da dove arriva la posizione.
  Future<void> Function(Position position)? onPosition;

  void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler(_handleCall);
  }

  /// Non deve mai lanciare: chiamato anche su piattaforme/versioni dove il
  /// canale nativo non esiste ancora (es. durante l'aggiornamento dell'app),
  /// nel qual caso fallisce in modo innocuo e resta solo il tracciamento
  /// normale.
  Future<void> start() async {
    try {
      await _channel.invokeMethod('startSignificantLocationMonitoring');
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopSignificantLocationMonitoring');
    } catch (_) {}
  }

  /// Da chiamare ad ogni avvio del tracciamento (vedi LocationTracker.start):
  /// recupera un'eventuale posizione arrivata mentre l'app era terminata e
  /// il canale nativo->Dart non era ancora pronto a riceverla dal vivo (vedi
  /// il commento su sendLocation lato Swift). Innocuo se non c'è nulla in
  /// sospeso o se il canale non esiste su questa piattaforma/versione.
  Future<void> consumePending() async {
    try {
      final json = await _channel.invokeMethod<String>('consumePendingBackgroundLocation');
      if (json == null) return;
      final args = Map<String, dynamic>.from(jsonDecode(json) as Map);
      await onPosition?.call(_positionFromArgs(args));
    } catch (_) {}
  }

  Future<void> _handleCall(MethodCall call) async {
    if (call.method != 'onBackgroundLocation') return;
    final args = Map<String, dynamic>.from(call.arguments as Map);
    await onPosition?.call(_positionFromArgs(args));
  }

  Position _positionFromArgs(Map<String, dynamic> args) {
    final lat = (args['lat'] as num).toDouble();
    final lng = (args['lng'] as num).toDouble();
    final timestampMs = (args['timestampMs'] as num).toInt();
    final accuracy = (args['accuracy'] as num?)?.toDouble() ?? 50.0;
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}
