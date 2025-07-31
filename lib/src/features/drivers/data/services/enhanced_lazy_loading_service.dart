import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../orders/data/models/order.dart';
import '../../presentation/providers/enhanced_driver_order_history_providers.dart';
import 'enhanced_cache_service.dart';
import 'optimized_database_service.dart';

/// Enhanced lazy loading service with cursor-based pagination and performance optimization
class EnhancedLazyLoadingService {
  static const int _defaultPageSize = 20;
  static const int _maxPageSize = 100;
  static const int _prefetchThreshold = 5;
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  static const Duration _requestTimeout = Duration(seconds: 30);
  
  static EnhancedLazyLoadingService? _instance;
  static EnhancedLazyLoadingService get instance => _instance ??= EnhancedLazyLoadingService._();
  
  EnhancedLazyLoadingService._();
  
  final Map<String, EnhancedLazyLoadingState> _loadingStates = {};
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, Completer<EnhancedLazyLoadingResult<Order>>> _ongoingRequests = {};
  final Map<String, DateTime> _lastRequestTimes = {};
  
  // Performance monitoring
  final Map<String, List<Duration>> _loadTimes = {};
  final Map<String, int> _cacheHitCounts = {};
  final Map<String, int> _cacheMissCounts = {};

  /// Initialize the enhanced lazy loading service
  Future<void> initialize() async {
    await EnhancedCacheService.instance.initialize();
    debugPrint('🚀 EnhancedLazyLoadingService: Initialized with cursor pagination');
  }

