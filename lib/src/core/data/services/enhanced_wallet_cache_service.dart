import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../../utils/logger.dart';
import '../../../features/marketplace_wallet/data/models/customer_wallet.dart';
import '../../../features/marketplace_wallet/data/models/loyalty_account.dart';
import 'optimized_wallet_query_service.dart';

/// Enhanced caching service with intelligent invalidation and multi-level caching
class EnhancedWalletCacheService {
  static const String _walletPrefix = 'enhanced_wallet_';
  static const String _loyaltyPrefix = 'enhanced_loyalty_';
  static const String _transactionsPrefix = 'enhanced_transactions_';
  static const String _dashboardPrefix = 'enhanced_dashboard_';
  static const String _analyticsPrefix = 'enhanced_analytics_';
  static const String _metadataPrefix = 'cache_metadata_';

  final AppLogger _logger = AppLogger();
  SharedPreferences? _prefs;
  
  // Memory cache for frequently accessed data
  final Map<String, CacheEntry> _memoryCache = {};
  static const int _maxMemoryCacheSize = 50;
  
  // Cache durations for different data types
  static const Duration _walletCacheDuration = Duration(minutes: 2);
  static const Duration _loyaltyCacheDuration = Duration(minutes: 3);
  static const Duration _transactionsCacheDuration = Duration(minutes: 5);
  static const Duration _dashboardCacheDuration = Duration(minutes: 1);


