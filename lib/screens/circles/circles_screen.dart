import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../models/circle_group.dart';
import '../../models/person.dart';
import '../../models/routine_anomaly.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/person_avatar.dart';
import '../onboarding/create_circle_screen.dart';
import '../onboarding/join_circle_screen.dart';
import 'circle_detail_screen.dart';

class CirclesScreen extends StatefulWidget {
  const CirclesScreen({super.key, this.forceCoachMark = false});

  /// Se true, mostra sempre la guida introduttiva anche se è già stata vista
  /// (richiamata a mano da Impostazioni), invece di controllare se è la
  /// prima volta.
  final bool forceCoachMark;

  @override
  State<CirclesScreen> createState() => _CirclesScreenState();
}

class _CirclesScreenState extends State<CirclesScreen> {
  static const _coachMarkPrefKey = 'circles_coachmark_seen';
  static const _coachMarkTotalSteps = 2;

  final _headerKey = GlobalKey();
  final _cardKey = GlobalKey();

  /// 0 = nascosta, 1..N = passo corrente della guida (N = _coachMarkTotalSteps).
  int _coachMarkStep = 0;
  bool _coachMarkChecked = false;

  void _maybeStartCoachMark(bool hasCircles) {
    if (_coachMarkChecked || !hasCircles) return;
    _coachMarkChecked = true;
    if (widget.forceCoachMark) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _coachMarkStep = 1);
      });
      return;
    }
    unawaited(_maybeShowFirstTime());
  }

  Future<void> _maybeShowFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_coachMarkPrefKey) ?? false) return;
    await prefs.setBool(_coachMarkPrefKey, true);
    if (mounted) setState(() => _coachMarkStep = 1);
  }

  void _advanceCoachMark() {
    setState(() => _coachMarkStep = _coachMarkStep >= _coachMarkTotalSteps ? 0 : _coachMarkStep + 1);
  }

  void _dismissCoachMark() => setState(() => _coachMarkStep = 0);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        _maybeStartCoachMark(state.circles.isNotEmpty);
        GlobalKey? targetFor(int step) => switch (step) {
              1 => _headerKey,
              2 => _cardKey,
              _ => null,
            };
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.circlesTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_outlined),
                onPressed: () => _showAddOptions(context),
              ),
            ],
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  for (final anomaly in state.routineAnomalies) _RoutineAnomalyBanner(anomaly: anomaly),
                  for (var i = 0; i < state.circles.length; i++)
                    _CircleCard(
                      circle: state.circles[i],
                      headerKey: i == 0 ? _headerKey : null,
                      cardKey: i == 0 ? _cardKey : null,
                    ),
                ],
              ),
              if (_coachMarkStep > 0)
                _CoachMarkOverlay(
                  key: ValueKey(_coachMarkStep),
                  step: _coachMarkStep,
                  totalSteps: _coachMarkTotalSteps,
                  targetKey: targetFor(_coachMarkStep),
                  onNext: _advanceCoachMark,
                  onSkip: _dismissCoachMark,
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.circlesAddTitle, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: AppTheme.surfaceAlt, child: Icon(Icons.add_rounded, color: AppTheme.primary)),
                title: Text(l10n.circlesCreateNew),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateCircleScreen(isOnboarding: false)),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: AppTheme.surfaceAlt, child: Icon(Icons.qr_code_rounded, color: AppTheme.primary)),
                title: Text(l10n.circlesHaveInviteCode),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final circle = await Navigator.of(context).push<CircleGroup>(
                    MaterialPageRoute(builder: (_) => const JoinCircleScreen(isOnboarding: false)),
                  );
                  if (circle != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.circlesJoinedSnackbar(circle.name))));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineAnomalyBanner extends StatelessWidget {
  const _RoutineAnomalyBanner({required this.anomaly});
  final RoutineAnomaly anomaly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final person = AppState.instance.personById(anomaly.profileId);
    final name = person?.name ?? l10n.commonSomeone;
    final expected = anomaly.expectedTime.format(context);
    final isArrival = anomaly.kind == RoutineAnomalyKind.lateArrival;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accentAmber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentAmber.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.accentAmber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArrival ? l10n.circlesAnomalyNotYetAt(name, anomaly.zoneName) : l10n.circlesAnomalyStillAt(name, anomaly.zoneName),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  isArrival ? l10n.circlesAnomalyLateArrival(expected, anomaly.minutesLate) : l10n.circlesAnomalyLate(expected, anomaly.minutesLate),
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Riepilogo di una cerchia: icona, nome, membri. Tutte le azioni (aree
/// sicure, messaggi, codice invito...) vivono ora in [CircleDetailScreen],
/// raggiunta toccando l'intera card — prima erano 8-9 pillole ammassate su
/// una fila scorrevole, facile da non scoprire tutta col dito.
class _CircleCard extends StatelessWidget {
  const _CircleCard({required this.circle, this.headerKey, this.cardKey});
  final CircleGroup circle;

  /// Punti di ancoraggio per la guida introduttiva (vedi _CoachMarkOverlay):
  /// valorizzati solo sulla prima cerchia della lista, le altre restano null.
  final GlobalKey? headerKey;
  final GlobalKey? cardKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final members = circle.memberIds.map(AppState.instance.personById).whereType<Person>().toList();
    final isEvents = circle.isEventsCircle;
    // Le Cerchie Eventi hanno un colore fisso (non quello scelto alla
    // creazione, disattivato apposta in quel form) così si riconoscono a
    // colpo d'occhio in mezzo alle altre: sono l'unico tipo di cerchia dove
    // nessuno vede mai la posizione live di nessun altro.
    final accent = isEvents ? AppTheme.accentAmber : circle.color;
    return InkWell(
      key: cardKey,
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CircleDetailScreen(circleId: circle.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: isEvents ? Border.all(color: accent.withOpacity(0.4), width: 1.4) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              key: headerKey,
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: CustomPaint(
                    painter: isEvents ? _DashedCirclePainter(color: accent) : null,
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(0.15)),
                      alignment: Alignment.center,
                      child: Icon(circle.icon, color: accent, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              circle.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: AppTheme.textPrimary),
                            ),
                          ),
                          if (isEvents) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: accent.withOpacity(0.16), borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                l10n.circlesEventsBadge,
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: accent, letterSpacing: 0.4),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        isEvents ? l10n.circlesEventsSubtitle : l10n.mapPeopleCount(members.length),
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
              ],
            ),
            const SizedBox(height: 14),
            // Solo un'anteprima di chi c'è: niente scroll qui (in
            // conflitto col tocco sull'intera card), il dettaglio con tutti
            // i membri toccabili è nella schermata di dettaglio.
            Row(
              children: [
                for (final person in members.take(5))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PersonAvatar(person: person, size: 36, showStatusDot: !isEvents),
                  ),
                if (members.length > 5)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.surfaceAlt),
                    alignment: Alignment.center,
                    child: Text('+${members.length - 5}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bordo tratteggiato per l'icona di una Cerchia Eventi: disegnato a mano
/// perché Flutter non offre un BorderSide tratteggiato pronto all'uso.
class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 1;
    const dashCount = 14;
    const gapFraction = 0.45;
    for (var i = 0; i < dashCount; i++) {
      final startAngle = (i / dashCount) * 2 * math.pi;
      final sweep = (2 * math.pi / dashCount) * (1 - gapFraction);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) => oldDelegate.color != color;
}

