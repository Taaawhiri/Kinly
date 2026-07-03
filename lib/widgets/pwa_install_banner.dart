import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/pwa_install_service.dart';
import '../theme/app_theme.dart';

/// Banner per installare Kinly come PWA: su Chrome/Edge Android mostra un
/// vero pulsante "Installa" (intercetta beforeinstallprompt), su iOS Safari
/// (dove quell'evento non esiste) spiega solo il gesto manuale da fare.
/// Non compare affatto fuori dal web o se l'app gira già installata.
class PwaInstallBanner extends StatefulWidget {
  const PwaInstallBanner({super.key});

  static const _prefKey = 'pwa_install_banner_dismissed';

  @override
  State<PwaInstallBanner> createState() => _PwaInstallBannerState();
}

class _PwaInstallBannerState extends State<PwaInstallBanner> {
  bool _dismissed = true;
  bool _canInstall = false;
  bool _prefsLoaded = false;
  bool _installing = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _canInstall = PwaInstallService.instance.canInstall;
      PwaInstallService.instance.canInstallStream.listen((value) {
        if (mounted) setState(() => _canInstall = value);
      });
      _loadDismissed();
    }
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _dismissed = prefs.getBool(PwaInstallBanner._prefKey) ?? false;
        _prefsLoaded = true;
      });
    }
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PwaInstallBanner._prefKey, true);
  }

  Future<void> _install() async {
    setState(() => _installing = true);
    await PwaInstallService.instance.promptInstall();
    if (mounted) setState(() => _installing = false);
    await _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_prefsLoaded || _dismissed) return const SizedBox.shrink();
    final service = PwaInstallService.instance;
    if (service.isStandalone) return const SizedBox.shrink();
    final showAndroid = _canInstall;
    final showIos = !showAndroid && service.isIOS;
    if (!showAndroid && !showIos) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.18)),
            alignment: Alignment.center,
            child: const Icon(Icons.add_to_home_screen_rounded, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.pwaInstallTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
                const SizedBox(height: 3),
                Text(
                  showAndroid ? l10n.pwaInstallAndroidBody : l10n.pwaInstallIosBody,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, height: 1.3),
                ),
                if (showAndroid) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: FilledButton(
                      onPressed: _installing ? null : _install,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _installing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                          : Text(l10n.pwaInstallButton, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
            onPressed: _dismiss,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
