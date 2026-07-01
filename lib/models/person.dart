import 'dart:math';
import 'package:flutter/material.dart';
import 'sharing_mode.dart';

/// Stato dinamico dedotto dall'ultima velocità nota: nessun sensore in più,
/// solo delle soglie sulla velocità GPS che già tracciamo.
enum ActivityStatus { stationary, walking, running, driving }

extension ActivityStatusData on ActivityStatus {
  IconData get icon {
    switch (this) {
      case ActivityStatus.stationary:
        return Icons.circle;
      case ActivityStatus.walking:
        return Icons.directions_walk_rounded;
      case ActivityStatus.running:
        return Icons.directions_run_rounded;
      case ActivityStatus.driving:
        return Icons.directions_car_filled_rounded;
    }
  }
}

/// Un membro della tua cerchia (o tu stesso).
class Person {
  const Person({
    required this.id,
    required this.name,
    required this.color,
    this.lat,
    this.lng,
    required this.address,
    required this.lastUpdate,
    required this.batteryPercent,
    required this.isSharingWithMe,
    required this.mode,
    this.isMe = false,
    this.isPremium = false,
    this.speedAlertKmh,
    this.isFuzzyLocation = false,
    this.speedKmh,
  });

  final String id;
  final String name;
  final Color color;

  /// Coordinate reali dell'ultima posizione nota, se disponibile e visibile.
  /// Se [isFuzzyLocation] è vero, sono già arrotondate lato server.
  final double? lat;
  final double? lng;

  final String address;
  final DateTime lastUpdate;
  final int batteryPercent;

  /// True se attualmente vedi la posizione di questa persona.
  final bool isSharingWithMe;
  final SharingMode mode;
  final bool isMe;

  /// Abbonamento Kinly+ attivo.
  final bool isPremium;

  /// Soglia di velocità (km/h) oltre la quale si registra un avviso di
  /// guida (Kinly+); null se questa persona non l'ha impostata.
  final int? speedAlertKmh;

  /// True se questa persona condivide in modalità "approssimativa": [lat]/
  /// [lng] sono già arrotondati dal server, non il punto esatto.
  final bool isFuzzyLocation;

  /// Ultima velocità nota (km/h), se disponibile: usata per mostrare lo
  /// stato dinamico (fermo/a piedi/in corsa/in auto).
  final double? speedKmh;

  /// Dedotto dall'ultima velocità nota: nessuna soglia se non condivide o
  /// non c'è ancora un dato di velocità.
  ActivityStatus get activityStatus {
    final kmh = speedKmh;
    if (kmh == null || kmh < 1) return ActivityStatus.stationary;
    if (kmh < 7) return ActivityStatus.walking;
    if (kmh < 15) return ActivityStatus.running;
    return ActivityStatus.driving;
  }

  bool get isBatteryLow => batteryPercent > 0 && batteryPercent <= 15;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, min(2, parts.first.length)).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  String get lastUpdateLabel {
    final diff = DateTime.now().difference(lastUpdate);
    if (diff.inMinutes < 1) return 'Proprio ora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min fa';
    if (diff.inHours < 24) return '${diff.inHours} h fa';
    return '${diff.inDays} g fa';
  }

  Person copyWith({bool? isSharingWithMe, SharingMode? mode}) {
    return Person(
      id: id,
      name: name,
      color: color,
      lat: lat,
      lng: lng,
      address: address,
      lastUpdate: lastUpdate,
      batteryPercent: batteryPercent,
      isSharingWithMe: isSharingWithMe ?? this.isSharingWithMe,
      mode: mode ?? this.mode,
      isMe: isMe,
      isPremium: isPremium,
      speedAlertKmh: speedAlertKmh,
      isFuzzyLocation: isFuzzyLocation,
      speedKmh: speedKmh,
    );
  }
}
