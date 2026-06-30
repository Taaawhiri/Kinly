import 'dart:math';
import 'package:flutter/material.dart';

/// Marchio/logo di URBIS: un emblema circolare con un piccolo skyline
/// stilizzato e un alone che attraversa lo spettro di colori delle rarità,
/// dal comune al segreto. Usato come icona dell'app e nella schermata
/// di apertura buste.
class UrbisLogo extends StatelessWidget {
  const UrbisLogo({super.key, this.size = 96, this.squareBackground = false, this.transparent = false});

  final double size;
  final bool squareBackground;

  /// Se true non disegna alcuno sfondo (usato per il livello "foreground"
  /// dell'adaptive icon Android).
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _UrbisLogoPainter(squareBackground: squareBackground, transparent: transparent),
    );
  }
}

class _UrbisLogoPainter extends CustomPainter {
  _UrbisLogoPainter({required this.squareBackground, this.transparent = false});
  final bool squareBackground;
  final bool transparent;

  static const _spectrum = [
    Color(0xFF9AA5B1), // comune
    Color(0xFF2E8B57), // non comune
    Color(0xFF2563EB), // rara
    Color(0xFF7C3AED), // epica
    Color(0xFFD97706), // leggendaria
    Color(0xFFFF3CAC), // segreta
    Color(0xFF9AA5B1),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    final bgRect = Rect.fromCircle(center: c, radius: r);
    if (!transparent) {
      final bgPaint = Paint()..color = const Color(0xFF0B0E14);
      if (squareBackground) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * 0.22)),
          bgPaint,
        );
      } else {
        canvas.drawOval(bgRect, bgPaint);
      }
    }

    // Alone sfumato che attraversa tutte le rarità.
    final haloPaint = Paint()
      ..shader = const SweepGradient(colors: _spectrum, startAngle: 0, endAngle: 2 * pi)
          .createShader(bgRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.1;
    canvas.drawOval(bgRect.deflate(r * 0.07), haloPaint);

    // Skyline stilizzato e fisso (identico a ogni dimensione, per coerenza
    // dell'icona a ogni risoluzione).
    final skylinePaint = Paint()..color = const Color(0xFFF4F6F8);
    final baseline = c.dy + r * 0.32;
    final buildings = [
      Rect.fromLTWH(c.dx - r * 0.62, baseline - r * 0.42, r * 0.26, r * 0.42),
      Rect.fromLTWH(c.dx - r * 0.34, baseline - r * 0.62, r * 0.24, r * 0.62),
      Rect.fromLTWH(c.dx - r * 0.06, baseline - r * 0.86, r * 0.22, r * 0.86),
      Rect.fromLTWH(c.dx + r * 0.18, baseline - r * 0.56, r * 0.24, r * 0.56),
      Rect.fromLTWH(c.dx + r * 0.44, baseline - r * 0.36, r * 0.22, r * 0.36),
    ];
    for (final b in buildings) {
      canvas.drawRect(b, skylinePaint);
    }
    // guglia sulla torre centrale
    final spire = Path()
      ..moveTo(c.dx - r * 0.06, baseline - r * 0.86)
      ..lineTo(c.dx + r * 0.05, baseline - r * 1.02)
      ..lineTo(c.dx + r * 0.16, baseline - r * 0.86)
      ..close();
    canvas.drawPath(spire, skylinePaint);

    canvas.drawRect(
      Rect.fromLTWH(c.dx - r * 0.66, baseline, r * 1.32, r * 0.05),
      skylinePaint,
    );

    // Stella a sei punte sopra lo skyline: richiama la rarità Segreta.
    final starPaint = Paint()..color = const Color(0xFFFFD86B);
    final starCenter = Offset(c.dx, c.dy - r * 0.5);
    _drawStar(canvas, starCenter, r * 0.16, starPaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 2;
      final outer = center + Offset(cos(angle), sin(angle)) * radius;
      final innerAngle = angle + pi / 6;
      final inner = center + Offset(cos(innerAngle), sin(innerAngle)) * radius * 0.42;
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _UrbisLogoPainter oldDelegate) => false;
}
