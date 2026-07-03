import 'dart:async';
import 'dart:io';
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
  void Function(String zoneId)? _onArrivalConfirmed;

  static const _channel = AndroidNotificationChannel(
    'kinly_default',
    'Kinly',
    description: 'Avvisi importanti: SOS, aree sicure, richieste di posizione.',
    importance: Importance.high,
  );

  /// Canale separato per il "ping d'arrivo" (vedi [showArrivalPrompt]): una
  /// notifica con un pulsante d'azione, non un semplice avviso.
  static const _arrivalChannel = AndroidNotificationChannel(
    'kinly_arrival',
    'Ping d\'arrivo',
    description: 'Notifica per avvisare rapidamente la cerchia quando arrivi in un\'area sicura.',
    importance: Importance.high,
  );

  static const _arrivalActionPrefix = 'confirm_arrival_';

  /// Non fallisce mai: su piattaforme dove Firebase non è configurato
  /// (es. web/desktop in fase di sviluppo) semplicemente non fa nulla,
  /// invece di bloccare l'avvio dell'app.
  ///
  /// [onArrivalConfirmed] è chiamato quando l'utente tocca "Sono arrivato"
  /// sulla notifica del ping d'arrivo (vedi [showArrivalPrompt]), sia ad
  /// app già aperta sia se l'ha aperta apposta toccando la notifica.
  Future<void> initialize({void Function(String zoneId)? onArrivalConfirmed}) async {
    _onArrivalConfirmed = onArrivalConfirmed;
    if (_initialized) return;
    try {
      await _localNotifications.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_arrivalChannel);

      // Se l'app era chiusa ed è stata aperta apposta toccando la notifica
      // del ping d'arrivo, il tap arriva qui invece che nella callback
      // sopra (che si registra "in tempo" solo se l'app era già in vita).
      final launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
      final launchResponse = launchDetails?.notificationResponse;
      if (launchDetails?.didNotificationLaunchApp == true && launchResponse != null) {
        _handleNotificationResponse(launchResponse);
      }

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

  void _handleNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    if (actionId == null || !actionId.startsWith(_arrivalActionPrefix)) return;
    final zoneId = actionId.substring(_arrivalActionPrefix.length);
    if (zoneId.isNotEmpty) _onArrivalConfirmed?.call(zoneId);
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

  /// Notifica con il pulsante "Sono arrivato" (solo Android, per ora):
  /// mostrata da LocationTracker quando si entra in un'area sicura, oltre
  /// alla registrazione automatica dell'ingresso già esistente. Un modo
  /// rapido e volontario di avvisare la cerchia con un messaggio, invece
  /// di affidarsi solo all'evento silenzioso.
  ///
  /// showsUserInterface: true perché la callback qui è quella "in
  /// primo piano" (onDidReceiveNotificationResponse): con l'app
  /// completamente chiusa, un'azione senza interfaccia richiederebbe un
  /// isolate Dart separato (onDidReceiveBackgroundNotificationResponse,
  /// con re-inizializzazione di Supabase al suo interno) non implementato
  /// qui per prudenza, non essendo testabile in questo ambiente di
  /// sviluppo. Toccare l'azione apre quindi l'app (il tempo di inviare il
  /// messaggio), ma non serve navigare o toccare altro al suo interno.
  Future<void> showArrivalPrompt({required String zoneId, required String zoneLabel, required String actionLabel}) async {
    if (!Platform.isAndroid) return;
    try {
      await _localNotifications.show(
        id: zoneId.hashCode,
        title: zoneLabel,
        body: actionLabel,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _arrivalChannel.id,
            _arrivalChannel.name,
            actions: [AndroidNotificationAction('$_arrivalActionPrefix$zoneId', actionLabel, showsUserInterface: true)],
          ),
        ),
      );
    } catch (_) {
      // Mai bloccare il tracciamento per una notifica facoltativa.
    }
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
