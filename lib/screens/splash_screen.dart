import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

/// Schermata mostrata durante il primo caricamento dei dati da Supabase (o
/// in caso di errore di rete, con la possibilità di riprovare).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final error = AppState.instance.loadError;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const KinlyLogo(size: 72),
              const SizedBox(height: 24),
              if (error == null) ...[
                const CircularProgressIndicator(),
              ] else ...[
                Icon(Icons.wifi_off_rounded, size: 32, color: AppTheme.textSecondary),
                const SizedBox(height: 12),
                Text(
                  'Non riusciamo a contattare Kinly. Controlla la connessione e riprova.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5, height: 1.4),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => AppState.instance.initialize(),
                  child: const Text('Riprova'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
