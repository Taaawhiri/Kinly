import 'dart:async';
import 'dart:math' show min;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';
import '../l10n/app_localizations.dart';
import '../models/meeting_point.dart';
import '../models/person.dart';
import '../models/safe_zone.dart';
import '../services/location_tracker.dart';
import '../theme/app_theme.dart';
import '../utils/avatar_catalog.dart';
import '../utils/color_hex.dart';
import '../utils/generative_avatar.dart';
import '../utils/geo_circle.dart';

/// I pin persona/punto d'incontro vengono disegnati a questa risoluzione
/// (2x le dimensioni "logiche") per restare nitidi sugli schermi ad alta
/// densità. Su Android/iOS il plugin comunica questo fattore alla mappa
/// nativa, che quindi li mostra già alla dimensione giusta; il plugin web
/// invece lo ignora sempre (vedi `addImage` in maplibre_gl_web, che passa
/// `pixelRatio: 1` in modo fisso) e mostrerebbe l'immagine a grandezza
/// doppia — da qui l'avatar "enorme" sul browser. Su web compensiamo
/// dimezzando `iconSize` in fase di aggiunta del simbolo.
const double _avatarBitmapPixelRatio = 2.0;

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
    this.onMeetingPointTap,
    this.onSafeZoneTap,
    this.searchPreviewPoint,
  });

  /// Le persone da mostrare come marcatori: solo quelle con una posizione
  /// nota (`lat`/`lng` non nulli) vengono effettivamente disegnate.
  final List<Person> people;
  final ValueChanged<String>? onPersonTap;

  /// Aree sicure da disegnare come cerchi colorati in scala reale (metri).
  final List<SafeZone> safeZones;

  /// Punti d'incontro attivi da mostrare come marcatori a bandiera.
  final List<MeetingPoint> meetingPoints;

  /// Chiamato quando si tocca il marcatore di un punto d'incontro.
  final ValueChanged<String>? onMeetingPointTap;

  /// Chiamato quando si tocca l'area colorata di un'area sicura.
  final ValueChanged<String>? onSafeZoneTap;

  /// Chiamato quando la mappa è pronta: utile a chi la usa per aggiungere
  /// controlli propri (es. un pulsante "centra sulla mia posizione").
  final ValueChanged<MapLibreMapController>? onMapReady;

  /// Risultato di una ricerca indirizzo/luogo da mostrare come marcatore
  /// temporaneo (es. "vuoi renderlo un punto d'incontro?"), non ancora
  /// salvato in nessuna cerchia. Passato come prop, invece di aggiungerlo
  /// direttamente al controller da fuori, così sopravvive ai normali cicli
  /// di sincronizzazione dei marcatori (che altrimenti lo cancellerebbero).
  final LatLng? searchPreviewPoint;

  /// Se false disabilita pan/zoom/rotazione (utile per un'anteprima piccola
  /// e non interattiva, come nel dettaglio di una persona).
  final bool interactive;

  static const String styleAsset = 'assets/map/kinly_style.json';

  @override
  State<KinlyMap> createState() => _KinlyMapState();
}

class _KinlyMapState extends State<KinlyMap> with WidgetsBindingObserver {
  MapLibreMapController? _controller;
  final Set<String> _registeredImages = {};
  bool _styleLoaded = false;

  /// Vero dopo il primo ricentraggio automatico sulla MIA posizione: serve a
  /// correggere la mappa quando all'avvio mostra ancora l'ultima posizione
  /// salvata (magari vecchia) prima che arrivi un fix GPS fresco, senza poi
  /// continuare a spostare la camera ogni volta che qualcuno si muove.
  bool _autoCenteredOnFreshFix = false;

