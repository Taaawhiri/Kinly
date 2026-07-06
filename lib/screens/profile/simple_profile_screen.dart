import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../state/simple_mode_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/dnd_label.dart';
import '../../widgets/dnd_sheet.dart';
import '../../widgets/person_avatar.dart';
import '../circles/circles_screen.dart';
import 'help_support_screen.dart';
import 'profile_screen.dart';

/// Versione di ProfileScreen per la Modalità Rapida: solo le azioni che
/// contano quando si è scelta la schermata semplice — cerchie, non
/// disturbare, assistenza, uscire dalla modalità, disconnettersi. Tutto il
/// resto (avatar, stato, lingua, Kinly+, privacy) resta a un tocco da
/// "Impostazioni complete", non sparisce.
class SimpleProfileScreen extends StatelessWidget {
  const SimpleProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppState.instance, SimpleModeController.instance]),
      builder: (context, _) {
        final state = AppState.instance;
        final l10n = AppLocalizations.of(context)!;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(title: Text(l10n.navProfile)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Column(
                  children: [
                    PersonAvatar(person: state.me, size: 76, showStatusDot: false),
                    const SizedBox(height: 12),
                    Text(state.me.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _BigRow(
                icon: Icons.groups_rounded,
                label: l10n.profileYourCirclesHeader,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CirclesScreen())),
              ),
              const SizedBox(height: 12),
              _BigRow(
                icon: state.me.isDndActive ? Icons.notifications_off_rounded : Icons.notifications_none_rounded,
                label: state.me.isDndActive ? dndStatusLabel(l10n, state.me) : l10n.dndCardTitle,
                highlighted: state.me.isDndActive,
                onTap: () => state.me.isDndActive ? state.deactivateDnd() : showDndOptionsSheet(context),
              ),
              const SizedBox(height: 12),
              _BigRow(
                icon: Icons.help_outline_rounded,
                label: l10n.profileHelpSupport,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
              ),
              const SizedBox(height: 12),
              _BigRow(
                icon: Icons.tune_rounded,
                label: l10n.simpleProfileFullSettings,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.simpleModeCardTitle, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                          const SizedBox(height: 3),
                          Text(l10n.simpleProfileModeToggleHint, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.35)),
                        ],
                      ),
                    ),
                    Switch(
                      value: SimpleModeController.instance.enabled,
                      onChanged: (v) => SimpleModeController.instance.setEnabled(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _BigRow(
                icon: Icons.logout_rounded,
                label: l10n.profileLogout,
                destructive: true,
                onTap: () async {
                  await state.logOut();
                  if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BigRow extends StatelessWidget {
  const _BigRow({required this.icon, required this.label, required this.onTap, this.destructive = false, this.highlighted = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppTheme.accentCoral : (highlighted ? AppTheme.accentAmber : AppTheme.textPrimary);
    return Material(
      color: highlighted ? AppTheme.accentAmber.withOpacity(0.12) : AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: color))),
              if (!destructive) Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
