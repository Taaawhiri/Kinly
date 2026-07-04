import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/circle_group.dart';
import '../models/safe_zone.dart';
import '../models/sharing_mode.dart';
import 'supabase_client.dart';

/// Sollevata quando un'operazione viene bloccata dai limiti del piano
/// gratuito (vedi il trigger `enforce_circle_limits` nello schema).
enum FreeLimitKind { tooManyCircles, circleFull, dailyMessageLimit, dailyPingLimit, dailyExpenseLimit }

class FreeLimitException implements Exception {
  const FreeLimitException(this.kind);
  final FreeLimitKind kind;
}

/// Tutte le operazioni reali su Supabase: profilo, cerchie, posizioni e
/// richieste. Le policy RLS del database (vedi supabase/schema.sql) sono la
/// vera fonte di verità su chi può vedere cosa: qui ci limitiamo a fare le
/// query, senza duplicare quella logica lato client.
class KinlyRepository {
  KinlyRepository._();
  static final instance = KinlyRepository._();

  String get _myId => supabase.auth.currentUser!.id;

  // ---------------------------------------------------------------------
  // Profilo
  // ---------------------------------------------------------------------

  /// Legge da `profiles_view` (non dalla tabella grezza): stesse colonne di
  /// `profiles`, più `effective_is_premium` calcolato lato server (tiene
  /// conto anche del beneficio ereditato dal piano Family di chi ha creato
  /// la cerchia, vedi `is_effectively_premium` nello schema).
  Future<Map<String, dynamic>> fetchMyProfile() async {
    return supabase.from('profiles_view').select().eq('id', _myId).single();
  }

  Future<List<Map<String, dynamic>>> fetchProfiles(List<String> ids) async {
    if (ids.isEmpty) return [];
    return supabase.from('profiles_view').select().inFilter('id', ids);
  }

  Future<void> updateBirthday(DateTime? birthday) async {
    await supabase.from('profiles').update({
      'birthday': birthday == null ? null : '${birthday.year.toString().padLeft(4, '0')}-${birthday.month.toString().padLeft(2, '0')}-${birthday.day.toString().padLeft(2, '0')}',
    }).eq('id', _myId);
  }

  Future<void> updatePaymentLink(String? link) async {
    await supabase.from('profiles').update({'payment_link': link}).eq('id', _myId);
  }

  Future<void> updatePhoneNumber(String? phoneNumber) async {
    await supabase.from('profiles').update({'phone_number': phoneNumber}).eq('id', _myId);
  }

  Future<void> updateWeeklySummaryEnabled(bool enabled) async {
    await supabase.from('profiles').update({'weekly_summary_enabled': enabled}).eq('id', _myId);
  }

  /// Attività della cerchia nell'ultima settimana (SOS, richieste di aiuto,
  /// ingressi in aree sicure, avvisi di velocità): vedi weekly_circle_stats
  /// nello schema. Le RLS delle tabelle sottostanti già limitano i conteggi
  /// a ciò che posso vedere.
  Future<Map<String, dynamic>> fetchWeeklyCircleStats(String circleId) async {
    final row = await supabase.rpc('weekly_circle_stats', params: {'p_circle_id': circleId}).single();
    return row;
  }

  /// Imposta il mio stato del momento: scade automaticamente a mezzanotte
  /// locale, senza bisogno di un'azione per toglierlo.
  Future<void> updateStatus({required String emoji, String? text}) async {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    await supabase.from('profiles').update({
      'status_emoji': emoji,
      'status_text': text,
      'status_expires_at': endOfDay.toUtc().toIso8601String(),
    }).eq('id', _myId);
  }

  Future<void> clearStatus() async {
    await supabase.from('profiles').update({'status_emoji': null, 'status_text': null, 'status_expires_at': null}).eq('id', _myId);
  }

  Future<void> setSharingMode(SharingMode mode) async {
    await supabase.from('profiles').update({'sharing_mode': mode.dbValue}).eq('id', _myId);
  }

  /// I miei override di modalità per cerchia (righe assenti = uso quella
  /// generale per quella cerchia).
  Future<List<Map<String, dynamic>>> fetchMyCircleSharingSettings() async {
    return supabase.from('circle_member_settings').select().eq('profile_id', _myId);
  }

