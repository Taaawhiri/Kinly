import 'package:flutter/material.dart';
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
      appBar: AppBar(title: Text('Statistiche · ${widget.person.name}')),
      body: SafeArea(
        child: AppState.instance.isPremium ? _buildStats() : _buildUpsell(),
      ),
    );
  }

  Widget _buildUpsell() {
    return EmptyStateView(
      icon: Icons.route_rounded,
      title: 'Funzione Kinly+',
      message: 'Passa a Kinly+ per vedere quanta strada avete fatto e rivedere gli itinerari percorsi.',
      action: FilledButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
        child: const Text('Scopri Kinly+'),
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
        final trips = snapshot.data ?? const [];
        if (trips.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Ancora nessun itinerario disponibile: torna qui dopo qualche spostamento.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          );
        }

        final now = DateTime.now();
        final weekMeters = trips.where((t) => now.difference(t.end) <= const Duration(days: 7)).fold(0.0, (sum, t) => sum + t.distanceMeters);
        final monthMeters = trips.where((t) => now.difference(t.end) <= const Duration(days: 30)).fold(0.0, (sum, t) => sum + t.distanceMeters);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Ultimi 7 giorni', value: _formatDistance(weekMeters))),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'Ultimi 30 giorni', value: _formatDistance(monthMeters))),
              ],
            ),
            const SizedBox(height: 24),
            Text('Itinerari recenti', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
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
                  Text('$_dateLabel · $minutes min', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
    final km = trip.distanceMeters >= 1000 ? '${(trip.distanceMeters / 1000).toStringAsFixed(1)} km' : '${trip.distanceMeters.round()} m';
    return Scaffold(
      appBar: AppBar(title: const Text('Itinerario')),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 280, child: TripRouteMap(points: trip.points)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _DetailRow(icon: Icons.trip_origin_rounded, label: 'Partenza', value: trip.startLabel),
                  const SizedBox(height: 12),
                  _DetailRow(icon: Icons.flag_rounded, label: 'Arrivo', value: trip.endLabel),
                  const SizedBox(height: 12),
                  _DetailRow(icon: Icons.straighten_rounded, label: 'Distanza', value: km),
                  const SizedBox(height: 12),
                  _DetailRow(icon: Icons.schedule_rounded, label: 'Durata', value: '${trip.duration.inMinutes} min'),
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
