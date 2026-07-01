import 'package:geolocator/geolocator.dart';
import '../models/location_history_point.dart';
import '../models/safe_zone.dart';

/// Un luogo frequentato spesso, candidato a diventare un'area sicura.
class ZoneSuggestion {
  const ZoneSuggestion({required this.lat, required this.lng, required this.address, required this.dayCount});
  final double lat;
  final double lng;
  final String? address;
  final int dayCount;
}

/// Dallo storico posizioni individua i luoghi dove si torna spesso (stessa
/// cella di ~110 m in almeno [minDays] giorni diversi) che non sono già
/// coperti da un'area sicura esistente: candidati naturali a diventarlo.
List<ZoneSuggestion> suggestZones(
  List<LocationHistoryPoint> history,
  List<SafeZone> existingZones, {
  int minDays = 3,
  int maxSuggestions = 3,
}) {
  // Cella di ~110 m: abbastanza larga da raggruppare i punti GPS dello
  // stesso posto, abbastanza stretta da distinguere posti diversi.
  final byCell = <String, List<LocationHistoryPoint>>{};
  for (final p in history) {
    final key = '${p.lat.toStringAsFixed(3)},${p.lng.toStringAsFixed(3)}';
    byCell.putIfAbsent(key, () => []).add(p);
  }

  final suggestions = <ZoneSuggestion>[];
  for (final points in byCell.values) {
    final days = points.map((p) {
      final d = p.recordedAt.toLocal();
      return '${d.year}-${d.month}-${d.day}';
    }).toSet();
    if (days.length < minDays) continue;

    final lat = points.map((p) => p.lat).reduce((a, b) => a + b) / points.length;
    final lng = points.map((p) => p.lng).reduce((a, b) => a + b) / points.length;

    final coveredByExisting = existingZones.any(
      (z) => Geolocator.distanceBetween(lat, lng, z.lat, z.lng) < z.radiusMeters + 150,
    );
    if (coveredByExisting) continue;

    String? address;
    for (final p in points) {
      if (p.address != null && p.address!.isNotEmpty) {
        address = p.address;
        break;
      }
    }
    suggestions.add(ZoneSuggestion(lat: lat, lng: lng, address: address, dayCount: days.length));
  }

  suggestions.sort((a, b) => b.dayCount.compareTo(a.dayCount));
  return suggestions.take(maxSuggestions).toList();
}
