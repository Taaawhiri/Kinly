import 'dart:math';
import 'package:flutter/material.dart';

/// Effetto "foil" olografico animato, riservato alle carte di rarità Segreta.
/// Combina una banda di luce arcobaleno che scorre in diagonale con un lieve
/// respiro di scala e un pulviscolo di scintille: l'idea è suggerire una
/// carta fisica che cambia riflesso muovendola sotto la luce, ma animata
/// in continuo perché qui è digitale.
class FoilOverlay extends StatefulWidget {
  const FoilOverlay({super.key, required this.child, required this.borderRadius});

  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<FoilOverlay> createState() => _FoilOverlayState();
}

class _FoilOverlayState extends State<FoilOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Sparkle> _sparkles = List.generate(14, (i) => _Sparkle(i));

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final breathe = 1.0 + 0.015 * sin(t * 2 * pi);
        return Transform.scale(
          scale: breathe,
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: Stack(
              children: [
                widget.child,
                Positioned.fill(
                  child: IgnorePointer(
                    child: ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback: (rect) {
                        final shift = (t * 2) - 1; // -1..1
                        return LinearGradient(
                          begin: const Alignment(-1.6, -1.6),
                          end: const Alignment(1.6, 1.6),
                          transform: _SweepTransform(shift),
                          colors: const [
                            Colors.transparent,
                            Color(0x33FFFFFF),
                            Color(0x88FF8AD4),
                            Color(0x886AD4FF),
                            Color(0x33FFFFFF),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.35, 0.5, 0.6, 0.75, 1.0],
                        ).createShader(rect);
                      },
                      child: Container(color: Colors.white.withOpacity(0.55)),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _SparklePainter(sparkles: _sparkles, t: t),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SweepTransform extends GradientTransform {
  const _SweepTransform(this.shift);
  final double shift;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.identity()..translate(bounds.width * shift, 0.0);
  }
}

class _Sparkle {
  _Sparkle(int index)
      : dx = Random(index * 911 + 7).nextDouble(),
        dy = Random(index * 37 + 3).nextDouble(),
        phase = Random(index * 131 + 11).nextDouble(),
        size = 1.5 + Random(index * 53 + 1).nextDouble() * 2.2;
  final double dx;
  final double dy;
  final double phase;
  final double size;
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({required this.sparkles, required this.t});
  final List<_Sparkle> sparkles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final local = ((t + s.phase) % 1.0);
      final opacity = (sin(local * pi)).clamp(0.0, 1.0);
      if (opacity <= 0.02) continue;
      final paint = Paint()..color = Colors.white.withOpacity(opacity);
      final center = Offset(s.dx * size.width, s.dy * size.height);
      _drawStar(canvas, center, s.size * (0.6 + opacity * 0.6), paint);
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), paint..strokeWidth = 0.8);
    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => oldDelegate.t != t;
}
