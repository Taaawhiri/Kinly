import 'package:flutter/material.dart';
import '../models/city_card.dart';
import '../models/rarity.dart';
import '../theme/app_theme.dart';
import '../widgets/city_card_widget.dart';
import '../widgets/interactive_3d_card.dart';

class CardDetailScreen extends StatelessWidget {
  const CardDetailScreen({super.key, required this.card, this.revealLocked = false});
  final CityCard card;

  /// Se true, mostra sempre l'arte completa anche se la carta non è
  /// ancora sbloccata (usato dalla vetrina rarità e dal riepilogo busta).
  final bool revealLocked;

  @override
  Widget build(BuildContext context) {
    final rarity = card.rarity;
    final revealed = card.unlocked || revealLocked;
    return Scaffold(
      appBar: AppBar(
        title: Text(revealed ? card.city : 'Carta sconosciuta'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                SizedBox(
                  width: 280,
                  height: 280 * 1.42,
                  child: Interactive3DCard(
                    borderRadius: BorderRadius.circular(280 * 0.065),
                    child: CityCardWidget(card: card, width: 280, revealLocked: revealLocked),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Trascina la carta per inclinarla',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _InfoTile(label: 'Rarità', value: rarity.label, color: rarity.accentColor),
                          _InfoTile(label: 'Drop rate', value: '${rarity.dropRatePercent}%', color: rarity.accentColor),
                          _InfoTile(label: 'Nel set', value: '${rarity.cardsInSet} carte', color: rarity.accentColor),
                        ],
                      ),
                      if (rarity.isAnimatedFoil && revealed) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppTheme.surface,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: AppTheme.gold, size: 18),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Carta foil animata — l\'unica del set',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5)),
      ],
    );
  }
}
