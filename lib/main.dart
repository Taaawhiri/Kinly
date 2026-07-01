import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/root_shell.dart';
import 'screens/splash_screen.dart';
import 'services/supabase_client.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const KinlyApp());
}

class KinlyApp extends StatelessWidget {
  const KinlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kinly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

/// Radice della navigazione: mostra l'accesso, il caricamento dei dati o
/// l'app vera e propria a seconda dello stato di autenticazione. Reagisce ai
/// cambi di sessione di Supabase (login/logout) e ai cambi di AppState
/// (dati caricati, cerchie create) senza bisogno di route dedicate: le
/// schermate figlie tornano semplicemente in cima allo stack di navigazione
/// quando serve, lasciando che sia questo widget a decidere cosa mostrare.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Session? _session = supabase.auth.currentSession;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    if (_session != null) {
      unawaited(AppState.instance.initialize());
    }
    _authSub = supabase.auth.onAuthStateChange.listen((state) {
      final wasSignedIn = _session != null;
      setState(() => _session = state.session);
      if (state.session != null && !wasSignedIn) {
        unawaited(AppState.instance.initialize());
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) return const SignInScreen();

    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        if (!state.hasLoadedOnce) return const SplashScreen();
        if (!state.hasCircles) return const WelcomeScreen();
        return const RootShell();
      },
    );
  }
}
