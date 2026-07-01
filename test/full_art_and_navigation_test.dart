import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbis_tcg/theme/app_theme.dart';
import 'package:urbis_tcg/screens/rarity_showcase_screen.dart';
import 'package:urbis_tcg/widgets/full_art_scenes.dart';

void main() {
  test('le 5 città più rare hanno una full art dedicata, le altre no', () {
    for (final city in ['Roma', 'Venezia', 'Kyoto', 'Gerusalemme', 'Atlantide']) {
      expect(fullArtPainterFor(city), isNotNull, reason: city);
    }
    expect(fullArtPainterFor('Tokyo'), isNull);
    expect(fullArtPainterFor('Milano'), isNull);
  });

  testWidgets('toccando una carta nella vetrina si apre il dettaglio con la carta grande', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark, home: const RarityShowcaseScreen()));
    await tester.pumpAndSettle();

    // La prima carta Comune del set è Tokyo: il nome è renderizzato dentro
    // la carta stessa, che è l'area effettivamente cliccabile.
    await tester.tap(find.text('Tokyo'));
    await tester.pumpAndSettle();

    expect(find.text('Trascina la carta per inclinarla'), findsOneWidget);
  });
}
