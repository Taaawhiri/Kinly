import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/nearby_poi.dart';

/// Punti di interesse vicini (ristoranti, bar, farmacie, supermercati) via
/// Overpass API (dati OpenStreetMap, gratuita, senza chiave): mostra solo
/// un contesto informativo sulla mappa, nessun dato personale coinvolto.
class NearbyPoiService {
  NearbyPoiService._();
  static final instance = NearbyPoiService._();

  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  Future<List<NearbyPoi>> nearby(double lat, double lng, {int radiusMeters = 600}) async {
    final query = '''
[out:json][timeout:15];
(
  node["amenity"~"^(restaurant|cafe|bar|pub|pharmacy)\$"](around:$radiusMeters,$lat,$lng);
  node["shop"="supermarket"](around:$radiusMeters,$lat,$lng);
);
out center 25;
''';
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'data': query},
    );
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
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
