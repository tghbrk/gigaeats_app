import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../core/utils/logger.dart';
import '../../core/errors/exceptions.dart';

/// Cache service for storing and retrieving data locally
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final AppLogger _logger = AppLogger();
  
  // Cache box names
  static const String _userCacheBox = 'user_cache';
  static const String _vendorCacheBox = 'vendor_cache';
  static const String _orderCacheBox = 'order_cache';
  static const String _menuItemCacheBox = 'menu_item_cache';
  static const String _generalCacheBox = 'general_cache';
  static const String _metadataBox = 'cache_metadata';

  // Cache expiration times
  static const Duration _defaultExpiration = Duration(hours: 1);
  static const Duration _userDataExpiration = Duration(minutes: 30);
  static const Duration _vendorDataExpiration = Duration(hours: 2);
  static const Duration _orderDataExpiration = Duration(minutes: 15);
  static const Duration _menuItemExpiration = Duration(hours: 6);

  late Box<String> _userCache;
  late Box<String> _vendorCache;
  late Box<String> _orderCache;
  late Box<String> _menuItemCache;
  late Box<String> _generalCache;
  late Box<Map<dynamic, dynamic>> _metadataCache;

  bool _isInitialized = false;

  /// Initialize the cache service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();
      
      _userCache = await Hive.openBox<String>(_userCacheBox);
      _vendorCache = await Hive.openBox<String>(_vendorCacheBox);
      _orderCache = await Hive.openBox<String>(_orderCacheBox);
      _menuItemCache = await Hive.openBox<String>(_menuItemCacheBox);
      _generalCache = await Hive.openBox<String>(_generalCacheBox);
      _metadataCache = await Hive.openBox<Map<dynamic, dynamic>>(_metadataBox);

      _isInitialized = true;
      _logger.info('Cache service initialized successfully');

      // Clean expired cache on startup
      await _cleanExpiredCache();
    } catch (e) {
      _logger.error('Failed to initialize cache service', e);
      throw CacheException(message: 'Failed to initialize cache service');
    }
  }

  /// Store data in cache with expiration
  Future<void> store<T>(
    String key,
    T data, {
    Duration? expiration,
    CacheCategory category = CacheCategory.general,
  }) async {
    if (!_isInitialized) await init();

    try {
      final box = _getBoxForCategory(category);
      final expirationTime = expiration ?? _getDefaultExpirationForCategory(category);
      
      // Serialize data
      final serializedData = _serializeData(data);
      
      // Store data
      await box.put(key, serializedData);
      
      // Store metadata
      await _metadataCache.put(key, {
        'category': category.name,
        'expiration': DateTime.now().add(expirationTime).millisecondsSinceEpoch,
        'created': DateTime.now().millisecondsSinceEpoch,
      });

      _logger.debug('Cached data for key: $key in category: ${category.name}');
    } catch (e) {
      _logger.error('Failed to store cache for key: $key', e);
      throw CacheException(message: 'Failed to store cache data');
    }
  }

  /// Retrieve data from cache
  Future<T?> get<T>(String key, {CacheCategory? category}) async {
    if (!_isInitialized) await init();

    try {
      // Check if data exists and is not expired
      if (!await _isValidCache(key)) {
        await _removeExpiredEntry(key);
        return null;
      }

      final metadata = _metadataCache.get(key);
      final dataCategory = category ?? CacheCategory.values.firstWhere(
        (cat) => cat.name == metadata?['category'],
        orElse: () => CacheCategory.general,
      );

      final box = _getBoxForCategory(dataCategory);
      final serializedData = box.get(key);

      if (serializedData == null) return null;

      // Deserialize data
      final data = _deserializeData<T>(serializedData);
      _logger.debug('Retrieved cached data for key: $key');
      
      return data;
    } catch (e) {
      _logger.warning('Failed to retrieve cache for key: $key', e);
      return null;
    }
  }

  /// Remove specific cache entry
  Future<void> remove(String key) async {
    if (!_isInitialized) await init();

    try {
      final metadata = _metadataCache.get(key);
      if (metadata != null) {
        final category = CacheCategory.values.firstWhere(
          (cat) => cat.name == metadata['category'],
          orElse: () => CacheCategory.general,
        );
        
        final box = _getBoxForCategory(category);
        await box.delete(key);
      }
      
      await _metadataCache.delete(key);
      _logger.debug('Removed cache for key: $key');
    } catch (e) {
      _logger.error('Failed to remove cache for key: $key', e);
    }
  }

  /// Clear all cache for a specific category
  Future<void> clearCategory(CacheCategory category) async {
    if (!_isInitialized) await init();

    try {
      final box = _getBoxForCategory(category);
      await box.clear();
      
      // Remove metadata for this category
      final keysToRemove = <String>[];
      for (final key in _metadataCache.keys) {
        final metadata = _metadataCache.get(key);
        if (metadata?['category'] == category.name) {
          keysToRemove.add(key.toString());
        }
      }
      
      for (final key in keysToRemove) {
        await _metadataCache.delete(key);
      }

      _logger.info('Cleared cache for category: ${category.name}');
    } catch (e) {
      _logger.error('Failed to clear cache for category: ${category.name}', e);
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    if (!_isInitialized) await init();

    try {
      await Future.wait([
        _userCache.clear(),
        _vendorCache.clear(),
        _orderCache.clear(),
        _menuItemCache.clear(),
        _generalCache.clear(),
        _metadataCache.clear(),
      ]);

      _logger.info('Cleared all cache');
    } catch (e) {
      _logger.error('Failed to clear all cache', e);
    }
  }

  /// Get cache statistics
  Future<CacheStats> getStats() async {
    if (!_isInitialized) await init();

    try {
      final stats = CacheStats(
        userCacheSize: _userCache.length,
        vendorCacheSize: _vendorCache.length,
        orderCacheSize: _orderCache.length,
        menuItemCacheSize: _menuItemCache.length,
        generalCacheSize: _generalCache.length,
        totalEntries: _metadataCache.length,
      );

      return stats;
    } catch (e) {
      _logger.error('Failed to get cache stats', e);
      return CacheStats.empty();
    }
  }

  /// Check if cache entry is valid (not expired)
  Future<bool> _isValidCache(String key) async {
    final metadata = _metadataCache.get(key);
    if (metadata == null) return false;

    final expiration = metadata['expiration'] as int?;
    if (expiration == null) return false;

    final expirationDate = DateTime.fromMillisecondsSinceEpoch(expiration);
    return DateTime.now().isBefore(expirationDate);
  }

  /// Remove expired cache entry
  Future<void> _removeExpiredEntry(String key) async {
    await remove(key);
    _logger.debug('Removed expired cache entry: $key');
  }

  /// Clean all expired cache entries
  Future<void> _cleanExpiredCache() async {
    try {
      final expiredKeys = <String>[];
      
      for (final key in _metadataCache.keys) {
        if (!await _isValidCache(key.toString())) {
          expiredKeys.add(key.toString());
        }
      }

      for (final key in expiredKeys) {
        await _removeExpiredEntry(key);
      }

      if (expiredKeys.isNotEmpty) {
        _logger.info('Cleaned ${expiredKeys.length} expired cache entries');
      }
    } catch (e) {
      _logger.error('Failed to clean expired cache', e);
    }
  }

  /// Get appropriate box for category
  Box<String> _getBoxForCategory(CacheCategory category) {
    switch (category) {
      case CacheCategory.user:
        return _userCache;
      case CacheCategory.vendor:
        return _vendorCache;
      case CacheCategory.order:
        return _orderCache;
      case CacheCategory.menuItem:
        return _menuItemCache;
      case CacheCategory.general:
        return _generalCache;
    }
  }

  /// Get default expiration for category
  Duration _getDefaultExpirationForCategory(CacheCategory category) {
    switch (category) {
      case CacheCategory.user:
        return _userDataExpiration;
      case CacheCategory.vendor:
        return _vendorDataExpiration;
      case CacheCategory.order:
        return _orderDataExpiration;
      case CacheCategory.menuItem:
        return _menuItemExpiration;
      case CacheCategory.general:
        return _defaultExpiration;
    }
  }

  /// Serialize data to string
  String _serializeData<T>(T data) {
    try {
      return json.encode(data);
    } catch (e) {
      // If JSON encoding fails, convert to string
      return data.toString();
    }
  }

  /// Deserialize data from string
  T? _deserializeData<T>(String serializedData) {
    try {
      final decoded = json.decode(serializedData);
      return decoded as T?;
    } catch (e) {
      // If JSON decoding fails, return as string if T is String
      if (T == String) {
        return serializedData as T?;
      }
      return null;
    }
  }
}

/// Cache categories for better organization
enum CacheCategory {
  user,
  vendor,
  order,
  menuItem,
  general,
}

/// Cache statistics
class CacheStats {
  final int userCacheSize;
  final int vendorCacheSize;
  final int orderCacheSize;
  final int menuItemCacheSize;
  final int generalCacheSize;
  final int totalEntries;

  const CacheStats({
    required this.userCacheSize,
    required this.vendorCacheSize,
    required this.orderCacheSize,
    required this.menuItemCacheSize,
    required this.generalCacheSize,
    required this.totalEntries,
  });

  factory CacheStats.empty() => const CacheStats(
    userCacheSize: 0,
    vendorCacheSize: 0,
    orderCacheSize: 0,
    menuItemCacheSize: 0,
    generalCacheSize: 0,
    totalEntries: 0,
  );

  int get totalSize => userCacheSize + vendorCacheSize + orderCacheSize + menuItemCacheSize + generalCacheSize;
}
