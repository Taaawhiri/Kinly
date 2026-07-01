/// Un'area sicura definita per una cerchia (funzione Kinly+): un luogo con
/// un raggio, per essere avvisati quando qualcuno entra o esce.
class SafeZone {
  const SafeZone({
    required this.id,
    required this.circleId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
    required this.createdBy,
  });

  factory SafeZone.fromRow(Map<String, dynamic> row) {
    return SafeZone(
      id: row['id'] as String,
      circleId: row['circle_id'] as String,
      name: row['name'] as String,
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      radiusMeters: (row['radius_meters'] as num).toInt(),
      createdBy: row['created_by'] as String,
    );
  }

  final String id;
  final String circleId;
  final String name;
  final double lat;
  final double lng;
  final int radiusMeters;
  final String createdBy;
}

enum SafeZoneEventType { enter, exit }

/// Un ingresso o un'uscita da un'area sicura.
class SafeZoneEvent {
  const SafeZoneEvent({
    required this.id,
    required this.zoneId,
    required this.profileId,
    required this.type,
    required this.occurredAt,
  });

  factory SafeZoneEvent.fromRow(Map<String, dynamic> row) {
    return SafeZoneEvent(
      id: row['id'] as String,
      zoneId: row['zone_id'] as String,
      profileId: row['profile_id'] as String,
      type: row['event_type'] == 'enter' ? SafeZoneEventType.enter : SafeZoneEventType.exit,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
    );
  }

  final String id;
  final String zoneId;
  final String profileId;
  final SafeZoneEventType type;
  final DateTime occurredAt;
}
