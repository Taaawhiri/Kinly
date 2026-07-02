import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../models/location_history_point.dart';
import '../theme/app_theme.dart';
import '../utils/color_hex.dart';
import '../widgets/kinly_map.dart';

/// Disegna il percorso di un tragitto come una linea sulla mappa, con un
/// marcatore all'inizio e uno alla fine, più un cursore che rifà il
/// tragitto nel tempo (play/pausa + slider) invece di mostrare solo la
/// linea statica.
class TripRouteMap extends StatefulWidget {
  const TripRouteMap({super.key, required this.points});
  final List<LocationHistoryPoint> points;

  @override
  State<TripRouteMap> createState() => _TripRouteMapState();
}

class _TripRouteMapState extends State<TripRouteMap> with SingleTickerProviderStateMixin {
  MapLibreMapController? _mapController;
  Circle? _replayMarker;
  bool _routeReady = false;

  /// La riproduzione dura sempre questo tempo, indipendentemente da quanto
  /// sia durato il tragitto vero (potrebbe essere di ore): un "replay"
  /// dovrebbe essere rapido da guardare, non richiedere lo stesso tempo del
  /// tragitto originale.
  static const _playbackDuration = Duration(seconds: 8);

  late final AnimationController _playback = AnimationController(vsync: this, duration: _playbackDuration)
    ..addListener(() {
      setState(() {});
      _moveReplayMarker(_playback.value);
    });

  @override
  void dispose() {
    _playback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) return const SizedBox.shrink();
    final first = widget.points.first;
    return Column(
      children: [
        Expanded(
          child: MapLibreMap(
            styleString: KinlyMap.styleAsset,
            initialCameraPosition: CameraPosition(target: LatLng(first.lat, first.lng), zoom: 13),
            onMapCreated: (controller) => _mapController = controller,
            onStyleLoadedCallback: _drawRoute,
            compassEnabled: false,
            logoEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
          ),
        ),
        if (widget.points.length > 1) _buildReplayBar(),
      ],
    );
  }

  Widget _buildReplayBar() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_playback.isAnimating ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, size: 32, color: AppTheme.primary),
            onPressed: _routeReady ? _togglePlayback : null,
            tooltip: _playback.isAnimating ? 'Pausa' : 'Rivedi il tragitto',
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(trackHeight: 3, overlayShape: SliderComponentShape.noOverlay),
              child: Slider(
                value: _playback.value,
                onChangeStart: (_) => _playback.stop(),
                onChanged: _routeReady ? (v) => setState(() => _playback.value = v) : null,
                onChangeEnd: (v) => _moveReplayMarker(v),
                activeColor: AppTheme.primary,
                inactiveColor: AppTheme.divider,
              ),
            ),
          ),
          SizedBox(
            width: 46,
            child: Text(
              _elapsedLabel(_playback.value),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _togglePlayback() {
    if (_playback.isAnimating) {
      _playback.stop();
    } else {
      _playback.forward(from: _playback.value >= 1.0 ? 0.0 : _playback.value);
    }
  }

  /// Tempo trascorso NEL tragitto vero alla posizione attuale del cursore
  /// (non il tempo di riproduzione, compresso): dà il senso di quanto sia
  /// durato davvero quel tratto.
  String _elapsedLabel(double progress) {
    final points = widget.points;
    if (points.length < 2) return '';
    final totalMinutes = points.last.recordedAt.difference(points.first.recordedAt).inMinutes;
    final elapsedMinutes = (totalMinutes * progress).round();
    return '$elapsedMinutes min';
  }

  Future<void> _drawRoute() async {
    final controller = _mapController;
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
    if (widget.points.length > 1) {
      _replayMarker = await controller.addCircle(
        CircleOptions(geometry: line.first, circleRadius: 9, circleColor: AppTheme.accentAmber.toHex(), circleStrokeColor: '#FFFFFF', circleStrokeWidth: 3),
      );
    }

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

    if (mounted) setState(() => _routeReady = true);
  }

  Future<void> _moveReplayMarker(double progress) async {
    final controller = _mapController;
    final marker = _replayMarker;
    if (controller == null || marker == null) return;
    await controller.updateCircle(marker, CircleOptions(geometry: _interpolatedPosition(progress)));
  }

  /// Posizione lungo il tragitto al tempo `progress` (0..1), interpolata in
  /// base all'orario reale dei punti registrati (non solo alla distanza):
  /// una sosta lunga tiene il cursore fermo più a lungo, come è successo
  /// davvero, invece di scorrere a velocità costante.
  LatLng _interpolatedPosition(double progress) {
    final points = widget.points;
    final first = points.first;
    if (points.length < 2) return LatLng(first.lat, first.lng);

    final totalMs = points.last.recordedAt.difference(first.recordedAt).inMilliseconds;
    if (totalMs <= 0) return LatLng(first.lat, first.lng);
    final targetMs = totalMs * progress.clamp(0.0, 1.0);

    for (var i = 1; i < points.length; i++) {
      final segmentEndMs = points[i].recordedAt.difference(first.recordedAt).inMilliseconds;
      if (targetMs <= segmentEndMs || i == points.length - 1) {
        final segmentStartMs = points[i - 1].recordedAt.difference(first.recordedAt).inMilliseconds;
        final segmentSpanMs = segmentEndMs - segmentStartMs;
        final t = segmentSpanMs <= 0 ? 1.0 : ((targetMs - segmentStartMs) / segmentSpanMs).clamp(0.0, 1.0);
        return LatLng(
          points[i - 1].lat + (points[i].lat - points[i - 1].lat) * t,
          points[i - 1].lng + (points[i].lng - points[i - 1].lng) * t,
        );
      }
    }
    return LatLng(points.last.lat, points.last.lng);
  }
}
