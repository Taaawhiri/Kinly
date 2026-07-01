import 'dart:math';
import 'package:flutter/material.dart';

/// Illustrazioni "full art" dedicate, disegnate a mano (vettoriali, via
/// Canvas) per le carte più rare del set: le quattro Leggendarie e la
/// Segreta. A differenza delle altre 95 carte — che condividono uno
/// skyline procedurale — queste cinque hanno una scena unica pensata per
/// la propria città, in stile "full art" come le carte più pregiate dei
/// giochi di carte da collezione fisici.
CustomPainter? fullArtPainterFor(String city) {
  switch (city) {
    case 'Roma':
      return const _RomaScene();
    case 'Venezia':
      return const _VeneziaScene();
    case 'Kyoto':
      return const _KyotoScene();
    case 'Gerusalemme':
      return const _GerusalemmeScene();
    case 'Atlantide':
      return const _AtlantideScene();
    default:
      return null;
  }
}

void _sky(Canvas canvas, Size size, List<Color> colors, List<double>? stops) {
  final rect = Offset.zero & size;
  final paint = Paint()
    ..shader = LinearGradient(
      colors: colors,
      stops: stops,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(rect);
  canvas.drawRect(rect, paint);
}

void _glowCircle(Canvas canvas, Offset center, double radius, Color color) {
  final glow = Paint()
    ..color = color.withOpacity(0.55)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.6);
  canvas.drawCircle(center, radius * 1.4, glow);
  canvas.drawCircle(center, radius, Paint()..color = color);
}

void _stars(Canvas canvas, Size size, int seed, int count, {double top = 0.55}) {
  final rng = Random(seed);
  final paint = Paint()..color = Colors.white;
  for (var i = 0; i < count; i++) {
    final p = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height * top);
    final r = 0.6 + rng.nextDouble() * 1.1;
    canvas.drawCircle(p, r, paint..color = Colors.white.withOpacity(0.4 + rng.nextDouble() * 0.5));
  }
}

class _RomaScene extends CustomPainter {
  const _RomaScene();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _sky(canvas, size, const [Color(0xFF3B1F0E), Color(0xFFB5541E), Color(0xFFF3A94E)], const [0, 0.55, 1]);

    _glowCircle(canvas, Offset(w * 0.78, h * 0.28), w * 0.14, const Color(0xFFFFE1A6));

    // Uccelli in volo.
    final birdPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (final p in [Offset(w * 0.2, h * 0.18), Offset(w * 0.3, h * 0.13), Offset(w * 0.14, h * 0.24)]) {
      final path = Path()
        ..moveTo(p.dx - 6, p.dy)
        ..quadraticBezierTo(p.dx - 2, p.dy - 4, p.dx, p.dy)
        ..quadraticBezierTo(p.dx + 2, p.dy - 4, p.dx + 6, p.dy);
      canvas.drawPath(path, birdPaint);
    }

    final groundY = h * 0.86;
    final stone = Paint()..color = const Color(0xFF201007);

    // Colosseo: anello ellittico con due ordini di arcate.
    final arenaRect = Rect.fromCenter(center: Offset(w * 0.5, groundY - h * 0.02), width: w * 0.98, height: h * 0.4);
    canvas.drawRRect(RRect.fromRectAndRadius(arenaRect, Radius.circular(w * 0.05)), stone);

    final archPaint = Paint()..color = const Color(0xFF3B1F0E);
    const rows = 2;
    const archesPerRow = 11;
    for (var row = 0; row < rows; row++) {
      final rowTop = arenaRect.top + h * 0.045 + row * (h * 0.135);
      final rowHeight = h * 0.1;
      final archWidth = arenaRect.width / archesPerRow;
      for (var i = 0; i < archesPerRow; i++) {
        final left = arenaRect.left + i * archWidth + archWidth * 0.22;
        final archRect = Rect.fromLTWH(left, rowTop, archWidth * 0.56, rowHeight);
        canvas.drawRRect(
          RRect.fromRectAndCorners(archRect, topLeft: const Radius.circular(6), topRight: const Radius.circular(6)),
          archPaint,
        );
      }
    }
    // Cornicione superiore.
    canvas.drawRect(Rect.fromLTWH(arenaRect.left, arenaRect.top - h * 0.012, arenaRect.width, h * 0.018), stone);

