import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../models/person.dart';
import '../../models/ping.dart';
import '../../services/kinly_repository.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/directions_launcher.dart';
import '../../utils/dnd_label.dart';
import '../../widgets/person_avatar.dart';
import '../premium/paywall_screen.dart';
import 'person_detail_screen.dart';

/// Versione di PersonDetailScreen per la Modalità Rapida: avatar grande,
/// stato in chiaro, un solo pulsante per chiamare e uno per farsi
/// accompagnare — niente cronologia, statistiche o avvisi di guida, che
/// restano a un tocco di distanza dietro "Vedi dettagli completi".
class SimplePersonDetailScreen extends StatelessWidget {
  const SimplePersonDetailScreen({super.key, required this.personId});
  final String personId;

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final person = AppState.instance.personById(personId);
        if (person == null) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context)!;
        final canSee = person.isMe || person.isSharingWithMe;
        final live = canSee && !person.isStale;
        final statusText = canSee
            ? (person.address.trim().isNotEmpty ? person.address : person.lastUpdateLabel(l10n))
            : l10n.simpleModeLocationHidden;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(title: Text(person.name)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                Center(child: PersonAvatar(person: person, size: 96, showStatusDot: false)),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    person.name,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: live ? AppTheme.accentGreen : AppTheme.textSecondary.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          statusText,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!person.isMe && person.isDndActive) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: AppTheme.accentAmber.withOpacity(0.13), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Icon(Icons.notifications_off_rounded, size: 18, color: AppTheme.accentAmber),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            personDndLabel(l10n, person),
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (!person.isMe) ...[
                  Row(
                    children: [
                      if ((person.phoneNumber ?? '').isNotEmpty)
                        Expanded(
                          child: _BigButton(
                            icon: Icons.call_rounded,
                            label: l10n.simpleModeCall(person.name.trim().split(RegExp(r'\s+')).first),
                            color: AppTheme.accentGreen,
                            onTap: () => _call(person.phoneNumber!),
                          ),
                        ),
                      if ((person.phoneNumber ?? '').isNotEmpty && canSee && person.lat != null) const SizedBox(width: 10),
                      if (canSee && person.lat != null && person.lng != null)
                        Expanded(
                          child: _BigButton(
                            icon: Icons.directions_rounded,
                            label: l10n.personGetDirections(person.name.trim().split(RegExp(r'\s+')).first),
                            color: AppTheme.primary,
                            onTap: () => openDirectionsTo(person.lat!, person.lng!),
                          ),
                        ),
                    ],
                  ),
                  if (canSee && person.lat != null) ...[
                    const SizedBox(height: 20),
                    _SimplePingRow(person: person),
                  ],
                ],
                const SizedBox(height: 28),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: personId))),
                    child: Text(l10n.simplePersonFullDetails),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stessa idea di _PingRow in PersonDetailScreen (un tocco, niente da
/// scrivere) ma con pulsanti più grandi, coerenti col resto della schermata.
class _SimplePingRow extends StatefulWidget {
  const _SimplePingRow({required this.person});
  final Person person;

  @override
  State<_SimplePingRow> createState() => _SimplePingRowState();
}

class _SimplePingRowState extends State<_SimplePingRow> {
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

  List<PingKind> get _suggestedKinds => switch (widget.person.activityStatus) {
        ActivityStatus.driving => [PingKind.traffic, PingKind.checkIn],
        ActivityStatus.walking => [PingKind.coffee, PingKind.checkIn],
        ActivityStatus.stationary => [PingKind.coffee, PingKind.checkIn],
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final kind in _suggestedKinds)
          OutlinedButton.icon(
            onPressed: _sent != null ? null : () => _send(kind),
            icon: Text(kind.emoji, style: const TextStyle(fontSize: 18)),
            label: Text(_sent == kind ? l10n.personPingSent : kind.label(l10n), style: const TextStyle(fontSize: 14)),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          ),
      ],
    );
  }
}
