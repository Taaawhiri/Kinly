import 'dart:math';
import 'package:flutter/material.dart';
import '../data/gacha_service.dart';
import '../models/city_card.dart';
import '../models/pack_result.dart';
import '../models/rarity.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/city_card_widget.dart';
import '../widgets/rarity_badge.dart';

enum _Phase { idle, shaking, bursting, revealing, summary }

/// Schermata di apertura busta: la busta è gratuita durante la fase di
/// test, ma il motore delle probabilità (vedi [GachaService]) è già quello
/// "definitivo" che verrà usato quando le buste diventeranno a pagamento.
class PackOpeningScreen extends StatefulWidget {
  const PackOpeningScreen({super.key});

  @override
  State<PackOpeningScreen> createState() => _PackOpeningScreenState();
}

class _PackOpeningScreenState extends State<PackOpeningScreen> with TickerProviderStateMixin {
  _Phase _phase = _Phase.idle;
  late final AnimationController _shakeController;
  late final AnimationController _flashController;
  PackResult? _result;
  List<int> _revealOrder = [];
  final Set<int> _revealedIndexes = {};

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _startOpening() async {
    if (_phase != _Phase.idle) return;
    setState(() => _phase = _Phase.shaking);
    await _shakeController.forward(from: 0);

    setState(() => _phase = _Phase.bursting);
    final result = GachaService.openPack();
    // Rivela dalla rarità più bassa alla più alta: il colpo migliore arriva per ultimo.
    final order = List<int>.generate(result.cards.length, (i) => i)
      ..sort((a, b) => result.cards[a].rarity.index.compareTo(result.cards[b].rarity.index));

    await _flashController.forward(from: 0);
    setState(() {
      _result = result;
      _revealOrder = order;
      _phase = _Phase.revealing;
    });
    await _flashController.reverse();

    for (final index in _revealOrder) {
      await Future.delayed(Duration(milliseconds: index == _revealOrder.last ? 550 : 380));
      if (!mounted) return;
      setState(() => _revealedIndexes.add(index));
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _phase = _Phase.summary);
  }

  void _reset() {
    setState(() {
      _phase = _Phase.idle;
      _result = null;
      _revealOrder = [];
      _revealedIndexes.clear();
    });
  }

  Rarity? get _bestRarity {
    if (_result == null) return null;
    return _result!.cards.map((c) => c.rarity).reduce((a, b) => a.index >= b.index ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Apri busta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showOdds(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(child: Center(child: _buildPhaseContent(context))),
          _BurstFlash(controller: _flashController, color: _bestRarity?.accentColor ?? AppTheme.gold, isGodPack: _result?.isGodPack ?? false),
        ],
      ),
    );
  }

  Widget _buildPhaseContent(BuildContext context) {
    switch (_phase) {
      case _Phase.idle:
      case _Phase.shaking:
      case _Phase.bursting:
        return _PackArt(
          shakeController: _shakeController,
          isShaking: _phase == _Phase.shaking,
          isBursting: _phase == _Phase.bursting,
          onTap: _startOpening,
        );
      case _Phase.revealing:
        return _RevealGrid(
          cards: _result!.cards,
          isNew: _result!.isNew,
          revealed: _revealedIndexes,
          isGodPack: _result!.isGodPack,
        );
      case _Phase.summary:
        return _Summary(result: _result!, onAgain: _reset, onDone: () => Navigator.of(context).pop());
    }
  }

  void _showOdds(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const _OddsSheet(),
    );
  }
}

class _PackArt extends StatelessWidget {
  const _PackArt({
    required this.shakeController,
    required this.isShaking,
    required this.isBursting,
    required this.onTap,
  });

