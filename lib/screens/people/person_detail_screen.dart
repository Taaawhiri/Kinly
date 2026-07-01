import 'package:flutter/material.dart';
import '../../models/person.dart';
import '../../models/sharing_mode.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kinly_map.dart';
import '../../widgets/sharing_mode_badge.dart';
import '../../widgets/weather_card.dart';
import '../premium/location_history_screen.dart';
import '../premium/speed_alerts_screen.dart';
import 'radar_screen.dart';

class PersonDetailScreen extends StatelessWidget {
  const PersonDetailScreen({super.key, required this.personId});
  final String personId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final person = AppState.instance.personById(personId);
        if (person == null) return const SizedBox.shrink();
        final canSee = person.isMe || person.isSharingWithMe;

        return Scaffold(
          appBar: AppBar(title: Text(person.name)),
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 260,
                  child: canSee && person.lat != null
                      ? KinlyMap(people: [person], interactive: false)
                      : Container(
                          color: const Color(0xFFEEF1FA),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            child: Icon(Icons.location_off_outlined, color: AppTheme.textSecondary, size: 30),
                          ),
                        ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                canSee ? person.address : 'Posizione non condivisa',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                              ),
                            ),
                            SharingModeBadge(mode: person.mode),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (canSee) _InfoRow(icon: Icons.access_time, label: 'Aggiornato ${person.lastUpdateLabel}'),
                        if (canSee) const SizedBox(height: 10),
                        if (canSee) _InfoRow(icon: _batteryIcon(person.batteryPercent), label: 'Batteria ${person.batteryPercent}%'),
                        if (canSee && person.lat != null && person.lng != null) ...[
                          const SizedBox(height: 14),
                          WeatherCard(lat: person.lat!, lng: person.lng!),
                        ],
                        const SizedBox(height: 20),
                        if (!person.isMe && canSee && person.lat != null)
                          _LinkTile(
                            icon: Icons.explore_rounded,
                            label: 'Radar di prossimità',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => RadarScreen(person: person)),
                            ),
                          ),
                        if (!person.isMe && canSee && person.lat != null) const SizedBox(height: 10),
                        _LinkTile(
                          icon: Icons.history_rounded,
                          label: 'Cronologia posizioni',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => LocationHistoryScreen(person: person)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _LinkTile(
                          icon: Icons.speed_rounded,
                          label: 'Avvisi di guida',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => SpeedAlertsScreen(person: person)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildAction(person),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAction(Person person) {
    if (person.isMe) return const SizedBox.shrink();

    if (person.isSharingWithMe) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.accentGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('Sta condividendo la posizione con te.', style: TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
          ],
        ),
      );
    }

    if (person.mode == SharingMode.paused) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(Icons.visibility_off_outlined, color: AppTheme.textSecondary, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text('È in modalità fantasma: non può ricevere richieste in questo momento.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          ],
        ),
      );
    }

    final alreadyRequested = AppState.instance.hasPendingOutgoingTo(person.id);
    return FilledButton.icon(
      onPressed: alreadyRequested ? null : () => AppState.instance.sendLocationRequest(person.id),
      icon: Icon(alreadyRequested ? Icons.hourglass_top_rounded : Icons.location_searching_rounded, size: 18),
      label: Text(alreadyRequested ? 'Richiesta inviata' : 'Richiedi posizione'),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
    );
  }

  IconData _batteryIcon(int percent) {
    if (percent >= 80) return Icons.battery_full;
    if (percent >= 40) return Icons.battery_5_bar;
    if (percent >= 15) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(icon, size: 19, color: AppTheme.textPrimary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppTheme.textPrimary))),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5)),
      ],
    );
  }
}
