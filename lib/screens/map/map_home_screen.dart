import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../models/help_request.dart';
import '../../models/nearby_poi.dart';
import '../../models/ping.dart';
import '../../models/shopping_stop.dart';
import '../../services/nearby_poi_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/circle_chip.dart';
import '../../widgets/kinly_map.dart';
import '../../widgets/person_list_tile.dart';
import '../circles/meeting_point_screen.dart';
import '../people/help_request_screen.dart';
import '../people/person_detail_screen.dart';
import '../people/sos_alert_screen.dart';

class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key});

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

const double _sheetInitialSize = 0.42;
const double _sheetMinSize = 0.14;
const double _sheetMaxSize = 0.9;

class _MapHomeScreenState extends State<MapHomeScreen> {
  final _sheetController = DraggableScrollableController();
  MapLibreMapController? _mapController;
  bool _centering = false;

  List<NearbyPoi> _nearbyPois = [];
  DateTime? _lastPoiFetchAt;
  double? _lastPoiFetchLat;
  double? _lastPoiFetchLng;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  /// Aggiorna i punti di interesse vicini solo se ti sei spostato/a
  /// abbastanza o è passato un po' di tempo, per non interrogare Overpass
  /// ad ogni singolo aggiornamento di posizione.
  void _maybeFetchNearbyPois(double lat, double lng) {
    final now = DateTime.now();
    if (_lastPoiFetchAt != null && now.difference(_lastPoiFetchAt!) < const Duration(minutes: 2)) return;
    final movedEnough = _lastPoiFetchLat == null || Geolocator.distanceBetween(_lastPoiFetchLat!, _lastPoiFetchLng!, lat, lng) > 400;
    final staleEnough = _lastPoiFetchAt == null || now.difference(_lastPoiFetchAt!) > const Duration(minutes: 15);
    if (!movedEnough && !staleEnough) return;
    _lastPoiFetchAt = now;
    _lastPoiFetchLat = lat;
    _lastPoiFetchLng = lng;
    unawaited(_fetchNearbyPois(lat, lng));
  }

  Future<void> _fetchNearbyPois(double lat, double lng) async {
    try {
      final pois = await NearbyPoiService.instance.nearby(lat, lng);
      if (mounted) setState(() => _nearbyPois = pois);
    } catch (_) {
      // Solo un livello informativo: se fallisce non deve rompere la mappa.
    }
  }

