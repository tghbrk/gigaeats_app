import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

import '../../../orders/data/models/order.dart';
import '../models/customer_order_history_models.dart';
import 'customer_order_history_service.dart';
import '../../../../core/services/performance_monitor.dart';

/// Advanced lazy loading service for customer orders with performance optimization
class CustomerOrderLazyLoadingService {
  final CustomerOrderHistoryService _orderHistoryService;
  final PerformanceMonitor _performanceMonitor;
  
  // Cache management
  final Map<String, CustomerOrderCache> _cache = {};
  final Queue<String> _cacheKeys = Queue<String>();
  static const int _maxCacheSize = 10;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  // Prefetching configuration
  static const int _prefetchThreshold = 5; // Items remaining before prefetch
  static const int _prefetchBatchSize = 20;
  
  // Performance tracking
  final Map<String, CustomerOrderLoadingMetrics> _loadingMetrics = {};
  
  CustomerOrderLazyLoadingService({
    CustomerOrderHistoryService? orderHistoryService,
    PerformanceMonitor? performanceMonitor,
  }) : _orderHistoryService = orderHistoryService ?? CustomerOrderHistoryService(),
        _performanceMonitor = performanceMonitor ?? PerformanceMonitor();

  /// Load initial batch of orders with performance monitoring
  Future<CustomerOrderLazyLoadResult> loadInitial({
    required String customerId,
    required CustomerDateRangeFilter filter,
  }) async {
    final stopwatch = Stopwatch()..start();
    final tracker = _performanceMonitor.startTracking('lazy_load_initial');
    final cacheKey = _generateCacheKey(customerId, filter);
    
    debugPrint('🚀 LazyLoading: Loading initial batch for customer: $customerId');
    debugPrint('🚀 LazyLoading: Filter: ${filter.toString()}');
    
    try {
      // Check cache first
      final cachedResult = _getCachedResult(cacheKey);
      if (cachedResult != null) {
        debugPrint('🚀 LazyLoading: Cache hit for key: $cacheKey');
        _updateMetrics(cacheKey, stopwatch.elapsedMilliseconds, true);
        return cachedResult;
      }
      
      // Load from service
      final orders = await _orderHistoryService.getCustomerOrderHistory(
        customerId: customerId,
        filter: filter,
      );
      
      final groupedHistory = CustomerGroupedOrderHistory.fromOrders(orders);
      final hasMore = orders.length >= filter.limit;
      
      // Generate cursor for next page
      String? nextCursor;
      if (hasMore && orders.isNotEmpty) {
        final lastOrder = orders.last;
        nextCursor = _generateCursor(lastOrder);
      }
      
      final result = CustomerOrderLazyLoadResult(
        items: groupedHistory,
        hasMore: hasMore,
        nextCursor: nextCursor,
        totalLoaded: orders.length,
        isFromCache: false,
        loadTimeMs: stopwatch.elapsedMilliseconds,
      );
      
      // Cache the result
      _cacheResult(cacheKey, result);
      
      // Start prefetching if needed and we have enough items to warrant it
      if (hasMore && orders.length >= _prefetchThreshold) {
        _schedulePrefetch(customerId, filter, nextCursor);
      }
      
      _updateMetrics(cacheKey, stopwatch.elapsedMilliseconds, false);
      tracker.stop();
      debugPrint('🚀 LazyLoading: Initial load complete - ${orders.length} orders, ${groupedHistory.length} groups');

      return result;
    } catch (e) {
      debugPrint('🚀 LazyLoading: Error in initial load: $e');
      _updateMetrics(cacheKey, stopwatch.elapsedMilliseconds, false, error: e.toString());
      rethrow;
    }
  }

