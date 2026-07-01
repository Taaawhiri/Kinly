import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Marchio di Cerchia: un pin di posizione al centro di un anello con tre
/// punti colorati — le persone della tua cerchia che ti stanno vicino.
class CerchiaLogo extends StatelessWidget {
  const CerchiaLogo({super.key, this.size = 96, this.squareBackground = false, this.transparent = false});

  final double size;
  final bool squareBackground;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CerchiaLogoPainter(squareBackground: squareBackground, transparent: transparent),
    );
  }
}

class _CerchiaLogoPainter extends CustomPainter {
  _CerchiaLogoPainter({required this.squareBackground, required this.transparent});
  final bool squareBackground;
  final bool transparent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    if (!transparent) {
      final bgRect = Rect.fromCircle(center: c, radius: r);
      final bgPaint = Paint()
        ..shader = const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bgRect);
      if (squareBackground) {
        canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * 0.22)), bgPaint);
      } else {
        canvas.drawOval(bgRect, bgPaint);
      }
    }

    // Anello che rappresenta la cerchia. Su sfondo trasparente (livello
    // "foreground" dell'adaptive icon) il fondo non è più il gradiente blu,
    // quindi ring e pin devono portare il proprio colore per restare visibili.
    final ringColor = transparent ? AppTheme.primary : Colors.white.withOpacity(0.85);
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.09;
    canvas.drawCircle(c, r * 0.62, ringPaint);

    // Tre persone sull'anello.
    const dotColors = [AppTheme.accentCoral, AppTheme.accentGreen, AppTheme.accentAmber];
    for (var i = 0; i < 3; i++) {
      final angle = -pi / 2 + i * (2 * pi / 3);
      final p = c + Offset(cos(angle), sin(angle)) * r * 0.62;
      canvas.drawCircle(p, r * 0.115, Paint()..color = Colors.white);
      canvas.drawCircle(p, r * 0.085, Paint()..color = dotColors[i]);
    }

    // Pin di posizione al centro: cerchio + triangolo uniti (più
    // affidabile dei calcoli d'arco per ottenere una goccia pulita).
    final pinCenter = Offset(c.dx, c.dy - r * 0.08);
    final pinRadius = r * 0.26;
    final head = Path()..addOval(Rect.fromCircle(center: pinCenter, radius: pinRadius));
    final tailTopY = pinCenter.dy + pinRadius * 0.62;
    final tail = Path()
      ..moveTo(pinCenter.dx - pinRadius * 0.78, tailTopY)
      ..lineTo(pinCenter.dx + pinRadius * 0.78, tailTopY)
      ..lineTo(pinCenter.dx, pinCenter.dy + pinRadius * 1.9)
      ..close();
    final pin = Path.combine(PathOperation.union, head, tail);
    canvas.drawPath(pin, Paint()..color = transparent ? AppTheme.primary : Colors.white);
    canvas.drawCircle(pinCenter, pinRadius * 0.42, Paint()..color = transparent ? Colors.white : AppTheme.primaryDark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
