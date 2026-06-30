import 'package:flutter/foundation.dart';
import '../data/cities_data.dart';
import '../models/city_card.dart';

/// Stato in-memory della collezione del giocatore per la durata della
/// sessione: tiene traccia di quali carte sono state sbloccate aprendo
/// buste, in aggiunta allo stato iniziale "demo" del dataset.
class CollectionState extends ChangeNotifier {
  CollectionState._() : _cards = List.of(CitiesRepository.allCards);

  static final CollectionState instance = CollectionState._();

  final List<CityCard> _cards;

  List<CityCard> get cards => List.unmodifiable(_cards);

  int get unlockedCount => _cards.where((c) => c.unlocked).length;

  CityCard cardAt(int index) => _cards[index];

  /// Sblocca la carta con questo id (se non già sbloccata) e ritorna true
  /// se si trattava di una carta nuova per la collezione (non un duplicato).
  bool unlock(int id) {
    final index = _cards.indexWhere((c) => c.id == id);
    if (index == -1) return false;
    final wasNew = !_cards[index].unlocked;
    if (wasNew) {
      _cards[index] = _cards[index].copyWith(unlocked: true);
      notifyListeners();
    }
    return wasNew;
  }
}
