import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../orders/data/models/order.dart';
import '../../presentation/providers/enhanced_driver_order_history_providers.dart';
import 'order_history_cache_service.dart';

/// Advanced lazy loading service for driver order history
class LazyLoadingService {
  static const int _defaultPageSize = 20;
  static const int _prefetchThreshold = 5; // Load more when 5 items from end
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  
  static LazyLoadingService? _instance;
  static LazyLoadingService get instance => _instance ??= LazyLoadingService._();
  
  LazyLoadingService._();
  
  final Map<String, LazyLoadingState> _loadingStates = {};
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, Completer<List<Order>>> _ongoingRequests = {};
  
  /// Initialize the lazy loading service
  void initialize() {
    debugPrint('🚗 LazyLoadingService: Initialized');
  }

  /// Load orders with lazy loading strategy
  Future<LazyLoadingResult<Order>> loadOrders({
    required String driverId,
    required DateRangeFilter filter,
    bool forceRefresh = false,
    bool prefetch = false,
  }) async {
    final stateKey = _generateStateKey(driverId, filter);
    
    // Check if there's an ongoing request for the same parameters
    if (_ongoingRequests.containsKey(stateKey)) {
      debugPrint('🚗 LazyLoading: Reusing ongoing request for: $stateKey');
      final orders = await _ongoingRequests[stateKey]!.future;
      return LazyLoadingResult(
        items: orders,
        hasMore: _hasMoreData(stateKey, orders.length),
        isLoading: false,
        currentPage: filter.offset ~/ filter.limit + 1,
        totalLoaded: orders.length,
      );
    }

    // Get or create loading state
    final state = _loadingStates[stateKey] ??= LazyLoadingState(
      driverId: driverId,
      filter: filter,
    );

    // Check cache first (unless force refresh)
    if (!forceRefresh && !prefetch) {
      final cachedOrders = await OrderHistoryCacheService.instance
          .getCachedOrderHistory(driverId, filter);
      
      if (cachedOrders != null) {
        debugPrint('🚗 LazyLoading: Cache hit for: $stateKey (${cachedOrders.length} orders)');
        return LazyLoadingResult(
          items: cachedOrders,
          hasMore: _hasMoreData(stateKey, cachedOrders.length),
          isLoading: false,
          currentPage: filter.offset ~/ filter.limit + 1,
          totalLoaded: cachedOrders.length,
          fromCache: true,
        );
      }
    }

    // Create completer for ongoing request tracking
    final completer = Completer<List<Order>>();
    _ongoingRequests[stateKey] = completer;

    try {
      state.isLoading = true;
      debugPrint('🚗 LazyLoading: Loading orders for: $stateKey (offset: ${filter.offset}, limit: ${filter.limit})');

      final orders = await _fetchOrdersFromDatabase(driverId, filter);
      
      // Update state
      state.isLoading = false;
      state.lastLoadedCount = orders.length;
      state.totalLoaded += orders.length;
      state.hasMore = orders.length >= filter.limit;

      // Cache the results
      await OrderHistoryCacheService.instance.cacheOrderHistory(
        driverId,
        filter,
        orders,
      );

      // Complete the request
      completer.complete(orders);
      
      // Prefetch next page if conditions are met
      if (!prefetch && orders.length >= filter.limit && state.hasMore) {
        _schedulePrefetch(driverId, filter);
      }

      debugPrint('🚗 LazyLoading: Loaded ${orders.length} orders for: $stateKey');
      
      return LazyLoadingResult(
        items: orders,
        hasMore: state.hasMore,
        isLoading: false,
        currentPage: filter.offset ~/ filter.limit + 1,
        totalLoaded: state.totalLoaded,
      );
    } catch (e) {
      state.isLoading = false;
      completer.completeError(e);
      debugPrint('🚗 LazyLoading: Error loading orders: $e');
      rethrow;
    } finally {
      _ongoingRequests.remove(stateKey);
    }
  }

  /// Load more orders (pagination)
  Future<LazyLoadingResult<Order>> loadMore({
    required String driverId,
    required DateRangeFilter currentFilter,
  }) async {
    final stateKey = _generateStateKey(driverId, currentFilter);
    final state = _loadingStates[stateKey];
    
    if (state == null || !state.hasMore || state.isLoading) {
      return LazyLoadingResult(
        items: [],
        hasMore: state?.hasMore ?? false,
        isLoading: state?.isLoading ?? false,
        currentPage: currentFilter.offset ~/ currentFilter.limit + 1,
        totalLoaded: state?.totalLoaded ?? 0,
      );
    }

    // Create next page filter
    final nextPageFilter = currentFilter.copyWith(
      offset: currentFilter.offset + currentFilter.limit,
    );

    return loadOrders(
      driverId: driverId,
      filter: nextPageFilter,
    );
  }

  /// Check if should trigger lazy loading based on scroll position
  bool shouldLoadMore({
    required String driverId,
    required DateRangeFilter filter,
    required int currentIndex,
    required int totalItems,
  }) {
    final stateKey = _generateStateKey(driverId, filter);
    final state = _loadingStates[stateKey];
    
    if (state == null || !state.hasMore || state.isLoading) {
      return false;
    }

    // Trigger when user is near the end
    return (totalItems - currentIndex) <= _prefetchThreshold;
  }

  /// Prefetch next page of data
  Future<void> prefetchNextPage({
    required String driverId,
    required DateRangeFilter currentFilter,
  }) async {
    final nextPageFilter = currentFilter.copyWith(
      offset: currentFilter.offset + currentFilter.limit,
    );

    try {
      await loadOrders(
        driverId: driverId,
        filter: nextPageFilter,
        prefetch: true,
      );
      debugPrint('🚗 LazyLoading: Prefetched next page successfully');
    } catch (e) {
      debugPrint('🚗 LazyLoading: Prefetch failed: $e');
    }
  }

