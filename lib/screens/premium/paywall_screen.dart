import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
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

List<(IconData, String, String)> _features(AppLocalizations l10n) => [
      (Icons.history_rounded, l10n.paywallFeatureLocationHistoryTitle, l10n.paywallFeatureLocationHistoryDesc),
      (Icons.route_rounded, l10n.paywallFeatureStatsTitle, l10n.paywallFeatureStatsDesc),
      (Icons.fence_rounded, l10n.paywallFeatureSafeZonesTitle, l10n.paywallFeatureSafeZonesDesc),
      (Icons.groups_rounded, l10n.paywallFeatureUnlimitedCirclesTitle, l10n.paywallFeatureUnlimitedCirclesDesc),
      (Icons.speed_rounded, l10n.paywallFeatureDrivingTitle, l10n.paywallFeatureDrivingDesc),
      (Icons.gps_fixed_rounded, l10n.paywallFeatureBackgroundTitle, l10n.paywallFeatureBackgroundDesc),
      (Icons.forum_rounded, l10n.paywallFeatureUnlimitedMsgTitle, l10n.paywallFeatureUnlimitedMsgDesc),
      (Icons.shopping_bag_outlined, l10n.paywallFeatureShoppingTitle, l10n.paywallFeatureShoppingDesc),
      (Icons.visibility_off_rounded, l10n.paywallFeatureGhostModeTitle, l10n.paywallFeatureGhostModeDesc),
      (Icons.widgets_rounded, l10n.paywallFeatureWidgetTitle, l10n.paywallFeatureWidgetDesc),
      (Icons.support_agent_rounded, l10n.paywallFeaturePriorityTitle, l10n.paywallFeaturePriorityDesc),
    ];

class _PaywallScreenState extends State<PaywallScreen> {
  bool _sendingCancelRequest = false;
  bool _cancelRequestSent = false;
  bool _sendingUpgrade = false;
  String? _upgradeRequestSentFor;