  /// Load orders with enhanced lazy loading and cursor pagination
  Future<EnhancedLazyLoadingResult<Order>> loadOrders({
    required String driverId,
    required DateRangeFilter filter,
    String? cursor,
    bool forceRefresh = false,
    bool prefetch = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final stateKey = _generateStateKey(driverId, filter, cursor);
    
    try {
      // Check for ongoing request
      if (_ongoingRequests.containsKey(stateKey)) {
        debugPrint('🚀 EnhancedLazyLoading: Reusing ongoing request for: $stateKey');
        return await _ongoingRequests[stateKey]!.future;
      }

      // Create completer for this request
      final completer = Completer<EnhancedLazyLoadingResult<Order>>();
      _ongoingRequests[stateKey] = completer;

      // Get or create loading state
      final state = _loadingStates[stateKey] ??= EnhancedLazyLoadingState(
        driverId: driverId,
        filter: filter,
        cursor: cursor,
      );

      // Check cache first (unless force refresh)
      if (!forceRefresh && !prefetch) {
        final cachedResult = await _getCachedResult(driverId, filter, cursor);
        if (cachedResult != null) {
          _recordCacheHit(stateKey);
          completer.complete(cachedResult);
          _ongoingRequests.remove(stateKey);
          stopwatch.stop();
          _recordLoadTime(stateKey, stopwatch.elapsed);
          return cachedResult;
        }
      }

      _recordCacheMiss(stateKey);
      state.isLoading = true;
      
      // Determine optimal page size based on performance history
      final optimalPageSize = _calculateOptimalPageSize(stateKey, filter.limit);
      final optimizedFilter = filter.copyWith(limit: optimalPageSize);

      debugPrint('🚀 EnhancedLazyLoading: Loading orders for: $stateKey (cursor: $cursor, limit: $optimalPageSize)');

      // Use cursor-based pagination for better performance
      final orders = await _fetchOrdersWithCursor(driverId, optimizedFilter, cursor);
      
      // Determine next cursor
      final nextCursor = orders.isNotEmpty ? _generateNextCursor(orders.last) : null;
      final hasMore = orders.length >= optimalPageSize;

      // Create result
      final result = EnhancedLazyLoadingResult<Order>(
        items: orders,
        hasMore: hasMore,
        nextCursor: nextCursor,
        isLoading: false,
        currentPage: _calculateCurrentPage(cursor, optimalPageSize),
        totalLoaded: orders.length,
        fromCache: false,
        loadTime: stopwatch.elapsed,
        cacheKey: stateKey,
      );

      // Update state
      state.isLoading = false;
      state.lastLoadedCount = orders.length;
      state.totalLoaded += orders.length;
      state.hasMore = hasMore;
      state.nextCursor = nextCursor;

      // Cache the results
      await _cacheResult(driverId, filter, cursor, result);

      // Schedule prefetch if conditions are met
      if (!prefetch && hasMore && nextCursor != null) {
        _schedulePrefetch(driverId, filter, nextCursor);
      }

      completer.complete(result);
      stopwatch.stop();
      _recordLoadTime(stateKey, stopwatch.elapsed);
      
      debugPrint('🚀 EnhancedLazyLoading: Loaded ${orders.length} orders in ${stopwatch.elapsedMilliseconds}ms');
      return result;

    } catch (e) {
      stopwatch.stop();
      debugPrint('🚀 EnhancedLazyLoading: Error loading orders: $e');
      
      final errorResult = EnhancedLazyLoadingResult<Order>(
        items: [],
        hasMore: false,
        nextCursor: null,
        isLoading: false,
        currentPage: 1,
        totalLoaded: 0,
        fromCache: false,
        loadTime: stopwatch.elapsed,
        cacheKey: stateKey,
        error: e.toString(),
      );
      
      if (_ongoingRequests.containsKey(stateKey)) {
        _ongoingRequests[stateKey]!.complete(errorResult);
      }
      
      return errorResult;
    } finally {
      _ongoingRequests.remove(stateKey);
    }
  }

  /// Load more orders (next page)
  Future<EnhancedLazyLoadingResult<Order>> loadMore({
    required String driverId,
    required DateRangeFilter currentFilter,
    required String? currentCursor,
  }) async {
    final stateKey = _generateStateKey(driverId, currentFilter, currentCursor);
    final state = _loadingStates[stateKey];
    
    if (state == null || !state.hasMore || state.isLoading) {
      return EnhancedLazyLoadingResult<Order>(
        items: [],
        hasMore: state?.hasMore ?? false,
        nextCursor: state?.nextCursor,
        isLoading: state?.isLoading ?? false,
        currentPage: _calculateCurrentPage(currentCursor, currentFilter.limit),
        totalLoaded: state?.totalLoaded ?? 0,
        fromCache: false,
        loadTime: Duration.zero,
        cacheKey: stateKey,
      );
    }

    return loadOrders(
      driverId: driverId,
      filter: currentFilter,
      cursor: state.nextCursor,
    );
  }

  /// Prefetch next page of data
  Future<void> prefetchNextPage({
    required String driverId,
    required DateRangeFilter currentFilter,
    required String? currentCursor,
  }) async {
    final stateKey = _generateStateKey(driverId, currentFilter, currentCursor);
    final state = _loadingStates[stateKey];
    
    if (state?.nextCursor == null) return;

    try {
      await loadOrders(
        driverId: driverId,
        filter: currentFilter,
        cursor: state!.nextCursor,
        prefetch: true,
      );
      debugPrint('🚀 EnhancedLazyLoading: Prefetched next page successfully');
    } catch (e) {
      debugPrint('🚀 EnhancedLazyLoading: Prefetch failed: $e');
    }
  }

  /// Check if should load more based on current position
  bool shouldLoadMore({
    required String driverId,
    required DateRangeFilter filter,
    required String? cursor,
    required int currentIndex,
    required int totalItems,
  }) {
    final stateKey = _generateStateKey(driverId, filter, cursor);
    final state = _loadingStates[stateKey];
    
    if (state == null || !state.hasMore || state.isLoading) {
      return false;
    }
    
    return (totalItems - currentIndex) <= _prefetchThreshold;
  }

  /// Get performance analytics
  Map<String, dynamic> getPerformanceAnalytics() {
    final totalCacheHits = _cacheHitCounts.values.fold(0, (sum, count) => sum + count);
    final totalCacheMisses = _cacheMissCounts.values.fold(0, (sum, count) => sum + count);
    final cacheHitRate = totalCacheHits + totalCacheMisses > 0 
        ? totalCacheHits / (totalCacheHits + totalCacheMisses) 
        : 0.0;

    final allLoadTimes = _loadTimes.values.expand((times) => times).toList();
    final averageLoadTime = allLoadTimes.isNotEmpty
        ? Duration(microseconds: allLoadTimes.fold(Duration.zero, (sum, time) => sum + time).inMicroseconds ~/ allLoadTimes.length)
        : Duration.zero;

    return {
      'cacheHitRate': cacheHitRate,
      'totalCacheHits': totalCacheHits,
      'totalCacheMisses': totalCacheMisses,
      'averageLoadTime': averageLoadTime.inMilliseconds,
      'activeStates': _loadingStates.length,
      'ongoingRequests': _ongoingRequests.length,
    };
  }

  /// Clear loading state for driver
  void clearDriverState(String driverId) {
    _loadingStates.removeWhere((key, state) => state.driverId == driverId);
    _ongoingRequests.removeWhere((key, _) => key.contains(driverId));
    _debounceTimers.removeWhere((key, timer) {
      if (key.contains(driverId)) {
        timer.cancel();
        return true;
      }
      return false;
    });
    
    debugPrint('🚀 EnhancedLazyLoading: Cleared state for driver: $driverId');
  }

  /// Fetch orders using cursor-based pagination
  Future<List<Order>> _fetchOrdersWithCursor(
    String driverId,
    DateRangeFilter filter,
    String? cursor,
  ) async {
    // Parse cursor to get timestamp and ID
    DateTime? cursorTimestamp;
    String? cursorId;
    
    if (cursor != null) {
      final parts = cursor.split('|');
      if (parts.length == 2) {
        cursorTimestamp = DateTime.tryParse(parts[0]);
        cursorId = parts[1];
      }
    }

    // Use optimized database service with cursor pagination
    return await OptimizedDatabaseService.instance.getDriverOrderHistoryCursorPaginated(
      driverId: driverId,
      startDate: filter.startDate,
      endDate: filter.endDate,
      cursorTimestamp: cursorTimestamp,
      cursorId: cursorId,
      limit: filter.limit,
      direction: 'next',
    );
  }

  /// Generate next cursor from the last order
  String _generateNextCursor(Order lastOrder) {
    final timestamp = lastOrder.actualDeliveryTime?.toIso8601String() ?? 
                     lastOrder.createdAt.toIso8601String();
    return '$timestamp|${lastOrder.id}';
  }

  /// Calculate optimal page size based on performance history
  int _calculateOptimalPageSize(String stateKey, int requestedSize) {
    final loadTimes = _loadTimes[stateKey];
    if (loadTimes == null || loadTimes.isEmpty) {
      return min(requestedSize, _defaultPageSize);
    }

    // Calculate average load time
    final averageLoadTime = Duration(microseconds: loadTimes.fold(Duration.zero, (sum, time) => sum + time).inMicroseconds ~/ loadTimes.length);
    
    // Adjust page size based on performance
    if (averageLoadTime.inMilliseconds < 500) {
      // Fast loading - can handle larger pages
      return min(requestedSize * 2, _maxPageSize);
    } else if (averageLoadTime.inMilliseconds > 2000) {
      // Slow loading - reduce page size
      return max(requestedSize ~/ 2, 10);
    }
    
    return min(requestedSize, _defaultPageSize);
  }

  /// Calculate current page number from cursor
  int _calculateCurrentPage(String? cursor, int pageSize) {
    // For cursor-based pagination, page number is less meaningful
    // but we can estimate based on cursor presence
    return cursor != null ? 2 : 1;
  }

  /// Get cached result
  Future<EnhancedLazyLoadingResult<Order>?> _getCachedResult(
    String driverId,
    DateRangeFilter filter,
    String? cursor,
  ) async {
    final cachedOrders = await EnhancedCacheService.instance.getCachedOrderHistory(driverId, filter);
    if (cachedOrders != null) {
      return EnhancedLazyLoadingResult<Order>(
        items: cachedOrders,
        hasMore: cachedOrders.length >= filter.limit,
        nextCursor: cachedOrders.isNotEmpty ? _generateNextCursor(cachedOrders.last) : null,
        isLoading: false,
        currentPage: _calculateCurrentPage(cursor, filter.limit),
        totalLoaded: cachedOrders.length,
        fromCache: true,
        loadTime: Duration.zero,
        cacheKey: _generateStateKey(driverId, filter, cursor),
      );
    }
    return null;
  }

  /// Cache result
  Future<void> _cacheResult(
    String driverId,
    DateRangeFilter filter,
    String? cursor,
    EnhancedLazyLoadingResult<Order> result,
  ) async {
    await EnhancedCacheService.instance.cacheOrderHistory(
      driverId,
      filter,
      result.items,
    );
  }

  /// Schedule prefetch with debouncing
  void _schedulePrefetch(String driverId, DateRangeFilter filter, String nextCursor) {
    final prefetchKey = 'prefetch_${driverId}_$nextCursor';
    
    _debounceTimers[prefetchKey]?.cancel();
    _debounceTimers[prefetchKey] = Timer(_debounceDelay, () {
      prefetchNextPage(
        driverId: driverId,
        currentFilter: filter,
        currentCursor: nextCursor,
      );
      _debounceTimers.remove(prefetchKey);
    });
  }

  /// Generate state key
  String _generateStateKey(String driverId, DateRangeFilter filter, String? cursor) {
    final startDate = filter.startDate?.toIso8601String() ?? 'null';
    final endDate = filter.endDate?.toIso8601String() ?? 'null';
    final cursorStr = cursor ?? 'null';
    return 'enhanced_${driverId}_${startDate}_${endDate}_${filter.limit}_$cursorStr';
  }

  /// Record performance metrics
  void _recordLoadTime(String stateKey, Duration loadTime) {
    _loadTimes[stateKey] ??= [];
    _loadTimes[stateKey]!.add(loadTime);
    
    // Keep only recent load times
    if (_loadTimes[stateKey]!.length > 10) {
      _loadTimes[stateKey]!.removeAt(0);
    }
  }

  void _recordCacheHit(String stateKey) {
    _cacheHitCounts[stateKey] = (_cacheHitCounts[stateKey] ?? 0) + 1;
  }

  void _recordCacheMiss(String stateKey) {
    _cacheMissCounts[stateKey] = (_cacheMissCounts[stateKey] ?? 0) + 1;
  }

  /// Dispose and cleanup
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _loadingStates.clear();
    _ongoingRequests.clear();
    _loadTimes.clear();
    _cacheHitCounts.clear();
    _cacheMissCounts.clear();
    debugPrint('🚀 EnhancedLazyLoadingService: Disposed and cleaned up');
  }
}

