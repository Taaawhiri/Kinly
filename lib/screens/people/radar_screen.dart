import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/person.dart';
import '../../services/location_tracker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/person_avatar.dart';

/// Radar di prossimità: bussola GPS + magnetometro che indica la direzione
/// e la distanza verso un amico, per ritrovarsi in un posto affollato senza
/// scriversi "dove sei?" a vicenda. Non serve hardware speciale (niente
/// UWB): un GPS e una bussola bastano per un'indicazione utile a corto
/// raggio.
class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key, required this.person});
  final Person person;

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<CompassEvent>? _compassSub;
  Position? _myPosition;
  double? _heading;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final granted = await LocationTracker.instance.requestPermission();
    if (!granted) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 3),
    ).listen((position) {
      if (mounted) setState(() => _myPosition = position);
    });
    // flutter_compass non ha un'implementazione web: niente bussola li',
    // la UI ripiega gia' da sola su un messaggio quando _heading resta null.
    if (!kIsWeb) {
      try {
        _compassSub = FlutterCompass.events?.listen((event) {
          if (mounted) setState(() => _heading = event.heading);
        });
      } catch (_) {
        // Bussola non disponibile su questo dispositivo: va bene, la UI lo gestisce.
      }
    }
    try {
      final current = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _myPosition = current);
    } catch (_) {
      // Arriverà dallo stream.
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _compassSub?.cancel();
    super.dispose();
  }

  double _bearingDegrees(double lat1, double lng1, double lat2, double lng2) {
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaLambda = (lng2 - lng1) * pi / 180;
    final y = sin(deltaLambda) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda);
    final theta = atan2(y, x);
    return (theta * 180 / pi + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    final targetLat = widget.person.lat;
    final targetLng = widget.person.lng;

    return Scaffold(
      appBar: AppBar(title: Text('Radar · ${widget.person.name}')),
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (_permissionDenied) {
              return _buildMessage(
                icon: Icons.location_off_outlined,
                message: 'Serve il permesso di localizzazione per usare il radar.',
              );
            }
            if (targetLat == null || targetLng == null) {
              return _buildMessage(
                icon: Icons.location_disabled_outlined,
                message: '${widget.person.name} non sta condividendo la posizione al momento.',
              );
            }
            if (_myPosition == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final distance = Geolocator.distanceBetween(
              _myPosition!.latitude,
              _myPosition!.longitude,
              targetLat,
              targetLng,
            );
            final bearing = _bearingDegrees(_myPosition!.latitude, _myPosition!.longitude, targetLat, targetLng);
            final heading = _heading;

            if (heading == null) {
              return _buildMessage(
                icon: Icons.explore_off_outlined,
                message: 'Bussola non disponibile su questo dispositivo. Usa la mappa per orientarti.',
              );
            }

            final arrowAngle = (bearing - heading) * pi / 180;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PersonAvatar(person: widget.person, size: 56, showStatusDot: false),
                const SizedBox(height: 24),
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surface,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, spreadRadius: 4)],
                        ),
                      ),
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.divider, width: 1.4)),
                      ),
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.divider, width: 1.4)),
                      ),
                      AnimatedRotation(
                        turns: arrowAngle / (2 * pi),
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: Icon(Icons.navigation_rounded, size: 96, color: widget.person.color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  distance >= 1000 ? '${(distance / 1000).toStringAsFixed(1)} km' : '${distance.round()} m',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  distance < 50 ? 'Sei vicinissimo!' : 'Segui la freccia per raggiungere ${widget.person.name}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessage({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
