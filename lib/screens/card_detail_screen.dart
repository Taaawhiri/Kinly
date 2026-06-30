import 'package:flutter/material.dart';
import '../models/city_card.dart';
import '../models/rarity.dart';
import '../theme/app_theme.dart';
import '../widgets/city_card_widget.dart';

class CardDetailScreen extends StatelessWidget {
  const CardDetailScreen({super.key, required this.card});
  final CityCard card;

  @override
  Widget build(BuildContext context) {
    final rarity = card.rarity;
    return Scaffold(
      appBar: AppBar(
        title: Text(card.unlocked ? card.city : 'Carta sconosciuta'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                CityCardWidget(card: card, width: 280),
                const SizedBox(height: 28),
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
                      if (rarity.isAnimatedFoil && card.unlocked) ...[
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
