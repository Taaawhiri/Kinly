import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:home_widget/home_widget.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/help_request.dart';
import '../../models/person.dart';
import '../../models/ping.dart';
import '../../models/safe_zone.dart';
import '../../models/shopping_stop.dart';
import '../../services/battery_optimization_service.dart';
import '../../services/crash_detection_service.dart';
import '../../services/emergency_sms_settings.dart';
import '../../services/kinly_repository.dart';
import '../../services/location_tracker.dart';
import '../../services/place_search_service.dart';
import '../../services/walk_me_home_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/blurred_bottom_sheet.dart';
import '../../widgets/circle_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/entrance_fade.dart';
import '../../widgets/kinly_map.dart';
import '../../widgets/person_list_tile.dart';
import '../../widgets/pwa_install_banner.dart';
import '../circles/meeting_point_screen.dart';
import '../people/help_request_screen.dart';
import '../people/person_detail_screen.dart';
import '../people/sos_alert_screen.dart';
import '../premium/paywall_screen.dart';
import '../premium/safe_zones_screen.dart';

class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key});

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

const double _sheetInitialSize = 0.42;
const double _sheetMinSize = 0.14;
const double _sheetMaxSize = 0.9;

/// Stessa soglia di root_shell.dart (dove si passa da bottom bar a barra
/// laterale): qui decide se mostrare "La tua cerchia" come pannello fisso
/// invece che come foglio da trascinare dal basso.
const double _wideLayoutBreakpoint = 900.0;

class _MapHomeScreenState extends State<MapHomeScreen> {
  static const _webNoticePrefKey = 'web_companion_notice_dismissed';
  static const _batteryPromptedPrefKey = 'battery_optimization_prompted';

  final _sheetController = DraggableScrollableController();
  MapLibreMapController? _mapController;
  bool _centering = false;

  /// Vero anche su mobile/desktop nativo, dove il banner non serve mai:
  /// diventa rilevante solo se kIsWeb e non e' gia' stato chiuso una volta.
  bool _webNoticeDismissed = !kIsWeb;

  /// Vero mentre un dito tocca il pannello "La tua cerchia" (per
  /// trascinarlo o scorrere la lista). Su app nativa la mappa sotto resta
  /// ferma da sola durante quel gesto; su web invece la mappa e' un
  /// elemento nativo del browser (canvas di maplibre-gl-js) che riceve i
  /// tocchi direttamente dal DOM, scavalcando l'arbitraggio dei gesti di
  /// Flutter — quindi si muove anche se visivamente e' coperta dal
  /// pannello. Qui disabilitiamo i suoi gesti finche' il pannello e' sotto
  /// al dito, invece di affidarci al solo ordine degli elementi nello Stack.
  bool _sheetPointerDown = false;

  // Ricerca indirizzo/luogo sulla mappa (es. "Esselunga via Roma 5"): stesso
  // servizio Nominatim gia' usato per i punti d'incontro (place_search_service.dart).
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<PlaceResult> _searchResults = [];
  PlaceResult? _selectedPlace;
  bool _searching = false;
  Timer? _searchDebounce;

  /// Aggiornato ad ogni build: serve fuori da build() (nell'handler globale
  /// della tastiera, che non ha un BuildContext comodo da cui leggere
  /// MediaQuery) per sapere se siamo nel layout largo da desktop.
  bool _isWideLayout = false;
  StreamSubscription<Uri?>? _widgetClickSub;

