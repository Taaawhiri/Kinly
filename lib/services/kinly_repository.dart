import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/circle_group.dart';
import '../models/sharing_mode.dart';
import 'supabase_client.dart';

/// Sollevata quando un'operazione viene bloccata dai limiti del piano
/// gratuito (vedi il trigger `enforce_circle_limits` nello schema).
enum FreeLimitKind { tooManyCircles, circleFull }

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

  Future<Map<String, dynamic>> fetchMyProfile() async {
    return supabase.from('profiles').select().eq('id', _myId).single();
  }

  Future<List<Map<String, dynamic>>> fetchProfiles(List<String> ids) async {
    if (ids.isEmpty) return [];
    return supabase.from('profiles').select().inFilter('id', ids);
  }

  Future<void> setSharingMode(SharingMode mode) async {
    await supabase.from('profiles').update({'sharing_mode': mode.dbValue}).eq('id', _myId);
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

  /// Orario di reperibilità (valori già convertiti in UTC, formato
  /// "HH:MM:SS"): fuori da questa finestra nessuno vede la mia posizione,
  /// qualunque sia la modalità di condivisione. Null = nessuna limitazione.
  Future<void> updateAutoGhostSchedule({String? startUtc, String? endUtc}) async {
    await supabase.from('profiles').update({
      'auto_ghost_start': startUtc,
      'auto_ghost_end': endUtc,
    }).eq('id', _myId);
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

  Future<CircleGroup> createCircle({required String name, required String iconKey, required String colorHex}) async {
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
    return e;
  }

  String _generateInviteCode(String name) {
    final rng = Random();
    final trimmed = name.trim();
    final prefix = trimmed.isEmpty ? 'KIN' : trimmed.substring(0, min(3, trimmed.length)).toUpperCase();
    final suffix = List.generate(4, (_) => '23456789ABCDEFGHJKMNPQRSTUVWXYZ'[rng.nextInt(31)]).join();
    return '$prefix-$suffix';
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
      'updated_at': DateTime.now().toIso8601String(),
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
  }) async {
    try {
      await supabase.from('safe_zones').insert({
        'circle_id': circleId,
        'name': name,
        'lat': lat,
        'lng': lng,
        'radius_meters': radiusMeters,
        'created_by': _myId,
      });
    } on PostgrestException catch (e) {
      if (e.code == '42501') throw const FreeLimitException(FreeLimitKind.circleFull);
      rethrow;
    }
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

  // ---------------------------------------------------------------------
  // Punto d'incontro condiviso (non è una funzione Kinly+)
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchMeetingPoints() async {
    return supabase.from('meeting_points').select();
  }

  Future<void> createMeetingPoint({required String circleId, required String name, required double lat, required double lng}) async {
    await supabase.from('meeting_points').insert({
      'circle_id': circleId,
      'name': name,
      'lat': lat,
      'lng': lng,
      'created_by': _myId,
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
  // Assistenza
  // ---------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchMySupportMessages() async {
    return supabase.from('support_messages').select().order('created_at', ascending: false);
  }

  Future<void> sendSupportMessage(String message) async {
    await supabase.from('support_messages').insert({'profile_id': _myId, 'message': message});
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
      'resolved_at': DateTime.now().toIso8601String(),
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
      'responded_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  // ---------------------------------------------------------------------
  // Realtime: un unico canale che avvisa di qualunque cambiamento
  // rilevante, così l'app può ricaricare i dati e restare aggiornata.
  // ---------------------------------------------------------------------

  RealtimeChannel subscribeToChanges(void Function() onChange) {
    final channel = supabase.channel('kinly_live_updates');
    for (final table in [
      'profiles',
      'circle_members',
      'circles',
      'locations',
      'location_requests',
      'safe_zones',
      'safe_zone_events',
      'speed_events',
      'meeting_points',
      'meeting_point_arrivals',
      'sos_alerts',
    ]) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (payload) => onChange(),
      );
    }
    channel.subscribe();
    return channel;
  }
}
