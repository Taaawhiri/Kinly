import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/circle_expense.dart';
import '../models/circle_group.dart';
import '../models/circle_message.dart';
import '../models/encounter.dart';
import '../models/help_request.dart';
import '../models/location_history_point.dart';
import '../models/location_request.dart';
import '../models/meeting_point.dart';
import '../models/person.dart';
import '../models/ping.dart';
import '../models/routine_anomaly.dart';
import '../models/safe_zone.dart';
import '../models/sharing_mode.dart';
import '../models/shopping_stop.dart';
import '../models/sos_alert.dart';
import '../models/speed_event.dart';
import '../models/support_message.dart';
import '../services/auth_service.dart';
import '../services/crash_detection_service.dart';
import '../services/home_widget_service.dart';
import '../services/kinly_repository.dart';
import '../services/location_tracker.dart';
import '../services/push_notification_service.dart';
import '../services/walk_me_home_service.dart';
import '../utils/circle_icons.dart';
import '../utils/color_hex.dart';
import 'locale_controller.dart';

/// Stato dell'app: chi sono, le mie cerchie, chi ne fa parte e le richieste
/// di posizione in corso. I dati arrivano da Supabase (query + realtime); le
/// regole su chi può vedere cosa sono applicate dal database (RLS), non qui.
class AppState extends ChangeNotifier {
  AppState._();

  static final AppState instance = AppState._();

  final _repo = KinlyRepository.instance;

  bool isLoading = false;
  bool hasLoadedOnce = false;
  String? loadError;
  String? activeCircleId; // null = "Tutte"

  Person? _me;
  List<Person> _others = [];
  List<CircleGroup> _circles = [];
  List<LocationRequest> _requests = [];
  List<SafeZone> _safeZones = [];
  List<SafeZoneEvent> _safeZoneEvents = [];
  List<SpeedEvent> _speedEvents = [];
  List<MeetingPoint> _meetingPoints = [];
  List<MeetingPointArrival> _meetingPointArrivals = [];
  List<SosAlert> _sosAlerts = [];
  Set<String> _sosTrustedContactIds = {};
  List<CircleMessage> _circleMessages = [];
  List<HelpRequest> _helpRequests = [];
  List<Ping> _pings = [];
  List<Encounter> _encounters = [];
  List<ShoppingStop> _shoppingStops = [];
  List<ShoppingRequest> _shoppingRequests = [];
  List<ShoppingListItem> _shoppingListItems = [];
  List<CircleExpense> _circleExpenses = [];
  List<ExpenseShare> _expenseShares = [];
  final Set<String> _dismissedPingIds = {};
  final Set<String> _dismissedEncounterIds = {};
  Map<String, SharingMode> _circleSharingOverrides = {};
  TimeOfDay? _autoGhostStart;
  TimeOfDay? _autoGhostEnd;
  DateTime? _ghostUntil;

  RealtimeChannel? _channel;
  Timer? _refreshDebounce;
  Timer? _pollTimer;

  bool get isSignedIn => AuthService.instance.isSignedIn;
  bool get hasCircles => _circles.isNotEmpty;
  bool get isPremium => me.isPremium;
  bool get isAdmin => me.isAdmin;

  /// Piano posseduto direttamente (non l'effettivo): usato dalla pagina
  /// Kinly+ per capire quale dei tre livelli è davvero il mio, distinto dal
  /// beneficio Family eventualmente ereditato da qualcun altro.
  PremiumTier get myPremiumTier => me.premiumTier;

  /// Vero se sono Kinly+ solo perché membro di una cerchia il cui creatore
  /// ha il piano Family (non ho un abbonamento mio).
  bool get isFamilyBeneficiary => me.premiumTier == PremiumTier.none && me.isPremium;

  /// Nome di chi paga il piano Family da cui beneficio, se è così.
  String? get familyPlanOwnerName {
    if (!isFamilyBeneficiary) return null;
    for (final circle in _circles) {
      if (circle.createdBy == me.id) continue;
      final owner = personById(circle.createdBy);
      if (owner?.premiumTier == PremiumTier.family) return owner!.name;
    }
    return null;
  }

  Person get me => _me ?? _placeholderMe();
  List<Person> get others => List.unmodifiable(_others);
  List<CircleGroup> get circles => List.unmodifiable(_circles);
  List<LocationRequest> get requests => List.unmodifiable(_requests);
  List<SafeZone> get safeZones => List.unmodifiable(_safeZones);
  List<SafeZoneEvent> get safeZoneEvents => List.unmodifiable(_safeZoneEvents);
  List<SpeedEvent> get speedEvents => List.unmodifiable(_speedEvents);
  List<MeetingPoint> get meetingPoints => List.unmodifiable(_meetingPoints);

  /// SOS attivi (non risolti) visibili nelle mie cerchie, io compreso.
  List<SosAlert> get activeSosAlerts => _sosAlerts.where((a) => a.status == SosStatus.active).toList();

  /// Il mio SOS attivo, se ne ho uno in corso.
  SosAlert? get myActiveSos {
    for (final a in _sosAlerts) {
      if (a.profileId == me.id && a.status == SosStatus.active) return a;
    }
    return null;
  }

  /// Contatti scelti per ricevere il mio SOS: se vuoto, avvisa tutte le mie
  /// cerchie (comportamento di default).
  Set<String> get sosTrustedContactIds => Set.unmodifiable(_sosTrustedContactIds);

  /// Richieste di aiuto attive (non risolte) visibili nelle mie cerchie.
  List<HelpRequest> get activeHelpRequests => _helpRequests.where((h) => h.status == HelpRequestStatus.active).toList();

