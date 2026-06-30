# URBIS — TCG delle Città del Mondo

Mockup Flutter di un trading card game digitale: una collezione di 100
carte, una per ogni città del mondo, divise in sei rarità crescenti.

## Rarità del set

| Rarità       | Carte nel set | Drop rate | Stile carta                          |
|--------------|---------------|-----------|---------------------------------------|
| Comune       | 40            | 55%       | Bordo argento, palette neutra         |
| Non Comune   | 28            | 27%       | Bordo verde                           |
| Rara         | 18            | 12%       | Bordo blu + riflesso statico          |
| Epica        | 9             | 4.5%      | Bordo viola + bagliore                |
| Leggendaria  | 4             | 1.2%      | Bordo oro, cornice più ampia          |
| Segreta      | 1             | 0.3%      | **Foil olografica animata** (Atlantide) |

## Struttura del progetto

```
lib/
  models/      Rarity (metadati/colori) e CityCard
  data/        Dataset statico delle 100 città
  theme/       Tema scuro dell'app
  widgets/     CityCardWidget, FoilOverlay (animazione foil), SkylinePainter
  screens/     Home/Collezione, Vetrina Rarità, Dettaglio carta
```

## Avvio

```
flutter pub get
flutter run -d chrome   # o un device/emulatore a scelta
```
