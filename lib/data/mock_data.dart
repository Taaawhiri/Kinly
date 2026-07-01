import 'package:flutter/material.dart';
import '../models/circle_group.dart';
import '../models/location_request.dart';
import '../models/person.dart';
import '../models/sharing_mode.dart';
import '../theme/app_theme.dart';

/// Dati di esempio per il mockup: una piccola cerchia già popolata, così si
/// può vedere subito come si comporta l'app senza dover invitare nessuno.
class MockData {
  MockData._();

  static final DateTime _now = DateTime.now();

  static final Person me = Person(
    id: 'me',
    name: 'Io',
    color: AppTheme.primary,
    mapX: 0.5,
    mapY: 0.55,
    address: 'Sei qui',
    lastUpdate: _now,
    batteryPercent: 71,
    isSharingWithMe: true,
    mode: SharingMode.automatic,
    isMe: true,
  );

  static final List<Person> others = [
    Person(
      id: 'mamma',
      name: 'Mamma',
      color: const Color(0xFFE8608A),
      mapX: 0.28,
      mapY: 0.32,
      address: 'Via dei Tigli 4, Milano',
      lastUpdate: _now.subtract(const Duration(minutes: 2)),
      batteryPercent: 78,
      isSharingWithMe: true,
      mode: SharingMode.automatic,
    ),
    Person(
      id: 'papa',
      name: 'Papà',
      color: const Color(0xFF3E7CB1),
      mapX: 0.68,
      mapY: 0.22,
      address: 'Corso Buenos Aires 22, Milano',
      lastUpdate: _now.subtract(const Duration(minutes: 14)),
      batteryPercent: 45,
      isSharingWithMe: true,
      mode: SharingMode.automatic,
    ),
    Person(
      id: 'sofia',
      name: 'Sofia',
      color: const Color(0xFF9B6BD6),
      mapX: 0.42,
      mapY: 0.68,
      address: 'Ultima posizione non disponibile',
      lastUpdate: _now.subtract(const Duration(hours: 3)),
      batteryPercent: 92,
      isSharingWithMe: false,
      mode: SharingMode.onRequest,
    ),
    Person(
      id: 'marco',
      name: 'Marco',
      color: const Color(0xFF1AA6A0),
      mapX: 0.78,
      mapY: 0.62,
      address: 'Navigli, Milano',
      lastUpdate: _now.subtract(const Duration(minutes: 1)),
      batteryPercent: 63,
      isSharingWithMe: true,
      mode: SharingMode.automatic,
    ),
    Person(
      id: 'giulia',
      name: 'Giulia',
      color: const Color(0xFFE08A3C),
      mapX: 0.35,
      mapY: 0.78,
      address: 'Ultima posizione non disponibile',
      lastUpdate: _now.subtract(const Duration(hours: 5)),
      batteryPercent: 30,
      isSharingWithMe: false,
      mode: SharingMode.onRequest,
    ),
    Person(
      id: 'luca',
      name: 'Luca',
      color: const Color(0xFF8A8F98),
      mapX: 0.5,
      mapY: 0.5,
      address: 'Modalità fantasma attiva',
      lastUpdate: _now.subtract(const Duration(days: 1)),
      batteryPercent: 0,
      isSharingWithMe: false,
      mode: SharingMode.paused,
    ),
    Person(
      id: 'elena',
      name: 'Elena',
      color: const Color(0xFF4A63E7),
      mapX: 0.6,
      mapY: 0.4,
      address: 'Piazza Gae Aulenti, Milano',
      lastUpdate: _now.subtract(const Duration(minutes: 6)),
      batteryPercent: 55,
      isSharingWithMe: true,
      mode: SharingMode.automatic,
    ),
    Person(
      id: 'davide',
      name: 'Davide',
      color: const Color(0xFFB0752E),
      mapX: 0.22,
      mapY: 0.55,
      address: 'Bocconi, Milano',
      lastUpdate: _now.subtract(const Duration(minutes: 22)),
      batteryPercent: 88,
      isSharingWithMe: true,
      mode: SharingMode.onRequest,
    ),
  ];

  static final List<CircleGroup> circles = [
    const CircleGroup(
      id: 'famiglia',
      name: 'Famiglia',
      icon: Icons.favorite_rounded,
      color: Color(0xFFE8608A),
      memberIds: ['me', 'mamma', 'papa', 'sofia'],
      inviteCode: 'FAM-7Q2K',
    ),
    const CircleGroup(
      id: 'amici',
      name: 'Amici',
      icon: Icons.groups_rounded,
      color: AppTheme.accentGreen,
      memberIds: ['me', 'marco', 'giulia', 'luca'],
      inviteCode: 'AMI-P91X',
    ),
    const CircleGroup(
      id: 'lavoro',
      name: 'Lavoro',
      icon: Icons.work_rounded,
      color: AppTheme.accentAmber,
      memberIds: ['me', 'elena', 'davide'],
      inviteCode: 'LAV-3T5B',
    ),
  ];

  static final List<LocationRequest> requests = [
    LocationRequest(
      id: 'req1',
      personId: 'sofia',
      direction: RequestDirection.incoming,
      status: RequestStatus.pending,
      timestamp: _now.subtract(const Duration(minutes: 9)),
    ),
    LocationRequest(
      id: 'req2',
      personId: 'giulia',
      direction: RequestDirection.outgoing,
      status: RequestStatus.pending,
      timestamp: _now.subtract(const Duration(minutes: 40)),
    ),
    LocationRequest(
      id: 'req3',
      personId: 'davide',
      direction: RequestDirection.outgoing,
      status: RequestStatus.accepted,
      timestamp: _now.subtract(const Duration(hours: 2)),
    ),
  ];
}
