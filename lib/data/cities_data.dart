import '../models/city_card.dart';
import '../models/rarity.dart';

class _Seed {
  const _Seed(this.city, this.country, this.continent, this.population, this.foundedYear, this.rarity, {this.flavor});
  final String city;
  final String country;
  final String continent;
  final int population;
  final int foundedYear; // negativo = a.C.
  final Rarity rarity;
  final String? flavor;
}

/// Repository statico del set "URBIS — 100 Città del Mondo".
class CitiesRepository {
  CitiesRepository._();

  static final List<CityCard> allCards = _buildCards();

  static List<CityCard> byRarity(Rarity rarity) =>
      allCards.where((c) => c.rarity == rarity).toList();

  /// Una carta rappresentativa per ciascuna rarità, in ordine crescente,
  /// usata nella vetrina dell'app.
  static List<CityCard> get showcaseSet =>
      Rarity.values.map((r) => byRarity(r).first).toList();

  static List<CityCard> _buildCards() {
    final cards = <CityCard>[];
    for (var i = 0; i < _seeds.length; i++) {
      final id = i + 1;
      final s = _seeds[i];
      final unlocked = _isUnlocked(id, s.rarity);
      cards.add(CityCard(
        id: id,
        city: s.city,
        country: s.country,
        continent: s.continent,
        rarity: s.rarity,
        flavorText: s.flavor ?? _genericFlavor(s),
        population: s.population,
        foundedYear: s.foundedYear,
        unlocked: unlocked,
      ));
    }
    return cards;
  }

  static bool _isUnlocked(int id, Rarity rarity) {
    switch (rarity) {
      case Rarity.comune:
        return id % 5 != 0; // 32/40 sbloccate
      case Rarity.nonComune:
        return id % 4 == 0; // 7/28 sbloccate
      case Rarity.rara:
        return id == 70 || id == 77; // 2/18 sbloccate
      case Rarity.epica:
      case Rarity.leggendaria:
      case Rarity.segreta:
        return false; // ancora avvolte nel mistero...
    }
  }

  static String _genericFlavor(_Seed s) {
    switch (s.rarity) {
      case Rarity.comune:
        return 'Una metropoli che pulsa di vita ogni giorno, nel cuore di ${s.country}.';
      case Rarity.nonComune:
        return 'Tra strade affollate e angoli sorprendenti, ${s.city} sa sempre stupire.';
      case Rarity.rara:
        return 'Antiche pietre e storie dimenticate si respirano a ogni angolo di ${s.city}.';
      case Rarity.epica:
        return 'Le leggende di ${s.city} attraversano i secoli: chi la visita non torna più lo stesso.';
      case Rarity.leggendaria:
        return '${s.city} non è solo una città: è un mito vivente, scolpito nella memoria del mondo.';
      case Rarity.segreta:
        return 'Si dice che esista solo per chi sa davvero dove cercare.';
    }
  }

