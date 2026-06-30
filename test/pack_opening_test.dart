import 'package:flutter_test/flutter_test.dart';
import 'package:urbis_tcg/screens/pack_opening_screen.dart';
import 'package:urbis_tcg/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('aprire una busta porta fino al riepilogo con 5 carte', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: const PackOpeningScreen()));
    await tester.pump();

    expect(find.text('Tocca la busta per aprirla'), findsOneWidget);

    await tester.tap(find.text('BUSTA URBIS'));

    // La sequenza shake -> burst -> reveal a cascata usa Future.delayed tra
    // un frame e l'altro: avanziamo l'orologio a piccoli passi finché non
    // compare il riepilogo, invece di affidarci a pumpAndSettle (che si
    // ferma appena non ci sono frame programmati, anche se un Future è
    // ancora in attesa).
    var summaryShown = false;
    for (var i = 0; i < 60 && !summaryShown; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      summaryShown = find.textContaining('nuove carte').evaluate().isNotEmpty ||
          find.text('Busta completata').evaluate().isNotEmpty;
    }

    expect(summaryShown, true);
    expect(find.text('Torna alla collezione'), findsOneWidget);
  });
}
