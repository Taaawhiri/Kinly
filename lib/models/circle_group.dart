import 'package:flutter/material.dart';
import '../utils/circle_icons.dart';
import '../utils/color_hex.dart';

/// 'family' è il comportamento di sempre (posizione live condivisa secondo
/// le impostazioni di ognuno). 'events' è la Cerchia Eventi: nessuna
/// posizione live viene mai condivisa, solo Ritrovi con check-in puntuale.
enum CircleType {
  family,
  events;

  static CircleType fromRow(String? value) => value == 'events' ? CircleType.events : CircleType.family;

  String get value => this == CircleType.events ? 'events' : 'family';
}

/// Un gruppo di persone con cui condividi la posizione (famiglia, amici,
/// colleghi...). L'accesso è solo su invito: si entra con un codice.
/// Corrisponde a una riga della tabella `circles` su Supabase.
class CircleGroup {
  const CircleGroup({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.memberIds,
    required this.inviteCode,
    required this.createdBy,
    this.circleType = CircleType.family,
  });

  factory CircleGroup.fromRow(Map<String, dynamic> row, {required List<String> memberIds}) {
    return CircleGroup(
      id: row['id'] as String,
      name: row['name'] as String,
      icon: CircleIcons.iconFor(row['icon_key'] as String? ?? 'groups'),
      color: ColorHex.fromHex(row['color'] as String? ?? '#4A63E7'),
      memberIds: memberIds,
      inviteCode: row['invite_code'] as String,
      createdBy: row['created_by'] as String,
      circleType: CircleType.fromRow(row['circle_type'] as String?),
    );
  }

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<String> memberIds;
  final String inviteCode;
  final String createdBy;
  final CircleType circleType;

  bool get isEventsCircle => circleType == CircleType.events;

  CircleGroup copyWith({List<String>? memberIds}) {
    return CircleGroup(
      id: id,
      name: name,
      icon: icon,
      color: color,
      memberIds: memberIds ?? this.memberIds,
      inviteCode: inviteCode,
      createdBy: createdBy,
      circleType: circleType,
    );
  }
}
