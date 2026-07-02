import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/circle_expense.dart';
import '../../models/circle_group.dart';
import '../../models/person.dart';
import '../../services/kinly_repository.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/person_avatar.dart';
import '../premium/paywall_screen.dart';

/// Spese di gruppo condivise in una cerchia (stile Splitwise): solo un
/// registro di chi ha pagato cosa, nessun pagamento reale — Kinly non
/// gestisce mai soldi. "Chiedi il saldo"/"Paga" aprono il link di pagamento
/// personale (Satispay, PayPal.me...) impostato da ciascuno, se c'è.
class CircleExpensesScreen extends StatelessWidget {
  const CircleExpensesScreen({super.key, required this.circle});
  final CircleGroup circle;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final expenses = state.expensesForCircle(circle.id);
        final balances = state.netBalancesForCircle(circle.id);
        final members = circle.memberIds.map(state.personById).whereType<Person>().toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Spese di gruppo')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddExpenseSheet(context, members),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nuova spesa'),
          ),
          body: SafeArea(
            child: expenses.isEmpty
                ? _buildEmpty(context)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [
                      if (balances.values.any((v) => v.abs() > 0.01)) ...[
                        Text('Saldi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                        const SizedBox(height: 10),
                        for (final entry in balances.entries.where((e) => e.value.abs() > 0.01))
                          _BalanceRow(person: state.personById(entry.key), amount: entry.value),
                        const SizedBox(height: 20),
                      ],
                      Text('Spese', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                      const SizedBox(height: 10),
                      for (final expense in expenses) _ExpenseTile(expense: expense, payerName: state.personById(expense.paidBy)?.name ?? 'Qualcuno'),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return const EmptyStateView(
      icon: Icons.receipt_long_outlined,
      color: AppTheme.accentGreen,
      title: 'Nessuna spesa',
      message: 'Tieni traccia di chi ha pagato cosa nella cerchia, senza scriverlo a memoria.',
    );
  }

  void _openAddExpenseSheet(BuildContext context, List<Person> members) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _AddExpenseSheet(circleId: circle.id, members: members),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.person, required this.amount});
  final Person? person;
  final double amount;

  Future<void> _act(BuildContext context) async {
    final me = AppState.instance.me;
    if (amount > 0) {
      // Mi deve soldi: gli mostro il MIO link, così può pagarmi.
      if (me.paymentLink == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imposta il tuo link di pagamento in Privacy e sicurezza per farlo pagare più facilmente.')),
        );
        return;
      }
      await Clipboard.setData(ClipboardData(text: me.paymentLink!));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link di pagamento copiato: mandaglielo.')));
    } else {
      final link = person?.paymentLink;
      if (link == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${person?.name ?? 'Questa persona'} non ha impostato un link di pagamento.')),
        );
        return;
      }
      final uri = Uri.tryParse(link);
      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owesMe = amount > 0;
    final label = owesMe ? '${person?.name ?? 'Qualcuno'} ti deve' : 'Devi a ${person?.name ?? 'qualcuno'}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          if (person != null) PersonAvatar(person: person!, size: 38, showStatusDot: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
                Text(
                  '${amount.abs().toStringAsFixed(2)} €',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: owesMe ? AppTheme.accentGreen : AppTheme.accentCoral),
                ),
              ],
            ),
          ),
          OutlinedButton(onPressed: () => _act(context), child: Text(owesMe ? 'Chiedi il saldo' : 'Paga')),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.payerName});
  final CircleExpense expense;
  final String payerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.12)),
            alignment: Alignment.center,
            child: Icon(Icons.receipt_outlined, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.description, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
                Text('Pagato da $payerName', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text('${expense.amount.toStringAsFixed(2)} €', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet({required this.circleId, required this.members});
  final String circleId;
  final List<Person> members;

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  late Set<String> _selected = widget.members.map((m) => m.id).toSet();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    if (description.isEmpty || amount == null || amount <= 0 || _selected.isEmpty) {
      setState(() => _error = 'Compila descrizione, importo e almeno una persona.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final share = amount / _selected.length;
      await AppState.instance.createExpense(
        circleId: widget.circleId,
        description: description,
        amount: amount,
        sharesByProfileId: {for (final id in _selected) id: share},
      );
      if (mounted) Navigator.of(context).pop();
    } on FreeLimitException catch (e) {
      if (mounted && e.kind == FreeLimitKind.dailyExpenseLimit) {
        _showDailyLimitReached();
      } else if (mounted) {
        setState(() => _error = 'Non siamo riusciti a salvare la spesa. Riprova.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Non siamo riusciti a salvare la spesa. Riprova.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showDailyLimitReached() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Limite giornaliero raggiunto'),
        content: const Text('Hai già registrato 5 spese oggi: è il limite del piano gratuito. Con Kinly+ puoi registrarne quante vuoi.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ho capito')),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
            },
            child: const Text('Scopri Kinly+'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nuova spesa', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text('La paghi tu: la dividi tra le persone che selezioni qui sotto.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Descrizione (es. Cena, benzina)',
                filled: true,
                fillColor: AppTheme.surfaceAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Importo totale (€)',
                filled: true,
                fillColor: AppTheme.surfaceAlt,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            Text('Dividi tra', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final member in widget.members)
                  FilterChip(
                    label: Text(member.name),
                    selected: _selected.contains(member.id),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _selected.add(member.id);
                      } else {
                        _selected.remove(member.id);
                      }
                    }),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppTheme.accentCoral, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Text('Salva spesa'),
            ),
          ],
        ),
      ),
    );
  }
}