  @override
  void initState() {
    super.initState();
    // La mappa è la schermata sempre viva dell'app (IndexedStack): è il
    // posto giusto dove agganciare il conto alla rovescia del rilevamento
    // incidenti, che deve poter apparire in qualsiasi momento.
    CrashDetectionService.instance.onPossibleCrash = _showCrashCountdown;
    if (kIsWeb) unawaited(_loadWebNoticeState());
    _searchController.addListener(_onSearchChanged);
    // Scorciatoia "/" per la ricerca, come su molti siti (Gmail, GitHub…):
    // ha senso solo su web con una tastiera fisica a disposizione, non su
    // app nativa mobile. HardwareKeyboard invece di uno Shortcuts/Actions
    // legato al focus: così funziona anche quando, appena aperta la pagina,
    // nessun widget ha ancora il focus.
    if (kIsWeb) HardwareKeyboard.instance.addHandler(_handleGlobalKey);
    if (!kIsWeb) {
      unawaited(HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri));
      _widgetClickSub = HomeWidget.widgetClicked.listen(_handleWidgetUri);
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_ensureReliableTracking()));
    }
  }

  /// Perché Kinly "funzioni bene ovunque" senza che l'utente medio debba
  /// sapere nulla, alla prima apertura (una volta sola: vedi il flag)
  /// chiediamo da soli l'esclusione dal risparmio energetico di sistema —
  /// il singolo interruttore che più spesso decide se posizione e notifiche
  /// continuano ad arrivare in background su telefoni con gestione batteria
  /// aggressiva (Samsung, Xiaomi...). Il permesso notifiche viene invece
  /// già chiesto da PushNotificationService all'avvio.
  Future<void> _ensureReliableTracking() async {
    if (!Platform.isAndroid) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_batteryPromptedPrefKey) ?? false) return;
    // Segniamo subito il flag: anche se l'utente rifiuta, non lo
    // reinfastidiamo ad ogni apertura — resta comunque riproponibile a mano
    // dalla sezione Permessi in Privacy e sicurezza.
    await prefs.setBool(_batteryPromptedPrefKey, true);
    final alreadyExempt = await BatteryOptimizationService.instance.isIgnoringOptimizations();
    if (alreadyExempt || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.privacyBatteryOptimizationDialogTitle),
        content: Text(l10n.privacyBatteryOptimizationDialogBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonNotNow)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.privacyBatteryOptimizationOpen)),
        ],
      ),
    );
    if (proceed == true) {
      await BatteryOptimizationService.instance.requestIgnoreOptimizations();
    }
  }

  /// Le scorciatoie SOS/aiuto/accompagnami del widget in home aprono l'app e
  /// arrivano qui come URI (kinly://sos, .../help, .../walk): aprono solo la
  /// stessa conferma dei pulsanti in app (vedi _handleSosButton e affini),
  /// mai un'azione diretta — un tocco accidentale sul widget in tasca non
  /// deve poter far scattare un SOS vero. Toccare una riga persona nel
  /// widget arriva invece come kinly://person/<id>: centra la mappa lì,
  /// come toccare l'avatar nella lista sotto la mappa in app. Toccare
  /// l'anteprima bloccata del widget (chi non ha Kinly+) arriva come
  /// kinly://paywall: apre direttamente la pagina di Kinly+.
  void _handleWidgetUri(Uri? uri) {
    if (uri == null) return;
    final action = uri.host;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (action) {
        case 'sos':
          _handleSosButton();
        case 'help':
          _handleHelpButton();
        case 'walk':
          _onWalkMeHomeTap();
        case 'person':
          if (uri.pathSegments.isNotEmpty) {
            final person = AppState.instance.personById(uri.pathSegments.first);
            if (person != null) unawaited(_flyToPerson(person));
          }
        case 'paywall':
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
      }
    });
  }

  bool _handleGlobalKey(KeyEvent event) {
    if (!_isWideLayout || event is! KeyDownEvent) return false;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty && _selectedPlace == null) return false;
      _clearSearch();
      _searchFocusNode.unfocus();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.slash && !_searchFocusNode.hasFocus) {
      // Non rubare "/" se si sta già scrivendo in un altro campo di testo
      // (per ora non ce ne sono altri in questa pagina, ma è una guardia
      // economica da avere).
      final primary = FocusManager.instance.primaryFocus;
      if (primary != null && primary.context?.widget is EditableText) return false;
      _searchFocusNode.requestFocus();
      return true;
    }
    return false;
  }

  Future<void> _loadWebNoticeState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_webNoticePrefKey) ?? false;
    if (mounted) setState(() => _webNoticeDismissed = dismissed);
  }

  Future<void> _dismissWebNotice() async {
    setState(() => _webNoticeDismissed = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_webNoticePrefKey, true);
  }

  @override
  void dispose() {
    if (CrashDetectionService.instance.onPossibleCrash == _showCrashCountdown) {
      CrashDetectionService.instance.onPossibleCrash = null;
    }
    if (kIsWeb) HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    _widgetClickSub?.cancel();
    _sheetController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    final query = _searchController.text.trim();
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), _searchPlaces);
  }

  Future<void> _searchPlaces() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() => _searching = true);
    try {
      final results = await PlaceSearchService.instance.search(query);
      if (mounted) setState(() => _searchResults = results);
    } catch (_) {
      // Va bene restare senza risultati: si può sempre riprovare o
      // scegliere il punto a mano dal punto d'incontro.
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectSearchResult(PlaceResult result) {
    setState(() {
      _selectedPlace = result;
      _searchResults = [];
    });
    FocusScope.of(context).unfocus();
  }

  void _clearSearch() {
    setState(() {
      _selectedPlace = null;
      _searchResults = [];
      _searchController.clear();
    });
  }

  /// Chiede in quale cerchia salvarlo solo se ce ne sono più di una: stessa
  /// logica di _openMeetingPointEntry, ma qui si crea subito il punto
  /// d'incontro invece di aprire l'intera schermata di gestione.
  Future<void> _makeSearchResultMeetingPoint(PlaceResult place) async {
    final state = AppState.instance;
    final l10n = AppLocalizations.of(context)!;
    // Solo cerchie 'family': il punto d'incontro rivela una posizione, la
    // RLS lo blocca comunque in una Cerchia Eventi (che usa i Ritrovi).
    final familyCircles = state.familyCircles;
    if (familyCircles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.mapNeedCircleFirst)));
      return;
    }
    var circleId = familyCircles.any((c) => c.id == state.activeCircleId)
        ? state.activeCircleId
        : (familyCircles.length == 1 ? familyCircles.first.id : null);
    if (circleId == null) {
      circleId = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.mapWhichCircleTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
              for (final c in familyCircles)
                ListTile(
                  leading: Icon(c.icon, color: c.color),
                  title: Text(c.name),
                  onTap: () => Navigator.of(sheetContext).pop(c.id),
                ),
            ],
          ),
        ),
      );
      if (circleId == null) return;
    }
    final name = place.label.split(',').first;
    await AppState.instance.createMeetingPoint(circleId: circleId, name: name, lat: place.lat, lng: place.lng);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.mapMeetingPointAdded(name))));
      _clearSearch();
    }
  }

  Widget _buildShortcutHintPill() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(6)),
        child: Text('/', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(14),
          color: AppTheme.surface,
          child: ListenableBuilder(
            listenable: _searchFocusNode,
            builder: (context, _) {
              // Pillola "/" per far scoprire la scorciatoia da tastiera:
              // solo su desktop web, e solo quando non c'è già altro nel
              // campo suggerimento (spinner, "x" per pulire, o il fuoco).
              final showShortcutHint =
                  kIsWeb && _isWideLayout && !_searchFocusNode.hasFocus && !_searching && _searchController.text.isEmpty;
              return TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: l10n.mapSearchHint,
                  hintStyle: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
                  prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : (_searchController.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: _clearSearch)
                          : (showShortcutHint ? _buildShortcutHintPill() : null)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: AppTheme.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              );
            },
          ),
        ),
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = _searchResults[i];
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.place_outlined, color: AppTheme.textSecondary, size: 20),
                  title: Text(r.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  onTap: () => _selectSearchResult(r),
                );
              },
            ),
          ),
        if (_selectedPlace != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.place_rounded, color: AppTheme.accentCoral, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedPlace!.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: _clearSearch,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => _makeSearchResultMeetingPoint(_selectedPlace!),
                  icon: const Icon(Icons.share_location_rounded, size: 18),
                  label: Text(l10n.mapMakeMeetingPoint),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _centerOnMyLocation() async {
    setState(() => _centering = true);
    try {
      // forceRefresh (non solo getCurrentPosition) così, oltre a muovere la
      // mappa, aggiorna subito anche il MIO pin alla posizione attuale:
      // prima la mappa si spostava dove ero davvero ma il pin restava
      // fermo sull'ultima posizione salvata.
      final position = await LocationTracker.instance.forceRefresh() ?? await Geolocator.getCurrentPosition();
      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 15));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.mapLocationUnavailable)));
      }
    } finally {
      if (mounted) setState(() => _centering = false);
    }
  }

  /// Toccare l'avatar nella lista "La tua cerchia" centra la mappa lì
  /// invece di aprire la scheda persona (che resta un tocco sul resto
  /// della riga): il foglio si restringe un po' per lasciar vedere la
  /// mappa appena centrata invece di restare sopra a coprirla.
  Future<void> _flyToPerson(Person person) async {
    final lat = person.lat;
    final lng = person.lng;
    if (lat == null || lng == null) return;
    unawaited(_sheetController.animateTo(_sheetMinSize, duration: const Duration(milliseconds: 300), curve: Curves.easeOut));
    await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15));
  }

  Future<void> _confirmAndTriggerSos() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.mapSosConfirmTitle),
        content: Text(l10n.mapSosConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentCoral),
            child: Text(l10n.mapActivateSos),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition();
      await AppState.instance.triggerSos(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      if (!mounted) return;
      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.mapLocationUnavailableForSos)));
      } else {
        // Posizione trovata ma invio fallito: probabilmente non c'è
        // internet. Proponi il piano B via SMS, se un numero è configurato.
        await _offerSmsFallback(position);
      }
    }
  }

  /// SOS via SMS quando internet non c'è: apre l'app SMS con destinatario e
  /// testo (coordinate + link mappa) già compilati — l'invio lo confermi tu.
  Future<void> _offerSmsFallback(Position position) async {
    final l10n = AppLocalizations.of(context)!;
    final number = await EmergencySmsSettings.instance.getNumber();
    if (!mounted) return;
    if (number == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.mapSosNotSentOffline),
      ));
      return;
    }
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.mapNoInternetSosSmsTitle),
        content: Text(l10n.mapNoInternetSosSmsBody(number)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonNo)),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentCoral),
            child: Text(l10n.mapPrepareSms),
          ),
        ],
      ),
    );
    if (send != true) return;
    final body = Uri.encodeComponent(
      'SOS da Kinly! Ho bisogno di aiuto. La mia posizione: '
      'https://maps.google.com/?q=${position.latitude},${position.longitude}',
    );
    final uri = Uri.parse('sms:$number?body=$body');
    await launchUrl(uri);
  }

  // -----------------------------------------------------------------------
  // "Accompagnami": sessione a tempo con avviso automatico se non confermi.
  // -----------------------------------------------------------------------

  void _onWalkMeHomeTap() {
    final l10n = AppLocalizations.of(context)!;
    final walk = WalkMeHomeService.instance;
    if (walk.isActive) {
      final remaining = walk.remaining.inMinutes + 1;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(l10n.mapWalkMeHomeActiveTitle),
          content: Text(l10n.mapWalkMeHomeActiveBody(remaining)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonClose)),
            FilledButton(
              onPressed: () {
                walk.confirmArrival();
                Navigator.of(context).pop();
              },
              child: Text(l10n.mapArrived),
            ),
          ],
        ),
      );
      return;
    }

    final state = AppState.instance;
    // Solo cerchie 'family': Portami a casa può generare una richiesta di
    // aiuto, che rivela una posizione.
    final familyCircles = state.familyCircles;
    if (familyCircles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.mapNeedCircleFirst)));
      return;
    }
    final circleId = familyCircles.any((c) => c.id == state.activeCircleId) ? state.activeCircleId! : familyCircles.first.id;
    showBlurredModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(sheetContext)!.mapWalkMeHomeTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(sheetContext)!.mapWalkMeHomeDescription,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final minutes in [10, 20, 30, 45, 60])
                    ActionChip(
                      label: Text(AppLocalizations.of(sheetContext)!.mapWalkMeHomeMinutes(minutes)),
                      onPressed: () {
                        WalkMeHomeService.instance.start(duration: Duration(minutes: minutes), circleId: circleId);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(sheetContext)!.mapWalkMeHomeNote,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Rilevamento incidenti: conto alla rovescia prima dell'SOS automatico.
  // -----------------------------------------------------------------------

  void _showCrashCountdown() {
    if (!mounted) return;
    var secondsLeft = 30;
    var cancelled = false;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          if (secondsLeft > 0 && !cancelled) {
            Future.delayed(const Duration(seconds: 1), () {
              if (cancelled) return;
              secondsLeft -= 1;
              if (secondsLeft <= 0) {
                Navigator.of(dialogContext).pop();
                unawaited(_triggerSosFromCrash());
              } else {
                setDialogState(() {});
              }
            });
          }
          final l10n = AppLocalizations.of(dialogContext)!;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(l10n.mapCrashDetectedTitle),
            content: Text(l10n.mapCrashDetectedBody(secondsLeft)),
            actions: [
              FilledButton(
                onPressed: () {
                  cancelled = true;
                  Navigator.of(dialogContext).pop();
                },
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: Text(l10n.mapImFine),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _triggerSosFromCrash() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      await AppState.instance.triggerSos(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      final me = AppState.instance.me;
      if (me.lat != null && me.lng != null) {
        try {
          await AppState.instance.triggerSos(lat: me.lat!, lng: me.lng!);
        } catch (_) {
          // Offline: non c'è altro da fare in automatico.
        }
      }
    }
  }

  // -----------------------------------------------------------------------
  // Link "seguimi" per chi non ha l'app.
  // -----------------------------------------------------------------------

  void _openLiveShareSheet() {
    showBlurredModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(sheetContext)!.mapShareLocationLinkTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(sheetContext)!.mapShareLocationLinkBody,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, duration) in [
                    (AppLocalizations.of(sheetContext)!.mapDuration1h, Duration(hours: 1)),
                    (AppLocalizations.of(sheetContext)!.mapDuration3h, Duration(hours: 3)),
                    (AppLocalizations.of(sheetContext)!.mapDuration24h, Duration(hours: 24)),
                  ])
                    ActionChip(
                      label: Text(label),
                      onPressed: () async {
                        final l10n = AppLocalizations.of(context)!;
                        Navigator.of(sheetContext).pop();
                        try {
                          final url = await KinlyRepository.instance.createLiveShareLink(duration);
                          await Share.share(l10n.mapShareLiveMessage(label, url));
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.mapLinkCreateError)));
                          }
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMeetingPointEntry() {
    final state = AppState.instance;
    // Solo cerchie 'family': in una Cerchia Eventi il punto d'incontro è
    // sostituito dai Ritrovi.
    final familyCircles = state.familyCircles;
    final circle = state.activeCircleId != null && familyCircles.any((c) => c.id == state.activeCircleId)
        ? state.circleById(state.activeCircleId!)
        : (familyCircles.length == 1 ? familyCircles.first : null);
    if (circle != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => MeetingPointScreen(circle: circle)));
      return;
    }
    if (familyCircles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.mapNeedCircleFirst)));
      return;
    }
    showBlurredModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(alignment: Alignment.centerLeft, child: Text(AppLocalizations.of(sheetContext)!.mapWhichCircleForMeetingPoint, style: const TextStyle(fontWeight: FontWeight.w800))),
            ),
            for (final c in familyCircles)
              ListTile(
                leading: Icon(c.icon, color: c.color),
                title: Text(c.name),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => MeetingPointScreen(circle: c)));
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool _hasAnyBanner(AppState state) {
    return state.activeSosAlerts.any((a) => a.profileId != state.me.id) ||
        state.activeHelpRequests.any((h) => h.profileId != state.me.id) ||
        state.recentEncounters.isNotEmpty ||
        state.incomingPings.isNotEmpty ||
        state.othersActiveShoppingStops.isNotEmpty ||
        (state.myActiveShoppingStop != null && state.requestsForStop(state.myActiveShoppingStop!.id).isNotEmpty) ||
        WalkMeHomeService.instance.isActive;
  }

  void _openMeetingPointInfo(String meetingPointId) {
    final state = AppState.instance;
    final point = state.meetingPointById(meetingPointId);
    if (point == null) return;
    final circle = state.circleById(point.circleId);
    if (circle != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => MeetingPointScreen(circle: circle)));
    }
  }

  void _openSafeZoneInfo(String zoneId) {
    final state = AppState.instance;
    final zone = state.safeZoneById(zoneId);
    if (zone == null) return;
    final circle = state.circleById(zone.circleId);
    showBlurredModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: zone.zoneType.color.withOpacity(0.15)),
                    alignment: Alignment.center,
                    child: Icon(zone.kind.icon, color: zone.zoneType.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(zone.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                        Text(AppLocalizations.of(sheetContext)!.mapSafeZoneLabelAndRadius(zone.kind.label(AppLocalizations.of(sheetContext)!), zone.radiusMeters), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
              if (circle != null) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SafeZonesScreen(circle: circle)));
                  },
                  icon: const Icon(Icons.fence_rounded, size: 18),
                  label: Text(AppLocalizations.of(sheetContext)!.mapManageSafeZones),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openHelpRequestSheet() {
    showBlurredModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => const _HelpRequestSheet(),
    );
  }

  /// Usata sia dal pulsante SOS in app sia dalla scorciatoia SOS del widget
  /// in home (vedi _handleWidgetUri): se un SOS è già attivo mostra quello,
  /// altrimenti apre la conferma — mai un invio diretto.
  void _handleSosButton() {
    final state = AppState.instance;
    final mySos = state.myActiveSos;
    if (mySos != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SosAlertScreen(alert: mySos, person: state.me)),
      );
    } else {
      _confirmAndTriggerSos();
    }
  }

  /// Vedi [_handleSosButton]: stessa logica, per la richiesta di aiuto.
  void _handleHelpButton() {
    final state = AppState.instance;
    final mine = state.myActiveHelpRequest;
    if (mine != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HelpRequestScreen(request: mine, person: state.me)),
      );
    } else {
      _openHelpRequestSheet();
    }
  }

  Widget _buildEmergencyActions(AppState state) {
    return _EmergencyActionsGroup(
      sosActive: state.myActiveSos != null,
      helpActive: state.myActiveHelpRequest != null,
      walkActive: WalkMeHomeService.instance.isActive,
      onWalkTap: _onWalkMeHomeTap,
      onSosTap: _handleSosButton,
      onHelpTap: _handleHelpButton,
    );
  }

  Widget _buildBanners(AppState state) {
    final someone = AppLocalizations.of(context)!.commonSomeone;
    return Column(
      children: [
        if (WalkMeHomeService.instance.isActive)
          _WalkMeHomeBanner(
            remaining: WalkMeHomeService.instance.remaining,
            onArrived: () => WalkMeHomeService.instance.confirmArrival(),
          ),
        for (final alert in state.activeSosAlerts.where((a) => a.profileId != state.me.id))
          EntranceFade(
            key: ValueKey('sos_${alert.id}'),
            child: _SosBanner(
              personName: state.personById(alert.profileId)?.name ?? someone,
              onTap: () {
                final person = state.personById(alert.profileId);
                if (person != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SosAlertScreen(alert: alert, person: person)),
                  );
                }
              },
            ),
          ),
        for (final request in state.activeHelpRequests.where((h) => h.profileId != state.me.id))
          EntranceFade(
            key: ValueKey('help_${request.id}'),
            child: _HelpBanner(
              personName: state.personById(request.profileId)?.name ?? someone,
              reasonLabel: request.reason.label(AppLocalizations.of(context)!),
              onTap: () {
                final person = state.personById(request.profileId);
                if (person != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => HelpRequestScreen(request: request, person: person)),
                  );
                }
              },
            ),
          ),
        for (final encounter in state.recentEncounters)
          _EncounterBanner(
            personName: state.personById(encounter.otherPersonId(state.me.id))?.name ?? someone,
            onHighFive: () {
              state.sendPing(toId: encounter.otherPersonId(state.me.id), kind: PingKind.highFive);
              state.dismissEncounter(encounter.id);
            },
            onDismiss: () => state.dismissEncounter(encounter.id),
          ),
        for (final ping in state.incomingPings)
          _PingBanner(
            personName: state.personById(ping.fromId)?.name ?? someone,
            kind: ping.kind,
            onDismiss: () => state.dismissPing(ping.id),
            onReply: ping.kind == PingKind.checkIn
                ? () {
                    state.sendPing(toId: ping.fromId, kind: PingKind.allGood);
                    state.dismissPing(ping.id);
                  }
                : null,
          ),
        for (final stop in state.othersActiveShoppingStops)
          _ShoppingStopBanner(
            personName: state.personById(stop.profileId)?.name ?? someone,
            stop: stop,
            onSend: (note) => state.sendShoppingRequest(stopId: stop.id, note: note),
          ),
        if (state.myActiveShoppingStop != null && state.requestsForStop(state.myActiveShoppingStop!.id).isNotEmpty)
          _MyShoppingRequestsBanner(
            requests: state.requestsForStop(state.myActiveShoppingStop!.id),
            nameFor: (id) => state.personById(id)?.name ?? someone,
          ),
        const PwaInstallBanner(),
      ],
    );
  }

  Widget _buildCircleChipsRow(AppState state) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                CircleChip(
                  label: AppLocalizations.of(context)!.mapAllCirclesChip,
                  isSelected: state.activeCircleId == null,
                  onTap: () => state.setActiveCircle(null),
                ),
                const SizedBox(width: 8),
                for (final c in state.circles) ...[
                  CircleChip(
                    label: c.name,
                    icon: c.icon,
                    color: c.color,
                    isSelected: state.activeCircleId == c.id,
                    onTap: () => state.setActiveCircle(c.id),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _CenterOnMeButton(loading: _centering, onTap: _centerOnMyLocation),
          ),
        ],
      ),
    );
  }

  /// Intestazione + lista della cerchia: usata sia dentro il pannello
  /// trascinabile su mobile sia nel pannello laterale fisso su schermi
  /// larghi. [scrollController] arriva dal DraggableScrollableSheet solo
  /// nel primo caso: senza, la lista usa il proprio scroll indipendente.
  Widget _buildCircleListBody(List<Person> people, {ScrollController? scrollController}) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Text(l10n.mapYourCircle, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
              const Spacer(),
              Text(l10n.mapPeopleCount(people.length), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
              // Un solo "+" con le due azioni scritte per esteso nel menu,
              // invece di due icone senza testo affiancate: stesso numero di
              // tocchi, ma non c'è più niente da imparare a memoria.
              PopupMenuButton<VoidCallback>(
                icon: Icon(Icons.add_circle_outline_rounded, size: 22, color: AppTheme.primary),
                tooltip: '',
                onSelected: (action) => action(),
                itemBuilder: (context) => [
                  PopupMenuItem<VoidCallback>(
                    value: _openMeetingPointEntry,
                    child: Row(
                      children: [
                        Icon(Icons.add_location_alt_outlined, size: 18, color: AppTheme.textSecondary),
                        const SizedBox(width: 12),
                        Text(l10n.mapNewMeetingPointTooltip),
                      ],
                    ),
                  ),
                  PopupMenuItem<VoidCallback>(
                    value: _openLiveShareSheet,
                    child: Row(
                      children: [
                        Icon(Icons.link_rounded, size: 18, color: AppTheme.textSecondary),
                        const SizedBox(width: 12),
                        Text(l10n.mapShareLocationLinkTooltip),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: people.isEmpty
              // Anche vuoto, deve restare un ListView con lo stesso
              // scrollController del DraggableScrollableSheet: è da lì
              // che il foglio capisce il gesto di trascinamento su/giù.
              // Un Center al posto della lista lo disconnetterebbe.
              ? ListView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  children: [
                    EmptyStateView(
                      icon: Icons.person_add_alt_1_rounded,
                      title: l10n.mapEmptyCircleTitle,
                      message: l10n.mapEmptyCircleMessage,
                    ),
                  ],
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: people.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = people[i];
                    return PersonListTile(
                      person: p,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: p.id)),
                      ),
                      onAvatarTap: (p.lat != null && p.lng != null) ? () => _flyToPerson(p) : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMap(AppState state, List<Person> people, {bool interactive = true}) {
    return Listener(
      // Toccare/trascinare la mappa toglie il focus dalla barra di ricerca:
      // altrimenti restava aperta e la tastiera occupava lo schermo anche
      // dopo aver smesso di cercare. Usiamo Listener (eventi di puntamento
      // "grezzi") invece di GestureDetector(onPanDown: ...): quest'ultimo
      // registra un vero riconoscitore di pan che entra in competizione
      // nell'arena dei gesti con il pan nativo della mappa (una PlatformView
      // sotto al cofano), impedendole a volte di rispondere al trascinamento
      // con le dita — molto più evidente quando la mappa è già zoomata
      // larga per inquadrare più persone, dove un pan solo parzialmente
      // funzionante sembra completamente bloccato. Listener non entra mai
      // nell'arena dei gesti: non compete con nulla.
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _searchFocusNode.unfocus(),
      child: KinlyMap(
        people: [state.me, ...people.where((p) => p.isSharingWithMe)],
        safeZones: state.visibleSafeZones(),
        meetingPoints: state.visibleMeetingPoints(),
        interactive: interactive,
        onPersonTap: (personId) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: personId)),
        ),
        onMapReady: (controller) => _mapController = controller,
        onMeetingPointTap: (id) => _openMeetingPointInfo(id),
        onSafeZoneTap: (id) => _openSafeZoneInfo(id),
        searchPreviewPoint: _selectedPlace != null ? LatLng(_selectedPlace!.lat, _selectedPlace!.lng) : null,
      ),
    );
  }

  /// Layout mobile/stretto: mappa a schermo intero con il pannello "La tua
  /// cerchia" trascinabile dal basso, come una vera app.
  Widget _buildNarrowLayout(BuildContext context, AppState state, List<Person> people) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildMap(state, people, interactive: !(kIsWeb && _sheetPointerDown)),
            // Sfoca la mappa man mano che trascini su il pannello "La tua
            // cerchia" oltre la sua altezza di riposo: l'attenzione si
            // sposta sulla lista senza uno scatto netto. IgnorePointer evita
            // che questo livello (trasparente, sopra la mappa) rubi i gesti
            // di pan/zoom quando non sta sfocando nulla.
            AnimatedBuilder(
              animation: _sheetController,
              builder: (context, child) {
                final extent = _sheetController.isAttached ? _sheetController.size : _sheetInitialSize;
                final t = ((extent - _sheetInitialSize) / (_sheetMaxSize - _sheetInitialSize)).clamp(0.0, 1.0);
                if (t <= 0) return const SizedBox.shrink();
                return IgnorePointer(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6 * t, sigmaY: 6 * t),
                    child: Container(color: Colors.transparent),
                  ),
                );
              },
            ),
            if (!_webNoticeDismissed)
              SafeArea(
                // Sotto la barra di ricerca, non sopra (altrimenti finiscono
                // incollati uno sull'altro) e con lo stesso margine destro
                // della barra di ricerca: su schermi stretti (mobile web)
                // senza quel margine finiva largo quanto lo schermo, sotto
                // la pillola SOS/Aiuto/Accompagnami a destra — la "X" per
                // chiuderlo restava così coperta e non cliccabile.
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 78, 92, 0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: _WebCompanionNotice(onDismiss: _dismissWebNotice),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 92, 0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _buildSearchBar(),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                  child: _buildEmergencyActions(state),
                ),
              ),
            ),
            if (_hasAnyBanner(state))
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 130, 16, 0),
                  child: _buildBanners(state),
                ),
              ),
            // La barra delle cerchie e il pulsante GPS seguono insieme il
            // bordo superiore del pannello, alla stessa altezza: quando lo
            // trascini giù, scendono anche loro, invece di restare fermi in
            // mezzo alla mappa.
            AnimatedBuilder(
              animation: _sheetController,
              builder: (context, child) {
                final extent = _sheetController.isAttached ? _sheetController.size : _sheetInitialSize;
                final sheetTop = constraints.maxHeight * (1 - extent);
                return Positioned(left: 0, right: 0, top: sheetTop - 52, child: child!);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _buildCircleChipsRow(state),
              ),
            ),
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: _sheetInitialSize,
              minChildSize: _sheetMinSize,
              maxChildSize: _sheetMaxSize,
              // Niente snap: il pannello resta esattamente dove lo lasci.
              // Con lo snap attivo, un trascinamento verso il basso non
              // abbastanza deciso tornava indietro al punto di partenza
              // invece di ridursi — sembrava "bloccato".
              builder: (context, scrollController) {
                // Solo su web: mentre un dito e' sopra al pannello (per
                // trascinarlo o scorrere la lista), spegniamo i gesti della
                // mappa sotto — vedi il commento su _sheetPointerDown.
                // Listener e non GestureDetector: osserva i tocchi senza
                // "reclamarli", quindi non interferisce con lo scroll della
                // lista o col trascinamento del foglio.
                return Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: kIsWeb ? (_) => setState(() => _sheetPointerDown = true) : null,
                  onPointerUp: kIsWeb ? (_) => setState(() => _sheetPointerDown = false) : null,
                  onPointerCancel: kIsWeb ? (_) => setState(() => _sheetPointerDown = false) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 6),
                        Expanded(child: _buildCircleListBody(people, scrollController: scrollController)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Layout desktop/largo: pannello "La tua cerchia" sempre visibile a
  /// fianco della mappa, invece che sopra come un foglio da trascinare —
  /// su un monitor non ha senso dover "tirare su" qualcosa che ci sta già
  /// comodamente accanto.
  Widget _buildWideLayout(BuildContext context, AppState state, List<Person> people) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildMap(state, people),
              if (!_webNoticeDismissed)
                SafeArea(
                  // Sotto la barra di ricerca, non sopra: alla stessa
                  // altezza finivano incollati uno sull'altro, illeggibili
                  // entrambi.
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 78, 16, 0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _WebCompanionNotice(onDismiss: _dismissWebNotice),
                      ),
                    ),
                  ),
                ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: _buildSearchBar(),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                    child: _buildEmergencyActions(state),
                  ),
                ),
              ),
              if (_hasAnyBanner(state))
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 130, 16, 0),
                      child: SizedBox(width: 360, child: _buildBanners(state)),
                    ),
                  ),
                ),
              // In basso, come una barra dei filtri sopra la mappa: in alto
              // sarebbe stata la prima cosa vista e, per un bug di layout,
              // finiva per coprire l'intera mappa invece di stare al suo
              // posto (Align qui e' anche la parte che lo risolve: senza,
              // dentro uno Stack a schermo intero questi widget si espandono
              // a riempire tutto lo spazio disponibile).
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildCircleChipsRow(state),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 360,
          child: Material(
            color: AppTheme.surface,
            elevation: 4,
            child: SafeArea(
              left: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildCircleListBody(people),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppState.instance, WalkMeHomeService.instance]),
      builder: (context, _) {
        final state = AppState.instance;
        final people = state.visiblePeople();
        final isWide = MediaQuery.sizeOf(context).width >= _wideLayoutBreakpoint;
        _isWideLayout = isWide;

        return Scaffold(
          body: isWide ? _buildWideLayout(context, state, people) : _buildNarrowLayout(context, state, people),
        );
      },
    );
  }
}