  // 1-40 — COMUNE (40 carte): grandi metropoli moderne note a tutti.
  static const List<_Seed> _comune = [
    _Seed('Tokyo', 'Giappone', 'Asia', 37400000, 1457, Rarity.comune),
    _Seed('New York', 'Stati Uniti', 'Nord America', 8800000, 1624, Rarity.comune),
    _Seed('Londra', 'Regno Unito', 'Europa', 9000000, 47, Rarity.comune),
    _Seed('Parigi', 'Francia', 'Europa', 2140000, -250, Rarity.comune),
    _Seed('Berlino', 'Germania', 'Europa', 3700000, 1237, Rarity.comune),
    _Seed('Madrid', 'Spagna', 'Europa', 3300000, 852, Rarity.comune),
    _Seed('Toronto', 'Canada', 'Nord America', 2900000, 1793, Rarity.comune),
    _Seed('Sydney', 'Australia', 'Oceania', 5300000, 1788, Rarity.comune),
    _Seed('Los Angeles', 'Stati Uniti', 'Nord America', 3900000, 1781, Rarity.comune),
    _Seed('Chicago', 'Stati Uniti', 'Nord America', 2700000, 1833, Rarity.comune),
    _Seed('Città del Messico', 'Messico', 'Nord America', 9200000, 1325, Rarity.comune),
    _Seed('San Paolo', 'Brasile', 'Sud America', 12300000, 1554, Rarity.comune),
    _Seed('Buenos Aires', 'Argentina', 'Sud America', 3100000, 1536, Rarity.comune),
    _Seed('Mumbai', 'India', 'Asia', 12400000, 1507, Rarity.comune),
    _Seed('Shanghai', 'Cina', 'Asia', 24900000, 1291, Rarity.comune),
    _Seed('Seul', 'Corea del Sud', 'Asia', 9700000, 18, Rarity.comune),
    _Seed('Bangkok', 'Thailandia', 'Asia', 10500000, 1782, Rarity.comune),
    _Seed('Dubai', 'Emirati Arabi Uniti', 'Asia', 3500000, 1833, Rarity.comune),
    _Seed('Singapore', 'Singapore', 'Asia', 5700000, 1819, Rarity.comune),
    _Seed('Hong Kong', 'Cina', 'Asia', 7400000, 1842, Rarity.comune),
    _Seed('Amsterdam', 'Paesi Bassi', 'Europa', 870000, 1275, Rarity.comune),
    _Seed('Vienna', 'Austria', 'Europa', 1900000, 1, Rarity.comune),
    _Seed('Bruxelles', 'Belgio', 'Europa', 1200000, 979, Rarity.comune),
    _Seed('Lisbona', 'Portogallo', 'Europa', 545000, -1200, Rarity.comune),
    _Seed('Dublino', 'Irlanda', 'Europa', 1200000, 841, Rarity.comune),
    _Seed('Stoccolma', 'Svezia', 'Europa', 980000, 1252, Rarity.comune),
    _Seed('Copenaghen', 'Danimarca', 'Europa', 800000, 1167, Rarity.comune),
    _Seed('Oslo', 'Norvegia', 'Europa', 700000, 1040, Rarity.comune),
    _Seed('Helsinki', 'Finlandia', 'Europa', 660000, 1550, Rarity.comune),
    _Seed('Varsavia', 'Polonia', 'Europa', 1800000, 1300, Rarity.comune),
    _Seed('Praga', 'Repubblica Ceca', 'Europa', 1300000, 870, Rarity.comune),
    _Seed('Budapest', 'Ungheria', 'Europa', 1750000, 1241, Rarity.comune),
    _Seed('Atene', 'Grecia', 'Europa', 660000, -3000, Rarity.comune),
    _Seed('Il Cairo', 'Egitto', 'Africa', 10000000, 969, Rarity.comune),
    _Seed('Città del Capo', 'Sudafrica', 'Africa', 4600000, 1652, Rarity.comune),
    _Seed('Nairobi', 'Kenya', 'Africa', 4400000, 1899, Rarity.comune),
    _Seed('Lagos', 'Nigeria', 'Africa', 15400000, 1845, Rarity.comune),
    _Seed('Auckland', 'Nuova Zelanda', 'Oceania', 1700000, 1840, Rarity.comune),
    _Seed('Vancouver', 'Canada', 'Nord America', 2600000, 1886, Rarity.comune),
    _Seed('Miami', 'Stati Uniti', 'Nord America', 470000, 1896, Rarity.comune),
  ];

