import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/avatar_catalog.dart';
import '../../utils/generative_avatar.dart';
import '../../utils/image_resizer.dart';
import '../../widgets/person_avatar.dart';

/// Scelta dell'avatar, stile "profili" di un servizio di streaming — con in
/// più la possibilità di caricare una foto vera, per chi la preferisce.
class AvatarPickerScreen extends StatefulWidget {
  const AvatarPickerScreen({super.key});

  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  bool _uploading = false;
  late String _previewSeed;

  @override
  void initState() {
    super.initState();
    final currentKey = AppState.instance.me.avatarKey;
    _previewSeed = GenerativeAvatar.isGenerativeKey(currentKey) ? GenerativeAvatar.seedFromKey(currentKey!) : GenerativeAvatar.newRandomSeed();
  }

  void _shuffleGenerativeAvatar() {
    setState(() => _previewSeed = GenerativeAvatar.newRandomSeed());
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 90);
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final resized = resizeProfilePhoto(bytes);
      await AppState.instance.setProfilePhoto(resized);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.avatarUploadError)));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showPhotoOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.avatarChooseFromGallery),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.avatarTakePhoto),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickAndUpload(ImageSource.camera);
              },
            ),
            if (AppState.instance.me.photoUrl != null)
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: AppTheme.accentCoral),
                title: Text(l10n.avatarRemovePhoto, style: TextStyle(color: AppTheme.accentCoral)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  AppState.instance.removeProfilePhoto();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final selectedKey = state.me.avatarKey;
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.avatarPickerTitle)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      PersonAvatar(person: state.me, size: 88, showStatusDot: false),
                      if (_uploading)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black38),
                            child: const Center(
                              child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)),
                            ),
                          ),
                        ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: GestureDetector(
                          onTap: _uploading ? null : () => _showPhotoOptions(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary,
                              border: Border.all(color: AppTheme.surface, width: 2.5),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _uploading ? null : () => _showPhotoOptions(context),
                    child: Text(state.me.photoUrl != null ? l10n.avatarChangePhoto : l10n.avatarUploadPhoto),
                  ),
                ),
                const SizedBox(height: 14),
                Text(l10n.avatarThemedTitle, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  l10n.avatarThemedHint,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                ),
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
                const SizedBox(height: 24),
                Text(l10n.avatarGenerativeTitle, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(l10n.avatarGenerativeHint, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GenerativeAvatarPreview(seed: _previewSeed, size: 64),
                        if (selectedKey == GenerativeAvatar.keyFromSeed(_previewSeed))
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                              child: const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shuffleGenerativeAvatar,
                        icon: const Icon(Icons.shuffle_rounded, size: 18),
                        label: Text(l10n.avatarGenerativeShuffle),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: selectedKey == GenerativeAvatar.keyFromSeed(_previewSeed) ? null : () => state.setAvatar(GenerativeAvatar.keyFromSeed(_previewSeed)),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: Text(
                    selectedKey == GenerativeAvatar.keyFromSeed(_previewSeed) ? l10n.avatarGenerativeSelected : l10n.avatarGenerativeConfirm,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: selectedKey == null ? null : () => state.setAvatar(null),
                  icon: const Icon(Icons.text_fields_rounded, size: 18),
                  label: Text(l10n.avatarUseInitials),
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
