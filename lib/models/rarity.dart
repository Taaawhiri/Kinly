import 'package:flutter/material.dart';

/// Le sei rarità del set "URBIS — 100 Città del Mondo".
/// Ordinate dalla più comune (index 0) alla più rara (index 5).
enum Rarity {
  comune,
  nonComune,
  rara,
  epica,
  leggendaria,
  segreta,
}

extension RarityData on Rarity {
  String get label {
    switch (this) {
      case Rarity.comune:
        return 'Comune';
      case Rarity.nonComune:
        return 'Non Comune';
      case Rarity.rara:
        return 'Rara';
      case Rarity.epica:
        return 'Epica';
      case Rarity.leggendaria:
        return 'Leggendaria';
      case Rarity.segreta:
        return 'Segreta';
    }
  }

  /// Sigla mostrata sul badge della carta, stile TCG (es. "C", "U", "R"...).
  String get sigla {
    switch (this) {
      case Rarity.comune:
        return 'C';
      case Rarity.nonComune:
        return 'NC';
      case Rarity.rara:
        return 'R';
      case Rarity.epica:
        return 'E';
      case Rarity.leggendaria:
        return 'L';
      case Rarity.segreta:
        return '★';
    }
  }

  /// Quante carte del set di 100 appartengono a questa rarità.
  int get cardsInSet {
    switch (this) {
      case Rarity.comune:
        return 40;
      case Rarity.nonComune:
        return 28;
      case Rarity.rara:
        return 18;
      case Rarity.epica:
        return 9;
      case Rarity.leggendaria:
        return 4;
      case Rarity.segreta:
        return 1;
    }
  }

  /// Probabilità indicativa di drop da una busta (somma = 100).
  double get dropRatePercent {
    switch (this) {
      case Rarity.comune:
        return 55;
      case Rarity.nonComune:
        return 27;
      case Rarity.rara:
        return 12;
      case Rarity.epica:
        return 4.5;
      case Rarity.leggendaria:
        return 1.2;
      case Rarity.segreta:
        return 0.3;
    }
  }

  /// La rarità più alta ha la carta foil animata.
  bool get isAnimatedFoil => this == Rarity.segreta;

  /// Dalla rara in su le carte hanno un piccolo effetto di luce statico.
  bool get hasShine => index >= Rarity.rara.index;

  IconData get icon {
    switch (this) {
      case Rarity.comune:
        return Icons.location_city;
      case Rarity.nonComune:
        return Icons.apartment;
      case Rarity.rara:
        return Icons.account_balance;
      case Rarity.epica:
        return Icons.castle;
      case Rarity.leggendaria:
        return Icons.auto_awesome;
      case Rarity.segreta:
        return Icons.diamond;
    }
  }

  /// Colori principali usati per sfondo carta, badge e bagliori.
  List<Color> get gradientColors {
    switch (this) {
      case Rarity.comune:
        return const [Color(0xFF6B7785), Color(0xFF9AA5B1), Color(0xFFCBD3DA)];
      case Rarity.nonComune:
        return const [Color(0xFF14532D), Color(0xFF2E8B57), Color(0xFF6EE7A8)];
      case Rarity.rara:
        return const [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF7DD3FC)];
      case Rarity.epica:
        return const [Color(0xFF4C1D95), Color(0xFF7C3AED), Color(0xFFD8B4FE)];
      case Rarity.leggendaria:
        return const [Color(0xFF7C2D12), Color(0xFFD97706), Color(0xFFFDE68A)];
      case Rarity.segreta:
        return const [
          Color(0xFFFF3CAC),
          Color(0xFF784BA0),
          Color(0xFF2B86C5),
          Color(0xFF22D3EE),
          Color(0xFFFFD86B),
          Color(0xFFFF3CAC),
        ];
    }
  }

  Color get accentColor => gradientColors[gradientColors.length ~/ 2];
  Color get borderColor => gradientColors.last;
}
