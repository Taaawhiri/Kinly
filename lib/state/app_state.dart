import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/circle_group.dart';
import '../models/location_request.dart';
import '../models/person.dart';
import '../models/sharing_mode.dart';
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

  RealtimeChannel? _channel;
  Timer? _refreshDebounce;

  bool get isSignedIn => AuthService.instance.isSignedIn;
  bool get hasCircles => _circles.isNotEmpty;

  Person get me => _me ?? _placeholderMe();
  List<Person> get others => List.unmodifiable(_others);
  List<CircleGroup> get circles => List.unmodifiable(_circles);
  List<LocationRequest> get requests => List.unmodifiable(_requests);

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

      final coords = <String, (double, double)>{
        for (final l in locationRows) l['profile_id'] as String: ((l['lat'] as num).toDouble(), (l['lng'] as num).toDouble()),
      };
      final mapPositions = _projectToMap(coords);

      _me = _buildPerson(
        profileRow,
        locationByProfile[myId],
        mapPositions[myId],
        isMe: true,
        isSharingWithMe: true,
      );

      _others = otherProfiles
          .map((row) => _buildPerson(
                row,
                locationByProfile[row['id']],
                mapPositions[row['id']],
                isMe: false,
                isSharingWithMe: locationByProfile.containsKey(row['id']),
              ))
          .toList();

      final requestRows = await _repo.fetchLocationRequests();
      _requests = requestRows.map((row) => LocationRequest.fromRow(row, myId: myId)).toList();

      loadError = null;
    } catch (e) {
      loadError = e.toString();
    }
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 500), () async {
      await _refreshData();
      notifyListeners();
    });
  }

  Person _buildPerson(
    Map<String, dynamic> profile,
    Map<String, dynamic>? location,
    (double, double)? mapPos, {
    required bool isMe,
    required bool isSharingWithMe,
  }) {
    final canSeeLocation = isMe || isSharingWithMe;
    return Person(
      id: profile['id'] as String,
      name: profile['name'] as String,
      color: ColorHex.fromHex(profile['color'] as String? ?? '#4A63E7'),
      mapX: mapPos?.$1 ?? 0.5,
      mapY: mapPos?.$2 ?? 0.5,
      address: location?['address'] as String? ??
          (canSeeLocation ? 'Posizione non ancora disponibile' : 'Ultima posizione non disponibile'),
      lastUpdate: location != null ? DateTime.parse(location['updated_at'] as String) : DateTime.now(),
      batteryPercent: (profile['battery_percent'] as num?)?.toInt() ?? 0,
      isSharingWithMe: isSharingWithMe,
      mode: SharingModeData.fromDb(profile['sharing_mode'] as String? ?? 'automatic'),
      isMe: isMe,
    );
  }

  /// Proietta coordinate reali (lat, lng) su coordinate normalizzate 0..1
  /// per la mappa stilizzata dell'app (che non usa tile reali).
  Map<String, (double, double)> _projectToMap(Map<String, (double, double)> coords) {
    if (coords.isEmpty) return {};
    if (coords.length == 1) return {coords.keys.first: (0.5, 0.5)};

    final lats = coords.values.map((c) => c.$1);
    final lngs = coords.values.map((c) => c.$2);
    final minLat = lats.reduce(min), maxLat = lats.reduce(max);
    final minLng = lngs.reduce(min), maxLng = lngs.reduce(max);
    final latSpan = (maxLat - minLat).abs() < 1e-9 ? 1.0 : (maxLat - minLat);
    final lngSpan = (maxLng - minLng).abs() < 1e-9 ? 1.0 : (maxLng - minLng);
    const pad = 0.18;

    return coords.map((id, c) {
      final nx = (c.$2 - minLng) / lngSpan;
      final ny = 1 - (c.$1 - minLat) / latSpan;
      return MapEntry(id, (pad + nx * (1 - 2 * pad), pad + ny * (1 - 2 * pad)));
    });
  }

  Person _placeholderMe() => Person(
        id: AuthService.instance.currentUserId ?? 'me',
        name: 'Io',
        color: const Color(0xFF4A63E7),
        mapX: 0.5,
        mapY: 0.5,
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
}