  /// Load next batch with cursor-based pagination
  Future<CustomerOrderLazyLoadResult> loadNext({
    required String customerId,
    required CustomerDateRangeFilter filter,
    required String cursor,
  }) async {
    final stopwatch = Stopwatch()..start();
    final cacheKey = _generateCacheKey(customerId, filter, cursor);
    
    debugPrint('🚀 LazyLoading: Loading next batch with cursor: $cursor');
    
    try {
      // Check cache first
      final cachedResult = _getCachedResult(cacheKey);
      if (cachedResult != null) {
        debugPrint('🚀 LazyLoading: Cache hit for next batch: $cacheKey');
        _updateMetrics(cacheKey, stopwatch.elapsedMilliseconds, true);
        return cachedResult;
      }
      
      // Parse cursor
      final cursorData = _parseCursor(cursor);
      if (cursorData == null) {
        throw Exception('Invalid cursor format');
      }
      
      // Load with cursor pagination
      final orders = await _orderHistoryService.getCustomerOrderHistoryCursorPaginated(
        customerId: customerId,
        filter: filter,
        cursorTimestamp: cursorData['timestamp'],
        cursorId: cursorData['id'],
        direction: 'next',
      );
      
      final groupedHistory = CustomerGroupedOrderHistory.fromOrders(orders);
      final hasMore = orders.length >= filter.limit;
      
      // Generate cursor for next page
      String? nextCursor;
      if (hasMore && orders.isNotEmpty) {
        final lastOrder = orders.last;
        nextCursor = _generateCursor(lastOrder);
      }
      
      final result = CustomerOrderLazyLoadResult(
        items: groupedHistory,
        hasMore: hasMore,
        nextCursor: nextCursor,
        totalLoaded: orders.length,
        isFromCache: false,
        loadTimeMs: stopwatch.elapsedMilliseconds,
      );
      
      // Cache the result
      _cacheResult(cacheKey, result);
      
      // Continue prefetching if needed
      if (hasMore) {
        _schedulePrefetch(customerId, filter, nextCursor);
      }
      
      _updateMetrics(cacheKey, stopwatch.elapsedMilliseconds, false);
      debugPrint('🚀 LazyLoading: Next batch loaded - ${orders.length} orders, ${groupedHistory.length} groups');
      
      return result;
    } catch (e) {
      debugPrint('🚀 LazyLoading: Error loading next batch: $e');
      _updateMetrics(cacheKey, stopwatch.elapsedMilliseconds, false, error: e.toString());
      rethrow;
    }
  }

  /// Prefetch next batch in background
  Future<void> prefetchNext({
    required String customerId,
    required CustomerDateRangeFilter filter,
    String? cursor,
  }) async {
    if (cursor == null) return;
    
    debugPrint('🚀 LazyLoading: Prefetching next batch');
    
    try {
      final cacheKey = _generateCacheKey(customerId, filter, cursor);
      
      // Skip if already cached
      if (_cache.containsKey(cacheKey)) {
        debugPrint('🚀 LazyLoading: Prefetch skipped - already cached');
        return;
      }
      
      // Load in background with prefetch batch size
      final prefetchFilter = filter.copyWith(limit: _prefetchBatchSize);
      await loadNext(
        customerId: customerId,
        filter: prefetchFilter,
        cursor: cursor,
      );
      
      debugPrint('🚀 LazyLoading: Prefetch completed');
    } catch (e) {
      debugPrint('🚀 LazyLoading: Prefetch error: $e');
      // Don't rethrow - prefetch failures shouldn't affect main flow
    }
  }

  /// Clear cache for specific filter or all
  void clearCache([String? filterKey]) {
    if (filterKey != null) {
      _cache.remove(filterKey);
      _cacheKeys.remove(filterKey);
      debugPrint('🚀 LazyLoading: Cleared cache for key: $filterKey');
    } else {
      _cache.clear();
      _cacheKeys.clear();
      debugPrint('🚀 LazyLoading: Cleared all cache');
    }
  }

  /// Get performance metrics
  Map<String, CustomerOrderLoadingMetrics> getPerformanceMetrics() {
    return Map.unmodifiable(_loadingMetrics);
  }

  /// Get cache statistics
  CustomerOrderCacheStats getCacheStats() {
    final totalEntries = _cache.length;
    final totalMemoryKB = _cache.values
        .map((cache) => cache.estimatedSizeKB)
        .fold(0.0, (sum, size) => sum + size);
    
    final hitRate = _loadingMetrics.values.isEmpty
        ? 0.0
        : _loadingMetrics.values
            .map((m) => m.cacheHits)
            .fold(0, (sum, hits) => sum + hits) /
          _loadingMetrics.values
            .map((m) => m.totalRequests)
            .fold(0, (sum, total) => sum + total);
    
    return CustomerOrderCacheStats(
      totalEntries: totalEntries,
      totalMemoryKB: totalMemoryKB,
      hitRate: hitRate,
      maxCacheSize: _maxCacheSize,
    );
  }

