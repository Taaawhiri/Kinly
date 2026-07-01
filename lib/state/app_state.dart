import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/circle_group.dart';
import '../models/location_history_point.dart';
import '../models/location_request.dart';
import '../models/meeting_point.dart';
import '../models/person.dart';
import '../models/routine_anomaly.dart';
import '../models/safe_zone.dart';
import '../models/sharing_mode.dart';
import '../models/sos_alert.dart';
import '../models/speed_event.dart';
import '../models/support_message.dart';
import '../services/auth_service.dart';
import '../services/kinly_repository.dart';
import '../services/location_tracker.dart';
import '../utils/circle_icons.dart';
import '../utils/color_hex.dart';

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
  TimeOfDay? _autoGhostStart;
  TimeOfDay? _autoGhostEnd;

  RealtimeChannel? _channel;
  Timer? _refreshDebounce;

  bool get isSignedIn => AuthService.instance.isSignedIn;
  bool get hasCircles => _circles.isNotEmpty;
  bool get isPremium => me.isPremium;

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

  /// Orario di reperibilità (ora locale): fuori da questa finestra nessuno
  /// vede la mia posizione. Null = nessuna limitazione.
  TimeOfDay? get autoGhostStart => _autoGhostStart;
  TimeOfDay? get autoGhostEnd => _autoGhostEnd;

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

    _channel ??= _repo.subscribeToChanges(_scheduleRefresh);
    unawaited(LocationTracker.instance.start());
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

      final meetingPointRows = await _repo.fetchMeetingPoints();
      _meetingPoints = meetingPointRows.map(MeetingPoint.fromRow).toList();

      final arrivalRows = await _repo.fetchMeetingPointArrivals();
      _meetingPointArrivals = arrivalRows.map(MeetingPointArrival.fromRow).toList();

      final sosRows = await _repo.fetchSosAlerts();
      _sosAlerts = sosRows.map(SosAlert.fromRow).toList();

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
      mode: SharingModeData.fromDb(profile['sharing_mode'] as String? ?? 'automatic'),
      isMe: isMe,
      isPremium: profile['is_premium'] as bool? ?? false,
      speedAlertKmh: (profile['speed_alert_kmh'] as num?)?.toInt(),
      isFuzzyLocation: location?['is_fuzzy'] as bool? ?? false,
      speedKmh: (location?['speed_kmh'] as num?)?.toDouble(),
      avatarKey: profile['avatar_key'] as String?,
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
    await _channel?.unsubscribe();
    _channel = null;
    _refreshDebounce?.cancel();
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
    _autoGhostStart = null;
    _autoGhostEnd = null;
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
    await _repo.setSharingMode(mode);
    await _refreshData();
    notifyListeners();
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

  List<SafeZone> safeZonesForCircle(String circleId) => _safeZones.where((z) => z.circleId == circleId).toList();

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
  }) async {
    await _repo.createSafeZone(circleId: circleId, name: name, lat: lat, lng: lng, radiusMeters: radiusMeters);
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
    await _repo.updateSpeedAlert(kmh);
    await _refreshData();
    notifyListeners();
  }

  /// Cambia il mio avatar (vedi AvatarCatalog): null torna alle iniziali.
  Future<void> setAvatar(String? avatarKey) async {
    await _repo.updateAvatar(avatarKey);
    await _refreshData();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Orario di reperibilità
  // ---------------------------------------------------------------------

  /// Passa null a entrambi per disattivare la limitazione oraria.
  Future<void> setAutoGhostSchedule(TimeOfDay? start, TimeOfDay? end) async {
    await _repo.updateAutoGhostSchedule(
      startUtc: start == null ? null : _localTimeToUtcString(start),
      endUtc: end == null ? null : _localTimeToUtcString(end),
    );
    await _refreshData();
    notifyListeners();
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

  Future<void> createMeetingPoint({required String circleId, required String name, required double lat, required double lng}) async {
    await _repo.createMeetingPoint(circleId: circleId, name: name, lat: lat, lng: lng);
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
}
