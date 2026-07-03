import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/circle_group.dart';
import '../../models/shopping_stop.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

/// Lista della spesa fissa di una cerchia (es. "Latte", "Pane"): a
/// differenza di "Portami qualcosa" (legata a una sosta estemporanea),
/// resta finché non viene rimossa. Se qualcuno entra in un supermercato
/// salvato mentre ci sono voci non prese in carico, la notifica "sei al
/// negozio" le elenca automaticamente (vedi send-push/index.ts).
class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key, required this.circle});
  final CircleGroup circle;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final items = state.shoppingListItemsForCircle(circle.id);
        final l10n = AppLocalizations.of(context)!;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.shoppingListTitle)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddSheet(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.shoppingListAddButton),
          ),
          body: SafeArea(
            child: items.isEmpty
                ? EmptyStateView(
                    icon: Icons.local_grocery_store_outlined,
                    color: AppTheme.accentGreen,
                    title: l10n.shoppingListEmptyTitle,
                    message: l10n.shoppingListEmptyMessage,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [for (final item in items) _ShoppingListTile(item: item)],
                  ),
          ),
        );
      },
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _AddItemSheet(circleId: circle.id),
    );
  }
}

class _ShoppingListTile extends StatelessWidget {
  const _ShoppingListTile({required this.item});
  final ShoppingListItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = AppState.instance;
    final claimedByMe = item.claimedBy == state.me.id;
    final claimedByName = item.isClaimed ? state.personById(item.claimedBy!)?.name ?? l10n.commonSomeone : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(
            item.isClaimed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: item.isClaimed ? AppTheme.accentGreen : AppTheme.divider,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    decoration: item.isClaimed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (claimedByName != null)
                  Text(l10n.shoppingListClaimedBy(claimedByName), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (!item.isClaimed)
            OutlinedButton(
              onPressed: () => state.claimShoppingListItem(item.id, claim: true),
              child: Text(l10n.shoppingListClaimButton),
            )
          else if (claimedByMe)
            TextButton(
              onPressed: () => state.claimShoppingListItem(item.id, claim: false),
              child: Text(l10n.shoppingListUnclaim),
            ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
            visualDensity: VisualDensity.compact,
            onPressed: () => state.deleteShoppingListItem(item.id),
          ),
        ],
      ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet({required this.circleId});
  final String circleId;

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _controller.text.trim();
    if (label.isEmpty) return;
    setState(() => _saving = true);
    try {
      await AppState.instance.addShoppingListItem(circleId: widget.circleId, label: label);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.shoppingListAddButton, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              hintText: l10n.shoppingListAddHint,
              filled: true,
              fillColor: AppTheme.surfaceAlt,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : Text(l10n.shoppingListAddButton),
          ),
        ],
      ),
    );
  }
}
