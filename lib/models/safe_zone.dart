import 'package:flutter/material.dart';

/// Tipo di luogo di un'area sicura: usato solo per scegliere un'icona e per
/// personalizzare il testo delle notifiche push di ingresso/uscita (vedi
/// supabase/functions/send-push).
enum SafeZoneKind { home, work, school, other }

extension SafeZoneKindData on SafeZoneKind {
  String get dbValue => switch (this) {
        SafeZoneKind.home => 'home',
        SafeZoneKind.work => 'work',
        SafeZoneKind.school => 'school',
        SafeZoneKind.other => 'other',
      };

  static SafeZoneKind fromDb(String value) {
    switch (value) {
      case 'home':
        return SafeZoneKind.home;
      case 'work':
        return SafeZoneKind.work;
      case 'school':
        return SafeZoneKind.school;
      default:
        return SafeZoneKind.other;
    }
  }

  String get label => switch (this) {
        SafeZoneKind.home => 'Casa',
        SafeZoneKind.work => 'Lavoro',
        SafeZoneKind.school => 'Scuola',
        SafeZoneKind.other => 'Altro',
      };

  IconData get icon => switch (this) {
        SafeZoneKind.home => Icons.home_rounded,
        SafeZoneKind.work => Icons.work_rounded,
        SafeZoneKind.school => Icons.school_rounded,
        SafeZoneKind.other => Icons.fence_rounded,
      };
}

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
    required this.kind,
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
      kind: SafeZoneKindData.fromDb(row['kind'] as String? ?? 'other'),
    );
  }

  final String id;
  final String circleId;
  final String name;
  final double lat;
  final double lng;
  final int radiusMeters;
  final String createdBy;
  final SafeZoneKind kind;
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
