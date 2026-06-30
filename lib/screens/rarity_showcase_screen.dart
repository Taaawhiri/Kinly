import 'package:flutter/material.dart';
import '../data/cities_data.dart';
import '../models/rarity.dart';
import '../theme/app_theme.dart';
import '../widgets/city_card_widget.dart';
import '../widgets/rarity_badge.dart';

/// Galleria con un esempio di carta per ogni rarità del set, dalla più
/// comune (Comune) alla più rara in assoluto (Segreta, foil animata).
class RarityShowcaseScreen extends StatelessWidget {
  const RarityShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Le Rarità',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Dalla città dietro l\'angolo al mito perduto: più la rarità sale, più la carta diventa preziosa.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: Rarity.values.length,
            itemBuilder: (context, i) {
              final rarity = Rarity.values[i];
              final card = CitiesRepository.byRarity(rarity).first;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RarityBadge(rarity: rarity),
                        const SizedBox(width: 10),
                        Text(
                          '${rarity.cardsInSet} carte · ${rarity.dropRatePercent}% drop',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Center(child: CityCardWidget(card: card, width: 240, revealLocked: true)),
                    if (rarity.isAnimatedFoil) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(colors: rarity.gradientColors),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Foil olografica animata',
                                style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
