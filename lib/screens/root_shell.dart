import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'map/map_home_screen.dart';
import 'circles/circles_screen.dart';
import 'requests/requests_screen.dart';
import 'profile/profile_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

/// Sopra questa larghezza usiamo una barra laterale invece di quella in
/// basso: su schermi larghi (desktop/tablet orizzontale) una bottom bar
/// pensata per il pollice è solo spazio sprecato in fondo allo schermo.
const _wideLayoutBreakpoint = 900.0;

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _screens = [
    MapHomeScreen(),
    CirclesScreen(),
    RequestsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _wideLayoutBreakpoint;
    return PopScope(
      // Se non sei nella scheda Mappa, il tasto/gesto "indietro" ti ci
      // riporta invece di uscire subito dall'app; solo da lì un secondo
      // "indietro" chiude davvero l'app.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _index != 0) setState(() => _index = 0);
      },
      child: Scaffold(
        body: isWide ? _buildWideLayout(context) : IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: isWide
            ? null
            : ListenableBuilder(
                listenable: AppState.instance,
                builder: (context, _) {
                  final pending = AppState.instance.pendingIncoming.length;
                  return NavigationBar(
                    selectedIndex: _index,
                    onDestinationSelected: (i) => setState(() => _index = i),
                    destinations: [
                      const NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: 'Mappa'),
                      const NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: 'Cerchie'),
                      NavigationDestination(
                        icon: pending > 0 ? Badge(label: Text('$pending'), child: const Icon(Icons.mail_outline_rounded)) : const Icon(Icons.mail_outline_rounded),
                        selectedIcon: pending > 0 ? Badge(label: Text('$pending'), child: const Icon(Icons.mail_rounded)) : const Icon(Icons.mail_rounded),
                        label: 'Richieste',
                      ),
                      const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profilo'),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final pending = AppState.instance.pendingIncoming.length;
        return Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                const NavigationRailDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: Text('Mappa')),
                const NavigationRailDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: Text('Cerchie')),
                NavigationRailDestination(
                  icon: pending > 0 ? Badge(label: Text('$pending'), child: const Icon(Icons.mail_outline_rounded)) : const Icon(Icons.mail_outline_rounded),
                  selectedIcon: pending > 0 ? Badge(label: Text('$pending'), child: const Icon(Icons.mail_rounded)) : const Icon(Icons.mail_rounded),
                  label: const Text('Richieste'),
                ),
                const NavigationRailDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: Text('Profilo')),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: IndexedStack(index: _index, children: _screens)),
          ],
        );
      },
    );
  }
}
