import 'package:url_launcher/url_launcher.dart';

/// Apre Google Maps (app se installata, altrimenti il sito) con l'itinerario
/// già impostato verso [lat]/[lng], pronto per navigare: usato ovunque
/// nell'app si mostri la posizione di qualcun altro (dettaglio persona,
/// richiesta di aiuto, SOS).
Future<void> openDirectionsTo(double lat, double lng) async {
  final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
}
