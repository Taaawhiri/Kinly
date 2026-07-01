enum SosStatus { active, resolved }

/// Un SOS attivato da qualcuno della cerchia: solo posizione, nessuna
/// registrazione audio. Bypassa deliberatamente la modalità di
/// condivisione normale (vedi la policy RLS sos_alerts_select).
class SosAlert {
  const SosAlert({
    required this.id,
    required this.profileId,
    required this.lat,
    required this.lng,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  factory SosAlert.fromRow(Map<String, dynamic> row) {
    return SosAlert(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      status: row['status'] == 'resolved' ? SosStatus.resolved : SosStatus.active,
      createdAt: DateTime.parse(row['created_at'] as String),
      resolvedAt: row['resolved_at'] != null ? DateTime.parse(row['resolved_at'] as String) : null,
    );
  }

  final String id;
  final String profileId;
  final double lat;
  final double lng;
  final SosStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
}
