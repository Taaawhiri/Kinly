import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import '../../l10n/app_localizations.dart';
import '../../models/circle_group.dart';
import '../../models/safe_zone.dart';
import '../../services/kinly_repository.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/address_formatter.dart';
import '../../utils/zone_suggestions.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/safe_zone_editor_map.dart';
import '../../widgets/safe_zones_map.dart';
import 'paywall_screen.dart';

enum _ZoneFilter { all, safe, danger }

/// Aree di una cerchia (Kinly+): sicure (luoghi di fiducia) e pericolose
/// (luoghi da evitare). Crearle è un beneficio Kinly+, ma il rilevamento
/// degli ingressi/uscite vale per tutti i membri della cerchia.
class SafeZonesScreen extends StatefulWidget {
  const SafeZonesScreen({super.key, required this.circle});
  final CircleGroup circle;

  @override
  State<SafeZonesScreen> createState() => _SafeZonesScreenState();

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

class _SafeZonesScreenState extends State<SafeZonesScreen> {
  _ZoneFilter _filter = _ZoneFilter.all;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final zones = state.safeZonesForCircle(widget.circle.id);
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.safeZonesTitle(widget.circle.name)),
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
    final l10n = AppLocalizations.of(context)!;
    final safeCount = zones.where((z) => z.zoneType == SafeZoneType.safe).length;
    final dangerCount = zones.length - safeCount;
    final filtered = switch (_filter) {
      _ZoneFilter.all => zones,
      _ZoneFilter.safe => zones.where((z) => z.zoneType == SafeZoneType.safe).toList(),
      _ZoneFilter.danger => zones.where((z) => z.zoneType == SafeZoneType.danger).toList(),
    };
    return Column(
      children: [
        SizedBox(height: 220, child: SafeZonesMap(zones: zones)),
        if (dangerCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _ZoneFilterRow(
              selected: _filter,
              allLabel: l10n.safeZonesFilterAll(zones.length),
              safeLabel: l10n.safeZonesFilterSafe(safeCount),
              dangerLabel: l10n.safeZonesFilterDanger(dangerCount),
              onSelected: (f) => setState(() => _filter = f),
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(l10n.safeZonesFilterEmptyMessage, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5)),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (AppState.instance.isPremium && _filter == _ZoneFilter.all) _ZoneSuggestionsSection(circleId: widget.circle.id),
                    for (final zone in filtered) ...[
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
      builder: (sheetContext) => _SafeZoneSheet(circleId: widget.circle.id),
    );
  }
}

/// Pillole "Tutte / Sicure / Pericolose": mostrate solo quando esiste almeno
/// una zona pericolosa, per non aggiungere un controllo inutile a chi usa
/// solo le aree sicure come prima.
class _ZoneFilterRow extends StatelessWidget {
  const _ZoneFilterRow({
    required this.selected,
    required this.allLabel,
    required this.safeLabel,
    required this.dangerLabel,
    required this.onSelected,
  });
  final _ZoneFilter selected;
  final String allLabel;
  final String safeLabel;
  final String dangerLabel;
  final ValueChanged<_ZoneFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <(_ZoneFilter, String, Color?)>[
      (_ZoneFilter.all, allLabel, null),
      (_ZoneFilter.safe, safeLabel, AppTheme.accentGreen),
      (_ZoneFilter.danger, dangerLabel, AppTheme.accentCoral),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (filter, label, color) in items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: selected == filter,
                onSelected: (_) => onSelected(filter),
                selectedColor: (color ?? AppTheme.primary).withOpacity(0.16),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: selected == filter ? (color ?? AppTheme.primary) : AppTheme.textSecondary,
                ),
                side: BorderSide.none,
                backgroundColor: AppTheme.surfaceAlt,
              ),
            ),
        ],
      ),
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
    final color = zone.zoneType.color;
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
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.14)),
                alignment: Alignment.center,
                child: Icon(zone.kind.icon, color: color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            zone.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
                          ),
                        ),
                        if (zone.zoneType == SafeZoneType.danger) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: color.withOpacity(0.16), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              l10n.safeZoneTypeDanger,
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.02),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(l10n.safeZonesKindRadius(zone.kind.label(l10n), zone.radiusMeters), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
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

/// Toggle "Sicura / Pericolosa": colora la pillola selezionata col colore
/// del tipo (verde/rosso), così anche prima di scegliere l'icona del luogo
/// si capisce subito che tipo di area si sta disegnando.
class _ZoneTypeToggle extends StatelessWidget {
  const _ZoneTypeToggle({required this.selected, required this.onSelected});
  final SafeZoneType selected;
  final ValueChanged<SafeZoneType> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (SafeZoneType.safe, l10n.safeZoneTypeSafe, Icons.shield_outlined),
      (SafeZoneType.danger, l10n.safeZoneTypeDanger, Icons.warning_amber_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (final (type, label, icon) in items)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected == type ? type.color.withOpacity(0.16) : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 15, color: selected == type ? type.color : AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: selected == type ? type.color : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
  final _mapKey = GlobalKey<SafeZoneEditorMapState>();
  late final _nameController = TextEditingController(text: widget.existingZone?.name ?? '');
  final _addressController = TextEditingController();
  late double _radius = widget.existingZone?.radiusMeters.toDouble() ?? 150;
  late SafeZoneType _zoneType = widget.existingZone?.zoneType ?? SafeZoneType.safe;
  late SafeZoneKind _kind = widget.existingZone?.kind ?? SafeZoneKind.home;

  /// Il centro è sempre valorizzato (la mappa ha sempre una camera): parte
  /// dall'area esistente, da un suggerimento, dall'ultima posizione nota
  /// dell'utente o da un punto di default se non sappiamo altro — l'utente
  /// lo affina comunque spostando la mappa.
  late double _lat = widget.existingZone?.lat ?? widget.initialLat ?? AppState.instance.me.lat ?? 41.9028;
  late double _lng = widget.existingZone?.lng ?? widget.initialLng ?? AppState.instance.me.lng ?? 12.4964;
  late String? _addressLabel = widget.existingZone == null ? widget.initialAddress : null;

  bool _locating = false;
  bool _searching = false;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existingZone != null;

  @override
  void initState() {
    super.initState();
    // Per una nuova area senza suggerimento, prova subito a centrare sul
    // GPS reale (più preciso dell'ultima posizione nota) non appena pronto:
    // l'utente vede comunque una mappa fin da subito, poi si affina da sola.
    if (!_isEditing && widget.initialLat == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  List<SafeZoneKind> get _kindChoices => _zoneType == SafeZoneType.danger ? SafeZoneKindData.dangerKinds : SafeZoneKindData.safeKinds;

  void _setZoneType(SafeZoneType type) {
    setState(() {
      _zoneType = type;
      if (!_kindChoices.contains(_kind)) _kind = _kindChoices.first;
    });
  }

  Future<void> _onMapCenterChanged(LatLng target) async {
    setState(() {
      _lat = target.latitude;
      _lng = target.longitude;
    });
    try {
      final placemarks = await placemarkFromCoordinates(target.latitude, target.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final formatted = formatPlacemarkAddress(placemarks.first);
        if (formatted != null && formatted.isNotEmpty) setState(() => _addressLabel = formatted);
      }
    } catch (_) {
      // Va bene anche senza indirizzo leggibile: restano le coordinate.
    }
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
      String? confirmedAddress;
      try {
        final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
        if (placemarks.isNotEmpty) confirmedAddress = formatPlacemarkAddress(placemarks.first);
      } catch (_) {
        // Va bene anche senza indirizzo leggibile: restano comunque le coordinate.
      }
      if (!mounted) return;
      setState(() {
        _lat = loc.latitude;
        _lng = loc.longitude;
        _addressLabel = (confirmedAddress == null || confirmedAddress.isEmpty) ? null : confirmedAddress;
      });
      await _mapKey.currentState?.moveTo(LatLng(loc.latitude, loc.longitude));
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
        if (placemarks.isNotEmpty) address = formatPlacemarkAddress(placemarks.first);
      } catch (_) {
        // Va bene anche senza indirizzo leggibile.
      }
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _addressLabel = (address == null || address.isEmpty) ? null : address;
      });
      await _mapKey.currentState?.moveTo(LatLng(position.latitude, position.longitude));
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.meetingPointLocationUnavailable);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
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
          lat: _lat,
          lng: _lng,
          radiusMeters: _radius.round(),
          kind: _kind,
          zoneType: _zoneType,
        );
      } else {
        await AppState.instance.createSafeZone(
          circleId: widget.circleId,
          name: name,
          lat: _lat,
          lng: _lng,
          radiusMeters: _radius.round(),
          kind: _kind,
          zoneType: _zoneType,
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
    final title = _isEditing
        ? (_zoneType == SafeZoneType.danger ? l10n.safeZonesEditTitleDanger : l10n.safeZonesEditTitle)
        : (_zoneType == SafeZoneType.danger ? l10n.safeZonesNewTitleDanger : l10n.safeZonesNewTitle);
    final createLabel = _zoneType == SafeZoneType.danger ? l10n.safeZonesCreateButtonDanger : l10n.safeZonesCreateButton;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Text(l10n.safeZonesAreaTypeLabel, style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            _ZoneTypeToggle(selected: _zoneType, onSelected: _setZoneType),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 220,
                child: SafeZoneEditorMap(
                  key: _mapKey,
                  initialCenter: LatLng(_lat, _lng),
                  radiusMeters: _radius.round(),
                  color: _zoneType.color,
                  onCenterChanged: _onMapCenterChanged,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.safeZonesMapDrawHint, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.35)),
            const SizedBox(height: 4),
            Text(
              _addressLabel ?? '${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
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
                for (final kind in _kindChoices)
                  ChoiceChip(
                    label: Text(kind.label(l10n)),
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
              activeColor: _zoneType.color,
              onChanged: (v) => setState(() => _radius = v),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: Text(l10n.meetingPointUseMyLocation),
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
            const SizedBox(height: 16),
            // Chi crea un'area sicura spesso lo fa per un minore ("avvisami
            // quando arriva a scuola") e tende a fidarsi della notifica come
            // fosse una certezza: va detto qui che dipende da rete, GPS e
            // permessi del telefono, quindi non è garantita.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentCoral.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 17, color: AppTheme.accentCoral),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.safeZoneNotificationDisclaimer,
                      style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppTheme.accentCoral, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: _zoneType.color),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Text(_isEditing ? l10n.safeZonesSaveChanges : createLabel),
            ),
          ],
        ),
      ),
    );
  }
}
