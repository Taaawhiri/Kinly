import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/meeting_point.dart';
import '../models/nearby_poi.dart';
import '../models/person.dart';
import '../models/safe_zone.dart';
import '../theme/app_theme.dart';
import '../utils/avatar_catalog.dart';
import '../utils/color_hex.dart';
import '../utils/geo_circle.dart';

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
    this.onMapReady,
    this.safeZones = const [],
    this.meetingPoints = const [],
    this.nearbyPois = const [],
    this.onMeetingPointTap,
    this.onSafeZoneTap,
  });

  /// Le persone da mostrare come marcatori: solo quelle con una posizione
  /// nota (`lat`/`lng` non nulli) vengono effettivamente disegnate.
  final List<Person> people;
  final ValueChanged<String>? onPersonTap;

  /// Aree sicure da disegnare come cerchi colorati in scala reale (metri).
  final List<SafeZone> safeZones;

  /// Punti d'incontro attivi da mostrare come marcatori a bandiera.
  final List<MeetingPoint> meetingPoints;

  /// Punti di interesse vicini (ristoranti, bar, farmacie...) da mostrare
  /// come piccoli marcatori di sfondo, solo a scopo informativo.
  final List<NearbyPoi> nearbyPois;

  /// Chiamato quando si tocca il marcatore di un punto d'incontro.
  final ValueChanged<String>? onMeetingPointTap;

  /// Chiamato quando si tocca l'area colorata di un'area sicura.
  final ValueChanged<String>? onSafeZoneTap;

  /// Chiamato quando la mappa è pronta: utile a chi la usa per aggiungere
  /// controlli propri (es. un pulsante "centra sulla mia posizione").
  final ValueChanged<MapLibreMapController>? onMapReady;

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

  /// Vero dopo il primo ricentraggio automatico sulla MIA posizione: serve a
  /// correggere la mappa quando all'avvio mostra ancora l'ultima posizione
  /// salvata (magari vecchia) prima che arrivi un fix GPS fresco, senza poi
  /// continuare a spostare la camera ogni volta che qualcuno si muove.
  bool _autoCenteredOnFreshFix = false;

  List<Person> get _visiblePeople => widget.people.where((p) => p.lat != null && p.lng != null).toList();

  Person? _meIn(List<Person> people) {
    for (final p in people) {
      if (p.isMe) return p;
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant KinlyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_styleLoaded) return;
    if (!_samePeople(oldWidget.people, widget.people) ||
        !_sameMeetingPoints(oldWidget.meetingPoints, widget.meetingPoints) ||
        !_sameNearbyPois(oldWidget.nearbyPois, widget.nearbyPois)) {
      unawaited(_syncSymbols(fitCamera: false));
    }
    if (!_sameSafeZones(oldWidget.safeZones, widget.safeZones)) {
      unawaited(_syncSafeZoneFills());
    }
    if (!_autoCenteredOnFreshFix) {
      final oldMe = _meIn(oldWidget.people);
      final newMe = _meIn(widget.people);
      if (newMe?.lat != null && newMe?.lng != null && (oldMe?.lat != newMe?.lat || oldMe?.lng != newMe?.lng)) {
        _autoCenteredOnFreshFix = true;
        final controller = _controller;
        if (controller != null) {
          unawaited(controller.animateCamera(CameraUpdate.newLatLng(LatLng(newMe!.lat!, newMe.lng!))));
        }
      }
    }
  }

  bool _sameMeetingPoints(List<MeetingPoint> a, List<MeetingPoint> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].lat != b[i].lat || a[i].lng != b[i].lng) return false;
    }
    return true;
  }

  bool _sameSafeZones(List<SafeZone> a, List<SafeZone> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].lat != b[i].lat ||
          a[i].lng != b[i].lng ||
          a[i].radiusMeters != b[i].radiusMeters ||
          a[i].kind != b[i].kind) {
        return false;
      }
    }
    return true;
  }

  bool _sameNearbyPois(List<NearbyPoi> a, List<NearbyPoi> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
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
        controller.onFillTapped.add(_handleFillTap);
        widget.onMapReady?.call(controller);
      },
      onStyleLoadedCallback: () async {
        _styleLoaded = true;
        await _syncSymbols(fitCamera: true);
        await _syncSafeZoneFills();
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

    if (widget.meetingPoints.isNotEmpty) {
      final meetingImageName = await _ensureMeetingPointImage(controller);
      for (final point in widget.meetingPoints) {
        await controller.addSymbol(
          SymbolOptions(
            geometry: LatLng(point.lat, point.lng),
            iconImage: meetingImageName,
            iconSize: 1,
            iconAnchor: 'bottom',
          ),
          {'meetingPointId': point.id},
        );
      }
    }

    for (final poi in widget.nearbyPois) {
      final imageName = await _ensurePoiImage(controller, poi.category);
      await controller.addSymbol(
        SymbolOptions(geometry: LatLng(poi.lat, poi.lng), iconImage: imageName, iconSize: 0.8, iconAnchor: 'bottom'),
        {'poiId': poi.id},
      );
    }

    if (fitCamera) await _fitCamera(controller, people);
  }

  /// Disegna le aree sicure come cerchi in scala reale (metri, non pixel):
  /// livello separato dai simboli, così non viene toccato da clearSymbols.
  Future<void> _syncSafeZoneFills() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.clearFills();
    for (final zone in widget.safeZones) {
      final color = zone.kind.mapColor;
      final ring = circlePolygonPoints(zone.lat, zone.lng, zone.radiusMeters.toDouble());
      await controller.addFill(
        FillOptions(geometry: [ring], fillColor: color.toHex(), fillOpacity: 0.18, fillOutlineColor: color.toHex()),
        {'zoneId': zone.id},
      );
    }
  }

  void _handleSymbolTap(Symbol symbol) {
    final personId = symbol.data?['personId'] as String?;
    if (personId != null) {
      widget.onPersonTap?.call(personId);
      return;
    }
    final meetingPointId = symbol.data?['meetingPointId'] as String?;
    if (meetingPointId != null) widget.onMeetingPointTap?.call(meetingPointId);
  }

  void _handleFillTap(Fill fill) {
    final zoneId = fill.data?['zoneId'] as String?;
    if (zoneId != null) widget.onSafeZoneTap?.call(zoneId);
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

  static const _meetingPointImageName = 'kinly_meeting_point_pin';

  Future<String> _ensureMeetingPointImage(MapLibreMapController controller) async {
    if (!_registeredImages.contains(_meetingPointImageName)) {
      final bytes = await _renderFlagPin();
      await controller.addImage(_meetingPointImageName, bytes);
      _registeredImages.add(_meetingPointImageName);
    }
    return _meetingPointImageName;
  }

  Future<String> _ensurePoiImage(MapLibreMapController controller, NearbyPoiCategory category) async {
    final name = 'kinly_poi_${category.name}';
    if (!_registeredImages.contains(name)) {
      final bytes = await _renderSmallEmojiPin(category.emoji);
      await controller.addImage(name, bytes);
      _registeredImages.add(name);
    }
    return name;
  }

  @override
  void dispose() {
    _controller?.onSymbolTapped.remove(_handleSymbolTap);
    _controller?.onFillTapped.remove(_handleFillTap);
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

/// Marcatore a bandiera per un punto d'incontro: stessa forma a goccia dei
/// pin persona (punta verso il basso, ancorata alla coordinata esatta), ma
/// viola per distinguerlo a colpo d'occhio dagli avatar.
Future<Uint8List> _renderFlagPin() async {
  const double circleSize = 64;
  const double tailHeight = 20;
  const double pixelRatio = 2.0;
  const width = circleSize * pixelRatio;
  const height = (circleSize + tailHeight) * pixelRatio;
  const color = Color(0xFF8A6DE7);

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
    text: const TextSpan(text: '🚩', style: TextStyle(fontSize: radius * 0.85)),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));

  final picture = recorder.endRecording();
  final image = await picture.toImage(width.round(), height.round());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

/// Marcatore piccolo e neutro per un punto di interesse vicino (ristorante,
/// bar, farmacia...): solo un cerchio bianco con l'emoji della categoria,
/// più discreto dei pin di persone/punti d'incontro, che sono il contenuto
/// principale della mappa.
Future<Uint8List> _renderSmallEmojiPin(String emoji) async {
  const double circleSize = 44;
  const double pixelRatio = 2.0;
  const width = circleSize * pixelRatio;
  const height = circleSize * pixelRatio;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const center = Offset(width / 2, height / 2);
  const radius = (circleSize / 2) * pixelRatio;

  canvas.drawCircle(center, radius, Paint()..color = Colors.white);
  canvas.drawCircle(center, radius, Paint()
    ..color = Colors.black12
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4);

  final textPainter = TextPainter(
    text: TextSpan(text: emoji, style: TextStyle(fontSize: radius * 0.95)),
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
