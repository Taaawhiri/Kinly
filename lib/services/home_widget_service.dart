import 'dart:io';
import 'package:home_widget/home_widget.dart';
import '../models/person.dart';

/// Aggiorna il widget della schermata home di Android con un riassunto
/// della cerchia (fino a 3 persone con l'ultima posizione nota). Chiamato
/// da AppState dopo ogni refresh dei dati: se il widget non è stato
/// aggiunto alla home, non fa nulla di visibile e non costa nulla.
class HomeWidgetService {
  HomeWidgetService._();
  static final instance = HomeWidgetService._();

  Future<void> update(List<Person> others) async {
    if (!Platform.isAndroid) return;
    try {
      final visible = others.where((p) => p.isSharingWithMe).take(3).toList();
      String lineFor(int i) {
        if (i >= visible.length) return '';
        final p = visible[i];
        return '${p.name} · ${p.address.isEmpty ? '—' : p.address} (${p.lastUpdateLabel})';
      }

      await HomeWidget.saveWidgetData<String>('title', 'La tua cerchia');
      await HomeWidget.saveWidgetData<String>('line1', visible.isEmpty ? 'Nessuno sta condividendo ora' : lineFor(0));
      await HomeWidget.saveWidgetData<String>('line2', lineFor(1));
      await HomeWidget.saveWidgetData<String>('line3', lineFor(2));
      await HomeWidget.updateWidget(androidName: 'KinlyWidgetProvider');
    } catch (_) {
      // Il widget è solo un di più: mai bloccare il refresh dati per lui.
    }
  }
}
