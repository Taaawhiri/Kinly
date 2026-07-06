import 'dart:async';
import 'dart:math' show Point;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../l10n/app_localizations.dart';
import '../models/meeting_point.dart';
import '../models/person.dart';
import '../models/safe_zone.dart';
import '../services/location_tracker.dart';
import '../theme/app_theme.dart';
import '../utils/color_hex.dart';
import '../utils/geo_circle.dart';
import 'person_avatar.dart';

/// La mappa vera di Kinly: dati OpenStreetMap via OpenFreeMap (nessuna
/// chiave, nessun limite d'uso), con uno stile personalizzato nei colori
/// morbidi dell'app (vedi assets/map/kinly_style.json). Le persone sono
/// marcatori disegnati come il resto dell'app: un avatar colorato con le
/// iniziali e una piccola coda a goccia.
///
/// I pin persona/punto d'incontro NON sono simboli nativi MapLibre: sono
/// normali widget Flutter sovrapposti alla mappa (vedi _buildPersonPins/
/// _buildMeetingPointPins), riposizionati ad ogni movimento della camera
/// tramite controller.toScreenLocationBatch. Prima erano Symbol nativi, ma
/// vivono nella superficie grafica GL che Android/iOS può distruggere e
/// ricreare senza preavviso quando l'app va in background per liberare
/// memoria: qualunque logica di resync "dopo il fatto" (quella che c'era
/// prima qui) rincorre il sintomo ma non può essere davvero affidabile,
/// perché da Dart non c'è modo di sapere con certezza se la superficie è
/// sopravvissuta. Un widget Flutter invece non dipende da quella superficie
/// e il sistema operativo non può farlo sparire in quel modo: la mappa
/// nativa resta solo per le tile di sfondo, il riempimento delle aree
/// sicure e i cerchi (posizione approssimativa, anteprima ricerca), niente
/// di tutto ciò che deve restare sempre visibile in modo affidabile.
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
  bool _styleLoaded = false;

  /// Simboli etichetta area già presenti sulla mappa nativa, tenuti qui per
  /// aggiornarli sul posto (updateSymbol) invece di cancellarli e
  /// riaggiungerli. I pin persona/punto d'incontro non sono più qui: vedi
  /// il commento in testa al file.
  final Map<String, Symbol> _zoneLabelSymbols = {};

  /// Posizione a schermo (in pixel, relativa a questo widget) dell'ultimo
  /// pin persona/punto d'incontro calcolata da _updateOverlayPositions.
  /// Assente finché la prima proiezione non è arrivata, il che è normale
  /// nei primissimi istanti dopo la creazione della mappa.
  Map<String, Offset> _personScreenPositions = {};
  Map<String, Offset> _meetingPointScreenPositions = {};

  /// Coalescing delle richieste di riproiezione: onCameraMove viene chiamato
  /// molte volte durante un singolo gesto di pan/zoom, ma toScreenLocationBatch
  /// è una chiamata a canale nativo — lanciarne una per ogni tick
  /// accumulerebbe richieste in coda. Con questi due flag ne teniamo al più
  /// una in volo, e se ne arrivano altre mentre è in corso ne rilanciamo una
  /// sola appena finisce, invece di scartarle o accumularle.
  bool _positionUpdateInFlight = false;
  bool _positionUpdateQueued = false;

  /// Catena che serializza le sincronizzazioni dei livelli nativi (cerchi ed
  /// etichette area): _doSyncSymbols fa clearSymbols() sulle etichette e poi
  /// le riaggiunge, quindi due esecuzioni in corsa potrebbero accavallarsi.
  Future<void> _symbolSync = Future.value();

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
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshPermissionStatus());
      if (_styleLoaded) {
        // I pin sono widget Flutter: non dipendono dalla superficie nativa
        // e sopravvivono al resume da soli, ma la loro posizione a schermo
        // potrebbe essere cambiata (rotazione, camera diversa) mentre erano
        // in background, quindi la ricalcoliamo comunque.
        _schedulePositionUpdate();
        // Il riempimento aree sicure e le etichette testo, invece, restano
        // simboli/fill nativi: quelli sì possono essere stati cancellati
        // dal sistema operativo insieme alla superficie GL. Non possiamo
        // sapere con certezza se è successo, quindi al resume li
        // ricostruiamo sempre da zero (solo su mobile: sul web cambiare
        // scheda non distrugge la superficie).
        if (!kIsWeb) {
          unawaited(_hardResetSymbols(fitCamera: false));
          unawaited(_syncSafeZoneFills());
        }
      }
    }
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

    if (peopleOrMeetingPointsChanged || previewChanged) {
      unawaited(_syncSymbols(fitCamera: false));
    }
    if (safeZonesChanged) {
      unawaited(_syncSafeZoneFills());
      unawaited(_syncSymbols(fitCamera: false));
    }
    if (peopleOrMeetingPointsChanged) {
      _schedulePositionUpdate();
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
        color: AppTheme.surfaceAlt,
        alignment: Alignment.center,
        child: Text(l10n.mapWaitingForLocation, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      );
    }

    return Container(
      color: AppTheme.surfaceAlt,
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

    return Stack(
      children: [
        MapLibreMap(
          styleString: KinlyMap.styleAsset,
          initialCameraPosition: CameraPosition(target: LatLng(people.first.lat!, people.first.lng!), zoom: 14),
          onMapCreated: (controller) {
            _controller = controller;
            controller.onFillTapped.add(_handleFillTap);
            widget.onMapReady?.call(controller);
          },
          onStyleLoadedCallback: () async {
            _styleLoaded = true;
            // Lo stile è stato (ri)caricato: qualunque simbolo nativo
            // aggiunto prima (etichette area) non esiste più lato nativo.
            await _hardResetSymbols(fitCamera: true);
            await _syncSafeZoneFills();
          },
          // I pin sono widget Flutter sovrapposti (vedi commento in testa al
          // file): ad ogni movimento della camera ricalcoliamo dove metterli
          // a schermo, coalescendo le chiamate (vedi _schedulePositionUpdate)
          // perché durante un pan/zoom questo viene chiamato molte volte.
          onCameraMove: (_) => _schedulePositionUpdate(),
          onCameraIdle: _schedulePositionUpdate,
          compassEnabled: false,
          logoEnabled: false,
          rotateGesturesEnabled: widget.interactive,
          scrollGesturesEnabled: widget.interactive,
          zoomGesturesEnabled: widget.interactive,
          tiltGesturesEnabled: widget.interactive,
          doubleClickZoomEnabled: widget.interactive,
        ),
        ..._buildMeetingPointPins(),
        ..._buildPersonPins(people),
      ],
    );
  }

  List<Widget> _buildPersonPins(List<Person> people) {
    final pins = <Widget>[];
    for (final person in people) {
      final offset = _personScreenPositions[person.id];
      if (offset == null) continue;
      pins.add(
        Positioned(
          left: offset.dx - _PersonMapPin.avatarSize / 2,
          top: offset.dy - _PersonMapPin.avatarSize - _PersonMapPin.tailHeight,
          child: _PersonMapPin(person: person, onTap: () => widget.onPersonTap?.call(person.id)),
        ),
      );
    }
    return pins;
  }

  List<Widget> _buildMeetingPointPins() {
    final pins = <Widget>[];
    for (final point in widget.meetingPoints) {
      final offset = _meetingPointScreenPositions[point.id];
      if (offset == null) continue;
      pins.add(
        Positioned(
          left: offset.dx - _MeetingPointMapPin.size / 2,
          top: offset.dy - _MeetingPointMapPin.size - _MeetingPointMapPin.tailHeight,
          child: _MeetingPointMapPin(onTap: () => widget.onMeetingPointTap?.call(point.id)),
        ),
      );
    }
    return pins;
  }

  /// Vedi la doc su _positionUpdateInFlight/_positionUpdateQueued: incatena
  /// le richieste invece di lanciarle in parallelo.
  void _schedulePositionUpdate() {
    if (_positionUpdateInFlight) {
      _positionUpdateQueued = true;
      return;
    }
    _positionUpdateInFlight = true;
    unawaited(
      _updateOverlayPositions().whenComplete(() {
        _positionUpdateInFlight = false;
        if (_positionUpdateQueued) {
          _positionUpdateQueued = false;
          _schedulePositionUpdate();
        }
      }),
    );
  }

  /// Proietta le coordinate di persone e punti d'incontro in pixel a
  /// schermo con un'unica chiamata batch, poi aggiorna lo stato che i pin
  /// Flutter usano per posizionarsi. Un requestId scarta il risultato se nel
  /// frattempo è partita una richiesta più recente (può succedere: questa è
  /// una chiamata a canale nativo asincrona, e onCameraMove può richiamarla
  /// prima che la precedente torni).
  int _positionRequestId = 0;

  Future<void> _updateOverlayPositions() async {
    final controller = _controller;
    if (controller == null) return;
    final people = _visiblePeople;
    final points = widget.meetingPoints;
    if (people.isEmpty && points.isEmpty) {
      if (_personScreenPositions.isNotEmpty || _meetingPointScreenPositions.isNotEmpty) {
        setState(() {
          _personScreenPositions = {};
          _meetingPointScreenPositions = {};
        });
      }
      return;
    }

    final requestId = ++_positionRequestId;
    final latLngs = [
      for (final p in people) LatLng(p.lat!, p.lng!),
      for (final m in points) LatLng(m.lat, m.lng),
    ];

    List<Point> screenPoints;
    try {
      screenPoints = await controller.toScreenLocationBatch(latLngs);
    } catch (_) {
      return;
    }
    if (!mounted || requestId != _positionRequestId) return;

    final newPersonPositions = <String, Offset>{};
    for (var i = 0; i < people.length; i++) {
      final point = screenPoints[i];
      newPersonPositions[people[i].id] = Offset(point.x.toDouble(), point.y.toDouble());
    }
    final newMeetingPositions = <String, Offset>{};
    for (var i = 0; i < points.length; i++) {
      final point = screenPoints[people.length + i];
      newMeetingPositions[points[i].id] = Offset(point.x.toDouble(), point.y.toDouble());
    }

    setState(() {
      _personScreenPositions = newPersonPositions;
      _meetingPointScreenPositions = newMeetingPositions;
    });
  }

  /// Esegue le sincronizzazioni dei livelli nativi rimasti (cerchi ed
  /// etichette area) una alla volta (vedi _symbolSync).
  Future<void> _syncSymbols({required bool fitCamera}) {
    final next = _symbolSync.then((_) => _doSyncSymbols(fitCamera: fitCamera));
    _symbolSync = next.catchError((_) {});
    return next;
  }

  /// Da chiamare SOLO quando le etichette area nativa potrebbero non
  /// corrispondere più a quello che Dart crede di aver aggiunto (primo
  /// caricamento dello stile, o un resume che potrebbe aver ricreato la
  /// superficie): svuota per davvero la mappa e la bookkeeping, così la
  /// sincronizzazione successiva ricostruisce tutto da zero con addSymbol
  /// invece di provare un updateSymbol su riferimenti che potrebbero non
  /// esistere più.
  Future<void> _hardResetSymbols({required bool fitCamera}) {
    final next = _symbolSync.then((_) async {
      final controller = _controller;
      if (controller == null) return;
      _zoneLabelSymbols.clear();
      try {
        await controller.clearSymbols();
      } catch (_) {}
      await _doSyncSymbols(fitCamera: fitCamera);
    });
    _symbolSync = next.catchError((_) {});
    return next;
  }

  Future<void> _doSyncSymbols({required bool fitCamera}) async {
    final controller = _controller;
    if (controller == null) return;
    final people = _visiblePeople;

    await _syncCircles(controller, people);
    await _syncZoneLabelSymbols(controller);

    if (fitCamera) await _fitCamera(controller, people);
  }

  /// Le "nuvole" di posizione approssimativa e l'anteprima di ricerca sono
  /// poche e cambiano raramente: restano cerchi nativi, un livello separato
  /// dai pin Flutter e non toccato dal problema che li riguardava.
  Future<void> _syncCircles(MapLibreMapController controller, List<Person> people) async {
    await controller.clearCircles();
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
  }

  /// Nome dell'area scritto al centro del cerchio colorato (vedi
  /// _syncSafeZoneFills): prima si capiva solo toccandolo, ora si legge a
  /// colpo d'occhio, verde per una sicura o rosso per una pericolosa.
  Future<void> _syncZoneLabelSymbols(MapLibreMapController controller) async {
    final zones = widget.safeZones;
    final currentIds = zones.map((z) => z.id).toSet();
    final staleIds = _zoneLabelSymbols.keys.where((id) => !currentIds.contains(id)).toList();
    for (final id in staleIds) {
      final symbol = _zoneLabelSymbols.remove(id);
      if (symbol == null) continue;
      try {
        await controller.removeSymbol(symbol);
      } catch (_) {}
    }
    for (final zone in zones) {
      try {
        final options = SymbolOptions(
          geometry: LatLng(zone.lat, zone.lng),
          textField: zone.name,
          textSize: 12,
          textColor: zone.zoneType.color.toHex(),
          textHaloColor: '#FFFFFF',
          textHaloWidth: 1.2,
          textAnchor: 'center',
        );
        final existing = _zoneLabelSymbols[zone.id];
        if (existing != null) {
          await controller.updateSymbol(existing, options);
        } else {
          _zoneLabelSymbols[zone.id] = await controller.addSymbol(options, {'zoneId': zone.id});
        }
      } catch (_) {}
    }
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.onFillTapped.remove(_handleFillTap);
    super.dispose();
  }
}

