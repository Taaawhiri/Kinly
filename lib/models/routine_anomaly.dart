import 'package:flutter/material.dart';

/// Le due direzioni in cui la routine abituale di qualcuno rispetto a
/// un'area sicura può essere "in ritardo": esce più tardi del solito
/// ([lateExit], es. ancora al lavoro oltre l'orario abituale) o non è
/// ancora arrivato dove ci si aspetterebbe a quest'ora ([lateArrival], es.
/// non ancora a scuola). Prima veniva rilevato solo il primo caso.
enum RoutineAnomalyKind { lateExit, lateArrival }

/// Uno scostamento dalla routine abituale di qualcuno rispetto a un'area
/// sicura. Calcolato dal client sullo storico già scaricato, non richiede
/// nessun servizio esterno.
class RoutineAnomaly {
  const RoutineAnomaly({
    required this.kind,
    required this.zoneId,
    required this.zoneName,
    required this.profileId,
    required this.expectedTime,
    required this.minutesLate,
  });

  final RoutineAnomalyKind kind;
  final String zoneId;
  final String zoneName;
  final String profileId;

  /// Orario abituale (mediana degli ultimi eventi), ora locale: di uscita
  /// per [RoutineAnomalyKind.lateExit], di arrivo per [RoutineAnomalyKind.lateArrival].
  final TimeOfDay expectedTime;
  final int minutesLate;
}
