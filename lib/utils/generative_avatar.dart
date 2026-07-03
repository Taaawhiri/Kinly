import 'dart:math';
import 'package:flutter/material.dart';

/// Avatar generato automaticamente da un seed testuale: un motivo unico e
/// deterministico (stesso seed => sempre lo stesso disegno), calcolato
/// interamente sul dispositivo e senza alcuna chiamata di rete — a
/// differenza di librerie come DiceBear, che generano l'immagine lato
/// server a partire da un seed. Il seed viene salvato al posto della
/// solita chiave dell'[AvatarOption] (colonna avatar_key già esistente,
/// vedi AvatarCatalog), con il prefisso [keyPrefix] per riconoscerlo.
class GenerativeAvatar {
  GenerativeAvatar._();

  static const String keyPrefix = 'gen:';

  static bool isGenerativeKey(String? key) => key != null && key.startsWith(keyPrefix);

  static String seedFromKey(String key) => key.substring(keyPrefix.length);

  static String keyFromSeed(String seed) => '$keyPrefix$seed';

  static String newRandomSeed() {
    final random = Random();
    return List.generate(10, (_) => random.nextInt(36).toRadixString(36)).join();
  }

  static const List<List<Color>> _palettes = [
    [Color(0xFFFF9A56), Color(0xFFFF6B35)],
    [Color(0xFFB388EB), Color(0xFF8C6FD1)],
    [Color(0xFF5CC8D7), Color(0xFF3A9CAB)],
    [Color(0xFF7BC08A), Color(0xFF4E9C60)],
    [Color(0xFFFF9EC4), Color(0xFFE87DA6)],
    [Color(0xFFFFC857), Color(0xFFE8A73B)],
    [Color(0xFF6E7F9E), Color(0xFF4A5A79)],
    [Color(0xFFE38FC0), Color(0xFFC1579A)],
  ];

  static int _hashSeed(String seed) {
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = 0x1fffffff & (hash + unit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    return hash;
  }

  static List<Color> _paletteFor(String seed) {
    final random = Random(_hashSeed(seed));
    return _palettes[random.nextInt(_palettes.length)];
  }

  /// Colore da usare per bordi/ombre coerenti col resto dell'app (vedi
  /// come [AvatarOption.colors.last] viene usato altrove).
  static Color accentColor(String seed) => _paletteFor(seed).last;

  /// Disegna l'avatar dentro [rect] su [canvas]: usato sia dal widget
  /// [GenerativeAvatarPreview] sia dal renderer dei pin della mappa live,
  /// così il risultato è identico ovunque venga mostrato. Non ritaglia da
  /// solo: sta a chi chiama decidere se e come ritagliare (un widget può
  /// già vivere dentro un contenitore circolare, un canvas della mappa no).
  static void paint(Canvas canvas, Rect rect, String seed) {
    // Il seed guida sia i colori che le forme: stesso seed, stesso identico
    // disegno, per sempre — così l'utente lo riconosce come "il suo".
    final shapeRandom = Random(_hashSeed('$seed#shapes'));
    final palette = _paletteFor(seed);

    canvas.drawRect(rect, Paint()..shader = LinearGradient(colors: palette, begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(rect));

    final center = rect.center;
    final radius = rect.shortestSide / 2;
    final shapeCount = 4 + shapeRandom.nextInt(3);
    for (var i = 0; i < shapeCount; i++) {
      final angle = shapeRandom.nextDouble() * 2 * pi;
      final distanceFactor = 0.12 + shapeRandom.nextDouble() * 0.5;
      final offset = center + Offset(cos(angle), sin(angle)) * radius * distanceFactor;
      final shapeSize = radius * (0.14 + shapeRandom.nextDouble() * 0.18);
      final isLight = shapeRandom.nextBool();
      final paint = Paint()..color = isLight ? Colors.white.withOpacity(0.32) : palette.last.withOpacity(0.5);
      switch (shapeRandom.nextInt(3)) {
        case 0:
          canvas.drawCircle(offset, shapeSize, paint);
          break;
        case 1:
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: offset, width: shapeSize * 1.7, height: shapeSize * 1.7), Radius.circular(shapeSize * 0.4)),
            paint,
          );
          break;
        default:
          final path = Path()
            ..moveTo(offset.dx, offset.dy - shapeSize)
            ..lineTo(offset.dx + shapeSize, offset.dy + shapeSize)
            ..lineTo(offset.dx - shapeSize, offset.dy + shapeSize)
            ..close();
          canvas.drawPath(path, paint);
      }
    }
  }
}

/// Anteprima circolare di un avatar generativo, pronta per essere usata da
/// sola (es. nel selettore avatar) o dentro un altro contenitore già
/// circolare (es. [PersonAvatar]): si ritaglia sempre da sola, quindi il
/// doppio ritaglio in quest'ultimo caso non fa danni.
class GenerativeAvatarPreview extends StatelessWidget {
  const GenerativeAvatarPreview({super.key, required this.seed, this.size = 56});

  final String seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _GenerativeAvatarPainter(seed)),
      ),
    );
  }
}

class _GenerativeAvatarPainter extends CustomPainter {
  _GenerativeAvatarPainter(this.seed);
  final String seed;

  @override
  void paint(Canvas canvas, Size size) {
    GenerativeAvatar.paint(canvas, Offset.zero & size, seed);
  }

  @override
  bool shouldRepaint(covariant _GenerativeAvatarPainter oldDelegate) => oldDelegate.seed != seed;
}
