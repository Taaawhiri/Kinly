import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Accesso via email e password: niente registrazione pubblica alle
/// cerchie (per quello serve un invito), ma l'account si crea liberamente.
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  User? get currentUser => supabase.auth.currentUser;
  String? get currentUserId => supabase.auth.currentUser?.id;
  bool get isSignedIn => currentUser != null;

  Stream<AuthState> get onAuthStateChange => supabase.auth.onAuthStateChange;

  /// Crea l'account. `name` viene salvato nei metadata e usato dal trigger
  /// `handle_new_user` per creare il profilo. Se nel progetto Supabase è
  /// attiva la conferma email, `response.session` sarà nullo finché
  /// l'utente non conferma dal link ricevuto via email.
  Future<AuthResponse> signUp({required String email, required String password, String? name}) {
    return supabase.auth.signUp(
      email: email,
      password: password,
      data: name != null && name.trim().isNotEmpty ? {'name': name.trim()} : null,
    );
  }

  Future<AuthResponse> signIn({required String email, required String password}) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => supabase.auth.signOut();
}
