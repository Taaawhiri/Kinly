import 'package:flutter/material.dart';

/// Anello che si dilata e sfuma lentamente intorno al figlio: usato per
/// segnalare "Non disturbare attivo" con un respiro tranquillo, apposta
/// diverso dal passo/scivolamento di ActivityIndicator (quello comunica
/// movimento, questo deve comunicare l'opposto).
class PulseRing extends StatefulWidget {
  const PulseRing({super.key, required this.color, required this.child, this.size = 40});
  final Color color;
  final Widget child;
  final double size;

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            return Opacity(
              opacity: (1 - t) * 0.6,
              child: Transform.scale(
                scale: 1 + t * 0.35,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.color, width: 1.6)),
                ),
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}
