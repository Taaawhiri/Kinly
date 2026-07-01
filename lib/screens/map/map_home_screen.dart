import 'package:flutter/material.dart';
import '../../models/person.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/circle_chip.dart';
import '../../widgets/map_pin.dart';
import '../../widgets/person_list_tile.dart';
import '../../widgets/stylized_map_painter.dart';
import '../people/person_detail_screen.dart';

class MapHomeScreen extends StatelessWidget {
  const MapHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final people = state.visiblePeople();

        return Scaffold(
          body: Column(
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const StylizedMapBackground(),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth, h = constraints.maxHeight;
                        return Stack(
                          children: [
                            for (final p in people)
                              if (p.isSharingWithMe)
                                _positioned(p, w, h, context),
                            _positioned(state.me, w, h, context),
                          ],
                        );
                      },
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            const CerchiaLogo(size: 34),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    CircleChip(
                                      label: 'Tutte',
                                      isSelected: state.activeCircleId == null,
                                      onTap: () => state.setActiveCircle(null),
                                    ),
                                    const SizedBox(width: 8),
                                    for (final c in state.circles) ...[
                                      CircleChip(
                                        label: c.name,
                                        icon: c.icon,
                                        color: c.color,
                                        isSelected: state.activeCircleId == c.id,
                                        onTap: () => state.setActiveCircle(c.id),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Row(
                          children: [
                            const Text('La tua cerchia', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                            const Spacer(),
                            Text('${people.length} persone', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          itemCount: people.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final p = people[i];
                            return PersonListTile(
                              person: p,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: p.id)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _positioned(Person p, double w, double h, BuildContext context) {
    const pinSize = 46.0;
    return Positioned(
      left: w * p.mapX - pinSize * 0.9,
      top: h * p.mapY - pinSize * 1.5,
      child: MapPin(
        person: p,
        size: pinSize,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: p.id)),
        ),
      ),
    );
  }
}
