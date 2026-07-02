import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/support_message.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// Aiuto e assistenza: qualche domanda frequente più un modulo di
/// contatto reale (i messaggi finiscono nella tabella `support_messages`
/// su Supabase). Chi ha Kinly+ viene marcato come priorità dal server.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

List<(String, String)> _faqs(AppLocalizations l10n) => [
      (l10n.helpFaq1Q, l10n.helpFaq1A),
      (l10n.helpFaq2Q, l10n.helpFaq2A),
      (l10n.helpFaq3Q, l10n.helpFaq3A),
      (l10n.helpFaq4Q, l10n.helpFaq4A),
    ];

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _messageController = TextEditingController();
  bool _sending = false;
  Future<List<SupportMessage>>? _pastMessages;

  @override
  void initState() {
    super.initState();
    _pastMessages = AppState.instance.fetchMySupportMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await AppState.instance.sendSupportMessage(text);
      if (!mounted) return;
      _messageController.clear();
      setState(() => _pastMessages = AppState.instance.fetchMySupportMessages());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.helpSentSnackbar)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.helpSendError)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = AppState.instance.isPremium;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileHelpSupport)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(l10n.helpFaqsTitle, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            for (final faq in _faqs(l10n)) _FaqTile(question: faq.$1, answer: faq.$2),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Text(l10n.helpWriteToUs, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary))),
                if (isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.accentAmber.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(l10n.helpPriorityBadge, style: const TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.w700, fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isPremium ? l10n.helpPriorityHint : l10n.helpNormalHint,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.helpDescribeHint,
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _sending ? null : _send,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Text(l10n.helpSend),
            ),
            const SizedBox(height: 28),
            Text(l10n.helpYourRequests, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            FutureBuilder<List<SupportMessage>>(
              future: _pastMessages,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()));
                }
                final messages = snapshot.data ?? const [];
                if (messages.isEmpty) {
                  return Text(l10n.helpNoRequestsYet, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13));
                }
                return Column(children: [for (final m in messages) _SupportMessageTile(message: m)]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Text(question, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
          expandedAlignment: Alignment.topLeft,
          children: [Text(answer, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4))],
        ),
      ),
    );
  }
}

class _SupportMessageTile extends StatelessWidget {
  const _SupportMessageTile({required this.message});
  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(message.message, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppTheme.textPrimary))),
              const SizedBox(width: 8),
              _StatusChip(status: message.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(_formatDate(message.createdAt), style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5)),
          if (message.adminReply != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(10)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.reply_rounded, size: 15, color: AppTheme.accentGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(message.adminReply!, style: TextStyle(color: AppTheme.textPrimary, fontSize: 12.5, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (status) {
      'answered' => l10n.helpStatusAnswered,
      'closed' => l10n.helpStatusClosed,
      _ => l10n.helpStatusInProgress,
    };
    final color = switch (status) {
      'answered' => AppTheme.accentGreen,
      'closed' => AppTheme.textSecondary,
      _ => AppTheme.accentAmber,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10.5)),
    );
  }
}
