import 'dart:ui';
import 'package:flutter/material.dart';

/// Come [showModalBottomSheet], ma sfoca TUTTO lo schermo dietro il foglio
/// (mappa compresa), non solo la zona coperta dal foglio stesso: costruito
/// su showGeneralDialog perché il BackdropFilter deve avvolgere l'intera
/// area della route, cosa che showModalBottomSheet non permette.
Future<T?> showBlurredModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool isScrollControlled = false,
}) {
  final radius = (shape is RoundedRectangleBorder) ? shape.borderRadius : const BorderRadius.vertical(top: Radius.circular(20));
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Chiudi',
    barrierColor: Colors.black.withOpacity(0.10),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return SafeArea(
        // Il tocco fuori dal foglio chiude (comportamento standard di un
        // bottom sheet); il GestureDetector interno vuoto evita che il tocco
        // SUL foglio venga interpretato come "fuori".
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(dialogContext).pop(),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              // Niente padding tastiera qui: i fogli lo gestiscono già da
              // soli (EdgeInsets con viewInsets.bottom), aggiungerlo anche
              // qui lo raddoppierebbe.
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(dialogContext).size.height * (isScrollControlled ? 0.92 : 0.6),
                ),
                child: Material(
                  color: backgroundColor ?? Theme.of(dialogContext).colorScheme.surface,
                  borderRadius: radius is BorderRadius ? radius : null,
                  clipBehavior: Clip.antiAlias,
                  child: builder(dialogContext),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return BackdropFilter(
        // Il blur cresce insieme all'animazione di apertura, così l'effetto
        // è morbido invece di scattare al massimo di colpo.
        filter: ImageFilter.blur(sigmaX: 7 * animation.value, sigmaY: 7 * animation.value),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}
