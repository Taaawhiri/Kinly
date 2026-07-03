import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'sharing_mode.dart';

/// Stato dinamico dedotto dall'ultima velocità nota: nessun sensore in più,
/// solo delle soglie sulla velocità GPS che già tracciamo. Solo due stati
/// "in movimento" (a piedi o in auto): niente riconoscimento mezzi
/// pubblici, che richiederebbe un'API di activity recognition nativa
/// separata (Android Activity Recognition / iOS Core Motion).
enum ActivityStatus { stationary, walking, driving }

extension ActivityStatusData on ActivityStatus {
  IconData get icon {
    switch (this) {
      case ActivityStatus.stationary:
        return Icons.circle;
      case ActivityStatus.walking:
        return Icons.directions_walk_rounded;
      case ActivityStatus.driving:
        return Icons.directions_car_filled_rounded;
    }
  }
}

/// Livello di abbonamento posseduto DIRETTAMENTE dal profilo (non tiene
/// conto del beneficio ereditato da un piano Family altrui: per quello vedi
/// [Person.isPremium], già "effettivo").
enum PremiumTier { none, individual, family }

extension PremiumTierData on PremiumTier {
  static PremiumTier fromDb(String? value) => switch (value) {
        'individual' => PremiumTier.individual,
        'family' => PremiumTier.family,
        _ => PremiumTier.none,
      };
}

/// Un membro della tua cerchia (o tu stesso).
class Person {
  const Person({
    required this.id,
    required this.name,
    required this.color,
    this.lat,
    this.lng,
    required this.address,
    required this.lastUpdate,
    required this.batteryPercent,
    required this.isSharingWithMe,
    required this.mode,
    this.isMe = false,
    this.isPremium = false,
    this.speedAlertKmh,
    this.isFuzzyLocation = false,
    this.speedKmh,
    this.avatarKey,
    this.photoUrl,
    this.isAdmin = false,
    this.isBetaTester = false,
    this.birthday,
    this.statusEmoji,
    this.statusText,
    this.statusExpiresAt,
    this.paymentLink,
    this.premiumTier = PremiumTier.none,
    this.phoneNumber,
    this.weeklySummaryEnabled = true,
  });

  final String id;
  final String name;
  final Color color;

  /// Coordinate reali dell'ultima posizione nota, se disponibile e visibile.
  /// Se [isFuzzyLocation] è vero, sono già arrotondate lato server.
  final double? lat;
  final double? lng;

  final String address;
  final DateTime lastUpdate;
  final int batteryPercent;

  /// True se attualmente vedi la posizione di questa persona.
  final bool isSharingWithMe;
  final SharingMode mode;
  final bool isMe;

  /// Abbonamento Kinly+ attivo.
  final bool isPremium;

  /// Soglia di velocità (km/h) oltre la quale si registra un avviso di
  /// guida (Kinly+); null se questa persona non l'ha impostata.
  final int? speedAlertKmh;

  /// True se questa persona condivide in modalità "approssimativa": [lat]/
  /// [lng] sono già arrotondati dal server, non il punto esatto.
  final bool isFuzzyLocation;

  /// Ultima velocità nota (km/h), se disponibile: usata per mostrare lo
  /// stato dinamico (fermo/a piedi/in corsa/in auto).
  final double? speedKmh;

  /// Chiave dell'avatar a tema scelto (vedi AvatarCatalog); null = iniziali.
  final String? avatarKey;

  /// Foto profilo vera caricata dall'utente: se presente ha la precedenza
  /// sull'avatar a tema/iniziali (vedi PersonAvatar). Null = nessuna foto.
  final String? photoUrl;

  /// Amministratore dell'assistenza: vede e risponde a tutti i messaggi di
  /// supporto (vedi AdminSupportInboxScreen), non solo ai propri.
  final bool isAdmin;

  /// Beta tester: vede in Privacy e sicurezza la sezione per controllare e
  /// scaricare le build più recenti pubblicate su GitHub.
  final bool isBetaTester;

  /// Data di nascita (opzionale, la sceglie l'utente): solo mese e giorno
  /// contano, per mostrare un'iconcina di compleanno nel giorno giusto.
  final DateTime? birthday;

  /// Stato personalizzato del momento (emoji + testo breve, es. "🎉" +
  /// "con gli amici"): valido solo finché [statusExpiresAt] non è passato.
  final String? statusEmoji;
  final String? statusText;
  final DateTime? statusExpiresAt;

  /// Link personale di pagamento (Satispay, PayPal.me...), usato solo per
  /// "Spese di gruppo": null se non l'ha impostato.
  final String? paymentLink;

