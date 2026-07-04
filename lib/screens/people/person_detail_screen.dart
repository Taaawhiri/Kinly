import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/person.dart';
import '../../models/ping.dart';
import '../../models/sharing_mode.dart';
import '../../services/kinly_repository.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/battery_icon.dart';
import '../../utils/directions_launcher.dart';
import '../../utils/dnd_label.dart';
import '../../widgets/kinly_map.dart';
import '../../widgets/sharing_mode_badge.dart';
import '../../widgets/weather_card.dart';
import '../premium/location_history_screen.dart';
import '../premium/paywall_screen.dart';
import '../premium/speed_alerts_screen.dart';
import '../premium/statistics_screen.dart';
import 'radar_screen.dart';

/// Sotto questa soglia il bottone "Portami da..." parte diretto, sopra
/// chiede prima conferma: soglia diversa (e più larga) di Person.isStale
/// (10 min, usata solo per il pallino "online" sull'avatar) perché qui
/// l'obiettivo è diverso — evitare un itinerario palesemente vecchio, non
/// segnalare un dato appena scaduto.
const _staleDirectionsThreshold = Duration(minutes: 30);

Future<void> _confirmAndOpenDirections(BuildContext context, Person person) async {
  final l10n = AppLocalizations.of(context)!;
  final isStale = DateTime.now().difference(person.lastUpdate) > _staleDirectionsThreshold;
  if (isStale) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.personDirectionsStaleTitle),
        content: Text(l10n.personDirectionsStaleBody(person.lastUpdateLabel(l10n))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.personDirectionsStaleConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
  }
  await openDirectionsTo(person.lat!, person.lng!);
}

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
        final l10n = AppLocalizations.of(context)!;

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
                                canSee ? person.address : l10n.personLocationNotShared,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                              ),
                            ),
                            SharingModeBadge(mode: person.mode),
                          ],
                        ),
                        if (person.isBirthdayToday) ...[
                          const SizedBox(height: 8),
                          Text(l10n.personBirthdayToday, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
                        ],
                        if (person.hasActiveStatus) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${person.statusEmoji} ${person.statusText ?? ''}'.trim(),
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary),
                          ),
                        ],
                        if (!person.isMe && person.isDndActive) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(color: AppTheme.accentAmber.withOpacity(0.13), borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Icon(Icons.notifications_off_rounded, size: 16, color: AppTheme.accentAmber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    personDndLabel(l10n, person),
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppTheme.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (!person.isMe && canSee && person.lat != null) ...[
                          const SizedBox(height: 14),
                          _PingRow(person: person),
                        ],
                        const SizedBox(height: 14),
                        if (canSee) _InfoRow(icon: Icons.access_time, label: l10n.personUpdatedAt(person.lastUpdateLabel(l10n))),
                        if (canSee) const SizedBox(height: 10),
                        if (canSee) _InfoRow(icon: batteryIconFor(person.batteryPercent), label: l10n.personBatteryPercent(person.batteryPercent)),
                        if (!person.isMe && canSee && person.lat != null && person.lng != null) ...[
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () => _confirmAndOpenDirections(context, person),
                            icon: const Icon(Icons.directions_rounded, size: 18),
                            label: Text(l10n.personGetDirections(person.name)),
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                          ),
                        ],
                        if (canSee && person.lat != null && person.lng != null) ...[
                          const SizedBox(height: 14),
                          WeatherCard(lat: person.lat!, lng: person.lng!),
                        ],
                        const SizedBox(height: 20),
                        if (!person.isMe && canSee && person.lat != null)
                          _LinkTile(
                            icon: Icons.explore_rounded,
                            label: l10n.personRadarLink,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => RadarScreen(person: person)),
                            ),
                          ),
                        if (!person.isMe && canSee && person.lat != null) const SizedBox(height: 10),
                        _LinkTile(
                          icon: Icons.history_rounded,
                          label: l10n.personLocationHistoryLink,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => LocationHistoryScreen(person: person)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _LinkTile(
                          icon: Icons.route_rounded,
                          label: l10n.personStatisticsLink,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => StatisticsScreen(person: person)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _LinkTile(
                          icon: Icons.speed_rounded,
                          label: l10n.personDrivingAlertsLink,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => SpeedAlertsScreen(person: person)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildAction(context, person),
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

  Widget _buildAction(BuildContext context, Person person) {
    if (person.isMe) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    if (person.isSharingWithMe) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.accentGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 18),
            SizedBox(width: 10),
            Expanded(child: Text(l10n.personSharingWithYou, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
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
            Expanded(child: Text(l10n.personGhostMode, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          ],
        ),
      );
    }

    final alreadyRequested = AppState.instance.hasPendingOutgoingTo(person.id);
    return FilledButton.icon(
      onPressed: alreadyRequested ? null : () => AppState.instance.sendLocationRequest(person.id),
      icon: Icon(alreadyRequested ? Icons.hourglass_top_rounded : Icons.location_searching_rounded, size: 18),
      label: Text(alreadyRequested ? l10n.personRequestSent : l10n.personRequestLocation),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
    );
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

/// Tocco rapido senza scrivere: un'emoji con un significato preciso invece
/// di un messaggio (vedi PingKind).
class _PingRow extends StatefulWidget {
  const _PingRow({required this.person});
  final Person person;

  @override
  State<_PingRow> createState() => _PingRowState();
}

class _PingRowState extends State<_PingRow> {
  PingKind? _sent;

  Future<void> _send(PingKind kind) async {
    setState(() => _sent = kind);
    try {
      await AppState.instance.sendPing(toId: widget.person.id, kind: kind);
    } on FreeLimitException catch (e) {
      if (mounted) setState(() => _sent = null);
      if (mounted && e.kind == FreeLimitKind.dailyPingLimit) _showDailyLimitReached();
    } catch (_) {
      if (mounted) setState(() => _sent = null);
    }
  }

  void _showDailyLimitReached() {
    showDialog<void>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(l10n.personPingDailyLimitTitle),
          content: Text(l10n.personPingDailyLimitBody),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.circleMessagesGotIt)),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
              },
              child: Text(l10n.circleMessagesDiscoverPlus),
            ),
          ],
        );
      },
    );
  }

  /// Il ping "occhio al traffico" ha senso solo se sta guidando, "un caffè?"
  /// se sta camminando (o non sappiamo cosa sta facendo): un solo
  /// suggerimento legato a come si sta muovendo invece di sempre gli stessi
  /// due, più il "tutto bene?" sempre disponibile per un check rapido.
  List<PingKind> get _suggestedKinds => switch (widget.person.activityStatus) {
        ActivityStatus.driving => [PingKind.traffic, PingKind.checkIn],
        ActivityStatus.walking => [PingKind.coffee, PingKind.checkIn],
        ActivityStatus.stationary => [PingKind.coffee, PingKind.checkIn],
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final kind in _suggestedKinds)
          OutlinedButton.icon(
            onPressed: _sent != null ? null : () => _send(kind),
            icon: Text(kind.emoji, style: const TextStyle(fontSize: 16)),
            label: Text(_sent == kind ? l10n.personPingSent : kind.label(l10n)),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          ),
      ],
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
