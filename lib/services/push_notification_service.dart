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
  void Function(String fromId)? _onCheckInReply;

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

  /// Canale per il ping "tutto bene?": come [_arrivalChannel], una notifica
  /// con un pulsante d'azione invece di un semplice avviso.
  static const _checkInChannel = AndroidNotificationChannel(
    'kinly_check_in',
    'Tutto bene?',
    description: 'Notifica per rispondere subito con un tocco a un ping "tutto bene?".',
    importance: Importance.high,
  );

  static const _checkInActionPrefix = 'reply_check_in_';

  /// Non fallisce mai: su piattaforme dove Firebase non è configurato
  /// (es. web/desktop in fase di sviluppo) semplicemente non fa nulla,
  /// invece di bloccare l'avvio dell'app.
  ///
  /// [onArrivalConfirmed] è chiamato quando l'utente tocca "Sono arrivato"
  /// sulla notifica del ping d'arrivo (vedi [showArrivalPrompt]), sia ad
  /// app già aperta sia se l'ha aperta apposta toccando la notifica.
  ///
  /// [onCheckInReply] è lo stesso meccanismo per il pulsante "Sto bene!"
  /// sulla notifica di un ping "tutto bene?" ricevuto (vedi
  /// [_showForegroundNotification]): riceve l'id di chi ha chiesto, per
  /// mandargli subito il ping di risposta.
  Future<void> initialize({void Function(String zoneId)? onArrivalConfirmed, void Function(String fromId)? onCheckInReply}) async {
    _onArrivalConfirmed = onArrivalConfirmed;
    _onCheckInReply = onCheckInReply;
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
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_checkInChannel);

      // Se l'app era chiusa ed è stata aperta apposta toccando la notifica
      // del ping d'arrivo, il tap arriva qui invece che nella callback
      // sopra (che si registra "in tempo" solo se l'app era già in vita).
      final launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
      final launchResponse = launchDetails?.notificationResponse;
      if (launchDetails?.didNotificationLaunchApp == true && launchResponse != null) {
        _handleNotificationResponse(launchResponse);
      }

      // Chiediamo il permesso di MOSTRARE le notifiche (Android 13+/iOS), ma
      // NON blocchiamo la registrazione del token su questo esito: il token
      // FCM è indipendente dal permesso di visualizzazione. Registrarlo
      // sempre significa che, se l'utente concede il permesso più tardi (o
      // lo aveva già concesso ma la richiesta è stata rifiutata la prima
      // volta), le push iniziano ad arrivare senza dover reinstallare o
      // riloggare — prima invece un "no" iniziale lasciava il dispositivo
      // per sempre senza token, quindi invisibile al server.
      await FirebaseMessaging.instance.requestPermission();

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

  /// Da chiamare quando l'utente concede il permesso notifiche più tardi
  /// (es. dalla schermata Privacy e sicurezza): si assicura che il token di
  /// questo dispositivo sia registrato sul server, così le push iniziano
  /// subito ad arrivare. Se l'inizializzazione non è ancora avvenuta, la fa
  /// partire ora.
  Future<void> ensureRegistered() async {
    if (!_initialized) {
      await initialize(onArrivalConfirmed: _onArrivalConfirmed, onCheckInReply: _onCheckInReply);
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        _lastToken = token;
        await KinlyRepository.instance.upsertDeviceToken(token);
      }
    } catch (_) {
      // Va bene fallire in silenzio: onTokenRefresh rimedia comunque non
      // appena il token cambia.
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    if (actionId == null) return;
    if (actionId.startsWith(_arrivalActionPrefix)) {
      final zoneId = actionId.substring(_arrivalActionPrefix.length);
      if (zoneId.isNotEmpty) _onArrivalConfirmed?.call(zoneId);
    } else if (actionId.startsWith(_checkInActionPrefix)) {
      final fromId = actionId.substring(_checkInActionPrefix.length);
      if (fromId.isNotEmpty) _onCheckInReply?.call(fromId);
    }
  }

  /// Un ping "tutto bene?" (vedi data['type'] == 'ping_check_in', allegato
  /// dalla Edge Function send-push) porta in più un pulsante "Sto bene!"
  /// per rispondere subito: funziona qui (notifica mostrata mentre l'app è
  /// aperta) con lo stesso meccanismo già usato per il ping d'arrivo.
  /// Ad app chiusa la notifica arriva come avviso normale del sistema,
  /// senza il pulsante: aprirla mostra comunque il ping ricevuto in app,
  /// da cui si può rispondere con un tocco.
  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final fromId = message.data['type'] == 'ping_check_in' ? message.data['from_id'] as String? : null;
    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: fromId != null
            ? AndroidNotificationDetails(
                _checkInChannel.id,
                _checkInChannel.name,
                actions: [AndroidNotificationAction('$_checkInActionPrefix$fromId', 'Sto bene!', showsUserInterface: true)],
              )
            : AndroidNotificationDetails(_channel.id, _channel.name),
      ),
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
