/// Un messaggio inviato all'assistenza. `isPriority` è deciso dal server
/// in base all'abbonamento Kinly+ di chi scrive al momento dell'invio.
class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.message,
    required this.isPriority,
    required this.status,
    required this.createdAt,
    this.profileId,
    this.adminReply,
    this.repliedAt,
  });

  factory SupportMessage.fromRow(Map<String, dynamic> row) {
    return SupportMessage(
      id: row['id'] as String,
      profileId: row['profile_id'] as String?,
      message: row['message'] as String,
      isPriority: row['is_priority'] as bool? ?? false,
      status: row['status'] as String? ?? 'open',
      createdAt: DateTime.parse(row['created_at'] as String),
      adminReply: row['admin_reply'] as String?,
      repliedAt: row['replied_at'] != null ? DateTime.parse(row['replied_at'] as String) : null,
    );
  }

  final String id;
  final String? profileId;
  final String message;
  final bool isPriority;
  final String status;
  final DateTime createdAt;

  /// Risposta di un admin, se presente (vedi AdminSupportInboxScreen).
  final String? adminReply;
  final DateTime? repliedAt;
}
