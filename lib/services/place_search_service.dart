import 'dart:convert';
import 'package:http/http.dart' as http;

/// Un risultato di ricerca luogo (indirizzo o punto di interesse come un
/// ristorante), da usare per il punto d'incontro condiviso.
class PlaceResult {
  const PlaceResult({required this.label, required this.lat, required this.lng});
  final String label;
  final double lat;
  final double lng;
}

/// Ricerca luoghi/indirizzi tramite Nominatim (OpenStreetMap): gratuita,
/// senza chiave API, copre anche molti punti di interesse con nome (bar,
/// ristoranti, negozi), non solo indirizzi puntuali.
class PlaceSearchService {
  PlaceSearchService._();
  static final instance = PlaceSearchService._();

  static const _endpoint = 'https://nominatim.openstreetmap.org/search';

  Future<List<PlaceResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'q': trimmed,
      'format': 'jsonv2',
      'limit': '6',
    });
    final response = await http.get(
      uri,
      // Nominatim richiede un User-Agent che identifichi l'app (uso
      // gratuito, niente chiave): senza, alcune richieste vengono rifiutate.
      headers: {'User-Agent': 'KinlyApp/1.0'},
    );
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as List;
    return data.map((raw) {
      final row = raw as Map<String, dynamic>;
      return PlaceResult(
        label: row['display_name'] as String,
        lat: double.parse(row['lat'] as String),
        lng: double.parse(row['lon'] as String),
      );
    }).toList();
  }

  static const _reverseEndpoint = 'https://nominatim.openstreetmap.org/reverse';

  /// Indirizzo leggibile da coordinate, via Nominatim invece del pacchetto
  /// nativo `geocoding`: quest'ultimo non ha alcuna implementazione sul web,
  /// quindi lì restituiva sempre null (mostrando le coordinate al posto
  /// dell'indirizzo in cronologia posizioni e itinerari). Essendo una pura
  /// chiamata HTTP, questa funziona su qualunque piattaforma.
  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(_reverseEndpoint).replace(queryParameters: {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'jsonv2',
      });
      final response = await http.get(uri, headers: {'User-Agent': 'KinlyApp/1.0'});
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      if (address == null) return data['display_name'] as String?;

      final road = address['road'] as String?;
      final houseNumber = address['house_number'] as String?;
      final locality = (address['city'] ?? address['town'] ?? address['village'] ?? address['county']) as String?;

      final parts = [
        if (road != null) (houseNumber != null ? '$road $houseNumber' : road),
        if (locality != null) locality,
      ];
      if (parts.isNotEmpty) return parts.join(', ');
      return data['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
