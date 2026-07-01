import 'dart:ui';
import 'package:flutter/material.dart';

/// Come [showModalBottomSheet], ma con la mappa (o qualsiasi contenuto sotto)
/// sfocata invece che solo scurita: più elegante quando il foglio si apre
/// sopra la mappa live.
Future<T?> showBlurredModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  ShapeBorder? shape,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.12),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        decoration: BoxDecoration(color: backgroundColor, borderRadius: (shape as RoundedRectangleBorder?)?.borderRadius),
        child: builder(context),
      ),
    ),
  );
}
