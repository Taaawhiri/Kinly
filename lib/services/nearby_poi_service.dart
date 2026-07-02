import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nearby_poi.dart';

/// Punti di interesse vicini (ristoranti, bar, farmacie, supermercati) via
/// Overpass API (dati OpenStreetMap, gratuita, senza chiave): mostra solo
/// un contesto informativo sulla mappa, nessun dato personale coinvolto.
class NearbyPoiService {
  NearbyPoiService._();
  static final instance = NearbyPoiService._();

  // I server pubblici Overpass (nessuno dei quali richiede una chiave) sono
  // spesso sovraccarichi o lenti nelle ore di punta, uno più dell'altro a
  // seconda del momento: proviamo in sequenza più mirror indipendenti
  // invece di affidarci a uno o due soli, così un singolo server in
  // difficoltà non fa sparire del tutto i punti di interesse.
  static const _endpoints = [
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass-api.de/api/interpreter',
    'https://overpass.openstreetmap.fr/api/interpreter',
    'https://overpass.openstreetmap.ru/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
  ];

  /// Tempo massimo per ogni singolo server: deve superare il `timeout`
  /// dichiarato nella query stessa, altrimenti annulliamo la richiesta
  /// lato client proprio mentre il server starebbe per rispondere.
  static const _perServerTimeout = Duration(seconds: 20);

  /// Lancia un'eccezione solo se NESSUN server ha risposto affatto: una
  /// risposta valida con zero risultati (nessun locale nei paraggi) non è
  /// un errore e va distinta da un'indisponibilità totale dei server, così
  /// chi chiama può scegliere di tenere gli ultimi punti mostrati invece di
  /// farli sparire per un singolo tentativo sfortunato.
  Future<List<NearbyPoi>> nearby(double lat, double lng, {int radiusMeters = 600}) async {
    final query = '''
[out:json][timeout:18];
(
  node["amenity"~"^(restaurant|cafe|bar|pub|pharmacy)\$"](around:$radiusMeters,$lat,$lng);
  node["shop"="supermarket"](around:$radiusMeters,$lat,$lng);
);
out center 25;
''';

    Object? lastError;
    for (final endpoint in _endpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body: {'data': query},
            )
            .timeout(_perServerTimeout);
        if (response.statusCode == 200) return _parse(response.body);
        lastError = 'HTTP ${response.statusCode} da $endpoint';
      } catch (e) {
        lastError = e;
        // Prova il prossimo server prima di arrenderti.
      }
    }
    throw Exception('Nessun server Overpass raggiungibile: $lastError');
  }

  List<NearbyPoi> _parse(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final elements = (data['elements'] as List?) ?? [];
    final results = <NearbyPoi>[];
    for (final raw in elements) {
      final el = raw as Map<String, dynamic>;
      final tags = (el['tags'] as Map<String, dynamic>?) ?? {};
      final name = tags['name'] as String?;
      if (name == null || name.isEmpty) continue;
      final elLat = (el['lat'] as num?)?.toDouble();
      final elLng = (el['lon'] as num?)?.toDouble();
      if (elLat == null || elLng == null) continue;
      results.add(NearbyPoi(
        id: '${el['type']}${el['id']}',
        name: name,
        lat: elLat,
        lng: elLng,
        category: NearbyPoiCategoryData.fromOsmTags(amenity: tags['amenity'] as String?, shop: tags['shop'] as String?),
      ));
    }
    return results;
  }
}
