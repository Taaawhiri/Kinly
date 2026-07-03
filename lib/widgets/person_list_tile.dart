import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import 'person_avatar.dart';
import 'sharing_mode_badge.dart';

/// Riga standard per mostrare una persona: avatar, nome, indirizzo/ultimo
/// aggiornamento, badge di stato e uno slot per un'azione (es. "Richiedi").
class PersonListTile extends StatelessWidget {
  const PersonListTile({
    super.key,
    required this.person,
    this.onTap,
    this.trailing,
    this.showBadge = true,
  });

  final Person person;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final canSeeLocation = person.isMe || person.isSharingWithMe;
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            PersonAvatar(person: person, size: 46),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    canSeeLocation ? '${person.address} · ${person.lastUpdateLabel(l10n)}' : person.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                  ),
                  if (showBadge || (canSeeLocation && person.isBatteryLow)) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (showBadge) SharingModeBadge(mode: person.mode, dense: true),
                        if (canSeeLocation && person.isBatteryLow) _LowBatteryTag(label: l10n.helpReqReasonLowBattery),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _LowBatteryTag extends StatelessWidget {
  const _LowBatteryTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppTheme.accentCoral.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.battery_alert_rounded, size: 12, color: AppTheme.accentCoral),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: AppTheme.accentCoral, fontWeight: FontWeight.w700, fontSize: 10.5)),
        ],
      ),
    );
  }
}
