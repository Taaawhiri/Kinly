import 'package:geocoding/geocoding.dart';

/// Compone un indirizzo leggibile da un Placemark, includendo il numero
/// civico. Su Android il pacchetto `geocoding` spesso restituisce il nome
/// della via in `thoroughfare` e il numero civico SEPARATO in
/// `subThoroughfare`: usare solo `street` (come si faceva prima) lo faceva
/// sparire in molti indirizzi. Qui li ricombiniamo esplicitamente, con
/// `street` solo come ultima risorsa se gli altri campi sono vuoti.
String? formatPlacemarkAddress(Placemark p) {
  final thoroughfare = (p.thoroughfare ?? '').trim();
  final subThoroughfare = (p.subThoroughfare ?? '').trim();
  final locality = (p.locality ?? '').trim();

  String street;
  if (thoroughfare.isNotEmpty) {
    street = subThoroughfare.isNotEmpty ? '$thoroughfare $subThoroughfare' : thoroughfare;
  } else {
    street = (p.street ?? '').trim();
  }

  final parts = [if (street.isNotEmpty) street, if (locality.isNotEmpty) locality];
  return parts.isEmpty ? null : parts.join(', ');
}
