/// Una sosta rilevata in un supermercato/negozio/bar (funzione "Portami
/// qualcosa"): visibile alla cerchia, così chi vuole può chiedere qualcosa
/// al volo prima che la persona esca dal negozio.
class ShoppingStop {
  const ShoppingStop({
    required this.id,
    required this.profileId,
    required this.circleId,
    required this.category,
    this.placeName,
    required this.lat,
    required this.lng,
    required this.createdAt,
  });

  factory ShoppingStop.fromRow(Map<String, dynamic> row) {
    return ShoppingStop(
      id: row['id'] as String,
      profileId: row['profile_id'] as String,
      circleId: row['circle_id'] as String,
      category: row['category'] as String,
      placeName: row['place_name'] as String?,
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  final String id;
  final String profileId;
  final String circleId;
  final String category;
  final String? placeName;
  final double lat;
  final double lng;
  final DateTime createdAt;

  /// Una sosta più vecchia di 30 minuti si considera conclusa: non ha più
  /// senso proporre di chiedere qualcosa.
  bool get isActive => DateTime.now().difference(createdAt) < const Duration(minutes: 30);
}

class ShoppingRequest {
  const ShoppingRequest({required this.id, required this.stopId, required this.fromId, required this.note, required this.createdAt});

  factory ShoppingRequest.fromRow(Map<String, dynamic> row) {
    return ShoppingRequest(
      id: row['id'] as String,
      stopId: row['stop_id'] as String,
      fromId: row['from_id'] as String,
      note: row['note'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  final String id;
  final String stopId;
  final String fromId;
  final String note;
  final DateTime createdAt;
}

/// Voce fissa della lista della spesa di una cerchia (es. "Latte", "Pane"):
/// a differenza di [ShoppingStop] non è legata a una sosta estemporanea,
/// resta finché non viene rimossa. "Ci penso io" la marca presa in carico.
class ShoppingListItem {
  const ShoppingListItem({
    required this.id,
    required this.circleId,
    required this.label,
    required this.createdBy,
    required this.createdAt,
    this.claimedBy,
    this.claimedAt,
  });

  factory ShoppingListItem.fromRow(Map<String, dynamic> row) {
    return ShoppingListItem(
      id: row['id'] as String,
      circleId: row['circle_id'] as String,
      label: row['label'] as String,
      createdBy: row['created_by'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      claimedBy: row['claimed_by'] as String?,
      claimedAt: row['claimed_at'] == null ? null : DateTime.parse(row['claimed_at'] as String),
    );
  }

  final String id;
  final String circleId;
  final String label;
  final String createdBy;
  final DateTime createdAt;
  final String? claimedBy;
  final DateTime? claimedAt;

  bool get isClaimed => claimedBy != null;
}