  /// Generate cache key
  String _generateCacheKey(String customerId, CustomerDateRangeFilter filter, [String? cursor]) {
    final parts = [
      'customer_orders',
      customerId,
      filter.cacheKey,
      cursor ?? 'initial',
    ];
    return parts.join('_');
  }

  /// Generate cursor from order
  String _generateCursor(Order order) {
    return '${order.createdAt.toIso8601String()}|${order.id}';
  }

  /// Parse cursor
  Map<String, dynamic>? _parseCursor(String cursor) {
    try {
      final parts = cursor.split('|');
      if (parts.length != 2) return null;
      
      return {
        'timestamp': DateTime.parse(parts[0]),
        'id': parts[1],
      };
    } catch (e) {
      debugPrint('🚀 LazyLoading: Error parsing cursor: $e');
      return null;
    }
  }

  /// Get cached result if valid
  CustomerOrderLazyLoadResult? _getCachedResult(String cacheKey) {
    final cached = _cache[cacheKey];
    if (cached == null) return null;
    
    // Check expiry
    if (DateTime.now().difference(cached.timestamp) > _cacheExpiry) {
      _cache.remove(cacheKey);
      _cacheKeys.remove(cacheKey);
      return null;
    }
    
    // Update access time and move to end of queue
    _cacheKeys.remove(cacheKey);
    _cacheKeys.addLast(cacheKey);
    
    return cached.result.copyWith(isFromCache: true);
  }

  /// Cache result with LRU eviction
  void _cacheResult(String cacheKey, CustomerOrderLazyLoadResult result) {
    // Remove if already exists
    if (_cache.containsKey(cacheKey)) {
      _cacheKeys.remove(cacheKey);
    }
    
    // Add to cache
    _cache[cacheKey] = CustomerOrderCache(
      result: result,
      timestamp: DateTime.now(),
      estimatedSizeKB: _estimateResultSize(result),
    );
    _cacheKeys.addLast(cacheKey);
    
    // Evict oldest if over limit
    while (_cacheKeys.length > _maxCacheSize) {
      final oldestKey = _cacheKeys.removeFirst();
      _cache.remove(oldestKey);
    }
  }

  /// Estimate result size in KB
  double _estimateResultSize(CustomerOrderLazyLoadResult result) {
    // Rough estimation: 1KB per order + 0.5KB per group
    return (result.totalLoaded * 1.0) + (result.items.length * 0.5);
  }

  /// Schedule prefetch
  void _schedulePrefetch(String customerId, CustomerDateRangeFilter filter, String? cursor) {
    if (cursor == null) return;
    
    // Schedule prefetch after a short delay to avoid blocking main thread
    Timer(const Duration(milliseconds: 100), () {
      prefetchNext(
        customerId: customerId,
        filter: filter,
        cursor: cursor,
      );
    });
  }

  /// Update performance metrics
  void _updateMetrics(String cacheKey, int loadTimeMs, bool isFromCache, {String? error}) {
    final metrics = _loadingMetrics.putIfAbsent(
      cacheKey,
      () => CustomerOrderLoadingMetrics(cacheKey: cacheKey),
    );
    
    metrics.totalRequests++;
    metrics.totalLoadTimeMs += loadTimeMs;
    
    if (isFromCache) {
      metrics.cacheHits++;
    } else {
      metrics.cacheMisses++;
    }
    
    if (error != null) {
      metrics.errors++;
      metrics.lastError = error;
    }
    
    metrics.lastLoadTimeMs = loadTimeMs;
    metrics.averageLoadTimeMs = metrics.totalLoadTimeMs / metrics.totalRequests;
  }

  /// Dispose resources
  void dispose() {
    clearCache();
    _loadingMetrics.clear();
    debugPrint('🚀 LazyLoading: Service disposed');
  }
}

/// Result model for lazy loading operations
@immutable
class CustomerOrderLazyLoadResult {
  final List<CustomerGroupedOrderHistory> items;
  final bool hasMore;
  final String? nextCursor;
  final int totalLoaded;
  final bool isFromCache;
  final int loadTimeMs;

