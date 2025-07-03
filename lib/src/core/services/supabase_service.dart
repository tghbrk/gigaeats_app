import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import core utilities
import '../utils/logger.dart';

/// Service wrapper around Supabase client for centralized configuration
class SupabaseService {
  final SupabaseClient _client;
  final AppLogger _logger = AppLogger();

  SupabaseService(this._client);

  /// Get the Supabase client
  SupabaseClient get client => _client;

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// Get auth state changes stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _logger.info('🔐 [SUPABASE-SERVICE] Signing in user: $email');
    
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      _logger.info('✅ [SUPABASE-SERVICE] User signed in successfully');
      return response;
    } catch (e) {
      _logger.error('❌ [SUPABASE-SERVICE] Sign in failed: $e');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    _logger.info('📝 [SUPABASE-SERVICE] Signing up user: $email');
    
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      
      _logger.info('✅ [SUPABASE-SERVICE] User signed up successfully');
      return response;
    } catch (e) {
      _logger.error('❌ [SUPABASE-SERVICE] Sign up failed: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _logger.info('🚪 [SUPABASE-SERVICE] Signing out user');
    
    try {
      await _client.auth.signOut();
      _logger.info('✅ [SUPABASE-SERVICE] User signed out successfully');
    } catch (e) {
      _logger.error('❌ [SUPABASE-SERVICE] Sign out failed: $e');
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    _logger.info('🔑 [SUPABASE-SERVICE] Resetting password for: $email');
    
    try {
      await _client.auth.resetPasswordForEmail(email);
      _logger.info('✅ [SUPABASE-SERVICE] Password reset email sent');
    } catch (e) {
      _logger.error('❌ [SUPABASE-SERVICE] Password reset failed: $e');
      rethrow;
    }
  }

  /// Update user password
  Future<UserResponse> updatePassword(String newPassword) async {
    _logger.info('🔐 [SUPABASE-SERVICE] Updating user password');
    
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      _logger.info('✅ [SUPABASE-SERVICE] Password updated successfully');
      return response;
    } catch (e) {
      _logger.error('❌ [SUPABASE-SERVICE] Password update failed: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<UserResponse> updateUserProfile(Map<String, dynamic> data) async {
    _logger.info('👤 [SUPABASE-SERVICE] Updating user profile');
    
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(data: data),
      );
      
      _logger.info('✅ [SUPABASE-SERVICE] Profile updated successfully');
      return response;
    } catch (e) {
      _logger.error('❌ [SUPABASE-SERVICE] Profile update failed: $e');
      rethrow;
    }
  }

  /// Get session
  Session? get session => _client.auth.currentSession;

  /// Refresh session
  Future<AuthResponse> refreshSession() async {
    _logger.info('🔄 [SUPABASE-SERVICE] Refreshing session');
    
    try {
      final response = await _client.auth.refreshSession();
      _logger.info('✅ [SUPABASE-SERVICE] Session refreshed successfully');
      return response;
    } catch (e) {
      _logger.error('❌ [SUPABASE-SERVICE] Session refresh failed: $e');
      rethrow;
    }
  }

  /// Execute database query with error handling
  Future<T> executeQuery<T>(Future<T> Function() query) async {
    try {
      return await query();
    } on PostgrestException catch (e) {
      _logger.error('🗄️ [SUPABASE-SERVICE] Database error: ${e.message}', e);
      throw Exception('Database error: ${e.message}');
    } on AuthException catch (e) {
      _logger.error('🔐 [SUPABASE-SERVICE] Auth error: ${e.message}', e);
      throw Exception('Authentication error: ${e.message}');
    } catch (e) {
      _logger.error('❌ [SUPABASE-SERVICE] Unexpected error: $e', e);
      throw Exception('Unexpected error: $e');
    }
  }

  /// Upload file to storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> fileBytes,
    Map<String, String>? metadata,
  }) async {
    _logger.info('📁 [SUPABASE-SERVICE] Uploading file to $bucket/$path');
    
    try {
      await _client.storage.from(bucket).uploadBinary(
        path,
        Uint8List.fromList(fileBytes),
        fileOptions: FileOptions(
          metadata: metadata,
        ),
      );
      
      final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
      _logger.info('✅ [SUPABASE-SERVICE] File uploaded successfully');
      return publicUrl;
    } catch (e) {
      _logger.error('❌ [SUPABASE-SERVICE] File upload failed: $e');
      rethrow;
    }
  }

  /// Delete file from storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    _logger.info('🗑️ [SUPABASE-SERVICE] Deleting file from $bucket/$path');
    
    try {
      await _client.storage.from(bucket).remove([path]);
      _logger.info('✅ [SUPABASE-SERVICE] File deleted successfully');
    } catch (e) {
      _logger.error('❌ [SUPABASE-SERVICE] File deletion failed: $e');
      rethrow;
    }
  }

  /// Get public URL for file
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  /// Create signed URL for file
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    required int expiresIn,
  }) async {
    _logger.info('🔗 [SUPABASE-SERVICE] Creating signed URL for $bucket/$path');
    
    try {
      final signedUrl = await _client.storage.from(bucket).createSignedUrl(
        path,
        expiresIn,
      );
      
      _logger.info('✅ [SUPABASE-SERVICE] Signed URL created successfully');
      return signedUrl;
    } catch (e) {
      _logger.error('❌ [SUPABASE-SERVICE] Signed URL creation failed: $e');
      rethrow;
    }
  }

  /// Call Edge Function
  Future<FunctionResponse> callFunction({
    required String functionName,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    _logger.info('⚡ [SUPABASE-SERVICE] Calling function: $functionName');
    
    try {
      final response = await _client.functions.invoke(
        functionName,
        body: body,
        headers: headers,
      );
      
      _logger.info('✅ [SUPABASE-SERVICE] Function called successfully');
      return response;
    } catch (e) {
      _logger.error('❌ [SUPABASE-SERVICE] Function call failed: $e');
      rethrow;
    }
  }

  /// Subscribe to real-time changes
  RealtimeChannel subscribeToTable({
    required String table,
    String? filter,
    required void Function(PostgresChangePayload) callback,
  }) {
    _logger.info('👁️ [SUPABASE-SERVICE] Subscribing to table: $table');
    
    final channel = _client.channel('table_$table');
    
    var subscription = channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      callback: callback,
    );

    if (filter != null) {
      // Apply filter if provided
      // Note: This is a simplified example, actual filtering would depend on the specific use case
    }

    subscription.subscribe();
    
    _logger.info('✅ [SUPABASE-SERVICE] Subscribed to table changes');
    return channel;
  }

  /// Unsubscribe from real-time changes
  Future<void> unsubscribe(RealtimeChannel channel) async {
    _logger.info('🔇 [SUPABASE-SERVICE] Unsubscribing from channel');
    
    try {
      await channel.unsubscribe();
      _logger.info('✅ [SUPABASE-SERVICE] Unsubscribed successfully');
    } catch (e) {
      _logger.error('❌ [SUPABASE-SERVICE] Unsubscribe failed: $e');
      rethrow;
    }
  }

  /// Check connection status
  Future<bool> checkConnection() async {
    try {
      await _client.from('health_check').select('1').limit(1);
      return true;
    } catch (e) {
      _logger.warning('⚠️ [SUPABASE-SERVICE] Connection check failed: $e');
      return false;
    }
  }

  /// Get server time
  Future<DateTime> getServerTime() async {
    try {
      final response = await _client.rpc('get_server_time');
      return DateTime.parse(response as String);
    } catch (e) {
      _logger.warning('⚠️ [SUPABASE-SERVICE] Failed to get server time: $e');
      return DateTime.now(); // Fallback to local time
    }
  }
}