  /// Stato del permesso di posizione, usato solo per spiegare perché la
  /// mappa resta vuota (vedi _buildEmptyState) quando non è concesso: senza
  /// questo controllo, un permesso negato o il GPS spento sembravano un
  /// generico "in attesa della posizione" che non si risolveva mai, senza
  /// dare all'utente un modo per capire perché o rimediare.
  LocationPermission? _permission;
  bool _serviceEnabled = true;
  bool _requestingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshPermissionStatus());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Se l'utente è andato nelle impostazioni di sistema per concedere il
    // permesso (o accendere il GPS) e torna nell'app, questo lo scopre da
    // solo al rientro, senza bisogno di un pulsante "riprova" manuale.
    if (state == AppLifecycleState.resumed) unawaited(_refreshPermissionStatus());
  }

  /// Non deve mai lanciare un'eccezione non gestita: è chiamato anche solo
  /// per spiegare meglio uno stato vuoto, mai per bloccare la mappa.
  Future<void> _refreshPermissionStatus() async {
    try {
      final permission = await Geolocator.checkPermission();
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      setState(() {
        _permission = permission;
        _serviceEnabled = serviceEnabled;
      });
    } catch (_) {
      // Se il controllo stesso fallisce, si resta sul messaggio generico
      // di attesa invece di un errore: meglio poco informativo che rotto.
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _requestingPermission = true);
    try {
      final granted = await LocationTracker.instance.requestPermission();
      if (granted) unawaited(LocationTracker.instance.start());
    } catch (_) {
      // Idem: un errore qui non deve mai bloccare la UI.
    }
    await _refreshPermissionStatus();
    if (mounted) setState(() => _requestingPermission = false);
  }

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
    final peopleOrMeetingPointsChanged =
        !_samePeople(oldWidget.people, widget.people) || !_sameMeetingPoints(oldWidget.meetingPoints, widget.meetingPoints);
    final safeZonesChanged = !_sameSafeZones(oldWidget.safeZones, widget.safeZones);
    final previewChanged = !_sameLatLng(oldWidget.searchPreviewPoint, widget.searchPreviewPoint);

    // Una sola chiamata anche se più cose cambiano nello stesso momento
    // (tipico al primo avvio, quando persone e aree sicure arrivano dallo
    // stesso notifyListeners): _syncSymbols fa clearSymbols() e poi
    // riaggiunge tutto, quindi due chiamate in corsa senza coordinarsi
    // finivano per farsi cancellare i pin a vicenda — bug reale, non
    // teorico, che lasciava la mappa senza nessun pin persona.
    if (peopleOrMeetingPointsChanged || safeZonesChanged || previewChanged) {
      unawaited(_syncSymbols(fitCamera: false));
    }
    if (safeZonesChanged) {
      unawaited(_syncSafeZoneFills());
    }
    if (previewChanged) {
      final point = widget.searchPreviewPoint;
      final controller = _controller;
      if (point != null && controller != null) {
        unawaited(controller.animateCamera(CameraUpdate.newLatLngZoom(point, 16)));
      }
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

  /// LatLng non ha un operatore == personalizzato: senza questo confronto
  /// per valore, ogni rebuild della schermata (es. per un aggiornamento
  /// posizione altrui) ricrea un'istanza diversa con le stesse coordinate,
  /// che sembrerebbe "cambiata" e rifarebbe lo zoom sul risultato di
  /// ricerca ogni volta, anche da fermo.
  bool _sameLatLng(LatLng? a, LatLng? b) {
    if (a == null || b == null) return a == b;
    return a.latitude == b.latitude && a.longitude == b.longitude;
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
          a[i].kind != b[i].kind ||
          a[i].zoneType != b[i].zoneType ||
          a[i].name != b[i].name) {
        return false;
      }
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
          a[i].photoUrl != b[i].photoUrl ||
          a[i].isFuzzyLocation != b[i].isFuzzyLocation) {
        return false;
      }
    }
    return true;
  }

  /// Cosa mostrare al posto della mappa finché non c'è nessuna posizione
  /// (nemmeno la mia) da disegnare. Prima era sempre lo stesso testo
  /// passivo "in attesa della posizione": se il vero motivo è un permesso
  /// negato o il GPS spento, quel messaggio non si sarebbe mai risolto da
  /// solo, e l'utente non aveva modo di capire perché o cosa fare — da qui
  /// i pulsanti per rimediare direttamente.
  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final permission = _permission;

    String title;
    String body;
    String actionLabel;
    VoidCallback? onAction;

    if (!_serviceEnabled) {
      title = l10n.mapLocationServiceOffTitle;
      body = l10n.mapLocationServiceOffBody;
      actionLabel = l10n.mapOpenLocationSettings;
      onAction = () => unawaited(Geolocator.openLocationSettings());
    } else if (permission == LocationPermission.deniedForever) {
      title = l10n.mapLocationPermissionBlockedTitle;
      body = l10n.mapLocationPermissionBlockedBody;
      actionLabel = l10n.mapOpenAppSettings;
      onAction = () => unawaited(Geolocator.openAppSettings());
    } else if (permission == LocationPermission.denied || permission == LocationPermission.unableToDetermine) {
      title = l10n.mapLocationPermissionDeniedTitle;
      body = l10n.mapLocationPermissionDeniedBody;
      actionLabel = l10n.mapGrantPermission;
      onAction = _requestingPermission ? null : () => unawaited(_requestPermission());
    } else {
      // Permesso concesso e GPS acceso: è solo questione di aspettare il
      // primo fix, il caso genuino che il messaggio originale copriva.
      return Container(
        color: const Color(0xFFEEF1FA),
        alignment: Alignment.center,
        child: Text(l10n.mapWaitingForLocation, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      );
    }

    return Container(
      color: const Color(0xFFEEF1FA),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_rounded, size: 40, color: AppTheme.textSecondary),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onAction,
            child: _requestingPermission
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                : Text(actionLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final people = _visiblePeople;
    if (people.isEmpty) {
      return _buildEmptyState(context);
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

    final preview = widget.searchPreviewPoint;
    if (preview != null) {
      await controller.addCircle(
        CircleOptions(
          geometry: preview,
          circleRadius: 10,
          circleColor: AppTheme.accentCoral.toHex(),
          circleOpacity: 1,
          circleStrokeWidth: 3,
          circleStrokeColor: '#FFFFFF',
        ),
      );
    }

    await controller.clearSymbols();
    // Su web l'immagine viene sempre registrata come se fosse a 1x (vedi
    // commento su _avatarBitmapPixelRatio): compensiamo qui riducendo la
    // dimensione visualizzata, così il pin torna alla stessa grandezza
    // "logica" che si vede su Android/iOS invece di apparire doppio.
    final iconSize = kIsWeb ? 1 / _avatarBitmapPixelRatio : 1.0;
    for (final person in people) {
      final imageName = await _ensureAvatarImage(controller, person);
      await controller.addSymbol(
        SymbolOptions(
          geometry: LatLng(person.lat!, person.lng!),
          iconImage: imageName,
          iconSize: iconSize,
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
            iconSize: iconSize,
            iconAnchor: 'bottom',
          ),
          {'meetingPointId': point.id},
        );
      }
    }

    // Nome dell'area scritto al centro del cerchio colorato (vedi
    // _syncSafeZoneFills): prima si capiva solo toccandolo, ora si legge
    // a colpo d'occhio, verde per una sicura o rosso per una pericolosa.
    // Vive qui (non in _syncSafeZoneFills) perché condivide lo stesso
    // clearSymbols/addSymbol dei pin persona: tenerlo in un posto diverso
    // lo farebbe sparire ad ogni aggiornamento posizione.
    for (final zone in widget.safeZones) {
      await controller.addSymbol(
        SymbolOptions(
          geometry: LatLng(zone.lat, zone.lng),
          textField: zone.name,
          textSize: 12,
          textColor: zone.zoneType.color.toHex(),
          textHaloColor: '#FFFFFF',
          textHaloWidth: 1.2,
          textAnchor: 'center',
        ),
        {'zoneId': zone.id},
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
      final color = zone.zoneType.color;
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
    // All'apertura la mappa deve portarti DOVE SEI TU, non inquadrare tutta
    // la cerchia: è quello che ci si aspetta appena si apre l'app. Se la mia
    // posizione non è ancora nota si ripiega sull'inquadratura di chi c'è, e
    // il ricentraggio su di me scatta poi da solo appena arriva un fix GPS
    // fresco (vedi didUpdateWidget / _autoCenteredOnFreshFix).
    final me = _meIn(people);
    if (me?.lat != null && me?.lng != null) {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(me!.lat!, me.lng!), 15.5));
      return;
    }
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

  /// Priorità delle immagini pin, coerente con [PersonAvatar] usato nel
  /// resto dell'app: foto vera, poi avatar generativo da seed, poi avatar
  /// a tema, infine iniziali. Il download della foto può fallire (rete
  /// assente, URL scaduto): in quel caso si ripiega sotto senza bloccare
  /// la mappa, che non deve mai dipendere da una chiamata di rete extra.
  Future<String> _ensureAvatarImage(MapLibreMapController controller, Person person) async {
    final photoUrl = person.photoUrl;
    if (photoUrl != null) {
      final name = 'kinly_avatar_photo_${person.id}_${photoUrl.hashCode}';
      if (_registeredImages.contains(name)) return name;
      try {
        final bytes = await _renderAvatarPinWithPhoto(photoUrl, person.color);
        await controller.addImage(name, bytes);
        _registeredImages.add(name);
        return name;
      } catch (_) {
        // Foto non raggiungibile: si prosegue sotto con l'avatar/iniziali.
      }
    }

    final generativeKey = person.avatarKey;
    if (GenerativeAvatar.isGenerativeKey(generativeKey)) {
      final seed = GenerativeAvatar.seedFromKey(generativeKey!);
      final name = 'kinly_avatar_gen_${person.id}_$seed';
      if (!_registeredImages.contains(name)) {
        final bytes = await _renderAvatarPinWithGenerative(seed);
        await controller.addImage(name, bytes);
        _registeredImages.add(name);
      }
      return name;
    }

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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

/// Stessa forma del pin con iniziali, ma con la foto profilo vera al
/// centro (ritagliata quadrata dal centro, poi in un cerchio): coerente
/// con [PersonAvatar], che nel resto dell'app mostra la foto quando c'è.
/// Il download può lanciare un'eccezione (rete assente, URL non valido,
/// formato non decodificabile): sta a chi chiama ripiegare sull'avatar
/// a tema o sulle iniziali in quel caso.
Future<Uint8List> _renderAvatarPinWithPhoto(String photoUrl, Color tailColor) async {
  final response = await http.get(Uri.parse(photoUrl)).timeout(const Duration(seconds: 8));
  if (response.statusCode != 200) throw Exception('Foto non raggiungibile: HTTP ${response.statusCode}');
  final codec = await ui.instantiateImageCodec(response.bodyBytes);
  final frame = await codec.getNextFrame();
  final photo = frame.image;

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
  canvas.drawPath(tail, Paint()..color = tailColor);
  canvas.drawCircle(center, radius, Paint()..color = Colors.white);

  canvas.save();
  canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius * 0.92)));
  final side = min(photo.width, photo.height).toDouble();
  final srcSquare = Rect.fromCenter(center: Offset(photo.width / 2, photo.height / 2), width: side, height: side);
  final dstCircle = Rect.fromCircle(center: center, radius: radius * 0.92);
  canvas.drawImageRect(photo, srcSquare, dstCircle, Paint());
  canvas.restore();

  final picture2 = recorder.endRecording();
  final image2 = await picture2.toImage(width.round(), height.round());
  final byteData2 = await image2.toByteData(format: ui.ImageByteFormat.png);
  return byteData2!.buffer.asUint8List();
}

