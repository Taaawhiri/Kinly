import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/circle_group.dart';
import '../../models/safe_zone.dart';
import '../../services/kinly_repository.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/address_formatter.dart';
import '../../utils/zone_suggestions.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/safe_zones_map.dart';
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
            title: Text(AppLocalizations.of(context)!.safeZonesTitle(circle.name)),
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
    final l10n = AppLocalizations.of(context)!;
    return EmptyStateView(
      icon: Icons.fence_rounded,
      title: isPremium ? l10n.safeZonesEmptyTitleFree : l10n.privacyPlusFeatureTitle,
      message: isPremium ? l10n.safeZonesEmptyMessagePremium : l10n.safeZonesEmptyMessageFree,
      action: FilledButton(
        onPressed: () => isPremium
            ? _openCreateSheet(context)
            : Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
        child: Text(isPremium ? l10n.safeZonesCreateFirst : l10n.circleMessagesDiscoverPlus),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<SafeZone> zones) {
    return Column(
      children: [
        SizedBox(height: 220, child: SafeZonesMap(zones: zones)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (AppState.instance.isPremium) _ZoneSuggestionsSection(circleId: circle.id),
              for (final zone in zones) ...[
                _SafeZoneCard(zone: zone),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _SafeZoneSheet(circleId: circle.id),
    );
  }

  static void openEditSheet(BuildContext context, SafeZone zone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _SafeZoneSheet(circleId: zone.circleId, existingZone: zone),
    );
  }
}

/// Suggerimenti automatici: luoghi frequentati spesso (dallo storico
/// posizioni) non ancora coperti da un'area sicura, con la proposta di
/// crearne una lì in un tocco.
class _ZoneSuggestionsSection extends StatefulWidget {
  const _ZoneSuggestionsSection({required this.circleId});
  final String circleId;

  @override
  State<_ZoneSuggestionsSection> createState() => _ZoneSuggestionsSectionState();
}

class _ZoneSuggestionsSectionState extends State<_ZoneSuggestionsSection> {
  late final Future<List<ZoneSuggestion>> _future = _load();

  Future<List<ZoneSuggestion>> _load() async {
    final state = AppState.instance;
    final history = await state.fetchHistoryFor(state.me.id);
    return suggestZones(history, state.safeZones);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ZoneSuggestion>>(
      future: _future,
      builder: (context, snapshot) {
        final suggestions = snapshot.data ?? const [];
        if (suggestions.isEmpty) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.safeZonesSuggestedForYou, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            for (final s in suggestions)
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppTheme.surface,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (sheetContext) => _SafeZoneSheet(
                      circleId: widget.circleId,
                      initialLat: s.lat,
                      initialLng: s.lng,
                      initialAddress: s.address,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.address ?? '${s.lat.toStringAsFixed(4)}, ${s.lng.toStringAsFixed(4)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.textPrimary),
                            ),
                            Text(l10n.safeZonesFrequentVisit(s.dayCount),
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary, size: 18),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _SafeZoneCard extends StatelessWidget {
  const _SafeZoneCard({required this.zone});
  final SafeZone zone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                    Text(l10n.safeZonesKindRadius(zone.kind.label, zone.radiusMeters), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: AppTheme.textSecondary, size: 20),
                onPressed: () => SafeZonesScreen.openEditSheet(context, zone),
                tooltip: l10n.safeZonesEditTooltip,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentCoral, size: 20),
                onPressed: () => AppState.instance.deleteSafeZone(zone.id),
                tooltip: l10n.safeZonesDeleteTooltip,
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
                  lastEvent.type == SafeZoneEventType.enter ? l10n.safeZonesLastEntry : l10n.safeZonesLastExit,
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

class _SafeZoneSheet extends StatefulWidget {
  const _SafeZoneSheet({required this.circleId, this.existingZone, this.initialLat, this.initialLng, this.initialAddress});
  final String circleId;

  /// Se non nullo, il foglio modifica quest'area invece di crearne una nuova.
  final SafeZone? existingZone;

  /// Posizione precompilata (arriva da un suggerimento automatico basato
  /// sui luoghi frequentati): solo per la creazione, non per la modifica.
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  @override
  State<_SafeZoneSheet> createState() => _SafeZoneSheetState();
}

class _SafeZoneSheetState extends State<_SafeZoneSheet> {
  late final _nameController = TextEditingController(text: widget.existingZone?.name ?? '');
  final _addressController = TextEditingController();
  late double _radius = widget.existingZone?.radiusMeters.toDouble() ?? 150;
  late double? _lat = widget.existingZone?.lat ?? widget.initialLat;
  late double? _lng = widget.existingZone?.lng ?? widget.initialLng;
  late String? _addressLabel = widget.initialAddress;
  late SafeZoneKind _kind = widget.existingZone?.kind ?? SafeZoneKind.other;
  bool _locating = false;
  bool _searching = false;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existingZone != null;

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
        if (mounted) setState(() => _error = AppLocalizations.of(context)!.safeZonesAddressNotFound);
        return;
      }
      final loc = locations.first;
      // "locationFromAddress" ritorna solo lat/lng, non un indirizzo
      // leggibile: senza questo passaggio in più mostravamo il testo
      // digitato da te invece di confermare cosa ha trovato davvero il
      // geocoder (che potrebbe interpretare l'indirizzo diversamente).
      String? confirmedAddress;
      try {
        final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
        if (placemarks.isNotEmpty) {
          confirmedAddress = formatPlacemarkAddress(placemarks.first);
        }
      } catch (_) {
        // Va bene anche senza indirizzo leggibile: restano comunque le coordinate.
      }
      if (!mounted) return;
      setState(() {
        _lat = loc.latitude;
        _lng = loc.longitude;
        _addressLabel = (confirmedAddress == null || confirmedAddress.isEmpty) ? null : confirmedAddress;
      });
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.safeZonesAddressSearchError);
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
          address = formatPlacemarkAddress(placemarks.first);
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
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.meetingPointLocationUnavailable);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _lat == null || _lng == null) {
      setState(() => _error = AppLocalizations.of(context)!.meetingPointChooseNameAndLocation);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_isEditing) {
        await AppState.instance.updateSafeZone(
          zoneId: widget.existingZone!.id,
          name: name,
          lat: _lat!,
          lng: _lng!,
          radiusMeters: _radius.round(),
          kind: _kind,
        );
      } else {
        await AppState.instance.createSafeZone(
          circleId: widget.circleId,
          name: name,
          lat: _lat!,
          lng: _lng!,
          radiusMeters: _radius.round(),
          kind: _kind,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on FreeLimitException {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.safeZonesPlusOnly);
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _error = _isEditing ? l10n.safeZonesSaveChangesError : l10n.safeZonesCreateError);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEditing ? l10n.safeZonesEditTitle : l10n.safeZonesNewTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.safeZonesNameHint,
                filled: true,
                fillColor: AppTheme.surfaceAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.safeZonesPlaceType, style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
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
            Text(l10n.safeZonesRadiusMeters(_radius.round()), style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            Slider(
              value: _radius,
              min: 30,
              max: 1000,
              divisions: 97,
              label: l10n.safeZonesRadiusValue(_radius.round()),
              onChanged: (v) => setState(() => _radius = v),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: Text(_lat == null ? l10n.meetingPointUseMyLocation : l10n.meetingPointPositionSet),
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
                      hintText: l10n.safeZonesOrEnterAddress,
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
                  : Text(_isEditing ? l10n.safeZonesSaveChanges : l10n.safeZonesCreateButton),
            ),
          ],
        ),
      ),
    );
  }
}