/// SOS e Aiuto raggruppati in un'unica "pillola" verticale sul bordo destro
/// della mappa: più discreta di due cerchi colorati separati, ma con SOS
/// comunque riconoscibile in cima e in rosso pieno quando attivo.
/// Avviso mostrato solo sulla versione web (kIsWeb): spiega che qui Kinly e'
/// una "versione compagna" e non puo' replicare il tracciamento in
/// background, che su un sito web nessun browser puo' garantire ad app
/// chiusa. Si chiude una volta sola e resta chiuso (SharedPreferences).
class _WebCompanionNotice extends StatelessWidget {
  const _WebCompanionNotice({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.language_rounded, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.mapWebNotice,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, size: 16, color: AppTheme.textSecondary),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

class _EmergencyActionsGroup extends StatelessWidget {
  const _EmergencyActionsGroup({
    required this.sosActive,
    required this.helpActive,
    required this.walkActive,
    required this.onSosTap,
    required this.onHelpTap,
    required this.onWalkTap,
  });

  final bool sosActive;
  final bool helpActive;
  final bool walkActive;
  final VoidCallback onSosTap;
  final VoidCallback onHelpTap;
  final VoidCallback onWalkTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EmergencyActionButton(
            icon: Icons.emergency_rounded,
            color: AppTheme.accentCoral,
            active: sosActive,
            label: l10n.mapQuickActionSosLabel,
            activeLabel: l10n.mapSosActiveLabel,
            semanticLabel: l10n.mapActivateSosSemantic,
            onTap: onSosTap,
            topRadius: 18,
          ),
          Container(height: 1, width: 46, color: AppTheme.divider),
          _EmergencyActionButton(
            icon: Icons.pan_tool_alt_rounded,
            color: AppTheme.accentAmber,
            active: helpActive,
            label: l10n.mapQuickActionHelpLabel,
            activeLabel: l10n.mapHelpRequestedLabel,
            semanticLabel: l10n.mapAskForHelp,
            onTap: onHelpTap,
          ),
          Container(height: 1, width: 46, color: AppTheme.divider),
          _EmergencyActionButton(
            icon: Icons.directions_walk_rounded,
            color: AppTheme.primary,
            active: walkActive,
            label: l10n.mapQuickActionWalkLabel,
            activeLabel: l10n.mapWalkMeHomeActiveLabel,
            semanticLabel: l10n.mapWalkMeHomeSemantic,
            onTap: onWalkTap,
            bottomRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _EmergencyActionButton extends StatelessWidget {
  const _EmergencyActionButton({
    required this.icon,
    required this.color,
    required this.active,
    required this.label,
    required this.activeLabel,
    required this.semanticLabel,
    required this.onTap,
    this.topRadius = 0,
    this.bottomRadius = 0,
  });

  final IconData icon;
  final Color color;
  final bool active;

  /// Didascalia sempre visibile sotto l'icona: prima erano solo icone
  /// colorate distinguibili solo per tinta, con un tooltip che si scopre
  /// solo con un tocco lungo (quasi nessuno lo trova) — in un momento di
  /// emergenza non è il momento di indovinare quale pulsante è quale.
  final String label;
  final String activeLabel;
  final String semanticLabel;
  final VoidCallback onTap;
  final double topRadius;
  final double bottomRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(top: Radius.circular(topRadius), bottom: Radius.circular(bottomRadius));
    return Material(
      color: active ? color.withOpacity(0.12) : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Semantics(
            label: active ? activeLabel : semanticLabel,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: color, size: 22),
                    if (active)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SosBanner extends StatelessWidget {
  const _SosBanner({required this.personName, required this.onTap});
  final String personName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.accentCoral,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppTheme.accentCoral.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.mapSosBannerText(personName),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpBanner extends StatelessWidget {
  const _HelpBanner({required this.personName, required this.reasonLabel, required this.onTap});
  final String personName;
  final String reasonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.accentAmber,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.pan_tool_alt_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.mapHelpBannerText(personName, reasonLabel),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalkMeHomeBanner extends StatelessWidget {
  const _WalkMeHomeBanner({required this.remaining, required this.onArrived});
  final Duration remaining;
  final VoidCallback onArrived;

  @override
  Widget build(BuildContext context) {
    final minutes = remaining.inMinutes + 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_walk_rounded, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.mapWalkMeHomeBannerText(minutes),
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.textPrimary),
            ),
          ),
          TextButton(onPressed: onArrived, child: Text(AppLocalizations.of(context)!.mapArrived)),
        ],
      ),
    );
  }
}

class _EncounterBanner extends StatelessWidget {
  const _EncounterBanner({required this.personName, required this.onHighFive, required this.onDismiss});
  final String personName;
  final VoidCallback onHighFive;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3)),
      ]),
      child: Row(
        children: [
          const Text('🖐️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.mapEncounterText(personName),
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.textPrimary),
            ),
          ),
          TextButton(onPressed: onHighFive, child: Text(AppLocalizations.of(context)!.mapHighFive)),
          IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: onDismiss, visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}

