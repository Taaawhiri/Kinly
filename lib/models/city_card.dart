import 'rarity.dart';

/// Una carta collezionabile del set "URBIS — 100 Città del Mondo".
class CityCard {
  const CityCard({
    required this.id,
    required this.city,
    required this.country,
    required this.continent,
    required this.rarity,
    required this.flavorText,
    required this.population,
    required this.foundedYear,
    this.unlocked = false,
  });

  /// Numero di catalogo, es. 7 -> "007/100".
  final int id;
  final String city;
  final String country;
  final String continent;
  final Rarity rarity;
  final String flavorText;
  final int population;
  final int foundedYear;
  final bool unlocked;

  String get cardNumber => '${id.toString().padLeft(3, '0')}/100';

  CityCard copyWith({bool? unlocked}) {
    return CityCard(
      id: id,
      city: city,
      country: country,
      continent: continent,
      rarity: rarity,
      flavorText: flavorText,
      population: population,
      foundedYear: foundedYear,
      unlocked: unlocked ?? this.unlocked,
    );
  }

  String get populationFormatted {
    if (population <= 0) return 'Sito storico';
    if (population >= 1000000) {
      final millions = population / 1000000;
      return '${millions.toStringAsFixed(millions >= 10 ? 0 : 1)}M ab.';
    }
    return '${(population / 1000).round()}K ab.';
  }

  String get foundedYearFormatted {
    if (foundedYear < 0) return '${-foundedYear} a.C.';
    return '$foundedYear d.C.';
  }
}
