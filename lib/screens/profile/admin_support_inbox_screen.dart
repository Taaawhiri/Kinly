import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/support_message.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// Solo per admin (profiles.is_admin, impostato a mano da SQL Editor): vede
/// e risponde a tutti i messaggi di assistenza, non solo ai propri. La
/// risposta arriva all'utente direttamente nella sua schermata "Aiuto e
/// assistenza" (nessun invio email, è già così anche per l'invio).
class AdminSupportInboxScreen extends StatefulWidget {
  const AdminSupportInboxScreen({super.key});

  @override
  State<AdminSupportInboxScreen> createState() => _AdminSupportInboxScreenState();
}

class _AdminSupportInboxScreenState extends State<AdminSupportInboxScreen> {
  late Future<List<SupportMessage>> _messages;

  @override
  void initState() {
    super.initState();
    _messages = AppState.instance.fetchAllSupportMessagesForAdmin();
  }

  void _reload() {
    setState(() => _messages = AppState.instance.fetchAllSupportMessagesForAdmin());
  }

  Future<void> _openReply(SupportMessage message) async {
    final controller = TextEditingController(text: message.adminReply ?? '');
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => _ReplySheet(message: message, controller: controller),
    );
    if (sent == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileAdminSupport)),
      body: SafeArea(
        child: FutureBuilder<List<SupportMessage>>(
          future: _messages,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final messages = snapshot.data ?? const [];
            if (messages.isEmpty) {
              return Center(child: Text(l10n.adminSupportNoMessages, style: TextStyle(color: AppTheme.textSecondary)));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _MessageCard(message: messages[i], onTap: () => _openReply(messages[i])),
            );
          },
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.onTap});
  final SupportMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (message.isPriority)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.accentAmber.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text(l10n.adminSupportPriority, style: const TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.w700, fontSize: 10.5)),
                  ),
                Expanded(child: Text(_formatDate(message.createdAt), style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5))),
                Icon(
                  message.status == 'answered' ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  size: 15,
                  color: message.status == 'answered' ? AppTheme.accentGreen : AppTheme.accentAmber,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message.message, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppTheme.textPrimary)),
            if (message.adminReply != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(10)),
                child: Text(l10n.adminSupportRepliedWith(message.adminReply!), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

class _ReplySheet extends StatefulWidget {
  const _ReplySheet({required this.message, required this.controller});
  final SupportMessage message;
  final TextEditingController controller;

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  bool _sending = false;

  Future<void> _send() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await AppState.instance.replyToSupportMessage(id: widget.message.id, reply: text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.adminSupportReplyError)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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
          Text(l10n.adminSupportReplyTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(widget.message.message, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: widget.controller,
            autofocus: true,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: l10n.adminSupportReplyHint,
              filled: true,
              fillColor: AppTheme.surfaceAlt,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _sending ? null : _send,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: _sending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : Text(l10n.adminSupportSendReply),
          ),
        ],
      ),
    );
  }
}
