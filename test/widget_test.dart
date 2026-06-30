import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:urbis_tcg/main.dart';

void main() {
  testWidgets('URBIS app avvia e mostra la home della collezione', (WidgetTester tester) async {
    await tester.pumpWidget(const UrbisApp());
    await tester.pump();

    expect(find.text('URBIS'), findsOneWidget);
    expect(find.text('Collezione'), findsOneWidget);
    expect(find.text('Rarità'), findsOneWidget);
  });

  testWidgets('La vetrina mostra una carta per ogni rarità', (WidgetTester tester) async {
    await tester.pumpWidget(const UrbisApp());
    await tester.pump();

    await tester.tap(find.text('Rarità'));
    await tester.pumpAndSettle();

    expect(find.text('Le Rarità'), findsOneWidget);
    expect(find.text('Comune'), findsWidgets);

    final scrollable = find.byType(CustomScrollView).last;
    for (var i = 0; i < 6 && find.text('Segreta').evaluate().isEmpty; i++) {
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Segreta'), findsWidgets);
  });
}