  Future<void> _centerOnMyLocation() async {
    setState(() => _centering = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 15));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non siamo riusciti a rilevare la tua posizione.')));
      }
    } finally {
      if (mounted) setState(() => _centering = false);
    }
  }

  Future<void> _confirmAndTriggerSos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Attivare l\'SOS?'),
        content: const Text(
          'La tua posizione esatta verrà condivisa subito con tutte le tue cerchie, anche se hai una modalità di condivisione ridotta. Nessuna registrazione audio: solo posizione.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annulla')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentCoral),
            child: const Text('Attiva SOS'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final position = await Geolocator.getCurrentPosition();
      await AppState.instance.triggerSos(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non siamo riusciti a rilevare la tua posizione per l\'SOS.')));
      }
    }
  }

  void _openMeetingPointEntry() {
    final state = AppState.instance;
    final circle = state.activeCircleId != null
        ? state.circleById(state.activeCircleId!)
        : (state.circles.length == 1 ? state.circles.first : null);
    if (circle != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => MeetingPointScreen(circle: circle)));
      return;
    }
    if (state.circles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crea o entra in una cerchia prima.')));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(alignment: Alignment.centerLeft, child: Text('Per quale cerchia?', style: TextStyle(fontWeight: FontWeight.w800))),
            ),
            for (final c in state.circles)
              ListTile(
                leading: Icon(c.icon, color: c.color),
                title: Text(c.name),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => MeetingPointScreen(circle: c)));
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool _hasAnyBanner(AppState state) {
    return state.activeSosAlerts.any((a) => a.profileId != state.me.id) ||
        state.activeHelpRequests.any((h) => h.profileId != state.me.id) ||
        state.recentEncounters.isNotEmpty ||
        state.incomingPings.isNotEmpty ||
        state.othersActiveShoppingStops.isNotEmpty ||
        (state.myActiveShoppingStop != null && state.requestsForStop(state.myActiveShoppingStop!.id).isNotEmpty);
  }

  void _openHelpRequestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => const _HelpRequestSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final people = state.visiblePeople();
        if (state.me.lat != null && state.me.lng != null) {
          _maybeFetchNearbyPois(state.me.lat!, state.me.lng!);
        }

        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  KinlyMap(
                    people: [state.me, ...people.where((p) => p.isSharingWithMe)],
                    safeZones: state.visibleSafeZones(),
                    meetingPoints: state.visibleMeetingPoints(),
                    nearbyPois: _nearbyPois,
                    onPersonTap: (personId) => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: personId)),
                    ),
                    onMapReady: (controller) => _mapController = controller,
                  ),
                  // Align forza dei vincoli "loose" sul figlio: senza, lo
                  // Stack (fit: expand) costringerebbe il CustomPaint del
                  // logo a riempire tutto lo schermo (e a "rubare" i gesti
                  // di pan/zoom destinati alla mappa sottostante).
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 0, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const KinlyLogo(size: 34),
                            const SizedBox(height: 10),
                            _HelpButton(
                              active: state.myActiveHelpRequest != null,
                              onTap: () {
                                final mine = state.myActiveHelpRequest;
                                if (mine != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => HelpRequestScreen(request: mine, person: state.me)),
                                  );
                                } else {
                                  _openHelpRequestSheet();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                        child: _SosButton(
                          active: state.myActiveSos != null,
                          onTap: () {
                            final mySos = state.myActiveSos;
                            if (mySos != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => SosAlertScreen(alert: mySos, person: state.me)),
                              );
                            } else {
                              _confirmAndTriggerSos();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  if (_hasAnyBanner(state))
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 112, 16, 0),
                        child: Column(
                          children: [
                            for (final alert in state.activeSosAlerts.where((a) => a.profileId != state.me.id))
                              _SosBanner(
                                personName: state.personById(alert.profileId)?.name ?? 'Qualcuno',
                                onTap: () {
                                  final person = state.personById(alert.profileId);
                                  if (person != null) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => SosAlertScreen(alert: alert, person: person)),
                                    );
                                  }
                                },
                              ),
                            for (final request in state.activeHelpRequests.where((h) => h.profileId != state.me.id))
                              _HelpBanner(
                                personName: state.personById(request.profileId)?.name ?? 'Qualcuno',
                                reasonLabel: request.reason.label,
                                onTap: () {
                                  final person = state.personById(request.profileId);
                                  if (person != null) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => HelpRequestScreen(request: request, person: person)),
                                    );
                                  }
                                },
                              ),
                            for (final encounter in state.recentEncounters)
                              _EncounterBanner(
                                personName: state.personById(encounter.otherPersonId(state.me.id))?.name ?? 'Qualcuno',
                                onHighFive: () {
                                  state.sendPing(toId: encounter.otherPersonId(state.me.id), kind: PingKind.highFive);
                                  state.dismissEncounter(encounter.id);
                                },
                                onDismiss: () => state.dismissEncounter(encounter.id),
                              ),
                            for (final ping in state.incomingPings)
                              _PingBanner(
                                personName: state.personById(ping.fromId)?.name ?? 'Qualcuno',
                                kind: ping.kind,
                                onDismiss: () => state.dismissPing(ping.id),
                              ),
                            for (final stop in state.othersActiveShoppingStops)
                              _ShoppingStopBanner(
                                personName: state.personById(stop.profileId)?.name ?? 'Qualcuno',
                                stop: stop,
                                onSend: (note) => state.sendShoppingRequest(stopId: stop.id, note: note),
                              ),
                            if (state.myActiveShoppingStop != null && state.requestsForStop(state.myActiveShoppingStop!.id).isNotEmpty)
                              _MyShoppingRequestsBanner(
                                requests: state.requestsForStop(state.myActiveShoppingStop!.id),
                                nameFor: (id) => state.personById(id)?.name ?? 'Qualcuno',
                              ),
                          ],
                        ),
                      ),
                    ),
                  // La barra delle cerchie e il pulsante GPS seguono insieme
                  // il bordo superiore del pannello, alla stessa altezza:
                  // quando lo trascini giù, scendono anche loro, invece di
                  // restare fermi in mezzo alla mappa.
                  AnimatedBuilder(
                    animation: _sheetController,
                    builder: (context, child) {
                      final extent = _sheetController.isAttached ? _sheetController.size : _sheetInitialSize;
                      final sheetTop = constraints.maxHeight * (1 - extent);
                      return Positioned(
                        left: 0,
                        right: 0,
                        top: sheetTop - 52,
                        child: child!,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: SizedBox(
                        height: 40,
                        child: Row(
                          children: [
                            Expanded(
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  CircleChip(
                                    label: 'Tutte',
                                    isSelected: state.activeCircleId == null,
                                    onTap: () => state.setActiveCircle(null),
                                  ),
                                  const SizedBox(width: 8),
                                  for (final c in state.circles) ...[
                                    CircleChip(
                                      label: c.name,
                                      icon: c.icon,
                                      color: c.color,
                                      isSelected: state.activeCircleId == c.id,
                                      onTap: () => state.setActiveCircle(c.id),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: _CenterOnMeButton(loading: _centering, onTap: _centerOnMyLocation),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  DraggableScrollableSheet(
                    controller: _sheetController,
                    initialChildSize: _sheetInitialSize,
                    minChildSize: _sheetMinSize,
                    maxChildSize: _sheetMaxSize,
                    // Niente snap: il pannello resta esattamente dove lo
                    // lasci. Con lo snap attivo, un trascinamento verso il
                    // basso non abbastanza deciso tornava indietro al punto
                    // di partenza invece di ridursi — sembrava "bloccato".
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(4))),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                              child: Row(
                                children: [
                                  Text('La tua cerchia', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                                  const Spacer(),
                                  Text('${people.length} persone', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
                                  IconButton(
                                    icon: const Icon(Icons.add_location_alt_outlined, size: 20),
                                    tooltip: 'Nuovo punto d\'incontro',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: _openMeetingPointEntry,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                itemCount: people.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final p = people[i];
                                  return PersonListTile(
                                    person: p,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: p.id)),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _SosButton extends StatelessWidget {
  const _SosButton({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.accentCoral,
          border: active ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: [BoxShadow(color: AppTheme.accentCoral.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: Semantics(
          label: active ? 'SOS attivo' : 'Attiva SOS',
          child: Icon(Icons.emergency_rounded, color: Colors.white, size: active ? 30 : 26),
        ),
      ),
    );
  }
}

class _SosBanner extends StatelessWidget {
  const _SosBanner({required this.personName, required this.onTap});
  final String personName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.accentCoral,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppTheme.accentCoral.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$personName ha attivato l\'SOS · tocca per vedere dove si trova',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpButton extends StatelessWidget {
  const _HelpButton({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.accentAmber,
          border: active ? Border.all(color: Colors.white, width: 2.4) : null,
          boxShadow: [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        alignment: Alignment.center,
        child: Semantics(
          label: active ? 'Aiuto richiesto' : 'Chiedi aiuto',
          child: const Icon(Icons.pan_tool_alt_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _HelpBanner extends StatelessWidget {
  const _HelpBanner({required this.personName, required this.reasonLabel, required this.onTap});
  final String personName;
  final String reasonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.accentAmber,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.pan_tool_alt_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$personName ha bisogno di aiuto ($reasonLabel) · tocca per i dettagli',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EncounterBanner extends StatelessWidget {
  const _EncounterBanner({required this.personName, required this.onHighFive, required this.onDismiss});
  final String personName;
  final VoidCallback onHighFive;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3)),
      ]),
      child: Row(
        children: [
          const Text('🖐️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ti sei incrociato con $personName!',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.textPrimary),
            ),
          ),
          TextButton(onPressed: onHighFive, child: const Text('High five')),
          IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: onDismiss, visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}

class _PingBanner extends StatelessWidget {
  const _PingBanner({required this.personName, required this.kind, required this.onDismiss});
  final String personName;
  final PingKind kind;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3)),
      ]),
      child: Row(
        children: [
          Text(kind.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$personName: ${kind.label}',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.textPrimary),
            ),
          ),
          IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: onDismiss, visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}

class _ShoppingStopBanner extends StatefulWidget {
  const _ShoppingStopBanner({required this.personName, required this.stop, required this.onSend});
  final String personName;
  final ShoppingStop stop;
  final ValueChanged<String> onSend;

  @override
  State<_ShoppingStopBanner> createState() => _ShoppingStopBannerState();
}

class _ShoppingStopBannerState extends State<_ShoppingStopBanner> {
  final _controller = TextEditingController();
  bool _expanded = false;
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final note = _controller.text.trim();
    if (note.isEmpty) return;
    widget.onSend(note);
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.stop.placeName != null ? ' (${widget.stop.placeName})' : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3)),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🛒', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${widget.personName} è al negozio$place',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.textPrimary),
                ),
              ),
              if (_sent)
                const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 18)
              else
                TextButton(onPressed: () => setState(() => _expanded = !_expanded), child: const Text('Chiedi qualcosa')),
            ],
          ),
          if (_expanded && !_sent) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Es. Latte!',
                      filled: true,
                      fillColor: AppTheme.surfaceAlt,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send_rounded, size: 18), onPressed: _send),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MyShoppingRequestsBanner extends StatelessWidget {
  const _MyShoppingRequestsBanner({required this.requests, required this.nameFor});
  final List<ShoppingRequest> requests;
  final String Function(String) nameFor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ti hanno chiesto:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          for (final r in requests)
            Text('${nameFor(r.fromId)}: ${r.note}', style: TextStyle(fontSize: 12.5, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.reason, required this.selected, required this.onTap});
  final HelpRequestReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentAmber.withOpacity(0.14) : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.accentAmber : Colors.transparent, width: 1.6),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentAmber.withOpacity(selected ? 0.3 : 0.15)),
              alignment: Alignment.center,
              child: Icon(reason.icon, size: 17, color: AppTheme.accentAmber),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                reason.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpRequestSheet extends StatefulWidget {
  const _HelpRequestSheet();

  @override
  State<_HelpRequestSheet> createState() => _HelpRequestSheetState();
}

class _CenterOnMeButton extends StatelessWidget {
  const _CenterOnMeButton({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: loading ? null : onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2))
              : Icon(Icons.my_location_rounded, color: AppTheme.primary, size: 20),
        ),
      ),
    );
  }
}

