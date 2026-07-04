import 'package:flutter/material.dart';

/// Categoria di uno spot per Ritrovi: usata sia per l'icona che per il
/// filtro nella lista.
enum MeetupSpotCategory {
  park,
  bar,
  sport,
  other;

  static MeetupSpotCategory fromRow(String value) {
    return MeetupSpotCategory.values.firstWhere((c) => c.value == value, orElse: () => MeetupSpotCategory.other);
  }

  String get value => switch (this) {
    MeetupSpotCategory.park => 'park',
    MeetupSpotCategory.bar => 'bar',
    MeetupSpotCategory.sport => 'sport',
    MeetupSpotCategory.other => 'other',
  };

  IconData get icon => switch (this) {
    MeetupSpotCategory.park => Icons.park_outlined,
    MeetupSpotCategory.bar => Icons.local_cafe_outlined,
    MeetupSpotCategory.sport => Icons.sports_soccer_outlined,
    MeetupSpotCategory.other => Icons.place_outlined,
  };
}

/// Un posto salvato per ritrovarsi (parco, bar, campetto...), riutilizzabile
/// da chiunque nella cerchia. Non rivela mai una posizione live: è un punto
/// fisso, proposto una volta, non una posizione di una persona.
class MeetupSpot {
  const MeetupSpot({
    required this.id,
    required this.circleId,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    this.note,
    required this.createdBy,
    required this.createdAt,
  });

  factory MeetupSpot.fromRow(Map<String, dynamic> row) {
    return MeetupSpot(
      id: row['id'] as String,
      circleId: row['circle_id'] as String,
      name: row['name'] as String,
      category: MeetupSpotCategory.fromRow(row['category'] as String),
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      note: row['note'] as String?,
      createdBy: row['created_by'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  final String id;
  final String circleId;
  final String name;
  final MeetupSpotCategory category;
  final double lat;
  final double lng;
  final String? note;
  final String createdBy;
  final DateTime createdAt;
}

/// Una proposta di ritrovo in uno spot, con orario e nota facoltativa.
class Meetup {
  const Meetup({
    required this.id,
    required this.spotId,
    required this.circleId,
    required this.proposedBy,
    required this.scheduledAt,
    this.note,
    required this.createdAt,
  });

  factory Meetup.fromRow(Map<String, dynamic> row) {
    return Meetup(
      id: row['id'] as String,
      spotId: row['spot_id'] as String,
      circleId: row['circle_id'] as String,
      proposedBy: row['proposed_by'] as String,
      scheduledAt: DateTime.parse(row['scheduled_at'] as String),
      note: row['note'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  final String id;
  final String spotId;
  final String circleId;
  final String proposedBy;
  final DateTime scheduledAt;
  final String? note;
  final DateTime createdAt;

  /// Un ritrovo si considera passato/concluso 3 ore dopo l'orario proposto:
  /// da lì in poi non ha più senso mostrarlo tra le proposte attive.
  bool get isPast => DateTime.now().isAfter(scheduledAt.add(const Duration(hours: 3)));
}

enum MeetupRsvpResponse {
  yes,
  no;

  static MeetupRsvpResponse fromRow(String value) => value == 'yes' ? MeetupRsvpResponse.yes : MeetupRsvpResponse.no;

  String get value => this == MeetupRsvpResponse.yes ? 'yes' : 'no';
}

/// Risposta di un membro a un ritrovo proposto.
class MeetupRsvp {
  const MeetupRsvp({
    required this.meetupId,
    required this.profileId,
    required this.response,
    required this.respondedAt,
  });

  factory MeetupRsvp.fromRow(Map<String, dynamic> row) {
    return MeetupRsvp(
      meetupId: row['meetup_id'] as String,
      profileId: row['profile_id'] as String,
      response: MeetupRsvpResponse.fromRow(row['response'] as String),
      respondedAt: DateTime.parse(row['responded_at'] as String),
    );
  }

  final String meetupId;
  final String profileId;
  final MeetupRsvpResponse response;
  final DateTime respondedAt;
}

/// Check-in puntuale in uno spot: "chi c'è ora" (ambientale, se [meetupId] è
/// nullo) oppure conferma d'arrivo a un ritrovo proposto. Come per
/// ShoppingStop, nessuna scadenza salvata: si calcola qui, lato client.
class MeetupCheckin {
  const MeetupCheckin({
    required this.id,
    required this.spotId,
    this.meetupId,
    required this.profileId,
    required this.circleId,
    required this.createdAt,
  });

  factory MeetupCheckin.fromRow(Map<String, dynamic> row) {
    return MeetupCheckin(
      id: row['id'] as String,
      spotId: row['spot_id'] as String,
      meetupId: row['meetup_id'] as String?,
      profileId: row['profile_id'] as String,
      circleId: row['circle_id'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  final String id;
  final String spotId;
  final String? meetupId;
  final String profileId;
  final String circleId;
  final DateTime createdAt;

  /// Un check-in più vecchio di 3 ore si considera concluso: la persona non
  /// è più "presente ora" in quello spot.
  bool get isActive => DateTime.now().difference(createdAt) < const Duration(hours: 3);
}
