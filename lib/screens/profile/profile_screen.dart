import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/sharing_mode.dart';
import '../../state/app_state.dart';
import '../../state/locale_controller.dart';
import '../../state/simple_mode_controller.dart';
import '../../state/theme_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/dnd_label.dart';
import '../../utils/haptics.dart';
import '../../widgets/dnd_sheet.dart';
import '../../widgets/haptic_switch.dart';
import '../../widgets/person_avatar.dart';
import '../circles/circles_screen.dart';
import '../premium/paywall_screen.dart';
import 'admin_support_inbox_screen.dart';
import 'avatar_picker_screen.dart';
import 'help_support_screen.dart';
import 'privacy_security_screen.dart';

List<(String, String)> _statusPresets(AppLocalizations l10n) => [
      ('🎉', l10n.profileStatusFriends),
      ('🏠', l10n.profileStatusHome),
      ('🟢', l10n.profileStatusFree),
      ('🔋', l10n.profileStatusBusyDay),
    ];

void _openStatusPicker(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: AppState.instance.me.statusText ?? '');
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.profileStatusPickerTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(l10n.profileStatusPickerHint, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in _statusPresets(l10n))
                ActionChip(
                  avatar: Text(preset.$1, style: const TextStyle(fontSize: 16)),
                  label: Text(preset.$2),
                  onPressed: () {
                    AppState.instance.setStatus(emoji: preset.$1, text: preset.$2);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLength: 30,
                  decoration: InputDecoration(
                    hintText: l10n.profileStatusCustomHint,
                    filled: true,
                    fillColor: AppTheme.surfaceAlt,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  AppState.instance.setStatus(emoji: '💬', text: text);
                  Navigator.of(sheetContext).pop();
                },
                icon: const Icon(Icons.check_rounded),
              ),
            ],
          ),
          if (AppState.instance.me.hasActiveStatus) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                AppState.instance.clearStatus();
                Navigator.of(sheetContext).pop();
              },
              child: Text(l10n.profileRemoveStatus),
            ),
          ],
        ],
      ),
    ),
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppState.instance, ThemeController.instance, LocaleController.instance]),
      builder: (context, _) {
        final state = AppState.instance;
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.navProfile)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AvatarPickerScreen())),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        PersonAvatar(person: state.me, size: 56, showStatusDot: false),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary),
                          child: const Icon(Icons.edit_rounded, size: 11, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.me.name, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                        Text(l10n.profileActiveCircles(state.circles.length), style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openStatusPicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        state.me.hasActiveStatus ? '${state.me.statusEmoji} ${state.me.statusText ?? ''}'.trim() : l10n.profileYourStatus,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _Header(l10n.profileAppearance),
              const SizedBox(height: 10),
              _AppearancePicker(preference: ThemeController.instance.preference),
              const SizedBox(height: 24),
              _Header(l10n.languageSectionTitle),
              const SizedBox(height: 10),
              _LanguagePicker(locale: LocaleController.instance.locale),
              const SizedBox(height: 24),
              _Header(l10n.simpleModeSectionAccessibility),
              const SizedBox(height: 10),
              const _SimpleModeCard(),
              const SizedBox(height: 24),
              _Header(l10n.profileSharingModeHeader),
              const SizedBox(height: 10),
              for (final mode in SharingMode.values)
                _ModeCard(mode: mode, selected: state.myMode == mode, onTap: () => state.setMyMode(mode)),
              const SizedBox(height: 10),
              const _GhostModeCard(),
              const SizedBox(height: 10),
              const _DndModeCard(),
              const SizedBox(height: 24),
              _Header(l10n.profileYourCirclesHeader),
              const SizedBox(height: 10),
              _NavCard(
                icon: Icons.groups_rounded,
                label: l10n.profileCirclesManage(state.circles.length),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CirclesScreen())),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _Header(l10n.profileKinlyPlusHeader)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (state.isPremium ? AppTheme.accentGreen : AppTheme.accentAmber).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      state.isPremium ? l10n.profileActive : l10n.profileNotActive,
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
                child: _PremiumTeaser(isPremium: state.isPremium),
              ),
              const SizedBox(height: 10),
              _NavCard(
                icon: Icons.workspace_premium_outlined,
                label: state.isPremium ? l10n.profileManageSubscription : l10n.circleMessagesDiscoverPlus,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
              ),
              const SizedBox(height: 24),
              _Header(l10n.profileOtherHeader),
              const SizedBox(height: 10),
              _NavCard(
                icon: Icons.shield_outlined,
                label: l10n.profilePrivacySecurity,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacySecurityScreen())),
              ),
              const SizedBox(height: 10),
              _NavCard(
                icon: Icons.help_outline_rounded,
                label: l10n.profileHelpSupport,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
              ),
              if (state.isAdmin) ...[
                const SizedBox(height: 10),
                _NavCard(
                  icon: Icons.admin_panel_settings_outlined,
                  label: l10n.profileAdminSupport,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminSupportInboxScreen())),
                ),
              ],
              const SizedBox(height: 10),
              _NavCard(
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

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary));
  }
}

