/// Un punto d'incontro condiviso in una cerchia: chiunque può proporne uno,
/// non è una funzione Kinly+. Gli altri membri vedono la propria distanza
/// in tempo reale, e l'arrivo si registra da solo quando ci si avvicina.
class MeetingPoint {
  const MeetingPoint({
    required this.id,
    required this.circleId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.createdBy,
    this.expiresAt,
  });

  factory MeetingPoint.fromRow(Map<String, dynamic> row) {
    return MeetingPoint(
      id: row['id'] as String,
      circleId: row['circle_id'] as String,
      name: row['name'] as String,
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      createdBy: row['created_by'] as String,
      expiresAt: row['expires_at'] != null ? DateTime.parse(row['expires_at'] as String) : null,
    );
  }

  final String id;
  final String circleId;
  final String name;
  final double lat;
  final double lng;
  final String createdBy;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

class MeetingPointArrival {
  const MeetingPointArrival({required this.meetingPointId, required this.profileId, required this.arrivedAt});

  factory MeetingPointArrival.fromRow(Map<String, dynamic> row) {
    return MeetingPointArrival(
      meetingPointId: row['meeting_point_id'] as String,
      profileId: row['profile_id'] as String,
      arrivedAt: DateTime.parse(row['arrived_at'] as String),
    );
  }

  final String meetingPointId;
  final String profileId;
  final DateTime arrivedAt;
}
