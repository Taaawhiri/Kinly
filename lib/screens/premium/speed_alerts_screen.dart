import 'package:flutter/material.dart';
import '../../models/person.dart';
import '../../models/speed_event.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import 'paywall_screen.dart';

/// Avvisi di guida di una persona (Kinly+): quando ha superato la soglia
/// di velocità che si è impostata. Se non sono abbonato mostra solo
/// l'invito a passare a Kinly+: la RLS non mi ritorna comunque dati.
class SpeedAlertsScreen extends StatelessWidget {
  const SpeedAlertsScreen({super.key, required this.person});
  final Person person;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        return Scaffold(
          appBar: AppBar(title: Text('Avvisi di guida · ${person.name}')),
          body: SafeArea(
            child: state.isPremium ? _buildList(state.speedEventsFor(person.id)) : _buildUpsell(context),
          ),
        );
      },
    );
  }

  Widget _buildUpsell(BuildContext context) {
    return EmptyStateView(
      icon: Icons.speed_rounded,
      title: 'Funzione Kinly+',
      message: 'Passa a Kinly+ per sapere quando chi guida supera il limite di velocità che si è impostato.',
      action: FilledButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
        child: const Text('Scopri Kinly+'),
      ),
    );
  }

  Widget _buildList(List<SpeedEvent> events) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nessun avviso registrato: questa persona non ha ancora superato la soglia di velocità impostata (o non l\'ha impostata).',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _SpeedEventTile(event: events[i]),
    );
  }
}

class _SpeedEventTile extends StatelessWidget {
  const _SpeedEventTile({required this.event});
  final SpeedEvent event;

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
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentCoral.withOpacity(0.12)),
            alignment: Alignment.center,
            child: const Icon(Icons.speed_rounded, size: 17, color: AppTheme.accentCoral),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${event.speedKmh.round()} km/h (limite ${event.thresholdKmh.round()} km/h)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary),
                ),
                Text(_formatTimestamp(event.occurredAt), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
