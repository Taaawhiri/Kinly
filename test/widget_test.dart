import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cerchia/main.dart';
import 'package:cerchia/state/app_state.dart';

void main() {
  testWidgets('primo avvio mostra la schermata di benvenuto', (tester) async {
    AppState.instance.logOut();
    await tester.pumpWidget(const CerchiaApp());
    await tester.pump();

    expect(find.text('Cerchia'), findsOneWidget);
    expect(find.text('Crea la tua cerchia'), findsOneWidget);
    expect(find.text('Ho un codice di invito'), findsOneWidget);
  });

  testWidgets('un codice di invito valido apre la mappa della cerchia', (tester) async {
    AppState.instance.logOut();
    await tester.pumpWidget(const CerchiaApp());
    await tester.pump();

    await tester.tap(find.text('Ho un codice di invito'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'FAM-7Q2K');
    await tester.tap(find.text('Entra'));
    // La mappa ha pin con un'animazione che si ripete all'infinito, quindi
    // pumpAndSettle non si fermerebbe mai: avanziamo di pochi frame fissi.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('La tua cerchia'), findsOneWidget);
    expect(AppState.instance.hasOnboarded, true);
  });

  testWidgets('un codice di invito inventato mostra un errore', (tester) async {
    AppState.instance.logOut();
    await tester.pumpWidget(const CerchiaApp());
    await tester.pump();

    await tester.tap(find.text('Ho un codice di invito'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'NON-ESISTE');
    await tester.tap(find.text('Entra'));
    await tester.pump();

    expect(find.textContaining('Codice non valido'), findsOneWidget);
  });
}
