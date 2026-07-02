import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/location_request.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/person_avatar.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final incoming = state.pendingIncoming;
        final outgoing = state.pendingOutgoing;
        final history = state.history;
        final isEmpty = incoming.isEmpty && outgoing.isEmpty && history.isEmpty;

        return Scaffold(
          appBar: AppBar(title: Text(AppLocalizations.of(context)!.navRequests)),
          body: isEmpty
              ? const _EmptyState()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (incoming.isNotEmpty) ...[
                      _SectionTitle(AppLocalizations.of(context)!.requestsIncoming),
                      for (final r in incoming) _IncomingCard(request: r),
                      const SizedBox(height: 12),
                    ],
                    if (outgoing.isNotEmpty) ...[
                      _SectionTitle(AppLocalizations.of(context)!.requestsWaitingReply),
                      for (final r in outgoing) _OutgoingCard(request: r),
                      const SizedBox(height: 12),
                    ],
                    if (history.isNotEmpty) ...[
                      _SectionTitle(AppLocalizations.of(context)!.requestsHistory),
                      for (final r in history) _HistoryTile(request: r),
                    ],
                  ],
                ),
        );
      },
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

class _IncomingCard extends StatelessWidget {
  const _IncomingCard({required this.request});
  final LocationRequest request;

  @override
  Widget build(BuildContext context) {
    final person = AppState.instance.personById(request.personId);
    if (person == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

class _OutgoingCard extends StatelessWidget {
  const _OutgoingCard({required this.request});
  final LocationRequest request;

  @override
  Widget build(BuildContext context) {
    final person = AppState.instance.personById(request.personId);
    if (person == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
            ],
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