  final AnimationController shakeController;
  final bool isShaking;
  final bool isBursting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: shakeController,
          builder: (context, child) {
            final t = shakeController.value;
            final angle = isShaking ? sin(t * 4 * pi) * 0.09 * (1 - t) : 0.0;
            final scale = isBursting ? 1.0 + t * 0.0 : 1.0; // burst scale handled by flash overlay
            return Transform.rotate(
              angle: angle,
              child: Transform.scale(scale: scale, child: child),
            );
          },
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 220,
              height: 312,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E2530), Color(0xFF0B0E14)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppTheme.gold.withOpacity(0.5), width: 1.4),
                boxShadow: [BoxShadow(color: AppTheme.gold.withOpacity(0.25), blurRadius: 30, spreadRadius: 2)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const UrbisLogo(size: 96),
                  const SizedBox(height: 18),
                  const Text(
                    'BUSTA URBIS',
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 6),
                  const Text('5 carte casuali', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14532D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'GRATIS · FASE DI TEST',
                      style: TextStyle(color: Color(0xFF6EE7A8), fontWeight: FontWeight.w800, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          isShaking || isBursting ? 'Si apre...' : 'Tocca la busta per aprirla',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
        ),
      ],
    );
  }
}

class _BurstFlash extends StatelessWidget {
  const _BurstFlash({required this.controller, required this.color, required this.isGodPack});
  final AnimationController controller;
  final Color color;
  final bool isGodPack;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.value <= 0.0) return const SizedBox.shrink();
        return IgnorePointer(
          child: Container(
            color: Colors.transparent,
            child: Opacity(
              opacity: controller.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      (isGodPack ? AppTheme.gold : color).withOpacity(0.9),
                      (isGodPack ? AppTheme.gold : color).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RevealGrid extends StatelessWidget {
  const _RevealGrid({required this.cards, required this.isNew, required this.revealed, required this.isGodPack});
  final List<CityCard> cards;
  final List<bool> isNew;
  final Set<int> revealed;
  final bool isGodPack;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isGodPack)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _GodPackBanner(visible: revealed.isNotEmpty),
          ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 18,
          children: List.generate(cards.length, (i) {
            return _FlipCardSlot(card: cards[i], isNew: isNew[i], revealed: revealed.contains(i));
          }),
        ),
      ],
    );
  }
}

class _GodPackBanner extends StatelessWidget {
  const _GodPackBanner({required this.visible});
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFD86B), Color(0xFFFF3CAC), Color(0xFF7C3AED)]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Text(
          '✦ GOD PACK — 0.1% ✦',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.6),
        ),
      ),
    );
  }
}

class _FlipCardSlot extends StatelessWidget {
  const _FlipCardSlot({required this.card, required this.isNew, required this.revealed});
  final CityCard card;
  final bool isNew;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: revealed ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, t, _) {
        final showFront = t > 0.5;
        final angle = (1 - t) * pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..setEntry(3, 2, 0.0015)..rotateY(angle),
          child: showFront
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CityCardWidget(card: card, width: 130, revealLocked: true),
                      if (isNew)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(10)),
                            child: const Text('NUOVA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black)),
                          ),
                        ),
                    ],
                  ),
                )
              : const _CardBack(width: 130),
        );
      },
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 1.42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.065),
        gradient: const LinearGradient(colors: [Color(0xFF1E2530), Color(0xFF0B0E14)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: AppTheme.gold.withOpacity(0.35)),
      ),
      child: Center(child: UrbisLogo(size: width * 0.4)),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.result, required this.onAgain, required this.onDone});
  final PackResult result;
  final VoidCallback onAgain;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            result.newUnlocks > 0 ? '${result.newUnlocks} nuove carte!' : 'Busta completata',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 18,
            children: List.generate(result.cards.length, (i) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  CityCardWidget(card: result.cards[i], width: 130, revealLocked: true),
                  if (result.isNew[i])
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(10)),
                        child: const Text('NUOVA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black)),
                      ),
                    ),
                ],
              );
            }),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(onPressed: onDone, child: const Text('Torna alla collezione')),
              const SizedBox(width: 12),
              FilledButton(onPressed: onAgain, child: const Text('Apri un\'altra busta')),
            ],
          ),
        ],
      ),
    );
  }
}

class _OddsSheet extends StatelessWidget {
  const _OddsSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Probabilità di drop', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              'Ogni busta contiene 5 carte estratte in modo indipendente con queste percentuali fisse.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            for (final r in Rarity.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    RarityBadge(rarity: r, dense: true),
                    const Spacer(),
                    Text('${r.dropRatePercent}%', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            const Divider(color: AppTheme.surfaceAlt, height: 28),
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.gold, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'God Pack: 0.1% di possibilità che l\'intera busta diventi garantita Leggendaria/Segreta.',
                    style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.95), fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
