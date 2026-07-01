import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../models/help_request.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/circle_chip.dart';
import '../../widgets/kinly_map.dart';
import '../../widgets/person_list_tile.dart';
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

  @override
  void dispose() {
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
    try {
      final position = await Geolocator.getCurrentPosition();
      await AppState.instance.triggerSos(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non siamo riusciti a rilevare la tua posizione per l\'SOS.')));
      }
    }
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

        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  KinlyMap(
                    people: [state.me, ...people.where((p) => p.isSharingWithMe)],
                    onPersonTap: (personId) => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: personId)),
                    ),
                    onMapReady: (controller) => _mapController = controller,
                  ),
                  // Align forza dei vincoli "loose" sul figlio: senza, lo
                  // Stack (fit: expand) costringerebbe il CustomPaint del
                  // logo a riempire tutto lo schermo (e a "rubare" i gesti
                  // di pan/zoom destinati alla mappa sottostante).
                  const SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 0, 0),
                        child: KinlyLogo(size: 34),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _SosButton(
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
                            const SizedBox(height: 8),
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
                  if (state.activeSosAlerts.any((a) => a.profileId != state.me.id) ||
                      state.activeHelpRequests.any((h) => h.profileId != state.me.id))
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
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
                          ],
                        ),
                      ),
                    ),
                  // La barra delle cerchie segue il bordo superiore del
                  // pannello: quando lo trascini giù, scende anche lei,
                  // invece di restare ferma in mezzo alla mappa.
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 40,
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
                    ),
                  ),
                  // Il pulsante "centra su di me" segue anche lui il bordo
                  // del pannello, per restare sempre visibile e non finire
                  // coperto quando lo trascini verso l'alto.
                  AnimatedBuilder(
                    animation: _sheetController,
                    builder: (context, child) {
                      final extent = _sheetController.isAttached ? _sheetController.size : _sheetInitialSize;
                      final sheetTop = constraints.maxHeight * (1 - extent);
                      return Positioned(
                        right: 16,
                        top: sheetTop - 112,
                        child: child!,
                      );
                    },
                    child: _CenterOnMeButton(loading: _centering, onTap: _centerOnMyLocation),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppTheme.accentCoral,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppTheme.accentCoral.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emergency_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              active ? 'SOS attivo' : 'SOS',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppTheme.accentAmber,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pan_tool_alt_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              active ? 'Aiuto richiesto' : 'Aiuto',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final reason in HelpRequestReason.values)
                  ChoiceChip(
                    label: Text(reason.label),
                    avatar: Icon(reason.icon, size: 16),
                    selected: _reason == reason,
                    onSelected: (_) => setState(() => _reason = reason),
                  ),
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