class _PingBanner extends StatelessWidget {
  const _PingBanner({required this.personName, required this.kind, required this.onDismiss, this.onReply});
  final String personName;
  final PingKind kind;
  final VoidCallback onDismiss;

  /// Presente solo per un ping "tutto bene?": risposta con un tocco, senza
  /// dover aprire una scheda o scrivere nulla.
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3)),
      ]),
      child: Row(
        children: [
          Text(kind.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$personName: ${kind.label(l10n)}',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.textPrimary),
            ),
          ),
          if (onReply != null)
            TextButton(onPressed: onReply, child: Text(l10n.pingReplyAllGood)),
          IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: onDismiss, visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}

class _ShoppingStopBanner extends StatefulWidget {
  const _ShoppingStopBanner({required this.personName, required this.stop, required this.onSend});
  final String personName;
  final ShoppingStop stop;
  final ValueChanged<String> onSend;

  @override
  State<_ShoppingStopBanner> createState() => _ShoppingStopBannerState();
}

class _ShoppingStopBannerState extends State<_ShoppingStopBanner> {
  final _controller = TextEditingController();
  bool _expanded = false;
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final note = _controller.text.trim();
    if (note.isEmpty) return;
    widget.onSend(note);
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.stop.placeName != null ? ' (${widget.stop.placeName})' : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3)),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🛒', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.mapShoppingAtStore(widget.personName, place),
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.textPrimary),
                ),
              ),
              if (_sent)
                const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 18)
              else
                TextButton(onPressed: () => setState(() => _expanded = !_expanded), child: Text(AppLocalizations.of(context)!.mapAskSomething)),
            ],
          ),
          if (_expanded && !_sent) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.mapShoppingHint,
                      filled: true,
                      fillColor: AppTheme.surfaceAlt,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send_rounded, size: 18), onPressed: _send),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MyShoppingRequestsBanner extends StatelessWidget {
  const _MyShoppingRequestsBanner({required this.requests, required this.nameFor});
  final List<ShoppingRequest> requests;
  final String Function(String) nameFor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.mapTheyAskedFor, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          for (final r in requests)
            Text(AppLocalizations.of(context)!.mapShoppingRequestLine(nameFor(r.fromId), r.note), style: TextStyle(fontSize: 12.5, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.reason, required this.selected, required this.onTap});
  final HelpRequestReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentAmber.withOpacity(0.14) : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.accentAmber : Colors.transparent, width: 1.6),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentAmber.withOpacity(selected ? 0.3 : 0.15)),
              alignment: Alignment.center,
              child: Icon(reason.icon, size: 17, color: AppTheme.accentAmber),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                reason.label(AppLocalizations.of(context)!),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpRequestSheet extends StatefulWidget {
  const _HelpRequestSheet();

  @override
  State<_HelpRequestSheet> createState() => _HelpRequestSheetState();
}

