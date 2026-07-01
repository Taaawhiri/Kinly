/// Una spesa di gruppo condivisa in una cerchia (stile Splitwise: solo un
/// registro di chi ha pagato cosa, nessun pagamento reale). "Chiedi il
/// saldo" apre il payment_link personale dell'altra persona, se l'ha
/// impostato: Kinly non gestisce mai soldi.
class CircleExpense {
  const CircleExpense({
    required this.id,
    required this.circleId,
    required this.paidBy,
    required this.description,
    required this.amount,
    required this.createdAt,
  });

  factory CircleExpense.fromRow(Map<String, dynamic> row) {
    return CircleExpense(
      id: row['id'] as String,
      circleId: row['circle_id'] as String,
      paidBy: row['paid_by'] as String,
      description: row['description'] as String,
      amount: (row['amount'] as num).toDouble(),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  final String id;
  final String circleId;
  final String paidBy;
  final String description;
  final double amount;
  final DateTime createdAt;
}

class ExpenseShare {
  const ExpenseShare({required this.id, required this.expenseId, required this.profileId, required this.shareAmount});

  factory ExpenseShare.fromRow(Map<String, dynamic> row) {
    return ExpenseShare(
      id: row['id'] as String,
      expenseId: row['expense_id'] as String,
      profileId: row['profile_id'] as String,
      shareAmount: (row['share_amount'] as num).toDouble(),
    );
  }

  final String id;
  final String expenseId;
  final String profileId;
  final double shareAmount;
}
