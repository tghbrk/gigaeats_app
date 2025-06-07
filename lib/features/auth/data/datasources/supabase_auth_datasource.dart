import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../core/errors/exceptions.dart' as app_exceptions;
import '../../../../core/utils/logger.dart';
import '../../../../data/models/user.dart' as app_models;

/// Remote data source for authentication operations using Supabase
abstract class SupabaseAuthDataSource {
  Future<app_models.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<app_models.User> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  });

  Future<void> signOut();
  Future<app_models.User?> getCurrentUser();
  Stream<app_models.User?> get authStateChanges;
  Future<void> sendPasswordResetEmail(String email);
  Future<void> verifyEmail();
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> deleteAccount();
  Future<String> refreshToken();
  Future<bool> isAuthenticated();
  Future<app_models.User> signInWithGoogle();
  Future<app_models.User> signInWithApple();
}

/// Implementation of SupabaseAuthDataSource using Supabase Auth
class SupabaseAuthDataSourceImpl implements SupabaseAuthDataSource {
  final SupabaseClient _supabaseClient;
  final AppLogger _logger = AppLogger();

  SupabaseAuthDataSourceImpl({
    SupabaseClient? supabaseClient,
  }) : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  @override
  Future<app_models.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _logger.info('Attempting to sign in user: $email');

      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const app_exceptions.AuthException(message: 'Failed to sign in user');
      }

      // Get user profile from database
      final userProfile = await _getUserProfile(response.user!.id);
      
      _logger.info('User signed in successfully: $email');
      return userProfile;
    } on AuthException catch (e) {
      _logger.error('Supabase auth error during sign in', e);
      throw app_exceptions.AuthException(
        message: _getSupabaseErrorMessage(e),
        code: e.message,
        details: e,
      );
    } catch (e) {
      _logger.error('Unexpected error during sign in', e);
      throw app_exceptions.AuthException(
        message: 'Failed to sign in: ${e.toString()}',
        details: e,
      );
    }
  }

  @override
  Future<app_models.User> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      _logger.info('Attempting to sign up user: $email');

      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        },
      );

      if (response.user == null) {
        throw const app_exceptions.AuthException(message: 'Failed to create user');
      }

      // Wait for database trigger to create user profile
      await Future.delayed(const Duration(milliseconds: 500));

      // Get user profile from database
      final userProfile = await _getUserProfile(response.user!.id);
      
      _logger.info('User signed up successfully: $email');
      return userProfile;
    } on AuthException catch (e) {
      _logger.error('Supabase auth error during sign up', e);
      throw app_exceptions.AuthException(
        message: _getSupabaseErrorMessage(e),
        code: e.message,
        details: e,
      );
    } catch (e) {
      _logger.error('Unexpected error during sign up', e);
      throw app_exceptions.AuthException(
        message: 'Failed to sign up: ${e.toString()}',
        details: e,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      _logger.info('Signing out user');
      
      await _supabaseClient.auth.signOut();
      
      _logger.info('User signed out successfully');
    } catch (e) {
      _logger.error('Error during sign out', e);
      throw app_exceptions.AuthException(
        message: 'Failed to sign out: ${e.toString()}',
        details: e,
      );
    }
  }

  @override
  Future<app_models.User?> getCurrentUser() async {
    try {
      final supabaseUser = _supabaseClient.auth.currentUser;
      if (supabaseUser == null) return null;

      return await _getUserProfile(supabaseUser.id);
    } catch (e) {
      _logger.error('Error getting current user', e);
      return null;
    }
  }

  @override
  Stream<app_models.User?> get authStateChanges {
    return _supabaseClient.auth.onAuthStateChange.asyncMap((authState) async {
      if (authState.session?.user == null) return null;
      
      try {
        return await _getUserProfile(authState.session!.user.id);
      } catch (e) {
        _logger.error('Error getting user profile in auth state change', e);
        return null;
      }
    });
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
      _logger.info('Password reset email sent to: $email');
    } on AuthException catch (e) {
      _logger.error('Supabase auth error during password reset', e);
      throw app_exceptions.AuthException(
        message: _getSupabaseErrorMessage(e),
        code: e.message,
        details: e,
      );
    } catch (e) {
      _logger.error('Unexpected error during password reset', e);
      throw app_exceptions.AuthException(
        message: 'Failed to send password reset email: ${e.toString()}',
        details: e,
      );
    }
  }

  @override
  Future<void> verifyEmail() async {
    try {
      // Supabase handles email verification automatically during signup
      // This method is kept for interface compatibility
      _logger.info('Email verification handled by Supabase');
    } catch (e) {
      _logger.error('Unexpected error during email verification', e);
      throw app_exceptions.AuthException(
        message: 'Failed to send email verification: ${e.toString()}',
        details: e,
      );
    }
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      _logger.info('Password updated successfully');
    } on AuthException catch (e) {
      _logger.error('Supabase auth error during password update', e);
      throw app_exceptions.AuthException(
        message: _getSupabaseErrorMessage(e),
        code: e.message,
        details: e,
      );
    } catch (e) {
      _logger.error('Unexpected error during password update', e);
      throw app_exceptions.AuthException(
        message: 'Failed to update password: ${e.toString()}',
        details: e,
      );
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      // Note: Supabase doesn't have a direct delete user method in the client
      // This would typically be handled by a server-side function
      throw const app_exceptions.AuthException(
        message: 'Account deletion not implemented - requires server-side function',
      );
    } catch (e) {
      _logger.error('Unexpected error during account deletion', e);
      throw app_exceptions.AuthException(
        message: 'Failed to delete account: ${e.toString()}',
        details: e,
      );
    }
  }

  @override
  Future<String> refreshToken() async {
    try {
      final session = _supabaseClient.auth.currentSession;
      if (session?.accessToken == null) {
        throw const app_exceptions.AuthException(message: 'No active session');
      }

      return session!.accessToken;
    } catch (e) {
      _logger.error('Failed to refresh token', e);
      throw app_exceptions.AuthException(
        message: 'Failed to refresh token: ${e.toString()}',
        details: e,
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _supabaseClient.auth.currentUser != null;
  }

  @override
  Future<app_models.User> signInWithGoogle() async {
    try {
      await _supabaseClient.auth.signInWithOAuth(OAuthProvider.google);
      
      // Wait for auth state change
      await Future.delayed(const Duration(seconds: 2));
      
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw const app_exceptions.AuthException(message: 'Google sign-in failed');
      }
      
      return currentUser;
    } catch (e) {
      throw app_exceptions.AuthException(
        message: 'Google sign-in failed: ${e.toString()}',
        details: e,
      );
    }
  }

  @override
  Future<app_models.User> signInWithApple() async {
    try {
      await _supabaseClient.auth.signInWithOAuth(OAuthProvider.apple);
      
      // Wait for auth state change
      await Future.delayed(const Duration(seconds: 2));
      
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw const app_exceptions.AuthException(message: 'Apple sign-in failed');
      }
      
      return currentUser;
    } catch (e) {
      throw app_exceptions.AuthException(
        message: 'Apple sign-in failed: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get user profile from Supabase
  Future<app_models.User> _getUserProfile(String supabaseUserId) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select()
          .eq('supabase_user_id', supabaseUserId)
          .single();

      return app_models.User.fromJson(response);
    } catch (e) {
      _logger.error('Failed to get user profile from Supabase', e);
      throw app_exceptions.ServerException(
        message: 'Failed to get user profile: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Convert Supabase auth error to user-friendly message
  String _getSupabaseErrorMessage(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'Email not confirmed':
        return 'Please verify your email address before signing in.';
      case 'User already registered':
        return 'An account with this email already exists. Please sign in instead.';
      case 'Password should be at least 6 characters':
        return 'Password must be at least 6 characters long.';
      case 'Signup requires a valid password':
        return 'Please enter a valid password.';
      case 'Unable to validate email address: invalid format':
        return 'Please enter a valid email address.';
      default:
        return e.message;
    }
  }
}
