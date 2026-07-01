import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../utils/avatar_catalog.dart';
import '../utils/color_hex.dart';

/// La mappa vera di Kinly: dati OpenStreetMap via OpenFreeMap (nessuna
/// chiave, nessun limite d'uso), con uno stile personalizzato nei colori
/// morbidi dell'app (vedi assets/map/kinly_style.json). Le persone sono
/// marcatori disegnati come il resto dell'app: un avatar colorato con le
/// iniziali e una piccola coda a goccia.
class KinlyMap extends StatefulWidget {
  const KinlyMap({
    super.key,
    required this.people,
    this.onPersonTap,
    this.interactive = true,
  });

  /// Le persone da mostrare come marcatori: solo quelle con una posizione
  /// nota (`lat`/`lng` non nulli) vengono effettivamente disegnate.
  final List<Person> people;
  final ValueChanged<String>? onPersonTap;

  /// Se false disabilita pan/zoom/rotazione (utile per un'anteprima piccola
  /// e non interattiva, come nel dettaglio di una persona).
  final bool interactive;

  static const String styleAsset = 'assets/map/kinly_style.json';

  @override
  State<KinlyMap> createState() => _KinlyMapState();
}

class _KinlyMapState extends State<KinlyMap> {
  MapLibreMapController? _controller;
  final Set<String> _registeredImages = {};
  bool _styleLoaded = false;

  List<Person> get _visiblePeople => widget.people.where((p) => p.lat != null && p.lng != null).toList();

  @override
  void didUpdateWidget(covariant KinlyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_styleLoaded && !_samePeople(oldWidget.people, widget.people)) {
      unawaited(_syncSymbols(fitCamera: false));
    }
  }

  bool _samePeople(List<Person> a, List<Person> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].lat != b[i].lat ||
          a[i].lng != b[i].lng ||
          a[i].color != b[i].color ||
          a[i].avatarKey != b[i].avatarKey ||
          a[i].isFuzzyLocation != b[i].isFuzzyLocation) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final people = _visiblePeople;
    if (people.isEmpty) {
      return Container(
        color: const Color(0xFFEEF1FA),
        alignment: Alignment.center,
        child: Text(
          'In attesa della posizione…',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    return MapLibreMap(
      styleString: KinlyMap.styleAsset,
      initialCameraPosition: CameraPosition(target: LatLng(people.first.lat!, people.first.lng!), zoom: 14),
      onMapCreated: (controller) {
        _controller = controller;
        controller.onSymbolTapped.add(_handleSymbolTap);
      },
      onStyleLoadedCallback: () async {
        _styleLoaded = true;
        await _syncSymbols(fitCamera: true);
      },
      compassEnabled: false,
      logoEnabled: false,
      rotateGesturesEnabled: widget.interactive,
      scrollGesturesEnabled: widget.interactive,
      zoomGesturesEnabled: widget.interactive,
      tiltGesturesEnabled: widget.interactive,
      doubleClickZoomEnabled: widget.interactive,
    );
  }

  Future<void> _syncSymbols({required bool fitCamera}) async {
    final controller = _controller;
    if (controller == null) return;
    final people = _visiblePeople;

    await controller.clearCircles();
    // Chi condivide in modalità "approssimativa" ha già ricevuto una
    // posizione arrotondata dal server: la "nuvola" comunica visivamente
    // che quel punto non è quello esatto.
    for (final person in people.where((p) => p.isFuzzyLocation)) {
      await controller.addCircle(
        CircleOptions(
          geometry: LatLng(person.lat!, person.lng!),
          circleRadius: 46,
          circleColor: person.color.toHex(),
          circleOpacity: 0.2,
          circleBlur: 0.65,
          circleStrokeWidth: 1.4,
          circleStrokeColor: person.color.toHex(),
          circleStrokeOpacity: 0.5,
        ),
      );
    }

    await controller.clearSymbols();
    for (final person in people) {
      final imageName = await _ensureAvatarImage(controller, person);
      await controller.addSymbol(
        SymbolOptions(
          geometry: LatLng(person.lat!, person.lng!),
          iconImage: imageName,
          iconSize: 1,
          iconAnchor: 'bottom',
        ),
        {'personId': person.id},
      );
    }

    if (fitCamera) await _fitCamera(controller, people);
  }

  void _handleSymbolTap(Symbol symbol) {
    final personId = symbol.data?['personId'] as String?;
    if (personId != null) widget.onPersonTap?.call(personId);
  }

  Future<void> _fitCamera(MapLibreMapController controller, List<Person> people) async {
    if (people.length == 1) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(people.first.lat!, people.first.lng!), 14));
      return;
    }
    var minLat = people.first.lat!, maxLat = people.first.lat!;
    var minLng = people.first.lng!, maxLng = people.first.lng!;
    for (final p in people) {
      if (p.lat! < minLat) minLat = p.lat!;
      if (p.lat! > maxLat) maxLat = p.lat!;
      if (p.lng! < minLng) minLng = p.lng!;
      if (p.lng! > maxLng) maxLng = p.lng!;
    }
    final bounds = LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, left: 60, top: 80, right: 60, bottom: 80));
  }

  Future<String> _ensureAvatarImage(MapLibreMapController controller, Person person) async {
    final avatar = AvatarCatalog.find(person.avatarKey);
    final name = avatar != null
        ? 'kinly_avatar_${person.id}_${avatar.key}'
        : 'kinly_avatar_${person.id}_${person.color.toHex()}';
    if (!_registeredImages.contains(name)) {
      final bytes = avatar != null
          ? await _renderAvatarPinWithEmoji(avatar)
          : await _renderAvatarPin(person.color, person.initials);
      await controller.addImage(name, bytes);
      _registeredImages.add(name);
    }
    return name;
  }

  @override
  void dispose() {
    _controller?.onSymbolTapped.remove(_handleSymbolTap);
    super.dispose();
  }
}

