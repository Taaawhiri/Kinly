import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/avatar_catalog.dart';
import '../../widgets/person_avatar.dart';

/// Scelta dell'avatar, stile "profili" di un servizio di streaming: un
/// set di avatar a tema pronti, niente foto da caricare.
class AvatarPickerScreen extends StatelessWidget {
  const AvatarPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final selectedKey = state.me.avatarKey;
        return Scaffold(
          appBar: AppBar(title: const Text('Scegli il tuo avatar')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(child: PersonAvatar(person: state.me, size: 88, showStatusDot: false)),
                const SizedBox(height: 24),
                Text('Avatar a tema', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  children: [
                    for (final option in AvatarCatalog.options)
                      _AvatarTile(
                        option: option,
                        selected: option.key == selectedKey,
                        onTap: () => state.setAvatar(option.key),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: selectedKey == null ? null : () => state.setAvatar(null),
                  icon: const Icon(Icons.text_fields_rounded, size: 18),
                  label: const Text('Usa le iniziali'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({required this.option, required this.selected, required this.onTap});
  final AvatarOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: option.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: selected ? AppTheme.primary : Colors.transparent, width: 3),
          boxShadow: [BoxShadow(color: option.colors.last.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 28)),
            if (selected)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  child: const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