    // Cipressi ai lati.
    final cypress = Paint()..color = const Color(0xFF1B2914);
    for (final dx in [-0.46, 0.46]) {
      final cx = w * 0.5 + w * dx;
      final path = Path()
        ..moveTo(cx, groundY)
        ..lineTo(cx - w * 0.02, groundY - h * 0.05)
        ..quadraticBezierTo(cx, groundY - h * 0.32, cx + w * 0.02, groundY - h * 0.05)
        ..close();
      canvas.drawPath(path, cypress);
    }

    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY), Paint()..color = const Color(0xFF140A05));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VeneziaScene extends CustomPainter {
  const _VeneziaScene();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _sky(canvas, size, const [Color(0xFF0B1A3A), Color(0xFF1E3A6E), Color(0xFF3E6B94)], const [0, 0.6, 1]);
    _stars(canvas, size, 42, 40, top: 0.4);
    _glowCircle(canvas, Offset(w * 0.24, h * 0.2), w * 0.09, const Color(0xFFEFEFD8));

    final waterTop = h * 0.62;

    // Palazzi lungo il canale.
    final rng = Random(7);
    final buildingPaint = Paint()..color = const Color(0xFF0E1B33);
    final windowPaint = Paint()..color = const Color(0xFFF4C97A).withOpacity(0.85);
    double x = 0;
    while (x < w) {
      final bw = w * (0.08 + rng.nextDouble() * 0.07);
      final bh = h * (0.16 + rng.nextDouble() * 0.16);
      final rect = Rect.fromLTWH(x, waterTop - bh, bw, bh);
      canvas.drawRect(rect, buildingPaint);
      if (rng.nextDouble() > 0.5) {
        canvas.drawRect(Rect.fromLTWH(rect.left + bw * 0.3, rect.top - h * 0.02, bw * 0.4, h * 0.02), buildingPaint);
      }
      for (var i = 0; i < 3; i++) {
        if (rng.nextDouble() < 0.4) continue;
        canvas.drawRect(Rect.fromLTWH(rect.left + bw * 0.2 + i * bw * 0.25, rect.top + bh * 0.3, bw * 0.12, bh * 0.16), windowPaint);
      }
      x += bw * 0.85;
    }

    // Ponte ad arco.
    final bridgePaint = Paint()
      ..color = const Color(0xFF0E1B33)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.03;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.78, waterTop + h * 0.02), width: w * 0.34, height: h * 0.16),
      pi,
      pi,
      false,
      bridgePaint,
    );

    // Acqua + riflesso della luna.
    final waterPaint = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF16305C), Color(0xFF0A1830)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
          .createShader(Rect.fromLTWH(0, waterTop, w, h - waterTop));
    canvas.drawRect(Rect.fromLTWH(0, waterTop, w, h - waterTop), waterPaint);

    final reflection = Paint()..color = const Color(0xFFEFEFD8).withOpacity(0.25);
    for (var i = 0; i < 5; i++) {
      final ry = waterTop + h * 0.03 + i * h * 0.03;
      canvas.drawRect(Rect.fromLTWH(w * 0.24 - (10 - i * 1.4), ry, 20 - i * 2.0, h * 0.012), reflection);
    }

    // Gondola con gondoliere.
    final gondolaPaint = Paint()..color = const Color(0xFF0A0A0A);
    final gy = h * 0.86;
    final gondola = Path()
      ..moveTo(w * 0.42, gy)
      ..quadraticBezierTo(w * 0.46, gy + h * 0.02, w * 0.62, gy)
      ..quadraticBezierTo(w * 0.66, gy - h * 0.01, w * 0.68, gy - h * 0.035)
      ..quadraticBezierTo(w * 0.6, gy - h * 0.01, w * 0.42, gy)
      ..close();
    canvas.drawPath(gondola, gondolaPaint);
    canvas.drawLine(Offset(w * 0.5, gy - h * 0.03), Offset(w * 0.5, gy - h * 0.11), gondolaPaint..strokeWidth = 2);
    canvas.drawCircle(Offset(w * 0.5, gy - h * 0.13), h * 0.014, gondolaPaint);
    canvas.drawLine(Offset(w * 0.5, gy - h * 0.1), Offset(w * 0.44, gy - h * 0.07), gondolaPaint..strokeWidth = 1.6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KyotoScene extends CustomPainter {
  const _KyotoScene();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _sky(canvas, size, const [Color(0xFF7A3B57), Color(0xFFD97D6C), Color(0xFFF7C978)], const [0, 0.55, 1]);
    _glowCircle(canvas, Offset(w * 0.72, h * 0.32), w * 0.13, const Color(0xFFFFE7B0));

    // Montagne sullo sfondo.
    final mountain = Paint()..color = const Color(0xFF5C4F63).withOpacity(0.65);
    final mPath = Path()
      ..moveTo(0, h * 0.55)
      ..lineTo(w * 0.22, h * 0.4)
      ..lineTo(w * 0.4, h * 0.53)
      ..lineTo(w * 0.62, h * 0.36)
      ..lineTo(w * 0.85, h * 0.52)
      ..lineTo(w, h * 0.46)
      ..lineTo(w, h * 0.6)
      ..lineTo(0, h * 0.6)
      ..close();
    canvas.drawPath(mPath, mountain);

    final groundY = h * 0.86;

    // Pagoda a cinque piani.
    final pagoda = Paint()..color = const Color(0xFF2A1B1F);
    final px = w * 0.28;
    double roofW = w * 0.34;
    double top = groundY - h * 0.06;
    for (var i = 0; i < 5; i++) {
      final tierH = h * 0.075;
      final rect = Rect.fromCenter(center: Offset(px, top - tierH / 2), width: roofW, height: tierH * 0.5);
      canvas.drawRect(rect, pagoda);
      final roof = Path()
        ..moveTo(px - roofW / 2 - w * 0.03, top - tierH * 0.5)
        ..lineTo(px, top - tierH * 1.05)
        ..lineTo(px + roofW / 2 + w * 0.03, top - tierH * 0.5)
        ..close();
      canvas.drawPath(roof, pagoda);
      top -= tierH;
      roofW *= 0.82;
    }
    canvas.drawLine(Offset(px, top - h * 0.01), Offset(px, top - h * 0.05), pagoda..strokeWidth = 2);

    // Torii in primo piano.
    final torii = Paint()..color = const Color(0xFFB1432E);
    final legY1 = groundY + h * 0.02;
    canvas.drawRect(Rect.fromLTWH(w * 0.62, h * 0.58, w * 0.035, legY1 - h * 0.58), torii);
    canvas.drawRect(Rect.fromLTWH(w * 0.92, h * 0.58, w * 0.035, legY1 - h * 0.58), torii);
    canvas.drawRect(Rect.fromLTWH(w * 0.6, h * 0.56, w * 0.38, h * 0.028), torii);
    canvas.drawRect(Rect.fromLTWH(w * 0.63, h * 0.605, w * 0.32, h * 0.018), torii);

    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY), Paint()..color = const Color(0xFF241318));

    // Petali di sakura.
    final rng = Random(19);
    final petal = Paint()..color = const Color(0xFFF7B8D0).withOpacity(0.85);
    for (var i = 0; i < 22; i++) {
      final p = Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.85);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(rng.nextDouble() * pi);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 5, height: 2.6), petal);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GerusalemmeScene extends CustomPainter {
  const _GerusalemmeScene();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _sky(canvas, size, const [Color(0xFF14213D), Color(0xFF5A4A7A), Color(0xFFE8A660)], const [0, 0.5, 1]);
    _stars(canvas, size, 5, 22, top: 0.35);

    final groundY = h * 0.84;
    final wallPaint = Paint()..color = const Color(0xFF3A2E22);

    // Mura con merlature.
    canvas.drawRect(Rect.fromLTWH(0, groundY - h * 0.1, w, h * 0.1), wallPaint);
    const crenels = 14;
    final cw = w / crenels;
    for (var i = 0; i < crenels; i += 2) {
      canvas.drawRect(Rect.fromLTWH(i * cw, groundY - h * 0.13, cw, h * 0.03), wallPaint);
    }
    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY), Paint()..color = const Color(0xFF241A12));

    // Base ottagonale + cupola dorata.
    final domeBase = Paint()..color = const Color(0xFF274A6B);
    final baseRect = Rect.fromCenter(center: Offset(w * 0.5, groundY - h * 0.24), width: w * 0.5, height: h * 0.22);
    canvas.drawRect(baseRect, domeBase);
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(Rect.fromLTWH(baseRect.left + i * baseRect.width / 4, baseRect.top, baseRect.width / 4 - 2, baseRect.height), Paint()..color = const Color(0xFF1E3A54));
    }

    final domeCenter = Offset(w * 0.5, baseRect.top);
    final domeRadius = w * 0.22;
    final domePaint = Paint()
      ..shader = const RadialGradient(colors: [Color(0xFFFFE9A8), Color(0xFFD4A017)], center: Alignment(-0.3, -0.4))
          .createShader(Rect.fromCircle(center: domeCenter, radius: domeRadius));
    canvas.drawArc(Rect.fromCircle(center: domeCenter, radius: domeRadius), pi, pi, true, domePaint);
    canvas.drawRect(Rect.fromCenter(center: Offset(domeCenter.dx, domeCenter.dy - domeRadius - h * 0.03), width: w * 0.01, height: h * 0.07), Paint()..color = const Color(0xFFD4A017));
    canvas.drawCircle(Offset(domeCenter.dx, domeCenter.dy - domeRadius - h * 0.065), 3, Paint()..color = const Color(0xFFFFE9A8));

    // Torri laterali.
    final tower = Paint()..color = const Color(0xFF2C2318);
    for (final dx in [-0.34, 0.34]) {
      final tx = w * 0.5 + w * dx;
      canvas.drawRect(Rect.fromLTWH(tx - w * 0.035, groundY - h * 0.34, w * 0.07, h * 0.24), tower);
      canvas.drawArc(Rect.fromCenter(center: Offset(tx, groundY - h * 0.34), width: w * 0.07, height: h * 0.06), pi, pi, true, tower);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AtlantideScene extends CustomPainter {
  const _AtlantideScene();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _sky(canvas, size, const [Color(0xFF042034), Color(0xFF0A3B54), Color(0xFF0F5C6E)], const [0, 0.55, 1]);

    // Raggi di luce dall'alto.
    final rayPaint = Paint()..color = Colors.white.withOpacity(0.06);
    for (final dx in [0.2, 0.45, 0.7]) {
      final path = Path()
        ..moveTo(w * dx, 0)
        ..lineTo(w * dx + w * 0.09, 0)
        ..lineTo(w * dx - w * 0.05, h)
        ..lineTo(w * dx - w * 0.16, h)
        ..close();
      canvas.drawPath(path, rayPaint);
    }

    final groundY = h * 0.82;

    // Colonne spezzate.
    final column = Paint()..color = const Color(0xFF123B49);
    for (final spec in [
      (w * 0.16, h * 0.42, h * 0.02),
      (w * 0.38, h * 0.3, -h * 0.03),
      (w * 0.62, h * 0.5, h * 0.01),
      (w * 0.84, h * 0.34, -h * 0.02),
    ]) {
      final (cx, ch, breakOffset) = spec;
      final rect = Rect.fromLTWH(cx - w * 0.035, groundY - ch, w * 0.07, ch);
      final path = Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + breakOffset.abs())
        ..lineTo(rect.left + rect.width * 0.5, rect.top)
        ..lineTo(rect.right, rect.top + breakOffset.abs() * 0.6)
        ..lineTo(rect.right, rect.bottom)
        ..close();
      canvas.drawPath(path, column);
      for (var i = 1; i < 4; i++) {
        canvas.drawLine(Offset(rect.left, rect.bottom - i * ch / 4), Offset(rect.right, rect.bottom - i * ch / 4), Paint()..color = const Color(0xFF0A2A35)..strokeWidth = 1.4);
      }
    }

    canvas.drawRect(Rect.fromLTWH(0, groundY, w, h - groundY), Paint()..color = const Color(0xFF031824));

    // Emblema centrale luminoso (tridente su cerchio runico).
    final center = Offset(w * 0.5, h * 0.46);
    final glow = Paint()
      ..color = const Color(0xFF6FF3E8).withOpacity(0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, w * 0.16, glow);
    final ring = Paint()
      ..color = const Color(0xFFBFFFF6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, w * 0.15, ring);
    canvas.drawCircle(center, w * 0.12, ring..color = const Color(0xFFBFFFF6).withOpacity(0.6));

    final trident = Paint()
      ..color = const Color(0xFFEAFFFC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final tx = center.dx, topY = center.dy - w * 0.11, botY = center.dy + w * 0.11;
    canvas.drawLine(Offset(tx, topY), Offset(tx, botY), trident);
    canvas.drawLine(Offset(tx - w * 0.06, topY + w * 0.02), Offset(tx, topY + w * 0.07), trident);
    canvas.drawLine(Offset(tx + w * 0.06, topY + w * 0.02), Offset(tx, topY + w * 0.07), trident);
    canvas.drawLine(Offset(tx - w * 0.05, botY - w * 0.06), Offset(tx + w * 0.05, botY - w * 0.02), trident);
    canvas.drawLine(Offset(tx + w * 0.05, botY - w * 0.06), Offset(tx - w * 0.05, botY - w * 0.02), trident);

    // Bolle.
    final rng = Random(3);
    final bubble = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 16; i++) {
      final p = Offset(rng.nextDouble() * w, groundY - rng.nextDouble() * h * 0.75);
      canvas.drawCircle(p, 1.2 + rng.nextDouble() * 2.4, bubble..color = Colors.white.withOpacity(0.2 + rng.nextDouble() * 0.35));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