  Future<void> _requestCancellation() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _sendingCancelRequest = true);
    try {
      await AppState.instance.sendSupportMessage(l10n.paywallCancelMessage);
      if (mounted) setState(() => _cancelRequestSent = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.paywallRequestError)));
      }
    } finally {
      if (mounted) setState(() => _sendingCancelRequest = false);
    }
  }

  Future<void> _requestPlan(String planLabel) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _sendingUpgrade = true);
    try {
      await AppState.instance.sendSupportMessage(l10n.paywallUpgradeMessage(planLabel));
      if (mounted) setState(() => _upgradeRequestSentFor = planLabel);
      if (mounted) _showComingSoon(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.paywallRequestError)));
      }
    } finally {
      if (mounted) setState(() => _sendingUpgrade = false);
    }
  }

  void _showComingSoon(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l10n.paywallComingSoonTitle),
        content: Text(l10n.paywallComingSoonBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.circleMessagesGotIt)),
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
        final l10n = AppLocalizations.of(context)!;

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
                            PremiumTier.family => l10n.paywallFamilyActive,
                            PremiumTier.individual => l10n.paywallIndividualActive,
                            PremiumTier.none => familyOwnerName != null ? l10n.paywallIncluded : 'Kinly+',
                          },
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        familyOwnerName != null
                            ? l10n.paywallIncludedInFamilyOf(familyOwnerName)
                            : (isPremium ? l10n.paywallYourSubscriptionActive : l10n.paywallMorePeaceOfMind),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, height: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        familyOwnerName != null
                            ? l10n.paywallFamilyIncludedHint
                            : (isPremium ? l10n.paywallAllUnlockedHint : l10n.paywallChooseTierHint),
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(l10n.paywallWhatIncludes, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                for (final f in _features(l10n))
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
                const SizedBox(height: 24),
                Text(l10n.paywallComparePlans, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                const _PlanComparisonTable(),
                const SizedBox(height: 12),
                if (familyOwnerName != null) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: AppTheme.surfaceAlt, borderRadius: BorderRadius.circular(16)),
                    child: Text(
                      l10n.paywallFamilyMemberHint,
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
                        Text(l10n.paywallYourFamilyPlan, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
                        const SizedBox(height: 6),
                        Text(
                          l10n.paywallFamilyOwnerHint,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        if (_cancelRequestSent)
                          _sentRow(l10n.paywallRequestSent)
                        else
                          OutlinedButton(
                            onPressed: _sendingCancelRequest ? null : _requestCancellation,
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            child: _sendingCancelRequest
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                                : Text(l10n.paywallRequestCancellation),
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
                        Text(l10n.paywallManageSubscription, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary)),
                        const SizedBox(height: 6),
                        Text(
                          l10n.paywallIndividualCancelHint,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        if (_cancelRequestSent)
                          _sentRow(l10n.paywallRequestSent)
                        else
                          OutlinedButton(
                            onPressed: _sendingCancelRequest ? null : _requestCancellation,
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            child: _sendingCancelRequest
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                                : Text(l10n.paywallRequestCancellation),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PlanCard(
                    title: l10n.paywallSwitchToFamily,
                    price: l10n.paywallFamilyPrice,
                    description: l10n.paywallFamilyUpgradeDesc,
                    buttonLabel: l10n.paywallSwitchToFamily,
                    busy: _sendingUpgrade,
                    sent: _upgradeRequestSentFor == l10n.paywallPlanLabelFamily,
                    onTap: () => _requestPlan(l10n.paywallPlanLabelFamily),
                  ),
                ] else ...[
                  _PlanCard(
                    title: l10n.paywallIndividualTitle,
                    price: l10n.paywallIndividualPrice,
                    description: l10n.paywallIndividualDesc,
                    buttonLabel: l10n.paywallSwitchToIndividual,
                    busy: _sendingUpgrade,
                    sent: _upgradeRequestSentFor == l10n.paywallPlanLabelIndividual,
                    onTap: () => _requestPlan(l10n.paywallPlanLabelIndividual),
                  ),
                  const SizedBox(height: 14),
                  _PlanCard(
                    title: l10n.paywallFamilyTitle,
                    price: l10n.paywallFamilyPrice,
                    description: l10n.paywallFamilyDesc,
                    buttonLabel: l10n.paywallSwitchToFamily,
                    highlighted: true,
                    busy: _sendingUpgrade,
                    sent: _upgradeRequestSentFor == l10n.paywallPlanLabelFamily,
                    onTap: () => _requestPlan(l10n.paywallPlanLabelFamily),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      l10n.paywallDesignPreviewHint,
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
    final l10n = AppLocalizations.of(context)!;
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
                        TextSpan(text: l10n.paywallPerMonth, style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary)),
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
                Expanded(child: Text(l10n.paywallRequestSent, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13))),
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

List<(String, String?, String, String)> _comparisonRows(AppLocalizations l10n) => [
      (l10n.paywallCompareCirclesMembers, l10n.paywallCompareFreeCircleLimit, l10n.paywallCompareUnlimited, l10n.paywallCompareUnlimited),
      (l10n.paywallCompareMessagesPingExpenses, l10n.paywallCompare5PerDay, l10n.paywallCompareUnlimited, l10n.paywallCompareUnlimited),
      (l10n.paywallCompareSafeZonesCreate, null, 'check', 'check'),
      (l10n.personLocationHistoryLink, null, 'check', 'check'),
      (l10n.personStatisticsLink, null, 'check', 'check'),
      (l10n.personDrivingAlertsLink, null, 'check', 'check'),
      (l10n.privacyBackgroundTrackingHeader, null, 'check', 'check'),
      (l10n.paywallFeatureShoppingTitle, null, 'check', 'check'),
      (l10n.paywallFeatureGhostModeTitle, null, 'check', 'check'),
      (l10n.paywallFeatureWidgetTitle, null, 'check', 'check'),
      (l10n.paywallFeaturePriorityTitle, null, 'check', 'check'),
      (l10n.paywallCompareWhoBenefits, l10n.paywallCompareOnlyYou, l10n.paywallCompareOnlyYou, l10n.paywallCompareUpTo6People),
      (l10n.paywallComparePrice, l10n.paywallCompareFree, l10n.paywallCompareIndividualPricePerMonth, l10n.paywallCompareFamilyPricePerMonth),
    ];

/// Tabella riassuntiva Free / Individual / Family: utile per decidere
/// rapidamente senza dover leggere le descrizioni una per una.
class _PlanComparisonTable extends StatelessWidget {
  const _PlanComparisonTable();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {0: FlexColumnWidth(1.5), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1)},
        children: [
          TableRow(
            decoration: BoxDecoration(color: AppTheme.surfaceAlt),
            children: [
              const _TableCell('', header: true),
              _TableCell(l10n.paywallTierFree, header: true),
              _TableCell(l10n.paywallIndividualTitle, header: true),
              _TableCell(l10n.paywallFamilyTitle, header: true),
            ],
          ),
          for (final row in _comparisonRows(l10n))
            TableRow(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.divider, width: 0.6))),
              children: [
                _TableCell(row.$1, alignStart: true),
                _TableValueCell(row.$2),
                _TableValueCell(row.$3),
                _TableValueCell(row.$4),
              ],
            ),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.text, {this.header = false, this.alignStart = false});
  final String text;
  final bool header;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: alignStart ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          fontWeight: header ? FontWeight.w800 : FontWeight.w600,
          fontSize: header ? 11.5 : 11.5,
          color: header ? AppTheme.textSecondary : AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _TableValueCell extends StatelessWidget {
  const _TableValueCell(this.value);
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(child: Icon(Icons.close_rounded, size: 15, color: AppTheme.textSecondary)),
      );
    }
    if (value == 'check') {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(child: Icon(Icons.check_rounded, size: 16, color: AppTheme.accentGreen)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Text(value!, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppTheme.textPrimary)),
    );
  }
}
