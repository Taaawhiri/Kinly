import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/person_avatar.dart';

/// Scelta di chi avvisare quando attivi l'SOS: se non selezioni nessuno,
/// avvisa tutte le persone con cui condividi almeno una cerchia (il
/// comportamento di sempre). Selezionandone almeno una, l'SOS avvisa solo
/// quelle.
class SosContactsScreen extends StatelessWidget {
  const SosContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final people = state.others;
        final selected = state.sosTrustedContactIds;
        return Scaffold(
          appBar: AppBar(title: const Text('Contatti SOS')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selected.isEmpty
                              ? 'Nessuno selezionato: l\'SOS avviserà tutte le persone delle tue cerchie.'
                              : 'L\'SOS avviserà solo le ${selected.length} persone selezionate, non tutta la cerchia.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (people.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Non hai ancora nessuno nelle tue cerchie.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
                    ),
                  )
                else
                  for (final person in people)
                    _ContactTile(
                      name: person.name,
                      avatar: PersonAvatar(person: person, size: 42, showStatusDot: false),
                      selected: selected.contains(person.id),
                      onTap: () => state.toggleSosTrustedContact(person.id),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.name, required this.avatar, required this.selected, required this.onTap});
  final String name;
  final Widget avatar;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppTheme.accentCoral : Colors.transparent, width: 1.6),
          ),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(child: Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary))),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? AppTheme.accentCoral : AppTheme.divider,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