/// Guida introduttiva alla prima cerchia della lista: evidenzia a turno
/// l'intestazione e la card intera con un riquadro e una nuvoletta
/// esplicativa. Non "buca" lo scrim scuro attorno al riquadro evidenziato
/// (richiederebbe un CustomPainter dedicato): il bordo bianco intorno al
/// riquadro basta a farlo risaltare comunque.
class _CoachMarkOverlay extends StatefulWidget {
  const _CoachMarkOverlay({super.key, required this.step, required this.totalSteps, required this.targetKey, required this.onNext, required this.onSkip});
  final int step;
  final int totalSteps;
  final GlobalKey? targetKey;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  State<_CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<_CoachMarkOverlay> {
  Rect? _targetRect;

  (String, String) _stepContent(BuildContext context, int step) {
    final l10n = AppLocalizations.of(context)!;
    return switch (step) {
      1 => (l10n.circlesCoachStep1Title, l10n.circlesCoachStep1Body),
      _ => (l10n.circlesCoachStep2Title, l10n.circlesCoachStep2Body),
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final box = widget.targetKey?.currentContext?.findRenderObject() as RenderBox?;
    // Il riquadro va posizionato con Positioned dentro lo Stack di questo
    // overlay: localToGlobal senza `ancestor` restituisce le coordinate
    // rispetto alla radice dell'app (schermo intero), che pero' non
    // coincidono con l'origine locale di questo Stack (spostata in basso
    // dell'altezza di AppBar/status bar). Usarle cosi' com'erano faceva
    // scivolare il riquadro molto piu' in basso del punto vero.
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || overlayBox == null) {
      // Punto di ancoraggio non disegnato (es. schermo molto corto): salta
      // il passo invece di mostrare un riquadro senza senso.
      widget.onNext();
      return;
    }
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    if (mounted) setState(() => _targetRect = topLeft & box.size);
  }

  /// Altezza approssimativa della nuvoletta (titolo + testo + pallini/
  /// pulsanti): usata solo per capire se, in alto, finirebbe per coprire il
  /// riquadro evidenziato.
  static const _estimatedTooltipHeight = 170.0;

  double _tooltipTop(BuildContext context, Rect? rect) {
    final topInset = MediaQuery.of(context).padding.top + 16;
    if (rect != null && rect.top < topInset + _estimatedTooltipHeight) {
      return rect.bottom + 14;
    }
    return topInset;
  }

  @override
  Widget build(BuildContext context) {
    final (title, body) = _stepContent(context, widget.step);
    final rect = _targetRect;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),
        ),
        // Riquadro sul punto evidenziato: solo un contorno, quando la misura
        // riesce (schermo abbastanza alto da mostrare la prima cerchia). Se
        // fallisce si salta direttamente in _measure(), quindi qui arriva
        // sempre un rect valido o non arriva proprio.
        if (rect != null)
          Positioned(
            left: rect.left - 6,
            top: rect.top - 6,
            width: rect.width + 12,
            height: rect.height + 12,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
            ),
          ),
        // La nuvoletta resta di norma in alto, indipendentemente da dove si
        // trova il riquadro evidenziato: provare a metterla sempre "vicino"
        // al riquadro la faceva finire fuori schermo o sotto ad altri
        // elementi su alcuni layout (es. schermi corti, versione web).
        // Eccezione: al passo 1 l'intestazione della cerchia è proprio in
        // cima alla pagina, quindi la posizione fissa in alto ci finirebbe
        // sopra coprendola — in quel caso soltanto la spostiamo appena sotto
        // al riquadro evidenziato.
        Positioned(
          left: 20,
          right: 20,
          top: _tooltipTop(context, rect),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  Text(body, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (var i = 1; i <= widget.totalSteps; i++)
                        Container(
                          margin: const EdgeInsets.only(right: 5),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i <= widget.step ? AppTheme.primary : AppTheme.divider,
                          ),
                        ),
                      const Spacer(),
                      TextButton(onPressed: widget.onSkip, child: Text(AppLocalizations.of(context)!.circlesCoachSkip)),
                      FilledButton(
                        onPressed: widget.onNext,
                        child: Text(
                          widget.step >= widget.totalSteps ? AppLocalizations.of(context)!.circlesCoachFinish : AppLocalizations.of(context)!.circlesCoachNext,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
