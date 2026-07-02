import 'package:geolocator/geolocator.dart';
import '../models/location_history_point.dart';

/// Un tragitto ricostruito dallo storico posizioni: una sequenza di punti
/// senza interruzioni lunghe, con una distanza minima per non contare come
/// "tragitto" il semplice rumore GPS di chi è fermo.
class Trip {
  const Trip({required this.points, required this.distanceMeters});

  final List<LocationHistoryPoint> points;
  final double distanceMeters;

  DateTime get start => points.first.recordedAt;
  DateTime get end => points.last.recordedAt;
  Duration get duration => end.difference(start);

  String get startLabel => points.first.address ?? '${points.first.lat.toStringAsFixed(3)}, ${points.first.lng.toStringAsFixed(3)}';
  String get endLabel => points.last.address ?? '${points.last.lat.toStringAsFixed(3)}, ${points.last.lng.toStringAsFixed(3)}';
}

/// Una posizione la cui velocità implicita rispetto al punto precedente
/// supera questa soglia (circa 220 km/h, oltre il ragionevole anche in
/// autostrada) viene trattata come un errore GPS momentaneo — es. un fix
/// impreciso per scarsa ricezione, che "salta" lontano e poi torna quello
/// giusto — e scartata. Senza questo controllo un singolo salto del genere
/// veniva sommato come se fosse un vero spostamento, creando un "itinerario"
/// mai realmente percorso (tipicamente andata-e-ritorno verso il punto
/// sbagliato, con partenza e arrivo che infatti coincidono).
const double _maxPlausibleSpeedMetersPerSecond = 61;

/// Raggruppa lo storico posizioni (in qualsiasi ordine) in tragitti: un
/// varco di più di [gap] tra due punti consecutivi chiude il tragitto
/// corrente. Tragitti più corti di [minDistanceMeters] vengono scartati
/// (è solo rumore GPS di chi è rimasto fermo). Ritorna i tragitti più
/// recenti per primi.
List<Trip> buildTrips(
  List<LocationHistoryPoint> history, {
  double minDistanceMeters = 300,
  Duration gap = const Duration(minutes: 25),
}) {
  final points = [...history]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  final trips = <Trip>[];
  var current = <LocationHistoryPoint>[];

  void finishCurrent() {
    if (current.length < 2) return;
    var distance = 0.0;
    for (var i = 1; i < current.length; i++) {
      distance += Geolocator.distanceBetween(current[i - 1].lat, current[i - 1].lng, current[i].lat, current[i].lng);
    }
    if (distance >= minDistanceMeters) trips.add(Trip(points: List.of(current), distanceMeters: distance));
  }

  for (final p in points) {
    if (current.isNotEmpty) {
      final last = current.last;
      final elapsedSeconds = p.recordedAt.difference(last.recordedAt).inSeconds;
      if (elapsedSeconds > 0) {
        final segmentMeters = Geolocator.distanceBetween(last.lat, last.lng, p.lat, p.lng);
        if (segmentMeters / elapsedSeconds > _maxPlausibleSpeedMetersPerSecond) {
          continue; // scarta solo questo fix, non l'intero tragitto in corso
        }
      }
      if (p.recordedAt.difference(last.recordedAt) > gap) {
        finishCurrent();
        current = [];
      }
    }
    current.add(p);
  }
  finishCurrent();

  return trips.reversed.toList();
}
