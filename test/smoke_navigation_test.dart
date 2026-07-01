import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cerchia/main.dart';
import 'package:cerchia/state/app_state.dart';

/// Attraversa tutte le schermate principali per scovare errori di layout
/// (overflow, vincoli infiniti...) che i test più mirati non toccano.
void main() {
  testWidgets('si può navigare in tutte le tab principali senza errori', (tester) async {
    AppState.instance.logOut();
    await tester.pumpWidget(const CerchiaApp());
    await tester.pump();

    await tester.tap(find.text('Ho un codice di invito'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'FAM-7Q2K');
    await tester.tap(find.text('Entra'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);

    // Apro il dettaglio della prima persona in elenco (Mamma, che condivide).
    await tester.tap(find.text('Mamma'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pump();

    for (final tab in ['Cerchie', 'Richieste', 'Profilo', 'Mappa']) {
      await tester.tap(find.text(tab));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: 'tab $tab');
    }
  });
}
