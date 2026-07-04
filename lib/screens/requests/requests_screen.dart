import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/help_request.dart';
import '../../models/location_request.dart';
import '../../models/shopping_stop.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/person_avatar.dart';
import '../people/help_request_screen.dart';

enum _RequestCategory { all, help, location, shopping }

/// Tutto ciò che aspetta una risposta dalla cerchia in un solo posto:
/// richieste di posizione, di aiuto e "portami qualcosa" (prima le ultime
/// due vivevano solo come banner sulla mappa, invisibili una volta usciti
/// da lì). Il controllo in alto filtra per categoria, non per stato: dentro
/// "Posizione" restano in arrivo/in attesa/storico come nella versione
/// precedente di questa pagina.
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  _RequestCategory _category = _RequestCategory.all;

  Future<void> _confirmAndClearHistory(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.requestsClearHistoryConfirmTitle),
        content: Text(l10n.requestsClearHistoryConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonCancel)),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.accentCoral),
            child: Text(l10n.requestsClearHistoryButton),
          ),
        ],
      ),
    );
    if (confirmed == true) await AppState.instance.clearRequestHistory();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final l10n = AppLocalizations.of(context)!;

        final incoming = state.pendingIncoming;
        final outgoing = state.pendingOutgoing;
        final history = state.history;
        final help = state.activeHelpRequests.where((h) => h.profileId != state.me.id).toList();
        final shoppingOpportunities = state.othersActiveShoppingStops;
        final myStop = state.myActiveShoppingStop;
        final myStopRequests = myStop != null ? state.requestsForStop(myStop.id) : const <ShoppingRequest>[];

        final actionableCount = incoming.length + help.length + shoppingOpportunities.length + myStopRequests.length;
        final isFullyEmpty = incoming.isEmpty &&
            outgoing.isEmpty &&
            history.isEmpty &&
            help.isEmpty &&
            shoppingOpportunities.isEmpty &&
            myStopRequests.isEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.navRequests),
            actions: [
              if (_category == _RequestCategory.location && history.isNotEmpty)
                IconButton(
                  tooltip: l10n.requestsClearHistoryTooltip,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () => _confirmAndClearHistory(context),
                ),
            ],
          ),
          body: isFullyEmpty
              ? const _EmptyState()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: _CategorySegmented(
                        selected: _category,
                        allCount: actionableCount,
                        onSelected: (c) => setState(() => _category = c),
                      ),
                    ),
                    Expanded(
                      child: _RequestsList(
                        category: _category,
                        incoming: incoming,
                        outgoing: outgoing,
                        history: history,
                        help: help,
                        shoppingOpportunities: shoppingOpportunities,
                        myStopRequests: myStopRequests,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({
    required this.category,
    required this.incoming,
    required this.outgoing,
    required this.history,
    required this.help,
    required this.shoppingOpportunities,
    required this.myStopRequests,
  });

  final _RequestCategory category;
  final List<LocationRequest> incoming;
  final List<LocationRequest> outgoing;
  final List<LocationRequest> history;
  final List<HelpRequest> help;
  final List<ShoppingStop> shoppingOpportunities;
  final List<ShoppingRequest> myStopRequests;

  @override
  Widget build(BuildContext context) {
    final showAll = category == _RequestCategory.all;
    final showHelp = showAll || category == _RequestCategory.help;
    final showLocation = showAll || category == _RequestCategory.location;
    final showLocationDetail = category == _RequestCategory.location;
    final showShopping = showAll || category == _RequestCategory.shopping;

    final hasContent = (showHelp && help.isNotEmpty) ||
        (showLocation && incoming.isNotEmpty) ||
        (showLocationDetail && (outgoing.isNotEmpty || history.isNotEmpty)) ||
        (showShopping && (shoppingOpportunities.isNotEmpty || myStopRequests.isNotEmpty));

    if (!hasContent) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppLocalizations.of(context)!.requestsCategoryEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (showHelp)
          for (final h in help) _HelpCard(request: h, showKicker: showAll),
        if (showLocation)
          for (final r in incoming) _IncomingCard(request: r, showKicker: showAll),
        if (showShopping) ...[
          for (final s in shoppingOpportunities) _ShoppingOpportunityCard(stop: s, showKicker: showAll),
          if (myStopRequests.isNotEmpty) _MyShoppingRequestsCard(requests: myStopRequests, showKicker: showAll),
        ],
        if (showLocationDetail) ...[
          if (outgoing.isNotEmpty) ...[
            _SectionTitle(l10n.requestsWaitingReply),
            for (final r in outgoing) _OutgoingCard(request: r),
          ],
          if (history.isNotEmpty) ...[
            _SectionTitle(l10n.requestsHistory),
            for (final r in history) _HistoryTile(request: r),
          ],
        ],
      ],
    );
  }
}

