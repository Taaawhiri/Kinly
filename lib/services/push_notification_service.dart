import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'kinly_repository.dart';

/// Notifiche push reali (SOS, aree sicure, richieste di posizione) via
/// Firebase Cloud Messaging. L'invio effettivo parte da una Edge Function
/// Supabase quando succede qualcosa (vedi supabase/functions/send-push):
/// qui ci occupiamo solo di registrare il token di questo dispositivo e di
/// mostrare la notifica quando arriva mentre l'app è in primo piano (in
/// background/chiusa ci pensa direttamente il sistema operativo).
class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  String? _lastToken;
  bool _initialized = false;

  static const _channel = AndroidNotificationChannel(
    'kinly_default',
    'Kinly',
    description: 'Avvisi importanti: SOS, aree sicure, richieste di posizione.',
    importance: Importance.high,
  );

  /// Non fallisce mai: su piattaforme dove Firebase non è configurato
  /// (es. web/desktop in fase di sviluppo) semplicemente non fa nulla,
  /// invece di bloccare l'avvio dell'app.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _localNotifications.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        _lastToken = token;
        unawaited(KinlyRepository.instance.upsertDeviceToken(token));
      });

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        _lastToken = token;
        await KinlyRepository.instance.upsertDeviceToken(token);
      }
      _initialized = true;
    } catch (_) {
      // Firebase non disponibile/configurato su questa piattaforma: l'app
      // resta comunque utilizzabile, solo senza notifiche push.
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(android: AndroidNotificationDetails(_channel.id, _channel.name)),
    );
  }

  /// Da chiamare al logout: rimuove solo il token di QUESTO dispositivo,
  /// non tutti quelli dell'account (potrebbero essercene altri su
  /// dispositivi diversi ancora collegati).
  Future<void> unregister() async {
    final token = _lastToken;
    _lastToken = null;
    _initialized = false;
    if (token == null) return;
    try {
      await KinlyRepository.instance.deleteDeviceToken(token);
    } catch (_) {
      // Va bene anche se fallisce: al prossimo accesso verrà comunque
      // sovrascritto da un nuovo token, e Firebase scarta da solo i token
      // non più validi.
    }
  }
}
