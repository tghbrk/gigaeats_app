import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../orders/data/models/order.dart';
import '../../data/models/grouped_order_history.dart';
import '../../presentation/providers/enhanced_driver_order_history_providers.dart';

/// Enhanced intelligent caching service with performance optimization and analytics
class EnhancedCacheService {
  static const String _cachePrefix = 'enhanced_driver_cache_';
  static const String _metadataPrefix = 'enhanced_metadata_';
  static const String _analyticsPrefix = 'cache_analytics_';
  static const String _prefetchPrefix = 'cache_prefetch_';
  
  // Dynamic cache durations based on data characteristics
  static const Duration _shortCacheDuration = Duration(minutes: 5);   // Recent/today data
  static const Duration _mediumCacheDuration = Duration(minutes: 15); // This week data
  static const Duration _longCacheDuration = Duration(hours: 1);      // Older data
  static const Duration _veryLongCacheDuration = Duration(hours: 4);  // Historical data
  
  // Cache size limits for memory management
  static const int _maxMemoryCacheSize = 100;
  static const int _maxPersistentCacheSize = 500;
  static const int _maxPrefetchCacheSize = 50;
  
  static EnhancedCacheService? _instance;
  static EnhancedCacheService get instance => _instance ??= EnhancedCacheService._();
  
  EnhancedCacheService._();
  
  SharedPreferences? _prefs;
  final Map<String, EnhancedCacheEntry<List<Order>>> _memoryCache = {};
  final Map<String, EnhancedCacheEntry<GroupedOrderHistory>> _summaryCache = {};
  final Map<String, EnhancedCacheEntry<int>> _countCache = {};
  final Map<String, EnhancedCacheEntry<List<Order>>> _prefetchCache = {};
  
  // Analytics and performance tracking
  final Map<String, CacheAnalytics> _cacheAnalytics = {};
  final Map<String, DateTime> _lastAccessTimes = {};
  final Map<String, int> _accessCounts = {};
  
  // Cache warming queue
  final Set<String> _warmingQueue = {};
  bool _isWarming = false;

