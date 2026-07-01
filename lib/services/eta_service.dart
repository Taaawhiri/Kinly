import 'dart:convert';
import 'package:http/http.dart' as http;

/// Tempo di percorrenza stimato via OSRM (routing gratuito su dati
/// OpenStreetMap, nessuna chiave API — coerente con il resto dello stack).
/// Il server demo pubblico ha limiti d'uso blandi: lo usiamo solo per pochi
/// membri di una cerchia alla volta, con una piccola cache in memoria.
class EtaService {
  EtaService._();
  static final instance = EtaService._();

  static const _endpoint = 'https://router.project-osrm.org/route/v1/driving';

  final Map<String, (DateTime, Duration)> _cache = {};

  /// Durata stimata in auto tra due punti, o null se non calcolabile.
  Future<Duration?> eta({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final key = '${fromLat.toStringAsFixed(3)},${fromLng.toStringAsFixed(3)}->${toLat.toStringAsFixed(3)},${toLng.toStringAsFixed(3)}';
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.$1) < const Duration(minutes: 2)) {
      return cached.$2;
    }

    try {
      final uri = Uri.parse('$_endpoint/$fromLng,$fromLat;$toLng,$toLat?overview=false');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final seconds = ((routes.first as Map<String, dynamic>)['duration'] as num).round();
      final duration = Duration(seconds: seconds);
      _cache[key] = (DateTime.now(), duration);
      return duration;
    } catch (_) {
      return null;
    }
  }
}
