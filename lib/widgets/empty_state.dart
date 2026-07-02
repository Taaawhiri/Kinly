import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Illustrazione+testo per gli stati vuoti dell'app (nessun punto
/// d'incontro, nessuna area sicura, nessuna spesa, ecc.): al posto di una
/// singola icona piatta su sfondo tinta unita, usa un cerchio a gradiente
/// con un doppio "alone" attorno e un paio di puntini decorativi, così da
/// dare un minimo di profondità senza bisogno di un vero asset grafico.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Colore del cerchio: di default quello principale dell'app, ma può
  /// essere personalizzato per accostarlo al tema della sezione (es. verde
  /// per le spese, ambra per gli avvisi).
  final Color? color;

  /// Pulsante opzionale sotto al testo (es. "Crea la prima area").
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppTheme.primary;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _EmptyStateIllustration(icon: icon, color: tint),
          const SizedBox(height: 22),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.4)),
          if (action != null) ...[
            const SizedBox(height: 22),
            action!,
          ],
        ],
      ),
    );
  }
}

class _EmptyStateIllustration extends StatelessWidget {
  const _EmptyStateIllustration({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 132, height: 132, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.06))),
          Container(width: 96, height: 96, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.10))),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.85), color]),
              boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          // Un paio di puntini "fluttuanti" rompono la simmetria perfetta
          // del cerchio, senza appesantire la composizione.
          Positioned(top: 8, right: 16, child: _Dot(color: color, size: 9, opacity: 0.55)),
          Positioned(bottom: 12, left: 10, child: _Dot(color: color, size: 6, opacity: 0.4)),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size, required this.opacity});
  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(opacity)));
  }
}
