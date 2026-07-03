import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Motivo predefinito di una richiesta di aiuto: un gradino sotto l'SOS,
/// per situazioni che non sono un'emergenza ma per cui vuoi avvisare
/// rapidamente la cerchia (a differenza dell'SOS, non bypassa la modalità
/// di condivisione).
enum HelpRequestReason { flatTire, accident, followed, lowBattery, other }

extension HelpRequestReasonData on HelpRequestReason {
  String get dbValue => switch (this) {
        HelpRequestReason.flatTire => 'flat_tire',
        HelpRequestReason.accident => 'accident',
        HelpRequestReason.followed => 'followed',
        HelpRequestReason.lowBattery => 'low_battery',
        HelpRequestReason.other => 'other',
      };

  static HelpRequestReason fromDb(String value) {
    switch (value) {
      case 'flat_tire':
        return HelpRequestReason.flatTire;
      case 'accident':
        return HelpRequestReason.accident;
      case 'followed':
        return HelpRequestReason.followed;
      case 'low_battery':
        return HelpRequestReason.lowBattery;
      default:
        return HelpRequestReason.other;
    }
  }

  String label(AppLocalizations l10n) => switch (this) {
        HelpRequestReason.flatTire => l10n.helpReqReasonFlatTire,
        HelpRequestReason.accident => l10n.helpReqReasonAccident,
        HelpRequestReason.followed => l10n.helpReqReasonFollowed,
        HelpRequestReason.lowBattery => l10n.helpReqReasonLowBattery,
        HelpRequestReason.other => l10n.helpReqReasonOther,
      };

  IconData get icon => switch (this) {
        HelpRequestReason.flatTire => Icons.tire_repair_rounded,
        HelpRequestReason.accident => Icons.car_crash_rounded,
        HelpRequestReason.followed => Icons.visibility_rounded,
        HelpRequestReason.lowBattery => Icons.battery_alert_rounded,
        HelpRequestReason.other => Icons.help_rounded,
      };

  String get emoji => switch (this) {
        HelpRequestReason.flatTire => '🛞',
        HelpRequestReason.accident => '🚗',
        HelpRequestReason.followed => '👀',
        HelpRequestReason.lowBattery => '🔋',
        HelpRequestReason.other => '🆘',
      };
}

enum HelpRequestStatus { active, resolved }

class HelpRequest {
  const HelpRequest({
    required this.id,
    required this.circleId,
    required this.profileId,
    required this.reason,
    required this.note,
    required this.lat,
    required this.lng,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  factory HelpRequest.fromRow(Map<String, dynamic> row) {
    return HelpRequest(
      id: row['id'] as String,
      circleId: row['circle_id'] as String,
      profileId: row['profile_id'] as String,
      reason: HelpRequestReasonData.fromDb(row['reason'] as String),
      note: row['note'] as String?,
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      status: row['status'] == 'resolved' ? HelpRequestStatus.resolved : HelpRequestStatus.active,
      createdAt: DateTime.parse(row['created_at'] as String),
      resolvedAt: row['resolved_at'] != null ? DateTime.parse(row['resolved_at'] as String) : null,
    );
  }

  final String id;
  final String circleId;
  final String profileId;
  final HelpRequestReason reason;
  final String? note;
  final double lat;
  final double lng;
  final HelpRequestStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
}
