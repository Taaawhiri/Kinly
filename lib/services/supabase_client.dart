import 'package:supabase_flutter/supabase_flutter.dart';

/// Credenziali del progetto Supabase. Vanno passate a build/run time con
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
/// (vedi il README per come ottenerle e configurarle).
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

Future<void> initSupabase() async {
  await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.anonKey);
}

SupabaseClient get supabase => Supabase.instance.client;
