import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:kinly/utils/generative_avatar.dart';

/// Test sulla logica pura dell'avatar generativo da seed: nessuna rete,
/// nessun dispositivo Android/iOS necessario. Verificano soprattutto il
/// determinismo (stesso seed => stesso risultato, sempre), che è la
/// proprietà su cui si basa l'intera funzione.
void main() {
  group('GenerativeAvatar key <-> seed', () {
    test('isGenerativeKey riconosce solo le chiavi con il prefisso giusto', () {
      expect(GenerativeAvatar.isGenerativeKey('gen:abc123'), isTrue);
      expect(GenerativeAvatar.isGenerativeKey('fox'), isFalse);
      expect(GenerativeAvatar.isGenerativeKey(null), isFalse);
    });

    test('keyFromSeed e seedFromKey fanno il percorso di andata e ritorno', () {
      const seed = 'ab12cd34ef';
      final key = GenerativeAvatar.keyFromSeed(seed);
      expect(key, 'gen:$seed');
      expect(GenerativeAvatar.seedFromKey(key), seed);
    });

    test('newRandomSeed genera stringhe non vuote e (quasi sempre) diverse', () {
      final a = GenerativeAvatar.newRandomSeed();
      final b = GenerativeAvatar.newRandomSeed();
      expect(a, isNotEmpty);
      expect(b, isNotEmpty);
      expect(a, isNot(equals(b)));
    });
  });

  group('GenerativeAvatar determinismo', () {
    test('lo stesso seed produce sempre lo stesso colore', () {
      final colorA = GenerativeAvatar.accentColor('stesso-seed');
      final colorB = GenerativeAvatar.accentColor('stesso-seed');
      expect(colorA, colorB);
    });

    test('seed diversi tendono a produrre colori diversi', () {
      final colorA = GenerativeAvatar.accentColor('seed-uno');
      final colorB = GenerativeAvatar.accentColor('seed-due');
      expect(colorA, isNot(equals(colorB)));
    });

    test('paint disegna senza errori per un seed qualunque', () async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      GenerativeAvatar.paint(canvas, const ui.Rect.fromLTWH(0, 0, 72, 72), 'un-seed-qualsiasi');
      final picture = recorder.endRecording();
      final image = await picture.toImage(72, 72);
      expect(image.width, 72);
      expect(image.height, 72);
    });
  });
}
