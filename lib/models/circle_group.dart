import 'package:flutter/material.dart';

/// Un gruppo di persone con cui condividi la posizione (famiglia, amici,
/// colleghi...). L'accesso è solo su invito: si entra con un codice.
class CircleGroup {
  const CircleGroup({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.memberIds,
    required this.inviteCode,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final List<String> memberIds;
  final String inviteCode;

  CircleGroup copyWith({List<String>? memberIds}) {
    return CircleGroup(
      id: id,
      name: name,
      icon: icon,
      color: color,
      memberIds: memberIds ?? this.memberIds,
      inviteCode: inviteCode,
    );
  }
}
