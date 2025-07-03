import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/logger.dart';
import '../models/stakeholder_wallet.dart';
import '../models/wallet_transaction.dart';
import '../models/payout_request.dart';

class WalletCacheService {
  static const String _walletPrefix = 'wallet_';
  static const String _transactionsPrefix = 'transactions_';
  static const String _payoutsPrefix = 'payouts_';
  static const String _analyticsPrefix = 'analytics_';
  
  static const Duration _defaultCacheDuration = Duration(minutes: 5);
  static const Duration _transactionsCacheDuration = Duration(minutes: 2);
  static const Duration _analyticsCacheDuration = Duration(minutes: 10);

  final AppLogger _logger = AppLogger();
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Cache wallet data
  Future<void> cacheWallet(StakeholderWallet wallet) async {
    try {
      await initialize();
      final key = '$_walletPrefix${wallet.userId}_${wallet.userRole}';
      final data = {
        'wallet': wallet.toJson(),
        'cached_at': DateTime.now().toIso8601String(),
      };
      
      await _prefs!.setString(key, jsonEncode(data));
      debugPrint('💾 [WALLET-CACHE] Cached wallet: ${wallet.id}');
    } catch (e) {
      _logger.error('Failed to cache wallet', e);
    }
  }

  /// Get cached wallet data
  Future<StakeholderWallet?> getCachedWallet(String userId, String userRole) async {
    try {
      await initialize();
      final key = '$_walletPrefix${userId}_$userRole';
      final cachedData = _prefs!.getString(key);
      
      if (cachedData == null) return null;
      
      final data = jsonDecode(cachedData);
      final cachedAt = DateTime.parse(data['cached_at']);
      
      // Check if cache is still valid
      if (DateTime.now().difference(cachedAt) > _defaultCacheDuration) {
        await _prefs!.remove(key);
        return null;
      }
      
      final wallet = StakeholderWallet.fromJson(data['wallet']);
      debugPrint('💾 [WALLET-CACHE] Retrieved cached wallet: ${wallet.id}');
      return wallet;
    } catch (e) {
      _logger.error('Failed to get cached wallet', e);
      return null;
    }
  }

  /// Cache wallet transactions
  Future<void> cacheTransactions(String walletId, List<WalletTransaction> transactions) async {
    try {
      await initialize();
      final key = '$_transactionsPrefix$walletId';
      final data = {
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'cached_at': DateTime.now().toIso8601String(),
      };
      
      await _prefs!.setString(key, jsonEncode(data));
      debugPrint('💾 [WALLET-CACHE] Cached ${transactions.length} transactions for wallet: $walletId');
    } catch (e) {
      _logger.error('Failed to cache transactions', e);
    }
  }

  /// Get cached wallet transactions
  Future<List<WalletTransaction>?> getCachedTransactions(String walletId) async {
    try {
      await initialize();
      final key = '$_transactionsPrefix$walletId';
      final cachedData = _prefs!.getString(key);
      
      if (cachedData == null) return null;
      
      final data = jsonDecode(cachedData);
      final cachedAt = DateTime.parse(data['cached_at']);
      
      // Check if cache is still valid
      if (DateTime.now().difference(cachedAt) > _transactionsCacheDuration) {
        await _prefs!.remove(key);
        return null;
      }
      
      final transactions = (data['transactions'] as List)
          .map((json) => WalletTransaction.fromJson(json))
          .toList();
      
      debugPrint('💾 [WALLET-CACHE] Retrieved ${transactions.length} cached transactions for wallet: $walletId');
      return transactions;
    } catch (e) {
      _logger.error('Failed to get cached transactions', e);
      return null;
    }
  }

