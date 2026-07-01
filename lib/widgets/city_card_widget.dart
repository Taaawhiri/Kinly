import 'package:flutter/material.dart';
import '../models/city_card.dart';
import '../models/rarity.dart';
import '../theme/app_theme.dart';
import 'foil_overlay.dart';
import 'full_art_scenes.dart';
import 'rarity_badge.dart';
import 'skyline_painter.dart';

/// Il widget centrale dell'app: rende una carta collezionabile in stile TCG.
/// Lo stesso widget viene riusato ovunque (griglia collezione, vetrina
/// rarità, dettaglio) per garantire coerenza visiva.
class CityCardWidget extends StatelessWidget {
  const CityCardWidget({
    super.key,
    required this.card,
    this.width = 220,
    this.revealLocked = false,
  });

  final CityCard card;
  final double width;

  /// Se true, ignora lo stato "bloccato" della carta (usato nella vetrina
  /// delle rarità, dove vogliamo sempre mostrare l'arte completa).
  final bool revealLocked;

  bool get _isLocked => !card.unlocked && !revealLocked;

  @override
  Widget build(BuildContext context) {
    final rarity = card.rarity;
    final height = width * 1.42;
    final radius = BorderRadius.circular(width * 0.065);

    Widget frame = Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(width * (rarity.index >= Rarity.leggendaria.index ? 0.05 : 0.035)),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          colors: rarity.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.04),
        child: Container(
          color: AppTheme.surface,
          child: _isLocked ? _LockedFace(card: card, width: width) : _CardFace(card: card, width: width, height: height),
        ),
      ),
    );

    frame = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          if (rarity.hasShine)
            BoxShadow(
              color: rarity.accentColor.withOpacity(0.55),
              blurRadius: width * 0.16,
              spreadRadius: width * 0.004,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: frame,
    );

    if (rarity.isAnimatedFoil && !_isLocked) {
      frame = FoilOverlay(borderRadius: radius, child: frame);
    }

    return frame;
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.card, required this.width, required this.height});
  final CityCard card;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final rarity = card.rarity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(width * 0.05, width * 0.04, width * 0.04, width * 0.02),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  card.city,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: width * 0.082,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    height: 1.0,
                  ),
                ),
              ),
              SizedBox(width: width * 0.02),
              Flexible(child: RarityBadge(rarity: rarity, dense: width < 200, useSigla: width < 200)),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.045),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(width * 0.03),
              child: _ArtPanel(card: card, width: width),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(width * 0.045),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.public, size: width * 0.045, color: AppTheme.textSecondary),
                  SizedBox(width: width * 0.014),
                  Expanded(
                    child: Text(
                      '${card.country} · ${card.continent}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: width * 0.04, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
              SizedBox(height: width * 0.018),
              Row(
                children: [
                  Flexible(child: _StatChip(icon: Icons.groups, label: card.populationFormatted, width: width)),
                  SizedBox(width: width * 0.02),
                  Flexible(child: _StatChip(icon: Icons.history_edu, label: card.foundedYearFormatted, width: width)),
                ],
              ),
              SizedBox(height: width * 0.03),
              Text(
                card.flavorText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: width * 0.0375,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textSecondary,
                  height: 1.25,
                ),
              ),
              SizedBox(height: width * 0.02),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  card.cardNumber,
                  style: TextStyle(
                    fontSize: width * 0.034,
                    color: rarity.accentColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArtPanel extends StatelessWidget {
  const _ArtPanel({required this.card, required this.width});
  final CityCard card;
  final double width;

  @override
  Widget build(BuildContext context) {
    final rarity = card.rarity;
    final colors = rarity.gradientColors;
    final seed = card.city.hashCode;
    final fullArt = fullArtPainterFor(card.city);

    if (fullArt != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: fullArt, child: const SizedBox.expand()),
          if (rarity.hasShine)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.16),
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.35, 0.5, 0.65],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.first, colors[colors.length ~/ 2]],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          right: width * 0.08,
          top: width * 0.08,
          child: Container(
            width: width * 0.22,
            height: width * 0.22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.85),
              boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: width * 0.08)],
            ),
          ),
        ),
        Opacity(
          opacity: 0.16,
          child: Center(
            child: Icon(rarity.icon, size: width * 0.5, color: Colors.white),
          ),
        ),
        CustomPaint(
          painter: SkylinePainter(
            seed: seed,
            silhouetteColor: const Color(0xFF11151D),
            windowColor: rarity.gradientColors.last,
            landmark: landmarkForSeed(seed),
          ),
          child: const SizedBox.expand(),
        ),
        if (rarity.hasShine)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.22),
                      Colors.white.withOpacity(0.0),
                    ],
                    stops: const [0.35, 0.5, 0.65],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.width});
  final IconData icon;
  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: width * 0.024, vertical: width * 0.012),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: width * 0.04, color: AppTheme.textSecondary),
          SizedBox(width: width * 0.012),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: width * 0.032, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedFace extends StatelessWidget {
  const _LockedFace({required this.card, required this.width});
  final CityCard card;
  final double width;

  @override
  Widget build(BuildContext context) {
    final rarity = card.rarity;
    return Container(
      color: AppTheme.surfaceAlt,
      padding: EdgeInsets.all(width * 0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: width * 0.22, color: AppTheme.textSecondary.withOpacity(0.6)),
          SizedBox(height: width * 0.05),
          Text(
            '???',
            style: TextStyle(fontSize: width * 0.1, fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
          ),
          SizedBox(height: width * 0.03),
          RarityBadge(rarity: rarity, dense: width < 200),
          SizedBox(height: width * 0.05),
          Text(
            'Carta non ancora sbloccata',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: width * 0.034, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