class _AppearancePicker extends StatelessWidget {
  const _AppearancePicker({required this.preference});
  final AppThemePreference preference;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      (AppThemePreference.system, Icons.brightness_auto_rounded, l10n.languageSystem),
      (AppThemePreference.light, Icons.light_mode_rounded, l10n.profileThemeLight),
      (AppThemePreference.dark, Icons.dark_mode_rounded, l10n.profileThemeDark),
    ];
    return Row(
      children: [
        for (final option in options) ...[
          Expanded(child: _AppearanceOption(option: option, selected: preference == option.$1)),
          if (option != options.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({required this.option, required this.selected});
  final (AppThemePreference, IconData, String) option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ThemeController.instance.setPreference(option.$1),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.primary : Colors.transparent, width: 1.6),
        ),
        child: Column(
          children: [
            Icon(option.$2, size: 20, color: selected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(height: 6),
            Text(
              option.$3,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lingue offerte dal selettore: bandiera + locale. Aggiungerne una nuova
/// significa solo aggiungere una riga qui (più il relativo ARB "languageX")
/// — il foglio a comparsa si adatta da solo, non essendo più un Row a
/// larghezza fissa come la vecchia versione a 3 pill.
const _languageChoices = [
  (Locale('it'), '🇮🇹'),
  (Locale('en'), '🇬🇧'),
];

String _languageFlag(Locale locale) =>
    _languageChoices.firstWhere((c) => c.$1 == locale, orElse: () => _languageChoices.first).$2;

String _languageName(AppLocalizations l10n, Locale locale) =>
    locale.languageCode == 'it' ? l10n.languageItalian : l10n.languageEnglish;

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.locale});
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _openLanguageSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            _FlagBadge(flag: _languageFlag(locale)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_languageName(l10n, locale), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  void _openLanguageSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.languagePickerTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 14),
              for (final choice in _languageChoices)
                _LanguageOption(
                  flag: choice.$2,
                  label: _languageName(l10n, choice.$1),
                  selected: locale == choice.$1,
                  onTap: () {
                    LocaleController.instance.setLocale(choice.$1);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlagBadge extends StatelessWidget {
  const _FlagBadge({required this.flag});
  final String flag;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.surface),
      alignment: Alignment.center,
      child: Text(flag, style: const TextStyle(fontSize: 17)),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.flag, required this.label, required this.selected, required this.onTap});
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.primary : Colors.transparent, width: 1.6),
        ),
        child: Row(
          children: [
            _FlagBadge(flag: flag),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary))),
            if (selected) Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.selected, required this.onTap});
  final SharingMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  Text(mode.label(l10n), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary)),
                  Text(mode.description(l10n), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3)),
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

/// Nascondimento manuale a tempo (Kinly+): a differenza delle 4 modalità
/// sopra, non cambia sharing_mode — è un override temporaneo che il server
/// rispetta comunque (vedi is_within_ghost_schedule in schema.sql), quindi
/// funziona anche se l'app viene chiusa prima che scada da solo.
class _GhostModeCard extends StatelessWidget {
  const _GhostModeCard();

  static const _duration = Duration(hours: 2);

  String _formatTime(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = AppState.instance;

    if (!state.isPremium) {
      return GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Icon(Icons.nightlight_round, color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.ghostModeTitle, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
                    Text(l10n.ghostModePlusTeaser, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
            ],
          ),
        ),
      );
    }

    final active = state.isGhostModeActive;
    final until = state.ghostUntil;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? AppTheme.textSecondary.withOpacity(0.12) : AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? AppTheme.textSecondary.withOpacity(0.35) : Colors.transparent, width: 1.6),
      ),
      child: Row(
        children: [
          Icon(active ? Icons.visibility_off_rounded : Icons.nightlight_round, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? l10n.ghostModeActiveTitle : l10n.ghostModeTitle,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary),
                ),
                Text(
                  active ? l10n.ghostModeActiveUntil(_formatTime(until!)) : l10n.ghostModeDesc,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Haptics.medium();
              active ? state.cancelTemporaryGhostMode() : state.startTemporaryGhostMode(_duration);
            },
            child: Text(active ? l10n.ghostModeEndNow : l10n.ghostModeActivate),
          ),
        ],
      ),
    );
  }
}

