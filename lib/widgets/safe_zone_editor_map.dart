import 'dart:math';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'kinly_map.dart';

/// Mappa interattiva per "disegnare" un'area (sicura o pericolosa): il
/// perno resta sempre fermo al centro dello schermo, è la MAPPA che si
/// sposta sotto di lui quando l'utente fa pan — lo stesso schema usato da
/// Google Maps e simili per "scegli un punto sulla mappa". Evita del tutto
/// la gestione di un marcatore trascinabile (che in maplibre_gl richiede
/// convertire a mano le coordinate schermo↔geografiche e conflitta
/// facilmente con i gesti di pan della mappa stessa).
///
/// Il cerchio del raggio è disegnato come overlay Flutter (non come layer
/// mappa): la sua dimensione in pixel viene ricalcolata ad ogni movimento
/// della camera in base allo zoom corrente, così resta sempre perfettamente
/// centrato sul perno anche durante il trascinamento (un layer mappa vero
/// si aggiornerebbe solo a gesto concluso, con uno sfasamento visibile).
class SafeZoneEditorMap extends StatefulWidget {
  const SafeZoneEditorMap({
    super.key,
    required this.initialCenter,
    required this.radiusMeters,
    required this.color,
    required this.onCenterChanged,
    this.onMapReady,
  });

  final LatLng initialCenter;
  final int radiusMeters;
  final Color color;
  final ValueChanged<LatLng> onCenterChanged;

  /// Espone il controller al genitore, per poter spostare la camera da
  /// fuori (es. "usa la mia posizione" o un risultato di ricerca indirizzo).
  final ValueChanged<MapLibreMapController>? onMapReady;

  @override
  State<SafeZoneEditorMap> createState() => SafeZoneEditorMapState();
}

class SafeZoneEditorMapState extends State<SafeZoneEditorMap> {
  MapLibreMapController? _controller;
  late double _lat = widget.initialCenter.latitude;
  late double _zoom = _zoomForRadius(widget.radiusMeters.toDouble(), widget.initialCenter.latitude, 130);

  /// Sposta la camera su un nuovo punto (chiamato dal genitore quando
  /// l'utente usa il GPS o cerca un indirizzo).
  Future<void> moveTo(LatLng target) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.animateCamera(CameraUpdate.newLatLng(target));
    widget.onCenterChanged(target);
  }

  static double _zoomForRadius(double radiusMeters, double lat, double targetDiameterPx) {
    final metersPerPixelWanted = (2 * radiusMeters) / targetDiameterPx;
    final z = log(156543.03392 * cos(lat * pi / 180) / metersPerPixelWanted) / log(2);
    return z.clamp(3.0, 19.0);
  }

  double get _metersPerPixel => 156543.03392 * cos(_lat * pi / 180) / pow(2, _zoom);

  @override
  Widget build(BuildContext context) {
    final diameterPx = (2 * widget.radiusMeters) / _metersPerPixel;
    return Stack(
      alignment: Alignment.center,
      children: [
        MapLibreMap(
          styleString: KinlyMap.styleAsset,
          initialCameraPosition: CameraPosition(target: widget.initialCenter, zoom: _zoom),
          onMapCreated: (controller) {
            _controller = controller;
            widget.onMapReady?.call(controller);
          },
          onCameraMove: (position) => setState(() {
            _lat = position.target.latitude;
            _zoom = position.zoom;
          }),
          onCameraIdle: () {
            final target = _controller?.cameraPosition?.target;
            if (target != null) widget.onCenterChanged(target);
          },
          compassEnabled: false,
          logoEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          trackCameraPosition: true,
        ),
        // Il cerchio del raggio: puro overlay, ignora i tocchi così i gesti
        // di pan/zoom arrivano sempre alla mappa sottostante.
        IgnorePointer(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: diameterPx,
            height: diameterPx,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(0.18),
              border: Border.all(color: widget.color, width: 2),
            ),
          ),
        ),
        // Il perno: fermo al centro, la mappa si muove sotto di lui.
        IgnorePointer(
          child: Transform.translate(
            offset: const Offset(0, -18),
            child: Icon(Icons.location_on_rounded, size: 40, color: widget.color, shadows: const [
              Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
            ]),
          ),
        ),
      ],
    );
  }
}
