import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../models/user.dart';

/// Remote data source for authentication operations
abstract class AuthDataSource {
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<User> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  });

  Future<void> signOut();
  Future<User?> getCurrentUser();
  Stream<User?> get authStateChanges;
  Future<void> sendPasswordResetEmail(String email);
  Future<void> verifyEmail();
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> deleteAccount();
  Future<String> refreshToken();
  Future<bool> isAuthenticated();
  Future<User> signInWithGoogle();
  Future<User> signInWithApple();
}

/// Implementation of AuthDataSource using Firebase Auth + Supabase
class AuthDataSourceImpl implements AuthDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final SupabaseClient _supabaseClient;
  final AppLogger _logger = AppLogger();

  AuthDataSourceImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    SupabaseClient? supabaseClient,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _supabaseClient = supabaseClient ?? Supabase.instance.client;

  @override
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _logger.info('Attempting to sign in user: $email');

      // Sign in with Firebase
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const AuthException(message: 'Failed to sign in user');
      }

      // Get Firebase ID token
      final idToken = await credential.user!.getIdToken();

      // Sign in with Supabase using Firebase token
      final supabaseResponse = await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.firebase,
        idToken: idToken,
      );

      if (supabaseResponse.user == null) {
        throw const AuthException(message: 'Failed to authenticate with Supabase');
      }

      // Fetch user profile from Supabase
      final userProfile = await _getUserProfile(credential.user!.uid);
      
      _logger.info('User signed in successfully: $email');
      return userProfile;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.error('Firebase auth error during sign in', e);
      throw AuthException(
        message: _getFirebaseErrorMessage(e),
        code: e.code,
        details: e,
      );
    } catch (e) {
      _logger.error('Unexpected error during sign in', e);
      throw AuthException(
        message: 'Failed to sign in: ${e.toString()}',
        details: e,
      );
    }
  }

  @override
  Future<User> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      _logger.info('Attempting to sign up user: $email');

      // Create user with Firebase
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const AuthException(message: 'Failed to create user');
      }

      // Update display name
      await credential.user!.updateDisplayName(fullName);

      // Get Firebase ID token
      final idToken = await credential.user!.getIdToken();

      // Sign in with Supabase using Firebase token
      await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.firebase,
        idToken: idToken,
      );

      // Create user profile in Supabase
      final userProfile = await _createUserProfile(
        firebaseUid: credential.user!.uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      _logger.info('User signed up successfully: $email');
      return userProfile;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.error('Firebase auth error during sign up', e);
      throw AuthException(
        message: _getFirebaseErrorMessage(e),
        code: e.code,
        details: e,
      );
    } catch (e) {
      _logger.error('Unexpected error during sign up', e);
      throw AuthException(
        message: 'Failed to sign up: ${e.toString()}',
        details: e,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      _logger.info('Signing out user');
      
      await Future.wait([
        _firebaseAuth.signOut(),
        _supabaseClient.auth.signOut(),
      ]);

      _logger.info('User signed out successfully');
    } catch (e) {
      _logger.error('Error during sign out', e);
      throw AuthException(
        message: 'Failed to sign out: ${e.toString()}',
        details: e,
      );
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      return await _getUserProfile(firebaseUser.uid);
    } catch (e) {
      _logger.warning('Failed to get current user', e);
      return null;
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      
      try {
        return await _getUserProfile(firebaseUser.uid);
      } catch (e) {
        _logger.warning('Failed to get user profile in auth state stream', e);
        return null;
      }
    });
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _logger.info('Password reset email sent to: $email');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.error('Firebase auth error during password reset', e);
      throw AuthException(
        message: _getFirebaseErrorMessage(e),
        code: e.code,
        details: e,
      );
    } catch (e) {
      _logger.error('Unexpected error during password reset', e);
      throw AuthException(
        message: 'Failed to send password reset email: ${e.toString()}',
        details: e,
      );
    }
  }

  @override
  Future<void> verifyEmail() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException(message: 'No authenticated user found');
      }

      await user.sendEmailVerification();
      _logger.info('Email verification sent');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.error('Firebase auth error during email verification', e);
      throw AuthException(
        message: _getFirebaseErrorMessage(e),
        code: e.code,
        details: e,
      );
    } catch (e) {
      _logger.error('Unexpected error during email verification', e);
      throw AuthException(
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
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException(message: 'No authenticated user found');
      }

      // Re-authenticate user
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      _logger.info('Password updated successfully');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.error('Firebase auth error during password update', e);
      throw AuthException(
        message: _getFirebaseErrorMessage(e),
        code: e.code,
        details: e,
      );
    } catch (e) {
      _logger.error('Unexpected error during password update', e);
      throw AuthException(
        message: 'Failed to update password: ${e.toString()}',
        details: e,
      );
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException(message: 'No authenticated user found');
      }

      // Delete user profile from Supabase
      await _supabaseClient
          .from('users')
          .delete()
          .eq('firebase_uid', user.uid);

      // Delete Firebase user
      await user.delete();
      
      _logger.info('User account deleted successfully');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _logger.error('Firebase auth error during account deletion', e);
      throw AuthException(
        message: _getFirebaseErrorMessage(e),
        code: e.code,
        details: e,
      );
    } catch (e) {
      _logger.error('Unexpected error during account deletion', e);
      throw AuthException(
        message: 'Failed to delete account: ${e.toString()}',
        details: e,
      );
    }
  }

  @override
  Future<String> refreshToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException(message: 'No authenticated user found');
      }

      final token = await user.getIdToken(true); // Force refresh
      _logger.debug('Token refreshed successfully');
      return token;
    } catch (e) {
      _logger.error('Failed to refresh token', e);
      throw AuthException(
        message: 'Failed to refresh token: ${e.toString()}',
        details: e,
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _firebaseAuth.currentUser != null;
  }

  @override
  Future<User> signInWithGoogle() async {
    // TODO: Implement Google Sign In
    throw const AuthException(message: 'Google Sign In not implemented yet');
  }

  @override
  Future<User> signInWithApple() async {
    // TODO: Implement Apple Sign In
    throw const AuthException(message: 'Apple Sign In not implemented yet');
  }

  /// Get user profile from Supabase
  Future<User> _getUserProfile(String firebaseUid) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select()
          .eq('firebase_uid', firebaseUid)
          .single();

      return User.fromJson(response);
    } catch (e) {
      _logger.error('Failed to get user profile from Supabase', e);
      throw ServerException(
        message: 'Failed to get user profile',
        details: e,
      );
    }
  }

  /// Create user profile in Supabase
  Future<User> _createUserProfile({
    required String firebaseUid,
    required String email,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final userData = {
        'firebase_uid': firebaseUid,
        'email': email,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'role': 'customer', // Default role
        'is_verified': false,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabaseClient
          .from('users')
          .insert(userData)
          .select()
          .single();

      return User.fromJson(response);
    } catch (e) {
      _logger.error('Failed to create user profile in Supabase', e);
      throw ServerException(
        message: 'Failed to create user profile',
        details: e,
      );
    }
  }

  /// Convert Firebase auth error to user-friendly message
  String _getFirebaseErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
