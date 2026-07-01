import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Accesso via email con codice OTP: niente password, niente registrazione
/// pubblica "aperta" — basta l'email per entrare, ma per vedere qualcuno
/// serve comunque essere invitati nella sua cerchia.
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  User? get currentUser => supabase.auth.currentUser;
  String? get currentUserId => supabase.auth.currentUser?.id;
  bool get isSignedIn => currentUser != null;

  Stream<AuthState> get onAuthStateChange => supabase.auth.onAuthStateChange;

  /// Invia all'email un codice a 6 cifre da inserire nella schermata
  /// successiva. `name` viene salvato nei metadata e usato dal trigger
  /// `handle_new_user` per creare il profilo al primo accesso.
  Future<void> sendOtp({required String email, String? name}) {
    return supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
      data: name != null && name.trim().isNotEmpty ? {'name': name.trim()} : null,
    );
  }

  Future<void> verifyOtp({required String email, required String token}) {
    return supabase.auth.verifyOTP(type: OtpType.email, email: email, token: token);
  }

  Future<void> signOut() => supabase.auth.signOut();
}
