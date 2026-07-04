import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/circle_group.dart';
import '../../models/meetup.dart';
import '../../models/person.dart';
import '../../services/place_search_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/address_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/person_avatar.dart';

/// Ritrovi: alternativa al punto d'incontro che non rivela mai una
/// posizione live. Disponibile in ogni cerchia, ma è l'unico modo per
/// "trovarsi" in una Cerchia Eventi: si propone un ritrovo in uno spot
/// salvato, si risponde con un sì/no, e l'unico segnale legato alla
/// posizione è un avviso puntuale quando qualcuno arriva — mai un tragitto.
class RitroviScreen extends StatelessWidget {
  const RitroviScreen({super.key, required this.circle});
  final CircleGroup circle;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final spots = AppState.instance.spotsForCircle(circle.id);
        return Scaffold(
          appBar: AppBar(title: Text(l10n.ritroviTitle)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openCreateSpotSheet(context),
            icon: const Icon(Icons.add_location_alt_rounded),
            label: Text(l10n.ritroviAddSpotButton),
          ),
          body: SafeArea(
            child: spots.isEmpty
                ? EmptyStateView(
                    icon: Icons.diversity_3_rounded,
                    title: l10n.ritroviEmptyTitle,
                    message: l10n.ritroviEmptyMessage,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [for (final spot in spots) _SpotCard(spot: spot, circle: circle)],
                  ),
          ),
        );
      },
    );
  }

  void _openCreateSpotSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateSpotSheet(circleId: circle.id),
    );
  }
}

String _categoryLabel(AppLocalizations l10n, MeetupSpotCategory category) => switch (category) {
      MeetupSpotCategory.park => l10n.ritroviCategoryPark,
      MeetupSpotCategory.bar => l10n.ritroviCategoryBar,
      MeetupSpotCategory.sport => l10n.ritroviCategorySport,
      MeetupSpotCategory.other => l10n.ritroviCategoryOther,
    };

class _SpotCard extends StatelessWidget {
  const _SpotCard({required this.spot, required this.circle});
  final MeetupSpot spot;
  final CircleGroup circle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = AppState.instance;
    final hereNow = state.whoIsAtSpot(spot.id);
    final upcoming = state.meetupsForSpot(spot.id);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SpotDetailScreen(spot: spot, circle: circle))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentAmber.withOpacity(0.15)),
              alignment: Alignment.center,
              child: Icon(spot.category.icon, color: AppTheme.accentAmber, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spot.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(_categoryLabel(l10n, spot.category), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (hereNow.isNotEmpty)
                        _InfoChip(icon: Icons.circle, iconColor: AppTheme.accentGreen, label: l10n.ritroviHereNowCount(hereNow.length)),
                      if (upcoming.isNotEmpty)
                        _InfoChip(icon: Icons.event_rounded, iconColor: AppTheme.primary, label: l10n.ritroviUpcomingCount(upcoming.length)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.iconColor, required this.label});
  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: iconColor),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class SpotDetailScreen extends StatelessWidget {
  const SpotDetailScreen({super.key, required this.spot, required this.circle});
  final MeetupSpot spot;
  final CircleGroup circle;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final state = AppState.instance;
        final hereNow = state.whoIsAtSpot(spot.id);
        final upcoming = state.meetupsForSpot(spot.id);
        final amHereNow = hereNow.any((c) => c.profileId == state.me.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(spot.name),
            actions: [
              if (spot.createdBy == state.me.id)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: l10n.ritroviDeleteSpotTooltip,
                  onPressed: () {
                    Navigator.of(context).pop();
                    state.deleteMeetupSpot(spot.id);
                  },
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openProposeSheet(context),
            icon: const Icon(Icons.campaign_rounded),
            label: Text(l10n.ritroviProposeButton),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppTheme.accentAmber.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: AppTheme.accentAmber, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l10n.ritroviPrivacyHint, style: TextStyle(color: AppTheme.textPrimary, fontSize: 12.5, height: 1.3)),
                      ),
                    ],
                  ),
                ),
                if (spot.note != null && spot.note!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(spot.note!, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
                ],
                const SizedBox(height: 24),
                Text(l10n.ritroviWhoIsHereTitle, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 10),
                if (hereNow.isEmpty)
                  Text(l10n.ritroviWhoIsHereEmpty, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final checkin in hereNow)
                        Builder(builder: (context) {
                          final person = state.personById(checkin.profileId);
                          if (person == null) return const SizedBox.shrink();
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PersonAvatar(person: person, size: 44, showStatusDot: false),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 56,
                                child: Text(
                                  person.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ),
                            ],
                          );
                        }),
                    ],
                  ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: amHereNow ? null : () => state.checkInAtSpot(spotId: spot.id, circleId: circle.id),
                  icon: Icon(amHereNow ? Icons.check_circle_rounded : Icons.place_outlined, size: 18),
                  label: Text(amHereNow ? l10n.ritroviImHereConfirmed : l10n.ritroviImHereButton),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                ),
                const SizedBox(height: 28),
                Text(l10n.ritroviUpcomingTitle, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 10),
                if (upcoming.isEmpty)
                  Text(l10n.ritroviUpcomingEmpty, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))
                else
                  for (final meetup in upcoming) _MeetupTile(meetup: meetup, circle: circle),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openProposeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ProposeMeetupSheet(spot: spot, circleId: circle.id),
    );
  }
}

