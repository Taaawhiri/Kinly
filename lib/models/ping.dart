import '../l10n/app_localizations.dart';

/// Un tocco rapido su una persona sulla mappa, senza scrivere: un'emoji con
/// un significato preciso invece di un messaggio.
enum PingKind { coffee, traffic, highFive, checkIn, allGood }

extension PingKindData on PingKind {
  String get dbValue => switch (this) {
        PingKind.coffee => 'coffee',
        PingKind.traffic => 'traffic',
        PingKind.highFive => 'high_five',
        PingKind.checkIn => 'check_in',
        PingKind.allGood => 'all_good',
      };

  static PingKind fromDb(String value) => switch (value) {
        'coffee' => PingKind.coffee,
        'traffic' => PingKind.traffic,
        'check_in' => PingKind.checkIn,
        'all_good' => PingKind.allGood,
        _ => PingKind.highFive,
      };

  String get emoji => switch (this) {
        PingKind.coffee => '☕',
        PingKind.traffic => '🚨',
        PingKind.highFive => '🖐️',
        PingKind.checkIn => '🙂',
        PingKind.allGood => '👍',
      };

  String label(AppLocalizations l10n) => switch (this) {
        PingKind.coffee => l10n.pingKindCoffee,
        PingKind.traffic => l10n.pingKindTraffic,
        PingKind.highFive => l10n.pingKindHighFive,
        PingKind.checkIn => l10n.pingKindCheckIn,
        PingKind.allGood => l10n.pingKindAllGood,
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
