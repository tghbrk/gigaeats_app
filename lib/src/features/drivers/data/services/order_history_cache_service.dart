import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../orders/data/models/order.dart';
import '../../data/models/grouped_order_history.dart';
import '../../presentation/providers/enhanced_driver_order_history_providers.dart';

/// Advanced caching service specifically for driver order history
class OrderHistoryCacheService {
  static const String _cachePrefix = 'driver_order_history_';
  static const String _metadataPrefix = 'cache_metadata_';
  static const Duration _defaultCacheDuration = Duration(minutes: 15);
  
  static OrderHistoryCacheService? _instance;
  static OrderHistoryCacheService get instance => _instance ??= OrderHistoryCacheService._();
  
  OrderHistoryCacheService._();
  
  SharedPreferences? _prefs;
  final Map<String, CacheEntry<List<Order>>> _memoryCache = {};
  final Map<String, CacheEntry<OrderHistorySummary>> _summaryCache = {};
  final Map<String, CacheEntry<int>> _countCache = {};

  /// Initialize the cache service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _cleanupExpiredEntries();
    debugPrint('🚗 OrderHistoryCacheService: Initialized');
  }

  /// Generate cache key for order history
  String _generateCacheKey(String driverId, DateRangeFilter filter) {
    final startDate = filter.startDate?.toIso8601String() ?? 'null';
    final endDate = filter.endDate?.toIso8601String() ?? 'null';
    return '$_cachePrefix${driverId}_${startDate}_${endDate}_${filter.limit}_${filter.offset}';
  }

  /// Generate cache key for order count
  String _generateCountCacheKey(String driverId, DateRangeFilter filter) {
    final startDate = filter.startDate?.toIso8601String() ?? 'null';
    final endDate = filter.endDate?.toIso8601String() ?? 'null';
    return '${_cachePrefix}count_${driverId}_${startDate}_$endDate';
  }

  /// Generate cache key for summary
  String _generateSummaryCacheKey(String driverId, DateRangeFilter filter) {
    final startDate = filter.startDate?.toIso8601String() ?? 'null';
    final endDate = filter.endDate?.toIso8601String() ?? 'null';
    return '${_cachePrefix}summary_${driverId}_${startDate}_$endDate';
  }

  /// Cache order history data
  Future<void> cacheOrderHistory(
    String driverId,
    DateRangeFilter filter,
    List<Order> orders, {
    Duration? duration,
  }) async {
    try {
      final cacheKey = _generateCacheKey(driverId, filter);
      final expiry = DateTime.now().add(duration ?? _defaultCacheDuration);
      
      // Store in memory cache
      _memoryCache[cacheKey] = CacheEntry(orders, expiry);
      
      // Store in persistent cache
      if (_prefs != null) {
        final cacheData = {
          'data': orders.map((order) => order.toJson()).toList(),
          'expiry': expiry.millisecondsSinceEpoch,
          'driverId': driverId,
          'filter': {
            'startDate': filter.startDate?.toIso8601String(),
            'endDate': filter.endDate?.toIso8601String(),
            'limit': filter.limit,
            'offset': filter.offset,
          },
        };
        
        await _prefs!.setString(cacheKey, jsonEncode(cacheData));
        await _updateCacheMetadata(cacheKey, expiry);
      }
      
      debugPrint('🚗 OrderHistoryCache: Cached ${orders.length} orders for key: $cacheKey');
    } catch (e) {
      debugPrint('🚗 OrderHistoryCache: Error caching orders: $e');
    }
  }

  /// Get cached order history
  Future<List<Order>?> getCachedOrderHistory(
    String driverId,
    DateRangeFilter filter,
  ) async {
    try {
      final cacheKey = _generateCacheKey(driverId, filter);
      
      // Check memory cache first
      final memoryEntry = _memoryCache[cacheKey];
      if (memoryEntry != null && !memoryEntry.isExpired) {
        debugPrint('🚗 OrderHistoryCache: Memory cache hit for key: $cacheKey');
        return memoryEntry.data;
      }
      
      // Check persistent cache
      if (_prefs != null) {
        final cachedString = _prefs!.getString(cacheKey);
        if (cachedString != null) {
          final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
          final expiry = DateTime.fromMillisecondsSinceEpoch(cacheData['expiry'] as int);
          
          if (DateTime.now().isBefore(expiry)) {
            final ordersJson = cacheData['data'] as List<dynamic>;
            final orders = ordersJson
                .map((json) => Order.fromJson(json as Map<String, dynamic>))
                .toList();
            
            // Update memory cache
            _memoryCache[cacheKey] = CacheEntry(orders, expiry);
            
            debugPrint('🚗 OrderHistoryCache: Persistent cache hit for key: $cacheKey');
            return orders;
          } else {
            // Remove expired entry
            await _prefs!.remove(cacheKey);
            await _removeCacheMetadata(cacheKey);
          }
        }
      }
      
      debugPrint('🚗 OrderHistoryCache: Cache miss for key: $cacheKey');
      return null;
    } catch (e) {
      debugPrint('🚗 OrderHistoryCache: Error getting cached orders: $e');
      return null;
    }
  }

  /// Cache order count
  Future<void> cacheOrderCount(
    String driverId,
    DateRangeFilter filter,
    int count, {
    Duration? duration,
  }) async {
    try {
      final cacheKey = _generateCountCacheKey(driverId, filter);
      final expiry = DateTime.now().add(duration ?? _defaultCacheDuration);
      
      _countCache[cacheKey] = CacheEntry(count, expiry);
      
      if (_prefs != null) {
        final cacheData = {
          'count': count,
          'expiry': expiry.millisecondsSinceEpoch,
        };
        await _prefs!.setString(cacheKey, jsonEncode(cacheData));
      }
      
      debugPrint('🚗 OrderHistoryCache: Cached count $count for key: $cacheKey');
    } catch (e) {
      debugPrint('🚗 OrderHistoryCache: Error caching count: $e');
    }
  }

  /// Get cached order count
  Future<int?> getCachedOrderCount(
    String driverId,
    DateRangeFilter filter,
  ) async {
    try {
      final cacheKey = _generateCountCacheKey(driverId, filter);
      
      // Check memory cache first
      final memoryEntry = _countCache[cacheKey];
      if (memoryEntry != null && !memoryEntry.isExpired) {
        return memoryEntry.data;
      }
      
      // Check persistent cache
      if (_prefs != null) {
        final cachedString = _prefs!.getString(cacheKey);
        if (cachedString != null) {
          final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
          final expiry = DateTime.fromMillisecondsSinceEpoch(cacheData['expiry'] as int);
          
          if (DateTime.now().isBefore(expiry)) {
            final count = cacheData['count'] as int;
            _countCache[cacheKey] = CacheEntry(count, expiry);
            return count;
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('🚗 OrderHistoryCache: Error getting cached count: $e');
      return null;
    }
  }

  /// Cache order summary
  Future<void> cacheOrderSummary(
    String driverId,
    DateRangeFilter filter,
    OrderHistorySummary summary, {
    Duration? duration,
  }) async {
    try {
      final cacheKey = _generateSummaryCacheKey(driverId, filter);
      final expiry = DateTime.now().add(duration ?? _defaultCacheDuration);
      
      _summaryCache[cacheKey] = CacheEntry(summary, expiry);
      
      debugPrint('🚗 OrderHistoryCache: Cached summary for key: $cacheKey');
    } catch (e) {
      debugPrint('🚗 OrderHistoryCache: Error caching summary: $e');
    }
  }

  /// Get cached order summary
  OrderHistorySummary? getCachedOrderSummary(
    String driverId,
    DateRangeFilter filter,
  ) {
    try {
      final cacheKey = _generateSummaryCacheKey(driverId, filter);
      final entry = _summaryCache[cacheKey];
      
      if (entry != null && !entry.isExpired) {
        return entry.data;
      }
      
      return null;
    } catch (e) {
      debugPrint('🚗 OrderHistoryCache: Error getting cached summary: $e');
      return null;
    }
  }

  /// Invalidate cache for specific driver
  Future<void> invalidateDriverCache(String driverId) async {
    try {
      // Clear memory caches
      _memoryCache.removeWhere((key, _) => key.contains(driverId));
      _summaryCache.removeWhere((key, _) => key.contains(driverId));
      _countCache.removeWhere((key, _) => key.contains(driverId));
      
      // Clear persistent cache
      if (_prefs != null) {
        final keys = _prefs!.getKeys().where((key) => 
          key.startsWith(_cachePrefix) && key.contains(driverId)
        ).toList();
        
        for (final key in keys) {
          await _prefs!.remove(key);
          await _removeCacheMetadata(key);
        }
      }
      
      debugPrint('🚗 OrderHistoryCache: Invalidated cache for driver: $driverId');
    } catch (e) {
      debugPrint('🚗 OrderHistoryCache: Error invalidating cache: $e');
    }
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    try {
      _memoryCache.clear();
      _summaryCache.clear();
      _countCache.clear();
      
      if (_prefs != null) {
        final keys = _prefs!.getKeys().where((key) => 
          key.startsWith(_cachePrefix)
        ).toList();
        
        for (final key in keys) {
          await _prefs!.remove(key);
        }
        
        await _prefs!.remove('${_metadataPrefix}keys');
      }
      
      debugPrint('🚗 OrderHistoryCache: Cleared all cache');
    } catch (e) {
      debugPrint('🚗 OrderHistoryCache: Error clearing cache: $e');
    }
  }

  /// Update cache metadata for cleanup
  Future<void> _updateCacheMetadata(String key, DateTime expiry) async {
    try {
      if (_prefs == null) return;
      
      final existingKeys = _prefs!.getStringList('${_metadataPrefix}keys') ?? [];
      if (!existingKeys.contains(key)) {
        existingKeys.add(key);
        await _prefs!.setStringList('${_metadataPrefix}keys', existingKeys);
      }
    } catch (e) {
      debugPrint('🚗 OrderHistoryCache: Error updating metadata: $e');
    }
  }

  /// Remove cache metadata
  Future<void> _removeCacheMetadata(String key) async {
    try {
      if (_prefs == null) return;
      
      final existingKeys = _prefs!.getStringList('${_metadataPrefix}keys') ?? [];
      existingKeys.remove(key);
      await _prefs!.setStringList('${_metadataPrefix}keys', existingKeys);
    } catch (e) {
      debugPrint('🚗 OrderHistoryCache: Error removing metadata: $e');
    }
  }

  /// Cleanup expired entries
  Future<void> _cleanupExpiredEntries() async {
    try {
      if (_prefs == null) return;
      
      final keys = _prefs!.getStringList('${_metadataPrefix}keys') ?? [];
      final expiredKeys = <String>[];
      
      for (final key in keys) {
        final cachedString = _prefs!.getString(key);
        if (cachedString != null) {
          try {
            final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
            final expiry = DateTime.fromMillisecondsSinceEpoch(cacheData['expiry'] as int);
            
            if (DateTime.now().isAfter(expiry)) {
              expiredKeys.add(key);
            }
          } catch (e) {
            // Invalid cache entry, mark for removal
            expiredKeys.add(key);
          }
        } else {
          expiredKeys.add(key);
        }
      }
      
      // Remove expired entries
      for (final key in expiredKeys) {
        await _prefs!.remove(key);
        keys.remove(key);
      }
      
      await _prefs!.setStringList('${_metadataPrefix}keys', keys);
      
      if (expiredKeys.isNotEmpty) {
        debugPrint('🚗 OrderHistoryCache: Cleaned up ${expiredKeys.length} expired entries');
      }
    } catch (e) {
      debugPrint('🚗 OrderHistoryCache: Error during cleanup: $e');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'memoryEntries': _memoryCache.length,
      'summaryEntries': _summaryCache.length,
      'countEntries': _countCache.length,
      'persistentEntries': _prefs?.getKeys().where((key) => 
        key.startsWith(_cachePrefix)
      ).length ?? 0,
    };
  }
}

/// Cache entry with expiration
class CacheEntry<T> {
  final T data;
  final DateTime expiry;

  CacheEntry(this.data, this.expiry);

  bool get isExpired => DateTime.now().isAfter(expiry);
}
