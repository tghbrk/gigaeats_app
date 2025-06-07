import 'package:supabase_flutter/supabase_flutter.dart';

/// Base repository class providing common functionality for all repositories
abstract class BaseRepository {
  /// Get the Supabase client instance
  SupabaseClient get supabase => Supabase.instance.client;

  /// Get the current authenticated user
  User? get currentUser => supabase.auth.currentUser;

  /// Get the current user's ID
  String? get currentUserId => currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get authenticated client with error handling
  Future<SupabaseClient> getAuthenticatedClient() async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }
    return supabase;
  }

  /// Handle common database errors
  String handleDatabaseError(dynamic error) {
    if (error is PostgrestException) {
      switch (error.code) {
        case '23505':
          return 'A record with this information already exists';
        case '23503':
          return 'Cannot delete this record as it is referenced by other data';
        case '42501':
          return 'You do not have permission to perform this action';
        default:
          return error.message;
      }
    }
    return error.toString();
  }

  /// Execute a query with error handling
  Future<T> executeQuery<T>(Future<T> Function() query) async {
    try {
      return await query();
    } catch (error) {
      throw Exception(handleDatabaseError(error));
    }
  }

  /// Execute a query that returns a list with error handling
  Future<List<T>> executeListQuery<T>(
    Future<List<Map<String, dynamic>>> Function() query,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final data = await query();
      return data.map((item) => fromJson(item)).toList();
    } catch (error) {
      throw Exception(handleDatabaseError(error));
    }
  }

  /// Execute a query that returns a single item with error handling
  Future<T?> executeSingleQuery<T>(
    Future<Map<String, dynamic>?> Function() query,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final data = await query();
      return data != null ? fromJson(data) : null;
    } catch (error) {
      throw Exception(handleDatabaseError(error));
    }
  }
}