  /// Cache payout requests
  Future<void> cachePayoutRequests(String walletId, List<PayoutRequest> payouts) async {
    try {
      await initialize();
      final key = '$_payoutsPrefix$walletId';
      final data = {
        'payouts': payouts.map((p) => p.toJson()).toList(),
        'cached_at': DateTime.now().toIso8601String(),
      };
      
      await _prefs!.setString(key, jsonEncode(data));
      debugPrint('💾 [WALLET-CACHE] Cached ${payouts.length} payout requests for wallet: $walletId');
    } catch (e) {
      _logger.error('Failed to cache payout requests', e);
    }
  }

  /// Get cached payout requests
  Future<List<PayoutRequest>?> getCachedPayoutRequests(String walletId) async {
    try {
      await initialize();
      final key = '$_payoutsPrefix$walletId';
      final cachedData = _prefs!.getString(key);
      
      if (cachedData == null) return null;
      
      final data = jsonDecode(cachedData);
      final cachedAt = DateTime.parse(data['cached_at']);
      
      // Check if cache is still valid
      if (DateTime.now().difference(cachedAt) > _defaultCacheDuration) {
        await _prefs!.remove(key);
        return null;
      }
      
      final payouts = (data['payouts'] as List)
          .map((json) => PayoutRequest.fromJson(json))
          .toList();
      
      debugPrint('💾 [WALLET-CACHE] Retrieved ${payouts.length} cached payout requests for wallet: $walletId');
      return payouts;
    } catch (e) {
      _logger.error('Failed to get cached payout requests', e);
      return null;
    }
  }

  /// Cache wallet analytics
  Future<void> cacheAnalytics(String walletId, Map<String, dynamic> analytics) async {
    try {
      await initialize();
      final key = '$_analyticsPrefix$walletId';
      final data = {
        'analytics': analytics,
        'cached_at': DateTime.now().toIso8601String(),
      };
      
      await _prefs!.setString(key, jsonEncode(data));
      debugPrint('💾 [WALLET-CACHE] Cached analytics for wallet: $walletId');
    } catch (e) {
      _logger.error('Failed to cache analytics', e);
    }
  }

  /// Get cached wallet analytics
  Future<Map<String, dynamic>?> getCachedAnalytics(String walletId) async {
    try {
      await initialize();
      final key = '$_analyticsPrefix$walletId';
      final cachedData = _prefs!.getString(key);
      
      if (cachedData == null) return null;
      
      final data = jsonDecode(cachedData);
      final cachedAt = DateTime.parse(data['cached_at']);
      
      // Check if cache is still valid
      if (DateTime.now().difference(cachedAt) > _analyticsCacheDuration) {
        await _prefs!.remove(key);
        return null;
      }
      
      debugPrint('💾 [WALLET-CACHE] Retrieved cached analytics for wallet: $walletId');
      return data['analytics'];
    } catch (e) {
      _logger.error('Failed to get cached analytics', e);
      return null;
    }
  }

  /// Clear wallet cache
  Future<void> clearWalletCache(String userId, String userRole) async {
    try {
      await initialize();
      final walletKey = '$_walletPrefix${userId}_$userRole';
      await _prefs!.remove(walletKey);
      debugPrint('💾 [WALLET-CACHE] Cleared wallet cache for: $userId ($userRole)');
    } catch (e) {
      _logger.error('Failed to clear wallet cache', e);
    }
  }

  /// Clear transactions cache
  Future<void> clearTransactionsCache(String walletId) async {
    try {
      await initialize();
      final key = '$_transactionsPrefix$walletId';
      await _prefs!.remove(key);
      debugPrint('💾 [WALLET-CACHE] Cleared transactions cache for wallet: $walletId');
    } catch (e) {
      _logger.error('Failed to clear transactions cache', e);
    }
  }

  /// Clear payout requests cache
  Future<void> clearPayoutRequestsCache(String walletId) async {
    try {
      await initialize();
      final key = '$_payoutsPrefix$walletId';
      await _prefs!.remove(key);
      debugPrint('💾 [WALLET-CACHE] Cleared payout requests cache for wallet: $walletId');
    } catch (e) {
      _logger.error('Failed to clear payout requests cache', e);
    }
  }