/// Stessa forma del pin con iniziali, ma con l'avatar generativo da seed
/// (vedi GenerativeAvatar) al centro, per chi ha scelto quello invece di
/// un avatar a tema o di una foto.
Future<Uint8List> _renderAvatarPinWithGenerative(String seed) async {
  const double circleSize = 72;
  const double tailHeight = 22;
  const double pixelRatio = 2.0;
  const width = circleSize * pixelRatio;
  const height = (circleSize + tailHeight) * pixelRatio;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const center = Offset(width / 2, (circleSize / 2) * pixelRatio);
  const radius = (circleSize / 2) * pixelRatio;
  final tailColor = GenerativeAvatar.accentColor(seed);

  final tail = Path()
    ..moveTo(center.dx - radius * 0.42, center.dy + radius * 0.82)
    ..lineTo(center.dx + radius * 0.42, center.dy + radius * 0.82)
    ..lineTo(center.dx, height)
    ..close();
  canvas.drawPath(tail, Paint()..color = tailColor);
  canvas.drawCircle(center, radius, Paint()..color = Colors.white);

  canvas.save();
  canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius * 0.92)));
  GenerativeAvatar.paint(canvas, Rect.fromCircle(center: center, radius: radius * 0.92), seed);
  canvas.restore();

  final picture3 = recorder.endRecording();
  final image3 = await picture3.toImage(width.round(), height.round());
  final byteData3 = await image3.toByteData(format: ui.ImageByteFormat.png);
  return byteData3!.buffer.asUint8List();
}
