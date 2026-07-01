import 'package:flutter/material.dart';

/// Le icone tra cui si può scegliere per una cerchia, con la chiave
/// testuale corrispondente salvata in `circles.icon_key` su Supabase.
class CircleIcons {
  CircleIcons._();

  static const Map<String, IconData> byKey = {
    'favorite': Icons.favorite_rounded,
    'groups': Icons.groups_rounded,
    'work': Icons.work_rounded,
    'school': Icons.school_rounded,
    'pets': Icons.pets_rounded,
    'celebration': Icons.celebration_rounded,
  };

  static const List<String> choices = ['favorite', 'groups', 'work', 'school', 'pets', 'celebration'];

  static IconData iconFor(String key) => byKey[key] ?? Icons.groups_rounded;

  static String keyFor(IconData icon) => byKey.entries.firstWhere((e) => e.value == icon, orElse: () => byKey.entries.first).key;
}
