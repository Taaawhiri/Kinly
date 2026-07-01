import 'package:flutter/material.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/root_shell.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CerchiaApp());
}

class CerchiaApp extends StatelessWidget {
  const CerchiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cerchia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppState.instance.hasOnboarded ? const RootShell() : const WelcomeScreen(),
    );
  }
}
