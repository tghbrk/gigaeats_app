import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/customer_order_lazy_loading_service.dart';
import '../../data/models/customer_order_history_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/performance_monitor.dart';


/// Provider for the lazy loading service
final customerOrderLazyLoadingServiceProvider = Provider<CustomerOrderLazyLoadingService>((ref) {
  return CustomerOrderLazyLoadingService();
});

/// Enhanced lazy loading provider with performance monitoring
final enhancedCustomerOrderLazyProvider = StateNotifierProvider.family<
    EnhancedCustomerOrderLazyNotifier,
    EnhancedCustomerOrderLazyState,
    CustomerDateRangeFilter>((ref, filter) {
  return EnhancedCustomerOrderLazyNotifier(ref, filter);
});

/// Enhanced state notifier with advanced lazy loading capabilities
class EnhancedCustomerOrderLazyNotifier extends StateNotifier<EnhancedCustomerOrderLazyState> {
  final Ref _ref;
  CustomerDateRangeFilter _currentFilter;
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  EnhancedCustomerOrderLazyNotifier(this._ref, this._currentFilter)
      : super(const EnhancedCustomerOrderLazyState.initial());

  /// Load initial data with performance tracking
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    final tracker = _performanceMonitor.startTracking('customer_orders_initial_load');
    
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final authState = _ref.read(authStateProvider);
      final customerId = authState.user?.id;
      
      if (customerId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🚀 Enhanced Lazy: Loading initial data for customer: $customerId');
      debugPrint('🚀 Enhanced Lazy: Filter: $_currentFilter');

      final lazyService = _ref.read(customerOrderLazyLoadingServiceProvider);
      final result = await lazyService.loadInitial(
        customerId: customerId,
        filter: _currentFilter,
      );

      state = EnhancedCustomerOrderLazyState(
        items: result.items,
        hasMore: result.hasMore,
        isLoading: false,
        currentPage: 1,
        totalLoaded: result.totalLoaded,
        filter: _currentFilter,
        nextCursor: result.nextCursor,
        isFromCache: result.isFromCache,
        lastLoadTimeMs: result.loadTimeMs,
        cacheStats: lazyService.getCacheStats(),
      );

      tracker.stop(isSuccess: true, additionalMetadata: {
        'totalLoaded': result.totalLoaded,
        'groupCount': result.items.length,
        'isFromCache': result.isFromCache,
      });

      debugPrint('🚀 Enhanced Lazy: Initial load complete - ${result.totalLoaded} orders, ${result.items.length} groups');
      
      // Start prefetching if there's more data
      if (result.hasMore && result.nextCursor != null) {
        _schedulePrefetch(customerId, result.nextCursor!);
      }
      
    } catch (e) {
      debugPrint('🚀 Enhanced Lazy: Error in initial load: $e');
      tracker.stop(isSuccess: false, additionalMetadata: {'error': e.toString()});
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more data with cursor-based pagination
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.nextCursor == null) return;

    final tracker = _performanceMonitor.startTracking('customer_orders_load_more');
    
