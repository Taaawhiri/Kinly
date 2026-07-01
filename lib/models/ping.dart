/// Un tocco rapido su una persona sulla mappa, senza scrivere: un'emoji con
/// un significato preciso invece di un messaggio.
enum PingKind { coffee, traffic, highFive }

extension PingKindData on PingKind {
  String get dbValue => switch (this) {
        PingKind.coffee => 'coffee',
        PingKind.traffic => 'traffic',
        PingKind.highFive => 'high_five',
      };

  static PingKind fromDb(String value) => switch (value) {
        'coffee' => PingKind.coffee,
        'traffic' => PingKind.traffic,
        _ => PingKind.highFive,
      };

  String get emoji => switch (this) {
        PingKind.coffee => '☕',
        PingKind.traffic => '🚨',
        PingKind.highFive => '🖐️',
      };

  String get label => switch (this) {
        PingKind.coffee => 'Un caffè?',
        PingKind.traffic => 'Occhio al traffico',
        PingKind.highFive => 'High five',
      };
}

class Ping {
  const Ping({required this.id, required this.fromId, required this.toId, required this.kind, required this.createdAt});

  factory Ping.fromRow(Map<String, dynamic> row) {
    return Ping(
      id: row['id'] as String,
      fromId: row['from_id'] as String,
      toId: row['to_id'] as String,
      kind: PingKindData.fromDb(row['kind'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  final String id;
  final String fromId;
  final String toId;
  final PingKind kind;
  final DateTime createdAt;
}
