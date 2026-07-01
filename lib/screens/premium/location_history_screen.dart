import 'package:flutter/material.dart';
import '../../models/location_history_point.dart';
import '../../models/person.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'paywall_screen.dart';

/// Cronologia posizioni di una persona (Kinly+). Se non sono abbonato mostra
/// solo l'invito a passare a Kinly+: la RLS del database non mi ritorna
/// comunque nessun dato in quel caso.
class LocationHistoryScreen extends StatefulWidget {
  const LocationHistoryScreen({super.key, required this.person});
  final Person person;

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  late Future<List<LocationHistoryPoint>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppState.instance.isPremium
        ? AppState.instance.fetchHistoryFor(widget.person.id)
        : Future.value(const []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cronologia · ${widget.person.name}')),
      body: SafeArea(
        child: AppState.instance.isPremium ? _buildHistory() : _buildUpsell(),
      ),
    );
  }

  Widget _buildUpsell() {
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
            child: const Icon(Icons.history_rounded, color: AppTheme.primary, size: 32),
          ),
          const SizedBox(height: 20),
          const Text(
            'Funzione Kinly+',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Passa a Kinly+ per rivedere dove sono stati i membri della cerchia nei giorni passati.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
            child: const Text('Scopri Kinly+'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return FutureBuilder<List<LocationHistoryPoint>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final points = snapshot.data ?? const [];
        if (points.isEmpty) {
          return const Center(
            child: Text('Ancora nessuno storico disponibile.', style: TextStyle(color: AppTheme.textSecondary)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: points.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _HistoryTile(point: points[i]),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.point});
  final LocationHistoryPoint point;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.surfaceAlt),
            alignment: Alignment.center,
            child: const Icon(Icons.place_outlined, size: 17, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point.address ?? '${point.lat.toStringAsFixed(4)}, ${point.lng.toStringAsFixed(4)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary),
                ),
                Text(_formatTimestamp(point.recordedAt), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (sameDay) return 'Oggi, $time';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} · $time';
  }
}