class _HelpRequestSheetState extends State<_HelpRequestSheet> {
  final _noteController = TextEditingController();
  HelpRequestReason _reason = HelpRequestReason.flatTire;
  String? _circleId;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final state = AppState.instance;
    _circleId = state.activeCircleId ?? (state.circles.isNotEmpty ? state.circles.first.id : null);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final circleId = _circleId;
    if (circleId == null) {
      setState(() => _error = 'Crea o entra in una cerchia prima di chiedere aiuto.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final position = await Geolocator.getCurrentPosition();
      await AppState.instance.triggerHelpRequest(
        circleId: circleId,
        reason: _reason,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        lat: position.latitude,
        lng: position.longitude,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _error = 'Non siamo riusciti a inviare la richiesta. Riprova.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chiedi aiuto', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text(
              'Avvisa la tua cerchia con un motivo e la tua posizione attuale. A differenza dell\'SOS, non cambia la tua modalità di condivisione.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (state.circles.length > 1) ...[
              Text('Cerchia', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final circle in state.circles)
                    ChoiceChip(
                      label: Text(circle.name),
                      selected: _circleId == circle.id,
                      onSelected: (_) => setState(() => _circleId = circle.id),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Text('Motivo', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
              children: [
                for (final reason in HelpRequestReason.values) _ReasonCard(reason: reason, selected: _reason == reason, onTap: () => setState(() => _reason = reason)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLength: 140,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Aggiungi un dettaglio (opzionale)',
                filled: true,
                fillColor: AppTheme.surfaceAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppTheme.accentCoral, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _sending ? null : _send,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: AppTheme.accentAmber),
              child: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Text('Invia richiesta'),
            ),
          ],
        ),
      ),
    );
  }
}
