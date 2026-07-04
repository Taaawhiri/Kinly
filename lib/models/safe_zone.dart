import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Sicura (luogo di fiducia: casa, scuola, lavoro) o pericolosa (luogo da
/// evitare: strada trafficata, zona isolata...). Cambia il colore sulla
/// mappa e la semantica della notifica: una sicura avvisa quando SI ESCE
/// o si entra come conferma, una pericolosa avvisa quando SI ENTRA (vedi
/// supabase/functions/send-push, case 'safe_zone_events').
enum SafeZoneType { safe, danger }

extension SafeZoneTypeData on SafeZoneType {
  String get dbValue => this == SafeZoneType.danger ? 'danger' : 'safe';

  static SafeZoneType fromDb(String? value) => value == 'danger' ? SafeZoneType.danger : SafeZoneType.safe;

  String label(AppLocalizations l10n) => this == SafeZoneType.danger ? l10n.safeZoneTypeDanger : l10n.safeZoneTypeSafe;

  /// Colore usato per disegnare l'area sulla mappa e per i badge in lista.
  Color get color => this == SafeZoneType.danger ? AppTheme.accentCoral : AppTheme.accentGreen;
}

/// Tipo di luogo di un'area: usato solo per scegliere un'icona e per
/// personalizzare il testo delle notifiche push (vedi
/// supabase/functions/send-push). home/work/school/other sono pensati per
/// le aree sicure, road/isolated/water per le zone pericolose (ma "other"
/// resta condiviso tra le due).
enum SafeZoneKind { home, work, school, other, road, isolated, water }

extension SafeZoneKindData on SafeZoneKind {
  String get dbValue => switch (this) {
        SafeZoneKind.home => 'home',
        SafeZoneKind.work => 'work',
        SafeZoneKind.school => 'school',
        SafeZoneKind.other => 'other',
        SafeZoneKind.road => 'road',
        SafeZoneKind.isolated => 'isolated',
        SafeZoneKind.water => 'water',
      };

  static SafeZoneKind fromDb(String value) {
    switch (value) {
      case 'home':
        return SafeZoneKind.home;
      case 'work':
        return SafeZoneKind.work;
      case 'school':
        return SafeZoneKind.school;
      case 'road':
        return SafeZoneKind.road;
      case 'isolated':
        return SafeZoneKind.isolated;
      case 'water':
        return SafeZoneKind.water;
      default:
        return SafeZoneKind.other;
    }
  }

  /// Le scelte proposte in fase di creazione per un'area sicura.
  static const safeKinds = [SafeZoneKind.home, SafeZoneKind.school, SafeZoneKind.work, SafeZoneKind.other];

  /// Le scelte proposte in fase di creazione per una zona pericolosa.
  static const dangerKinds = [SafeZoneKind.road, SafeZoneKind.isolated, SafeZoneKind.water, SafeZoneKind.other];

  String label(AppLocalizations l10n) => switch (this) {
        SafeZoneKind.home => l10n.safeZoneKindHome,
        SafeZoneKind.work => l10n.safeZoneKindWork,
        SafeZoneKind.school => l10n.safeZoneKindSchool,
        SafeZoneKind.other => l10n.safeZoneKindOther,
        SafeZoneKind.road => l10n.safeZoneKindRoad,
        SafeZoneKind.isolated => l10n.safeZoneKindIsolated,
        SafeZoneKind.water => l10n.safeZoneKindWater,
      };

  IconData get icon => switch (this) {
        SafeZoneKind.home => Icons.home_rounded,
        SafeZoneKind.work => Icons.work_rounded,
        SafeZoneKind.school => Icons.school_rounded,
        SafeZoneKind.other => Icons.fence_rounded,
        SafeZoneKind.road => Icons.directions_car_rounded,
        SafeZoneKind.isolated => Icons.nightlight_round,
        SafeZoneKind.water => Icons.water_rounded,
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
    required this.zoneType,
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
      zoneType: SafeZoneTypeData.fromDb(row['zone_type'] as String?),
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
  final SafeZoneType zoneType;
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
