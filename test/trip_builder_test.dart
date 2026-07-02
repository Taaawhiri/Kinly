import 'package:flutter_test/flutter_test.dart';
import 'package:kinly/models/location_history_point.dart';
import 'package:kinly/utils/trip_builder.dart';

LocationHistoryPoint _point(double lat, double lng, DateTime at) {
  return LocationHistoryPoint(lat: lat, lng: lng, address: null, recordedAt: at);
}

void main() {
  group('buildTrips', () {
    test('scarta un fix GPS con velocità implicita impossibile invece di contarlo come viaggio', () {
      final base = DateTime(2024, 1, 1, 10, 0);
      final history = [
        _point(45.070, 7.686, base), // Torino
        _point(45.070, 7.686, base.add(const Duration(minutes: 1))), // ancora Torino
        // Salto GPS di ~80km in un minuto: fisicamente impossibile.
        _point(44.390, 7.548, base.add(const Duration(minutes: 2))), // vicino Cuneo
        _point(45.071, 7.687, base.add(const Duration(minutes: 3))), // torna a Torino
        // Un vero spostamento successivo, plausibile, che deve restare.
        _point(45.090, 7.700, base.add(const Duration(minutes: 10))),
      ];

      final trips = buildTrips(history);

      expect(trips, hasLength(1));
      final trip = trips.first;
      expect(trip.points.any((p) => p.lat == 44.390), isFalse, reason: 'il punto sbagliato deve essere scartato');
      expect(trip.distanceMeters, lessThan(10000));
    });

    test('un vero tragitto lungo e veloce (es. autostrada) non viene scartato', () {
      final base = DateTime(2024, 1, 1, 10, 0);
      final history = [
        _point(45.070, 7.686, base),
        _point(45.300, 7.900, base.add(const Duration(minutes: 20))),
      ];

      final trips = buildTrips(history);

      expect(trips, hasLength(1));
      expect(trips.first.distanceMeters, greaterThan(300));
    });
  });
}
