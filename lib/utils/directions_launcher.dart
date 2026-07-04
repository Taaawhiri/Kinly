import 'package:url_launcher/url_launcher.dart';

/// Apre Google Maps (app se installata, altrimenti il sito) con l'itinerario
/// già impostato verso [lat]/[lng], pronto per navigare: usato ovunque
/// nell'app si mostri la posizione di qualcun altro (dettaglio persona,
/// richiesta di aiuto, SOS).
///
/// Va dritto a launchUrl senza il solito controllo canLaunchUrl prima: per
/// uno schema https quel controllo dipende da una dichiarazione <queries>
/// nel manifest Android (da Android 11 in poi) che è facile dimenticare o
/// sbagliare, e se manca canLaunchUrl ritorna false senza nessun errore
/// visibile — il pulsante sembra premuto ma non succede nulla. launchUrl da
/// solo prova comunque ad aprire un browser se non c'è un'app dedicata.
Future<void> openDirectionsTo(double lat, double lng) async {
  final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Nessuna app in grado di aprirlo: niente da fare, non blocchiamo l'UI.
  }
}
