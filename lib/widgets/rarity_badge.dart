import 'package:flutter/material.dart';
import '../models/rarity.dart';

class RarityBadge extends StatelessWidget {
  const RarityBadge({super.key, required this.rarity, this.dense = false, this.useSigla = false});

  final Rarity rarity;
  final bool dense;

  /// Mostra la sigla (es. "NC") invece dell'etichetta intera: utile negli
  /// spazi molto stretti, come l'intestazione della carta.
  final bool useSigla;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 7 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: rarity.gradientColors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: rarity.accentColor.withOpacity(0.5), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(rarity.icon, size: dense ? 11 : 14, color: Colors.white),
          SizedBox(width: dense ? 3 : 5),
          Flexible(
            child: Text(
              useSigla ? rarity.sigla : rarity.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: dense ? 10 : 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
