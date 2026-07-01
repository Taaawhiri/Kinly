import 'package:flutter/material.dart';
import '../../models/circle_group.dart';
import '../../models/circle_message.dart';
import '../../services/kinly_repository.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/quick_message_catalog.dart';
import '../../widgets/person_avatar.dart';
import '../premium/paywall_screen.dart';

/// Messaggi brevi condivisi con tutta la cerchia: pensati per avvisi
/// importanti ("sto arrivando", "chiamami"), non per chiacchierare — per
/// quello l'app rimanda esplicitamente a WhatsApp o simili.
class CircleMessagesScreen extends StatefulWidget {
  const CircleMessagesScreen({super.key, required this.circle});
  final CircleGroup circle;

  @override
  State<CircleMessagesScreen> createState() => _CircleMessagesScreenState();
}

class _CircleMessagesScreenState extends State<CircleMessagesScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await AppState.instance.sendCircleMessage(circleId: widget.circle.id, body: trimmed);
      _controller.clear();
    } on FreeLimitException catch (e) {
      if (mounted && e.kind == FreeLimitKind.dailyMessageLimit) {
        _showDailyLimitReached();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non siamo riusciti a inviare il messaggio. Riprova.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non siamo riusciti a inviare il messaggio. Riprova.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showDailyLimitReached() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Limite giornaliero raggiunto'),
        content: const Text(
          'Hai già inviato 5 messaggi oggi: è il limite del piano gratuito. Con Kinly+ puoi mandarne quanti vuoi.',
        ),
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
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final messages = state.messagesForCircle(widget.circle.id);
        return Scaffold(
          appBar: AppBar(title: Text('Messaggi · ${widget.circle.name}')),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          state.isPremium
                              ? 'Solo per avvisi brevi e importanti. Per chiacchierare usa WhatsApp o un\'altra app di messaggistica.'
                              : 'Solo per avvisi brevi e importanti (max 5 al giorno nel piano gratuito). Per chiacchierare usa WhatsApp o un\'altra app di messaggistica.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Text(
                            'Nessun messaggio ancora.\nManda il primo avviso qui sotto.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.4),
                          ),
                        )
                      : ListView.separated(
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => _MessageTile(message: messages[i]),
                        ),
                ),
                _Composer(controller: _controller, sending: _sending, onSend: _send),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message});
  final CircleMessage message;

  @override
  Widget build(BuildContext context) {
    final sender = AppState.instance.personById(message.senderId);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sender != null) PersonAvatar(person: sender, size: 36, showStatusDot: false),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(sender?.name ?? 'Qualcuno', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textPrimary)),
                    const SizedBox(width: 8),
                    Text(_formatTime(message.createdAt), style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(message.body, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'ora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min fa';
    if (diff.inHours < 24) return '${diff.inHours} h fa';
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.sending, required this.onSend});
  final TextEditingController controller;
  final bool sending;
  final Future<void> Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: QuickMessageCatalog.options.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final option = QuickMessageCatalog.options[i];
                return ActionChip(
                  label: Text(option, style: const TextStyle(fontSize: 12.5)),
                  backgroundColor: AppTheme.surfaceAlt,
                  onPressed: sending ? null : () => onSend(option),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLength: CircleMessage.maxLength,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  decoration: InputDecoration(
                    hintText: 'Scrivi un avviso breve...',
                    filled: true,
                    fillColor: AppTheme.surfaceAlt,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: onSend,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: sending ? null : () => onSend(controller.text),
                icon: sending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
