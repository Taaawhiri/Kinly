import 'city_card.dart';

/// Il contenuto di una busta appena apert: 5 carte, eventualmente una
/// "God Pack" (la combinazione più rara possibile).
class PackResult {
  const PackResult({required this.cards, required this.isGodPack, required this.isNew});

  final List<CityCard> cards;
  final bool isGodPack;

  /// Per ogni carta in [cards], true se era nuova per la collezione (non un duplicato).
  final List<bool> isNew;

  int get newUnlocks => isNew.where((b) => b).length;
}
