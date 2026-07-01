import 'package:flutter/material.dart';
import '../../models/person.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// Schermata di presentazione di Kinly+: solo design, nessun pagamento vero.
/// I pulsanti "Passa a" non attivano alcun servizio di fatturazione, mandano
/// solo una richiesta di assistenza: l'abilitazione reale avverrà quando
/// sarà collegato un vero provider di pagamenti (per ora il piano si imposta
/// a mano da SQL Editor, come già faceva is_premium).
///
/// Due livelli, oltre al gratuito:
/// - Individual: sblocca Kinly+ solo per chi paga.
/// - Family: sblocca Kinly+ anche per chi entra (fino a 6 persone, per data
///   di ingresso) in una cerchia creata da chi ha questo piano — vedi
///   `is_effectively_premium` nello schema.
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
  bool _sendingUpgrade = false;
  String? _upgradeRequestSentFor;

  Future<void> _requestCancellation() async {
    setState(() => _sendingCancelRequest = true);
    try {
      await AppState.instance.sendSupportMessage('Vorrei annullare il mio abbonamento Kinly+.');
      if (mounted) setState(() => _cancelRequestSent = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non siamo riusciti a inviare la richiesta. Riprova.')));
      }
    } finally {
      if (mounted) setState(() => _sendingCancelRequest = false);
    }
  }

  Future<void> _requestPlan(String planLabel) async {
    setState(() => _sendingUpgrade = true);
    try {
      await AppState.instance.sendSupportMessage('Vorrei attivare il piano Kinly+ $planLabel.');
      if (mounted) setState(() => _upgradeRequestSentFor = planLabel);
      if (mounted) _showComingSoon(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non siamo riusciti a inviare la richiesta. Riprova.')));
      }
    } finally {
      if (mounted) setState(() => _sendingUpgrade = false);
    }
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('In arrivo'),
        content: const Text('I pagamenti Kinly+ non sono ancora attivi: abbiamo registrato la tua richiesta, ti attiveremo il piano a mano.'),
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
        final state = AppState.instance;
        final isPremium = state.isPremium;
        final tier = state.myPremiumTier;
        final familyOwnerName = state.familyPlanOwnerName;

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
                          switch (tier) {
                            PremiumTier.family => 'Kinly+ Family attivo',
                            PremiumTier.individual => 'Kinly+ Individual attivo',
                            PremiumTier.none => familyOwnerName != null ? 'Kinly+ incluso' : 'Kinly+',
                          },
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        familyOwnerName != null
                            ? 'Incluso nel piano Family di $familyOwnerName'
                            : (isPremium ? 'Il tuo abbonamento è attivo' : 'Più tranquillità per tutta la cerchia'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, height: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        familyOwnerName != null
                            ? 'Finché fai parte della sua cerchia, hai tutti i vantaggi Kinly+ senza pagare nulla.'
                            : (isPremium
                                ? 'Tutti i vantaggi qui sotto sono sbloccati per te e per le tue cerchie.'
                                : 'Un piano Individual sblocca i vantaggi solo per te; un piano Family li estende a chi inviti.'),
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
                if (familyOwnerName != null) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(16)),
                    child: Text(
                      'Non paghi nulla: chi ha creato quella cerchia con il piano Family ha esteso Kinly+ a te e agli altri primi membri (fino a 6).',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                    ),
                  ),
                ] else if (tier == PremiumTier.family) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Il tuo piano Family', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
                        const SizedBox(height: 6),
                        Text(
                          'Chi entra in una cerchia che hai creato (fino a 6 persone, in base a quando sono entrate) ha Kinly+ incluso, senza pagare nulla.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        if (_cancelRequestSent)
                          _sentRow('Richiesta inviata.')
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
                ] else if (tier == PremiumTier.individual) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gestisci abbonamento', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
                        const SizedBox(height: 6),
                        Text(
                          'Il tuo Kinly+ non è ancora collegato a un pagamento reale. Per disattivarlo, invia una richiesta: te lo disattiviamo a mano.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        if (_cancelRequestSent)
                          _sentRow('Richiesta inviata.')
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
                  const SizedBox(height: 14),
                  _PlanCard(
                    title: 'Passa a Family',
                    price: '9,90 €',
                    description: 'Estendi Kinly+ anche a chi inviti nelle cerchie che crei (fino a 6 persone), non solo a te.',
                    buttonLabel: 'Passa a Family',
                    busy: _sendingUpgrade,
                    sent: _upgradeRequestSentFor == 'Family (9,90€/mese)',
                    onTap: () => _requestPlan('Family (9,90€/mese)'),
                  ),
                ] else ...[
                  _PlanCard(
                    title: 'Individual',
                    price: '3,90 €',
                    description: 'Sblocca tutti i vantaggi Kinly+ per te, in tutte le tue cerchie.',
                    buttonLabel: 'Passa a Individual',
                    busy: _sendingUpgrade,
                    sent: _upgradeRequestSentFor == 'Individual (3,90€/mese)',
                    onTap: () => _requestPlan('Individual (3,90€/mese)'),
                  ),
                  const SizedBox(height: 14),
                  _PlanCard(
                    title: 'Family',
                    price: '9,90 €',
                    description: 'Un solo abbonamento: chi entra in una cerchia che crei (fino a 6 persone) ha Kinly+ incluso.',
                    buttonLabel: 'Passa a Family',
                    highlighted: true,
                    busy: _sendingUpgrade,
                    sent: _upgradeRequestSentFor == 'Family (9,90€/mese)',
                    onTap: () => _requestPlan('Family (9,90€/mese)'),
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

  Widget _sentRow(String label) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.description,
    required this.buttonLabel,
    required this.busy,
    required this.sent,
    required this.onTap,
    this.highlighted = false,
  });

  final String title;
  final String price;
  final String description;
  final String buttonLabel;
  final bool busy;
  final bool sent;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: highlighted ? AppTheme.primary.withOpacity(0.06) : AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlighted ? AppTheme.primary.withOpacity(0.4) : AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: price, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                        TextSpan(text: ' / mese', style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4)),
          const SizedBox(height: 14),
          if (sent)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.accentGreen, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Richiesta inviata.', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
              ],
            )
          else
            FilledButton(
              onPressed: busy ? null : onTap,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : Text(buttonLabel),
            ),
        ],
      ),
    );
  }
}
