import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/data/models/order.dart';
import '../../../../data/models/user_role.dart';
import '../../data/models/grouped_order_history.dart';
import '../../data/services/order_history_cache_service.dart';
import '../../data/services/lazy_loading_service.dart';
import '../../data/services/optimized_database_service.dart';
import 'enhanced_driver_order_history_providers.dart';

/// Optimized provider for driver order history with advanced caching and lazy loading
final optimizedDriverOrderHistoryProvider = AsyncNotifierProvider.family<
    OptimizedOrderHistoryNotifier,
    LazyLoadingResult<Order>,
    DateRangeFilter>(() {
  return OptimizedOrderHistoryNotifier();
});

/// Notifier for optimized order history management
class OptimizedOrderHistoryNotifier extends FamilyAsyncNotifier<LazyLoadingResult<Order>, DateRangeFilter> {
  String? _currentDriverId;
  
  @override
  Future<LazyLoadingResult<Order>> build(DateRangeFilter arg) async {
    // Initialize services if needed
    await _initializeServices();
    
    final authState = ref.read(authStateProvider);
    if (authState.user?.role != UserRole.driver) {
      debugPrint('🚗 OptimizedOrderHistory: User is not a driver, role: ${authState.user?.role}');
      return const LazyLoadingResult(
        items: [],
        hasMore: false,
        isLoading: false,
        currentPage: 1,
        totalLoaded: 0,
      );
    }

    final userId = authState.user?.id;
    if (userId == null) {
      debugPrint('🚗 OptimizedOrderHistory: No user ID found');
      return const LazyLoadingResult(
        items: [],
        hasMore: false,
        isLoading: false,
        currentPage: 1,
        totalLoaded: 0,
      );
    }

    // Get driver ID
    _currentDriverId = await _getDriverId(userId);
    if (_currentDriverId == null) {
      debugPrint('🚗 OptimizedOrderHistory: No driver profile found for user: $userId');
      return const LazyLoadingResult(
        items: [],
        hasMore: false,
        isLoading: false,
        currentPage: 1,
        totalLoaded: 0,
      );
    }

    debugPrint('🚗 OptimizedOrderHistory: Loading orders for driver: $_currentDriverId with filter: $arg');

    // Use optimized database service with lazy loading
    try {
      final orders = await OptimizedDatabaseService.instance.getDriverOrderHistory(
        driverId: _currentDriverId!,
        startDate: arg.startDate,
        endDate: arg.endDate,
        limit: arg.limit,
        offset: arg.offset,
      );

      final hasMore = orders.length >= arg.limit;

      return LazyLoadingResult(
        items: orders,
        hasMore: hasMore,
        isLoading: false,
        currentPage: arg.offset ~/ arg.limit + 1,
        totalLoaded: orders.length,
      );
    } catch (e) {
      // Fallback to lazy loading service
      debugPrint('🚗 OptimizedOrderHistory: Falling back to lazy loading service: $e');
      return await LazyLoadingService.instance.loadOrders(
        driverId: _currentDriverId!,
        filter: arg,
      );
    }
  }

  /// Load more orders (pagination)
  Future<void> loadMore() async {
    if (_currentDriverId == null) return;
    
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore || currentState.isLoading) {
      return;
    }

