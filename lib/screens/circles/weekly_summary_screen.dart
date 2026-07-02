import 'package:flutter/material.dart';
import '../../models/circle_group.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// Attività della cerchia negli ultimi 7 giorni, calcolata al volo (vedi
/// weekly_circle_stats nello schema): la stessa che arriva, se attivato,
/// nella notifica push settimanale (Profilo → Privacy e sicurezza).
class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key, required this.circle});
  final CircleGroup circle;

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  late Future<Map<String, dynamic>> _future = AppState.instance.fetchWeeklyCircleStats(widget.circle.id);

  void _retry() {
    setState(() => _future = AppState.instance.fetchWeeklyCircleStats(widget.circle.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Riepilogo · ${widget.circle.name}')),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Non siamo riusciti a caricare il riepilogo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _retry, child: const Text('Riprova')),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final sos = (data['sos_count'] as num?)?.toInt() ?? 0;
            final help = (data['help_count'] as num?)?.toInt() ?? 0;
            final safeZone = (data['safe_zone_entries'] as num?)?.toInt() ?? 0;
            final speed = (data['speed_alerts'] as num?)?.toInt() ?? 0;
            final allZero = sos == 0 && help == 0 && safeZone == 0 && speed == 0;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Ultimi 7 giorni', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  'Attività di "${widget.circle.name}", visibile a tutti i membri.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                if (allZero)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: AppTheme.accentGreen),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Settimana tranquilla: nessun evento da segnalare.',
                            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  _StatTile(icon: Icons.emergency_outlined, color: AppTheme.accentCoral, label: 'SOS attivati', value: sos),
                  const SizedBox(height: 10),
                  _StatTile(icon: Icons.pan_tool_outlined, color: AppTheme.accentAmber, label: 'Richieste di aiuto', value: help),
                  const SizedBox(height: 10),
                  _StatTile(icon: Icons.fence_rounded, color: AppTheme.accentGreen, label: 'Ingressi in aree sicure', value: safeZone),
                  const SizedBox(height: 10),
                  _StatTile(icon: Icons.speed_rounded, color: AppTheme.primary, label: 'Avvisi di velocità', value: speed),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Puoi ricevere questo riepilogo anche via notifica una volta a settimana: attivalo da Profilo → Privacy e sicurezza.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.color, required this.label, required this.value});
  final IconData icon;
  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary))),
          Text('$value', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
