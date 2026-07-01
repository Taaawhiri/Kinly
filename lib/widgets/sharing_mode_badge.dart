import 'package:flutter/material.dart';
import '../models/sharing_mode.dart';

/// Piccolo badge colorato che riassume la modalità di condivisione.
class SharingModeBadge extends StatelessWidget {
  const SharingModeBadge({super.key, required this.mode, this.dense = false});

  final SharingMode mode;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 12, vertical: dense ? 4 : 6),
      decoration: BoxDecoration(
        color: mode.color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(mode.icon, size: dense ? 12 : 14, color: mode.color),
          SizedBox(width: dense ? 4 : 6),
          Text(
            mode.label,
            style: TextStyle(color: mode.color, fontWeight: FontWeight.w700, fontSize: dense ? 11 : 12.5),
          ),
        ],
      ),
    );
  }
}
