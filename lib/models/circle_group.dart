import 'package:flutter/material.dart';
import '../utils/circle_icons.dart';
import '../utils/color_hex.dart';

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
    );
  }

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<String> memberIds;
  final String inviteCode;
  final String createdBy;

  CircleGroup copyWith({List<String>? memberIds}) {
    return CircleGroup(
      id: id,
      name: name,
      icon: icon,
      color: color,
      memberIds: memberIds ?? this.memberIds,
      inviteCode: inviteCode,
      createdBy: createdBy,
    );
  }
}
