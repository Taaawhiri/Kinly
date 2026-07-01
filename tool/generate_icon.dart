// Script di utilità (non un test): renderizza CerchiaLogo a 1024x1024 e lo
// salva come PNG per generare l'icona dell'app con flutter_launcher_icons.
// Uso: flutter test tool/generate_icon.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cerchia/widgets/app_logo.dart';

void main() {
  testWidgets('genera assets/icon/icon.png', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: const SizedBox(
            width: 1024,
            height: 1024,
            child: CerchiaLogo(size: 1024, squareBackground: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final file = File('assets/icon/icon.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
