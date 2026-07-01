import 'package:flutter/material.dart';
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
                  Text(person.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    canSeeLocation ? '${person.address} · ${person.lastUpdateLabel}' : person.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                  ),
                  if (showBadge) ...[
                    const SizedBox(height: 6),
                    SharingModeBadge(mode: person.mode, dense: true),
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