  const CustomerOrderLazyLoadResult({
    required this.items,
    required this.hasMore,
    this.nextCursor,
    required this.totalLoaded,
    required this.isFromCache,
    required this.loadTimeMs,
  });

  CustomerOrderLazyLoadResult copyWith({
    List<CustomerGroupedOrderHistory>? items,
    bool? hasMore,
    String? nextCursor,
    int? totalLoaded,
    bool? isFromCache,
    int? loadTimeMs,
  }) {
    return CustomerOrderLazyLoadResult(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      totalLoaded: totalLoaded ?? this.totalLoaded,
      isFromCache: isFromCache ?? this.isFromCache,
      loadTimeMs: loadTimeMs ?? this.loadTimeMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerOrderLazyLoadResult &&
          runtimeType == other.runtimeType &&
          listEquals(items, other.items) &&
          hasMore == other.hasMore &&
          nextCursor == other.nextCursor &&
          totalLoaded == other.totalLoaded &&
          isFromCache == other.isFromCache &&
          loadTimeMs == other.loadTimeMs;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(items),
        hasMore,
        nextCursor,
        totalLoaded,
        isFromCache,
        loadTimeMs,
      );

  @override
  String toString() => 'CustomerOrderLazyLoadResult('
      'items: ${items.length} groups, '
      'hasMore: $hasMore, '
      'totalLoaded: $totalLoaded, '
      'isFromCache: $isFromCache, '
      'loadTimeMs: ${loadTimeMs}ms'
      ')';
}

/// Cache entry model
@immutable
class CustomerOrderCache {
  final CustomerOrderLazyLoadResult result;
  final DateTime timestamp;
  final double estimatedSizeKB;

  const CustomerOrderCache({
    required this.result,
    required this.timestamp,
    required this.estimatedSizeKB,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerOrderCache &&
          runtimeType == other.runtimeType &&
          result == other.result &&
          timestamp == other.timestamp &&
          estimatedSizeKB == other.estimatedSizeKB;

  @override
  int get hashCode => Object.hash(result, timestamp, estimatedSizeKB);

  @override
  String toString() => 'CustomerOrderCache('
      'timestamp: $timestamp, '
      'sizeKB: ${estimatedSizeKB.toStringAsFixed(1)}'
      ')';
}

/// Performance metrics model
class CustomerOrderLoadingMetrics {
  final String cacheKey;
  int totalRequests = 0;
  int cacheHits = 0;
  int cacheMisses = 0;
  int errors = 0;
  int totalLoadTimeMs = 0;
  int lastLoadTimeMs = 0;
  double averageLoadTimeMs = 0.0;
  String? lastError;

  CustomerOrderLoadingMetrics({required this.cacheKey});

  double get cacheHitRate => totalRequests == 0 ? 0.0 : cacheHits / totalRequests;
  double get errorRate => totalRequests == 0 ? 0.0 : errors / totalRequests;

  @override
  String toString() => 'CustomerOrderLoadingMetrics('
      'cacheKey: $cacheKey, '
      'requests: $totalRequests, '
      'hitRate: ${(cacheHitRate * 100).toStringAsFixed(1)}%, '
      'avgLoadTime: ${averageLoadTimeMs.toStringAsFixed(0)}ms'
      ')';
}

/// Cache statistics model
@immutable
class CustomerOrderCacheStats {
  final int totalEntries;
  final double totalMemoryKB;
  final double hitRate;
  final int maxCacheSize;

  const CustomerOrderCacheStats({
    required this.totalEntries,
    required this.totalMemoryKB,
    required this.hitRate,
    required this.maxCacheSize,
  });

  double get memoryUsagePercent => maxCacheSize == 0 ? 0.0 : totalEntries / maxCacheSize;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerOrderCacheStats &&
          runtimeType == other.runtimeType &&
          totalEntries == other.totalEntries &&
          totalMemoryKB == other.totalMemoryKB &&
          hitRate == other.hitRate &&
          maxCacheSize == other.maxCacheSize;

  @override
  int get hashCode => Object.hash(totalEntries, totalMemoryKB, hitRate, maxCacheSize);

  @override
  String toString() => 'CustomerOrderCacheStats('
      'entries: $totalEntries/$maxCacheSize, '
      'memory: ${totalMemoryKB.toStringAsFixed(1)}KB, '
      'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%'
      ')';
}
