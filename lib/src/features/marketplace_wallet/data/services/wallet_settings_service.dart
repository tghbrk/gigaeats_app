import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_settings.dart';
import '../models/spending_limits.dart';

/// Service for managing wallet settings and preferences
class WalletSettingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize wallet settings for a new user
  Future<String> initializeWalletSettings({
    required String walletId,
  }) async {
    try {
      debugPrint('🔍 [WALLET-SETTINGS] Initializing settings for wallet: $walletId');

      final response = await _supabase.functions.invoke(
        'wallet-settings',
        body: {
          'action': 'initialize',
          'wallet_id': walletId,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to initialize wallet settings');
      }

      final settingsId = response.data['data']['settings_id'] as String;

      debugPrint('✅ [WALLET-SETTINGS] Initialized settings: $settingsId');
      return settingsId;
    } catch (e) {
      debugPrint('❌ [WALLET-SETTINGS] Error initializing settings: $e');
      throw Exception('Failed to initialize wallet settings: $e');
    }
  }

  /// Get wallet settings
  Future<WalletSettings> getWalletSettings({
    required String walletId,
  }) async {
    try {
      debugPrint('🔍 [WALLET-SETTINGS] Getting settings for wallet: $walletId');

      final response = await _supabase.functions.invoke(
        'wallet-settings',
        body: {
          'action': 'get',
          'wallet_id': walletId,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to get wallet settings');
      }

      final settings = WalletSettings.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );

      debugPrint('✅ [WALLET-SETTINGS] Retrieved settings successfully');
      return settings;
    } catch (e) {
      debugPrint('❌ [WALLET-SETTINGS] Error getting settings: $e');
      throw Exception('Failed to get wallet settings: $e');
    }
  }

  /// Update wallet settings
  Future<WalletSettings> updateWalletSettings({
    required String walletId,
    required Map<String, dynamic> settingsUpdate,
  }) async {
    try {
      debugPrint('🔍 [WALLET-SETTINGS] Updating settings for wallet: $walletId');

      final response = await _supabase.functions.invoke(
        'wallet-settings',
        body: {
          'action': 'update',
          'wallet_id': walletId,
          'settings': settingsUpdate,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to update wallet settings');
      }

      final updatedSettings = WalletSettings.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );

      debugPrint('✅ [WALLET-SETTINGS] Updated settings successfully');
      return updatedSettings;
    } catch (e) {
      debugPrint('❌ [WALLET-SETTINGS] Error updating settings: $e');
      throw Exception('Failed to update wallet settings: $e');
    }
  }

  /// Get spending limits
  Future<List<SpendingLimit>> getSpendingLimits({
    required String walletId,
  }) async {
    try {
      debugPrint('🔍 [WALLET-SETTINGS] Getting spending limits for wallet: $walletId');

      final response = await _supabase.functions.invoke(
        'wallet-settings',
        body: {
          'action': 'get_spending_limits',
          'wallet_id': walletId,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to get spending limits');
      }

      final limitsData = response.data['data'] as List<dynamic>;
      final limits = limitsData
          .map((json) => SpendingLimit.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [WALLET-SETTINGS] Retrieved ${limits.length} spending limits');
      return limits;
    } catch (e) {
      debugPrint('❌ [WALLET-SETTINGS] Error getting spending limits: $e');
      throw Exception('Failed to get spending limits: $e');
    }
  }

  /// Update spending limits
  Future<List<SpendingLimit>> updateSpendingLimits({
    required String walletId,
    required List<Map<String, dynamic>> limitsUpdate,
  }) async {
    try {
      debugPrint('🔍 [WALLET-SETTINGS] Updating spending limits for wallet: $walletId');

      final response = await _supabase.functions.invoke(
        'wallet-settings',
        body: {
          'action': 'update_spending_limits',
          'wallet_id': walletId,
          'spending_limits': limitsUpdate,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to update spending limits');
      }

      final limitsData = response.data['data'] as List<dynamic>;
      final updatedLimits = limitsData
          .map((json) => SpendingLimit.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [WALLET-SETTINGS] Updated ${updatedLimits.length} spending limits');
      return updatedLimits;
    } catch (e) {
      debugPrint('❌ [WALLET-SETTINGS] Error updating spending limits: $e');
      throw Exception('Failed to update spending limits: $e');
    }
  }

  /// Get notification preferences
  Future<List<Map<String, dynamic>>> getNotificationPreferences({
    required String walletId,
  }) async {
    try {
      debugPrint('🔍 [WALLET-SETTINGS] Getting notification preferences for wallet: $walletId');

      final response = await _supabase.functions.invoke(
        'wallet-settings',
        body: {
          'action': 'get_notifications',
          'wallet_id': walletId,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to get notification preferences');
      }

      final preferences = response.data['data'] as List<dynamic>;
      final preferencesMap = preferences
          .map((json) => json as Map<String, dynamic>)
          .toList();

      debugPrint('✅ [WALLET-SETTINGS] Retrieved ${preferences.length} notification preferences');
      return preferencesMap;
    } catch (e) {
      debugPrint('❌ [WALLET-SETTINGS] Error getting notification preferences: $e');
      throw Exception('Failed to get notification preferences: $e');
    }
  }

  /// Update notification preferences
  Future<List<Map<String, dynamic>>> updateNotificationPreferences({
    required String walletId,
    required List<Map<String, dynamic>> preferencesUpdate,
  }) async {
    try {
      debugPrint('🔍 [WALLET-SETTINGS] Updating notification preferences for wallet: $walletId');

      final response = await _supabase.functions.invoke(
        'wallet-settings',
        body: {
          'action': 'update_notifications',
          'wallet_id': walletId,
          'notification_preferences': preferencesUpdate,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to update notification preferences');
      }

      final preferences = response.data['data'] as List<dynamic>;
      final updatedPreferences = preferences
          .map((json) => json as Map<String, dynamic>)
          .toList();

      debugPrint('✅ [WALLET-SETTINGS] Updated ${updatedPreferences.length} notification preferences');
      return updatedPreferences;
    } catch (e) {
      debugPrint('❌ [WALLET-SETTINGS] Error updating notification preferences: $e');
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  /// Update display preferences
  Future<WalletSettings> updateDisplayPreferences({
    required String walletId,
    String? currencyDisplay,
    bool? showBalanceOnDashboard,
    bool? showRecentTransactions,
    int? transactionHistoryLimit,
  }) async {
    final settingsUpdate = <String, dynamic>{};

    if (currencyDisplay != null) {
      settingsUpdate['currency_display'] = currencyDisplay;
    }
    if (showBalanceOnDashboard != null) {
      settingsUpdate['show_balance_on_dashboard'] = showBalanceOnDashboard;
    }
    if (showRecentTransactions != null) {
      settingsUpdate['show_recent_transactions'] = showRecentTransactions;
    }
    if (transactionHistoryLimit != null) {
      settingsUpdate['transaction_history_limit'] = transactionHistoryLimit;
    }

    return updateWalletSettings(
      walletId: walletId,
      settingsUpdate: settingsUpdate,
    );
  }

  /// Update security preferences
  Future<WalletSettings> updateSecurityPreferences({
    required String walletId,
    bool? requirePinForTransactions,
    bool? requireBiometricForTransactions,
    bool? requireConfirmationForLargeAmounts,
    double? largeAmountThreshold,
    int? autoLockTimeoutMinutes,
  }) async {
    final settingsUpdate = <String, dynamic>{};

    if (requirePinForTransactions != null) {
      settingsUpdate['require_pin_for_transactions'] = requirePinForTransactions;
    }
    if (requireBiometricForTransactions != null) {
      settingsUpdate['require_biometric_for_transactions'] = requireBiometricForTransactions;
    }
    if (requireConfirmationForLargeAmounts != null) {
      settingsUpdate['require_confirmation_for_large_amounts'] = requireConfirmationForLargeAmounts;
    }
    if (largeAmountThreshold != null) {
      settingsUpdate['large_amount_threshold'] = largeAmountThreshold;
    }
    if (autoLockTimeoutMinutes != null) {
      settingsUpdate['auto_lock_timeout_minutes'] = autoLockTimeoutMinutes;
    }

    return updateWalletSettings(
      walletId: walletId,
      settingsUpdate: settingsUpdate,
    );
  }

  /// Update privacy preferences
  Future<WalletSettings> updatePrivacyPreferences({
    required String walletId,
    bool? allowAnalytics,
    bool? allowMarketingNotifications,
    bool? shareTransactionData,
  }) async {
    final settingsUpdate = <String, dynamic>{};

    if (allowAnalytics != null) {
      settingsUpdate['allow_analytics'] = allowAnalytics;
    }
    if (allowMarketingNotifications != null) {
      settingsUpdate['allow_marketing_notifications'] = allowMarketingNotifications;
    }
    if (shareTransactionData != null) {
      settingsUpdate['share_transaction_data'] = shareTransactionData;
    }

    return updateWalletSettings(
      walletId: walletId,
      settingsUpdate: settingsUpdate,
    );
  }

  /// Update auto-reload preferences
  Future<WalletSettings> updateAutoReloadPreferences({
    required String walletId,
    bool? autoReloadEnabled,
    double? autoReloadThreshold,
    double? autoReloadAmount,
    String? autoReloadPaymentMethodId,
  }) async {
    final settingsUpdate = <String, dynamic>{};

    if (autoReloadEnabled != null) {
      settingsUpdate['auto_reload_enabled'] = autoReloadEnabled;
    }
    if (autoReloadThreshold != null) {
      settingsUpdate['auto_reload_threshold'] = autoReloadThreshold;
    }
    if (autoReloadAmount != null) {
      settingsUpdate['auto_reload_amount'] = autoReloadAmount;
    }
    if (autoReloadPaymentMethodId != null) {
      settingsUpdate['auto_reload_payment_method_id'] = autoReloadPaymentMethodId;
    }

    return updateWalletSettings(
      walletId: walletId,
      settingsUpdate: settingsUpdate,
    );
  }

  /// Update spending alert preferences
  Future<WalletSettings> updateSpendingAlertPreferences({
    required String walletId,
    bool? spendingAlertsEnabled,
    double? dailySpendingAlertThreshold,
    double? weeklySpendingAlertThreshold,
    double? monthlySpendingAlertThreshold,
  }) async {
    final settingsUpdate = <String, dynamic>{};

    if (spendingAlertsEnabled != null) {
      settingsUpdate['spending_alerts_enabled'] = spendingAlertsEnabled;
    }
    if (dailySpendingAlertThreshold != null) {
      settingsUpdate['daily_spending_alert_threshold'] = dailySpendingAlertThreshold;
    }
    if (weeklySpendingAlertThreshold != null) {
      settingsUpdate['weekly_spending_alert_threshold'] = weeklySpendingAlertThreshold;
    }
    if (monthlySpendingAlertThreshold != null) {
      settingsUpdate['monthly_spending_alert_threshold'] = monthlySpendingAlertThreshold;
    }

    return updateWalletSettings(
      walletId: walletId,
      settingsUpdate: settingsUpdate,
    );
  }

  /// Validate settings update
  String? validateSettingsUpdate(Map<String, dynamic> settings) {
    // Validate auto-reload settings
    if (settings.containsKey('auto_reload_threshold') && settings.containsKey('auto_reload_amount')) {
      final threshold = settings['auto_reload_threshold'] as double?;
      final amount = settings['auto_reload_amount'] as double?;
      if (threshold != null && amount != null && amount <= threshold) {
        return 'Auto-reload amount must be greater than threshold';
      }
    }

    // Validate large amount threshold
    if (settings.containsKey('large_amount_threshold')) {
      final threshold = settings['large_amount_threshold'] as double?;
      if (threshold != null && threshold <= 0) {
        return 'Large amount threshold must be positive';
      }
    }

    // Validate auto-lock timeout
    if (settings.containsKey('auto_lock_timeout_minutes')) {
      final timeout = settings['auto_lock_timeout_minutes'] as int?;
      if (timeout != null && timeout <= 0) {
        return 'Auto-lock timeout must be positive';
      }
    }

    // Validate transaction history limit
    if (settings.containsKey('transaction_history_limit')) {
      final limit = settings['transaction_history_limit'] as int?;
      if (limit != null && (limit <= 0 || limit > 100)) {
        return 'Transaction history limit must be between 1 and 100';
      }
    }

    return null; // Valid
  }

  /// Get user-friendly error message
  String getErrorMessage(String error) {
    if (error.contains('Wallet not found')) {
      return 'Wallet not found. Please try again.';
    } else if (error.contains('access denied')) {
      return 'You do not have permission to access this wallet.';
    } else if (error.contains('Auto-reload amount must be greater than threshold')) {
      return 'Auto-reload amount must be greater than the threshold amount.';
    } else if (error.contains('Large amount threshold must be positive')) {
      return 'Large amount threshold must be a positive number.';
    } else if (error.contains('Auto-lock timeout must be positive')) {
      return 'Auto-lock timeout must be a positive number.';
    } else if (error.contains('Transaction history limit')) {
      return 'Transaction history limit must be between 1 and 100.';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}
