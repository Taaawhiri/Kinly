import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/location_history_point.dart';
import '../theme/app_theme.dart';
import '../utils/color_hex.dart';
import '../widgets/kinly_map.dart';

/// Disegna il percorso di un tragitto come una linea sulla mappa, con un
/// marcatore all'inizio e uno alla fine.
class TripRouteMap extends StatefulWidget {
  const TripRouteMap({super.key, required this.points});
  final List<LocationHistoryPoint> points;

  @override
  State<TripRouteMap> createState() => _TripRouteMapState();
}

class _TripRouteMapState extends State<TripRouteMap> {
  MapLibreMapController? _controller;

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) return const SizedBox.shrink();
    final first = widget.points.first;
    return MapLibreMap(
      styleString: KinlyMap.styleAsset,
      initialCameraPosition: CameraPosition(target: LatLng(first.lat, first.lng), zoom: 13),
      onMapCreated: (controller) => _controller = controller,
      onStyleLoadedCallback: _drawRoute,
      compassEnabled: false,
      logoEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
    );
  }

  Future<void> _drawRoute() async {
    final controller = _controller;
    if (controller == null || widget.points.isEmpty) return;
    final line = widget.points.map((p) => LatLng(p.lat, p.lng)).toList();

    await controller.addLine(
      LineOptions(geometry: line, lineColor: AppTheme.primary.toHex(), lineWidth: 4, lineOpacity: 0.85),
    );
    await controller.addCircle(
      CircleOptions(geometry: line.first, circleRadius: 7, circleColor: AppTheme.accentGreen.toHex(), circleStrokeColor: '#FFFFFF', circleStrokeWidth: 2),
    );
    await controller.addCircle(
      CircleOptions(geometry: line.last, circleRadius: 7, circleColor: AppTheme.accentCoral.toHex(), circleStrokeColor: '#FFFFFF', circleStrokeWidth: 2),
    );

    var minLat = line.first.latitude, maxLat = line.first.latitude;
    var minLng = line.first.longitude, maxLng = line.first.longitude;
    for (final p in line) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
        left: 40,
        top: 40,
        right: 40,
        bottom: 40,
      ),
    );
  }
}
