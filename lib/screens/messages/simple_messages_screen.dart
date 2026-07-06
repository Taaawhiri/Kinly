import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/circle_group.dart';
import '../../models/circle_message.dart';
import '../../services/kinly_repository.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/quick_message_catalog.dart';
import '../../widgets/person_avatar.dart';
import '../people/simple_person_detail_screen.dart';
import '../premium/paywall_screen.dart';

/// Versione di CircleMessagesScreen per la Modalità Rapida: stessa logica
/// (stesso limite giornaliero gratuito, stessi messaggi rapidi), ma niente
/// da scegliere all'apertura — mostra subito i messaggi della prima cerchia,
/// con testo e pulsanti più grandi. Chi ha più di una cerchia può comunque
/// cambiarla dai chip in alto.
class SimpleMessagesScreen extends StatefulWidget {
  const SimpleMessagesScreen({super.key});

  @override
  State<SimpleMessagesScreen> createState() => _SimpleMessagesScreenState();
}

class _SimpleMessagesScreenState extends State<SimpleMessagesScreen> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _selectedCircleId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(String circleId, String body) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await AppState.instance.sendCircleMessage(circleId: circleId, body: trimmed);
      _controller.clear();
    } on FreeLimitException catch (e) {
      if (mounted && e.kind == FreeLimitKind.dailyMessageLimit) _showDailyLimitReached();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.circleMessagesSendError)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showDailyLimitReached() {
    showDialog<void>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(l10n.circleMessagesDailyLimitTitle),
          content: Text(l10n.circleMessagesDailyLimitBody),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.circleMessagesGotIt)),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
              },
              child: Text(l10n.circleMessagesDiscoverPlus),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final circles = AppState.instance.circles;
        if (circles.isEmpty) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(title: Text(l10n.simpleMessagesTitle)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.circleMessagesEmptyMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.4),
                ),
              ),
            ),
          );
        }

        final selected = circles.firstWhere(
          (c) => c.id == _selectedCircleId,
          orElse: () => circles.first,
        );
        final messages = AppState.instance.messagesForCircle(selected.id);

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(title: Text(l10n.simpleMessagesTitle)),
          body: SafeArea(
            child: Column(
              children: [
                if (circles.length > 1) _CirclePicker(circles: circles, selectedId: selected.id, onSelect: (id) => setState(() => _selectedCircleId = id)),
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.forum_outlined, size: 40, color: AppTheme.textSecondary),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.circleMessagesEmptyTitle,
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.circleMessagesEmptyMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) => _SimpleMessageTile(message: messages[i]),
                        ),
                ),
                _SimpleComposer(controller: _controller, sending: _sending, onSend: (body) => _send(selected.id, body)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CirclePicker extends StatelessWidget {
  const _CirclePicker({required this.circles, required this.selectedId, required this.onSelect});
  final List<CircleGroup> circles;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.simpleMessagesChooseCircle, style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w700, fontSize: 12.5)),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: circles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final circle = circles[i];
                final selected = circle.id == selectedId;
                return ChoiceChip(
                  label: Text(circle.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  selected: selected,
                  onSelected: (_) => onSelect(circle.id),
                  selectedColor: AppTheme.primary.withOpacity(0.16),
                  labelStyle: TextStyle(color: selected ? AppTheme.primary : AppTheme.textPrimary),
                  side: BorderSide(color: selected ? AppTheme.primary : AppTheme.divider),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleMessageTile extends StatelessWidget {
  const _SimpleMessageTile({required this.message});
  final CircleMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sender = AppState.instance.personById(message.senderId);
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: sender != null && !sender.isMe
            ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SimplePersonDetailScreen(personId: sender.id)))
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sender != null) PersonAvatar(person: sender, size: 44, showStatusDot: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sender?.name ?? l10n.commonSomeone,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary),
                          ),
                        ),
                        Text(_formatTime(l10n, message.createdAt), style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(message.body, style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(AppLocalizations l10n, DateTime dt) {
    final local = dt.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return l10n.circleMessagesTimeNow;
    if (diff.inMinutes < 60) return l10n.circleMessagesTimeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.circleMessagesTimeHoursAgo(diff.inHours);
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  }
}

class _SimpleComposer extends StatelessWidget {
  const _SimpleComposer({required this.controller, required this.sending, required this.onSend});
  final TextEditingController controller;
  final bool sending;
  final Future<void> Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final quickOptions = QuickMessageCatalog.options(l10n);
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bottoni grandi invece delle chip piccole della versione completa:
          // in Modalità Rapida deve essere possibile mandare un avviso senza
          // scrivere nulla, con un solo tocco preciso.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in quickOptions)
                OutlinedButton(
                  onPressed: sending ? null : () => onSend(option),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  child: Text(option, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLength: CircleMessage.maxLength,
                  style: const TextStyle(fontSize: 16),
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  decoration: InputDecoration(
                    hintText: l10n.circleMessagesComposerHint,
                    filled: true,
                    fillColor: AppTheme.surfaceAlt,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                  onSubmitted: onSend,
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: AppTheme.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: sending ? null : () => onSend(controller.text),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
