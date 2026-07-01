import 'dart:math';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Genera i punti di un cerchio di raggio [radiusMeters] intorno a un
/// centro, per disegnarlo come poligono su una mappa: a differenza di un
/// cerchio in pixel (che cambia dimensione con lo zoom), questo rappresenta
/// sempre la distanza reale in metri, indipendentemente dallo zoom.
List<LatLng> circlePolygonPoints(double lat, double lng, double radiusMeters, {int segments = 64}) {
  const earthRadius = 6371000.0;
  final latRad = lat * pi / 180;
  final lngRad = lng * pi / 180;
  final angularDistance = radiusMeters / earthRadius;

  final points = <LatLng>[];
  for (var i = 0; i <= segments; i++) {
    final bearing = 2 * pi * i / segments;
    final destLat = asin(sin(latRad) * cos(angularDistance) + cos(latRad) * sin(angularDistance) * cos(bearing));
    final destLng = lngRad +
        atan2(
          sin(bearing) * sin(angularDistance) * cos(latRad),
          cos(angularDistance) - sin(latRad) * sin(destLat),
        );
    points.add(LatLng(destLat * 180 / pi, destLng * 180 / pi));
  }
  return points;
}
