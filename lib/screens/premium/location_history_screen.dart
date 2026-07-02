import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/location_history_point.dart';
import '../../models/person.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
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

  Future<void> _confirmAndDeleteHistory() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.historyDeleteConfirmTitle),
        content: Text(l10n.historyDeleteConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentCoral),
            child: Text(l10n.historyDeleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await AppState.instance.deleteMyLocationHistory();
      if (mounted) {
        setState(() => _future = Future.value(const []));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.historyDeletedSnackbar)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.historyDeleteError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ha senso solo sulla propria: la RLS non permetterebbe comunque di
    // cancellare lo storico di qualcun altro.
    final canDelete = widget.person.isMe && AppState.instance.isPremium;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle(widget.person.name)),
        actions: [
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: l10n.historyDeleteTooltip,
              onPressed: _confirmAndDeleteHistory,
            ),
        ],
      ),
      body: SafeArea(
        child: AppState.instance.isPremium ? _buildHistory() : _buildUpsell(),
      ),
    );
  }

  Widget _buildUpsell() {
    final l10n = AppLocalizations.of(context)!;
    return EmptyStateView(
      icon: Icons.history_rounded,
      title: l10n.privacyPlusFeatureTitle,
      message: l10n.historyUpsellMessage,
      action: FilledButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
        child: Text(l10n.circleMessagesDiscoverPlus),
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
          return Center(
            child: Text(AppLocalizations.of(context)!.historyEmpty, style: TextStyle(color: AppTheme.textSecondary)),
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
            child: Icon(Icons.place_outlined, size: 17, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  point.address ?? '${point.lat.toStringAsFixed(4)}, ${point.lng.toStringAsFixed(4)}',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary),
                ),
                Text(_formatTimestamp(context, point.recordedAt), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