/// A differenza di Ghost Mode, gratuita: non tocca la posizione, silenzia
/// solo le notifiche di cortesia (messaggi, richieste, ping). Tocca "Attiva"
/// per scegliere una durata (foglio condiviso con il pulsante rapido sulla
/// mappa); "Disattiva" invece agisce subito, senza aprire nulla.
class _DndModeCard extends StatelessWidget {
  const _DndModeCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = AppState.instance;
    final active = state.me.isDndActive;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active ? AppTheme.accentAmber.withOpacity(0.12) : AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? AppTheme.accentAmber.withOpacity(0.4) : Colors.transparent, width: 1.6),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_off_rounded, color: active ? AppTheme.accentAmber : AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.dndCardTitle, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
                Text(
                  active ? dndStatusLabel(l10n, state.me) : l10n.dndCardDescriptionOff,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              if (active) {
                Haptics.medium();
                state.deactivateDnd();
              } else {
                showDndOptionsSheet(context);
              }
            },
            child: Text(active ? l10n.dndDeactivateButton : l10n.dndActivateButton),
          ),
        ],
      ),
    );
  }
}

/// Interruttore della Modalità Rapida: cambia solo la home (mappa ridotta,
/// testo grande, meno icone), non cosa condividi. Preferenza locale, quindi
/// legge/scrive direttamente su SimpleModeController; l'intera app si
/// ricostruisce alla commutazione (è nel ListenableBuilder in cima).
class _SimpleModeCard extends StatelessWidget {
  const _SimpleModeCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Ascolta SimpleModeController in locale, così l'evidenziazione e
    // l'interruttore si aggiornano all'istante al tocco, senza dipendere da
    // una ricostruzione più grande.
    return ListenableBuilder(
      listenable: SimpleModeController.instance,
      builder: (context, _) {
        final active = SimpleModeController.instance.enabled;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary.withOpacity(0.10) : AppTheme.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? AppTheme.primary.withOpacity(0.4) : Colors.transparent, width: 1.6),
          ),
          child: Row(
            children: [
              Icon(Icons.accessibility_new_rounded, color: active ? AppTheme.primary : AppTheme.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.simpleModeCardTitle, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
                    Text(l10n.simpleModeCardDescription, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              HapticSwitch(
                value: active,
                onChanged: (v) => SimpleModeController.instance.setEnabled(v),
              ),
            ],
          ),
        );
      },
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
  const _PremiumTeaser({required this.isPremium});
  final bool isPremium;

  List<(IconData, String, String)> _features(AppLocalizations l10n) => [
        (Icons.history_rounded, l10n.profileFeatureLocationHistoryTitle, l10n.profileFeatureLocationHistoryDesc),
        (Icons.fence_rounded, l10n.profileFeatureSafeZonesTitle, l10n.profileFeatureSafeZonesDesc),
        (Icons.speed_rounded, l10n.profileFeatureDrivingAlertsTitle, l10n.profileFeatureDrivingAlertsDesc),
        (Icons.gps_fixed_rounded, l10n.profileFeatureBackgroundTrackingTitle, l10n.profileFeatureBackgroundTrackingDesc),
        (Icons.forum_rounded, l10n.profileFeatureUnlimitedTitle, l10n.profileFeatureUnlimitedDesc),
        (Icons.shopping_bag_outlined, l10n.profileFeatureShoppingTitle, l10n.profileFeatureShoppingDesc),
        (Icons.support_agent_rounded, l10n.profileFeaturePrioritySupportTitle, l10n.profileFeaturePrioritySupportDesc),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accent = isPremium ? AppTheme.accentGreen : AppTheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent.withOpacity(0.07), accent.withOpacity(0.02)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          for (final f in _features(l10n))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(f.$1, size: 20, color: accent.withOpacity(0.55)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.$2, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
                        Text(f.$3, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5, height: 1.3)),
                      ],
                    ),
                  ),
                  Icon(
                    isPremium ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                    size: 15,
                    color: isPremium ? AppTheme.accentGreen : AppTheme.textSecondary.withOpacity(0.6),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
