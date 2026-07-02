import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
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
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.speedAlertsTitle(person.name))),
          body: SafeArea(
            child: state.isPremium ? _buildList(context, state.speedEventsFor(person.id)) : _buildUpsell(context),
          ),
        );
      },
    );
  }

  Widget _buildUpsell(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyStateView(
      icon: Icons.speed_rounded,
      title: l10n.privacyPlusFeatureTitle,
      message: l10n.speedAlertsUpsellMessage,
      action: FilledButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
        child: Text(l10n.circleMessagesDiscoverPlus),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<SpeedEvent> events) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            AppLocalizations.of(context)!.speedAlertsEmpty,
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
                  AppLocalizations.of(context)!.speedAlertsKmhLimit(event.speedKmh.round(), event.thresholdKmh.round()),
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary),
                ),
                Text(_formatTimestamp(context, event.occurredAt), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (sameDay) return AppLocalizations.of(context)!.historyToday(time);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} · $time';
  }
}