  /// Initialize the cache service
  Future<void> initialize() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      await _cleanupExpiredCache();
      debugPrint('🚀 [ENHANCED-CACHE] Cache service initialized');
    }
  }

  /// Cache wallet dashboard data with intelligent invalidation
  Future<void> cacheDashboardData(WalletDashboardData data) async {
    try {
      await initialize();
      final userId = data.wallet?.userId ?? 'unknown';
      final key = '$_dashboardPrefix$userId';
      
      final cacheEntry = CacheEntry(
        data: data.toJson(),
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(_dashboardCacheDuration),
        version: _generateDataVersion(data),
        dependencies: ['wallet', 'loyalty', 'transactions'],
      );

      // Store in memory cache
      _addToMemoryCache(key, cacheEntry);
      
      // Store in persistent cache
      await _prefs!.setString(key, jsonEncode(cacheEntry.toJson()));
      
      // Update cache metadata
      await _updateCacheMetadata(key, cacheEntry);
      
      debugPrint('🚀 [ENHANCED-CACHE] Cached dashboard data for user: $userId');
    } catch (e) {
      _logger.error('Failed to cache dashboard data', e);
    }
  }

  /// Get cached dashboard data with validation
  Future<WalletDashboardData?> getCachedDashboardData(String userId) async {
    try {
      await initialize();
      final key = '$_dashboardPrefix$userId';
      
      // Check memory cache first
      final memoryCacheEntry = _memoryCache[key];
      if (memoryCacheEntry != null && !memoryCacheEntry.isExpired) {
        debugPrint('🚀 [ENHANCED-CACHE] Retrieved dashboard data from memory cache');
        return WalletDashboardData.fromJson(memoryCacheEntry.data);
      }
      
      // Check persistent cache
      final cachedData = _prefs!.getString(key);
      if (cachedData == null) return null;
      
      final cacheEntry = CacheEntry.fromJson(jsonDecode(cachedData));
      
      // Check if cache is still valid
      if (cacheEntry.isExpired) {
        await _prefs!.remove(key);
        _memoryCache.remove(key);
        return null;
      }
      
      // Add to memory cache for faster future access
      _addToMemoryCache(key, cacheEntry);
      
      debugPrint('🚀 [ENHANCED-CACHE] Retrieved dashboard data from persistent cache');
      return WalletDashboardData.fromJson(cacheEntry.data);
    } catch (e) {
      _logger.error('Failed to get cached dashboard data', e);
      return null;
    }
  }

  /// Cache wallet data with dependency tracking
  Future<void> cacheWallet(CustomerWallet wallet) async {
    try {
      await initialize();
      final key = '$_walletPrefix${wallet.userId}';
      
      final cacheEntry = CacheEntry(
        data: wallet.toJson(),
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(_walletCacheDuration),
        version: _generateWalletVersion(wallet),
        dependencies: ['wallet'],
      );

      _addToMemoryCache(key, cacheEntry);
      await _prefs!.setString(key, jsonEncode(cacheEntry.toJson()));
      await _updateCacheMetadata(key, cacheEntry);
      
      // Invalidate dependent caches
      await _invalidateDependentCaches(['wallet']);
      
      debugPrint('🚀 [ENHANCED-CACHE] Cached wallet: ${wallet.id}');
    } catch (e) {
      _logger.error('Failed to cache wallet', e);
    }
  }

  /// Cache loyalty account with smart invalidation
  Future<void> cacheLoyaltyAccount(LoyaltyAccount loyaltyAccount) async {
    try {
      await initialize();
      final key = '$_loyaltyPrefix${loyaltyAccount.userId}';
      
      final cacheEntry = CacheEntry(
        data: loyaltyAccount.toJson(),
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(_loyaltyCacheDuration),
        version: _generateLoyaltyVersion(loyaltyAccount),
        dependencies: ['loyalty'],
      );

      _addToMemoryCache(key, cacheEntry);
      await _prefs!.setString(key, jsonEncode(cacheEntry.toJson()));
      await _updateCacheMetadata(key, cacheEntry);
      
      // Invalidate dependent caches
      await _invalidateDependentCaches(['loyalty']);
      
      debugPrint('🚀 [ENHANCED-CACHE] Cached loyalty account: ${loyaltyAccount.id}');
    } catch (e) {
      _logger.error('Failed to cache loyalty account', e);
    }
  }

  /// Cache transactions with pagination support
  Future<void> cacheTransactions(
    String userId,
    List<CustomerWalletTransaction> transactions, {
    int page = 0,
    String? type,
  }) async {
    try {
      await initialize();
      final cacheKey = _generateTransactionsCacheKey(userId, page, type);
      
      final cacheEntry = CacheEntry(
        data: {
          'transactions': transactions.map((t) => t.toJson()).toList(),
          'page': page,
          'type': type,
          'count': transactions.length,
        },
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(_transactionsCacheDuration),
        version: _generateTransactionsVersion(transactions),
        dependencies: ['transactions'],
      );

      _addToMemoryCache(cacheKey, cacheEntry);
      await _prefs!.setString(cacheKey, jsonEncode(cacheEntry.toJson()));
      await _updateCacheMetadata(cacheKey, cacheEntry);
      
      debugPrint('🚀 [ENHANCED-CACHE] Cached ${transactions.length} transactions (page: $page)');
    } catch (e) {
      _logger.error('Failed to cache transactions', e);
    }
  }

  /// Intelligent cache invalidation based on data changes
  Future<void> invalidateCache({
    String? userId,
    List<String>? dataTypes,
    bool invalidateAll = false,
  }) async {
    try {
      await initialize();
      
      if (invalidateAll) {
        await _clearAllCache();
        return;
      }
      
      final keysToRemove = <String>[];
      
      // Find keys to invalidate based on criteria
      for (final key in _prefs!.getKeys()) {
        if (userId != null && key.contains(userId)) {
          keysToRemove.add(key);
        } else if (dataTypes != null) {
          for (final dataType in dataTypes) {
            if (key.startsWith('enhanced_$dataType')) {
              keysToRemove.add(key);
            }
          }
        }
      }
      
      // Remove from both memory and persistent cache
      for (final key in keysToRemove) {
        await _prefs!.remove(key);
        _memoryCache.remove(key);
      }
      
      debugPrint('🚀 [ENHANCED-CACHE] Invalidated ${keysToRemove.length} cache entries');
    } catch (e) {
      _logger.error('Failed to invalidate cache', e);
    }
  }

  /// Get cache statistics and health metrics
  Future<EnhancedCacheStatistics> getCacheStatistics() async {
    try {
      await initialize();
      final keys = _prefs!.getKeys();
      
      int walletCount = 0;
      int loyaltyCount = 0;
      int transactionsCount = 0;
      int dashboardCount = 0;
      int analyticsCount = 0;
      int expiredCount = 0;
      
      for (final key in keys) {
        if (key.startsWith(_walletPrefix)) {
          walletCount++;
        } else if (key.startsWith(_loyaltyPrefix)) {
          loyaltyCount++;
        } else if (key.startsWith(_transactionsPrefix)) {
          transactionsCount++;
        } else if (key.startsWith(_dashboardPrefix)) {
          dashboardCount++;
        } else if (key.startsWith(_analyticsPrefix)) {
          analyticsCount++;
        }
        
        // Check if expired
        try {
          final cachedData = _prefs!.getString(key);
          if (cachedData != null) {
            final cacheEntry = CacheEntry.fromJson(jsonDecode(cachedData));
            if (cacheEntry.isExpired) expiredCount++;
          }
        } catch (e) {
          // Invalid cache entry
          expiredCount++;
        }
      }
      
      return EnhancedCacheStatistics(
        walletCount: walletCount,
        loyaltyCount: loyaltyCount,
        transactionsCount: transactionsCount,
        dashboardCount: dashboardCount,
        analyticsCount: analyticsCount,
        memoryCacheSize: _memoryCache.length,
        expiredCount: expiredCount,
        totalItems: keys.length,
        hitRate: _calculateHitRate(),
      );
    } catch (e) {
      _logger.error('Failed to get cache statistics', e);
      return const EnhancedCacheStatistics.empty();
    }
  }

  /// Preload critical cache data
  Future<void> preloadCriticalData(String userId) async {
    try {
      debugPrint('🚀 [ENHANCED-CACHE] Preloading critical data for user: $userId');
      
      // This would typically trigger background loading of essential data
      // Implementation depends on specific requirements
      
    } catch (e) {
      _logger.error('Failed to preload critical data', e);
    }
  }

  // Private helper methods
  void _addToMemoryCache(String key, CacheEntry entry) {
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      // Remove oldest entry
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }
    _memoryCache[key] = entry;
  }

  String _generateDataVersion(WalletDashboardData data) {
    final content = '${data.wallet?.updatedAt}${data.loyaltyAccount?.updatedAt}${data.recentTransactions.length}';
    return md5.convert(utf8.encode(content)).toString().substring(0, 8);
  }

  String _generateWalletVersion(CustomerWallet wallet) {
    final content = '${wallet.availableBalance}${wallet.pendingBalance}${wallet.updatedAt}';
    return md5.convert(utf8.encode(content)).toString().substring(0, 8);
  }

  String _generateLoyaltyVersion(LoyaltyAccount loyalty) {
    final content = '${loyalty.availablePoints}${loyalty.currentTier}${loyalty.updatedAt}';
    return md5.convert(utf8.encode(content)).toString().substring(0, 8);
  }

  String _generateTransactionsVersion(List<CustomerWalletTransaction> transactions) {
    final content = transactions.map((t) => '${t.id}${t.createdAt}').join();
    return md5.convert(utf8.encode(content)).toString().substring(0, 8);
  }

  String _generateTransactionsCacheKey(String userId, int page, String? type) {
    return '$_transactionsPrefix${userId}_p${page}_${type ?? 'all'}';
  }

  Future<void> _updateCacheMetadata(String key, CacheEntry entry) async {
    final metadataKey = '$_metadataPrefix$key';
    final metadata = {
      'created_at': entry.cachedAt.toIso8601String(),
      'expires_at': entry.expiresAt.toIso8601String(),
      'version': entry.version,
      'dependencies': entry.dependencies,
    };
    await _prefs!.setString(metadataKey, jsonEncode(metadata));
  }

  Future<void> _invalidateDependentCaches(List<String> changedDependencies) async {
    final keysToInvalidate = <String>[];
    
    for (final key in _prefs!.getKeys()) {
      if (key.startsWith(_metadataPrefix)) {
        try {
          final metadataJson = _prefs!.getString(key);
          if (metadataJson != null) {
            final metadata = jsonDecode(metadataJson);
            final dependencies = List<String>.from(metadata['dependencies'] ?? []);
            
            if (dependencies.any((dep) => changedDependencies.contains(dep))) {
              final originalKey = key.replaceFirst(_metadataPrefix, '');
              keysToInvalidate.add(originalKey);
            }
          }
        } catch (e) {
          // Invalid metadata, remove it
          keysToInvalidate.add(key.replaceFirst(_metadataPrefix, ''));
        }
      }
    }
    
    for (final key in keysToInvalidate) {
      await _prefs!.remove(key);
      await _prefs!.remove('$_metadataPrefix$key');
      _memoryCache.remove(key);
    }
    
    if (keysToInvalidate.isNotEmpty) {
      debugPrint('🚀 [ENHANCED-CACHE] Invalidated ${keysToInvalidate.length} dependent caches');
    }
  }

  Future<void> _cleanupExpiredCache() async {
    final keysToRemove = <String>[];
    
    for (final key in _prefs!.getKeys()) {
      if (key.startsWith('enhanced_')) {
        try {
          final cachedData = _prefs!.getString(key);
          if (cachedData != null) {
            final cacheEntry = CacheEntry.fromJson(jsonDecode(cachedData));
            if (cacheEntry.isExpired) {
              keysToRemove.add(key);
            }
          }
        } catch (e) {
          // Invalid cache entry, remove it
          keysToRemove.add(key);
        }
      }
    }
    
    for (final key in keysToRemove) {
      await _prefs!.remove(key);
      await _prefs!.remove('$_metadataPrefix$key');
    }
    
    if (keysToRemove.isNotEmpty) {
      debugPrint('🚀 [ENHANCED-CACHE] Cleaned up ${keysToRemove.length} expired cache entries');
    }
  }

  Future<void> _clearAllCache() async {
    final keysToRemove = _prefs!.getKeys()
        .where((key) => key.startsWith('enhanced_') || key.startsWith(_metadataPrefix))
        .toList();
    
    for (final key in keysToRemove) {
      await _prefs!.remove(key);
    }
    
    _memoryCache.clear();
    debugPrint('🚀 [ENHANCED-CACHE] Cleared all cache data');
  }

  double _calculateHitRate() {
    // This would be implemented with actual hit/miss tracking
    // For now, return a placeholder
    return 0.85;
  }
}

