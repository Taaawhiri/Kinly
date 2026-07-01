import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/biometric_lock_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/onboarding/onboarding_intro_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/root_shell.dart';
import 'screens/splash_screen.dart';
import 'services/biometric_lock_service.dart';
import 'services/onboarding_settings.dart';
import 'services/supabase_client.dart';
import 'state/app_state.dart';
import 'state/theme_controller.dart';
import 'theme/app_theme.dart';

/// Chiave globale del Navigator: serve ai servizi che devono aprire una
/// schermata senza avere un BuildContext (es. rilevamento incidenti).
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Tutto l'avvio è in una zona protetta: se una qualunque inizializzazione
  // lancia un errore non previsto prima che la UI sia disegnata, lo
  // registriamo invece di far morire il processo in silenzio (schermata che
  // si chiude subito all'apertura).
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      // Configurato via android/app/google-services.json: su piattaforme
      // senza quel file (es. web/desktop in sviluppo) fallisce in modo
      // innocuo e l'app parte comunque, solo senza notifiche push.
      await Firebase.initializeApp();
    } catch (_) {
      // Vedi PushNotificationService.initialize per lo stesso principio.
    }

    try {
      await initSupabase();
    } catch (_) {
      // Senza Supabase l'app mostrerà la schermata di accesso e fallirà lì
      // in modo visibile, invece di morire silenziosamente all'avvio.
    }
    await ThemeController.instance.load();
    runApp(const KinlyApp());
  }, (error, stack) {
    if (!kDebugMode) {
      debugPrint('Errore non gestito: $error\n$stack');
    }
  });
}

class KinlyApp extends StatelessWidget {
  const KinlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Kinly',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.themeMode,
          // AppTheme.xxx sono colori statici usati ovunque nell'app (non
          // sempre tramite Theme.of(context)): li aggiorniamo qui in base al
          // tema effettivamente risolto, e forziamo la ricostruzione di
          // tutto l'albero sottostante (KeyedSubtree con chiave diversa)
          // così anche i widget "const" più in profondità li rileggono.
          builder: (context, child) {
            final brightness = Theme.of(context).brightness;
            AppTheme.isDark = brightness == Brightness.dark;
            return KeyedSubtree(key: ValueKey(brightness), child: child!);
          },
          home: const AuthGate(),
        );
      },
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

  /// null finché non sappiamo ancora se l'accesso biometrico è attivo su
  /// questo dispositivo; true/false una volta controllato.
  bool? _biometricLockActive;

  /// null finché non sappiamo ancora se l'onboarding introduttivo è già
  /// stato visto su questo dispositivo.
  bool? _onboardingSeen;

  @override
  void initState() {
    super.initState();
    if (_session != null) {
      unawaited(AppState.instance.initialize());
      unawaited(_checkBiometricLock());
      unawaited(_checkOnboarding());
    }
    _authSub = supabase.auth.onAuthStateChange.listen((state) {
      final wasSignedIn = _session != null;
      setState(() => _session = state.session);
      if (state.session != null && !wasSignedIn) {
        unawaited(AppState.instance.initialize());
        unawaited(_checkBiometricLock());
        unawaited(_checkOnboarding());
      }
    });
  }

  Future<void> _checkBiometricLock() async {
    final enabled = await BiometricLockService.instance.isEnabled();
    if (mounted) setState(() => _biometricLockActive = enabled);
  }

  Future<void> _checkOnboarding() async {
    final seen = await OnboardingSettings.instance.hasSeenIntro();
    if (mounted) setState(() => _onboardingSeen = seen);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) return const SignInScreen();
    if (_biometricLockActive == null) return const SplashScreen();
    if (_biometricLockActive == true) {
      return BiometricLockScreen(onUnlocked: () => setState(() => _biometricLockActive = false));
    }

    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final state = AppState.instance;
        if (!state.hasLoadedOnce) return const SplashScreen();
        if (!state.hasCircles) {
          if (_onboardingSeen == null) return const SplashScreen();
          if (_onboardingSeen == false) {
            return OnboardingIntroScreen(onDone: () => setState(() => _onboardingSeen = true));
          }
          return const WelcomeScreen();
        }
        return const RootShell();
      },
    );
  }
}
