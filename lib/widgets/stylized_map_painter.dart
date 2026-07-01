import 'dart:math';
import 'package:flutter/material.dart';

/// Una mappa "stilizzata": niente tile reali né chiavi API, solo
/// un'illustrazione leggera e coerente con il resto dell'app — strade,
/// un parco, un fiume. Serve da sfondo alla mappa dei membri della cerchia.
class StylizedMapBackground extends StatelessWidget {
  const StylizedMapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MapPainter(), child: const SizedBox.expand());
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFEEF1FA), Color(0xFFE3E9F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    // Fiume: una banda morbida diagonale.
    final riverPaint = Paint()..color = const Color(0xFFCBD9F0);
    final river = Path()
      ..moveTo(-w * 0.1, h * 0.15)
      ..quadraticBezierTo(w * 0.35, h * 0.32, w * 0.5, h * 0.55)
      ..quadraticBezierTo(w * 0.68, h * 0.82, w * 1.1, h * 0.92)
      ..lineTo(w * 1.1, h * 1.05)
      ..quadraticBezierTo(w * 0.62, h * 0.92, w * 0.42, h * 0.62)
      ..quadraticBezierTo(w * 0.28, h * 0.4, -w * 0.1, h * 0.28)
      ..close();
    canvas.drawPath(river, riverPaint);

    // Parco: una macchia verde morbida.
    final parkPaint = Paint()..color = const Color(0xFFD8ECD6);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.18, h * 0.72), width: w * 0.42, height: h * 0.3), parkPaint);
    final treePaint = Paint()..color = const Color(0xFFBBDDB6);
    final rngTrees = Random(11);
    for (var i = 0; i < 10; i++) {
      final p = Offset(
        w * 0.18 + (rngTrees.nextDouble() - 0.5) * w * 0.36,
        h * 0.72 + (rngTrees.nextDouble() - 0.5) * h * 0.24,
      );
      canvas.drawCircle(p, 3.5 + rngTrees.nextDouble() * 3, treePaint);
    }

    // Isolati: rettangoli chiari con bordo sottile, disposti su una griglia
    // leggermente irregolare per non sembrare artificiale.
    final blockFill = Paint()..color = Colors.white.withOpacity(0.55);
    final blockStroke = Paint()
      ..color = const Color(0xFFCED8EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rng = Random(4);
    const cols = 6;
    const rows = 8;
    final cellW = w / cols;
    final cellH = h / rows;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (rng.nextDouble() < 0.32) continue; // lascia spazio a strade più larghe
        final pad = min(cellW, cellH) * 0.16;
        final rectBlock = Rect.fromLTWH(
          c * cellW + pad + rng.nextDouble() * 3,
          r * cellH + pad + rng.nextDouble() * 3,
          cellW - pad * 2,
          cellH - pad * 2,
        );
        final radius = Radius.circular(min(cellW, cellH) * 0.12);
        canvas.drawRRect(RRect.fromRectAndRadius(rectBlock, radius), blockFill);
        canvas.drawRRect(RRect.fromRectAndRadius(rectBlock, radius), blockStroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
