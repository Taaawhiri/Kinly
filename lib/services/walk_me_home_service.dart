import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/help_request.dart';
import '../state/app_state.dart';

/// "Accompagnami": avvii una sessione a tempo ("torno a casa in 20 minuti");
/// se allo scadere non hai confermato l'arrivo — a mano, o automaticamente
/// entrando in un'area sicura di tipo Casa — l'app manda da sola una
/// richiesta di aiuto alla cerchia con la tua posizione.
///
/// Limite onesto: il timer vive nell'app. Se il sistema la chiude del tutto
/// prima della scadenza, l'avviso automatico non parte (alla riapertura la
/// sessione scaduta viene rilevata e segnalata). La scadenza è salvata su
/// disco proprio per sopravvivere a un riavvio dell'app.
class WalkMeHomeService extends ChangeNotifier {
  WalkMeHomeService._();
  static final instance = WalkMeHomeService._();

  static const _prefEndKey = 'walk_me_home_end';
  static const _prefCircleKey = 'walk_me_home_circle';

  DateTime? _endsAt;
  String? _circleId;
  Timer? _timer;
  bool _triggering = false;
  // Vero se l'utente conferma l'arrivo MENTRE _onExpired è già partito e sta
  // aspettando la posizione: senza, una conferma in quella finestra veniva
  // ignorata e partiva comunque il falso allarme alla cerchia.
  bool _arrivalConfirmed = false;

  bool get isActive => _endsAt != null && _endsAt!.isAfter(DateTime.now());
  DateTime? get endsAt => _endsAt;
  Duration get remaining => _endsAt == null ? Duration.zero : _endsAt!.difference(DateTime.now());

  /// Da chiamare all'avvio dell'app: riprende una sessione ancora in corso,
  /// o segnala subito se è scaduta mentre l'app era chiusa.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final endMillis = prefs.getInt(_prefEndKey);
    if (endMillis == null) return;
    _endsAt = DateTime.fromMillisecondsSinceEpoch(endMillis);
    _circleId = prefs.getString(_prefCircleKey);
    if (_endsAt!.isBefore(DateTime.now())) {
      await _onExpired();
    } else {
      _armTimer();
      notifyListeners();
    }
  }

  Future<void> start({required Duration duration, required String circleId}) async {
    _endsAt = DateTime.now().add(duration);
    _circleId = circleId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefEndKey, _endsAt!.millisecondsSinceEpoch);
    await prefs.setString(_prefCircleKey, circleId);
    _armTimer();
    notifyListeners();
  }

  /// Conferma l'arrivo (manuale o automatica entrando in area Casa): la
  /// sessione termina senza avvisare nessuno.
  Future<void> confirmArrival() async {
    _arrivalConfirmed = true;
    await _clear();
    notifyListeners();
  }

  void _armTimer() {
    _timer?.cancel();
    final delay = _endsAt!.difference(DateTime.now());
    _timer = Timer(delay.isNegative ? Duration.zero : delay, () => unawaited(_onExpired()));
  }

  Future<void> _onExpired() async {
    if (_triggering) return;
    _triggering = true;
    _arrivalConfirmed = false;
    final circleId = _circleId;
    await _clear();
    try {
      double lat = 0, lng = 0;
      try {
        final position = await Geolocator.getCurrentPosition();
        lat = position.latitude;
        lng = position.longitude;
      } catch (_) {
        final me = AppState.instance.me;
        lat = me.lat ?? 0;
        lng = me.lng ?? 0;
      }
      // Se l'utente ha confermato l'arrivo mentre recuperavamo la posizione,
      // niente falso allarme.
      if (_arrivalConfirmed) return;
      final targetCircle = circleId ?? (AppState.instance.circles.isNotEmpty ? AppState.instance.circles.first.id : null);
      if (targetCircle != null) {
        await AppState.instance.triggerHelpRequest(
          circleId: targetCircle,
          reason: HelpRequestReason.other,
          note: 'Accompagnami: non ha confermato l\'arrivo entro il tempo previsto.',
          lat: lat,
          lng: lng,
        );
      }
    } catch (_) {
      // Se anche l'avviso fallisce (es. offline) non c'è altro da fare qui.
    } finally {
      _triggering = false;
      notifyListeners();
    }
  }

  Future<void> _clear() async {
    _timer?.cancel();
    _timer = null;
    _endsAt = null;
    _circleId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefEndKey);
    await prefs.remove(_prefCircleKey);
  }
}
