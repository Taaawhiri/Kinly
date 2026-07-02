import 'package:flutter/material.dart';

/// Fa comparire [child] con una piccola dissolvenza + scala, invece che di
/// scatto: pensato per banner urgenti (SOS, richieste d'aiuto...) che
/// altrimenti spuntano dal nulla senza farsi notare. Riparte da capo solo
/// se il widget viene ricreato (serve una Key stabile per elemento, es.
/// l'id dell'avviso), non ad ogni rebuild del genitore.
class EntranceFade extends StatelessWidget {
  const EntranceFade({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.9 + (t.clamp(0.0, 1.0) * 0.1), child: child),
      ),
      child: child,
    );
  }
}
