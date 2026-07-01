/// Un avviso di guida (Kinly+): registrato quando qualcuno supera la
/// propria soglia di velocità impostata.
class SpeedEvent {
  const SpeedEvent({
    required this.id,
    required this.profileId,
    required this.speedKmh,
    required this.thresholdKmh,
    required this.occurredAt,
  });

  factory SpeedEvent.fromRow(Map<String, dynamic> row) {
    return SpeedEvent(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      speedKmh: (row['speed_kmh'] as num).toDouble(),
      thresholdKmh: (row['threshold_kmh'] as num).toDouble(),
      occurredAt: DateTime.parse(row['occurred_at'] as String),
    );
  }

  final String id;
  final String profileId;
  final double speedKmh;
  final double thresholdKmh;
  final DateTime occurredAt;
}
