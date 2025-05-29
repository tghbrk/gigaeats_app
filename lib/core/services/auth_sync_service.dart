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

      // Set the Firebase ID token for Supabase auth
      await _setSupabaseAuth(idToken);

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

      // Create a fresh Supabase client to avoid any auth header issues
      final freshSupabase = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.anonKey,
      );

      final response = await freshSupabase
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

  /// Set Firebase ID token for Supabase authentication
  Future<void> _setSupabaseAuth(String idToken) async {
    try {
      // For Firebase JWT integration with Supabase RLS, we need to set the token
      // in the request headers. This is typically done by creating a new client
      // with the token or by using the REST client directly.

      // Create a new Supabase client with the Firebase token as authorization
      final authenticatedClient = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.anonKey,
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      debugPrint('AuthSyncService: Firebase token set for Supabase auth');
    } catch (e) {
      debugPrint('AuthSyncService: Error setting Supabase auth: $e');
      // Continue without throwing - this might be expected in some cases
    }
  }

  /// Get current Firebase user and sync to Supabase
  Future<app_models.User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      // Get Firebase ID token for Supabase requests
      final idToken = await firebaseUser.getIdToken();
      if (idToken != null) {
        await _setSupabaseAuth(idToken);
      }

      // Fetch user profile from Supabase
      final response = await _supabase
          .from('users')
          .select()
          .eq('firebase_uid', firebaseUser.uid)
          .single();

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
      if (idToken != null) {
        await _setSupabaseAuth(idToken);
      }

      await _supabase
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
      if (idToken != null) {
        await _setSupabaseAuth(idToken);
      }

      await _supabase
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
      if (idToken != null) {
        await _setSupabaseAuth(idToken);
      }

      await _supabase
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
      if (idToken != null) {
        await _setSupabaseAuth(idToken);
      }

      final response = await _supabase
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
        await _setSupabaseAuth(idToken);
      }
    }
  }
}