/// Coda a goccia sotto il pin, così la punta (non il centro del cerchio)
/// coincide con la coordinata geografica esatta — stessa idea dei vecchi
/// pin disegnati su canvas, solo che qui è un widget vero.
class _MapPinTail extends StatelessWidget {
  const _MapPinTail({required this.color, required this.width, required this.height});

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(width, height), painter: _MapPinTailPainter(color));
  }
}

class _MapPinTailPainter extends CustomPainter {
  _MapPinTailPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.08, 0)
      ..lineTo(size.width * 0.92, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MapPinTailPainter oldDelegate) => oldDelegate.color != color;
}

/// Pin persona sulla mappa: lo stesso [PersonAvatar] usato nel resto
/// dell'app (foto, avatar generativo/a tema o iniziali, puntino di stato),
/// con una coda a goccia sotto per ancorarlo al punto esatto.
class _PersonMapPin extends StatelessWidget {
  const _PersonMapPin({required this.person, required this.onTap});

  final Person person;
  final VoidCallback? onTap;

  static const double avatarSize = 44;
  static const double tailHeight = 9;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PersonAvatar(person: person, size: avatarSize, showActivityBadge: false),
          _MapPinTail(color: person.color, width: avatarSize * 0.36, height: tailHeight),
        ],
      ),
    );
  }
}

/// Pin a bandiera per un punto d'incontro: stessa forma a goccia dei pin
/// persona, ma viola per distinguerlo a colpo d'occhio dagli avatar.
class _MeetingPointMapPin extends StatelessWidget {
  const _MeetingPointMapPin({required this.onTap});

  final VoidCallback? onTap;

  static const double size = 40;
  static const double tailHeight = 9;
  static const Color _color = Color(0xFF8A6DE7);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color,
              border: Border.all(color: Colors.white, width: size * 0.08),
              boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.35), blurRadius: size * 0.22, offset: const Offset(0, size * 0.06))],
            ),
            alignment: Alignment.center,
            child: const Text('🚩', style: TextStyle(fontSize: size * 0.5)),
          ),
          const _MapPinTail(color: _color, width: size * 0.36, height: tailHeight),
        ],
      ),
    );
  }
}
