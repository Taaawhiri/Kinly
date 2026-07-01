import 'package:flutter/material.dart';
import '../../models/sharing_mode.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/person_avatar.dart';
import '../circles/circles_screen.dart';
import '../premium/paywall_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        return Scaffold(
          appBar: AppBar(title: const Text('Profilo')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  PersonAvatar(person: state.me, size: 56, showStatusDot: false),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(state.me.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                      Text('${state.circles.length} cerchie attive', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const _Header('Modalità di condivisione'),
              const SizedBox(height: 10),
              for (final mode in SharingMode.values)
                _ModeCard(mode: mode, selected: state.myMode == mode, onTap: () => state.setMyMode(mode)),
              const SizedBox(height: 24),
              const _Header('Le tue cerchie'),
              const SizedBox(height: 10),
              _NavCard(
                icon: Icons.groups_rounded,
                label: '${state.circles.length} cerchie · gestisci membri e inviti',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CirclesScreen())),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: _Header('Kinly+')),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (state.isPremium ? AppTheme.accentGreen : AppTheme.accentAmber).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      state.isPremium ? 'Attivo' : 'Non attivo',
                      style: TextStyle(
                        color: state.isPremium ? AppTheme.accentGreen : AppTheme.accentAmber,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
                child: const _PremiumTeaser(),
              ),
              const SizedBox(height: 10),
              _NavCard(
                icon: Icons.workspace_premium_outlined,
                label: state.isPremium ? 'Gestisci abbonamento Kinly+' : 'Scopri Kinly+',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
              ),
              const SizedBox(height: 24),
              const _Header('Altro'),
              const SizedBox(height: 10),
              _NavCard(icon: Icons.shield_outlined, label: 'Privacy e sicurezza', onTap: () {}),
              const SizedBox(height: 10),
              _NavCard(icon: Icons.help_outline_rounded, label: 'Aiuto e assistenza', onTap: () {}),
              const SizedBox(height: 10),
              _NavCard(
                icon: Icons.logout_rounded,
                label: 'Esci',
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

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary));
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.selected, required this.onTap});
  final SharingMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? mode.color : Colors.transparent, width: 1.6),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(shape: BoxShape.circle, color: mode.color.withOpacity(0.14)),
              alignment: Alignment.center,
              child: Icon(mode.icon, color: mode.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mode.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
                  Text(mode.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: selected ? mode.color : AppTheme.divider,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({required this.icon, required this.label, required this.onTap, this.destructive = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppTheme.accentCoral : AppTheme.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13.5))),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

class _PremiumTeaser extends StatelessWidget {
  const _PremiumTeaser();

  static const _features = [
    (Icons.history_rounded, 'Cronologia posizioni', 'Rivedi dove sono stati i membri della cerchia nei giorni passati.'),
    (Icons.fence_rounded, 'Aree sicure', 'Ricevi una notifica quando qualcuno arriva o esce da un luogo.'),
    (Icons.speed_rounded, 'Avvisi di guida', 'Sappi quando chi guida supera un limite di velocità impostato.'),
    (Icons.support_agent_rounded, 'Assistenza prioritaria', 'Supporto dedicato per la tua cerchia, 7 giorni su 7.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.07), AppTheme.primary.withOpacity(0.02)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          for (final f in _features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(f.$1, size: 20, color: AppTheme.primary.withOpacity(0.55)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
                        Text(f.$3, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.3)),
                      ],
                    ),
                  ),
                  Icon(Icons.lock_outline_rounded, size: 15, color: AppTheme.textSecondary.withOpacity(0.6)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
