import 'dart:io';
import 'package:home_widget/home_widget.dart';
import '../l10n/app_localizations.dart';
import '../models/person.dart';
import '../utils/color_hex.dart';

/// Aggiorna il widget della schermata home di Android con un riassunto
/// della cerchia (fino a 3 persone con l'ultima posizione nota). Chiamato
/// da AppState dopo ogni refresh dei dati: se il widget non è stato
/// aggiunto alla home, non fa nulla di visibile e non costa nulla.
///
/// NOTA STORICA: una versione precedente di questa funzione (home_widget
/// ^0.7.0) causava un crash immediato dell'app all'avvio su Android,
/// isolato con un test binario (commit 99ecf30). La causa era quasi
/// certamente l'incompatibilità di quella versione con Android Gradle
/// Plugin 9.x usato da questo progetto: home_widget 0.9.2 ha aggiunto
/// esplicitamente il supporto ad AGP 9.x (vedi CHANGELOG upstream). Non è
/// stato possibile testare su un dispositivo Android reale da questo
/// ambiente di sviluppo: verificare con cautela prima di considerarla
/// definitivamente sicura.
class HomeWidgetService {
  HomeWidgetService._();
  static final instance = HomeWidgetService._();

  /// [l10n] arriva da lookupAppLocalizations(locale): questo servizio è
  /// chiamato da AppState, che non ha un BuildContext a disposizione.
  Future<void> update(List<Person> others, AppLocalizations l10n) async {
    if (!Platform.isAndroid) return;
    try {
      final visible = others.where((p) => p.isSharingWithMe).take(3).toList();

      await HomeWidget.saveWidgetData<String>('title', l10n.homeWidgetTitle);
      if (visible.isEmpty) {
        // Niente da mostrare ancora: invece di lasciarlo vuoto o con un
        // esempio scritto, il lato Android (vedi KinlyWidgetProvider)
        // disegna due righe puramente illustrative (pallino + barre
        // astratte al posto del testo) — la stessa illustrazione usata per
        // spiegare la funzione sul sito, capibile a colpo d'occhio senza
        // dover leggere un esempio.
        await HomeWidget.saveWidgetData<String>('isPreview', '1');
      } else {
        for (var i = 0; i < 3; i++) {
          final n = i + 1;
          if (i < visible.length) {
            final p = visible[i];
            await HomeWidget.saveWidgetData<String>('name$n', p.name);
            await HomeWidget.saveWidgetData<String>('sub$n', '${p.address.isEmpty ? '—' : p.address} · ${p.lastUpdateLabel(l10n)}');
            await HomeWidget.saveWidgetData<String>('id$n', p.id);
            await HomeWidget.saveWidgetData<String>('color$n', p.color.toHex());
          } else {
            await HomeWidget.saveWidgetData<String>('name$n', '');
          }
        }
        await HomeWidget.saveWidgetData<String>('isPreview', '0');
      }
      await HomeWidget.updateWidget(androidName: 'KinlyWidgetProvider');
    } catch (_) {
      // Il widget è solo un di più: mai bloccare il refresh dati per lui.
    }
  }
}
