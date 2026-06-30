import 'package:flutter/material.dart';
import '../models/city_card.dart';
import '../models/rarity.dart';
import '../state/collection_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/city_card_widget.dart';
import '../widgets/rarity_badge.dart';
import 'card_detail_screen.dart';
import 'pack_opening_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Rarity? _filter;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CollectionState.instance,
      builder: (context, _) => _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final all = CollectionState.instance.cards;
    final unlockedCount = CollectionState.instance.unlockedCount;
    final visible = _filter == null ? all : all.where((c) => c.rarity == _filter).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              unlocked: unlockedCount,
              total: all.length,
              onOpenPack: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PackOpeningScreen()),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _FilterRow(selected: _filter, onSelected: (r) => setState(() => _filter = r))),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1 / 1.42,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _GridCard(card: visible[i]),
                childCount: visible.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.unlocked, required this.total, required this.onOpenPack});
  final int unlocked;
  final int total;
  final VoidCallback onOpenPack;

  @override
  Widget build(BuildContext context) {
    final progress = unlocked / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const UrbisLogo(size: 44),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'URBIS',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      '100 Città del Mondo · La tua collezione',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onOpenPack,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.style, color: AppTheme.gold, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Apri busta',
                        style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: AppTheme.surfaceAlt,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.gold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$unlocked/$total',
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelected});
  final Rarity? selected;
  final ValueChanged<Rarity?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(label: 'Tutte', isSelected: selected == null, onTap: () => onSelected(null)),
          const SizedBox(width: 8),
          for (final r in Rarity.values) ...[
            _Chip(
              label: r.label,
              color: r.accentColor,
              isSelected: selected == r,
              onTap: () => onSelected(r),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.isSelected, required this.onTap, this.color});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.gold;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? c.withOpacity(0.22) : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? c : AppTheme.surfaceAlt, width: 1.4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? c : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({required this.card});
  final CityCard card;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
      ),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => CityCardWidget(card: card, width: constraints.maxWidth),
            ),
          ),
          const SizedBox(height: 6),
          if (card.unlocked)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    card.city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            )
          else
            RarityBadge(rarity: card.rarity, dense: true),
        ],
      ),
    );
  }
}