class _CenterOnMeButton extends StatelessWidget {
  const _CenterOnMeButton({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: loading ? null : onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2))
              : SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GpsIconPainter(color: AppTheme.primary))),
        ),
      ),
    );
  }
}

/// Icona GPS disegnata a mano invece di usare un glifo Material: i glifi
/// "my_location"/"gps_fixed" hanno il punto centrale otticamente decentrato
/// nel loro riquadro, visibile proprio dentro un pulsante circolare piccolo.
/// Disegnando noi il cerchio e il puntino sullo stesso centro esatto del
/// canvas, la centratura è garantita. Niente tacche a croce intorno
/// all'anello: con quelle sembra un mirino invece della classica icona
/// "centra sulla mia posizione".
class _GpsIconPainter extends CustomPainter {
  const _GpsIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(center, 5.5, ringPaint);
    canvas.drawCircle(center, 2.6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _GpsIconPainter oldDelegate) => oldDelegate.color != color;
}

class _HelpRequestSheetState extends State<_HelpRequestSheet> {
  final _noteController = TextEditingController();
  HelpRequestReason _reason = HelpRequestReason.flatTire;
  String? _circleId;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final state = AppState.instance;
    // Solo cerchie 'family': una richiesta di aiuto rivela una posizione,
    // la RLS la blocca comunque in una Cerchia Eventi.
    final familyCircles = state.familyCircles;
    _circleId = familyCircles.any((c) => c.id == state.activeCircleId)
        ? state.activeCircleId
        : (familyCircles.isNotEmpty ? familyCircles.first.id : null);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final circleId = _circleId;
    if (circleId == null) {
      setState(() => _error = AppLocalizations.of(context)!.mapNeedCircleForHelp);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final position = await Geolocator.getCurrentPosition();
      await AppState.instance.triggerHelpRequest(
        circleId: circleId,
        reason: _reason,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        lat: position.latitude,
        lng: position.longitude,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.mapHelpRequestSendError);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final l10n = AppLocalizations.of(context)!;
    final familyCircles = state.familyCircles;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.mapAskForHelp, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text(
              l10n.mapHelpRequestDescription,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (familyCircles.length > 1) ...[
              Text(l10n.mapCircleLabel, style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final circle in familyCircles)
                    ChoiceChip(
                      label: Text(circle.name),
                      selected: _circleId == circle.id,
                      onSelected: (_) => setState(() => _circleId = circle.id),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Text(l10n.mapReasonLabel, style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
              children: [
                for (final reason in HelpRequestReason.values) _ReasonCard(reason: reason, selected: _reason == reason, onTap: () => setState(() => _reason = reason)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLength: 140,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.mapNoteHint,
                filled: true,
                fillColor: AppTheme.surfaceAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppTheme.accentCoral, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _sending ? null : _send,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: AppTheme.accentAmber),
              child: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Text(l10n.mapSendRequest),
            ),
          ],
        ),
      ),
    );
  }
}
