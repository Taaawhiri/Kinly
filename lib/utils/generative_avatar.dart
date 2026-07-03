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

  static const List<Color> _skinTones = [
    Color(0xFFFFDBB4),
    Color(0xFFF1C27D),
    Color(0xFFE0AC69),
    Color(0xFFC68642),
    Color(0xFF8D5524),
    Color(0xFF5C3A21),
  ];

  static const List<Color> _hairColors = [
    Color(0xFF2B2118),
    Color(0xFF5A3D2B),
    Color(0xFF8A5A34),
    Color(0xFFB5651D),
    Color(0xFFE8B923),
    Color(0xFFECECEC),
    Color(0xFFC1493D),
  ];

  static Random _sub(String seed, String salt) => Random(_hashSeed('$seed#$salt'));

  /// Disegna un volto cartoon semplice dentro [rect] su [canvas]: usato
  /// sia dal widget [GenerativeAvatarPreview] sia dal renderer dei pin
  /// della mappa live, così il risultato è identico ovunque venga
  /// mostrato. Non ritaglia da solo: sta a chi chiama decidere se e come
  /// ritagliare (un widget può già vivere dentro un contenitore
  /// circolare, un canvas della mappa no). Ogni tratto (pelle, capelli,
  /// occhi, bocca, accessori) è scelto da una porzione diversa del seed,
  /// così un piccolo elenco di varianti per tratto produce comunque
  /// moltissime combinazioni uniche.
  static void paint(Canvas canvas, Rect rect, String seed) {
    final bgPalette = _paletteFor(seed);
    canvas.drawRect(rect, Paint()..shader = LinearGradient(colors: bgPalette, begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(rect));

    final s = rect.shortestSide;
    final faceCenter = rect.center + Offset(0, s * 0.05);
    final faceRadius = s * 0.335;

    final skin = _skinTones[_sub(seed, 'skin').nextInt(_skinTones.length)];
    final hair = _hairColors[_sub(seed, 'hair').nextInt(_hairColors.length)];
    final hairStyle = _sub(seed, 'hairstyle').nextInt(5);
    final mouthStyle = _sub(seed, 'mouth').nextInt(3);
    final hasGlasses = _sub(seed, 'glasses').nextDouble() < 0.28;
    final hasBlush = _sub(seed, 'blush').nextDouble() < 0.55;

    _paintHairBack(canvas, faceCenter, faceRadius, hair, hairStyle);
    canvas.drawCircle(faceCenter, faceRadius, Paint()..color = skin);
    if (hasBlush) _paintBlush(canvas, faceCenter, faceRadius);
    _paintEyes(canvas, faceCenter, faceRadius);
    _paintEyebrows(canvas, faceCenter, faceRadius, hair);
    _paintMouth(canvas, faceCenter, faceRadius, mouthStyle);

    // La frangia non deve mai poter coprire occhi o bocca, qualunque sia
    // la forma scelta per lo stile: si ritaglia sempre a un'area sopra le
    // sopracciglia, indipendentemente dalla geometria esatta del tratto.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(
      faceCenter.dx - faceRadius * 1.4,
      faceCenter.dy - faceRadius * 1.4,
      faceCenter.dx + faceRadius * 1.4,
      faceCenter.dy - faceRadius * 0.22,
    ));
    _paintHairFront(canvas, faceCenter, faceRadius, hair, hairStyle);
    canvas.restore();

    if (hasGlasses) _paintGlasses(canvas, faceCenter, faceRadius);
  }

  static void _paintEyes(Canvas canvas, Offset faceCenter, double r) {
    final eyeY = faceCenter.dy - r * 0.05;
    final eyeDx = r * 0.4;
    final eyePaint = Paint()..color = const Color(0xFF2B2118);
    canvas.drawCircle(Offset(faceCenter.dx - eyeDx, eyeY), r * 0.1, eyePaint);
    canvas.drawCircle(Offset(faceCenter.dx + eyeDx, eyeY), r * 0.1, eyePaint);
  }

  static void _paintEyebrows(Canvas canvas, Offset faceCenter, double r, Color hair) {
    final browY = faceCenter.dy - r * 0.34;
    final browDx = r * 0.4;
    final paint = Paint()
      ..color = hair
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(faceCenter.dx - browDx - r * 0.16, browY + r * 0.03), Offset(faceCenter.dx - browDx + r * 0.16, browY - r * 0.03), paint);
    canvas.drawLine(Offset(faceCenter.dx + browDx - r * 0.16, browY - r * 0.03), Offset(faceCenter.dx + browDx + r * 0.16, browY + r * 0.03), paint);
  }

  static void _paintBlush(Canvas canvas, Offset faceCenter, double r) {
    final paint = Paint()..color = const Color(0xFFFF8A80).withOpacity(0.4);
    canvas.drawCircle(Offset(faceCenter.dx - r * 0.62, faceCenter.dy + r * 0.22), r * 0.16, paint);
    canvas.drawCircle(Offset(faceCenter.dx + r * 0.62, faceCenter.dy + r * 0.22), r * 0.16, paint);
  }

  static void _paintMouth(Canvas canvas, Offset faceCenter, double r, int style) {
    final mouthCenter = Offset(faceCenter.dx, faceCenter.dy + r * 0.42);
    final paint = Paint()
      ..color = const Color(0xFF8A3B32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.08
      ..strokeCap = StrokeCap.round;
    switch (style) {
      case 0: // sorriso
        final path = Path()
          ..moveTo(mouthCenter.dx - r * 0.26, mouthCenter.dy)
          ..quadraticBezierTo(mouthCenter.dx, mouthCenter.dy + r * 0.26, mouthCenter.dx + r * 0.26, mouthCenter.dy);
        canvas.drawPath(path, paint);
        break;
      case 1: // sorriso aperto, con un accenno di denti
        final fillPaint = Paint()..color = const Color(0xFF8A3B32);
        final path = Path()
          ..moveTo(mouthCenter.dx - r * 0.24, mouthCenter.dy - r * 0.02)
          ..quadraticBezierTo(mouthCenter.dx, mouthCenter.dy + r * 0.3, mouthCenter.dx + r * 0.24, mouthCenter.dy - r * 0.02)
          ..quadraticBezierTo(mouthCenter.dx, mouthCenter.dy + r * 0.1, mouthCenter.dx - r * 0.24, mouthCenter.dy - r * 0.02)
          ..close();
        canvas.drawPath(path, fillPaint);
        break;
      default: // neutro
        canvas.drawLine(Offset(mouthCenter.dx - r * 0.2, mouthCenter.dy), Offset(mouthCenter.dx + r * 0.2, mouthCenter.dy), paint);
    }
  }

  static void _paintGlasses(Canvas canvas, Offset faceCenter, double r) {
    final eyeY = faceCenter.dy - r * 0.05;
    final eyeDx = r * 0.4;
    final paint = Paint()
      ..color = const Color(0xFF2B2118)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.05;
    final lensRadius = r * 0.2;
    canvas.drawCircle(Offset(faceCenter.dx - eyeDx, eyeY), lensRadius, paint);
    canvas.drawCircle(Offset(faceCenter.dx + eyeDx, eyeY), lensRadius, paint);
    canvas.drawLine(Offset(faceCenter.dx - eyeDx + lensRadius, eyeY), Offset(faceCenter.dx + eyeDx - lensRadius, eyeY), paint);
  }

  /// Il volume dei capelli dietro il viso (visibile solo ai lati/in alto,
  /// il resto è coperto dal cerchio della pelle disegnato sopra).
  static void _paintHairBack(Canvas canvas, Offset faceCenter, double r, Color hair, int style) {
    final paint = Paint()..color = hair;
    switch (style) {
      case 0: // caschetto
        canvas.drawCircle(faceCenter + Offset(0, -r * 0.06), r * 1.1, paint);
        break;
      case 1: // riccioli/afro
        canvas.drawCircle(faceCenter + Offset(0, -r * 0.1), r * 1.32, paint);
        break;
      case 2: // scriminatura laterale
        canvas.drawOval(Rect.fromCenter(center: faceCenter + Offset(-r * 0.1, -r * 0.08), width: r * 2.3, height: r * 2.15), paint);
        break;
      case 3: // raccolto alto
        canvas.drawCircle(faceCenter + Offset(0, -r * 0.05), r * 1.05, paint);
        canvas.drawCircle(faceCenter + Offset(0, -r * 1.25), r * 0.42, paint);
        break;
      default: // rasati/calvo: nessun volume dietro
        break;
    }
  }

  /// La frangia/attaccatura sopra la fronte, disegnata dopo il viso così
  /// resta sempre visibile anche quando il volume dietro è piccolo.
  static void _paintHairFront(Canvas canvas, Offset faceCenter, double r, Color hair, int style) {
    final paint = Paint()..color = hair;
    switch (style) {
      case 0: // caschetto: banda piena sulla fronte
        final path = Path()
          ..moveTo(faceCenter.dx - r * 1.02, faceCenter.dy - r * 0.28)
          ..arcTo(Rect.fromCircle(center: faceCenter, radius: r * 1.02), pi * 1.08, -pi * 1.16, false)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 1: // riccioli: qualche ciuffo tondo sul bordo del viso
        for (final angle in [-0.9, -0.45, 0.0, 0.45, 0.9]) {
          final offset = faceCenter + Offset(sin(angle) * r * 1.05, -cos(angle) * r * 1.05);
          canvas.drawCircle(offset, r * 0.26, paint);
        }
        break;
      case 2: // scriminatura laterale: ciuffo asimmetrico
        final path = Path()
          ..moveTo(faceCenter.dx - r * 1.05, faceCenter.dy - r * 0.15)
          ..quadraticBezierTo(faceCenter.dx - r * 0.2, faceCenter.dy - r * 1.05, faceCenter.dx + r * 0.75, faceCenter.dy - r * 0.55)
          ..quadraticBezierTo(faceCenter.dx + r * 0.15, faceCenter.dy - r * 0.7, faceCenter.dx - r * 0.75, faceCenter.dy - r * 0.2)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 3: // raccolto alto: piccola frangetta corta
        final path = Path()
          ..moveTo(faceCenter.dx - r * 0.8, faceCenter.dy - r * 0.42)
          ..arcTo(Rect.fromCircle(center: faceCenter, radius: r * 0.95), pi * 1.18, -pi * 0.72, false)
          ..close();
        canvas.drawPath(path, paint);
        break;
      default: // rasati/calvo: nessuna frangia
        break;
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
