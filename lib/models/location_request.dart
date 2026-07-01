/// Direzione di una richiesta di posizione.
enum RequestDirection { incoming, outgoing }

/// Stato di una richiesta di posizione.
enum RequestStatus { pending, accepted, declined }

/// Una richiesta puntuale "posso vedere dove sei?" tra due persone della
/// stessa cerchia. Usata quando qualcuno non condivide in automatico.
class LocationRequest {
  const LocationRequest({
    required this.id,
    required this.personId,
    required this.direction,
    required this.status,
    required this.timestamp,
  });

  final String id;

  /// L'altra persona coinvolta nella richiesta (non "me").
  final String personId;
  final RequestDirection direction;
  final RequestStatus status;
  final DateTime timestamp;

  LocationRequest copyWith({RequestStatus? status}) {
    return LocationRequest(
      id: id,
      personId: personId,
      direction: direction,
      status: status ?? this.status,
      timestamp: timestamp,
    );
  }
}
