import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/circle_group.dart';
import '../../models/meeting_point.dart';
import '../../models/person.dart';
import '../../services/place_search_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/person_avatar.dart';

/// Punto d'incontro condiviso: chiunque nella cerchia può proporne uno (non
/// è una funzione Kinly+). Ognuno vede la propria distanza in tempo reale;
/// l'arrivo si registra da solo quando ci si avvicina, come per le aree
/// sicure — ma qui vale per tutti, non solo per chi è abbonato.
class MeetingPointScreen extends StatelessWidget {
  const MeetingPointScreen({super.key, required this.circle});
  final CircleGroup circle;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final point = state.meetingPointForCircle(circle.id);
        final members = circle.memberIds.map(state.personById).whereType<Person>().toList();

        return Scaffold(
          appBar: AppBar(
            title: Text('Punto d\'incontro'),
            actions: [
              if (point != null && point.createdBy == state.me.id)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Elimina punto d\'incontro',
                  onPressed: () => state.deleteMeetingPoint(point.id),
                ),
            ],
          ),
          floatingActionButton: point == null
              ? FloatingActionButton.extended(
                  onPressed: () => _openCreateSheet(context),
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text('Crea punto'),
                )
              : null,
          body: SafeArea(
            child: point == null ? _buildEmpty(context) : _buildActive(context, point, members),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.12)),
            alignment: Alignment.center,
            child: const Icon(Icons.share_location_rounded, color: AppTheme.primary, size: 32),
          ),
          const SizedBox(height: 20),
          Text('Nessun punto d\'incontro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Proponi un luogo dove ritrovarvi: tutti vedranno la propria distanza in tempo reale, senza scriversi "dove sei?".',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildActive(BuildContext context, MeetingPoint point, List<Person> members) {
    final state = AppState.instance;
    final entries = <(Person, double?, bool)>[];
    for (final m in members) {
      final distance = (m.lat != null && m.lng != null) ? Geolocator.distanceBetween(m.lat!, m.lng!, point.lat, point.lng) : null;
      entries.add((m, distance, state.hasArrived(point.id, m.id)));
    }
    entries.sort((a, b) {
      if (a.$2 == null && b.$2 == null) return 0;
      if (a.$2 == null) return 1;
      if (b.$2 == null) return -1;
      return a.$2!.compareTo(b.$2!);
    });

    final myArrived = state.hasArrived(point.id, state.me.id);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.1), AppTheme.primary.withOpacity(0.02)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary),
                alignment: Alignment.center,
                child: const Icon(Icons.flag_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(point.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.textPrimary)),
                    if (point.scheduledAt != null) ...[
                      const SizedBox(height: 2),
                      Text(_formatScheduled(point.scheduledAt!), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!myArrived)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: OutlinedButton.icon(
              onPressed: () => state.markArrivedAt(point.id),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Segna il mio arrivo'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ),
        Text('Chi sta arrivando', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
        const SizedBox(height: 10),
        for (final entry in entries) _MemberDistanceTile(person: entry.$1, distanceMeters: entry.$2, arrived: entry.$3),
      ],
    );
  }

  String _formatScheduled(DateTime dt) {
    final local = dt.toLocal();
    return 'Ore ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} · ${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _CreateMeetingPointSheet(circleId: circle.id),
    );
  }
}

class _MemberDistanceTile extends StatelessWidget {
  const _MemberDistanceTile({required this.person, required this.distanceMeters, required this.arrived});
  final Person person;
  final double? distanceMeters;
  final bool arrived;

  @override
  Widget build(BuildContext context) {
    String distanceLabel;
    if (arrived) {
      distanceLabel = 'Arrivato/a';
    } else if (distanceMeters == null) {
      distanceLabel = 'Posizione non disponibile';
    } else if (distanceMeters! >= 1000) {
      distanceLabel = '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
    } else {
      distanceLabel = '${distanceMeters!.round()} m';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          PersonAvatar(person: person, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Text(person.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
          ),
          Row(
            children: [
              if (arrived) const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 16),
              if (arrived) const SizedBox(width: 6),
              Text(
                distanceLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: arrived ? AppTheme.accentGreen : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateMeetingPointSheet extends StatefulWidget {
  const _CreateMeetingPointSheet({required this.circleId});
  final String circleId;

  @override
  State<_CreateMeetingPointSheet> createState() => _CreateMeetingPointSheetState();
}

String _formatScheduledForSheet(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _CreateMeetingPointSheetState extends State<_CreateMeetingPointSheet> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  double? _lat;
  double? _lng;
  String? _addressLabel;
  DateTime? _scheduledAt;
  bool _locating = false;
  bool _searching = false;
  bool _saving = false;
  String? _error;
  List<PlaceResult> _results = [];

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
      _results = [];
    });
    try {
      final results = await PlaceSearchService.instance.search(query);
      if (mounted) setState(() => _results = results);
      if (results.isEmpty && mounted) setState(() => _error = 'Nessun risultato per "$query".');
    } catch (_) {
      if (mounted) setState(() => _error = 'Ricerca non riuscita. Riprova.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _pickResult(PlaceResult result) {
    setState(() {
      _lat = result.lat;
      _lng = result.lng;
      _addressLabel = result.label;
      _results = [];
      _searchController.clear();
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = result.label.split(',').first;
      }
    });
  }

  Future<void> _pickScheduledTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledAt != null ? TimeOfDay.fromDateTime(_scheduledAt!) : TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() => _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final position = await Geolocator.getCurrentPosition();
      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          address = [if ((p.street ?? '').isNotEmpty) p.street, if ((p.locality ?? '').isNotEmpty) p.locality].join(', ');
        }
      } catch (_) {
        // Va bene anche senza indirizzo leggibile.
      }
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _addressLabel = (address == null || address.isEmpty) ? null : address;
        if (_nameController.text.trim().isEmpty && _addressLabel != null) {
          _nameController.text = _addressLabel!;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Non siamo riusciti a rilevare la tua posizione.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _lat == null || _lng == null) {
      setState(() => _error = 'Scegli un nome e una posizione.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AppState.instance.createMeetingPoint(
        circleId: widget.circleId,
        name: name,
        lat: _lat!,
        lng: _lng!,
        scheduledAt: _scheduledAt,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _error = 'Non siamo riusciti a creare il punto d\'incontro. Riprova.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nuovo punto d\'incontro', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nome (es. Ingresso stadio, Bar Roma)',
                filled: true,
                fillColor: AppTheme.surfaceAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cerca un luogo (es. Ristorante da Mario)',
                      filled: true,
                      fillColor: AppTheme.surfaceAlt,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _searchPlaces(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _searching ? null : _searchPlaces,
                  icon: _searching
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search_rounded),
                ),
              ],
            ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(14)),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = _results[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.place_outlined, size: 18),
                      title: Text(r.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                      onTap: () => _pickResult(r),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: const [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('oppure')), Expanded(child: Divider())],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: Text(_lat == null ? 'Usa la mia posizione attuale' : 'Posizione impostata'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            if (_lat != null) ...[
              const SizedBox(height: 8),
              Text(
                _addressLabel ?? '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickScheduledTime,
              icon: const Icon(Icons.schedule_rounded, size: 18),
              label: Text(_scheduledAt == null ? 'Imposta un orario (opzionale)' : _formatScheduledForSheet(_scheduledAt!)),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppTheme.accentCoral, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Text('Crea punto'),
            ),
          ],
        ),
      ),
    );
  }
}