    try {
      state = const AsyncValue.loading();
      
      final result = await LazyLoadingService.instance.loadMore(
        driverId: _currentDriverId!,
        currentFilter: arg,
      );

      // Merge with existing items
      final existingItems = currentState.items;
      final newItems = [...existingItems, ...result.items];
      
      state = AsyncValue.data(result.copyWith(
        items: newItems,
        totalLoaded: newItems.length,
      ));
      
      debugPrint('🚗 OptimizedOrderHistory: Loaded ${result.items.length} more orders, total: ${newItems.length}');
    } catch (e, stackTrace) {
      debugPrint('🚗 OptimizedOrderHistory: Error loading more: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refresh data (force reload)
  Future<void> refresh() async {
    if (_currentDriverId == null) return;
    
    try {
      debugPrint('🚗 OptimizedOrderHistory: Refreshing data for driver: $_currentDriverId');
      
      // Invalidate cache
      await OrderHistoryCacheService.instance.invalidateDriverCache(_currentDriverId!);
      
      // Reset lazy loading state
      LazyLoadingService.instance.resetState(_currentDriverId!);
      
      // Reload data
      state = const AsyncValue.loading();
      final result = await LazyLoadingService.instance.loadOrders(
        driverId: _currentDriverId!,
        filter: arg,
        forceRefresh: true,
      );
      
      state = AsyncValue.data(result);
      debugPrint('🚗 OptimizedOrderHistory: Refreshed ${result.items.length} orders');
    } catch (e, stackTrace) {
      debugPrint('🚗 OptimizedOrderHistory: Error refreshing: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Prefetch next page
  Future<void> prefetchNext() async {
    if (_currentDriverId == null) return;
    
    try {
      await LazyLoadingService.instance.prefetchNextPage(
        driverId: _currentDriverId!,
        currentFilter: arg,
      );
    } catch (e) {
      debugPrint('🚗 OptimizedOrderHistory: Prefetch error: $e');
    }
  }

  /// Check if should load more based on scroll position
  bool shouldLoadMore(int currentIndex, int totalItems) {
    if (_currentDriverId == null) return false;
    
    return LazyLoadingService.instance.shouldLoadMore(
      driverId: _currentDriverId!,
      filter: arg,
      currentIndex: currentIndex,
      totalItems: totalItems,
    );
  }

  /// Initialize services
  Future<void> _initializeServices() async {
    await OrderHistoryCacheService.instance.initialize();
    LazyLoadingService.instance.initialize();
  }

  /// Get driver ID for user
  Future<String?> _getDriverId(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final driverResponse = await supabase
          .from('drivers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return driverResponse?['id'] as String?;
    } catch (e) {
      debugPrint('🚗 OptimizedOrderHistory: Error getting driver ID: $e');
      return null;
    }
  }
}

/// Optimized provider for grouped order history
final optimizedGroupedOrderHistoryProvider = Provider.family<AsyncValue<List<GroupedOrderHistory>>, DateRangeFilter>((ref, filter) {
  final orderHistoryAsync = ref.watch(optimizedDriverOrderHistoryProvider(filter));
  
  return orderHistoryAsync.when(
    data: (result) {
      final groupedHistory = GroupedOrderHistory.fromOrders(result.items);
      return AsyncValue.data(groupedHistory);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Optimized provider for order count with caching
final optimizedOrderCountProvider = AsyncNotifierProvider.family<
    OptimizedOrderCountNotifier,
    int,
    DateRangeFilter>(() {
  return OptimizedOrderCountNotifier();
});

/// Notifier for optimized order count
class OptimizedOrderCountNotifier extends FamilyAsyncNotifier<int, DateRangeFilter> {
  String? _currentDriverId;

  @override
  Future<int> build(DateRangeFilter arg) async {
    final authState = ref.read(authStateProvider);
    if (authState.user?.role != UserRole.driver) return 0;

    final userId = authState.user?.id;
    if (userId == null) return 0;

    _currentDriverId = await _getDriverId(userId);
    if (_currentDriverId == null) return 0;

    // Check cache first
    final cachedCount = await OrderHistoryCacheService.instance
        .getCachedOrderCount(_currentDriverId!, arg);
    
    if (cachedCount != null) {
      debugPrint('🚗 OptimizedOrderCount: Cache hit for count: $cachedCount');
      return cachedCount;
    }

    // Fetch from database
    final count = await _fetchOrderCount(_currentDriverId!, arg);
    
    // Cache the result
    await OrderHistoryCacheService.instance.cacheOrderCount(
      _currentDriverId!,
      arg,
      count,
    );

    debugPrint('🚗 OptimizedOrderCount: Fetched and cached count: $count');
    return count;
  }

  /// Get driver ID for user
  Future<String?> _getDriverId(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final driverResponse = await supabase
          .from('drivers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return driverResponse?['id'] as String?;
    } catch (e) {
      debugPrint('🚗 OptimizedOrderCount: Error getting driver ID: $e');
      return null;
    }
  }

  /// Fetch order count from database using optimized service
  Future<int> _fetchOrderCount(String driverId, DateRangeFilter filter) async {
    try {
      return await OptimizedDatabaseService.instance.countDriverOrders(
        driverId: driverId,
        startDate: filter.startDate,
        endDate: filter.endDate,
      );
    } catch (e) {
      debugPrint('🚗 OptimizedOrderCount: Error fetching count: $e');
      return 0;
    }
  }
}

/// Optimized provider for order summary with caching
final optimizedOrderSummaryProvider = Provider.family<AsyncValue<OrderHistorySummary>, DateRangeFilter>((ref, filter) {
  final groupedHistoryAsync = ref.watch(optimizedGroupedOrderHistoryProvider(filter));
  
  return groupedHistoryAsync.when(
    data: (groupedHistory) {
      final summary = GroupedOrderHistory.getSummary(groupedHistory);

      // Cache the summary asynchronously (fire and forget)
      _cacheSummaryAsync(ref, filter, summary);

      return AsyncValue.data(summary);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Helper function to cache summary asynchronously
void _cacheSummaryAsync(Ref ref, DateRangeFilter filter, OrderHistorySummary summary) {
  // Fire and forget caching
  Future(() async {
    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId != null) {
        final driverId = await _getDriverIdForSummary(userId);
        if (driverId != null) {
          await OrderHistoryCacheService.instance.cacheOrderSummary(
            driverId,
            filter,
            summary,
          );
        }
      }
    } catch (e) {
      debugPrint('🚗 OptimizedOrderSummary: Error caching summary: $e');
    }
  });
}

/// Helper function to get driver ID for summary caching
Future<String?> _getDriverIdForSummary(String userId) async {
  try {
    final supabase = Supabase.instance.client;
    final driverResponse = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    return driverResponse?['id'] as String?;
  } catch (e) {
    return null;
  }
}

/// Provider for performance monitoring
final performanceMonitorProvider = Provider<Map<String, dynamic>>((ref) {
  return {
    'cacheStats': OrderHistoryCacheService.instance.getCacheStats(),
    'lazyLoadingStats': LazyLoadingService.instance.getLoadingStats(),
    'timestamp': DateTime.now().toIso8601String(),
  };
});

/// Extension for null safety helper
extension NullableExtension<T> on T? {
  void let(void Function(T) action) {
    if (this != null) {
      action(this as T);
    }
  }
}
