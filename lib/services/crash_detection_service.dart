import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/app_state.dart';

/// Rilevamento incidenti (Kinly+, opt-in): mentre risulti "in auto" (dalla
/// velocità GPS già tracciata), l'accelerometro cerca un urto violento; se
/// lo trova, l'app mostra un conto alla rovescia e — se non annulli — attiva
/// l'SOS da sola.
///
/// La soglia è volutamente conservativa (≈5g) per ridurre i falsi allarmi da
/// telefono che cade o buche: meglio mancare un urto lieve che far partire
/// SOS a raffica. Funziona mentre l'app è attiva (in primo piano, o in
/// background col tracciamento attivo che tiene vivo il processo).
class CrashDetectionService {
  CrashDetectionService._();
  static final instance = CrashDetectionService._();

  static const _prefKey = 'crash_detection_enabled';

  /// Accelerazione totale (m/s²) oltre cui si considera un urto: ~5g.
  static const _impactThreshold = 49.0;

  /// Velocità minima recente (km/h) perché un urto conti come possibile
  /// incidente stradale e non come telefono caduto dal tavolo.
  static const _minRecentSpeedKmh = 30.0;

  /// Dopo un rilevamento, ignora l'accelerometro per un po': l'urto genera
  /// una raffica di letture sopra soglia, non serve segnalarle tutte.
  static const _cooldown = Duration(minutes: 2);

  StreamSubscription<AccelerometerEvent>? _sub;
  DateTime? _lastTriggerAt;

  /// Chiamato quando viene rilevato un possibile incidente: la UI mostra il
  /// conto alla rovescia e decide se attivare l'SOS.
  void Function()? onPossibleCrash;

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    if (value) {
      await start();
    } else {
      await stop();
    }
  }

  Future<void> start() async {
    if (_sub != null) return;
    if (!await isEnabled()) return;
    _sub = accelerometerEventStream().listen(_onEvent, onError: (_) {});
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _onEvent(AccelerometerEvent event) {
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    if (magnitude < _impactThreshold) return;

    final now = DateTime.now();
    if (_lastTriggerAt != null && now.difference(_lastTriggerAt!) < _cooldown) return;

    // L'urto conta solo se poco fa stavi davvero andando a velocità da
    // strada: usa l'ultima velocità nota già tracciata dal LocationTracker.
    final speed = AppState.instance.me.speedKmh;
    if (speed == null || speed < _minRecentSpeedKmh) return;

    _lastTriggerAt = now;
    onPossibleCrash?.call();
  }
}
