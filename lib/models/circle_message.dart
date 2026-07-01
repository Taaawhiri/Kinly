/// Un messaggio breve condiviso con tutta una cerchia: pensato per avvisi
/// rapidi e importanti ("sto arrivando", "chiamami"), non per chiacchierare
/// (per quello l'app rimanda a WhatsApp o simili). Il limite di lunghezza è
/// imposto anche lato server (vedi supabase/schema.sql).
class CircleMessage {
  const CircleMessage({
    required this.id,
    required this.circleId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory CircleMessage.fromRow(Map<String, dynamic> row) {
    return CircleMessage(
      id: row['id'] as String,
      circleId: row['circle_id'] as String,
      senderId: row['sender_id'] as String,
      body: row['body'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  final String id;
  final String circleId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  static const maxLength = 140;
}
