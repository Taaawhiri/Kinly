import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/help_request.dart';
import '../../models/ping.dart';
import '../../models/safe_zone.dart';
import '../../models/shopping_stop.dart';
import '../../services/crash_detection_service.dart';
import '../../services/emergency_sms_settings.dart';
import '../../services/kinly_repository.dart';
import '../../services/walk_me_home_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/blurred_bottom_sheet.dart';
import '../../widgets/circle_chip.dart';
import '../../widgets/kinly_map.dart';
import '../../widgets/person_list_tile.dart';
import '../circles/meeting_point_screen.dart';
import '../people/help_request_screen.dart';
import '../people/person_detail_screen.dart';
import '../people/sos_alert_screen.dart';
import '../premium/safe_zones_screen.dart';

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

  @override
  void initState() {
    super.initState();
    // La mappa è la schermata sempre viva dell'app (IndexedStack): è il
    // posto giusto dove agganciare il conto alla rovescia del rilevamento
    // incidenti, che deve poter apparire in qualsiasi momento.
    CrashDetectionService.instance.onPossibleCrash = _showCrashCountdown;
  }

  @override
  void dispose() {
    if (CrashDetectionService.instance.onPossibleCrash == _showCrashCountdown) {
      CrashDetectionService.instance.onPossibleCrash = null;
    }
    _sheetController.dispose();
    super.dispose();
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
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition();
      await AppState.instance.triggerSos(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      if (!mounted) return;
      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non siamo riusciti a rilevare la tua posizione per l\'SOS.')));
      } else {
        // Posizione trovata ma invio fallito: probabilmente non c'è
        // internet. Proponi il piano B via SMS, se un numero è configurato.
        await _offerSmsFallback(position);
      }
    }
  }

  /// SOS via SMS quando internet non c'è: apre l'app SMS con destinatario e
  /// testo (coordinate + link mappa) già compilati — l'invio lo confermi tu.
  Future<void> _offerSmsFallback(Position position) async {
    final number = await EmergencySmsSettings.instance.getNumber();
    if (!mounted) return;
    if (number == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('SOS non inviato (sei offline?). Imposta un numero SOS via SMS in Privacy e sicurezza per avere un piano B.'),
      ));
      return;
    }
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Niente internet: SOS via SMS?'),
        content: Text('Non siamo riusciti a inviare l\'SOS online. Vuoi mandare un SMS con la tua posizione a $number?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentCoral),
            child: const Text('Prepara SMS'),
          ),
        ],
      ),
    );
    if (send != true) return;
    final body = Uri.encodeComponent(
      'SOS da Kinly! Ho bisogno di aiuto. La mia posizione: '
      'https://maps.google.com/?q=${position.latitude},${position.longitude}',
    );
    final uri = Uri.parse('sms:$number?body=$body');
    await launchUrl(uri);
  }

  // -----------------------------------------------------------------------
  // "Accompagnami": sessione a tempo con avviso automatico se non confermi.
  // -----------------------------------------------------------------------

  void _onWalkMeHomeTap() {
    final walk = WalkMeHomeService.instance;
    if (walk.isActive) {
      final remaining = walk.remaining.inMinutes + 1;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Accompagnami attivo'),
          content: Text('Se non confermi entro ~$remaining min, la tua cerchia riceve un avviso con la tua posizione.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Chiudi')),
            FilledButton(
              onPressed: () {
                walk.confirmArrival();
                Navigator.of(context).pop();
              },
              child: const Text('Sono arrivato/a'),
            ),
          ],
        ),
      );
      return;
    }

    final state = AppState.instance;
    if (state.circles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crea o entra in una cerchia prima.')));
      return;
    }
    final circleId = state.activeCircleId ?? state.circles.first.id;
    showBlurredModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Accompagnami', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text(
                'Scegli in quanto tempo prevedi di arrivare: se non confermi entro quel tempo (o non entri in un\'area Casa), la tua cerchia riceve automaticamente un avviso con la tua posizione.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final minutes in [10, 20, 30, 45, 60])
                    ActionChip(
                      label: Text('$minutes min'),
                      onPressed: () {
                        WalkMeHomeService.instance.start(duration: Duration(minutes: minutes), circleId: circleId);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Nota: se il telefono chiude del tutto l\'app prima della scadenza, l\'avviso automatico potrebbe non partire.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Rilevamento incidenti: conto alla rovescia prima dell'SOS automatico.
  // -----------------------------------------------------------------------

  void _showCrashCountdown() {
    if (!mounted) return;
    var secondsLeft = 30;
    var cancelled = false;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          if (secondsLeft > 0 && !cancelled) {
            Future.delayed(const Duration(seconds: 1), () {
              if (cancelled) return;
              secondsLeft -= 1;
              if (secondsLeft <= 0) {
                Navigator.of(dialogContext).pop();
                unawaited(_triggerSosFromCrash());
              } else {
                setDialogState(() {});
              }
            });
          }
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text('Possibile incidente rilevato'),
            content: Text('SOS automatico tra $secondsLeft secondi. Stai bene? Annulla se è un falso allarme.'),
            actions: [
              FilledButton(
                onPressed: () {
                  cancelled = true;
                  Navigator.of(dialogContext).pop();
                },
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: const Text('Sto bene, annulla'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _triggerSosFromCrash() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      await AppState.instance.triggerSos(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      final me = AppState.instance.me;
      if (me.lat != null && me.lng != null) {
        try {
          await AppState.instance.triggerSos(lat: me.lat!, lng: me.lng!);
        } catch (_) {
          // Offline: non c'è altro da fare in automatico.
        }
      }
    }
  }

  // -----------------------------------------------------------------------
  // Link "seguimi" per chi non ha l'app.
  // -----------------------------------------------------------------------

  void _openLiveShareSheet() {
    showBlurredModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Condividi la posizione con un link', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 6),
              Text(
                'Chi riceve il link vede la tua posizione live dal browser, anche senza l\'app. Il link scade da solo.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, duration) in [('1 ora', Duration(hours: 1)), ('3 ore', Duration(hours: 3)), ('24 ore', Duration(hours: 24))])
                    ActionChip(
                      label: Text(label),
                      onPressed: () async {
                        Navigator.of(sheetContext).pop();
                        try {
                          final url = await KinlyRepository.instance.createLiveShareLink(duration);
                          await Share.share('Segui la mia posizione live su Kinly (valido $label): $url');
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non siamo riusciti a creare il link. Riprova.')));
                          }
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
    showBlurredModalBottomSheet(
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
        (state.myActiveShoppingStop != null && state.requestsForStop(state.myActiveShoppingStop!.id).isNotEmpty) ||
        WalkMeHomeService.instance.isActive;
  }

  void _openMeetingPointInfo(String meetingPointId) {
    final state = AppState.instance;
    final point = state.meetingPointById(meetingPointId);
    if (point == null) return;
    final circle = state.circleById(point.circleId);
    if (circle != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => MeetingPointScreen(circle: circle)));
    }
  }

  void _openSafeZoneInfo(String zoneId) {
    final state = AppState.instance;
    final zone = state.safeZoneById(zoneId);
    if (zone == null) return;
    final circle = state.circleById(zone.circleId);
    showBlurredModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: zone.kind.mapColor.withOpacity(0.15)),
                    alignment: Alignment.center,
                    child: Icon(zone.kind.icon, color: zone.kind.mapColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(zone.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                        Text('${zone.kind.label} · raggio ${zone.radiusMeters} m', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
              if (circle != null) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SafeZonesScreen(circle: circle)));
                  },
                  icon: const Icon(Icons.fence_rounded, size: 18),
                  label: const Text('Gestisci aree sicure'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openHelpRequestSheet() {
    showBlurredModalBottomSheet(
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
      listenable: Listenable.merge([AppState.instance, WalkMeHomeService.instance]),
      builder: (context, _) {
        final state = AppState.instance;
        final people = state.visiblePeople();

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
                    onPersonTap: (personId) => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: personId)),
                    ),
                    onMapReady: (controller) => _mapController = controller,
                    onMeetingPointTap: (id) => _openMeetingPointInfo(id),
                    onSafeZoneTap: (id) => _openSafeZoneInfo(id),
                  ),
                  // Sfoca la mappa man mano che trascini su il pannello "La
                  // tua cerchia" oltre la sua altezza di riposo: l'attenzione
                  // si sposta sulla lista senza uno scatto netto. IgnorePointer
                  // evita che questo livello (trasparente, sopra la mappa)
                  // rubi i gesti di pan/zoom quando non sta sfocando nulla.
                  AnimatedBuilder(
                    animation: _sheetController,
                    builder: (context, child) {
                      final extent = _sheetController.isAttached ? _sheetController.size : _sheetInitialSize;
                      final t = ((extent - _sheetInitialSize) / (_sheetMaxSize - _sheetInitialSize)).clamp(0.0, 1.0);
                      if (t <= 0) return const SizedBox.shrink();
                      return IgnorePointer(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6 * t, sigmaY: 6 * t),
                          child: Container(color: Colors.transparent),
                        ),
                      );
                    },
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                        child: _EmergencyActionsGroup(
                          sosActive: state.myActiveSos != null,
                          helpActive: state.myActiveHelpRequest != null,
                          walkActive: WalkMeHomeService.instance.isActive,
                          onWalkTap: _onWalkMeHomeTap,
                          onSosTap: () {
                            final mySos = state.myActiveSos;
                            if (mySos != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => SosAlertScreen(alert: mySos, person: state.me)),
                              );
                            } else {
                              _confirmAndTriggerSos();
                            }
                          },
                          onHelpTap: () {
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
                      ),
                    ),
                  ),
                  if (_hasAnyBanner(state))
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 130, 16, 0),
                        child: Column(
                          children: [
                            if (WalkMeHomeService.instance.isActive)
                              _WalkMeHomeBanner(
                                remaining: WalkMeHomeService.instance.remaining,
                                onArrived: () => WalkMeHomeService.instance.confirmArrival(),
                              ),
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
                                  IconButton(
                                    icon: const Icon(Icons.link_rounded, size: 20),
                                    tooltip: 'Condividi posizione con un link',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: _openLiveShareSheet,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: people.isEmpty
                                  // Anche vuoto, deve restare un ListView con lo stesso
                                  // scrollController del DraggableScrollableSheet: è da lì
                                  // che il foglio capisce il gesto di trascinamento su/giù.
                                  // Un Center al posto della lista lo disconnetterebbe.
                                  ? ListView(
                                      controller: scrollController,
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                                      children: [
                                        Column(
                                          children: [
                                            Icon(Icons.person_add_alt_1_rounded, size: 32, color: AppTheme.textSecondary),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Nessuno da vedere qui ancora.\nInvita una persona nella cerchia per vederla sulla mappa.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.4),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  : ListView.separated(
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

/// SOS e Aiuto raggruppati in un'unica "pillola" verticale sul bordo destro
/// della mappa: più discreta di due cerchi colorati separati, ma con SOS
/// comunque riconoscibile in cima e in rosso pieno quando attivo.
class _EmergencyActionsGroup extends StatelessWidget {
  const _EmergencyActionsGroup({
    required this.sosActive,
    required this.helpActive,
    required this.walkActive,
    required this.onSosTap,
    required this.onHelpTap,
    required this.onWalkTap,
  });

  final bool sosActive;
  final bool helpActive;
  final bool walkActive;
  final VoidCallback onSosTap;
  final VoidCallback onHelpTap;
  final VoidCallback onWalkTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EmergencyActionButton(
            icon: Icons.emergency_rounded,
            color: AppTheme.accentCoral,
            active: sosActive,
            activeLabel: 'SOS attivo',
            semanticLabel: 'Attiva SOS',
            onTap: onSosTap,
            topRadius: 18,
          ),
          Container(height: 1, width: 40, color: AppTheme.divider),
          _EmergencyActionButton(
            icon: Icons.pan_tool_alt_rounded,
            color: AppTheme.accentAmber,
            active: helpActive,
            activeLabel: 'Aiuto richiesto',
            semanticLabel: 'Chiedi aiuto',
            onTap: onHelpTap,
          ),
          Container(height: 1, width: 40, color: AppTheme.divider),
          _EmergencyActionButton(
            icon: Icons.directions_walk_rounded,
            color: AppTheme.primary,
            active: walkActive,
            activeLabel: 'Accompagnami attivo',
            semanticLabel: 'Accompagnami',
            onTap: onWalkTap,
            bottomRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _EmergencyActionButton extends StatelessWidget {
  const _EmergencyActionButton({
    required this.icon,
    required this.color,
    required this.active,
    required this.activeLabel,
    required this.semanticLabel,
    required this.onTap,
    this.topRadius = 0,
    this.bottomRadius = 0,
  });

  final IconData icon;
  final Color color;
  final bool active;
  final String activeLabel;
  final String semanticLabel;
  final VoidCallback onTap;
  final double topRadius;
  final double bottomRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(top: Radius.circular(topRadius), bottom: Radius.circular(bottomRadius));
    return Material(
      color: active ? color.withOpacity(0.12) : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Semantics(
            label: active ? activeLabel : semanticLabel,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (active)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                  ),
              ],
            ),
          ),
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

class _WalkMeHomeBanner extends StatelessWidget {
  const _WalkMeHomeBanner({required this.remaining, required this.onArrived});
  final Duration remaining;
  final VoidCallback onArrived;

  @override
  Widget build(BuildContext context) {
    final minutes = remaining.inMinutes + 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_walk_rounded, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Accompagnami attivo · conferma entro ~$minutes min',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.textPrimary),
            ),
          ),
          TextButton(onPressed: onArrived, child: const Text('Sono arrivato/a')),
        ],
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
              : SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GpsIconPainter(color: AppTheme.primary))),
        ),
      ),
    );
  }
}

/// Icona GPS disegnata a mano invece di usare un glifo Material: i glifi
/// "my_location"/"gps_fixed" hanno il punto centrale otticamente decentrato
/// nel loro riquadro, visibile proprio dentro un pulsante circolare piccolo.
/// Disegnando noi il cerchio e il puntino sullo stesso centro esatto del
/// canvas, la centratura è garantita.
class _GpsIconPainter extends CustomPainter {
  const _GpsIconPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final tickPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    const ringRadius = 5.5;
    const tickLength = 3.0;
    const tickGap = 1.5;
    canvas.drawCircle(center, ringRadius, ringPaint);
    canvas.drawCircle(center, 2.2, Paint()..color = color);
    for (final angle in [-90.0, 0.0, 90.0, 180.0]) {
      final rad = angle * 3.1415926535 / 180;
      final dir = Offset(math.cos(rad), math.sin(rad));
      final start = center + dir * (ringRadius + tickGap);
      final end = start + dir * tickLength;
      canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GpsIconPainter oldDelegate) => oldDelegate.color != color;
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
