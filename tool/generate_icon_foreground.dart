// Script di utilità (non un test): renderizza il solo livello "foreground"
// trasparente del logo, per l'adaptive icon Android.
// Uso: flutter test tool/generate_icon_foreground.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinly/widgets/app_logo.dart';

void main() {
  testWidgets('genera assets/icon/icon_foreground.png', (tester) async {
    // La finestra di test di default è 800x600: senza forzarla a un
    // quadrato, il RepaintBoundary cattura un'immagine non quadrata e
    // l'icona finale risulta schiacciata.
    await tester.binding.setSurfaceSize(const Size(1024, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          // flutter_launcher_icons applica già un inset del 16% per lato
          // per ricavare la safe-zone dell'adaptive icon: qui il logo deve
          // quindi arrivare quasi al bordo, senza un margine nostro extra
          // (altrimenti il segno risulta troppo piccolo/decentrato).
          child: const SizedBox(
            width: 1024,
            height: 1024,
            child: KinlyLogo(size: 1024, transparent: true),
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
