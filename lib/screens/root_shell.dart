import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../state/simple_mode_controller.dart';
import 'map/map_home_screen.dart';
import 'map/simple_home_screen.dart';
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

  static const _tabCount = 4;

  /// La prima scheda è la home a mappa, oppure la Modalità Rapida se
  /// attivata da Profilo → Accessibilità. Il resto è invariato. RootShell
  /// viene ricostruita quando la preferenza cambia (SimpleModeController è
  /// nel ListenableBuilder in cima all'app), quindi qui basta leggerla.
  List<Widget> get _screens => [
        SimpleModeController.instance.enabled ? const SimpleHomeScreen() : const MapHomeScreen(),
        const CirclesScreen(),
        const RequestsScreen(),
        const ProfileScreen(),
      ];

  /// Un Navigator indipendente per ciascuna scheda, usato solo nel layout
  /// largo (desktop/tablet): senza, aprire un dettaglio dentro una scheda
  /// (es. "Aree sicure" o "Punto d'incontro" da Cerchie) sostituiva l'intera
  /// pagina con Navigator.push, facendo sparire anche la barra laterale.
  /// Con un Navigator a parte per scheda, quel push resta confinato dentro
  /// il proprio riquadro e la barra laterale resta sempre visibile.
  late final _tabNavigatorKeys = List.generate(_tabCount, (_) => GlobalKey<NavigatorState>());

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
                  final pending = AppState.instance.pendingRequestsBadgeCount;
                  final l10n = AppLocalizations.of(context)!;
                  return NavigationBar(
                    selectedIndex: _index,
                    onDestinationSelected: (i) => setState(() => _index = i),
                    destinations: [
                      NavigationDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map_rounded), label: l10n.navMap),
                      NavigationDestination(icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups_rounded), label: l10n.navCircles),
                      NavigationDestination(
                        icon: pending > 0 ? Badge(label: Text('$pending'), child: const Icon(Icons.mail_outline_rounded)) : const Icon(Icons.mail_outline_rounded),
                        selectedIcon: pending > 0 ? Badge(label: Text('$pending'), child: const Icon(Icons.mail_rounded)) : const Icon(Icons.mail_rounded),
                        label: l10n.navRequests,
                      ),
                      NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded), label: l10n.navProfile),
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
        final pending = AppState.instance.pendingRequestsBadgeCount;
        final l10n = AppLocalizations.of(context)!;
        return Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) {
                if (i == _index) {
                  // Ritoccare la scheda già attiva torna alla sua pagina
                  // principale: utile visto che la barra resta sempre lì,
                  // diventa un modo naturale per "risalire" da un dettaglio.
                  _tabNavigatorKeys[i].currentState?.popUntil((r) => r.isFirst);
                } else {
                  setState(() => _index = i);
                }
              },
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map_rounded), label: Text(l10n.navMap)),
                NavigationRailDestination(icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups_rounded), label: Text(l10n.navCircles)),
                NavigationRailDestination(
                  icon: pending > 0 ? Badge(label: Text('$pending'), child: const Icon(Icons.mail_outline_rounded)) : const Icon(Icons.mail_outline_rounded),
                  selectedIcon: pending > 0 ? Badge(label: Text('$pending'), child: const Icon(Icons.mail_rounded)) : const Icon(Icons.mail_rounded),
                  label: Text(l10n.navRequests),
                ),
                NavigationRailDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded), label: Text(l10n.navProfile)),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: [
                  for (var i = 0; i < _screens.length; i++)
                    Navigator(
                      key: _tabNavigatorKeys[i],
                      onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => _screens[i]),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
