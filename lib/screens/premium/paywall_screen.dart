import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// Schermata di presentazione di Kinly+: solo design, nessun pagamento vero.
/// Il pulsante in fondo non attiva alcun servizio di fatturazione, mostra
/// solo un messaggio: l'abilitazione reale avverrà quando sarà collegato un
/// vero provider di pagamenti. Se l'account è già premium (impostato a
/// mano da SQL Editor, per ora) mostra lo stato attivo con la possibilità
/// di richiedere l'annullamento.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

const _features = [
  (Icons.history_rounded, 'Cronologia posizioni', 'Rivedi dove sono stati i membri della cerchia nei giorni passati.'),
  (Icons.fence_rounded, 'Aree sicure', 'Casa, lavoro, scuola: ricevi una notifica personalizzata quando qualcuno arriva o esce.'),
  (Icons.groups_rounded, 'Cerchie senza limiti', 'Nessun limite al numero di cerchie o di persone per cerchia.'),
  (Icons.speed_rounded, 'Avvisi di guida', 'Sappi quando chi guida supera un limite di velocità impostato.'),
  (Icons.gps_fixed_rounded, 'Tracciamento in background', 'La posizione continua ad aggiornarsi anche con l\'app chiusa.'),
  (Icons.forum_rounded, 'Messaggi illimitati', 'Manda quanti messaggi vuoi alla tua cerchia, senza il limite giornaliero.'),
  (Icons.support_agent_rounded, 'Assistenza prioritaria', 'Supporto dedicato per la tua cerchia, 7 giorni su 7.'),
];

class _PaywallScreenState extends State<PaywallScreen> {
  bool _sendingCancelRequest = false;
  bool _cancelRequestSent = false;

  Future<void> _requestCancellation() async {
    setState(() => _sendingCancelRequest = true);
    try {
      await AppState.instance.sendSupportMessage(
        'Vorrei annullare il mio abbonamento Kinly+.',
      );
      if (mounted) setState(() => _cancelRequestSent = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non siamo riusciti a inviare la richiesta. Riprova.')));
      }
    } finally {
      if (mounted) setState(() => _sendingCancelRequest = false);
    }
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('In arrivo'),
        content: const Text('I pagamenti Kinly+ non sono ancora attivi: questa è solo un\'anteprima del design.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ho capito')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final isPremium = AppState.instance.isPremium;
        return Scaffold(
          appBar: AppBar(title: const Text('Kinly+')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: isPremium ? [AppTheme.accentGreen, const Color(0xFF17924E)] : [AppTheme.primary, AppTheme.primaryDark]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          isPremium ? 'Kinly+ attivo' : 'Kinly+',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isPremium ? 'Il tuo abbonamento è attivo' : 'Più tranquillità per tutta la cerchia',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, height: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPremium
                            ? 'Tutti i vantaggi qui sotto sono sbloccati per te e per le tue cerchie.'
                            : 'Basta un solo abbonamento a persona per sbloccare i vantaggi per tutte le cerchie di cui fa parte.',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Cosa include', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                for (final f in _features)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: (isPremium ? AppTheme.accentGreen : AppTheme.primary).withOpacity(0.12)),
                          alignment: Alignment.center,
                          child: Icon(f.$1, color: isPremium ? AppTheme.accentGreen : AppTheme.primary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.$2, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textPrimary)),
                              Text(f.$3, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3)),
                            ],
                          ),
                        ),
                        if (isPremium) const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 18),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                if (isPremium) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gestisci abbonamento', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
                        const SizedBox(height: 6),
                        Text(
                          'Il tuo Kinly+ non è ancora collegato a un pagamento reale (nessun sistema di fatturazione attivo). Per disattivarlo, invia una richiesta: te lo disattiviamo a mano.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        if (_cancelRequestSent)
                          Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 18),
                              SizedBox(width: 8),
                              Expanded(child: Text('Richiesta inviata.', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
                            ],
                          )
                        else
                          OutlinedButton(
                            onPressed: _sendingCancelRequest ? null : _requestCancellation,
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            child: _sendingCancelRequest
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                                : const Text('Richiedi annullamento'),
                          ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Piano mensile', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                              SizedBox(height: 4),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: '4,99 €', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                                    TextSpan(text: ' / mese', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text('Disdici quando vuoi', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => _showComingSoon(context),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                    child: const Text('Passa a Kinly+'),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Anteprima del design: i pagamenti non sono ancora attivi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
