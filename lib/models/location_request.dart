/// Direzione di una richiesta di posizione.
enum RequestDirection { incoming, outgoing }

/// Stato di una richiesta di posizione.
enum RequestStatus { pending, accepted, declined }

/// Una richiesta puntuale "posso vedere dove sei?" tra due persone della
/// stessa cerchia. Usata quando qualcuno non condivide in automatico.
/// Corrisponde a una riga della tabella `location_requests` su Supabase.
class LocationRequest {
  const LocationRequest({
    required this.id,
    required this.personId,
    required this.direction,
    required this.status,
    required this.timestamp,
  });

  factory LocationRequest.fromRow(Map<String, dynamic> row, {required String myId}) {
    final requesterId = row['requester_id'] as String;
    final targetId = row['target_id'] as String;
    final direction = requesterId == myId ? RequestDirection.outgoing : RequestDirection.incoming;
    return LocationRequest(
      id: row['id'] as String,
      personId: direction == RequestDirection.outgoing ? targetId : requesterId,
      direction: direction,
      status: _statusFromDb(row['status'] as String),
      timestamp: DateTime.parse(row['created_at'] as String),
    );
  }

  static RequestStatus _statusFromDb(String value) {
    switch (value) {
      case 'accepted':
        return RequestStatus.accepted;
      case 'declined':
        return RequestStatus.declined;
      case 'pending':
      default:
        return RequestStatus.pending;
    }
  }

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
