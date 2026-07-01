import 'package:flutter/material.dart';
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

const _faqs = [
  (
    'Chi vede la mia posizione?',
    'Solo chi fa parte di una tua cerchia, e solo se la tua modalità di condivisione lo permette (automatica, su richiesta o sospesa). Puoi cambiarla in ogni momento dal tuo profilo.',
  ),
  (
    'Come invito qualcuno in una cerchia?',
    'Crea una cerchia dalla scheda "Cerchie" e condividi il codice invito che ti viene mostrato: chi lo inserisce entra subito a farne parte.',
  ),
  (
    'Cosa cambia con Kinly+?',
    'Il piano gratuito ha un limite di 2 cerchie e 6 persone per cerchia. Kinly+ toglie i limiti e sblocca cronologia posizioni, aree sicure e avvisi di guida.',
  ),
  (
    'Come cancello un\'area sicura o esco da una cerchia?',
    'Le aree sicure si eliminano dalla schermata "Aree sicure" di una cerchia (icona del cestino). Per uscire da una cerchia scrivici da qui: te ne aiutiamo a occupare a mano finché non aggiungiamo il pulsante in app.',
  ),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Messaggio inviato, ti risponderemo via email.')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non siamo riusciti a inviare il messaggio. Riprova.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = AppState.instance.isPremium;
    return Scaffold(
      appBar: AppBar(title: const Text('Aiuto e assistenza')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('Domande frequenti', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            for (final faq in _faqs) _FaqTile(question: faq.$1, answer: faq.$2),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Text('Scrivici', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary))),
                if (isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.accentAmber.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: const Text('Priorità Kinly+', style: TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.w700, fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isPremium
                  ? 'Come abbonato Kinly+ la tua richiesta viene messa in coda prioritaria.'
                  : 'Ti rispondiamo via email appena possibile.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Descrivi il problema o la domanda...',
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
                  : const Text('Invia'),
            ),
            const SizedBox(height: 28),
            Text('Le tue richieste', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 10),
            FutureBuilder<List<SupportMessage>>(
              future: _pastMessages,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()));
                }
                final messages = snapshot.data ?? const [];
                if (messages.isEmpty) {
                  return Text('Non hai ancora inviato nessuna richiesta.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13));
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
    final label = switch (status) {
      'answered' => 'Risposto',
      'closed' => 'Chiuso',
      _ => 'In corso',
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
