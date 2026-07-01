import 'package:flutter/material.dart';

/// Uno scostamento dalla routine abituale di qualcuno rispetto a un'area
/// sicura: è ancora dentro oltre il solito orario di uscita. Calcolato dal
/// client sullo storico già scaricato, non richiede nessun servizio esterno.
class RoutineAnomaly {
  const RoutineAnomaly({
    required this.zoneId,
    required this.zoneName,
    required this.profileId,
    required this.expectedExit,
    required this.minutesLate,
  });

  final String zoneId;
  final String zoneName;
  final String profileId;

  /// Orario abituale di uscita (mediana degli ultimi eventi), ora locale.
  final TimeOfDay expectedExit;
  final int minutesLate;
}
