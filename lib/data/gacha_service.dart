import 'dart:math';
import '../models/city_card.dart';
import '../models/pack_result.dart';
import '../models/rarity.dart';
import '../state/collection_state.dart';
import 'cities_data.dart';

/// Motore delle probabilità di drop. Le percentuali sono fisse e
/// corrispondono esattamente a [Rarity.dropRatePercent] (la somma delle
/// sei rarità è sempre 100). Ogni busta contiene 5 carte indipendenti,
/// tranne nel raro caso di una God Pack: 0.1% di probabilità per busta di
/// trasformarla in un'estrazione garantita Leggendaria/Segreta.
class GachaService {
  GachaService._();

  static const int cardsPerPack = 5;
  static const double godPackChance = 0.001; // 0.1%

  static final Random _rng = Random();

  static PackResult openPack() {
    final isGodPack = _rng.nextDouble() < godPackChance;
    final cards = isGodPack ? _drawGodPack() : _drawNormalPack();
    final isNew = cards.map((card) => CollectionState.instance.unlock(card.id)).toList();

    return PackResult(cards: cards, isGodPack: isGodPack, isNew: isNew);
  }

  static List<CityCard> _drawNormalPack() =>
      List.generate(cardsPerPack, (_) => _drawWeightedCard());

  static CityCard _drawWeightedCard() {
    final roll = _rng.nextDouble() * 100;
    var cumulative = 0.0;
    for (final rarity in Rarity.values) {
      cumulative += rarity.dropRatePercent;
      if (roll <= cumulative) return _randomCardOfRarity(rarity);
    }
    return _randomCardOfRarity(Rarity.comune);
  }

  /// Una God Pack garantisce 5 carte tra le due rarità più alte, con un
  /// 35% di possibilità per ogni slot di essere proprio la Segreta.
  static List<CityCard> _drawGodPack() {
    return List.generate(cardsPerPack, (_) {
      final rarity = _rng.nextDouble() < 0.35 ? Rarity.segreta : Rarity.leggendaria;
      return _randomCardOfRarity(rarity);
    });
  }

  static CityCard _randomCardOfRarity(Rarity rarity) {
    final pool = CitiesRepository.byRarity(rarity);
    return pool[_rng.nextInt(pool.length)];
  }
}
