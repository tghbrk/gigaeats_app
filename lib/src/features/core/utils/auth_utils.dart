import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility functions for authentication
class AuthUtils {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if user is authenticated
  static bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Get current user
  static User? get currentUser => _supabase.auth.currentUser;

  /// Get current user ID
  static String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Check if user has a specific role
  static Future<bool> hasRole(String role) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from('user_profiles')
          .select('role')
          .eq('user_id', user.id)
          .maybeSingle();

      return response?['role'] == role;
    } catch (e) {
      return false;
    }
  }

  /// Get user role
  static Future<String?> getUserRole() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('user_profiles')
          .select('role')
          .eq('user_id', user.id)
          .maybeSingle();

      return response?['role'];
    } catch (e) {
      return null;
    }
  }

  /// Check if user is admin
  static Future<bool> isAdmin() async {
    return await hasRole('admin');
  }

  /// Check if user is vendor
  static Future<bool> isVendor() async {
    return await hasRole('vendor');
  }

  /// Check if user is customer
  static Future<bool> isCustomer() async {
    return await hasRole('customer');
  }

  /// Check if user is sales agent
  static Future<bool> isSalesAgent() async {
    return await hasRole('sales_agent');
  }

  /// Check if user is driver
  static Future<bool> isDriver() async {
    return await hasRole('driver');
  }

  /// Get user email
  static String? get userEmail => currentUser?.email;

  /// Check if email is verified
  static bool get isEmailVerified => currentUser?.emailConfirmedAt != null;

  /// Sign out user
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Refresh session
  static Future<void> refreshSession() async {
    await _supabase.auth.refreshSession();
  }

  /// Get user metadata
  static Map<String, dynamic>? get userMetadata => currentUser?.userMetadata;

  /// Update user metadata
  static Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    await _supabase.auth.updateUser(
      UserAttributes(data: metadata),
    );
  }

  /// Check if user can access admin features
  static Future<bool> canAccessAdmin() async {
    return await isAdmin();
  }

  /// Check if user can manage vendors
  static Future<bool> canManageVendors() async {
    final role = await getUserRole();
    return role == 'admin' || role == 'sales_agent';
  }

  /// Check if user can manage orders
  static Future<bool> canManageOrders() async {
    final role = await getUserRole();
    return role == 'admin' || role == 'vendor' || role == 'sales_agent';
  }

  /// Get user display name
  static String get displayName {
    final user = currentUser;
    if (user == null) return 'Guest';
    
    return user.userMetadata?['full_name'] ?? 
           user.email?.split('@').first ?? 
           'User';
  }

  /// Check if user profile is complete
  static Future<bool> isProfileComplete() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from('user_profiles')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return false;

      // Check if required fields are filled
      return response['full_name'] != null && 
             response['phone_number'] != null &&
             response['role'] != null;
    } catch (e) {
      return false;
    }
  }
}
