import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/user.dart' as app_models;
import '../../data/models/user_role.dart';
import '../config/supabase_config.dart';

class AuthSyncService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final SupabaseClient _supabase;

  AuthSyncService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    SupabaseClient? supabase,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _supabase = supabase ?? Supabase.instance.client;

  /// Sync Firebase user to Supabase database directly
  Future<void> syncUserToSupabase(firebase_auth.User firebaseUser) async {
    try {
      debugPrint('AuthSyncService: Starting user sync for ${firebaseUser.uid}');

      // Get Firebase ID token
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Get user role from Firebase custom claims
      final idTokenResult = await firebaseUser.getIdTokenResult();
      final claims = idTokenResult.claims;
      final roleString = claims?['role'] as String?;
      final userRole = roleString != null
          ? UserRole.fromString(roleString)
          : UserRole.salesAgent; // Default role

      // Upsert user data in Supabase
      final userData = {
        'firebase_uid': firebaseUser.uid,
        'email': firebaseUser.email,
        'full_name': firebaseUser.displayName ?? '',
        'phone_number': firebaseUser.phoneNumber,
        'role': userRole.value,
        'is_verified': firebaseUser.emailVerified,
        'is_active': true,
        'profile_image_url': firebaseUser.photoURL,
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint('AuthSyncService: Attempting to upsert user data: $userData');

      // Create an authenticated Supabase client with Firebase token
      final authenticatedClient = _createAuthenticatedClient(idToken);

      final response = await authenticatedClient
          .from('users')
          .upsert(userData, onConflict: 'firebase_uid')
          .select()
          .single();

      debugPrint('AuthSyncService: User synced successfully: ${response['id']}');
    } catch (e) {
      debugPrint('AuthSyncService: Error syncing user: $e');
      rethrow;
    }
  }

  /// Create authenticated Supabase client with Firebase token
  SupabaseClient _createAuthenticatedClient(String idToken) {
    return SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.anonKey,
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );
  }

  /// Get current Firebase user and sync to Supabase
  Future<app_models.User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      // Get Firebase ID token for Supabase requests
      final idToken = await firebaseUser.getIdToken();

      debugPrint('AuthSyncService: Fetching user with Firebase UID: ${firebaseUser.uid}');

      // Create authenticated client for this request
      final authenticatedClient = idToken != null
          ? _createAuthenticatedClient(idToken)
          : _supabase;

      // Fetch user profile from Supabase using authenticated client
      final response = await authenticatedClient
          .from('users')
          .select()
          .eq('firebase_uid', firebaseUser.uid)
          .single();

      debugPrint('AuthSyncService: Successfully fetched user from Supabase');
      return app_models.User.fromJson(response);
    } catch (e) {
      debugPrint('AuthSyncService: Error getting current user: $e');
      return null;
    }
  }

  /// Set user role during registration (temporary workaround for Spark plan)
  Future<void> setUserRole(String firebaseUid, UserRole role) async {
    try {
      // For Spark plan, we'll set the role directly in Supabase
      // This is a temporary workaround until we upgrade to Blaze plan

      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      final client = idToken != null
          ? _createAuthenticatedClient(idToken)
          : _supabase;

      await client
          .from('users')
          .update({
            'role': role.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('firebase_uid', firebaseUid);

      debugPrint('AuthSyncService: User role set to ${role.value}');
    } catch (e) {
      debugPrint('AuthSyncService: Error setting user role: $e');
      rethrow;
    }
  }

  /// Update user role in Firebase custom claims and sync to Supabase
  Future<void> updateUserRole(String firebaseUid, UserRole role) async {
    try {
      // Note: Setting custom claims requires Firebase Admin SDK
      // This would typically be done via a Cloud Function
      // For now, we'll just update Supabase directly

      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      final client = idToken != null
          ? _createAuthenticatedClient(idToken)
          : _supabase;

      await client
          .from('users')
          .update({
            'role': role.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('firebase_uid', firebaseUid);

      debugPrint('AuthSyncService: User role updated to ${role.value}');
    } catch (e) {
      debugPrint('AuthSyncService: Error updating user role: $e');
      rethrow;
    }
  }

  /// Set user verification status (temporary workaround for Spark plan)
  Future<void> setUserVerification(String firebaseUid, bool verified) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      final client = idToken != null
          ? _createAuthenticatedClient(idToken)
          : _supabase;

      await client
          .from('users')
          .update({
            'is_verified': verified,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('firebase_uid', firebaseUid);

      debugPrint('AuthSyncService: User verification set to $verified');
    } catch (e) {
      debugPrint('AuthSyncService: Error setting user verification: $e');
      rethrow;
    }
  }

  /// Get user role from Supabase (temporary workaround for claims)
  Future<UserRole?> getUserRole(String firebaseUid) async {
    try {
      final idToken = await _firebaseAuth.currentUser?.getIdToken();
      final client = idToken != null
          ? _createAuthenticatedClient(idToken)
          : _supabase;

      final response = await client
          .from('users')
          .select('role')
          .eq('firebase_uid', firebaseUid)
          .single();

      final roleString = response['role'] as String?;
      return roleString != null ? UserRole.fromString(roleString) : null;
    } catch (e) {
      debugPrint('AuthSyncService: Error getting user role: $e');
      return null;
    }
  }

  /// Clear Supabase session when user signs out
  Future<void> clearSupabaseSession() async {
    try {
      await _supabase.auth.signOut();
      debugPrint('AuthSyncService: Supabase session cleared');
    } catch (e) {
      debugPrint('AuthSyncService: Error clearing Supabase session: $e');
    }
  }

  /// Ensure Firebase token is valid and set for Supabase
  Future<void> ensureSupabaseAuth() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      final idToken = await firebaseUser.getIdToken();
      if (idToken != null) {
        debugPrint('AuthSyncService: Firebase token available for Supabase auth');
      }
    }
  }
}
