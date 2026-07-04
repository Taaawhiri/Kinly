import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../models/circle_group.dart';
import '../../models/person.dart';
import '../../models/sharing_mode.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/person_avatar.dart';
import '../people/person_detail_screen.dart';
import '../premium/safe_zones_screen.dart';
import 'circle_expenses_screen.dart';
import 'circle_messages_screen.dart';
import 'meeting_point_screen.dart';
import 'shopping_list_screen.dart';
import 'weekly_summary_screen.dart';

/// Dettaglio di una cerchia: membri, codice invito e tutte le sue azioni.
/// Prima vivevano tutte come una fila di pillole orizzontali nella lista
/// Cerchie — con 8-9 azioni per cerchia, difficili da scoprire tutte con lo
/// scroll e senza nessuna gerarchia tra loro. Qui ognuna ha il suo spazio,
/// come un elenco di impostazioni.
///
/// Riceve solo l'id, non uno snapshot della cerchia: la rilegge da AppState
/// ad ogni ricostruzione, così un codice appena rigenerato o un nuovo membro
/// entrato si vedono subito senza dover tornare indietro e rientrare.
class CircleDetailScreen extends StatelessWidget {
  const CircleDetailScreen({super.key, required this.circleId});
  final String circleId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final circle = AppState.instance.circleById(circleId);
        if (circle == null) {
          // La cerchia non esiste più (es. l'ho lasciata da un altro
          // dispositivo): torno indietro invece di restare su una
          // schermata ormai senza senso.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
          return const Scaffold(body: SizedBox.shrink());
        }
        return _CircleDetailBody(circle: circle);
      },
    );
  }
}

class _CircleDetailBody extends StatelessWidget {
  const _CircleDetailBody({required this.circle});
  final CircleGroup circle;

  Future<void> _confirmAndRegenerateCode(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.circlesRegenerateConfirmTitle),
        content: Text(l10n.circlesRegenerateConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentCoral),
            child: Text(l10n.circlesRegenerateConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final code = await AppState.instance.regenerateInviteCode(circle);
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.circlesRegenerateSuccessSnackbar(code))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final members = circle.memberIds.map(AppState.instance.personById).whereType<Person>().toList();
    final isCreator = circle.createdBy == AppState.instance.me.id;

    return Scaffold(
      appBar: AppBar(title: Text(circle.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: circle.color.withOpacity(0.15)),
                alignment: Alignment.center,
                child: Icon(circle.icon, color: circle.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(circle.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary)),
                    Text(l10n.mapPeopleCount(members.length), style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final person = members[i];
                return GestureDetector(
                  onTap: person.isMe
                      ? null
                      : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: person.id))),
                  child: PersonAvatar(person: person, size: 44),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: circle.inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.circlesInviteCodeCopied)));
                  },
                  child: Row(
                    children: [
                      Text(
                        circle.inviteCode,
                        style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 17, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.copy_rounded, size: 15, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(l10n.circlesInviteCodeHint, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Condivisione via WhatsApp e simili: include sia il
                          // codice (funziona sempre) sia il link kinly:// che
                          // apre l'app già compilata dove i link
                          // personalizzati sono cliccabili.
                          Share.share(l10n.circlesInviteShareMessage(circle.name, circle.inviteCode));
                        },
                        icon: const Icon(Icons.ios_share_rounded, size: 16),
                        label: Text(l10n.circlesActionInvite, maxLines: 1, overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12)),
                      ),
                    ),
                    if (isCreator) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmAndRegenerateCode(context),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(
                            l10n.circlesActionRegenerateCode,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(l10n.circlesDetailActionsTitle, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
          ),
          Container(
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _DetailActionTile(
                  icon: Icons.fence_rounded,
                  label: l10n.circlesActionSafeZones,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SafeZonesScreen(circle: circle))),
                ),
                _DetailActionDivider(),
                _DetailActionTile(
                  icon: Icons.share_location_rounded,
                  label: l10n.circlesActionMeetingPoint,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MeetingPointScreen(circle: circle))),
                ),
                _DetailActionDivider(),
                _DetailActionTile(
                  icon: Icons.forum_outlined,
                  label: l10n.circlesActionMessages,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CircleMessagesScreen(circle: circle))),
                ),
                _DetailActionDivider(),
                _DetailActionTile(
                  icon: Icons.receipt_long_outlined,
                  label: l10n.circlesActionExpenses,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CircleExpensesScreen(circle: circle))),
                ),
                _DetailActionDivider(),
                _DetailActionTile(
                  icon: Icons.local_grocery_store_outlined,
                  label: l10n.circlesActionShoppingList,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShoppingListScreen(circle: circle))),
                ),
                _DetailActionDivider(),
                _DetailActionTile(
                  icon: Icons.insights_rounded,
                  label: l10n.circlesActionSummary,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WeeklySummaryScreen(circle: circle))),
                ),
                _DetailActionDivider(),
                _DetailActionTile(
                  icon: Icons.tune_rounded,
                  label: l10n.circlesActionYourMode,
                  onTap: () => _openSharingModeSheet(context, circle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Riga di un'azione della cerchia: icona in un pallino colorato, etichetta,
/// freccina — stile elenco impostazioni, non più una pillola tra tante dello
/// stesso peso su una fila orizzontale facile da non scorrere fino in fondo.
class _DetailActionTile extends StatelessWidget {
  const _DetailActionTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.12)),
              alignment: Alignment.center,
              child: Icon(icon, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppTheme.textPrimary))),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DetailActionDivider extends StatelessWidget {
  const _DetailActionDivider();

  @override
  Widget build(BuildContext context) => Divider(height: 1, indent: 66, color: AppTheme.divider);
}

void _openSharingModeSheet(BuildContext context, CircleGroup circle) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => _CircleSharingModeSheet(circle: circle),
  );
}

/// Permette di scegliere una modalità di condivisione valida SOLO in questa
/// cerchia (es. automatica con la famiglia, approssimativa con i colleghi),
/// invece che la modalità generale valida ovunque. Se condividi la stessa
/// cerchia in un'altra modalità più permissiva, conta quella: qui scegli solo
/// il "minimo" che vuoi garantire in questa cerchia specifica.
class _CircleSharingModeSheet extends StatelessWidget {
  const _CircleSharingModeSheet({required this.circle});
  final CircleGroup circle;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final override = state.modeOverrideForCircle(circle.id);
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.circlesYourModeInTitle(circle.name), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text(
                  l10n.circlesModeOverrideHint,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 14),
                _SharingOptionTile(
                  label: l10n.circlesUseGeneralMode,
                  description: l10n.circlesGeneralModeDescription(state.myMode.label(l10n)),
                  icon: Icons.settings_backup_restore_rounded,
                  color: AppTheme.textSecondary,
                  selected: override == null,
                  onTap: () {
                    state.setCircleSharingMode(circle.id, null);
                    Navigator.of(context).pop();
                  },
                ),
                for (final mode in SharingMode.values)
                  _SharingOptionTile(
                    label: mode.label(l10n),
                    description: mode.description(l10n),
                    icon: mode.icon,
                    color: mode.color,
                    selected: override == mode,
                    onTap: () {
                      state.setCircleSharingMode(circle.id, mode);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SharingOptionTile extends StatelessWidget {
  const _SharingOptionTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : Colors.transparent, width: 1.6),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.14)),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
                  Text(description, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.3)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
