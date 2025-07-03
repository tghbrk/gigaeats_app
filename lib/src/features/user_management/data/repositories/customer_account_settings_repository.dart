import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../domain/customer_account_settings.dart';

/// Repository for managing customer account settings
class CustomerAccountSettingsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user's account settings
  Future<CustomerAccountSettings?> getCurrentSettings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      final response = await _supabase
          .from('customer_account_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        // Create default settings if none exist
        return await _createDefaultSettings(user.id);
      }

      return CustomerAccountSettings.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('Database error getting account settings: ${e.message}');
      throw Exception('Failed to load account settings: ${e.message}');
    } catch (e) {
      debugPrint('Error getting account settings: $e');
      throw Exception('Failed to load account settings: $e');
    }
  }

  /// Create default settings for a new user
  Future<CustomerAccountSettings> _createDefaultSettings(String userId) async {
    try {
      final defaultSettings = CustomerAccountSettings.createDefault(userId);
      
      final response = await _supabase
          .from('customer_account_settings')
          .insert(defaultSettings.toJson())
          .select()
          .single();

      return CustomerAccountSettings.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('Database error creating default settings: ${e.message}');
      throw Exception('Failed to create default settings: ${e.message}');
    } catch (e) {
      debugPrint('Error creating default settings: $e');
      throw Exception('Failed to create default settings: $e');
    }
  }

  /// Update account settings
  Future<void> updateSettings(CustomerAccountSettings settings) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      await _supabase
          .from('customer_account_settings')
          .update(settings.toJson())
          .eq('user_id', user.id);

      debugPrint('Account settings updated successfully');
    } on PostgrestException catch (e) {
      debugPrint('Database error updating account settings: ${e.message}');
      throw Exception('Failed to update account settings: ${e.message}');
    } catch (e) {
      debugPrint('Error updating account settings: $e');
      throw Exception('Failed to update account settings: $e');
    }
  }

  /// Delete account settings (for account deletion)
  Future<void> deleteSettings(String userId) async {
    try {
      await _supabase
          .from('customer_account_settings')
          .delete()
          .eq('user_id', userId);

      debugPrint('Account settings deleted successfully');
    } on PostgrestException catch (e) {
      debugPrint('Database error deleting account settings: ${e.message}');
      throw Exception('Failed to delete account settings: ${e.message}');
    } catch (e) {
      debugPrint('Error deleting account settings: $e');
      throw Exception('Failed to delete account settings: $e');
    }
  }

  /// Update only notification preferences
  Future<void> updateNotificationPreferences(
    String userId,
    CustomerNotificationPreferences preferences,
  ) async {
    try {
      await _supabase
          .from('customer_account_settings')
          .update({
            'notification_preferences': preferences.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      debugPrint('Notification preferences updated successfully');
    } on PostgrestException catch (e) {
      debugPrint('Database error updating notification preferences: ${e.message}');
      throw Exception('Failed to update notification preferences: ${e.message}');
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  /// Update only privacy settings
  Future<void> updatePrivacySettings(
    String userId,
    CustomerPrivacySettings privacy,
  ) async {
    try {
      await _supabase
          .from('customer_account_settings')
          .update({
            'privacy_settings': privacy.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      debugPrint('Privacy settings updated successfully');
    } on PostgrestException catch (e) {
      debugPrint('Database error updating privacy settings: ${e.message}');
      throw Exception('Failed to update privacy settings: ${e.message}');
    } catch (e) {
      debugPrint('Error updating privacy settings: $e');
      throw Exception('Failed to update privacy settings: $e');
    }
  }

  /// Update only app preferences
  Future<void> updateAppPreferences(
    String userId,
    CustomerAppPreferences app,
  ) async {
    try {
      await _supabase
          .from('customer_account_settings')
          .update({
            'app_preferences': app.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      debugPrint('App preferences updated successfully');
    } on PostgrestException catch (e) {
      debugPrint('Database error updating app preferences: ${e.message}');
      throw Exception('Failed to update app preferences: ${e.message}');
    } catch (e) {
      debugPrint('Error updating app preferences: $e');
      throw Exception('Failed to update app preferences: $e');
    }
  }

  /// Update only security settings
  Future<void> updateSecuritySettings(
    String userId,
    CustomerSecuritySettings security,
  ) async {
    try {
      await _supabase
          .from('customer_account_settings')
          .update({
            'security_settings': security.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      debugPrint('Security settings updated successfully');
    } on PostgrestException catch (e) {
      debugPrint('Database error updating security settings: ${e.message}');
      throw Exception('Failed to update security settings: ${e.message}');
    } catch (e) {
      debugPrint('Error updating security settings: $e');
      throw Exception('Failed to update security settings: $e');
    }
  }

  /// Check if user has custom settings (not default)
  Future<bool> hasCustomSettings(String userId) async {
    try {
      final response = await _supabase
          .from('customer_account_settings')
          .select('created_at, updated_at')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return false;

      final createdAt = DateTime.parse(response['created_at']);
      final updatedAt = DateTime.parse(response['updated_at']);

      // If updated_at is significantly different from created_at, user has made changes
      return updatedAt.difference(createdAt).inMinutes > 1;
    } catch (e) {
      debugPrint('Error checking custom settings: $e');
      return false;
    }
  }

  /// Reset settings to default values
  Future<void> resetToDefaults(String userId) async {
    try {
      final defaultSettings = CustomerAccountSettings.createDefault(userId);
      
      await _supabase
          .from('customer_account_settings')
          .update(defaultSettings.toJson())
          .eq('user_id', userId);

      debugPrint('Settings reset to defaults successfully');
    } on PostgrestException catch (e) {
      debugPrint('Database error resetting settings: ${e.message}');
      throw Exception('Failed to reset settings: ${e.message}');
    } catch (e) {
      debugPrint('Error resetting settings: $e');
      throw Exception('Failed to reset settings: $e');
    }
  }
}
