import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/safe_zone.dart';
import '../utils/color_hex.dart';
import '../utils/geo_circle.dart';
import '../widgets/kinly_map.dart';

/// Mostra le aree sicure di una cerchia come cerchi colorati disegnati in
/// scala reale (metri, non pixel): a colpo d'occhio si vede dove sono e
/// quanto sono grandi, invece di leggerlo solo in una lista.
class SafeZonesMap extends StatefulWidget {
  const SafeZonesMap({super.key, required this.zones});
  final List<SafeZone> zones;

  @override
  State<SafeZonesMap> createState() => _SafeZonesMapState();
}

class _SafeZonesMapState extends State<SafeZonesMap> {
  MapLibreMapController? _controller;

  static const _colorsByKind = {
    SafeZoneKind.home: Color(0xFF4A63E7),
    SafeZoneKind.work: Color(0xFFE7A54A),
    SafeZoneKind.school: Color(0xFF17924E),
    SafeZoneKind.other: Color(0xFF8A6DE7),
  };

  @override
  void didUpdateWidget(covariant SafeZonesMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zones != widget.zones) {
      unawaited(_drawZones());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.zones.isEmpty) return const SizedBox.shrink();
    final first = widget.zones.first;
    return MapLibreMap(
      styleString: KinlyMap.styleAsset,
      initialCameraPosition: CameraPosition(target: LatLng(first.lat, first.lng), zoom: 13),
      onMapCreated: (controller) => _controller = controller,
      onStyleLoadedCallback: () async {
        await _drawZones();
        await _fitToZones();
      },
      compassEnabled: false,
      logoEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
    );
  }

  Future<void> _drawZones() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.clearFills();
    for (final zone in widget.zones) {
      final color = _colorsByKind[zone.kind] ?? _colorsByKind[SafeZoneKind.other]!;
      final ring = circlePolygonPoints(zone.lat, zone.lng, zone.radiusMeters.toDouble());
      await controller.addFill(
        FillOptions(
          geometry: [ring],
          fillColor: color.toHex(),
          fillOpacity: 0.22,
          fillOutlineColor: color.toHex(),
        ),
      );
    }
  }

  Future<void> _fitToZones() async {
    final controller = _controller;
    if (controller == null || widget.zones.isEmpty) return;
    if (widget.zones.length == 1) {
      final zone = widget.zones.first;
      await controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(zone.lat, zone.lng), 14));
      return;
    }
    var minLat = widget.zones.first.lat, maxLat = widget.zones.first.lat;
    var minLng = widget.zones.first.lng, maxLng = widget.zones.first.lng;
    for (final zone in widget.zones) {
      if (zone.lat < minLat) minLat = zone.lat;
      if (zone.lat > maxLat) maxLat = zone.lat;
      if (zone.lng < minLng) minLng = zone.lng;
      if (zone.lng > maxLng) maxLng = zone.lng;
    }
    final bounds = LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, left: 40, top: 40, right: 40, bottom: 40));
  }
}