  // 41-68 — NON COMUNE (28 carte): città dal carattere distintivo.
  static const List<_Seed> _nonComune = [
    _Seed('Barcellona', 'Spagna', 'Europa', 1620000, -230, Rarity.nonComune),
    _Seed('Milano', 'Italia', 'Europa', 1370000, -590, Rarity.nonComune),
    _Seed('Monaco di Baviera', 'Germania', 'Europa', 1480000, 1158, Rarity.nonComune),
    _Seed('Zurigo', 'Svizzera', 'Europa', 440000, 15, Rarity.nonComune),
    _Seed('Ginevra', 'Svizzera', 'Europa', 200000, -100, Rarity.nonComune),
    _Seed('Edimburgo', 'Regno Unito', 'Europa', 530000, 600, Rarity.nonComune),
    _Seed('Reykjavik', 'Islanda', 'Europa', 130000, 874, Rarity.nonComune),
    _Seed('Marrakech', 'Marocco', 'Africa', 930000, 1070, Rarity.nonComune),
    _Seed('Casablanca', 'Marocco', 'Africa', 3700000, 1515, Rarity.nonComune),
    _Seed('Istanbul', 'Turchia', 'Asia', 15500000, -660, Rarity.nonComune),
    _Seed('Pechino', 'Cina', 'Asia', 21500000, -1045, Rarity.nonComune),
    _Seed('Osaka', 'Giappone', 'Asia', 2700000, 645, Rarity.nonComune),
    _Seed('Taipei', 'Taiwan', 'Asia', 2600000, 1709, Rarity.nonComune),
    _Seed('Kuala Lumpur', 'Malesia', 'Asia', 1800000, 1857, Rarity.nonComune),
    _Seed('Giacarta', 'Indonesia', 'Asia', 10500000, 1527, Rarity.nonComune),
    _Seed('Manila', 'Filippine', 'Asia', 1850000, 1571, Rarity.nonComune),
    _Seed('Tel Aviv', 'Israele', 'Asia', 460000, 1909, Rarity.nonComune),
    _Seed('Doha', 'Qatar', 'Asia', 1450000, 1825, Rarity.nonComune),
    _Seed('Johannesburg', 'Sudafrica', 'Africa', 5800000, 1886, Rarity.nonComune),
    _Seed('Addis Abeba', 'Etiopia', 'Africa', 3400000, 1886, Rarity.nonComune),
    _Seed('Tunisi', 'Tunisia', 'Africa', 690000, -698, Rarity.nonComune),
    _Seed('Accra', 'Ghana', 'Africa', 2500000, 1650, Rarity.nonComune),
    _Seed('Montreal', 'Canada', 'Nord America', 1800000, 1642, Rarity.nonComune),
    _Seed('Boston', 'Stati Uniti', 'Nord America', 690000, 1630, Rarity.nonComune),
    _Seed('Lima', 'Perù', 'Sud America', 9700000, 1535, Rarity.nonComune),
    _Seed('Bogotà', 'Colombia', 'Sud America', 7900000, 1538, Rarity.nonComune),
    _Seed('Santiago', 'Cile', 'Sud America', 6300000, 1541, Rarity.nonComune),
    _Seed('Melbourne', 'Australia', 'Oceania', 5100000, 1835, Rarity.nonComune),
  ];

  // 69-86 — RARA (18 carte): gioielli storici meno scontati.
  static const List<_Seed> _rara = [
    _Seed('Firenze', 'Italia', 'Europa', 360000, 59, Rarity.rara),
    _Seed('Siviglia', 'Spagna', 'Europa', 690000, -800, Rarity.rara),
    _Seed('Cracovia', 'Polonia', 'Europa', 780000, 965, Rarity.rara),
    _Seed('San Pietroburgo', 'Russia', 'Europa', 5400000, 1703, Rarity.rara),
    _Seed('Mosca', 'Russia', 'Europa', 12600000, 1147, Rarity.rara),
    _Seed('Marsiglia', 'Francia', 'Europa', 870000, -600, Rarity.rara),
    _Seed('Porto', 'Portogallo', 'Europa', 240000, 300, Rarity.rara),
    _Seed('Dubrovnik', 'Croazia', 'Europa', 42000, 614, Rarity.rara),
    _Seed('Salisburgo', 'Austria', 'Europa', 155000, 696, Rarity.rara),
    _Seed('Hanoi', 'Vietnam', 'Asia', 8100000, 1010, Rarity.rara),
    _Seed('Luang Prabang', 'Laos', 'Asia', 56000, 1353, Rarity.rara),
    _Seed('Kathmandu', 'Nepal', 'Asia', 1500000, 167, Rarity.rara),
    _Seed('Samarcanda', 'Uzbekistan', 'Asia', 550000, -700, Rarity.rara),
    _Seed('Damasco', 'Siria', 'Asia', 2500000, -8000, Rarity.rara),
    _Seed('Fez', 'Marocco', 'Africa', 1200000, 789, Rarity.rara),
    _Seed('Zanzibar City', 'Tanzania', 'Africa', 600000, 1830, Rarity.rara),
    _Seed('Cusco', 'Perù', 'Sud America', 430000, 1100, Rarity.rara),
    _Seed('Cartagena', 'Colombia', 'Sud America', 1030000, 1533, Rarity.rara),
  ];

