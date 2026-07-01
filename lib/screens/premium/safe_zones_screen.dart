import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/circle_group.dart';
import '../../models/safe_zone.dart';
import '../../services/kinly_repository.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'paywall_screen.dart';

/// Aree sicure di una cerchia (Kinly+): crearle è un beneficio Kinly+, ma il
/// rilevamento degli ingressi/uscite vale per tutti i membri della cerchia.
class SafeZonesScreen extends StatelessWidget {
  const SafeZonesScreen({super.key, required this.circle});
  final CircleGroup circle;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final zones = state.safeZonesForCircle(circle.id);
        return Scaffold(
          appBar: AppBar(
            title: Text('Aree sicure · ${circle.name}'),
            actions: [
              if (state.isPremium)
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _openCreateSheet(context),
                ),
            ],
          ),
          body: SafeArea(
            child: zones.isEmpty ? _buildEmpty(context, state.isPremium) : _buildList(context, zones),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context, bool isPremium) {
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
            child: const Icon(Icons.fence_rounded, color: AppTheme.primary, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            isPremium ? 'Nessuna area sicura' : 'Funzione Kinly+',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            isPremium
                ? 'Crea un\'area (ad esempio casa o scuola) per ricevere una notifica quando qualcuno entra o esce.'
                : 'Passa a Kinly+ per creare aree sicure e ricevere una notifica quando qualcuno arriva o esce da un luogo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => isPremium
                ? _openCreateSheet(context)
                : Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
            child: Text(isPremium ? 'Crea la prima area' : 'Scopri Kinly+'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<SafeZone> zones) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: zones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _SafeZoneCard(zone: zones[i]),
    );
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _CreateSafeZoneSheet(circleId: circle.id),
    );
  }
}

class _SafeZoneCard extends StatelessWidget {
  const _SafeZoneCard({required this.zone});
  final SafeZone zone;

  @override
  Widget build(BuildContext context) {
    final events = AppState.instance.eventsForZone(zone.id);
    final lastEvent = events.isEmpty ? null : events.first;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentGreen.withOpacity(0.14)),
                alignment: Alignment.center,
                child: Icon(zone.kind.icon, color: AppTheme.accentGreen, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zone.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                    Text('${zone.kind.label} · Raggio ${zone.radiusMeters} m', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentCoral, size: 20),
                onPressed: () => AppState.instance.deleteSafeZone(zone.id),
                tooltip: 'Elimina area',
              ),
            ],
          ),
          if (lastEvent != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  lastEvent.type == SafeZoneEventType.enter ? Icons.login_rounded : Icons.logout_rounded,
                  size: 15,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  lastEvent.type == SafeZoneEventType.enter ? 'Ultimo ingresso registrato' : 'Ultima uscita registrata',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CreateSafeZoneSheet extends StatefulWidget {
  const _CreateSafeZoneSheet({required this.circleId});
  final String circleId;

  @override
  State<_CreateSafeZoneSheet> createState() => _CreateSafeZoneSheetState();
}

class _CreateSafeZoneSheetState extends State<_CreateSafeZoneSheet> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  double _radius = 150;
  double? _lat;
  double? _lng;
  String? _addressLabel;
  SafeZoneKind _kind = SafeZoneKind.other;
  bool _locating = false;
  bool _searching = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) {
        if (mounted) setState(() => _error = 'Indirizzo non trovato. Prova a essere più preciso.');
        return;
      }
      final loc = locations.first;
      if (!mounted) return;
      setState(() {
        _lat = loc.latitude;
        _lng = loc.longitude;
        _addressLabel = query;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Non siamo riusciti a cercare questo indirizzo. Riprova.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
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
      await AppState.instance.createSafeZone(
        circleId: widget.circleId,
        name: name,
        lat: _lat!,
        lng: _lng!,
        radiusMeters: _radius.round(),
        kind: _kind,
      );
      if (mounted) Navigator.of(context).pop();
    } on FreeLimitException {
      if (mounted) setState(() => _error = 'Le aree sicure sono una funzione Kinly+.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Non siamo riusciti a creare l\'area. Riprova.');
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
            Text('Nuova area sicura', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nome (es. Casa, Scuola)',
                filled: true,
                fillColor: AppTheme.surfaceAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tipo di luogo', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in SafeZoneKind.values)
                  ChoiceChip(
                    label: Text(kind.label),
                    avatar: Icon(kind.icon, size: 16),
                    selected: _kind == kind,
                    onSelected: (_) => setState(() => _kind = kind),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Raggio: ${_radius.round()} m', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            Slider(
              value: _radius,
              min: 30,
              max: 1000,
              divisions: 97,
              label: '${_radius.round()} m',
              onChanged: (v) => setState(() => _radius = v),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: Text(_lat == null ? 'Usa la mia posizione attuale' : 'Posizione impostata'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      hintText: 'Oppure inserisci un indirizzo',
                      filled: true,
                      fillColor: AppTheme.surfaceAlt,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _searchAddress(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _searching ? null : _searchAddress,
                  icon: _searching
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search_rounded),
                ),
              ],
            ),
            if (_lat != null) ...[
              const SizedBox(height: 8),
              Text(
                _addressLabel ?? '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
              ),
            ],
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
                  : const Text('Crea area'),
            ),
          ],
        ),
      ),
    );
  }
}