/// Controllo a pillola per filtrare per categoria (non per stato): stesso
/// linguaggio visivo di prima, applicato a un ambito più ampio.
class _CategorySegmented extends StatelessWidget {
  const _CategorySegmented({required this.selected, required this.allCount, required this.onSelected});
  final _RequestCategory selected;
  final int allCount;
  final ValueChanged<_RequestCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <(_RequestCategory, String)>[
      (_RequestCategory.all, allCount > 0 ? '${l10n.requestsTabAll} · $allCount' : l10n.requestsTabAll),
      (_RequestCategory.help, l10n.requestsTabHelp),
      (_RequestCategory.location, l10n.requestsTabLocation),
      (_RequestCategory.shopping, l10n.requestsTabShopping),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (final (category, label) in items)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected == category ? AppTheme.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: selected == category
                        ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: selected == category ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Riga icona + etichetta che identifica la categoria di una card: mostrata
/// solo nella vista "Tutte" (mescolata), nascosta dentro una categoria già
/// filtrata dove sarebbe ridondante col controllo sopra.
class _CategoryKicker extends StatelessWidget {
  const _CategoryKicker({required this.icon, required this.color, required this.label});
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12)),
            alignment: Alignment.center,
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 9),
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.3, color: color)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.request, required this.showKicker});
  final HelpRequest request;
  final bool showKicker;

  @override
  Widget build(BuildContext context) {
    final person = AppState.instance.personById(request.profileId);
    if (person == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showKicker) _CategoryKicker(icon: Icons.pan_tool_alt_rounded, color: AppTheme.accentCoral, label: l10n.requestsTabHelp),
          Row(
            children: [
              PersonAvatar(person: person, size: 40, showStatusDot: false),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.helpRequestPersonNeeds(person.name, request.reason.label(l10n)),
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.accentCoral),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HelpRequestScreen(request: request, person: person))),
              child: Text(l10n.requestsHelpGoTo),
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingCard extends StatelessWidget {
  const _IncomingCard({required this.request, required this.showKicker});
  final LocationRequest request;
  final bool showKicker;

  @override
  Widget build(BuildContext context) {
    final person = AppState.instance.personById(request.personId);
    if (person == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showKicker) _CategoryKicker(icon: Icons.location_searching_rounded, color: AppTheme.primary, label: l10n.requestsTabLocation),
          Row(
            children: [
              PersonAvatar(person: person, size: 40, showStatusDot: false),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.requestsWantsToSeeYou(person.name),
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => AppState.instance.respondToIncoming(request.id, false),
                  child: Text(l10n.requestsReject),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => AppState.instance.respondToIncoming(request.id, true),
                  child: Text(l10n.requestsApprove),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Qualcuno della cerchia è al negozio: si può chiedergli qualcosa al volo.
/// Stessa logica di _ShoppingStopBanner sulla mappa (map_home_screen.dart),
/// qui in stile card invece che banner.
class _ShoppingOpportunityCard extends StatefulWidget {
  const _ShoppingOpportunityCard({required this.stop, required this.showKicker});
  final ShoppingStop stop;
  final bool showKicker;

  @override
  State<_ShoppingOpportunityCard> createState() => _ShoppingOpportunityCardState();
}

class _ShoppingOpportunityCardState extends State<_ShoppingOpportunityCard> {
  final _controller = TextEditingController();
  bool _expanded = false;
  bool _sent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final note = _controller.text.trim();
    if (note.isEmpty) return;
    AppState.instance.sendShoppingRequest(stopId: widget.stop.id, note: note);
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final person = AppState.instance.personById(widget.stop.profileId);
    final name = person?.name ?? l10n.commonSomeone;
    final place = widget.stop.placeName != null ? ' (${widget.stop.placeName})' : '';
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showKicker) _CategoryKicker(icon: Icons.local_grocery_store_outlined, color: AppTheme.accentGreen, label: l10n.requestsTabShopping),
          Text(l10n.mapShoppingAtStore(name, place), style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (_sent)
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 18),
                const SizedBox(width: 8),
                Text(l10n.requestsShoppingSent, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            )
          else if (!_expanded)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppTheme.accentGreen),
                onPressed: () => setState(() => _expanded = true),
                child: Text(l10n.mapAskSomething),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: l10n.mapShoppingHint,
                      filled: true,
                      fillColor: AppTheme.surfaceAlt,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send_rounded, size: 18), onPressed: _send),
              ],
            ),
        ],
      ),
    );
  }
}

