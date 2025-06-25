import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer_wallet_settings.dart';

/// Service for managing customer wallet settings
class CustomerWalletSettingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get wallet settings for a user
  Future<CustomerWalletSettings> getSettings(String userId) async {
    try {
      // For now, return default settings since Edge Functions don't exist
      // TODO: Implement database-based settings storage
      debugPrint('🔍 [WALLET-SETTINGS-SERVICE] Getting settings for user: $userId');

      // Return default settings
      return CustomerWalletSettings.defaults();
    } catch (e) {
      debugPrint('❌ [WALLET-SETTINGS-SERVICE] Error getting settings: $e');

      // Return default settings on error
      return CustomerWalletSettings.defaults();
    }
  }

  /// Update display settings
  Future<void> updateDisplaySettings(String userId, Map<String, dynamic> updates) async {
    try {
      // For now, just log the update since Edge Functions don't exist
      // TODO: Implement database-based settings storage
      debugPrint('🔍 [WALLET-SETTINGS-SERVICE] Updating display settings for user: $userId');
      debugPrint('🔍 [WALLET-SETTINGS-SERVICE] Updates: $updates');

      // Simulate successful update
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('❌ [WALLET-SETTINGS-SERVICE] Error updating display settings: $e');
      rethrow;
    }
  }

  /// Update security settings
  Future<void> updateSecuritySettings(String userId, Map<String, dynamic> updates) async {
    try {
      // For now, just log the update since Edge Functions don't exist
      // TODO: Implement database-based settings storage
      debugPrint('🔍 [WALLET-SETTINGS-SERVICE] Updating security settings for user: $userId');
      debugPrint('🔍 [WALLET-SETTINGS-SERVICE] Updates: $updates');

      // Simulate successful update
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('❌ [WALLET-SETTINGS-SERVICE] Error updating security settings: $e');
      rethrow;
    }
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(String userId, Map<String, dynamic> updates) async {
    try {
      // For now, just log the update since Edge Functions don't exist
      // TODO: Implement database-based settings storage
      debugPrint('🔍 [WALLET-SETTINGS-SERVICE] Updating notification settings for user: $userId');
      debugPrint('🔍 [WALLET-SETTINGS-SERVICE] Updates: $updates');

      // Simulate successful update
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('❌ [WALLET-SETTINGS-SERVICE] Error updating notification settings: $e');
      rethrow;
    }
  }

  /// Update auto-reload settings
  Future<void> updateAutoReloadSettings(String userId, Map<String, dynamic> updates) async {
    try {
      // For now, just log the update since Edge Functions don't exist
      // TODO: Implement database-based settings storage
      debugPrint('🔍 [WALLET-SETTINGS-SERVICE] Updating auto-reload settings for user: $userId');
      debugPrint('🔍 [WALLET-SETTINGS-SERVICE] Updates: $updates');

      // Simulate successful update
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('❌ [WALLET-SETTINGS-SERVICE] Error updating auto-reload settings: $e');
      rethrow;
    }
  }

  /// Update spending limits
  Future<void> updateSpendingLimits(String userId, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase.functions.invoke(
        'wallet-settings',
        body: {
          'action': 'update_spending_limits',
          'user_id': userId,
          'updates': updates,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to update spending limits');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to update spending limits: ${data['error']}');
      }
    } on FunctionException catch (e) {
      throw Exception('Failed to update spending limits: ${e.details}');
    } catch (e) {
      throw Exception('Failed to update spending limits: ${e.toString()}');
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(String userId, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase.functions.invoke(
        'wallet-settings',
        body: {
          'action': 'update_privacy',
          'user_id': userId,
          'updates': updates,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to update privacy settings');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to update privacy settings: ${data['error']}');
      }
    } on FunctionException catch (e) {
      throw Exception('Failed to update privacy settings: ${e.details}');
    } catch (e) {
      throw Exception('Failed to update privacy settings: ${e.toString()}');
    }
  }

  /// Reset settings to defaults
  Future<void> resetToDefaults(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'wallet-settings',
        body: {
          'action': 'reset_to_defaults',
          'user_id': userId,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to reset settings');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to reset settings: ${data['error']}');
      }
    } on FunctionException catch (e) {
      throw Exception('Failed to reset settings: ${e.details}');
    } catch (e) {
      throw Exception('Failed to reset settings: ${e.toString()}');
    }
  }

  /// Initialize default settings for a new user
  Future<CustomerWalletSettings> initializeSettings(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'wallet-settings',
        body: {
          'action': 'initialize',
          'user_id': userId,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to initialize wallet settings');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to initialize wallet settings: ${data['error']}');
      }

      return CustomerWalletSettings.fromJson(data['settings'] as Map<String, dynamic>);
    } on FunctionException catch (e) {
      throw Exception('Failed to initialize wallet settings: ${e.details}');
    } catch (e) {
      throw Exception('Failed to initialize wallet settings: ${e.toString()}');
    }
  }

  /// Get spending limit status and usage
  Future<Map<String, dynamic>> getSpendingLimitStatus(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-spending-limit-status',
        body: {
          'user_id': userId,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to get spending limit status');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to get spending limit status: ${data['error']}');
      }

      return {
        'daily_spent': (data['daily_spent'] as num?)?.toDouble() ?? 0.0,
        'weekly_spent': (data['weekly_spent'] as num?)?.toDouble() ?? 0.0,
        'monthly_spent': (data['monthly_spent'] as num?)?.toDouble() ?? 0.0,
        'daily_limit': (data['daily_limit'] as num?)?.toDouble(),
        'weekly_limit': (data['weekly_limit'] as num?)?.toDouble(),
        'monthly_limit': (data['monthly_limit'] as num?)?.toDouble(),
        'daily_remaining': (data['daily_remaining'] as num?)?.toDouble(),
        'weekly_remaining': (data['weekly_remaining'] as num?)?.toDouble(),
        'monthly_remaining': (data['monthly_remaining'] as num?)?.toDouble(),
        'daily_percentage': (data['daily_percentage'] as num?)?.toDouble() ?? 0.0,
        'weekly_percentage': (data['weekly_percentage'] as num?)?.toDouble() ?? 0.0,
        'monthly_percentage': (data['monthly_percentage'] as num?)?.toDouble() ?? 0.0,
      };
    } on FunctionException catch (e) {
      throw Exception('Failed to get spending limit status: ${e.details}');
    } catch (e) {
      throw Exception('Failed to get spending limit status: ${e.toString()}');
    }
  }

  /// Check if a transaction would exceed spending limits
  Future<Map<String, dynamic>> checkSpendingLimits(String userId, double amount) async {
    try {
      final response = await _supabase.functions.invoke(
        'check-spending-limits',
        body: {
          'user_id': userId,
          'amount': amount,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to check spending limits');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to check spending limits: ${data['error']}');
      }

      return {
        'allowed': data['allowed'] as bool,
        'exceeded_limits': List<String>.from(data['exceeded_limits'] ?? []),
        'warnings': List<String>.from(data['warnings'] ?? []),
        'remaining_amounts': data['remaining_amounts'] as Map<String, dynamic>? ?? {},
      };
    } on FunctionException catch (e) {
      throw Exception('Failed to check spending limits: ${e.details}');
    } catch (e) {
      throw Exception('Failed to check spending limits: ${e.toString()}');
    }
  }

  /// Export settings for backup or transfer
  Future<Map<String, dynamic>> exportSettings(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'export-wallet-settings',
        body: {
          'user_id': userId,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to export settings');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to export settings: ${data['error']}');
      }

      return data['settings'] as Map<String, dynamic>;
    } on FunctionException catch (e) {
      throw Exception('Failed to export settings: ${e.details}');
    } catch (e) {
      throw Exception('Failed to export settings: ${e.toString()}');
    }
  }

  /// Import settings from backup
  Future<void> importSettings(String userId, Map<String, dynamic> settingsData) async {
    try {
      final response = await _supabase.functions.invoke(
        'import-wallet-settings',
        body: {
          'user_id': userId,
          'settings_data': settingsData,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to import settings');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to import settings: ${data['error']}');
      }
    } on FunctionException catch (e) {
      throw Exception('Failed to import settings: ${e.details}');
    } catch (e) {
      throw Exception('Failed to import settings: ${e.toString()}');
    }
  }
}