    try {
      state = state.copyWith(isLoading: true);
      
      final authState = _ref.read(authStateProvider);
      final customerId = authState.user?.id;
      
      if (customerId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🚀 Enhanced Lazy: Loading more data - page ${state.currentPage + 1}');

      final lazyService = _ref.read(customerOrderLazyLoadingServiceProvider);
      final result = await lazyService.loadNext(
        customerId: customerId,
        filter: _currentFilter,
        cursor: state.nextCursor!,
      );

      // Combine with existing items
      final combinedItems = [...state.items, ...result.items];

      state = EnhancedCustomerOrderLazyState(
        items: combinedItems,
        hasMore: result.hasMore,
        isLoading: false,
        currentPage: state.currentPage + 1,
        totalLoaded: state.totalLoaded + result.totalLoaded,
        filter: _currentFilter,
        nextCursor: result.nextCursor,
        isFromCache: result.isFromCache,
        lastLoadTimeMs: result.loadTimeMs,
        cacheStats: lazyService.getCacheStats(),
      );

      tracker.stop(isSuccess: true, additionalMetadata: {
        'newItemsLoaded': result.totalLoaded,
        'totalItemsNow': state.totalLoaded,
        'isFromCache': result.isFromCache,
      });

      debugPrint('🚀 Enhanced Lazy: Load more complete - ${result.totalLoaded} new orders, ${state.totalLoaded} total');
      
      // Continue prefetching if there's more data
      if (result.hasMore && result.nextCursor != null) {
        _schedulePrefetch(customerId, result.nextCursor!);
      }
      
    } catch (e) {
      debugPrint('🚀 Enhanced Lazy: Error loading more: $e');
      tracker.stop(isSuccess: false, additionalMetadata: {'error': e.toString()});
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh data with new filter
  Future<void> refresh([CustomerDateRangeFilter? newFilter]) async {
    if (newFilter != null) {
      _currentFilter = newFilter.copyWith(offset: 0); // Reset to first page
    } else {
      _currentFilter = _currentFilter.copyWith(offset: 0);
    }
    
    debugPrint('🚀 Enhanced Lazy: Refreshing with filter: $_currentFilter');
    
    // Clear cache for this filter
    final lazyService = _ref.read(customerOrderLazyLoadingServiceProvider);
    lazyService.clearCache();
    
    await loadInitial();
  }

  /// Update filter and refresh
  Future<void> updateFilter(CustomerDateRangeFilter newFilter) async {
    debugPrint('🚀 Enhanced Lazy: Updating filter from $_currentFilter to $newFilter');
    await refresh(newFilter);
  }

  /// Schedule prefetch in background
  void _schedulePrefetch(String customerId, String cursor) {
    final lazyService = _ref.read(customerOrderLazyLoadingServiceProvider);
    
    // Don't await - run in background
    lazyService.prefetchNext(
      customerId: customerId,
      filter: _currentFilter,
      cursor: cursor,
    );
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    final lazyService = _ref.read(customerOrderLazyLoadingServiceProvider);
    return {
      'loadingMetrics': lazyService.getPerformanceMetrics(),
      'cacheStats': lazyService.getCacheStats(),
      'performanceMonitor': _performanceMonitor.getSummary(),
    };
  }

  /// Clear cache
  void clearCache() {
    final lazyService = _ref.read(customerOrderLazyLoadingServiceProvider);
    lazyService.clearCache();
  }
}

/// Enhanced state for lazy loading with performance metrics
@immutable
class EnhancedCustomerOrderLazyState {
  final List<CustomerGroupedOrderHistory> items;
  final bool hasMore;
  final bool isLoading;
  final int currentPage;
  final int totalLoaded;
  final String? error;
  final CustomerDateRangeFilter? filter;
  final String? nextCursor;
  final bool isFromCache;
  final int lastLoadTimeMs;
  final CustomerOrderCacheStats? cacheStats;

  const EnhancedCustomerOrderLazyState({
    required this.items,
    required this.hasMore,
    required this.isLoading,
    required this.currentPage,
    required this.totalLoaded,
    this.error,
    this.filter,
    this.nextCursor,
    required this.isFromCache,
    required this.lastLoadTimeMs,
    this.cacheStats,
  });

  const EnhancedCustomerOrderLazyState.initial()
      : items = const [],
        hasMore = true,
        isLoading = false,
        currentPage = 0,
        totalLoaded = 0,
        error = null,
        filter = null,
        nextCursor = null,
        isFromCache = false,
        lastLoadTimeMs = 0,
        cacheStats = null;

  EnhancedCustomerOrderLazyState copyWith({
    List<CustomerGroupedOrderHistory>? items,
    bool? hasMore,
    bool? isLoading,
    int? currentPage,
    int? totalLoaded,
    String? error,
    CustomerDateRangeFilter? filter,
    String? nextCursor,
    bool? isFromCache,
    int? lastLoadTimeMs,
    CustomerOrderCacheStats? cacheStats,
  }) {
    return EnhancedCustomerOrderLazyState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      currentPage: currentPage ?? this.currentPage,
      totalLoaded: totalLoaded ?? this.totalLoaded,
      error: error,
      filter: filter ?? this.filter,
      nextCursor: nextCursor ?? this.nextCursor,
      isFromCache: isFromCache ?? this.isFromCache,
      lastLoadTimeMs: lastLoadTimeMs ?? this.lastLoadTimeMs,
      cacheStats: cacheStats ?? this.cacheStats,
    );
  }

  /// Get performance summary
  String get performanceSummary {
    final cacheHitRate = cacheStats?.hitRate ?? 0.0;
    final memoryUsage = cacheStats?.totalMemoryKB ?? 0.0;

    return 'Performance: ${lastLoadTimeMs}ms load time, '
           '${(cacheHitRate * 100).toStringAsFixed(1)}% cache hit rate, '
           '${memoryUsage.toStringAsFixed(1)}KB memory usage';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnhancedCustomerOrderLazyState &&
          runtimeType == other.runtimeType &&
          listEquals(items, other.items) &&
          hasMore == other.hasMore &&
          isLoading == other.isLoading &&
          currentPage == other.currentPage &&
          totalLoaded == other.totalLoaded &&
          error == other.error &&
          filter == other.filter &&
          nextCursor == other.nextCursor &&
          isFromCache == other.isFromCache &&
          lastLoadTimeMs == other.lastLoadTimeMs &&
          cacheStats == other.cacheStats;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(items),
        hasMore,
        isLoading,
        currentPage,
        totalLoaded,
        error,
        filter,
        nextCursor,
        isFromCache,
        lastLoadTimeMs,
        cacheStats,
      );

  @override
  String toString() => 'EnhancedCustomerOrderLazyState('
      'items: ${items.length} groups, '
      'hasMore: $hasMore, '
      'isLoading: $isLoading, '
      'currentPage: $currentPage, '
      'totalLoaded: $totalLoaded, '
      'isFromCache: $isFromCache, '
      'lastLoadTimeMs: ${lastLoadTimeMs}ms'
      ')';
}

/// Provider for performance monitoring
final customerOrderPerformanceProvider = Provider<Map<String, dynamic>>((ref) {
  // This would typically be updated by the lazy loading notifier
  return {};
});

/// Provider for cache statistics
final customerOrderCacheStatsProvider = Provider<CustomerOrderCacheStats?>((ref) {
  final lazyService = ref.watch(customerOrderLazyLoadingServiceProvider);
  return lazyService.getCacheStats();
});