class _MeetupTile extends StatelessWidget {
  const _MeetupTile({required this.meetup, required this.circle});
  final Meetup meetup;
  final CircleGroup circle;

  String _scheduledLabel(AppLocalizations l10n) {
    final now = DateTime.now();
    final local = meetup.scheduledAt.toLocal();
    final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final isToday = local.year == now.year && local.month == now.month && local.day == now.day;
    final isTomorrow = local.year == now.year && local.month == now.month && local.day == now.day + 1;
    if (now.difference(local).inMinutes.abs() < 5) return l10n.ritroviScheduledNow;
    if (isToday) return l10n.ritroviScheduledToday(time);
    if (isTomorrow) return l10n.ritroviScheduledTomorrow(time);
    final date = '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
    return l10n.ritroviScheduledOn(date, time);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = AppState.instance;
    final proposer = state.personById(meetup.proposedBy);
    final myResponse = state.myRsvpFor(meetup.id);
    final yesCount = state.rsvpsFor(meetup.id).where((r) => r.response == MeetupRsvpResponse.yes).length;
    final hasCheckedIn = state.hasCheckedInTo(meetup.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _scheduledLabel(l10n),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                ),
              ),
              if (yesCount > 0)
                Text(l10n.ritroviRsvpYesCount(yesCount), style: TextStyle(fontSize: 12, color: AppTheme.accentGreen, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            l10n.ritroviProposedBy(proposer?.name ?? l10n.commonSomeone),
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          if (meetup.note != null && meetup.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(meetup.note!, style: TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.3)),
          ],
          const SizedBox(height: 10),
          if (myResponse == MeetupRsvpResponse.yes && hasCheckedIn)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 16),
                const SizedBox(width: 6),
                Text(l10n.ritroviArrivedLabel, style: TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ],
            )
          else if (myResponse == MeetupRsvpResponse.yes)
            OutlinedButton.icon(
              onPressed: () => state.checkInAtSpot(spotId: meetup.spotId, meetupId: meetup.id, circleId: circle.id),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: Text(l10n.ritroviMarkArrivedButton),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => state.respondToMeetup(meetupId: meetup.id, attending: true),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.accentGreen, minimumSize: const Size.fromHeight(40)),
                    child: Text(l10n.ritroviRsvpYes),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => state.respondToMeetup(meetupId: meetup.id, attending: false),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textSecondary, minimumSize: const Size.fromHeight(40)),
                    child: Text(l10n.ritroviRsvpNo),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CreateSpotSheet extends StatefulWidget {
  const _CreateSpotSheet({required this.circleId});
  final String circleId;

  @override
  State<_CreateSpotSheet> createState() => _CreateSpotSheetState();
}

