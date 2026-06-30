import 'dart:math';
import 'package:flutter/material.dart';

/// Disegna uno skyline stilizzato e deterministico, generato a partire dal
/// nome della città. Non sono immagini reali: è l'illustrazione "vettoriale"
/// di ogni carta, pensata per il mockup.
class SkylinePainter extends CustomPainter {
  SkylinePainter({
    required this.seed,
    required this.silhouetteColor,
    required this.windowColor,
    this.landmark = LandmarkShape.tower,
  });

  final int seed;
  final Color silhouetteColor;
  final Color windowColor;
  final LandmarkShape landmark;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final baseline = size.height * 0.82;

    // Stelle / cielo notturno leggero per le rarità più rare viene aggiunto
    // sopra da altri widget: qui ci concentriamo sullo skyline.
    final buildingPaint = Paint()..color = silhouetteColor;
    final windowPaint = Paint()..color = windowColor.withOpacity(0.85);

    double x = -size.width * 0.05;
    final buildings = <Rect>[];
    while (x < size.width * 1.05) {
      final w = size.width * (0.08 + rng.nextDouble() * 0.09);
      final hFactor = 0.18 + rng.nextDouble() * 0.55;
      final h = size.height * hFactor;
      final rect = Rect.fromLTWH(x, baseline - h, w, h);
      buildings.add(rect);
      x += w * (0.62 + rng.nextDouble() * 0.25);
    }

    for (final rect in buildings) {
      canvas.drawRect(rect, buildingPaint);
      // finestrelle
      final cols = max(1, (rect.width / 7).floor());
      final rows = max(1, (rect.height / 9).floor());
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          if (rng.nextDouble() < 0.35) continue;
          final wx = rect.left + 3 + c * 7.0;
          final wy = rect.top + 4 + r * 9.0;
          if (wx > rect.right - 3 || wy > rect.bottom - 3) continue;
          canvas.drawRect(Rect.fromLTWH(wx, wy, 2.4, 3.4), windowPaint);
        }
      }
    }

    _drawLandmark(canvas, size, baseline, buildingPaint);

    // linea di base
    canvas.drawRect(
      Rect.fromLTWH(0, baseline, size.width, size.height - baseline),
      buildingPaint,
    );
  }

  void _drawLandmark(Canvas canvas, Size size, double baseline, Paint paint) {
    final cx = size.width * 0.5;
    switch (landmark) {
      case LandmarkShape.tower:
        final h = size.height * 0.62;
        final path = Path()
          ..moveTo(cx - 3, baseline)
          ..lineTo(cx - 1.2, baseline - h)
          ..lineTo(cx, baseline - h - 14)
          ..lineTo(cx + 1.2, baseline - h)
          ..lineTo(cx + 3, baseline)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case LandmarkShape.dome:
        final r = size.width * 0.07;
        final domeBase = baseline - size.height * 0.34;
        canvas.drawRect(
          Rect.fromLTWH(cx - r, domeBase, r * 2, size.height * 0.34),
          paint,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, domeBase), radius: r),
          pi,
          pi,
          true,
          paint,
        );
        break;
      case LandmarkShape.pyramid:
        final h = size.height * 0.4;
        final w = size.width * 0.16;
        final path = Path()
          ..moveTo(cx - w, baseline)
          ..lineTo(cx, baseline - h)
          ..lineTo(cx + w, baseline)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case LandmarkShape.bridge:
        final w = size.width * 0.34;
        final h = size.height * 0.22;
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, baseline), width: w, height: h * 2),
          pi,
          pi,
          false,
          Paint()
            ..color = paint.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant SkylinePainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.silhouetteColor != silhouetteColor ||
        oldDelegate.windowColor != windowColor ||
        oldDelegate.landmark != landmark;
  }
}

enum LandmarkShape { tower, dome, pyramid, bridge }

/// Sceglie una forma "landmark" deterministica in base al nome città.
LandmarkShape landmarkForSeed(int seed) {
  return LandmarkShape.values[seed % LandmarkShape.values.length];
}
