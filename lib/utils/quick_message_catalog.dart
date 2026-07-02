import '../l10n/app_localizations.dart';

/// Messaggi rapidi pronti per i "Messaggi cerchia": incoraggiano un uso
/// breve e frequente senza dover scrivere, mantenendo il canale limitato a
/// avvisi (non una chat).
class QuickMessageCatalog {
  QuickMessageCatalog._();

  static List<String> options(AppLocalizations l10n) => [
        l10n.quickMessage1,
        l10n.quickMessage2,
        l10n.quickMessage3,
        l10n.quickMessage4,
        l10n.quickMessage5,
        l10n.quickMessage6,
        l10n.quickMessage7,
        l10n.quickMessage8,
      ];
}
