import 'dart:io';
import 'package:home_widget/home_widget.dart';
import '../l10n/app_localizations.dart';
import '../models/circle_group.dart';
import '../models/person.dart';
import '../utils/color_hex.dart';

/// Aggiorna il widget della schermata home di Android con un riassunto
/// di una cerchia alla volta (fino a 3 persone con l'ultima posizione
/// nota). Chiamato da AppState dopo ogni refresh dei dati: se il widget
/// non è stato aggiunto alla home, non fa nulla di visibile e non costa
/// nulla.
///
/// Se l'utente ha più di una cerchia, i dati di TUTTE vengono salvati (una
/// sotto l'altra, con chiavi prefissate "c0_", "c1_"...): è il lato Android
/// (KinlyWidgetProvider) a decidere quale mostrare in base all'indice
/// scelto dall'utente scorrendo con le frecce, e a ridisegnare subito senza
/// dover riaprire l'app o aspettare il prossimo refresh dati.
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
  ///
  /// Widget Kinly+: chi non è abbonato vede solo un invito a sbloccarlo
  /// (nessun nome o posizione reale scritto nei dati del widget), non i
  /// dati reali della cerchia.
  Future<void> update(List<Person> others, List<CircleGroup> circles, AppLocalizations l10n, {required bool isPremium}) async {
    if (!Platform.isAndroid) return;
    try {
      await HomeWidget.saveWidgetData<String>('title', l10n.homeWidgetTitle);
      if (!isPremium) {
        await HomeWidget.saveWidgetData<String>('locked', '1');
        await HomeWidget.saveWidgetData<String>('lockedTitle', l10n.homeWidgetLockedTitle);
        await HomeWidget.saveWidgetData<String>('lockedSubtitle', l10n.homeWidgetLockedSubtitle);
        await HomeWidget.updateWidget(androidName: 'KinlyWidgetProvider');
        return;
      }
      await HomeWidget.saveWidgetData<String>('locked', '0');
      await HomeWidget.saveWidgetData<String>('circleCount', '${circles.length}');

      for (var c = 0; c < circles.length; c++) {
        final circle = circles[c];
        final prefix = 'c${c}_';
        await HomeWidget.saveWidgetData<String>('circleName$c', circle.name);

        final visible = others.where((p) => p.isSharingWithMe && circle.memberIds.contains(p.id)).take(3).toList();
        if (visible.isEmpty) {
          // Niente da mostrare ancora in questa cerchia: invece di
          // lasciarla vuota o con un esempio scritto, il lato Android
          // (vedi KinlyWidgetProvider) disegna due righe puramente
          // illustrative (pallino + barre astratte al posto del testo) —
          // la stessa illustrazione usata per spiegare la funzione sul
          // sito, capibile a colpo d'occhio senza dover leggere un esempio.
          await HomeWidget.saveWidgetData<String>('${prefix}isPreview', '1');
          continue;
        }
        await HomeWidget.saveWidgetData<String>('${prefix}isPreview', '0');
        for (var i = 0; i < 3; i++) {
          final n = i + 1;
          if (i < visible.length) {
            final p = visible[i];
            await HomeWidget.saveWidgetData<String>('${prefix}name$n', p.name);
            await HomeWidget.saveWidgetData<String>(
              '${prefix}sub$n',
              '${p.address.isEmpty ? '—' : p.address} · ${p.lastUpdateLabel(l10n)}',
            );
            await HomeWidget.saveWidgetData<String>('${prefix}id$n', p.id);
            await HomeWidget.saveWidgetData<String>('${prefix}color$n', p.color.toHex());
          } else {
            await HomeWidget.saveWidgetData<String>('${prefix}name$n', '');
          }
        }
      }
      await HomeWidget.updateWidget(androidName: 'KinlyWidgetProvider');
    } catch (_) {
      // Il widget è solo un di più: mai bloccare il refresh dati per lui.
    }
  }
}
