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
    if (current.isNotEmpty && p.recordedAt.difference(current.last.recordedAt) > gap) {
      finishCurrent();
      current = [];
    }
    current.add(p);
  }
  finishCurrent();

  return trips.reversed.toList();
}
