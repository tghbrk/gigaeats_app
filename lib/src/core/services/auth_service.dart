import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for authentication operations
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  /// Update user password
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  /// Update user email
  Future<UserResponse> updateEmail(String newEmail) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(email: newEmail),
      );
      return response;
    } catch (e) {
      throw Exception('Failed to update email: $e');
    }
  }

  /// Get auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Refresh session
  Future<AuthResponse> refreshSession() async {
    try {
      final response = await _supabase.auth.refreshSession();
      return response;
    } catch (e) {
      throw Exception('Failed to refresh session: $e');
    }
  }

  /// Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Check if email is confirmed
  bool get isEmailConfirmed => currentUser?.emailConfirmedAt != null;

  /// Resend email confirmation
  Future<void> resendEmailConfirmation() async {
    try {
      if (currentUser?.email != null) {
        await _supabase.auth.resend(
          type: OtpType.signup,
          email: currentUser!.email!,
        );
      }
    } catch (e) {
      throw Exception('Failed to resend email confirmation: $e');
    }
  }
}