  /// Clear analytics cache
  Future<void> clearAnalyticsCache(String walletId) async {
    try {
      await initialize();
      final key = '$_analyticsPrefix$walletId';
      await _prefs!.remove(key);
      debugPrint('💾 [WALLET-CACHE] Cleared analytics cache for wallet: $walletId');
    } catch (e) {
      _logger.error('Failed to clear analytics cache', e);
    }
  }

  /// Clear all wallet-related cache
  Future<void> clearAllWalletCache() async {
    try {
      await initialize();
      final keys = _prefs!.getKeys();
      final walletKeys = keys.where((key) => 
          key.startsWith(_walletPrefix) ||
          key.startsWith(_transactionsPrefix) ||
          key.startsWith(_payoutsPrefix) ||
          key.startsWith(_analyticsPrefix)
      ).toList();
      
      for (final key in walletKeys) {
        await _prefs!.remove(key);
      }
      
      debugPrint('💾 [WALLET-CACHE] Cleared all wallet cache (${walletKeys.length} items)');
    } catch (e) {
      _logger.error('Failed to clear all wallet cache', e);
    }
  }

  /// Get cache statistics
  Future<CacheStatistics> getCacheStatistics() async {
    try {
      await initialize();
      final keys = _prefs!.getKeys();
      
      int walletCount = 0;
      int transactionsCount = 0;
      int payoutsCount = 0;
      int analyticsCount = 0;
      
      for (final key in keys) {
        if (key.startsWith(_walletPrefix)) {
          walletCount++;
        } else if (key.startsWith(_transactionsPrefix)) {
          transactionsCount++;
        } else if (key.startsWith(_payoutsPrefix)) {
          payoutsCount++;
        } else if (key.startsWith(_analyticsPrefix)) {
          analyticsCount++;
        }
      }
      
      return CacheStatistics(
        walletCount: walletCount,
        transactionsCount: transactionsCount,
        payoutsCount: payoutsCount,
        analyticsCount: analyticsCount,
        totalItems: walletCount + transactionsCount + payoutsCount + analyticsCount,
      );
    } catch (e) {
      _logger.error('Failed to get cache statistics', e);
      return const CacheStatistics(
        walletCount: 0,
        transactionsCount: 0,
        payoutsCount: 0,
        analyticsCount: 0,
        totalItems: 0,
      );
    }
  }

  /// Check if cache is healthy (not too old)
  Future<bool> isCacheHealthy() async {
    try {
      await initialize();
      final keys = _prefs!.getKeys();
      final walletKeys = keys.where((key) => key.startsWith(_walletPrefix)).toList();
      
      if (walletKeys.isEmpty) return true; // No cache is healthy
      
      // Check if any cache items are too old
      for (final key in walletKeys.take(5)) { // Check first 5 items
        final cachedData = _prefs!.getString(key);
        if (cachedData != null) {
          final data = jsonDecode(cachedData);
          final cachedAt = DateTime.parse(data['cached_at']);
          
          // If any item is older than 1 hour, consider cache unhealthy
          if (DateTime.now().difference(cachedAt) > const Duration(hours: 1)) {
            return false;
          }
        }
      }
      
      return true;
    } catch (e) {
      _logger.error('Failed to check cache health', e);
      return false;
    }
  }
}

/// Cache statistics data class
class CacheStatistics {
  final int walletCount;
  final int transactionsCount;
  final int payoutsCount;
  final int analyticsCount;
  final int totalItems;

  const CacheStatistics({
    required this.walletCount,
    required this.transactionsCount,
    required this.payoutsCount,
    required this.analyticsCount,
    required this.totalItems,
  });

  @override
  String toString() {
    return 'CacheStatistics(wallets: $walletCount, transactions: $transactionsCount, payouts: $payoutsCount, analytics: $analyticsCount, total: $totalItems)';
  }
}