class _CreateSpotSheetState extends State<_CreateSpotSheet> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final _noteController = TextEditingController();
  MeetupSpotCategory _category = MeetupSpotCategory.park;
  double? _lat;
  double? _lng;
  String? _addressLabel;
  bool _locating = false;
  bool _searching = false;
  bool _saving = false;
  String? _error;
  List<PlaceResult> _results = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.length < 3) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), _searchPlaces);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _searchController.dispose();
    _noteController.dispose();
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
      if (results.isEmpty && mounted) setState(() => _error = AppLocalizations.of(context)!.ritroviSpotNoResultsFor(query));
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.ritroviSpotSearchFailed);
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
        if (_nameController.text.trim().isEmpty && _addressLabel != null) {
          _nameController.text = _addressLabel!;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.ritroviSpotLocationUnavailable);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _lat == null || _lng == null) {
      setState(() => _error = AppLocalizations.of(context)!.ritroviSpotChooseNameAndLocation);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AppState.instance.createMeetupSpot(
        circleId: widget.circleId,
        name: name,
        category: _category,
        lat: _lat!,
        lng: _lng!,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.ritroviSpotCreateError);
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
            Text(l10n.ritroviNewSpotTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Text(l10n.ritroviSpotCategoryLabel, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final category in MeetupSpotCategory.values)
                  ChoiceChip(
                    label: Text(_categoryLabel(l10n, category)),
                    avatar: Icon(category.icon, size: 16, color: _category == category ? Colors.white : AppTheme.textSecondary),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                    selectedColor: AppTheme.accentAmber,
                    labelStyle: TextStyle(color: _category == category ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.ritroviSpotSearchHint,
                prefixIcon: _searching
                    ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                    : const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppTheme.surfaceAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _searchPlaces(),
            ),
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
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
            if (_lat != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _addressLabel ?? '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [Expanded(child: const Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(l10n.ritroviSpotOr)), Expanded(child: const Divider())],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: Text(_lat == null ? l10n.ritroviSpotUseMyLocation : l10n.ritroviSpotPositionSet),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: l10n.ritroviSpotNameHint,
                filled: true,
                fillColor: AppTheme.surfaceAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: l10n.ritroviSpotNoteHint,
                filled: true,
                fillColor: AppTheme.surfaceAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
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
                  : Text(l10n.ritroviSpotCreateButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProposeMeetupSheet extends StatefulWidget {
  const _ProposeMeetupSheet({required this.spot, required this.circleId});
  final MeetupSpot spot;
  final String circleId;

  @override
  State<_ProposeMeetupSheet> createState() => _ProposeMeetupSheetState();
}

enum _WhenChoice { now, today, tomorrow }

class _ProposeMeetupSheetState extends State<_ProposeMeetupSheet> {
  final _noteController = TextEditingController();
  _WhenChoice _when = _WhenChoice.now;
  TimeOfDay _time = TimeOfDay.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  DateTime _resolveScheduledAt() {
    final now = DateTime.now();
    switch (_when) {
      case _WhenChoice.now:
        return now;
      case _WhenChoice.today:
        return DateTime(now.year, now.month, now.day, _time.hour, _time.minute);
      case _WhenChoice.tomorrow:
        final tomorrow = now.add(const Duration(days: 1));
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, _time.hour, _time.minute);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AppState.instance.proposeMeetup(
        spotId: widget.spot.id,
        circleId: widget.circleId,
        scheduledAt: _resolveScheduledAt(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.ritroviProposeError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.ritroviProposeTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(widget.spot.name, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 18),
          Text(l10n.ritroviProposeWhen, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.ritroviWhenNow),
                selected: _when == _WhenChoice.now,
                onSelected: (_) => setState(() => _when = _WhenChoice.now),
              ),
              ChoiceChip(
                label: Text(_when == _WhenChoice.today ? l10n.ritroviWhenTodayAt(_time.format(context)) : l10n.ritroviWhenToday),
                selected: _when == _WhenChoice.today,
                onSelected: (_) {
                  setState(() => _when = _WhenChoice.today);
                  _pickTime();
                },
              ),
              ChoiceChip(
                label: Text(_when == _WhenChoice.tomorrow ? l10n.ritroviWhenTomorrowAt(_time.format(context)) : l10n.ritroviWhenTomorrow),
                selected: _when == _WhenChoice.tomorrow,
                onSelected: (_) {
                  setState(() => _when = _WhenChoice.tomorrow);
                  _pickTime();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: l10n.ritroviProposeNoteHint,
              filled: true,
              fillColor: AppTheme.surfaceAlt,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.accentCoral, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : Text(l10n.ritroviProposeSubmit),
          ),
        ],
      ),
    );
  }
}
