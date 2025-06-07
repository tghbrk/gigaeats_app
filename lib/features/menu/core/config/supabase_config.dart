import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration for menu features
class SupabaseConfig {
  /// Get the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Menu-related table names
  static const String menuItemsTable = 'menu_items';
  static const String menuVersionsTable = 'menu_versions';
  static const String menuItemsVersionedTable = 'menu_items_versioned';
  static const String menuCategoriesTable = 'menu_categories';
  static const String productTable = 'products';

  /// Menu-related RLS policies
  static const String menuItemsPolicy = 'menu_items_policy';
  static const String menuVersionsPolicy = 'menu_versions_policy';

  /// Check if user is authenticated
  static bool get isAuthenticated => client.auth.currentUser != null;

  /// Get current user ID
  static String? get currentUserId => client.auth.currentUser?.id;

  /// Get authenticated client
  static Future<SupabaseClient> getAuthenticatedClient() async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }
    return client;
  }
}
