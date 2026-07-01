/// Un punto di interesse vicino (ristorante, bar, farmacia...), mostrato
/// sulla mappa live solo a scopo informativo: nessun dato personale, nessuna
/// funzione Kinly+ collegata.
enum NearbyPoiCategory { restaurant, cafe, bar, pharmacy, supermarket, other }

extension NearbyPoiCategoryData on NearbyPoiCategory {
  String get emoji => switch (this) {
        NearbyPoiCategory.restaurant => '🍽️',
        NearbyPoiCategory.cafe => '☕',
        NearbyPoiCategory.bar => '🍹',
        NearbyPoiCategory.pharmacy => '💊',
        NearbyPoiCategory.supermarket => '🛒',
        NearbyPoiCategory.other => '📍',
      };

  static NearbyPoiCategory fromOsmTags({String? amenity, String? shop}) {
    switch (amenity) {
      case 'restaurant':
        return NearbyPoiCategory.restaurant;
      case 'cafe':
        return NearbyPoiCategory.cafe;
      case 'bar':
      case 'pub':
        return NearbyPoiCategory.bar;
      case 'pharmacy':
        return NearbyPoiCategory.pharmacy;
    }
    if (shop == 'supermarket') return NearbyPoiCategory.supermarket;
    return NearbyPoiCategory.other;
  }
}

class NearbyPoi {
  const NearbyPoi({required this.id, required this.name, required this.lat, required this.lng, required this.category});

  final String id;
  final String name;
  final double lat;
  final double lng;
  final NearbyPoiCategory category;
}
