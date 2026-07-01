import 'package:flutter/material.dart';

/// Avvolge una carta e la rende "fisica": trascinandola con il dito si
/// inclina in prospettiva (come tenerla in mano sotto la luce) e un
/// riflesso scorre sulla superficie. Al rilascio torna dritta con un
/// piccolo rimbalzo elastico.
class Interactive3DCard extends StatefulWidget {
  const Interactive3DCard({super.key, required this.child, this.borderRadius = const BorderRadius.all(Radius.circular(18))});

  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<Interactive3DCard> createState() => _Interactive3DCardState();
}

class _Interactive3DCardState extends State<Interactive3DCard> with SingleTickerProviderStateMixin {
  static const double _maxTiltRad = 0.45;

  Offset _tilt = Offset.zero; // componenti x/y in [-1, 1]
  Offset _snapFrom = Offset.zero;
  late final AnimationController _snapController;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..addListener(() {
        final t = Curves.elasticOut.transform(_snapController.value);
        setState(() => _tilt = Offset.lerp(_snapFrom, Offset.zero, t)!);
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _updateTilt(Offset localPosition, Size size) {
    final dx = (localPosition.dx / size.width) * 2 - 1;
    final dy = (localPosition.dy / size.height) * 2 - 1;
    setState(() => _tilt = Offset(dx.clamp(-1, 1), dy.clamp(-1, 1)));
  }

  void _snapBack() {
    _snapFrom = _tilt;
    _snapController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return GestureDetector(
          onPanDown: (d) {
            _snapController.stop();
            _updateTilt(d.localPosition, size);
          },
          onPanUpdate: (d) => _updateTilt(d.localPosition, size),
          onPanEnd: (_) => _snapBack(),
          onPanCancel: _snapBack,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0018)
              ..rotateX(-_tilt.dy * _maxTiltRad)
              ..rotateY(_tilt.dx * _maxTiltRad),
            child: Stack(
              children: [
                widget.child,
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: widget.borderRadius,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (_tilt.distance).clamp(0.0, 1.0) * 0.55,
                        child: Align(
                          alignment: Alignment(_tilt.dx, _tilt.dy),
                          child: Container(
                            width: size.shortestSide * 1.3,
                            height: size.shortestSide * 1.3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.0)],
                              ),
                            ),
                          ),
                        ),
                      ),
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
