import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';
import 'emergency_sms_settings.dart';

/// Flusso SOS condiviso (conferma → posizione → invio → ripiego SMS se
/// offline), un'unica implementazione riusata sia dalla home a mappa sia
/// dalla Modalità Rapida: l'SOS è sicurezza, non deve esistere in due copie
/// che possono divergere.
class SosFlow {
  const SosFlow._();

  /// Chiede conferma, poi manda l'SOS con la posizione attuale. Se l'invio
  /// fallisce ma la posizione c'è (tipicamente: niente internet), propone il
  /// piano B via SMS quando è configurato un numero di emergenza.
  static Future<void> confirmAndTrigger(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.mapSosConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.mapSosConfirmBody),
            const SizedBox(height: 14),
            // Disclaimer di sicurezza (e legale): l'SOS avvisa i contatti
            // fidati, non i servizi di emergenza, e la consegna non è
            // garantita. Va mostrato proprio nel momento in cui si sta per
            // contare su questa funzione, non nascosto in un menu.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentCoral.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 17, color: AppTheme.accentCoral),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.sosDisclaimer,
                      style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentCoral),
            child: Text(l10n.mapActivateSos),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    // Il momento più critico dell'app: il feedback tattile più forte
    // disponibile, per far percepire subito che l'SOS è partito.
    Haptics.heavy();
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition();
      await AppState.instance.triggerSos(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      if (!context.mounted) return;
      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.mapLocationUnavailableForSos)));
      } else {
        // Posizione trovata ma invio fallito: probabilmente non c'è internet.
        // Proponi il piano B via SMS, se un numero è configurato.
        await _offerSmsFallback(context, position);
      }
    }
  }

  /// SOS via SMS quando internet non c'è: apre l'app SMS con destinatario e
  /// testo (coordinate + link mappa) già compilati — l'invio lo confermi tu.
  static Future<void> _offerSmsFallback(BuildContext context, Position position) async {
    final l10n = AppLocalizations.of(context)!;
    final number = await EmergencySmsSettings.instance.getNumber();
    if (!context.mounted) return;
    if (number == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.mapSosNotSentOffline)));
      return;
    }
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.mapNoInternetSosSmsTitle),
        content: Text(l10n.mapNoInternetSosSmsBody(number)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonNo)),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentCoral),
            child: Text(l10n.mapPrepareSms),
          ),
        ],
      ),
    );
    if (send != true) return;
    final body = Uri.encodeComponent(
      'SOS da Kinly! Ho bisogno di aiuto. La mia posizione: '
      'https://maps.google.com/?q=${position.latitude},${position.longitude}',
    );
    final uri = Uri.parse('sms:$number?body=$body');
    await launchUrl(uri);
  }
}
