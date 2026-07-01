// Script di utilità (non un test): renderizza il solo livello "foreground"
// trasparente del logo, per l'adaptive icon Android.
// Uso: flutter test tool/generate_icon_foreground.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cerchia/widgets/app_logo.dart';

void main() {
  testWidgets('genera assets/icon/icon_foreground.png', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: const SizedBox(
            width: 1024,
            height: 1024,
            child: Center(
              child: SizedBox(
                width: 1024 * 0.62,
                height: 1024 * 0.62,
                child: CerchiaLogo(size: 1024 * 0.62, transparent: true),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final file = File('assets/icon/icon_foreground.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
