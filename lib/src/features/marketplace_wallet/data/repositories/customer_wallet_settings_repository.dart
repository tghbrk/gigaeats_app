import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';

import '../../../../data/repositories/base_repository.dart';
import '../../../../core/errors/failures.dart';
import '../models/wallet_settings.dart';
import '../models/spending_limits.dart';
import '../models/notification_preferences.dart';

/// Comprehensive repository for customer wallet settings
/// Integrates with the new database schema and Edge Functions
class CustomerWalletSettingsRepository extends BaseRepository {
  CustomerWalletSettingsRepository({
    super.client,
  });

  /// Initialize wallet settings for a user and wallet
  Future<Either<Failure, WalletSettings>> initializeWalletSettings({
    required String walletId,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [WALLET-SETTINGS-REPO] Initializing settings for wallet: $walletId');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await client.functions.invoke(
        'wallet-settings',
        body: {
          'action': 'initialize',
          'wallet_id': walletId,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to initialize wallet settings');
      }

      // Get the initialized settings
      return await getWalletSettings(walletId: walletId).then((result) => 
        result.fold((failure) => throw Exception(failure.message), (settings) => settings!));
    });
  }

  /// Get wallet settings
  Future<Either<Failure, WalletSettings?>> getWalletSettings({
    required String walletId,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [WALLET-SETTINGS-REPO] Getting settings for wallet: $walletId');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await client.functions.invoke(
        'wallet-settings',
        body: {
          'action': 'get',
          'wallet_id': walletId,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to get wallet settings');
      }

      if (response.data['data'] == null) {
        return null;
      }

      final settings = WalletSettings.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );

      debugPrint('✅ [WALLET-SETTINGS-REPO] Retrieved settings successfully');
      return settings;
    });
  }

  /// Update wallet settings
  Future<Either<Failure, WalletSettings>> updateWalletSettings({
    required String walletId,
    required Map<String, dynamic> settingsUpdate,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [WALLET-SETTINGS-REPO] Updating settings for wallet: $walletId');

      final response = await client.functions.invoke(
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

      debugPrint('✅ [WALLET-SETTINGS-REPO] Updated settings successfully');
      return updatedSettings;
    });
  }

  /// Get spending limits
  Future<Either<Failure, List<SpendingLimit>>> getSpendingLimits({
    required String walletId,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [WALLET-SETTINGS-REPO] Getting spending limits for wallet: $walletId');

      final response = await client.functions.invoke(
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

      debugPrint('✅ [WALLET-SETTINGS-REPO] Retrieved ${limits.length} spending limits');
      return limits;
    });
  }

  /// Update spending limits
  Future<Either<Failure, List<SpendingLimit>>> updateSpendingLimits({
    required String walletId,
    required List<Map<String, dynamic>> limitsUpdate,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [WALLET-SETTINGS-REPO] Updating spending limits for wallet: $walletId');

      final response = await client.functions.invoke(
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
      final limits = limitsData
          .map((json) => SpendingLimit.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [WALLET-SETTINGS-REPO] Updated ${limits.length} spending limits');
      return limits;
    });
  }

  /// Get notification preferences
  Future<Either<Failure, List<NotificationPreference>>> getNotificationPreferences({
    required String walletId,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [WALLET-SETTINGS-REPO] Getting notification preferences for wallet: $walletId');

      final response = await client.functions.invoke(
        'wallet-settings',
        body: {
          'action': 'get_notifications',
          'wallet_id': walletId,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to get notification preferences');
      }

      final preferencesData = response.data['data'] as List<dynamic>;
      final preferences = preferencesData
          .map((json) => NotificationPreference.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [WALLET-SETTINGS-REPO] Retrieved ${preferences.length} notification preferences');
      return preferences;
    });
  }

  /// Update notification preferences
  Future<Either<Failure, List<NotificationPreference>>> updateNotificationPreferences({
    required String walletId,
    required List<Map<String, dynamic>> preferencesUpdate,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [WALLET-SETTINGS-REPO] Updating notification preferences for wallet: $walletId');

      final response = await client.functions.invoke(
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

      final preferencesData = response.data['data'] as List<dynamic>;
      final preferences = preferencesData
          .map((json) => NotificationPreference.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [WALLET-SETTINGS-REPO] Updated ${preferences.length} notification preferences');
      return preferences;
    });
  }

  /// Get wallet settings stream for real-time updates
  Stream<WalletSettings?> getWalletSettingsStream({
    required String walletId,
  }) {
    return executeStreamQuery(() {
      debugPrint('🔍 [WALLET-SETTINGS-REPO-STREAM] Setting up wallet settings stream for: $walletId');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        return Stream.error(Exception('User not authenticated'));
      }

      return client
          .from('wallet_settings')
          .stream(primaryKey: ['id'])
          .map((data) {
            // Filter for current user and wallet
            final filtered = data.where((item) =>
                item['user_id'] == currentUser.id &&
                item['wallet_id'] == walletId).toList();

            if (filtered.isEmpty) return null;

            return WalletSettings.fromJson(filtered.first);
          });
    });
  }

  /// Check spending limit for a transaction
  Future<Either<Failure, Map<String, dynamic>>> checkSpendingLimit({
    required String walletId,
    required double transactionAmount,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [WALLET-SETTINGS-REPO] Checking spending limit for amount: $transactionAmount');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await client.rpc('check_spending_limit', params: {
        'p_user_id': currentUser.id,
        'p_wallet_id': walletId,
        'p_transaction_amount': transactionAmount,
      });

      debugPrint('✅ [WALLET-SETTINGS-REPO] Spending limit check completed');
      return response as Map<String, dynamic>;
    });
  }

  /// Update spending limit usage after a transaction
  Future<Either<Failure, void>> updateSpendingLimitUsage({
    required String walletId,
    required double transactionAmount,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [WALLET-SETTINGS-REPO] Updating spending limit usage for amount: $transactionAmount');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await client.rpc('update_spending_limit_usage', params: {
        'p_user_id': currentUser.id,
        'p_wallet_id': walletId,
        'p_transaction_amount': transactionAmount,
      });

      debugPrint('✅ [WALLET-SETTINGS-REPO] Spending limit usage updated');
    });
  }
}
