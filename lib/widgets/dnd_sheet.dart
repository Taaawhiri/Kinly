import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/dnd_label.dart';
import '../utils/haptics.dart';

/// Foglio di attivazione/disattivazione di Non disturbare: stesso
/// contenuto sia che si apra dalla card in Profilo sia dal pulsante rapido
/// sulla mappa, così le due entrate restano sempre coerenti tra loro.
void showDndOptionsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _DndOptionsSheet(),
  );
}

/// "Fino a stasera": le 21:00 di oggi, o tra 3 ore se sono già passate le
/// 21 (altrimenti la durata risulterebbe negativa o quasi nulla).
Duration _untilTonight() {
  final now = DateTime.now();
  final tonight = DateTime(now.year, now.month, now.day, 21);
  return tonight.isAfter(now) ? tonight.difference(now) : const Duration(hours: 3);
}

class _DndOptionsSheet extends StatelessWidget {
  const _DndOptionsSheet();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context)!;
        final state = AppState.instance;
        final me = state.me;
        final active = me.isDndActive;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentAmber.withOpacity(0.15)),
                      alignment: Alignment.center,
                      child: Icon(Icons.notifications_off_rounded, color: AppTheme.accentAmber, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(l10n.dndSheetTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(l10n.dndSheetSubtitle, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4)),
                const SizedBox(height: 18),
                if (active) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.accentAmber.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppTheme.accentAmber, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(dndStatusLabel(l10n, me), style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () {
                      Haptics.medium();
                      state.deactivateDnd();
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: AppTheme.textSecondary),
                    child: Text(l10n.dndDeactivateNow),
                  ),
                ] else ...[
                  _DndOptionTile(
                    label: l10n.dndOption1Hour,
                    onTap: () {
                      Haptics.medium();
                      state.activateDnd(duration: const Duration(hours: 1));
                      Navigator.of(context).pop();
                    },
                  ),
                  _DndOptionTile(
                    label: l10n.dndOption3Hours,
                    onTap: () {
                      Haptics.medium();
                      state.activateDnd(duration: const Duration(hours: 3));
                      Navigator.of(context).pop();
                    },
                  ),
                  _DndOptionTile(
                    label: l10n.dndOptionTonight,
                    onTap: () {
                      Haptics.medium();
                      state.activateDnd(duration: _untilTonight());
                      Navigator.of(context).pop();
                    },
                  ),
                  _DndOptionTile(
                    label: l10n.dndOptionManual,
                    onTap: () {
                      Haptics.medium();
                      state.activateDnd();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DndOptionTile extends StatelessWidget {
  const _DndOptionTile({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary))),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
