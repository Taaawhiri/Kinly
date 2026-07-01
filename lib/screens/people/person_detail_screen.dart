import 'package:flutter/material.dart';
import '../../models/person.dart';
import '../../models/sharing_mode.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/person_avatar.dart';
import '../../widgets/sharing_mode_badge.dart';
import '../../widgets/stylized_map_painter.dart';

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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const StylizedMapBackground(),
                      if (canSee)
                        Center(child: PersonAvatar(person: person, size: 64))
                      else
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            child: const Icon(Icons.location_off_outlined, color: AppTheme.textSecondary, size: 30),
                          ),
                        ),
                    ],
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
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                              ),
                            ),
                            SharingModeBadge(mode: person.mode),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (canSee) _InfoRow(icon: Icons.access_time, label: 'Aggiornato ${person.lastUpdateLabel}'),
                        if (canSee) const SizedBox(height: 10),
                        if (canSee) _InfoRow(icon: _batteryIcon(person.batteryPercent), label: 'Batteria ${person.batteryPercent}%'),
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
        child: const Row(
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
        child: const Row(
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
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13.5)),
      ],
    );
  }
}
