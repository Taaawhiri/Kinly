import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/rarity_showcase_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const UrbisApp());
}

class UrbisApp extends StatelessWidget {
  const UrbisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'URBIS — TCG delle Città',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    RarityShowcaseScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.collections_bookmark_outlined), selectedIcon: Icon(Icons.collections_bookmark), label: 'Collezione'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Rarità'),
        ],
      ),
    );
  }
}