  /// null rimuove l'override (torna a usare la modalità generale in quella
  /// cerchia).
  Future<void> setCircleSharingMode(String circleId, SharingMode? mode) async {
    if (mode == null) {
      await supabase.from('circle_member_settings').delete().eq('circle_id', circleId).eq('profile_id', _myId);
    } else {
      await supabase.from('circle_member_settings').upsert(
        {'circle_id': circleId, 'profile_id': _myId, 'sharing_mode': mode.dbValue},
        onConflict: 'circle_id,profile_id',
      );
    }
  }

  Future<void> updateBatteryPercent(int percent) async {
    await supabase.from('profiles').update({'battery_percent': percent}).eq('id', _myId);
  }

  /// Imposta la mia soglia di velocità (Kinly+ per chi la guarda): null
  /// disattiva gli avvisi.
  Future<void> updateSpeedAlert(int? kmh) async {
    await supabase.from('profiles').update({'speed_alert_kmh': kmh}).eq('id', _myId);
  }

  /// Chiave dell'avatar a tema scelto (vedi AvatarCatalog): null torna alle
  /// iniziali colorate.
  Future<void> updateAvatar(String? avatarKey) async {
    await supabase.from('profiles').update({'avatar_key': avatarKey}).eq('id', _myId);
  }

  /// Carica una foto profilo (già ridotta e compressa lato client, vedi
  /// image_resizer.dart) e ritorna l'URL pubblico da salvare sul profilo.
  /// Percorso fisso per utente (con upsert) invece di un nome generato ad
  /// ogni caricamento: così una foto sostituita non lascia file orfani nel
  /// bucket. Il timestamp in coda all'URL serve solo a rompere la cache del
  /// browser quando la foto cambia — il file sul server è sempre lo stesso.
  Future<String> uploadProfilePhoto(List<int> jpegBytes) async {
    final path = '$_myId/avatar.jpg';
    await supabase.storage.from('avatars').uploadBinary(
          path,
          Uint8List.fromList(jpegBytes),
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    final url = supabase.storage.from('avatars').getPublicUrl(path);
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> updatePhotoUrl(String? url) async {
    await supabase.from('profiles').update({'photo_url': url}).eq('id', _myId);
  }

  Future<void> deleteProfilePhoto() async {
    try {
      await supabase.storage.from('avatars').remove(['$_myId/avatar.jpg']);
    } catch (_) {
      // Va bene se il file non esiste già: l'importante è che dopo questa
      // chiamata non ce ne sia più uno associato al profilo.
    }
  }

  /// Orario di reperibilità (valori già convertiti in UTC, formato
  /// "HH:MM:SS"): fuori da questa finestra nessuno vede la mia posizione,
  /// qualunque sia la modalità di condivisione. Null = nessuna limitazione.
  Future<void> updateAutoGhostSchedule({String? startUtc, String? endUtc}) async {
    await supabase.from('profiles').update({
      'auto_ghost_start': startUtc,
      'auto_ghost_end': endUtc,
    }).eq('id', _myId);
  }

  /// Ghost Mode temporaneo (Kinly+): null per tornare visibile subito.
  Future<void> updateGhostUntil(DateTime? until) async {
    await supabase.from('profiles').update({'ghost_until': until?.toUtc().toIso8601String()}).eq('id', _myId);
  }

  // ---------------------------------------------------------------------
  // Cerchie
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchMyCircles() async {
    return supabase.from('circles').select();
  }

  /// Coppie (circle_id, profile_id) per tutte le mie cerchie: la RLS filtra
  /// automaticamente ai soli membri delle cerchie di cui faccio parte.
  Future<List<Map<String, dynamic>>> fetchAllCircleMemberships() async {
    return supabase.from('circle_members').select('circle_id, profile_id');
  }

  Future<CircleGroup> createCircle({
    required String name,
    required String iconKey,
    required String colorHex,
    CircleType circleType = CircleType.family,
  }) async {
    late Map<String, dynamic> row;
    var attempt = 0;
    while (true) {
      final code = _generateInviteCode(name);
      try {
        row = await supabase
            .from('circles')
            .insert({
              'name': name,
              'icon_key': iconKey,
              'color': colorHex,
              'invite_code': code,
              'created_by': _myId,
              'circle_type': circleType.value,
            })
            .select()
            .single();
        break;
      } on PostgrestException catch (e) {
        attempt++;
        if (e.code != '23505' || attempt >= 5) rethrow;
      }
    }
    try {
      await supabase.from('circle_members').insert({'circle_id': row['id'], 'profile_id': _myId});
    } on PostgrestException catch (e) {
      // La cerchia è stata creata ma non posso aggiungermici: la elimino
      // per non lasciare in giro una cerchia senza membri.
      await supabase.from('circles').delete().eq('id', row['id']);
      throw _translateLimitError(e);
    }
    return CircleGroup.fromRow(row, memberIds: [_myId]);
  }

  /// Cerca una cerchia dal codice invito e, se esiste, mi ci aggiunge.
  /// Ritorna null se il codice non corrisponde a nessuna cerchia.
  Future<CircleGroup?> joinCircleByCode(String code) async {
    final result = await supabase.rpc('find_circle_by_code', params: {'p_code': code});
    if (result == null) return null;
    final row = Map<String, dynamic>.from(result as Map);
    try {
      // ignoreDuplicates evita un UPDATE se sono già membro (per cui non
      // c'è una policy RLS dedicata: non serve, basta non fare nulla).
      await supabase.from('circle_members').upsert(
        {'circle_id': row['id'], 'profile_id': _myId},
        onConflict: 'circle_id,profile_id',
        ignoreDuplicates: true,
      );
    } on PostgrestException catch (e) {
      throw _translateLimitError(e);
    }
    final members = await supabase.from('circle_members').select('profile_id').eq('circle_id', row['id']);
    final memberIds = members.map((m) => m['profile_id'] as String).toList();
    return CircleGroup.fromRow(row, memberIds: memberIds);
  }

  Object _translateLimitError(PostgrestException e) {
    if (e.message.contains('free_circle_limit_reached')) return const FreeLimitException(FreeLimitKind.tooManyCircles);
    if (e.message.contains('free_member_limit_reached')) return const FreeLimitException(FreeLimitKind.circleFull);
    if (e.message.contains('free_message_limit_reached')) return const FreeLimitException(FreeLimitKind.dailyMessageLimit);
    if (e.message.contains('free_ping_limit_reached')) return const FreeLimitException(FreeLimitKind.dailyPingLimit);
    if (e.message.contains('free_expense_limit_reached')) return const FreeLimitException(FreeLimitKind.dailyExpenseLimit);
    return e;
  }

  /// 6 caratteri da un alfabeto di 31 simboli (niente 0/1/O/I/L, facili da
  /// confondere a voce o a schermo) danno oltre 887 milioni di combinazioni
  /// per prefisso: con i 4 di prima (~924mila) indovinare un codice a caso
  /// senza conoscerlo, magari partendo da un prefisso comune come "FAM",
  /// era realisticamente alla portata di uno script, specie senza un
  /// limite ai tentativi lato server. Genera con Random.secure() invece del
  /// generatore di default, non pensato per essere imprevedibile.
  String _generateInviteCode(String name) {
    final rng = Random.secure();
    final trimmed = name.trim();
    final prefix = trimmed.isEmpty ? 'KIN' : trimmed.substring(0, min(3, trimmed.length)).toUpperCase();
    final suffix = List.generate(6, (_) => '23456789ABCDEFGHJKMNPQRSTUVWXYZ'[rng.nextInt(31)]).join();
    return '$prefix-$suffix';
  }

  /// Genera un nuovo codice invito per una cerchia già esistente, al posto
  /// di quello attuale: utile se è stato condiviso per sbaglio o si sospetta
  /// che qualcuno che non dovrebbe averlo lo conosca. Solo chi ha creato la
  /// cerchia può farlo (impone la RLS in update sulla tabella `circles`).
  Future<String> regenerateInviteCode({required String circleId, required String circleName}) async {
    var attempt = 0;
    while (true) {
      final code = _generateInviteCode(circleName);
      try {
        await supabase.from('circles').update({'invite_code': code}).eq('id', circleId);
        return code;
      } on PostgrestException catch (e) {
        attempt++;
        if (e.code != '23505' || attempt >= 5) rethrow;
      }
    }
  }

  /// Solo chi ha creato la cerchia può rimuovere un altro membro (impone la
  /// RLS "circle_members_delete_by_creator"): se lo tenta chiunque altro,
  /// la delete non tocca nessuna riga senza sollevare errore.
  Future<void> removeCircleMember({required String circleId, required String profileId}) async {
    await supabase.from('circle_members').delete().eq('circle_id', circleId).eq('profile_id', profileId);
  }

  /// Esco da una cerchia (rimuovo solo la mia riga). Chi l'ha creata non può
  /// usare questa via: dovrebbe eliminarla (vedi deleteCircle), altrimenti
  /// resterebbe una cerchia senza nessuno che può più modificarla.
  Future<void> leaveCircle(String circleId) async {
    await supabase.from('circle_members').delete().eq('circle_id', circleId).eq('profile_id', _myId);
  }

  /// Elimina l'intera cerchia (solo chi l'ha creata, RLS "circles_delete_creator"):
  /// cancella a cascata membri, aree sicure, punti d'incontro, messaggi,
  /// spese e tutto il resto legato a questa cerchia, per tutti i membri.
  Future<void> deleteCircle(String circleId) async {
    await supabase.from('circles').delete().eq('id', circleId);
  }

  // ---------------------------------------------------------------------
  // Posizione
  // ---------------------------------------------------------------------

  /// Usa la RPC `fetch_visible_locations` (non una select diretta) perché
  /// applica l'arrotondamento della posizione per chi è in modalità fuzzy
  /// lato server: il punto esatto di chi è "approssimativo" non arriva mai
  /// al client di chi guarda.
  Future<List<Map<String, dynamic>>> fetchLocations(List<String> ids) async {
    if (ids.isEmpty) return [];
    final result = await supabase.rpc('fetch_visible_locations', params: {'p_ids': ids});
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<void> upsertMyLocation({required double lat, required double lng, String? address, double? speedKmh}) async {
    await supabase.from('locations').upsert({
      'profile_id': _myId,
      'lat': lat,
      'lng': lng,
      'address': address,
      'speed_kmh': speedKmh,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> appendLocationHistory({required double lat, required double lng, String? address}) async {
    await supabase.from('location_history').insert({'profile_id': _myId, 'lat': lat, 'lng': lng, 'address': address});
  }

  /// Storico di una persona (Kinly+): se non sono premium, la RLS ritorna
  /// semplicemente una lista vuota invece di un errore.
  Future<List<Map<String, dynamic>>> fetchLocationHistory(String profileId, {int limit = 200}) async {
    return supabase
        .from('location_history')
        .select()
        .eq('profile_id', profileId)
        .order('recorded_at', ascending: false)
        .limit(limit);
  }

  /// Cancella tutto il MIO storico posizioni: gli "itinerari" nelle
  /// statistiche sono ricostruiti al volo da questi punti (non c'è una
  /// tabella separata), quindi svuotare qui basta a far sparire anche quelli.
  /// Solo sulle mie righe: la RLS non permetterebbe comunque di toccare
  /// quelle di qualcun altro.
  Future<void> deleteMyLocationHistory() async {
    await supabase.from('location_history').delete().eq('profile_id', _myId);
  }

  // ---------------------------------------------------------------------
  // Aree sicure (Kinly+)
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchSafeZones() async {
    return supabase.from('safe_zones').select();
  }

  Future<void> createSafeZone({
    required String circleId,
    required String name,
    required double lat,
    required double lng,
    required int radiusMeters,
    required SafeZoneKind kind,
    required SafeZoneType zoneType,
  }) async {
    try {
      await supabase.from('safe_zones').insert({
        'circle_id': circleId,
        'name': name,
        'lat': lat,
        'lng': lng,
        'radius_meters': radiusMeters,
        'created_by': _myId,
        'kind': kind.dbValue,
        'zone_type': zoneType.dbValue,
      });
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw const FreeLimitException(FreeLimitKind.circleFull);
      rethrow;
    }
  }

  Future<void> updateSafeZone({
    required String zoneId,
    required String name,
    required double lat,
    required double lng,
    required int radiusMeters,
    required SafeZoneKind kind,
    required SafeZoneType zoneType,
  }) async {
    await supabase.from('safe_zones').update({
      'name': name,
      'lat': lat,
      'lng': lng,
      'radius_meters': radiusMeters,
      'kind': kind.dbValue,
      'zone_type': zoneType.dbValue,
    }).eq('id', zoneId);
  }

  Future<void> deleteSafeZone(String zoneId) async {
    await supabase.from('safe_zones').delete().eq('id', zoneId);
  }

  Future<List<Map<String, dynamic>>> fetchSafeZoneEvents({int limit = 50}) async {
    return supabase.from('safe_zone_events').select().order('occurred_at', ascending: false).limit(limit);
  }

  Future<void> recordSafeZoneEvent({required String zoneId, required bool entering}) async {
    await supabase.from('safe_zone_events').insert({
      'zone_id': zoneId,
      'profile_id': _myId,
      'event_type': entering ? 'enter' : 'exit',
    });
  }

  // ---------------------------------------------------------------------
  // Avvisi di guida (Kinly+)
  // ---------------------------------------------------------------------

  /// Avvisi registrati: se non sono premium, la RLS ritorna una lista
  /// vuota invece di un errore (stessa logica di fetchLocationHistory).
  Future<List<Map<String, dynamic>>> fetchSpeedEvents({int limit = 50}) async {
    return supabase.from('speed_events').select().order('occurred_at', ascending: false).limit(limit);
  }

  Future<void> recordSpeedEvent({required double speedKmh, required double thresholdKmh}) async {
    await supabase.from('speed_events').insert({
      'profile_id': _myId,
      'speed_kmh': speedKmh,
      'threshold_kmh': thresholdKmh,
    });
  }

  /// Avvisa la cerchia che il telefono sta per scaricarsi (gratuita, non
  /// serve essere premium): il trigger send_push_trigger su battery_alerts
  /// fa partire la notifica.
  Future<void> recordBatteryAlert(int percent) async {
    await supabase.from('battery_alerts').insert({
      'profile_id': _myId,
      'battery_percent': percent,
    });
  }

  // ---------------------------------------------------------------------
  // Punto d'incontro condiviso (non è una funzione Kinly+)
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchMeetingPoints() async {
    return supabase.from('meeting_points').select();
  }

  Future<void> createMeetingPoint({
    required String circleId,
    required String name,
    required double lat,
    required double lng,
    DateTime? scheduledAt,
  }) async {
    await supabase.from('meeting_points').insert({
      'circle_id': circleId,
      'name': name,
      'lat': lat,
      'lng': lng,
      'created_by': _myId,
      'scheduled_at': scheduledAt?.toUtc().toIso8601String(),
    });
  }

  Future<void> deleteMeetingPoint(String id) async {
    await supabase.from('meeting_points').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchMeetingPointArrivals() async {
    return supabase.from('meeting_point_arrivals').select();
  }

  /// Idempotente: se ho già segnato l'arrivo a questo punto non fa nulla.
  Future<void> recordMeetingPointArrival(String meetingPointId) async {
    await supabase.from('meeting_point_arrivals').upsert(
      {'meeting_point_id': meetingPointId, 'profile_id': _myId},
      onConflict: 'meeting_point_id,profile_id',
      ignoreDuplicates: true,
    );
  }

  // ---------------------------------------------------------------------
  // Ritrovi: alternativa al punto d'incontro che non rivela mai una
  // posizione live, unica opzione disponibile nelle Cerchie Eventi.
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchMeetupSpots() async {
    return supabase.from('meetup_spots').select();
  }

  Future<void> createMeetupSpot({
    required String circleId,
    required String name,
    required String category,
    required double lat,
    required double lng,
    String? note,
  }) async {
    await supabase.from('meetup_spots').insert({
      'circle_id': circleId,
      'name': name,
      'category': category,
      'lat': lat,
      'lng': lng,
      'note': note,
      'created_by': _myId,
    });
  }

  Future<void> deleteMeetupSpot(String id) async {
    await supabase.from('meetup_spots').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> fetchMeetups() async {
    return supabase.from('meetups').select();
  }

  Future<void> proposeMeetup({
    required String spotId,
    required String circleId,
    required DateTime scheduledAt,
    String? note,
  }) async {
    await supabase.from('meetups').insert({
      'spot_id': spotId,
      'circle_id': circleId,
      'proposed_by': _myId,
      'scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'note': note,
    });
  }

  Future<List<Map<String, dynamic>>> fetchMeetupRsvps() async {
    return supabase.from('meetup_rsvps').select();
  }

  Future<void> respondToMeetup({required String meetupId, required bool attending}) async {
    await supabase.from('meetup_rsvps').upsert(
      {'meetup_id': meetupId, 'profile_id': _myId, 'response': attending ? 'yes' : 'no'},
      onConflict: 'meetup_id,profile_id',
    );
  }

  Future<List<Map<String, dynamic>>> fetchMeetupCheckins() async {
    return supabase.from('meetup_checkins').select();
  }

  /// Registra la propria presenza in uno spot: rilevata dal dispositivo
  /// confrontando la propria posizione con quella dello spot, mai una
  /// posizione continua o un tragitto. [meetupId] è valorizzato solo quando
  /// il check-in conferma l'arrivo a un ritrovo proposto.
  Future<void> recordMeetupCheckin({required String spotId, String? meetupId, required String circleId}) async {
    await supabase.from('meetup_checkins').insert({
      'spot_id': spotId,
      'meetup_id': meetupId,
      'profile_id': _myId,
      'circle_id': circleId,
    });
  }

  // ---------------------------------------------------------------------
  // Messaggi cerchia (brevi, non è una chat: vedi CircleMessage)
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchCircleMessages() async {
    return supabase.from('circle_messages').select().order('created_at', ascending: false).limit(200);
  }

  Future<void> sendCircleMessage({required String circleId, required String body}) async {
    try {
      await supabase.from('circle_messages').insert({'circle_id': circleId, 'sender_id': _myId, 'body': body});
    } on PostgrestException catch (e) {
      throw _translateLimitError(e);
    }
  }

  // ---------------------------------------------------------------------
  // Assistenza
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchMySupportMessages() async {
    return supabase.from('support_messages').select().order('created_at', ascending: false);
  }

  Future<void> sendSupportMessage(String message) async {
    await supabase.from('support_messages').insert({'profile_id': _myId, 'message': message});
  }

  /// Tutti i messaggi di assistenza (solo per admin: la RLS ritorna solo i
  /// propri a chi non lo è).
  Future<List<Map<String, dynamic>>> fetchAllSupportMessages() async {
    return supabase.from('support_messages').select().order('created_at', ascending: false);
  }

  Future<void> replyToSupportMessage({required String id, required String reply}) async {
    await supabase.from('support_messages').update({
      'admin_reply': reply,
      'status': 'answered',
      'replied_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  // ---------------------------------------------------------------------
  // Token per le notifiche push (Firebase Cloud Messaging)
  // ---------------------------------------------------------------------

  Future<void> upsertDeviceToken(String token) async {
    await supabase.from('device_tokens').upsert(
      {'profile_id': _myId, 'token': token, 'updated_at': DateTime.now().toUtc().toIso8601String()},
      onConflict: 'profile_id,token',
    );
  }

  Future<void> deleteDeviceToken(String token) async {
    await supabase.from('device_tokens').delete().eq('profile_id', _myId).eq('token', token);
  }

  // ---------------------------------------------------------------------
  // Richiesta di aiuto (un gradino sotto l'SOS)
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchHelpRequests() async {
    return supabase.from('help_requests').select().order('created_at', ascending: false);
  }

  Future<void> triggerHelpRequest({
    required String circleId,
    required String reasonDbValue,
    String? note,
    required double lat,
    required double lng,
  }) async {
    await supabase.from('help_requests').insert({
      'circle_id': circleId,
      'profile_id': _myId,
      'reason': reasonDbValue,
      'note': note,
      'lat': lat,
      'lng': lng,
    });
  }

  Future<void> resolveHelpRequest(String id) async {
    await supabase.from('help_requests').update({
      'status': 'resolved',
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  // ---------------------------------------------------------------------
  // Contatti SOS di fiducia
  // ---------------------------------------------------------------------

  Future<List<String>> fetchSosTrustedContactIds() async {
    final rows = await supabase.from('sos_trusted_contacts').select('contact_id').eq('profile_id', _myId);
    return rows.map((r) => r['contact_id'] as String).toList();
  }

  Future<void> addSosTrustedContact(String contactId) async {
    await supabase.from('sos_trusted_contacts').upsert(
      {'profile_id': _myId, 'contact_id': contactId},
      onConflict: 'profile_id,contact_id',
      ignoreDuplicates: true,
    );
  }

  Future<void> removeSosTrustedContact(String contactId) async {
    await supabase.from('sos_trusted_contacts').delete().eq('profile_id', _myId).eq('contact_id', contactId);
  }

  // ---------------------------------------------------------------------
  // SOS "Black Box" (solo posizione, nessuna registrazione)
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchSosAlerts() async {
    return supabase.from('sos_alerts').select().order('created_at', ascending: false);
  }

  Future<void> triggerSos({required double lat, required double lng}) async {
    await supabase.from('sos_alerts').insert({'profile_id': _myId, 'lat': lat, 'lng': lng});
  }

  Future<void> resolveSos(String id) async {
    await supabase.from('sos_alerts').update({
      'status': 'resolved',
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  // ---------------------------------------------------------------------
  // Richieste di posizione
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchLocationRequests() async {
    return supabase.from('location_requests').select().order('created_at', ascending: false);
  }

  Future<bool> sendLocationRequest(String targetId) async {
    final existing = await supabase
        .from('location_requests')
        .select('id')
        .eq('requester_id', _myId)
        .eq('target_id', targetId)
        .eq('status', 'pending');
    if (existing.isNotEmpty) return false;
    await supabase.from('location_requests').insert({'requester_id': _myId, 'target_id': targetId});
    return true;
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    await supabase.from('location_requests').update({
      'status': accept ? 'accepted' : 'declined',
      'responded_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', requestId);
  }

  /// Rimuove una singola richiesta (in attesa, inviata, o già risolta) dalla
  /// lista: la RLS permette di farlo a chi l'ha mandata o ricevuta.
  Future<void> deleteLocationRequest(String requestId) async {
    await supabase.from('location_requests').delete().eq('id', requestId);
  }

  /// Svuota solo le MIE richieste già risolte (accettate/rifiutate): quelle
  /// ancora in attesa non vengono toccate, si tolgono una alla volta con
  /// [deleteLocationRequest]. Il filtro su requester/target è già imposto
  /// dalla RLS, ma lo ripetiamo qui per non affidarsi solo a quello.
  Future<void> clearLocationRequestHistory() async {
    await supabase
        .from('location_requests')
        .delete()
        .neq('status', 'pending')
        .or('requester_id.eq.$_myId,target_id.eq.$_myId');
  }

  // ---------------------------------------------------------------------
  // Ping contestuali e incontri (High five)
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchPings({int limit = 30}) async {
    return supabase.from('pings').select().order('created_at', ascending: false).limit(limit);
  }

  Future<void> sendPing({required String toId, required String kind}) async {
    try {
      await supabase.from('pings').insert({'from_id': _myId, 'to_id': toId, 'kind': kind});
    } on PostgrestException catch (e) {
      throw _translateLimitError(e);
    }
  }

  Future<List<Map<String, dynamic>>> fetchEncounters({int limit = 20}) async {
    return supabase.from('encounters').select().order('created_at', ascending: false).limit(limit);
  }

  // ---------------------------------------------------------------------
  // "Portami qualcosa": cache POI + soste + richieste
  // ---------------------------------------------------------------------

  /// Cella di ~11m (4 decimali) usata come chiave della cache condivisa.
  String poiCellKey(double lat, double lng) => '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';

  Future<Map<String, dynamic>?> fetchPoiCache(String cellKey) async {
    final rows = await supabase.from('poi_cache').select().eq('cell_key', cellKey).limit(1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> upsertPoiCache({required String cellKey, required String category, String? placeName}) async {
    await supabase.from('poi_cache').upsert({
      'cell_key': cellKey,
      'category': category,
      'place_name': placeName,
      'fetched_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'cell_key');
  }

  Future<List<Map<String, dynamic>>> fetchShoppingStops() async {
    return supabase.from('shopping_stops').select().order('created_at', ascending: false).limit(50);
  }

  Future<void> recordShoppingStop({
    required String circleId,
    required String category,
    String? placeName,
    required double lat,
    required double lng,
  }) async {
    await supabase.from('shopping_stops').insert({
      'profile_id': _myId,
      'circle_id': circleId,
      'category': category,
      'place_name': placeName,
      'lat': lat,
      'lng': lng,
    });
  }

  Future<List<Map<String, dynamic>>> fetchShoppingRequests() async {
    return supabase.from('shopping_requests').select().order('created_at', ascending: false).limit(50);
  }

  Future<void> sendShoppingRequest({required String stopId, required String note}) async {
    await supabase.from('shopping_requests').insert({'stop_id': stopId, 'from_id': _myId, 'note': note});
  }

  // ---------------------------------------------------------------------
  // Lista della spesa condivisa (voci fisse, non legate a una sosta)
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchShoppingListItems() async {
    return supabase.from('shopping_list_items').select().order('created_at', ascending: false).limit(200);
  }

  Future<void> addShoppingListItem({required String circleId, required String label}) async {
    await supabase.from('shopping_list_items').insert({'circle_id': circleId, 'label': label, 'created_by': _myId});
  }

  /// Passa null a claim per liberare la voce (l'ha già presa qualcun altro
  /// o serve rimetterla in coda).
  Future<void> claimShoppingListItem({required String itemId, required bool claim}) async {
    await supabase.from('shopping_list_items').update({
      'claimed_by': claim ? _myId : null,
      'claimed_at': claim ? DateTime.now().toUtc().toIso8601String() : null,
    }).eq('id', itemId);
  }

  Future<void> deleteShoppingListItem(String itemId) async {
    await supabase.from('shopping_list_items').delete().eq('id', itemId);
  }

  // ---------------------------------------------------------------------
  // Spese di gruppo (Splitwise)
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchCircleExpenses() async {
    return supabase.from('circle_expenses').select().order('created_at', ascending: false).limit(200);
  }

  Future<List<Map<String, dynamic>>> fetchExpenseShares() async {
    return supabase.from('expense_shares').select();
  }

  Future<void> createExpense({
    required String circleId,
    required String description,
    required double amount,
    required Map<String, double> sharesByProfileId,
  }) async {
    Map<String, dynamic> expense;
    try {
      expense = await supabase
          .from('circle_expenses')
          .insert({'circle_id': circleId, 'paid_by': _myId, 'description': description, 'amount': amount})
          .select()
          .single();
    } on PostgrestException catch (e) {
      throw _translateLimitError(e);
    }
    await supabase.from('expense_shares').insert([
      for (final entry in sharesByProfileId.entries) {'expense_id': expense['id'], 'profile_id': entry.key, 'share_amount': entry.value},
    ]);
  }

  Future<void> deleteExpense(String id) async {
    await supabase.from('circle_expenses').delete().eq('id', id);
  }

  // ---------------------------------------------------------------------
  // Condivisione posizione via link pubblico
  // ---------------------------------------------------------------------

  /// Crea un link "seguimi" valido per [duration] e ritorna l'URL completo
  /// da condividere: chiunque lo apre nel browser (anche senza l'app) vede
  /// la posizione live finché non scade.
  ///
  /// La pagina vive su Cloudflare Pages (non su Supabase): il dominio
  /// condiviso *.supabase.co riscrive sempre le pagine HTML in testo
  /// semplice, quindi lì può vivere solo l'API che restituisce i dati (vedi
  /// supabase/functions/live-share). La pagina statica con la mappa è in
  /// docs/live-share.html in questo repository, pubblicata su
  /// kinlyapp.pages.dev.
  Future<String> createLiveShareLink(Duration duration) async {
    final rng = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final token = List.generate(28, (_) => chars[rng.nextInt(chars.length)]).join();
    await supabase.from('live_share_links').insert({
      'profile_id': _myId,
      'token': token,
      'expires_at': DateTime.now().add(duration).toUtc().toIso8601String(),
    });
    return 'https://kinlyapp.pages.dev/live-share.html?t=$token';
  }

  // ---------------------------------------------------------------------
  // Realtime: un unico canale che avvisa di qualunque cambiamento
  // rilevante, così l'app può ricaricare i dati e restare aggiornata.
  // ---------------------------------------------------------------------

  /// [onLocationChange] gestisce da sola i cambi sulla tabella `locations`
  /// (il grosso del traffico realtime: scatta ad ogni spostamento di
  /// chiunque nella cerchia), passando solo il profile_id cambiato — così
  /// chi ascolta può aggiornare in modo mirato la sola persona interessata
  /// invece di ricaricare tutto. [onOtherChange] resta il comportamento
  /// precedente ("ricarica tutto") per le altre tabelle, molto meno
  /// frequenti (messaggi, spese, aree sicure...).
  RealtimeChannel subscribeToChanges(void Function() onOtherChange, void Function(String profileId) onLocationChange) {
    final channel = supabase.channel('kinly_live_updates');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'locations',
      callback: (payload) {
        final row = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
        final profileId = row['profile_id'] as String?;
        if (profileId != null) {
          onLocationChange(profileId);
        } else {
          onOtherChange();
        }
      },
    );
    for (final table in [
      'profiles',
      'circle_members',
      'circles',
      'location_requests',
      'safe_zones',
      'safe_zone_events',
      'speed_events',
      'meeting_points',
      'meeting_point_arrivals',
      'sos_alerts',
      'circle_messages',
      'help_requests',
      'pings',
      'encounters',
      'shopping_stops',
      'shopping_requests',
      'circle_expenses',
      'expense_shares',
      'circle_member_settings',
      'meetup_spots',
      'meetups',
      'meetup_rsvps',
      'meetup_checkins',
    ]) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (payload) => onOtherChange(),
      );
    }
    channel.subscribe();
    return channel;
  }
}