  /// Initialize the enhanced cache service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadCacheAnalytics();
    await _cleanupExpiredEntries();
    await _initializeCacheWarming();
    debugPrint('🚀 EnhancedCacheService: Initialized with intelligent caching');
  }

  /// Generate intelligent cache key with priority scoring
  String _generateCacheKey(String driverId, DateRangeFilter filter) {
    final startDate = filter.startDate?.toIso8601String() ?? 'null';
    final endDate = filter.endDate?.toIso8601String() ?? 'null';
    final priority = _calculateCachePriority(filter);
    return '$_cachePrefix${driverId}_${startDate}_${endDate}_${filter.limit}_${filter.offset}_p$priority';
  }

  /// Calculate cache priority based on filter characteristics
  int _calculateCachePriority(DateRangeFilter filter) {
    int priority = 5; // Base priority
    
    final now = DateTime.now();
    
    // Higher priority for recent data
    if (filter.startDate != null) {
      final daysDiff = now.difference(filter.startDate!).inDays;
      if (daysDiff <= 1) priority += 5;      // Today/yesterday
      else if (daysDiff <= 7) priority += 3; // This week
      else if (daysDiff <= 30) priority += 1; // This month
    }
    
    // Higher priority for commonly used filters
    if (filter.hasActiveFilter) {
      final range = filter.endDate?.difference(filter.startDate ?? now).inDays ?? 1;
      if (range <= 1) priority += 3;      // Single day
      else if (range <= 7) priority += 2; // Week range
      else if (range <= 30) priority += 1; // Month range
    }
    
    return min(priority, 10); // Cap at 10
  }

  /// Determine optimal cache duration based on data characteristics
  Duration _getOptimalCacheDuration(DateRangeFilter filter) {
    final now = DateTime.now();
    
    // Recent data changes more frequently
    if (filter.startDate != null) {
      final daysDiff = now.difference(filter.startDate!).inDays;
      if (daysDiff <= 1) return _shortCacheDuration;      // Today/yesterday
      else if (daysDiff <= 7) return _mediumCacheDuration; // This week
      else if (daysDiff <= 30) return _longCacheDuration;  // This month
    }
    
    // Historical data can be cached longer
    return _veryLongCacheDuration;
  }

  /// Cache order history with intelligent optimization
  Future<void> cacheOrderHistory(
    String driverId,
    DateRangeFilter filter,
    List<Order> orders, {
    Duration? duration,
    bool isPrefetch = false,
  }) async {
    try {
      final cacheKey = _generateCacheKey(driverId, filter);
      final optimalDuration = duration ?? _getOptimalCacheDuration(filter);
      final expiry = DateTime.now().add(optimalDuration);
      final priority = _calculateCachePriority(filter);
      
      final cacheEntry = EnhancedCacheEntry(
        data: orders,
        expiry: expiry,
        priority: priority,
        accessCount: 0,
        lastAccessed: DateTime.now(),
        dataSize: _calculateDataSize(orders),
        isPrefetched: isPrefetch,
        filterMetadata: _extractFilterMetadata(filter),
      );
      
      // Store in appropriate cache based on type
      if (isPrefetch) {
        _prefetchCache[cacheKey] = cacheEntry;
        _managePrefetchCacheSize();
      } else {
        _memoryCache[cacheKey] = cacheEntry;
        _manageMemoryCacheSize();
      }
      
      // Store in persistent cache for high-priority items
      if (priority >= 7 && _prefs != null) {
        await _storePersistentCache(cacheKey, cacheEntry, orders);
      }
      
      // Update analytics
      _updateCacheAnalytics(cacheKey, 'cache', orders.length);
      
      debugPrint('🚀 EnhancedCache: Cached ${orders.length} orders (priority: $priority, duration: ${optimalDuration.inMinutes}min)');
    } catch (e) {
      debugPrint('🚀 EnhancedCache: Error caching orders: $e');
    }
  }

  /// Get cached order history with intelligent retrieval
  Future<List<Order>?> getCachedOrderHistory(
    String driverId,
    DateRangeFilter filter,
  ) async {
    try {
      final cacheKey = _generateCacheKey(driverId, filter);
      
      // Check memory cache first
      final memoryEntry = _memoryCache[cacheKey];
      if (memoryEntry != null && !memoryEntry.isExpired) {
        _updateAccessMetrics(cacheKey, memoryEntry);
        _updateCacheAnalytics(cacheKey, 'hit_memory', memoryEntry.data.length);
        debugPrint('🚀 EnhancedCache: Memory cache hit for key: $cacheKey');
        return memoryEntry.data;
      }
      
      // Check prefetch cache
      final prefetchEntry = _prefetchCache[cacheKey];
      if (prefetchEntry != null && !prefetchEntry.isExpired) {
        // Move from prefetch to main cache
        _memoryCache[cacheKey] = prefetchEntry.copyWith(isPrefetched: false);
        _prefetchCache.remove(cacheKey);
        
        _updateAccessMetrics(cacheKey, prefetchEntry);
        _updateCacheAnalytics(cacheKey, 'hit_prefetch', prefetchEntry.data.length);
        debugPrint('🚀 EnhancedCache: Prefetch cache hit for key: $cacheKey');
        return prefetchEntry.data;
      }
      
      // Check persistent cache
      if (_prefs != null) {
        final persistentData = await _retrievePersistentCache(cacheKey);
        if (persistentData != null) {
          // Restore to memory cache
          final cacheEntry = EnhancedCacheEntry(
            data: persistentData,
            expiry: DateTime.now().add(_getOptimalCacheDuration(filter)),
            priority: _calculateCachePriority(filter),
            accessCount: 1,
            lastAccessed: DateTime.now(),
            dataSize: _calculateDataSize(persistentData),
            isPrefetched: false,
            filterMetadata: _extractFilterMetadata(filter),
          );
          
          _memoryCache[cacheKey] = cacheEntry;
          _updateCacheAnalytics(cacheKey, 'hit_persistent', persistentData.length);
          debugPrint('🚀 EnhancedCache: Persistent cache hit for key: $cacheKey');
          return persistentData;
        }
      }
      
      // Cache miss
      _updateCacheAnalytics(cacheKey, 'miss', 0);
      debugPrint('🚀 EnhancedCache: Cache miss for key: $cacheKey');
      return null;
    } catch (e) {
      debugPrint('🚀 EnhancedCache: Error getting cached orders: $e');
      return null;
    }
  }

  /// Intelligent cache warming based on usage patterns
  Future<void> warmCache(String driverId, List<QuickDateFilter> commonFilters) async {
    if (_isWarming) return;
    
    _isWarming = true;
    debugPrint('🚀 EnhancedCache: Starting intelligent cache warming for driver: $driverId');
    
    try {
      for (final filter in commonFilters) {
        if (filter.isCommonlyUsed) {
          final dateFilter = filter.toDateRangeFilter();
          final cacheKey = _generateCacheKey(driverId, dateFilter);
          
          // Only warm if not already cached
          if (!_memoryCache.containsKey(cacheKey) && !_prefetchCache.containsKey(cacheKey)) {
            _warmingQueue.add(cacheKey);
          }
        }
      }
      
      debugPrint('🚀 EnhancedCache: Added ${_warmingQueue.length} items to warming queue');
    } finally {
      _isWarming = false;
    }
  }

  /// Get cache performance analytics
  Map<String, dynamic> getCacheAnalytics() {
    final totalHits = _cacheAnalytics.values.fold(0, (sum, analytics) => sum + analytics.hits);
    final totalMisses = _cacheAnalytics.values.fold(0, (sum, analytics) => sum + analytics.misses);
    final hitRate = totalHits + totalMisses > 0 ? (totalHits / (totalHits + totalMisses)) : 0.0;
    
    return {
      'memoryEntries': _memoryCache.length,
      'prefetchEntries': _prefetchCache.length,
      'summaryEntries': _summaryCache.length,
      'countEntries': _countCache.length,
      'totalHits': totalHits,
      'totalMisses': totalMisses,
      'hitRate': hitRate,
      'averageDataSize': _calculateAverageDataSize(),
      'topAccessedKeys': _getTopAccessedKeys(5),
      'cacheEfficiency': _calculateCacheEfficiency(),
    };
  }

  /// Calculate data size for memory management
  int _calculateDataSize(List<Order> orders) {
    // Rough estimation: each order ~1KB
    return orders.length * 1024;
  }

  /// Extract filter metadata for analytics
  Map<String, dynamic> _extractFilterMetadata(DateRangeFilter filter) {
    return {
      'hasDateRange': filter.hasActiveFilter,
      'dayRange': filter.startDate != null && filter.endDate != null 
          ? filter.endDate!.difference(filter.startDate!).inDays 
          : null,
      'limit': filter.limit,
      'offset': filter.offset,
    };
  }

  /// Update access metrics for cache entries
  void _updateAccessMetrics(String cacheKey, EnhancedCacheEntry entry) {
    _lastAccessTimes[cacheKey] = DateTime.now();
    _accessCounts[cacheKey] = (_accessCounts[cacheKey] ?? 0) + 1;
    entry.accessCount++;
    entry.lastAccessed = DateTime.now();
  }

  /// Update cache analytics
  void _updateCacheAnalytics(String cacheKey, String operation, int dataCount) {
    final analytics = _cacheAnalytics[cacheKey] ?? CacheAnalytics();
    
    switch (operation) {
      case 'hit_memory':
      case 'hit_prefetch':
      case 'hit_persistent':
        analytics.hits++;
        break;
      case 'miss':
        analytics.misses++;
        break;
      case 'cache':
        analytics.cacheOperations++;
        break;
    }
    
    analytics.lastOperation = operation;
    analytics.lastOperationTime = DateTime.now();
    analytics.totalDataProcessed += dataCount;
    
    _cacheAnalytics[cacheKey] = analytics;
  }

  /// Manage memory cache size with intelligent eviction
  void _manageMemoryCacheSize() {
    if (_memoryCache.length <= _maxMemoryCacheSize) return;

    // Sort by priority and access patterns for intelligent eviction
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) {
        final aEntry = a.value;
        final bEntry = b.value;

        // Lower priority items first
        final priorityCompare = aEntry.priority.compareTo(bEntry.priority);
        if (priorityCompare != 0) return priorityCompare;

        // Less frequently accessed items first
        final accessCompare = aEntry.accessCount.compareTo(bEntry.accessCount);
        if (accessCompare != 0) return accessCompare;

        // Older items first
        return aEntry.lastAccessed.compareTo(bEntry.lastAccessed);
      });

    // Remove lowest priority items
    final itemsToRemove = _memoryCache.length - _maxMemoryCacheSize + 10; // Remove extra for buffer
    for (int i = 0; i < itemsToRemove && i < sortedEntries.length; i++) {
      _memoryCache.remove(sortedEntries[i].key);
    }

    debugPrint('🚀 EnhancedCache: Evicted $itemsToRemove items from memory cache');
  }

  /// Manage prefetch cache size
  void _managePrefetchCacheSize() {
    if (_prefetchCache.length <= _maxPrefetchCacheSize) return;

    // Remove oldest prefetch entries
    final sortedEntries = _prefetchCache.entries.toList()
      ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));

    final itemsToRemove = _prefetchCache.length - _maxPrefetchCacheSize + 5;
    for (int i = 0; i < itemsToRemove && i < sortedEntries.length; i++) {
      _prefetchCache.remove(sortedEntries[i].key);
    }
  }

  /// Store data in persistent cache
  Future<void> _storePersistentCache(String cacheKey, EnhancedCacheEntry entry, List<Order> orders) async {
    try {
      final cacheData = {
        'data': orders.map((order) => order.toJson()).toList(),
        'expiry': entry.expiry.millisecondsSinceEpoch,
        'priority': entry.priority,
        'accessCount': entry.accessCount,
        'dataSize': entry.dataSize,
        'filterMetadata': entry.filterMetadata,
      };

      await _prefs!.setString(cacheKey, jsonEncode(cacheData));
      await _updatePersistentCacheMetadata(cacheKey, entry);
    } catch (e) {
      debugPrint('🚀 EnhancedCache: Error storing persistent cache: $e');
    }
  }

  /// Retrieve data from persistent cache
  Future<List<Order>?> _retrievePersistentCache(String cacheKey) async {
    try {
      final cachedString = _prefs!.getString(cacheKey);
      if (cachedString != null) {
        final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
        final expiry = DateTime.fromMillisecondsSinceEpoch(cacheData['expiry'] as int);

        if (DateTime.now().isBefore(expiry)) {
          final ordersJson = cacheData['data'] as List<dynamic>;
          return ordersJson
              .map((json) => Order.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          // Remove expired entry
          await _prefs!.remove(cacheKey);
          await _removePersistentCacheMetadata(cacheKey);
        }
      }
    } catch (e) {
      debugPrint('🚀 EnhancedCache: Error retrieving persistent cache: $e');
    }
    return null;
  }

  /// Load cache analytics from persistent storage
  Future<void> _loadCacheAnalytics() async {
    try {
      final analyticsJson = _prefs?.getString('${_analyticsPrefix}data');
      if (analyticsJson != null) {
        final analyticsData = jsonDecode(analyticsJson) as Map<String, dynamic>;
        analyticsData.forEach((key, value) {
          _cacheAnalytics[key] = CacheAnalytics.fromJson(value as Map<String, dynamic>);
        });
        debugPrint('🚀 EnhancedCache: Loaded ${_cacheAnalytics.length} analytics entries');
      }
    } catch (e) {
      debugPrint('🚀 EnhancedCache: Error loading analytics: $e');
    }
  }

  /// Save cache analytics to persistent storage
  Future<void> _saveCacheAnalytics() async {
    try {
      final analyticsData = <String, dynamic>{};
      _cacheAnalytics.forEach((key, analytics) {
        analyticsData[key] = analytics.toJson();
      });

      await _prefs?.setString('${_analyticsPrefix}data', jsonEncode(analyticsData));
    } catch (e) {
      debugPrint('🚀 EnhancedCache: Error saving analytics: $e');
    }
  }

  /// Initialize cache warming based on historical usage
  Future<void> _initializeCacheWarming() async {
    try {
      // Analyze historical usage patterns to determine warming candidates
      final topKeys = _getTopAccessedKeys(10);
      debugPrint('🚀 EnhancedCache: Identified ${topKeys.length} keys for potential warming');
    } catch (e) {
      debugPrint('🚀 EnhancedCache: Error initializing cache warming: $e');
    }
  }

  /// Clean up expired entries from all caches
  Future<void> _cleanupExpiredEntries() async {
    try {
      final now = DateTime.now();

      // Clean memory caches
      _memoryCache.removeWhere((key, entry) => entry.isExpired);
      _prefetchCache.removeWhere((key, entry) => entry.isExpired);
      _summaryCache.removeWhere((key, entry) => entry.isExpired);
      _countCache.removeWhere((key, entry) => entry.isExpired);

      // Clean persistent cache
      if (_prefs != null) {
        final keys = _prefs!.getKeys().where((key) => key.startsWith(_cachePrefix)).toList();
        int expiredCount = 0;

        for (final key in keys) {
          final cachedString = _prefs!.getString(key);
          if (cachedString != null) {
            try {
              final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
              final expiry = DateTime.fromMillisecondsSinceEpoch(cacheData['expiry'] as int);

              if (now.isAfter(expiry)) {
                await _prefs!.remove(key);
                await _removePersistentCacheMetadata(key);
                expiredCount++;
              }
            } catch (e) {
              // Remove corrupted entries
              await _prefs!.remove(key);
              expiredCount++;
            }
          }
        }

        if (expiredCount > 0) {
          debugPrint('🚀 EnhancedCache: Cleaned up $expiredCount expired entries');
        }
      }
    } catch (e) {
      debugPrint('🚀 EnhancedCache: Error during cleanup: $e');
    }
  }

  /// Update persistent cache metadata
  Future<void> _updatePersistentCacheMetadata(String cacheKey, EnhancedCacheEntry entry) async {
    try {
      final metadataKey = '$_metadataPrefix$cacheKey';
      final metadata = {
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': entry.expiry.toIso8601String(),
        'priority': entry.priority,
        'data_size': entry.dataSize,
      };
      await _prefs!.setString(metadataKey, jsonEncode(metadata));
    } catch (e) {
      debugPrint('🚀 EnhancedCache: Error updating metadata: $e');
    }
  }

  /// Remove persistent cache metadata
  Future<void> _removePersistentCacheMetadata(String cacheKey) async {
    try {
      final metadataKey = '$_metadataPrefix$cacheKey';
      await _prefs?.remove(metadataKey);
    } catch (e) {
      debugPrint('🚀 EnhancedCache: Error removing metadata: $e');
    }
  }

  /// Calculate average data size across all cache entries
  double _calculateAverageDataSize() {
    final allEntries = [
      ..._memoryCache.values,
      ..._prefetchCache.values,
      ..._summaryCache.values,
    ];

    if (allEntries.isEmpty) return 0.0;

    final totalSize = allEntries.fold(0, (sum, entry) => sum + entry.dataSize);
    return totalSize / allEntries.length;
  }

  /// Get top accessed cache keys
  List<String> _getTopAccessedKeys(int count) {
    final sortedEntries = _accessCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(count).map((entry) => entry.key).toList();
  }

  /// Calculate cache efficiency score
  double _calculateCacheEfficiency() {
    final analytics = getCacheAnalytics();
    final hitRate = analytics['hitRate'] as double;
    final memoryUtilization = _memoryCache.length / _maxMemoryCacheSize;

    // Efficiency = (hit rate * 0.7) + (memory utilization * 0.3)
    return (hitRate * 0.7) + (memoryUtilization * 0.3);
  }

  /// Invalidate cache for specific driver with intelligent cleanup
  Future<void> invalidateDriverCache(String driverId) async {
    try {
      int removedCount = 0;

      // Clear memory caches
      removedCount += _memoryCache.length;
      _memoryCache.removeWhere((key, _) => key.contains(driverId));
      removedCount -= _memoryCache.length;

      _prefetchCache.removeWhere((key, _) => key.contains(driverId));
      _summaryCache.removeWhere((key, _) => key.contains(driverId));
      _countCache.removeWhere((key, _) => key.contains(driverId));

      // Clear persistent cache
      if (_prefs != null) {
        final keys = _prefs!.getKeys().where((key) =>
          key.startsWith(_cachePrefix) && key.contains(driverId)
        ).toList();

        for (final key in keys) {
          await _prefs!.remove(key);
          await _removePersistentCacheMetadata(key);
        }

        removedCount += keys.length;
      }

      // Clear analytics for this driver
      _cacheAnalytics.removeWhere((key, _) => key.contains(driverId));
      _accessCounts.removeWhere((key, _) => key.contains(driverId));
      _lastAccessTimes.removeWhere((key, _) => key.contains(driverId));

      debugPrint('🚀 EnhancedCache: Invalidated $removedCount cache entries for driver: $driverId');
    } catch (e) {
      debugPrint('🚀 EnhancedCache: Error invalidating cache: $e');
    }
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    await _saveCacheAnalytics();
    _memoryCache.clear();
    _prefetchCache.clear();
    _summaryCache.clear();
    _countCache.clear();
    _cacheAnalytics.clear();
    _accessCounts.clear();
    _lastAccessTimes.clear();
    _warmingQueue.clear();
    debugPrint('🚀 EnhancedCache: Disposed and cleaned up');
  }
}

