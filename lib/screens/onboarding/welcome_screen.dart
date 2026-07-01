import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import 'create_circle_screen.dart';
import 'join_circle_screen.dart';

/// Primo schermo che si vede: niente registrazione pubblica, si entra solo
/// con un invito oppure creando una nuova cerchia.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: Column(
            children: [
              const Spacer(),
              const CerchiaLogo(size: 108),
              const SizedBox(height: 28),
              const Text(
                'Cerchia',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.5),
              ),
              const SizedBox(height: 10),
              const Text(
                'La tua posizione, solo con chi conta davvero.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15.5, color: AppTheme.textSecondary, height: 1.4),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateCircleScreen()),
                ),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                child: const Text('Crea la tua cerchia'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JoinCircleScreen()),
                ),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                child: const Text('Ho un codice di invito'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 15, color: AppTheme.textSecondary.withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Accesso solo su invito. Nessuno vede la tua posizione senza il tuo permesso.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withOpacity(0.85), height: 1.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
