import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/circle_chip.dart';
import '../../widgets/kinly_map.dart';
import '../../widgets/person_list_tile.dart';
import '../people/person_detail_screen.dart';

class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key});

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

const double _sheetInitialSize = 0.42;
const double _sheetMinSize = 0.14;
const double _sheetMaxSize = 0.9;

class _MapHomeScreenState extends State<MapHomeScreen> {
  final _sheetController = DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        final people = state.visiblePeople();

        return Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  KinlyMap(
                    people: [state.me, ...people.where((p) => p.isSharingWithMe)],
                    onPersonTap: (personId) => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PersonDetailScreen(personId: personId)),
                    ),
                  ),
                  // Align forza dei vincoli "loose" sul figlio: senza, lo
                  // Stack (fit: expand) costringerebbe il CustomPaint del
                  // logo a riempire tutto lo schermo (e a "rubare" i gesti
                  // di pan/zoom destinati alla mappa sottostante).
                  const SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 0, 0),
                        child: KinlyLogo(size: 34),
                      ),
                    ),
                  ),
                  // La barra delle cerchie segue il bordo superiore del
                  // pannello: quando lo trascini giù, scende anche lei,
                  // invece di restare ferma in mezzo alla mappa.
                  AnimatedBuilder(
                    animation: _sheetController,
                    builder: (context, child) {
                      final extent = _sheetController.isAttached ? _sheetController.size : _sheetInitialSize;
                      final sheetTop = constraints.maxHeight * (1 - extent);
                      return Positioned(
                        left: 0,
                        right: 0,
                        top: sheetTop - 52,
                        child: child!,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  ),
                  DraggableScrollableSheet(
                    controller: _sheetController,
                    initialChildSize: _sheetInitialSize,
                    minChildSize: _sheetMinSize,
                    maxChildSize: _sheetMaxSize,
                    snap: true,
                    snapSizes: const [_sheetMinSize, _sheetInitialSize, _sheetMaxSize],
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
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
                                  Text('La tua cerchia', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                                  const Spacer(),
                                  Text('${people.length} persone', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                controller: scrollController,
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
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