  /// Reset loading state for specific driver
  void resetState(String driverId) {
    _loadingStates.removeWhere((key, _) => key.contains(driverId));
    _debounceTimers.forEach((key, timer) {
      if (key.contains(driverId)) {
        timer.cancel();
      }
    });
    _debounceTimers.removeWhere((key, _) => key.contains(driverId));
    _ongoingRequests.removeWhere((key, _) => key.contains(driverId));
    
    debugPrint('🚗 LazyLoading: Reset state for driver: $driverId');
  }

  /// Get loading state for debugging
  LazyLoadingState? getLoadingState(String driverId, DateRangeFilter filter) {
    final stateKey = _generateStateKey(driverId, filter);
    return _loadingStates[stateKey];
  }

  /// Get loading statistics
  Map<String, dynamic> getLoadingStats() {
    return {
      'activeStates': _loadingStates.length,
      'ongoingRequests': _ongoingRequests.length,
      'activeTimers': _debounceTimers.length,
      'states': _loadingStates.map((key, state) => MapEntry(key, {
        'hasMore': state.hasMore,
        'isLoading': state.isLoading,
        'totalLoaded': state.totalLoaded,
        'lastLoadedCount': state.lastLoadedCount,
      })),
    };
  }

  /// Generate unique state key
  String _generateStateKey(String driverId, DateRangeFilter filter) {
    final startDate = filter.startDate?.toIso8601String() ?? 'null';
    final endDate = filter.endDate?.toIso8601String() ?? 'null';
    return 'lazy_${driverId}_${startDate}_${endDate}_${filter.limit}';
  }

  /// Check if there's more data to load
  bool _hasMoreData(String stateKey, int loadedCount) {
    final state = _loadingStates[stateKey];
    if (state == null) return loadedCount >= _defaultPageSize;
    
    return state.hasMore && loadedCount >= state.filter.limit;
  }

  /// Schedule prefetch with debouncing
  void _schedulePrefetch(String driverId, DateRangeFilter filter) {
    final stateKey = _generateStateKey(driverId, filter);
    
    // Cancel existing timer
    _debounceTimers[stateKey]?.cancel();
    
    // Schedule new prefetch
    _debounceTimers[stateKey] = Timer(_debounceDelay, () {
      prefetchNextPage(driverId: driverId, currentFilter: filter);
      _debounceTimers.remove(stateKey);
    });
  }

  /// Fetch orders from database
  Future<List<Order>> _fetchOrdersFromDatabase(
    String driverId,
    DateRangeFilter filter,
  ) async {
    final supabase = Supabase.instance.client;
    
    // Build query with date filtering
    var query = supabase
        .from('orders')
        .select('''
          *,
          order_items:order_items(
            *,
            menu_item:menu_items!order_items_menu_item_id_fkey(
              id,
              name,
              image_url
            )
          ),
          vendors:vendors!orders_vendor_id_fkey(
            business_name,
            business_address
          )
        ''')
        .eq('assigned_driver_id', driverId)
        .inFilter('status', ['delivered', 'cancelled']);

    // Apply date filtering if specified
    if (filter.startDate != null) {
      query = query.gte('actual_delivery_time', filter.startDate!.toIso8601String());
    }

    if (filter.endDate != null) {
      query = query.lt('actual_delivery_time', filter.endDate!.toIso8601String());
    }

    // Apply ordering and pagination
    final response = await query
        .order('actual_delivery_time', ascending: false)
        .range(filter.offset, filter.offset + filter.limit - 1);

    return response.map((json) => Order.fromJson(json)).toList();
  }
}

/// Lazy loading state for tracking progress
class LazyLoadingState {
  final String driverId;
  final DateRangeFilter filter;
  bool isLoading;
  bool hasMore;
  int totalLoaded;
  int lastLoadedCount;
  DateTime lastLoadTime;

  LazyLoadingState({
    required this.driverId,
    required this.filter,
    this.isLoading = false,
    this.hasMore = true,
    this.totalLoaded = 0,
    this.lastLoadedCount = 0,
  }) : lastLoadTime = DateTime.now();

  void updateLoadTime() {
    lastLoadTime = DateTime.now();
  }

  @override
  String toString() {
    return 'LazyLoadingState(driverId: $driverId, isLoading: $isLoading, hasMore: $hasMore, totalLoaded: $totalLoaded)';
  }
}

/// Result of lazy loading operation
class LazyLoadingResult<T> {
  final List<T> items;
  final bool hasMore;
  final bool isLoading;
  final int currentPage;
  final int totalLoaded;
  final bool fromCache;
  final String? error;

  const LazyLoadingResult({
    required this.items,
    required this.hasMore,
    required this.isLoading,
    required this.currentPage,
    required this.totalLoaded,
    this.fromCache = false,
    this.error,
  });

  LazyLoadingResult<T> copyWith({
    List<T>? items,
    bool? hasMore,
    bool? isLoading,
    int? currentPage,
    int? totalLoaded,
    bool? fromCache,
    String? error,
  }) {
    return LazyLoadingResult<T>(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      currentPage: currentPage ?? this.currentPage,
      totalLoaded: totalLoaded ?? this.totalLoaded,
      fromCache: fromCache ?? this.fromCache,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'LazyLoadingResult(items: ${items.length}, hasMore: $hasMore, isLoading: $isLoading, currentPage: $currentPage, totalLoaded: $totalLoaded, fromCache: $fromCache)';
  }
}
