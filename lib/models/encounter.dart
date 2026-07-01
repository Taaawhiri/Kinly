/// Un "incrocio" rilevato tra due persone della stessa cerchia che si sono
/// trovate a pochi metri l'una dall'altra con posizioni entrambe fresche
/// (vedi il trigger `detect_encounters` nello schema).
class Encounter {
  const Encounter({required this.id, required this.profileA, required this.profileB, required this.createdAt});

  factory Encounter.fromRow(Map<String, dynamic> row) {
    return Encounter(
      id: row['id'] as String,
      profileA: row['profile_a'] as String,
      profileB: row['profile_b'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  final String id;
  final String profileA;
  final String profileB;
  final DateTime createdAt;

  String otherPersonId(String myId) => profileA == myId ? profileB : profileA;
}