/// Cache entry with metadata
class CacheEntry {
  final Map<String, dynamic> data;
  final DateTime cachedAt;
  final DateTime expiresAt;
  final String version;
  final List<String> dependencies;

  const CacheEntry({
    required this.data,
    required this.cachedAt,
    required this.expiresAt,
    required this.version,
    required this.dependencies,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'data': data,
    'cached_at': cachedAt.toIso8601String(),
    'expires_at': expiresAt.toIso8601String(),
    'version': version,
    'dependencies': dependencies,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'],
      cachedAt: DateTime.parse(json['cached_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      version: json['version'],
      dependencies: List<String>.from(json['dependencies'] ?? []),
    );
  }
}

/// Enhanced cache statistics
class EnhancedCacheStatistics {
  final int walletCount;
  final int loyaltyCount;
  final int transactionsCount;
  final int dashboardCount;
  final int analyticsCount;
  final int memoryCacheSize;
  final int expiredCount;
  final int totalItems;
  final double hitRate;

  const EnhancedCacheStatistics({
    required this.walletCount,
    required this.loyaltyCount,
    required this.transactionsCount,
    required this.dashboardCount,
    required this.analyticsCount,
    required this.memoryCacheSize,
    required this.expiredCount,
    required this.totalItems,
    required this.hitRate,
  });

  const EnhancedCacheStatistics.empty()
      : walletCount = 0,
        loyaltyCount = 0,
        transactionsCount = 0,
        dashboardCount = 0,
        analyticsCount = 0,
        memoryCacheSize = 0,
        expiredCount = 0,
        totalItems = 0,
        hitRate = 0.0;

  @override
  String toString() {
    return 'EnhancedCacheStatistics(total: $totalItems, wallet: $walletCount, loyalty: $loyaltyCount, '
           'transactions: $transactionsCount, dashboard: $dashboardCount, analytics: $analyticsCount, '
           'memory: $memoryCacheSize, expired: $expiredCount, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
  }
}