/// Disegna un pin come quelli dell'app: cerchio colorato con iniziali
/// bianche, bordo bianco e una coda a goccia verso il basso, così il punto
/// dell'icona coincide con la coordinata geografica (iconAnchor: bottom).
Future<Uint8List> _renderAvatarPin(Color color, String initials) async {
  const double circleSize = 72;
  const double tailHeight = 22;
  const double pixelRatio = 2.0;
  const width = circleSize * pixelRatio;
  const height = (circleSize + tailHeight) * pixelRatio;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const center = Offset(width / 2, (circleSize / 2) * pixelRatio);
  const radius = (circleSize / 2) * pixelRatio;

  final tail = Path()
    ..moveTo(center.dx - radius * 0.42, center.dy + radius * 0.82)
    ..lineTo(center.dx + radius * 0.42, center.dy + radius * 0.82)
    ..lineTo(center.dx, height)
    ..close();
  canvas.drawPath(tail, Paint()..color = color);

  canvas.drawCircle(center, radius, Paint()..color = Colors.white);
  canvas.drawCircle(center, radius * 0.92, Paint()..color = color);

  final textPainter = TextPainter(
    text: TextSpan(
      text: initials,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: radius * 0.72),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));

  final picture = recorder.endRecording();
  final image = await picture.toImage(width.round(), height.round());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

/// Stessa forma del pin con iniziali, ma con lo sfondo a gradiente e
/// l'emoji dell'avatar a tema scelto (vedi AvatarCatalog), coerente con
/// come viene mostrato nelle liste e nel dettaglio persona.
Future<Uint8List> _renderAvatarPinWithEmoji(AvatarOption avatar) async {
  const double circleSize = 72;
  const double tailHeight = 22;
  const double pixelRatio = 2.0;
  const width = circleSize * pixelRatio;
  const height = (circleSize + tailHeight) * pixelRatio;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const center = Offset(width / 2, (circleSize / 2) * pixelRatio);
  const radius = (circleSize / 2) * pixelRatio;

  final tail = Path()
    ..moveTo(center.dx - radius * 0.42, center.dy + radius * 0.82)
    ..lineTo(center.dx + radius * 0.42, center.dy + radius * 0.82)
    ..lineTo(center.dx, height)
    ..close();
  canvas.drawPath(tail, Paint()..color = avatar.colors.last);

  canvas.drawCircle(center, radius, Paint()..color = Colors.white);
  final gradientPaint = Paint()
    ..shader = ui.Gradient.linear(
      Offset(center.dx - radius, center.dy - radius),
      Offset(center.dx + radius, center.dy + radius),
      avatar.colors,
    );
  canvas.drawCircle(center, radius * 0.92, gradientPaint);

  final textPainter = TextPainter(
    text: TextSpan(text: avatar.emoji, style: TextStyle(fontSize: radius * 0.95)),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));

  final picture = recorder.endRecording();
  final image = await picture.toImage(width.round(), height.round());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
