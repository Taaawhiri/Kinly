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
    return PopScope(
      // Se non sei nella scheda Mappa, il tasto/gesto "indietro" ti ci
      // riporta invece di uscire subito dall'app; solo da lì un secondo
      // "indietro" chiude davvero l'app.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _index != 0) setState(() => _index = 0);
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: ListenableBuilder(
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
}
