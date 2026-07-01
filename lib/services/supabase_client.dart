import 'package:supabase_flutter/supabase_flutter.dart';

/// Credenziali del progetto Supabase. Di default puntano al progetto usato
/// per lo sviluppo di Kinly; puoi sovrascriverle a build/run time con
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
/// (utile per un secondo ambiente, es. staging). La anon key è pensata per
/// stare nel client (è protetta dalle policy RLS): non va confusa con la
/// service_role key, quella sì segreta, che non va mai usata nell'app.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tteqhmlcsgduuzlcqbrt.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR0ZXFobWxjc2dkdXV6bGNxYnJ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI4Njg2MzAsImV4cCI6MjA5ODQ0NDYzMH0.'
        'A1MC_Qma7lgN4ZDl-MDx-pmi0Rh5ZAcLcMHs_lAgYIc',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

Future<void> initSupabase() async {
  await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.anonKey);
}

SupabaseClient get supabase => Supabase.instance.client;