/// Enhanced lazy loading state with cursor support
class EnhancedLazyLoadingState {
  final String driverId;
  final DateRangeFilter filter;
  String? cursor;
  bool isLoading;
  bool hasMore;
  int lastLoadedCount;
  int totalLoaded;
  String? nextCursor;
  DateTime lastAccessTime;

  EnhancedLazyLoadingState({
    required this.driverId,
    required this.filter,
    this.cursor,
    this.isLoading = false,
    this.hasMore = true,
    this.lastLoadedCount = 0,
    this.totalLoaded = 0,
    this.nextCursor,
    DateTime? lastAccessTime,
  }) : lastAccessTime = lastAccessTime ?? DateTime.now();

  void updateAccess() {
    lastAccessTime = DateTime.now();
  }

  @override
  String toString() {
    return 'EnhancedLazyLoadingState(driverId: $driverId, cursor: $cursor, isLoading: $isLoading, hasMore: $hasMore, totalLoaded: $totalLoaded)';
  }
}

/// Enhanced lazy loading result with additional metadata
class EnhancedLazyLoadingResult<T> {
  final List<T> items;
  final bool hasMore;
  final String? nextCursor;
  final bool isLoading;
  final int currentPage;
  final int totalLoaded;
  final bool fromCache;
  final Duration loadTime;
  final String cacheKey;
  final String? error;