/// Enhanced cache entry with metadata and analytics
class EnhancedCacheEntry<T> {
  final T data;
  final DateTime expiry;
  final int priority;
  int accessCount;
  DateTime lastAccessed;
  final int dataSize;
  final bool isPrefetched;
  final Map<String, dynamic> filterMetadata;

  EnhancedCacheEntry({
    required this.data,
    required this.expiry,
    required this.priority,
    required this.accessCount,
    required this.lastAccessed,
    required this.dataSize,
    required this.isPrefetched,
    required this.filterMetadata,
  });

  bool get isExpired => DateTime.now().isAfter(expiry);

  EnhancedCacheEntry<T> copyWith({
    T? data,
    DateTime? expiry,
    int? priority,
    int? accessCount,
    DateTime? lastAccessed,
    int? dataSize,
    bool? isPrefetched,
    Map<String, dynamic>? filterMetadata,
  }) {
    return EnhancedCacheEntry<T>(
      data: data ?? this.data,
      expiry: expiry ?? this.expiry,
      priority: priority ?? this.priority,
      accessCount: accessCount ?? this.accessCount,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      dataSize: dataSize ?? this.dataSize,
      isPrefetched: isPrefetched ?? this.isPrefetched,
      filterMetadata: filterMetadata ?? this.filterMetadata,
    );
  }

