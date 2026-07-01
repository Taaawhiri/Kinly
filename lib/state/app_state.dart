import 'dart:math';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/circle_group.dart';
import '../models/location_request.dart';
import '../models/person.dart';
import '../models/sharing_mode.dart';

/// Stato dell'app per la durata della sessione: chi sono, le mie cerchie,
/// le persone che ne fanno parte e le richieste di posizione in corso.
/// Non c'è un vero backend: è tutto in memoria, pensato per il mockup.
class AppState extends ChangeNotifier {
  AppState._()
      : _me = MockData.me,
        _others = List.of(MockData.others),
        _circles = List.of(MockData.circles),
        _requests = List.of(MockData.requests);

  static final AppState instance = AppState._();

  bool hasOnboarded = false;
  String? activeCircleId; // null = "Tutte"

  Person _me;
  final List<Person> _others;
  final List<CircleGroup> _circles;
  final List<LocationRequest> _requests;

  Person get me => _me;
  List<Person> get others => List.unmodifiable(_others);
  List<CircleGroup> get circles => List.unmodifiable(_circles);
  List<LocationRequest> get requests => List.unmodifiable(_requests);

  SharingMode get myMode => _me.mode;

  void completeOnboarding() {
    hasOnboarded = true;
    notifyListeners();
  }

  void logOut() {
    hasOnboarded = false;
    activeCircleId = null;
    notifyListeners();
  }

  void setActiveCircle(String? id) {
    activeCircleId = id;
    notifyListeners();
  }

  void setMyMode(SharingMode mode) {
    _me = _me.copyWith(mode: mode);
    notifyListeners();
  }

  Person? personById(String id) {
    if (id == _me.id) return _me;
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

  bool hasPendingOutgoingTo(String personId) =>
      _requests.any((r) => r.personId == personId && r.direction == RequestDirection.outgoing && r.status == RequestStatus.pending);

  void sendLocationRequest(String personId) {
    if (hasPendingOutgoingTo(personId)) return;
    _requests.add(LocationRequest(
      id: 'req_${DateTime.now().microsecondsSinceEpoch}',
      personId: personId,
      direction: RequestDirection.outgoing,
      status: RequestStatus.pending,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  /// Rispondo a una richiesta che qualcuno mi ha fatto (vuole vedere dove sono).
  void respondToIncoming(String requestId, bool accept) {
    _updateRequestStatus(requestId, accept ? RequestStatus.accepted : RequestStatus.declined);
  }

  /// Simula la risposta dell'altra persona a una mia richiesta: per il
  /// mockup non c'è un vero destinatario dall'altra parte, quindi qui è
  /// l'utente stesso a far avanzare la demo.
  void simulateOutgoingResponse(String requestId, bool accept) {
    final request = _requests.firstWhere((r) => r.id == requestId, orElse: () => throw ArgumentError('id non trovato'));
    _updateRequestStatus(requestId, accept ? RequestStatus.accepted : RequestStatus.declined);
    if (accept) {
      final index = _others.indexWhere((p) => p.id == request.personId);
      if (index != -1) {
        _others[index] = _others[index].copyWith(isSharingWithMe: true);
      }
    }
    notifyListeners();
  }

  void _updateRequestStatus(String requestId, RequestStatus status) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;
    _requests[index] = _requests[index].copyWith(status: status);
    notifyListeners();
  }

  CircleGroup createCircle(String name, IconData icon, Color color) {
    final circle = CircleGroup(
      id: 'circle_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      icon: icon,
      color: color,
      memberIds: [_me.id],
      inviteCode: _generateInviteCode(name),
    );
    _circles.add(circle);
    notifyListeners();
    return circle;
  }

  /// Verifica un codice di invito rispetto alle cerchie esistenti (nel
  /// mockup non esiste un servizio remoto: è tutto locale).
  CircleGroup? joinCircleByCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final c in _circles) {
      if (c.inviteCode == normalized) return c;
    }
    return null;
  }

  String _generateInviteCode(String name) {
    final rng = Random();
    final prefix = name.trim().isEmpty ? 'CER' : name.trim().substring(0, min(3, name.trim().length)).toUpperCase();
    final suffix = List.generate(4, (_) => '23456789ABCDEFGHJKMNPQRSTUVWXYZ'[rng.nextInt(31)]).join();
    return '$prefix-$suffix';
  }
}