  // 87-95 — EPICA (9 carte): città-mito e siti che hanno definito civiltà.
  static const List<_Seed> _epica = [
    _Seed('Petra', 'Giordania', 'Asia', 0, -312, Rarity.epica,
        flavor: 'Scolpita nella roccia rosa del deserto, Petra appare solo a chi attraversa il canyon fino in fondo.'),
    _Seed('Machu Picchu', 'Perù', 'Sud America', 0, 1450, Rarity.epica,
        flavor: 'Sospesa tra le nuvole andine, la città perduta degli Inca non fu mai trovata dai conquistadores.'),
    _Seed('Angkor', 'Cambogia', 'Asia', 0, 802, Rarity.epica,
        flavor: 'Tra le radici della giungla, i templi di Angkor custodiscono il ricordo del più grande impero del Sud-Est asiatico.'),
    _Seed('Luxor', 'Egitto', 'Africa', 500000, -1400, Rarity.epica,
        flavor: 'Ogni pietra di Luxor porta inciso il nome di un faraone che credeva nell\'eternità.'),
    _Seed('Varanasi', 'India', 'Asia', 1200000, -1200, Rarity.epica,
        flavor: 'Sulle rive del Gange, Varanasi vive da millenni sul confine sottile tra la vita e ciò che viene dopo.'),
    _Seed('Timbuktu', 'Mali', 'Africa', 54000, 1100, Rarity.epica,
        flavor: 'Crocevia di carovane e di sapienti, Timbuktu fu per secoli la città dell\'oro e dei manoscritti.'),
    _Seed('Granada', 'Spagna', 'Europa', 230000, 1013, Rarity.epica,
        flavor: 'L\'Alhambra veglia su Granada come l\'ultimo sospiro di un regno che non volle dire addio.'),
    _Seed('Bagan', 'Myanmar', 'Asia', 0, 849, Rarity.epica,
        flavor: 'Migliaia di templi punteggiano la pianura di Bagan: all\'alba sembrano stelle cadute sulla terra.'),
    _Seed('Chichén Itzá', 'Messico', 'Nord America', 0, 600, Rarity.epica,
        flavor: 'La piramide di Kukulkán misura il tempo da oltre mille anni, un calendario scolpito nella pietra.'),
  ];

  // 96-99 — LEGGENDARIA (4 carte): le città-icona del mondo intero.
  static const List<_Seed> _leggendaria = [
    _Seed('Roma', 'Italia', 'Europa', 2870000, -753, Rarity.leggendaria,
        flavor: 'Caput Mundi. Ogni sua pietra ha visto nascere e cadere un impero, eppure è ancora qui, eterna.'),
    _Seed('Venezia', 'Italia', 'Europa', 258000, 421, Rarity.leggendaria,
        flavor: 'Costruita sull\'acqua per sfidare il tempo, Venezia galleggia tra specchi e nebbia come un sogno che non finisce.'),
    _Seed('Kyoto', 'Giappone', 'Asia', 1460000, 794, Rarity.leggendaria,
        flavor: 'Mille anni di imperatori e di silenzi tra i templi: Kyoto è l\'anima del Giappone scolpita nel legno e nel muschio.'),
    _Seed('Gerusalemme', 'Israele', 'Asia', 936000, -3000, Rarity.leggendaria,
        flavor: 'Tre fedi, una sola collina: Gerusalemme custodisce più storia di quanta le sue mura possano contenerne.'),
  ];

  // 100 — SEGRETA (1 carta): la leggenda definitiva. Foil animata.
  static const List<_Seed> _segreta = [
    _Seed('Atlantide', 'Sconosciuta', 'Oceano', 0, -9600, Rarity.segreta,
        flavor: 'Platone ne scrisse, il mare la nascose. Nessuno sa se Atlantide sia mai esistita — o se semplicemente attenda di essere ritrovata.'),
  ];

  static List<_Seed> get _seeds => [
        ..._comune,
        ..._nonComune,
        ..._rara,
        ..._epica,
        ..._leggendaria,
        ..._segreta,
      ];
}