  @override
  String toString() {
    return 'EnhancedCacheEntry(priority: $priority, accessCount: $accessCount, dataSize: $dataSize, isPrefetched: $isPrefetched)';
  }
}

/// Cache analytics for performance monitoring
class CacheAnalytics {
  int hits;
  int misses;
  int cacheOperations;
  String lastOperation;
  DateTime lastOperationTime;
  int totalDataProcessed;

  CacheAnalytics({
    this.hits = 0,
    this.misses = 0,
    this.cacheOperations = 0,
    this.lastOperation = '',
    DateTime? lastOperationTime,
    this.totalDataProcessed = 0,
  }) : lastOperationTime = lastOperationTime ?? DateTime.now();

  double get hitRate => hits + misses > 0 ? hits / (hits + misses) : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'hits': hits,
      'misses': misses,
      'cacheOperations': cacheOperations,
      'lastOperation': lastOperation,
      'lastOperationTime': lastOperationTime.toIso8601String(),
      'totalDataProcessed': totalDataProcessed,
    };
  }

  factory CacheAnalytics.fromJson(Map<String, dynamic> json) {
    return CacheAnalytics(
      hits: json['hits'] ?? 0,
      misses: json['misses'] ?? 0,
      cacheOperations: json['cacheOperations'] ?? 0,
      lastOperation: json['lastOperation'] ?? '',
      lastOperationTime: json['lastOperationTime'] != null
          ? DateTime.parse(json['lastOperationTime'])
          : DateTime.now(),
      totalDataProcessed: json['totalDataProcessed'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'CacheAnalytics(hits: $hits, misses: $misses, hitRate: ${hitRate.toStringAsFixed(2)})';
  }
}
