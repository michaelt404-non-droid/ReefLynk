import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final GoTrueClient _auth = Supabase.instance.client.auth;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  User? get currentUser => _auth.currentUser;

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }
}
