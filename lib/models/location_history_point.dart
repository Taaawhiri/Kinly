/// Un punto dello storico posizioni di una persona (funzione Kinly+).
class LocationHistoryPoint {
  const LocationHistoryPoint({
    required this.lat,
    required this.lng,
    required this.address,
    required this.recordedAt,
  });

  factory LocationHistoryPoint.fromRow(Map<String, dynamic> row) {
    return LocationHistoryPoint(
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      address: row['address'] as String?,
      recordedAt: DateTime.parse(row['recorded_at'] as String),
    );
  }

  final double lat;
  final double lng;
  final String? address;
  final DateTime recordedAt;
}
