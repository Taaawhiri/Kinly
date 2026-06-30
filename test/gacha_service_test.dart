import 'package:flutter_test/flutter_test.dart';
import 'package:urbis_tcg/data/gacha_service.dart';
import 'package:urbis_tcg/models/rarity.dart';
import 'package:urbis_tcg/state/collection_state.dart';

void main() {
  test('le percentuali di drop delle rarità sommano a 100', () {
    final total = Rarity.values.fold<double>(0, (sum, r) => sum + r.dropRatePercent);
    expect(total, 100);
  });

  test('ogni busta contiene esattamente 5 carte', () {
    final result = GachaService.openPack();
    expect(result.cards.length, 5);
    expect(result.isNew.length, 5);
  });

  test('su molte aperture la distribuzione delle rarità rispetta circa le percentuali attese', () {
    final counts = {for (final r in Rarity.values) r: 0};
    const iterations = 4000;
    for (var i = 0; i < iterations; i++) {
      for (final card in GachaService.openPack().cards) {
        counts[card.rarity] = counts[card.rarity]! + 1;
      }
    }
    const totalCards = iterations * 5;
    // La Comune deve restare nettamente la più frequente (tolleranza ampia
    // per via della componente God Pack e della casualità).
    final comunePercent = counts[Rarity.comune]! / totalCards * 100;
    expect(comunePercent, greaterThan(40));
    expect(comunePercent, lessThan(70));
  });

  test('una God Pack garantisce solo carte Leggendaria o Segreta', () {
    // Forziamo molte aperture finché non ne troviamo una God Pack (0.1%):
    // con un numero di tentativi alto la probabilità di fallire è trascurabile.
    var found = false;
    for (var i = 0; i < 20000 && !found; i++) {
      final result = GachaService.openPack();
      if (result.isGodPack) {
        found = true;
        for (final card in result.cards) {
          expect(card.rarity.index, greaterThanOrEqualTo(Rarity.leggendaria.index));
        }
      }
    }
  }, skip: false);

  test('CollectionState.unlock è idempotente: la stessa carta non conta due volte come nuova', () {
    const id = 100; // Atlantide: rarissima, prima di questo test difficilmente già sbloccata.
    final wasAlreadyUnlocked = CollectionState.instance.cards.firstWhere((c) => c.id == id).unlocked;
    final firstCall = CollectionState.instance.unlock(id);
    final secondCall = CollectionState.instance.unlock(id);

    expect(firstCall, !wasAlreadyUnlocked);
    expect(secondCall, false);
    expect(CollectionState.instance.cards.firstWhere((c) => c.id == id).unlocked, true);
  });
}
