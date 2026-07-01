import 'dart:math';
import 'package:flutter/material.dart';
import 'sharing_mode.dart';

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
  });

  final String id;
  final String name;
  final Color color;

  /// Coordinate reali dell'ultima posizione nota, se disponibile e visibile.
  final double? lat;
  final double? lng;

  final String address;
  final DateTime lastUpdate;
  final int batteryPercent;

  /// True se attualmente vedi la posizione di questa persona.
  final bool isSharingWithMe;
  final SharingMode mode;
  final bool isMe;

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
    );
  }
}