  const EnhancedLazyLoadingResult({
    required this.items,
    required this.hasMore,
    required this.nextCursor,
    required this.isLoading,
    required this.currentPage,
    required this.totalLoaded,
    required this.fromCache,
    required this.loadTime,
    required this.cacheKey,
    this.error,
  });

  bool get hasError => error != null;
  bool get isEmpty => items.isEmpty;
  int get itemCount => items.length;

  EnhancedLazyLoadingResult<T> copyWith({
    List<T>? items,
    bool? hasMore,
    String? nextCursor,
    bool? isLoading,
    int? currentPage,
    int? totalLoaded,
    bool? fromCache,
    Duration? loadTime,
    String? cacheKey,
    String? error,
  }) {
    return EnhancedLazyLoadingResult<T>(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      isLoading: isLoading ?? this.isLoading,
      currentPage: currentPage ?? this.currentPage,
      totalLoaded: totalLoaded ?? this.totalLoaded,
      fromCache: fromCache ?? this.fromCache,
      loadTime: loadTime ?? this.loadTime,
      cacheKey: cacheKey ?? this.cacheKey,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'EnhancedLazyLoadingResult(items: ${items.length}, hasMore: $hasMore, fromCache: $fromCache, loadTime: ${loadTime.inMilliseconds}ms)';
  }
}
