import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/circle_group.dart';
import '../models/sharing_mode.dart';
import 'supabase_client.dart';

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
    await supabase.from('circle_members').insert({'circle_id': row['id'], 'profile_id': _myId});
    return CircleGroup.fromRow(row, memberIds: [_myId]);
  }

  /// Cerca una cerchia dal codice invito e, se esiste, mi ci aggiunge.
  /// Ritorna null se il codice non corrisponde a nessuna cerchia.
  Future<CircleGroup?> joinCircleByCode(String code) async {
    final result = await supabase.rpc('find_circle_by_code', params: {'p_code': code});
    if (result == null) return null;
    final row = Map<String, dynamic>.from(result as Map);
    // ignoreDuplicates evita un UPDATE se sono già membro (per cui non c'è
    // una policy RLS dedicata: non serve, basta non fare nulla).
    await supabase.from('circle_members').upsert(
      {'circle_id': row['id'], 'profile_id': _myId},
      onConflict: 'circle_id,profile_id',
      ignoreDuplicates: true,
    );
    final members = await supabase.from('circle_members').select('profile_id').eq('circle_id', row['id']);
    final memberIds = members.map((m) => m['profile_id'] as String).toList();
    return CircleGroup.fromRow(row, memberIds: memberIds);
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

  Future<List<Map<String, dynamic>>> fetchLocations(List<String> ids) async {
    if (ids.isEmpty) return [];
    return supabase.from('locations').select().inFilter('profile_id', ids);
  }

  Future<void> upsertMyLocation({required double lat, required double lng, String? address}) async {
    await supabase.from('locations').upsert({
      'profile_id': _myId,
      'lat': lat,
      'lng': lng,
      'address': address,
      'updated_at': DateTime.now().toIso8601String(),
    });
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
    for (final table in ['profiles', 'circle_members', 'circles', 'locations', 'location_requests']) {
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
