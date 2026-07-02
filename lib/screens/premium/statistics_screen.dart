import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/person.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/trip_builder.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/trip_route_map.dart';
import 'paywall_screen.dart';

/// Statistiche di spostamento (Kinly+): distanza percorsa e itinerari
/// ricostruiti dallo storico posizioni, raggruppando i punti in "tragitti"
/// separati da soste lunghe.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key, required this.person});
  final Person person;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<List<Trip>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppState.instance.isPremium
        ? AppState.instance.fetchHistoryFor(widget.person.id).then(buildTrips)
        : Future.value(const []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.statsTitle(widget.person.name))),
      body: SafeArea(
        child: AppState.instance.isPremium ? _buildStats() : _buildUpsell(),
      ),
    );
  }

  Widget _buildUpsell() {
    final l10n = AppLocalizations.of(context)!;
    return EmptyStateView(
      icon: Icons.route_rounded,
      title: l10n.privacyPlusFeatureTitle,
      message: l10n.statsUpsellMessage,
      action: FilledButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
        child: Text(l10n.circleMessagesDiscoverPlus),
      ),
    );
  }

  Widget _buildStats() {
    return FutureBuilder<List<Trip>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final l10n = AppLocalizations.of(context)!;
        final trips = snapshot.data ?? const [];
        if (trips.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.statsNoTripsYet,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          );
        }

        final now = DateTime.now();
        final weekTrips = trips.where((t) => now.difference(t.end) <= const Duration(days: 7)).toList();
        final weekMeters = weekTrips.fold(0.0, (sum, t) => sum + t.distanceMeters);
        final monthMeters = trips.where((t) => now.difference(t.end) <= const Duration(days: 30)).fold(0.0, (sum, t) => sum + t.distanceMeters);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(child: _StatCard(label: l10n.statsLast7Days, value: _formatDistance(weekMeters))),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: l10n.statsLast30Days, value: _formatDistance(monthMeters))),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(l10n.statsWeeklySummary, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
                      const Spacer(),
                      Text(
                        l10n.statsTripCount(weekTrips.length),
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _WeeklyDistanceChart(trips: weekTrips),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.statsRecentTrips, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            for (final trip in trips)
              _TripTile(
                trip: trip,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _TripDetailScreen(trip: trip))),
              ),
          ],
        );
      },
    );
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.round()} m';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

/// Barre per gli ultimi 7 giorni (oggi compreso), stile "riepilogo
/// settimanale": distanza percorsa per giorno, un colpo d'occhio invece dei
/// soli km totali della settimana.
class _WeeklyDistanceChart extends StatelessWidget {
  const _WeeklyDistanceChart({required this.trips});
  final List<Trip> trips;

  List<String> _dayLabels(AppLocalizations l10n) => [
        l10n.statsDayMon,
        l10n.statsDayTue,
        l10n.statsDayWed,
        l10n.statsDayThu,
        l10n.statsDayFri,
        l10n.statsDaySat,
        l10n.statsDaySun,
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayLabels = _dayLabels(l10n);
    final today = DateTime.now();
    final days = List.generate(7, (i) => DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - i)));
    final metersByDay = <DateTime, double>{for (final d in days) d: 0};
    for (final trip in trips) {
      final day = DateTime(trip.end.year, trip.end.month, trip.end.day);
      if (metersByDay.containsKey(day)) metersByDay[day] = metersByDay[day]! + trip.distanceMeters;
    }
    final maxMeters = metersByDay.values.fold(0.0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final day in days) ...[
            Expanded(
              child: _DayBar(
                fraction: maxMeters <= 0 ? 0 : metersByDay[day]! / maxMeters,
                label: dayLabels[day.weekday - 1],
                isToday: day.day == today.day && day.month == today.month && day.year == today.year,
              ),
            ),
            if (day != days.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.fraction, required this.label, required this.isToday});
  final double fraction;
  final String label;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    // Altezza minima anche a zero, cosi' il giorno resta visibile come
    // "barretta" invece di sparire del tutto quando non ci si è mossi.
    final barHeight = 6.0 + fraction.clamp(0.0, 1.0) * 58.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 64,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              height: barHeight,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isToday ? AppTheme.primary : AppTheme.primary.withOpacity(0.28),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            color: isToday ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip, required this.onTap});
  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final km = trip.distanceMeters >= 1000 ? '${(trip.distanceMeters / 1000).toStringAsFixed(1)} km' : '${trip.distanceMeters.round()} m';
    final minutes = trip.duration.inMinutes;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.12)),
              alignment: Alignment.center,
              child: Icon(Icons.route_rounded, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${trip.startLabel} → ${trip.endLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  Text(AppLocalizations.of(context)!.statsDateAndMinutes(_dateLabel, minutes), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Text(km, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }

  String get _dateLabel {
    final d = trip.start;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }
}

class _TripDetailScreen extends StatelessWidget {
  const _TripDetailScreen({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final km = trip.distanceMeters >= 1000 ? '${(trip.distanceMeters / 1000).toStringAsFixed(1)} km' : '${trip.distanceMeters.round()} m';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTripLabel)),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 280 + 48, child: TripRouteMap(points: trip.points)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _DetailRow(icon: Icons.trip_origin_rounded, label: l10n.statsDeparture, value: trip.startLabel),
                  const SizedBox(height: 12),
                  _DetailRow(icon: Icons.flag_rounded, label: l10n.statsArrival, value: trip.endLabel),
                  const SizedBox(height: 12),
                  _DetailRow(icon: Icons.straighten_rounded, label: l10n.statsDistance, value: km),
                  const SizedBox(height: 12),
                  _DetailRow(icon: Icons.schedule_rounded, label: l10n.statsDuration, value: l10n.statsMinutes(trip.duration.inMinutes)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const Spacer(),
        Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary))),
      ],
    );
  }
}