/// Chi mi ha chiesto qualcosa mentre ero io al negozio (vedi
/// _MyShoppingRequestsBanner sulla mappa): solo informativa, nessuna azione
/// (non c'è un modo per "confermare" oltre a portarlo davvero).
class _MyShoppingRequestsCard extends StatelessWidget {
  const _MyShoppingRequestsCard({required this.requests, required this.showKicker});
  final List<ShoppingRequest> requests;
  final bool showKicker;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showKicker) _CategoryKicker(icon: Icons.local_grocery_store_outlined, color: AppTheme.accentGreen, label: l10n.requestsTabShopping),
          Text(l10n.mapTheyAskedFor, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          for (final r in requests)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.mapShoppingRequestLine(AppState.instance.personById(r.fromId)?.name ?? l10n.commonSomeone, r.note),
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _OutgoingCard extends StatelessWidget {
  const _OutgoingCard({required this.request});
  final LocationRequest request;

  @override
  Widget build(BuildContext context) {
    final person = AppState.instance.personById(request.personId);
    if (person == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return _Card(
      child: Row(
        children: [
          PersonAvatar(person: person, size: 40, showStatusDot: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.requestsWaitingFor(person.name), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
                Text(l10n.requestsNotifyOnReply, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.hourglass_top_rounded, color: AppTheme.accentAmber, size: 18),
          IconButton(
            tooltip: l10n.requestsCancelSentTooltip,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppTheme.textSecondary,
            visualDensity: VisualDensity.compact,
            onPressed: () => AppState.instance.deleteLocationRequest(request.id),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.request});
  final LocationRequest request;

  @override
  Widget build(BuildContext context) {
    final person = AppState.instance.personById(request.personId);
    if (person == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final accepted = request.status == RequestStatus.accepted;
    final directionLabel = request.direction == RequestDirection.incoming ? l10n.requestsTheyAskedYou(person.name) : l10n.requestsYouAsked(person.name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          PersonAvatar(person: person, size: 36, showStatusDot: false),
          const SizedBox(width: 12),
          Expanded(
            child: Text(directionLabel, style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
          ),
          Icon(
            accepted ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 17,
            color: accepted ? AppTheme.accentGreen : AppTheme.textSecondary,
          ),
          IconButton(
            tooltip: l10n.requestsDeleteTooltip,
            icon: const Icon(Icons.close_rounded, size: 17),
            color: AppTheme.textSecondary,
            visualDensity: VisualDensity.compact,
            onPressed: () => AppState.instance.deleteLocationRequest(request.id),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EmptyStateView(
      icon: Icons.mail_outline_rounded,
      title: l10n.requestsEmptyTitle,
      message: l10n.requestsEmptyMessage,
    );
  }
}