  /// La mia richiesta di aiuto attiva, se ne ho una in corso.
  HelpRequest? get myActiveHelpRequest {
    for (final h in _helpRequests) {
      if (h.profileId == me.id && h.status == HelpRequestStatus.active) return h;
    }
    return null;
  }

  /// Orario di reperibilità (ora locale): fuori da questa finestra nessuno
  /// vede la mia posizione. Null = nessuna limitazione.
  TimeOfDay? get autoGhostStart => _autoGhostStart;
  TimeOfDay? get autoGhostEnd => _autoGhostEnd;

  /// Ghost Mode temporaneo (Kinly+): se in futuro, nessuno vede la mia
  /// posizione fino a quel momento, qualunque sia sharing_mode.
  DateTime? get ghostUntil => _ghostUntil;
  bool get isGhostModeActive => _ghostUntil != null && _ghostUntil!.isAfter(DateTime.now());

  SharingMode get myMode => me.mode;

  /// Carica il profilo, le cerchie e le richieste dell'utente autenticato,
  /// poi resta in ascolto dei cambiamenti in tempo reale. Va chiamato dopo
  /// il login (e ogni volta che si torna in primo piano dopo un log out).
  Future<void> initialize() async {
    isLoading = true;
    loadError = null;
    notifyListeners();

    await _refreshData();

    isLoading = false;
    hasLoadedOnce = true;
    notifyListeners();

    _channel ??= _repo.subscribeToChanges(_scheduleRefresh, _handleLocationChange);
    unawaited(LocationTracker.instance.start());
    unawaited(PushNotificationService.instance.initialize(onArrivalConfirmed: sendArrivalPing));
    unawaited(WalkMeHomeService.instance.restore());
    if (isPremium) unawaited(CrashDetectionService.instance.start());

    // Rete di sicurezza oltre al realtime: alcuni cambiamenti (es. qualcuno
    // che entra in una cerchia) dipendono da policy RLS che si
    // "auto-controllano" (circle_members verifica l'appartenenza leggendo
    // se stessa) — Supabase Realtime non garantisce la consegna in questi
    // casi, quindi senza questo timer l'unico modo per vedere l'aggiunta
    // sarebbe riaprire l'app. Un refresh silenzioso ogni 45s copre anche
    // qualunque altra disconnessione realtime passeggera, non solo questa;
    // l'intervallo resta comunque prudente per non moltiplicare le
    // chiamate al piano gratuito di Supabase (vedi LocationTracker).
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 45), (_) => _scheduleRefresh());
  }

  Future<void> _refreshData() async {
    final myId = AuthService.instance.currentUserId;
    if (myId == null) return;

    try {
      final profileRow = await _repo.fetchMyProfile();
      final circleRows = await _repo.fetchMyCircles();
      final memberships = await _repo.fetchAllCircleMemberships();

      final memberIdsByCircle = <String, List<String>>{};
      for (final m in memberships) {
        memberIdsByCircle.putIfAbsent(m['circle_id'] as String, () => []).add(m['profile_id'] as String);
      }

      _circles = circleRows
          .map((row) => CircleGroup.fromRow(row, memberIds: memberIdsByCircle[row['id']] ?? const []))
          .toList();

      final otherIds = <String>{};
      for (final ids in memberIdsByCircle.values) {
        otherIds.addAll(ids);
      }
      otherIds.remove(myId);

      final otherProfiles = await _repo.fetchProfiles(otherIds.toList());
      final locationRows = await _repo.fetchLocations([myId, ...otherIds]);
      final locationByProfile = {for (final l in locationRows) l['profile_id'] as String: l};

      _me = _buildPerson(
        profileRow,
        locationByProfile[myId],
        isMe: true,
        isSharingWithMe: true,
      );

      _others = otherProfiles
          .map((row) => _buildPerson(
                row,
                locationByProfile[row['id']],
                isMe: false,
                isSharingWithMe: locationByProfile.containsKey(row['id']),
              ))
          .toList();

      final requestRows = await _repo.fetchLocationRequests();
      _requests = requestRows.map((row) => LocationRequest.fromRow(row, myId: myId)).toList();

      final zoneRows = await _repo.fetchSafeZones();
      _safeZones = zoneRows.map(SafeZone.fromRow).toList();

      final eventRows = await _repo.fetchSafeZoneEvents();
      _safeZoneEvents = eventRows.map(SafeZoneEvent.fromRow).toList();

      final speedEventRows = await _repo.fetchSpeedEvents();
      _speedEvents = speedEventRows.map(SpeedEvent.fromRow).toList();

      _autoGhostStart = _utcTimeStringToLocal(profileRow['auto_ghost_start'] as String?);
      _autoGhostEnd = _utcTimeStringToLocal(profileRow['auto_ghost_end'] as String?);
      final ghostUntilRaw = profileRow['ghost_until'] as String?;
      _ghostUntil = ghostUntilRaw != null ? DateTime.parse(ghostUntilRaw).toLocal() : null;

      final meetingPointRows = await _repo.fetchMeetingPoints();
      _meetingPoints = meetingPointRows.map(MeetingPoint.fromRow).toList();

      final arrivalRows = await _repo.fetchMeetingPointArrivals();
      _meetingPointArrivals = arrivalRows.map(MeetingPointArrival.fromRow).toList();

      final sosRows = await _repo.fetchSosAlerts();
      _sosAlerts = sosRows.map(SosAlert.fromRow).toList();

      final trustedContactIds = await _repo.fetchSosTrustedContactIds();
      _sosTrustedContactIds = trustedContactIds.toSet();

      final messageRows = await _repo.fetchCircleMessages();
      _circleMessages = messageRows.map(CircleMessage.fromRow).toList();

      final helpRequestRows = await _repo.fetchHelpRequests();
      _helpRequests = helpRequestRows.map(HelpRequest.fromRow).toList();

      final pingRows = await _repo.fetchPings();
      _pings = pingRows.map(Ping.fromRow).toList();

      final encounterRows = await _repo.fetchEncounters();
      _encounters = encounterRows.map(Encounter.fromRow).toList();

      final shoppingStopRows = await _repo.fetchShoppingStops();
      _shoppingStops = shoppingStopRows.map(ShoppingStop.fromRow).toList();

      final shoppingRequestRows = await _repo.fetchShoppingRequests();
      _shoppingRequests = shoppingRequestRows.map(ShoppingRequest.fromRow).toList();

      final shoppingListItemRows = await _repo.fetchShoppingListItems();
      _shoppingListItems = shoppingListItemRows.map(ShoppingListItem.fromRow).toList();

      final expenseRows = await _repo.fetchCircleExpenses();
      _circleExpenses = expenseRows.map(CircleExpense.fromRow).toList();

      final expenseShareRows = await _repo.fetchExpenseShares();
      _expenseShares = expenseShareRows.map(ExpenseShare.fromRow).toList();

      final circleSettingsRows = await _repo.fetchMyCircleSharingSettings();
      _circleSharingOverrides = {
        for (final r in circleSettingsRows) r['circle_id'] as String: SharingModeData.fromDb(r['sharing_mode'] as String),
      };

      unawaited(HomeWidgetService.instance.update(_others, lookupAppLocalizations(LocaleController.instance.locale)));

      loadError = null;
    } catch (e) {
      loadError = e.toString();
    }
  }

  /// L'orario è salvato in UTC (formato "HH:MM:SS"); qui lo riportiamo
  /// all'ora locale del dispositivo per mostrarlo nell'interfaccia.
  TimeOfDay? _utcTimeStringToLocal(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    final utc = DateTime.utc(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
    final local = utc.toLocal();
    return TimeOfDay(hour: local.hour, minute: local.minute);
  }

  String _localTimeToUtcString(TimeOfDay t) {
    final now = DateTime.now();
    final local = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    final utc = local.toUtc();
    return '${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')}:00';
  }

  // Un cambiamento realtime su una qualsiasi delle tabelle sottoscritte
  // rifà un caricamento completo (una decina di query). Con più persone
  // che si muovono nella stessa cerchia, un debounce troppo corto fa
  // ripartire questo carico ad ogni singolo aggiornamento di posizione:
  // una finestra più larga raggruppa più eventi vicini in un solo refresh.
  static const _refreshDebounceWindow = Duration(seconds: 2, milliseconds: 500);

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(_refreshDebounceWindow, () async {
      await _refreshData();
      notifyListeners();
    });
  }

  /// Profili per cui è già in corso una fetch mirata: evita di far partire
  /// più richieste in parallelo per la stessa persona se più eventi
  /// realtime arrivano ravvicinati (es. più fix GPS quasi in contemporanea).
  final Set<String> _pendingLocationFetches = {};

  /// Aggiorna SOLO la posizione della persona cambiata invece di rifare
  /// l'intero caricamento (~20 query): la tabella `locations` è di gran
  /// lunga la più "rumorosa" via realtime (cambia ad ogni spostamento di
  /// chiunque nella cerchia), quindi è quella che più beneficia di un
  /// aggiornamento mirato invece che di un refresh completo, per il
  /// consumo di banda del piano gratuito di Supabase.
  Future<void> _handleLocationChange(String profileId) async {
    if (_pendingLocationFetches.contains(profileId)) return;
    _pendingLocationFetches.add(profileId);
    try {
      final myId = AuthService.instance.currentUserId;
      if (myId == null) return;

      // Stessa RPC del refresh completo: applica già lato server sia la
      // visibilità (equivalente RLS) sia l'arrotondamento della modalità
      // "approssimativa", quindi il risultato è identico a quello che si
      // otterrebbe con un refresh completo.
      final rows = await _repo.fetchLocations([profileId]);
      final location = rows.isEmpty ? null : rows.first;
      final isSharingWithMe = location != null;

      if (profileId == myId) {
        final current = _me;
        if (current == null) {
          _scheduleRefresh();
          return;
        }
        _me = _patchPersonLocation(current, location, isSharingWithMe: true);
      } else {
        final index = _others.indexWhere((p) => p.id == profileId);
        if (index == -1) {
          // Persona non ancora nello stato locale (es. appena entrata in
          // una cerchia insieme alla mia): un refresh completo la aggiunge
          // correttamente, con tutti gli altri campi del profilo.
          _scheduleRefresh();
          return;
        }
        _others[index] = _patchPersonLocation(_others[index], location, isSharingWithMe: isSharingWithMe);
      }
      notifyListeners();
    } catch (_) {
      // In caso di errore meglio un refresh completo che uno stato a metà.
      _scheduleRefresh();
    } finally {
      _pendingLocationFetches.remove(profileId);
    }
  }

  /// Ricostruisce i soli campi legati alla posizione di [person] (vedi
  /// _buildPerson, di cui questo è il sotto-insieme "posizione"): usato per
  /// l'aggiornamento mirato di _handleLocationChange, per non toccare nome,
  /// avatar, stato o altri campi che non c'entrano con questo cambiamento.
  Person _patchPersonLocation(Person person, Map<String, dynamic>? location, {required bool isSharingWithMe}) {
    final canSeeLocation = person.isMe || isSharingWithMe;
    return Person(
      id: person.id,
      name: person.name,
      color: person.color,
      lat: location != null ? (location['lat'] as num).toDouble() : null,
      lng: location != null ? (location['lng'] as num).toDouble() : null,
      address: location?['address'] as String? ??
          (canSeeLocation ? 'Posizione non ancora disponibile' : 'Ultima posizione non disponibile'),
      lastUpdate: location != null ? DateTime.parse(location['updated_at'] as String) : person.lastUpdate,
      batteryPercent: person.batteryPercent,
      isSharingWithMe: isSharingWithMe,
      mode: person.mode,
      isMe: person.isMe,
      isPremium: person.isPremium,
      speedAlertKmh: person.speedAlertKmh,
      isFuzzyLocation: location?['is_fuzzy'] as bool? ?? false,
      speedKmh: (location?['speed_kmh'] as num?)?.toDouble(),
      avatarKey: person.avatarKey,
      photoUrl: person.photoUrl,
      isAdmin: person.isAdmin,
      birthday: person.birthday,
      statusEmoji: person.statusEmoji,
      statusText: person.statusText,
      statusExpiresAt: person.statusExpiresAt,
      paymentLink: person.paymentLink,
      premiumTier: person.premiumTier,
      phoneNumber: person.phoneNumber,
      weeklySummaryEnabled: person.weeklySummaryEnabled,
    );
  }

  Person _buildPerson(
    Map<String, dynamic> profile,
    Map<String, dynamic>? location, {
    required bool isMe,
    required bool isSharingWithMe,
  }) {
    final canSeeLocation = isMe || isSharingWithMe;
    return Person(
      id: profile['id'] as String,
      name: profile['name'] as String,
      color: ColorHex.fromHex(profile['color'] as String? ?? '#4A63E7'),
      lat: location != null ? (location['lat'] as num).toDouble() : null,
      lng: location != null ? (location['lng'] as num).toDouble() : null,
      address: location?['address'] as String? ??
          (canSeeLocation ? 'Posizione non ancora disponibile' : 'Ultima posizione non disponibile'),
      lastUpdate: location != null ? DateTime.parse(location['updated_at'] as String) : DateTime.now(),
      batteryPercent: (profile['battery_percent'] as num?)?.toInt() ?? 0,
      isSharingWithMe: isSharingWithMe,
      isMe: isMe,
      isPremium: profile['effective_is_premium'] as bool? ?? profile['is_premium'] as bool? ?? false,
      speedAlertKmh: (profile['speed_alert_kmh'] as num?)?.toInt(),
      isFuzzyLocation: location?['is_fuzzy'] as bool? ?? false,
      speedKmh: (location?['speed_kmh'] as num?)?.toDouble(),
      avatarKey: profile['avatar_key'] as String?,
      photoUrl: profile['photo_url'] as String?,
      isAdmin: profile['is_admin'] as bool? ?? false,
      mode: SharingModeData.fromDb(profile['effective_sharing_mode'] as String? ?? profile['sharing_mode'] as String? ?? 'automatic'),
      birthday: profile['birthday'] != null ? DateTime.parse(profile['birthday'] as String) : null,
      statusEmoji: profile['status_emoji'] as String?,
      statusText: profile['status_text'] as String?,
      statusExpiresAt: profile['status_expires_at'] != null ? DateTime.parse(profile['status_expires_at'] as String) : null,
      paymentLink: profile['payment_link'] as String?,
      premiumTier: PremiumTierData.fromDb(profile['premium_tier'] as String?),
      phoneNumber: profile['phone_number'] as String?,
      weeklySummaryEnabled: profile['weekly_summary_enabled'] as bool? ?? true,
    );
  }

  Person _placeholderMe() => Person(
        id: AuthService.instance.currentUserId ?? 'me',
        name: 'Io',
        color: const Color(0xFF4A63E7),
        address: '',
        lastUpdate: DateTime.now(),
        batteryPercent: 0,
        isSharingWithMe: true,
        mode: SharingMode.automatic,
        isMe: true,
      );

  Future<void> logOut() async {
    await LocationTracker.instance.stop();
    await PushNotificationService.instance.unregister();
    await _channel?.unsubscribe();
    _channel = null;
    _refreshDebounce?.cancel();
    _pollTimer?.cancel();
    _pollTimer = null;
    await AuthService.instance.signOut();
    _me = null;
    _others = [];
    _circles = [];
    _requests = [];
    _safeZones = [];
    _safeZoneEvents = [];
    _speedEvents = [];
    _meetingPoints = [];
    _meetingPointArrivals = [];
    _sosAlerts = [];
    _sosTrustedContactIds = {};
    _circleMessages = [];
    _helpRequests = [];
    _pings = [];
    _encounters = [];
    _shoppingStops = [];
    _shoppingRequests = [];
    _shoppingListItems = [];
    _circleExpenses = [];
    _expenseShares = [];
    _circleSharingOverrides = {};
    _dismissedPingIds.clear();
    _dismissedEncounterIds.clear();
    _autoGhostStart = null;
    _autoGhostEnd = null;
    _ghostUntil = null;
    activeCircleId = null;
    hasLoadedOnce = false;
    loadError = null;
    notifyListeners();
  }

  void setActiveCircle(String? id) {
    activeCircleId = id;
    notifyListeners();
  }

  Future<void> setMyMode(SharingMode mode) async {
    if (_me != null) _me = _me!.copyWith(mode: mode);
    notifyListeners();
    await _repo.setSharingMode(mode);
    unawaited(_refreshData().then((_) => notifyListeners()));
  }

  /// null = nessun override, uso la modalità generale in quella cerchia.
  SharingMode? modeOverrideForCircle(String circleId) => _circleSharingOverrides[circleId];

  Future<void> setCircleSharingMode(String circleId, SharingMode? mode) async {
    if (mode == null) {
      _circleSharingOverrides.remove(circleId);
    } else {
      _circleSharingOverrides[circleId] = mode;
    }
    notifyListeners();
    await _repo.setCircleSharingMode(circleId, mode);
    unawaited(_refreshData().then((_) => notifyListeners()));
  }

  Person? personById(String id) {
    if (_me != null && id == _me!.id) return _me;
    for (final p in _others) {
      if (p.id == id) return p;
    }
    return null;
  }

  CircleGroup? circleById(String id) {
    for (final c in _circles) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<CircleGroup> circlesForPerson(String id) => _circles.where((c) => c.memberIds.contains(id)).toList();

  /// Le persone (esclusa io) visibili nella cerchia attiva, o tutte se
  /// nessuna cerchia è selezionata.
  List<Person> visiblePeople() {
    if (activeCircleId == null) return others;
    final circle = circleById(activeCircleId!);
    if (circle == null) return others;
    return _others.where((p) => circle.memberIds.contains(p.id)).toList();
  }

  /// Aree sicure visibili nella mappa live per la cerchia attiva, o tutte
  /// se nessuna cerchia è selezionata.
  List<SafeZone> visibleSafeZones() {
    if (activeCircleId == null) return safeZones;
    return _safeZones.where((z) => z.circleId == activeCircleId).toList();
  }

  /// Punti d'incontro ancora attivi (non scaduti) per la cerchia attiva, o
  /// tutti se nessuna cerchia è selezionata.
  List<MeetingPoint> visibleMeetingPoints() {
    final active = _meetingPoints.where((p) => !p.isExpired);
    if (activeCircleId == null) return active.toList();
    return active.where((p) => p.circleId == activeCircleId).toList();
  }

  List<LocationRequest> get pendingIncoming =>
      _requests.where((r) => r.direction == RequestDirection.incoming && r.status == RequestStatus.pending).toList();

  List<LocationRequest> get pendingOutgoing =>
      _requests.where((r) => r.direction == RequestDirection.outgoing && r.status == RequestStatus.pending).toList();

  List<LocationRequest> get history => _requests.where((r) => r.status != RequestStatus.pending).toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  bool hasPendingOutgoingTo(String personId) => _requests
      .any((r) => r.personId == personId && r.direction == RequestDirection.outgoing && r.status == RequestStatus.pending);

  Future<bool> sendLocationRequest(String personId) async {
    final sent = await _repo.sendLocationRequest(personId);
    if (sent) {
      await _refreshData();
      notifyListeners();
    }
    return sent;
  }

  Future<void> respondToIncoming(String requestId, bool accept) async {
    await _repo.respondToRequest(requestId, accept);
    await _refreshData();
    notifyListeners();
  }

  Future<CircleGroup> createCircle(String name, IconData icon, Color color) async {
    final circle = await _repo.createCircle(name: name, iconKey: CircleIcons.keyFor(icon), colorHex: color.toHex());
    await _refreshData();
    notifyListeners();
    return circle;
  }

  /// Cerca una cerchia dal codice invito e, se esiste, mi ci fa entrare.
  Future<CircleGroup?> joinCircleByCode(String code) async {
    final circle = await _repo.joinCircleByCode(code);
    if (circle != null) {
      await _refreshData();
      notifyListeners();
    }
    return circle;
  }

  // ---------------------------------------------------------------------
  // Kinly+ : cronologia posizioni e aree sicure
  // ---------------------------------------------------------------------

  /// Storico di una persona (funzione Kinly+): torna vuoto se non sono
  /// abbonato, senza bisogno di controllarlo qui — lo decide la RLS.
  Future<List<LocationHistoryPoint>> fetchHistoryFor(String personId) async {
    final rows = await _repo.fetchLocationHistory(personId);
    return rows.map(LocationHistoryPoint.fromRow).toList();
  }

  /// Cancella tutta la MIA cronologia posizioni: gli itinerari nelle
  /// statistiche sono ricostruiti al volo da questi punti, quindi spariscono
  /// anche quelli senza bisogno di toccare altro.
  Future<void> deleteMyLocationHistory() => _repo.deleteMyLocationHistory();

  List<SafeZone> safeZonesForCircle(String circleId) => _safeZones.where((z) => z.circleId == circleId).toList();

  SafeZone? safeZoneById(String id) {
    for (final z in _safeZones) {
      if (z.id == id) return z;
    }
    return null;
  }

  MeetingPoint? meetingPointById(String id) {
    for (final p in _meetingPoints) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<SafeZoneEvent> eventsForZone(String zoneId) => _safeZoneEvents.where((e) => e.zoneId == zoneId).toList();

  /// Anomalie di routine: qualcuno è ancora dentro un'area sicura oltre il
  /// suo solito orario di uscita (mediana delle uscite passate). Calcolato
  /// al volo dallo storico già disponibile, senza notifiche push: si vede
  /// solo aprendo l'app.
  List<RoutineAnomaly> get routineAnomalies {
    const minHistory = 3;
    const lateThresholdMinutes = 20;

    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    final grouped = <String, List<SafeZoneEvent>>{};
    for (final e in _safeZoneEvents) {
      grouped.putIfAbsent('${e.zoneId}_${e.profileId}', () => []).add(e);
    }

    final anomalies = <RoutineAnomaly>[];
    for (final events in grouped.values) {
      events.sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
      final last = events.last;
      if (last.type != SafeZoneEventType.enter) continue;

      final lastLocal = last.occurredAt.toLocal();
      final isToday = lastLocal.year == now.year && lastLocal.month == now.month && lastLocal.day == now.day;
      if (!isToday) continue;

      final exitMinutes = events
          .where((e) => e.type == SafeZoneEventType.exit)
          .map((e) => e.occurredAt.toLocal())
          .map((dt) => dt.hour * 60 + dt.minute)
          .toList()
        ..sort();
      if (exitMinutes.length < minHistory) continue;
      final medianExit = exitMinutes[exitMinutes.length ~/ 2];

      final enterMinutes = lastLocal.hour * 60 + lastLocal.minute;
      if (enterMinutes >= medianExit) continue; // entrato dopo il solito orario di uscita: non è un ritardo

      if (nowMinutes > medianExit + lateThresholdMinutes) {
        SafeZone? zone;
        for (final z in _safeZones) {
          if (z.id == last.zoneId) {
            zone = z;
            break;
          }
        }
        if (zone == null) continue;
        anomalies.add(RoutineAnomaly(
          zoneId: last.zoneId,
          zoneName: zone.name,
          profileId: last.profileId,
          expectedExit: TimeOfDay(hour: medianExit ~/ 60, minute: medianExit % 60),
          minutesLate: nowMinutes - medianExit,
        ));
      }
    }
    return anomalies;
  }

  Future<void> createSafeZone({
    required String circleId,
    required String name,
    required double lat,
    required double lng,
    required int radiusMeters,
    required SafeZoneKind kind,
  }) async {
    await _repo.createSafeZone(circleId: circleId, name: name, lat: lat, lng: lng, radiusMeters: radiusMeters, kind: kind);
    await _refreshData();
    notifyListeners();
  }

  Future<void> updateSafeZone({
    required String zoneId,
    required String name,
    required double lat,
    required double lng,
    required int radiusMeters,
    required SafeZoneKind kind,
  }) async {
    await _repo.updateSafeZone(zoneId: zoneId, name: name, lat: lat, lng: lng, radiusMeters: radiusMeters, kind: kind);
    await _refreshData();
    notifyListeners();
  }

  Future<void> deleteSafeZone(String zoneId) async {
    await _repo.deleteSafeZone(zoneId);
    await _refreshData();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Kinly+ : avvisi di guida
  // ---------------------------------------------------------------------

  List<SpeedEvent> speedEventsFor(String personId) => _speedEvents.where((e) => e.profileId == personId).toList();

  /// Imposta la mia soglia di velocità: null disattiva gli avvisi.
  Future<void> setSpeedAlert(int? kmh) async {
    if (_me != null) _me = _me!.copyWith(speedAlertKmh: kmh, clearSpeedAlertKmh: kmh == null);
    notifyListeners();
    await _repo.updateSpeedAlert(kmh);
    unawaited(_refreshData().then((_) => notifyListeners()));
  }

  /// Cambia il mio avatar (vedi AvatarCatalog): null torna alle iniziali.
  Future<void> setAvatar(String? avatarKey) async {
    if (_me != null) _me = _me!.copyWith(avatarKey: avatarKey, clearAvatarKey: avatarKey == null);
    notifyListeners();
    await _repo.updateAvatar(avatarKey);
    unawaited(_refreshData().then((_) => notifyListeners()));
  }

  /// Carica una foto profilo vera: [jpegBytes] è già ridotta e compressa dal
  /// chiamante (vedi utils/image_resizer.dart) prima di arrivare qui. Ha la
  /// precedenza sull'avatar a tema quando presente (vedi PersonAvatar).
  Future<void> setProfilePhoto(List<int> jpegBytes) async {
    final url = await _repo.uploadProfilePhoto(jpegBytes);
    await _repo.updatePhotoUrl(url);
    if (_me != null) _me = _me!.copyWith(photoUrl: url);
    notifyListeners();
    unawaited(_refreshData().then((_) => notifyListeners()));
  }

  Future<void> removeProfilePhoto() async {
    if (_me != null) _me = _me!.copyWith(clearPhotoUrl: true);
    notifyListeners();
    await _repo.deleteProfilePhoto();
    await _repo.updatePhotoUrl(null);
    unawaited(_refreshData().then((_) => notifyListeners()));
  }

  // ---------------------------------------------------------------------
  // Orario di reperibilità
  // ---------------------------------------------------------------------

  /// Passa null a entrambi per disattivare la limitazione oraria.
  Future<void> setAutoGhostSchedule(TimeOfDay? start, TimeOfDay? end) async {
    _autoGhostStart = start;
    _autoGhostEnd = end;
    notifyListeners();
    await _repo.updateAutoGhostSchedule(
      startUtc: start == null ? null : _localTimeToUtcString(start),
      endUtc: end == null ? null : _localTimeToUtcString(end),
    );
    unawaited(_refreshData().then((_) => notifyListeners()));
  }

  // ---------------------------------------------------------------------
  // Ghost Mode temporaneo (Kinly+)
  // ---------------------------------------------------------------------

  /// Nasconde la mia posizione a tutti per [duration] (non tocca
  /// sharing_mode: alla scadenza torna tutto come prima da solo).
  Future<void> startTemporaryGhostMode(Duration duration) async {
    final until = DateTime.now().add(duration);
    _ghostUntil = until;
    notifyListeners();
    await _repo.updateGhostUntil(until);
    unawaited(_refreshData().then((_) => notifyListeners()));
  }

  /// Torna visibile subito, prima che scada da solo.
  Future<void> cancelTemporaryGhostMode() async {
    _ghostUntil = null;
    notifyListeners();
    await _repo.updateGhostUntil(null);
    unawaited(_refreshData().then((_) => notifyListeners()));
  }

  // ---------------------------------------------------------------------
  // Punto d'incontro condiviso
  // ---------------------------------------------------------------------

  /// Il punto attivo (non scaduto) di una cerchia, se c'è.
  MeetingPoint? meetingPointForCircle(String circleId) {
    for (final p in _meetingPoints) {
      if (p.circleId == circleId && !p.isExpired) return p;
    }
    return null;
  }

  List<MeetingPointArrival> arrivalsFor(String meetingPointId) =>
      _meetingPointArrivals.where((a) => a.meetingPointId == meetingPointId).toList();

  bool hasArrived(String meetingPointId, String profileId) =>
      _meetingPointArrivals.any((a) => a.meetingPointId == meetingPointId && a.profileId == profileId);

  Future<void> createMeetingPoint({
    required String circleId,
    required String name,
    required double lat,
    required double lng,
    DateTime? scheduledAt,
  }) async {
    await _repo.createMeetingPoint(circleId: circleId, name: name, lat: lat, lng: lng, scheduledAt: scheduledAt);
    await _refreshData();
    notifyListeners();
  }

  Future<void> deleteMeetingPoint(String id) async {
    await _repo.deleteMeetingPoint(id);
    await _refreshData();
    notifyListeners();
  }

  Future<void> markArrivedAt(String meetingPointId) async {
    await _repo.recordMeetingPointArrival(meetingPointId);
    await _refreshData();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Assistenza
  // ---------------------------------------------------------------------

  Future<void> sendSupportMessage(String message) => _repo.sendSupportMessage(message);

  Future<List<SupportMessage>> fetchMySupportMessages() async {
    final rows = await _repo.fetchMySupportMessages();
    return rows.map(SupportMessage.fromRow).toList();
  }

  // ---------------------------------------------------------------------
  // SOS "Black Box" (solo posizione, nessuna registrazione)
  // ---------------------------------------------------------------------

  Future<void> triggerSos({required double lat, required double lng}) async {
    await _repo.triggerSos(lat: lat, lng: lng);
    await _refreshData();
    notifyListeners();
  }

  Future<void> resolveSos(String id) async {
    await _repo.resolveSos(id);
    await _refreshData();
    notifyListeners();
  }

  /// Aggiunge o toglie una persona dai contatti scelti per il mio SOS.
  Future<void> toggleSosTrustedContact(String contactId) async {
    final enabled = _sosTrustedContactIds.contains(contactId);
    if (enabled) {
      _sosTrustedContactIds = {..._sosTrustedContactIds}..remove(contactId);
    } else {
      _sosTrustedContactIds = {..._sosTrustedContactIds, contactId};
    }
    notifyListeners();
    if (enabled) {
      await _repo.removeSosTrustedContact(contactId);
    } else {
      await _repo.addSosTrustedContact(contactId);
    }
  }

  // ---------------------------------------------------------------------
  // Assistenza (admin)
  // ---------------------------------------------------------------------

  Future<List<SupportMessage>> fetchAllSupportMessagesForAdmin() async {
    final rows = await _repo.fetchAllSupportMessages();
    return rows.map(SupportMessage.fromRow).toList();
  }

  Future<void> replyToSupportMessage({required String id, required String reply}) =>
      _repo.replyToSupportMessage(id: id, reply: reply);

  // ---------------------------------------------------------------------
  // Messaggi cerchia (brevi, non è una chat)
  // ---------------------------------------------------------------------

  List<CircleMessage> messagesForCircle(String circleId) =>
      _circleMessages.where((m) => m.circleId == circleId).toList();

  Future<void> sendCircleMessage({required String circleId, required String body}) async {
    await _repo.sendCircleMessage(circleId: circleId, body: body);
    await _refreshData();
    notifyListeners();
  }

  /// "Sono arrivato" toccato sulla notifica del ping d'arrivo (vedi
  /// PushNotificationService.showArrivalPrompt): invia un messaggio alla
  /// cerchia dell'area sicura senza bisogno di aprire/navigare nell'app.
  Future<void> sendArrivalPing(String zoneId) async {
    SafeZone? zone;
    for (final z in _safeZones) {
      if (z.id == zoneId) {
        zone = z;
        break;
      }
    }
    if (zone == null) return;
    final l10n = lookupAppLocalizations(LocaleController.instance.locale);
    await sendCircleMessage(circleId: zone.circleId, body: l10n.arrivalPingMessage(zone.name));
  }

  // ---------------------------------------------------------------------
  // Richiesta di aiuto (un gradino sotto l'SOS)
  // ---------------------------------------------------------------------

  Future<void> triggerHelpRequest({
    required String circleId,
    required HelpRequestReason reason,
    String? note,
    required double lat,
    required double lng,
  }) async {
    await _repo.triggerHelpRequest(circleId: circleId, reasonDbValue: reason.dbValue, note: note, lat: lat, lng: lng);
    await _refreshData();
    notifyListeners();
  }

  Future<void> resolveHelpRequest(String id) async {
    await _repo.resolveHelpRequest(id);
    await _refreshData();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Compleanno, stato personalizzato, link di pagamento
  // ---------------------------------------------------------------------

  Future<void> setBirthday(DateTime? birthday) async {
    if (_me != null) _me = _me!.copyWith(birthday: birthday);
    notifyListeners();
    await _repo.updateBirthday(birthday);
    unawaited(_refreshData().then((_) => notifyListeners()));
  }

  Future<void> setPaymentLink(String? link) async {
    if (_me != null) _me = _me!.copyWith(paymentLink: link);
    notifyListeners();
    await _repo.updatePaymentLink(link);
    unawaited(_refreshData().then((_) => notifyListeners()));
  }

  Future<void> setPhoneNumber(String? phoneNumber) async {
    if (_me != null) {
      _me = _me!.copyWith(phoneNumber: phoneNumber, clearPhoneNumber: phoneNumber == null);
    }
    notifyListeners();
    await _repo.updatePhoneNumber(phoneNumber);
    unawaited(_refreshData().then((_) => notifyListeners()));
  }

  Future<void> setWeeklySummaryEnabled(bool enabled) async {
    if (_me != null) _me = _me!.copyWith(weeklySummaryEnabled: enabled);
    notifyListeners();
    await _repo.updateWeeklySummaryEnabled(enabled);
  }

  Future<Map<String, dynamic>> fetchWeeklyCircleStats(String circleId) => _repo.fetchWeeklyCircleStats(circleId);

  /// Imposta il mio stato del momento (emoji + testo breve, opzionale):
  /// scade da solo a fine giornata.
  Future<void> setStatus({required String emoji, String? text}) async {
    await _repo.updateStatus(emoji: emoji, text: text);
    await _refreshData();
    notifyListeners();
  }

  Future<void> clearStatus() async {
    await _repo.clearStatus();
    await _refreshData();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Ping contestuali e incontri (High five)
  // ---------------------------------------------------------------------

  Future<void> sendPing({required String toId, required PingKind kind}) async {
    await _repo.sendPing(toId: toId, kind: kind.dbValue);
    await _refreshData();
    notifyListeners();
  }

  /// Ping ricevuti non ancora mostrati (non fatti sparire con [dismissPing]),
  /// più recenti di 5 minuti: passata questa finestra non ha più senso
  /// mostrare un banner per un tocco così effimero.
  List<Ping> get incomingPings => _pings
      .where((p) =>
          p.toId == me.id && !_dismissedPingIds.contains(p.id) && DateTime.now().difference(p.createdAt) < const Duration(minutes: 5))
      .toList();

  void dismissPing(String id) {
    _dismissedPingIds.add(id);
    notifyListeners();
  }

  /// I miei incontri recenti (ultime 2 ore) non ancora fatti sparire.
  List<Encounter> get recentEncounters => _encounters
      .where((e) =>
          (e.profileA == me.id || e.profileB == me.id) &&
          !_dismissedEncounterIds.contains(e.id) &&
          DateTime.now().difference(e.createdAt) < const Duration(hours: 2))
      .toList();

  void dismissEncounter(String id) {
    _dismissedEncounterIds.add(id);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // "Portami qualcosa"
  // ---------------------------------------------------------------------

  /// La mia sosta attiva più recente (se c'è), per mostrarmi le richieste
  /// ricevute.
  ShoppingStop? get myActiveShoppingStop {
    for (final s in _shoppingStops) {
      if (s.profileId == me.id && s.isActive) return s;
    }
    return null;
  }

  /// Soste attive (recenti) di altri membri delle mie cerchie, per proporre
  /// "hai bisogno di qualcosa?".
  List<ShoppingStop> get othersActiveShoppingStops => _shoppingStops.where((s) => s.profileId != me.id && s.isActive).toList();

  List<ShoppingRequest> requestsForStop(String stopId) => _shoppingRequests.where((r) => r.stopId == stopId).toList();

  Future<void> sendShoppingRequest({required String stopId, required String note}) async {
    await _repo.sendShoppingRequest(stopId: stopId, note: note);
    await _refreshData();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Lista della spesa condivisa (voci fisse per cerchia)
  // ---------------------------------------------------------------------

  List<ShoppingListItem> shoppingListItemsForCircle(String circleId) =>
      _shoppingListItems.where((i) => i.circleId == circleId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Future<void> addShoppingListItem({required String circleId, required String label}) async {
    await _repo.addShoppingListItem(circleId: circleId, label: label);
    await _refreshData();
    notifyListeners();
  }

  Future<void> claimShoppingListItem(String itemId, {required bool claim}) async {
    await _repo.claimShoppingListItem(itemId: itemId, claim: claim);
    await _refreshData();
    notifyListeners();
  }

  Future<void> deleteShoppingListItem(String itemId) async {
    await _repo.deleteShoppingListItem(itemId);
    await _refreshData();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Spese di gruppo (Splitwise)
  // ---------------------------------------------------------------------

  List<CircleExpense> expensesForCircle(String circleId) =>
      _circleExpenses.where((e) => e.circleId == circleId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<ExpenseShare> sharesForExpense(String expenseId) => _expenseShares.where((s) => s.expenseId == expenseId).toList();

  /// Saldo netto per ciascun membro della cerchia rispetto a me: positivo
  /// se quella persona mi deve soldi, negativo se li devo io a lei. Calcolo
  /// semplice fatto lato client (le cerchie sono piccole), senza bisogno di
  /// una funzione dedicata sul database.
  Map<String, double> netBalancesForCircle(String circleId) {
    final balances = <String, double>{};
    for (final expense in expensesForCircle(circleId)) {
      final shares = sharesForExpense(expense.id);
      for (final share in shares) {
        if (share.profileId == me.id && expense.paidBy == me.id) continue;
        if (share.profileId == me.id) {
          // Ho una quota di una spesa pagata da qualcun altro: gli devo la
          // mia quota.
          balances[expense.paidBy] = (balances[expense.paidBy] ?? 0) - share.shareAmount;
        } else if (expense.paidBy == me.id) {
          // Ho pagato io: chi ha una quota mi deve quella cifra.
          balances[share.profileId] = (balances[share.profileId] ?? 0) + share.shareAmount;
        }
      }
    }
    return balances;
  }

  Future<void> createExpense({
    required String circleId,
    required String description,
    required double amount,
    required Map<String, double> sharesByProfileId,
  }) async {
    await _repo.createExpense(circleId: circleId, description: description, amount: amount, sharesByProfileId: sharesByProfileId);
    await _refreshData();
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    await _repo.deleteExpense(id);
    await _refreshData();
    notifyListeners();
  }
}
