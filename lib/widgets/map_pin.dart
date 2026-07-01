import 'package:flutter/material.dart';
import '../models/person.dart';
import 'person_avatar.dart';

/// Il marcatore di una persona sulla mappa: un avatar con un piccolo
/// puntatore verso il basso e, se la posizione è live, un alone che pulsa.
class MapPin extends StatefulWidget {
  const MapPin({super.key, required this.person, this.size = 46, this.onTap});

  final Person person;
  final double size;
  final VoidCallback? onTap;

  @override
  State<MapPin> createState() => _MapPinState();
}

class _MapPinState extends State<MapPin> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get _isLive => widget.person.isMe || widget.person.isSharingWithMe;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size * 1.8,
            height: size * 1.8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isLive)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final t = _controller.value;
                      return Opacity(
                        opacity: (1 - t) * 0.45,
                        child: Container(
                          width: size * (1 + t * 0.8),
                          height: size * (1 + t * 0.8),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: widget.person.color),
                        ),
                      );
                    },
                  ),
                PersonAvatar(person: widget.person, size: size),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -6),
            child: CustomPaint(size: Size(size * 0.28, size * 0.18), painter: _PinTailPainter(color: widget.person.color)),
          ),
        ],
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  _PinTailPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinTailPainter oldDelegate) => oldDelegate.color != color;
}