  /// Livello di abbonamento posseduto direttamente (non l'effettivo: vedi
  /// [isPremium]). Usato solo dalla pagina Kinly+ per mostrare quale piano
  /// è davvero attivo.
  final PremiumTier premiumTier;

  /// Numero di telefono (facoltativo, lo aggiunge chi vuole): permette a chi
  /// riceve un SOS o una richiesta di aiuto di chiamare direttamente invece
  /// di vedere solo la posizione.
  final String? phoneNumber;

  /// Se ricevere la notifica push col riepilogo settimanale della cerchia.
  /// Riguarda solo [isMe]: per gli altri membri arriva com'è dal server,
  /// qui non serve mostrarlo.
  final bool weeklySummaryEnabled;

  bool get hasActiveStatus => statusEmoji != null && statusExpiresAt != null && statusExpiresAt!.isAfter(DateTime.now());

  bool get isBirthdayToday {
    final b = birthday;
    if (b == null) return false;
    final now = DateTime.now();
    return b.month == now.month && b.day == now.day;
  }

  /// Dedotto dall'ultima velocità nota: nessuna soglia se non condivide o
  /// non c'è ancora un dato di velocità. Sopra i 15 km/h si considera "in
  /// auto" (anche una corsa a piedi sostenuta resta sotto questa soglia).
  ActivityStatus get activityStatus {
    final kmh = speedKmh;
    if (kmh == null || kmh < 1) return ActivityStatus.stationary;
    if (kmh < 15) return ActivityStatus.walking;
    return ActivityStatus.driving;
  }

  bool get isBatteryLow => batteryPercent > 0 && batteryPercent <= 15;

  /// L'app manda un "battito" ogni pochi minuti anche da fermi apposta per
  /// questo (vedi LocationTracker._sendHeartbeat): se anche quello si è
  /// fermato, l'app di quella persona non sta più girando davvero (chiusa
  /// senza tracciamento in background, telefono spento, offline da un
  /// po') — non ha senso continuare a mostrarla come "in linea" solo
  /// perché la modalità di condivisione è "Automatica". La soglia è più
  /// larga dell'intervallo del battito per non sembrare offline per un
  /// singolo giro mancato per una rete lenta.
  static const _staleThreshold = Duration(minutes: 10);

  bool get isStale => DateTime.now().difference(lastUpdate) > _staleThreshold;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, min(2, parts.first.length)).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  String lastUpdateLabel(AppLocalizations l10n) {
    final diff = DateTime.now().difference(lastUpdate);
    if (diff.inMinutes < 1) return l10n.personLastUpdateNow;
    if (diff.inMinutes < 60) return l10n.personLastUpdateMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l10n.personLastUpdateHours(diff.inHours);
    return l10n.personLastUpdateDays(diff.inDays);
  }

  Person copyWith({
    double? lat,
    double? lng,
    String? address,
    DateTime? lastUpdate,
    double? speedKmh,
    bool clearSpeedKmh = false,
    bool? isSharingWithMe,
    SharingMode? mode,
    int? speedAlertKmh,
    bool clearSpeedAlertKmh = false,
    String? avatarKey,
    bool clearAvatarKey = false,
    String? photoUrl,
    bool clearPhotoUrl = false,
    DateTime? birthday,
    String? statusEmoji,
    String? statusText,
    DateTime? statusExpiresAt,
    bool clearStatus = false,
    String? paymentLink,
    String? phoneNumber,
    bool clearPhoneNumber = false,
    bool? weeklySummaryEnabled,
  }) {
    return Person(
      id: id,
      name: name,
      color: color,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      batteryPercent: batteryPercent,
      isSharingWithMe: isSharingWithMe ?? this.isSharingWithMe,
      mode: mode ?? this.mode,
      isMe: isMe,
      isPremium: isPremium,
      speedAlertKmh: clearSpeedAlertKmh ? null : (speedAlertKmh ?? this.speedAlertKmh),
      isFuzzyLocation: isFuzzyLocation,
      speedKmh: clearSpeedKmh ? null : (speedKmh ?? this.speedKmh),
      avatarKey: clearAvatarKey ? null : (avatarKey ?? this.avatarKey),
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      isAdmin: isAdmin,
      isBetaTester: isBetaTester,
      birthday: birthday ?? this.birthday,
      statusEmoji: clearStatus ? null : (statusEmoji ?? this.statusEmoji),
      statusText: clearStatus ? null : (statusText ?? this.statusText),
      statusExpiresAt: clearStatus ? null : (statusExpiresAt ?? this.statusExpiresAt),
      paymentLink: paymentLink ?? this.paymentLink,
      premiumTier: premiumTier,
      phoneNumber: clearPhoneNumber ? null : (phoneNumber ?? this.phoneNumber),
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
    );
  }
}
