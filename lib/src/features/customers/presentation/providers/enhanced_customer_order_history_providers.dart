import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/data/models/order.dart';
import '../../../../data/models/user_role.dart';
import '../../data/models/customer_order_history_models.dart';

/// Enhanced provider for customer order history with date filtering and pagination
final enhancedCustomerOrderHistoryProvider = FutureProvider.family<List<Order>, CustomerDateRangeFilter>((ref, filter) async {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.customer) {
    debugPrint('🛒 Enhanced History: User is not a customer, role: ${authState.user?.role}');
    return <Order>[];
  }

  final userId = authState.user?.id;
  if (userId == null) {
    debugPrint('🛒 Enhanced History: No user ID found');
    return <Order>[];
  }

  try {
    debugPrint('🛒 Enhanced History: Fetching orders for customer: $userId');
    debugPrint('🛒 Enhanced History: Filter - startDate: ${filter.startDate}, endDate: ${filter.endDate}');
    debugPrint('🛒 Enhanced History: Filter - limit: ${filter.limit}, offset: ${filter.offset}');
    debugPrint('🛒 Enhanced History: Filter - statusFilter: ${filter.statusFilter}');

    final supabase = Supabase.instance.client;

    // Build query with comprehensive joins
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
        .eq('customer_id', userId);

    // Apply status filtering
    if (filter.statusFilter != null) {
      switch (filter.statusFilter!) {
        case CustomerOrderFilterStatus.completed:
          query = query.eq('status', 'delivered');
          debugPrint('🛒 Enhanced History: Filtering for completed orders only (delivered)');
          break;
        case CustomerOrderFilterStatus.cancelled:
          query = query.eq('status', 'cancelled');
          debugPrint('🛒 Enhanced History: Filtering for cancelled orders only');
          break;
        case CustomerOrderFilterStatus.active:
          // Show only active orders (pending, confirmed, preparing, ready, out_for_delivery)
          query = query.inFilter('status', ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery']);
          debugPrint('🛒 Enhanced History: Filtering for active orders only (pending, confirmed, preparing, ready, out_for_delivery)');
          break;
      }
    } else {
      // Default to showing ALL orders when no specific status filter is applied
      debugPrint('🛒 Enhanced History: No status filter specified, showing all order statuses');
      // Don't apply any status filter - show all orders regardless of status
    }

    // Apply date filtering if specified
    if (filter.startDate != null) {
      // Use created_at for all orders as it's more reliable
      query = query.gte('created_at', filter.startDate!.toIso8601String());
      debugPrint('🛒 Enhanced History: Applied start date filter: ${filter.startDate}');
    }

    if (filter.endDate != null) {
      query = query.lt('created_at', filter.endDate!.toIso8601String());
      debugPrint('🛒 Enhanced History: Applied end date filter: ${filter.endDate}');
    }

    // Apply ordering and pagination
    final response = await query
        .order('created_at', ascending: false)
        .range(filter.offset, filter.offset + filter.limit - 1);

    debugPrint('🛒 Enhanced History: Retrieved ${response.length} orders');

    // Parse orders and log status distribution
    final orders = response.map((json) => Order.fromJson(json)).toList();

    // Log status distribution for debugging
    final statusCounts = <String, int>{};
    for (final order in orders) {
      final status = order.status.value;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    debugPrint('🛒 Enhanced History: Order status distribution: $statusCounts');

    return orders;
  } catch (e) {
    debugPrint('🛒 Enhanced History: Error fetching orders: $e');
    throw Exception('Failed to fetch customer order history: $e');
  }
});

/// Provider for grouped customer order history
final groupedCustomerOrderHistoryProvider = Provider.family<AsyncValue<List<CustomerGroupedOrderHistory>>, CustomerDateRangeFilter>((ref, filter) {
  final orderHistoryAsync = ref.watch(enhancedCustomerOrderHistoryProvider(filter));
  
  return orderHistoryAsync.when(
    data: (orders) {
      debugPrint('🛒 Grouped History: Processing ${orders.length} orders for grouping');
      final groupedHistory = CustomerGroupedOrderHistory.fromOrders(orders);
      debugPrint('🛒 Grouped History: Created ${groupedHistory.length} grouped entries');
      return AsyncValue.data(groupedHistory);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Provider for customer order history statistics
final customerOrderHistoryStatsProvider = FutureProvider.family<CustomerOrderHistorySummary, CustomerDateRangeFilter>((ref, filter) async {
  final orderHistoryAsync = ref.watch(enhancedCustomerOrderHistoryProvider(filter));
  
  return orderHistoryAsync.when(
    data: (orders) {
      final groupedHistory = CustomerGroupedOrderHistory.fromOrders(orders);
      return CustomerGroupedOrderHistory.getSummary(groupedHistory);
    },
    loading: () => throw const AsyncLoading(),
    error: (error, stackTrace) => throw error,
  );
});

/// Provider for daily customer order statistics
final dailyCustomerOrderStatsProvider = FutureProvider.family<Map<String, CustomerDailyStats>, String>((ref, customerId) async {
  try {
    final supabase = Supabase.instance.client;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thirtyDaysAgo = today.subtract(const Duration(days: 30));

    debugPrint('🛒 Daily Stats: Fetching stats for customer: $customerId');

    final response = await supabase
        .from('orders')
        .select('created_at, status, total_amount')
        .eq('customer_id', customerId)
        .inFilter('status', ['delivered', 'cancelled'])
        .gte('created_at', thirtyDaysAgo.toIso8601String())
        .order('created_at', ascending: false);

    debugPrint('🛒 Daily Stats: Retrieved ${response.length} orders for statistics');

    final dailyStats = <String, CustomerDailyStats>{};

    for (final orderData in response) {
      final createdAt = DateTime.parse(orderData['created_at']);
      final orderDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
      final dateKey = orderDate.toIso8601String().split('T')[0];
      
      final status = orderData['status'] as String;
      final amount = (orderData['total_amount'] as num).toDouble();

      if (!dailyStats.containsKey(dateKey)) {
        dailyStats[dateKey] = CustomerDailyStats(
          date: orderDate,
          totalOrders: 0,
          completedOrders: 0,
          cancelledOrders: 0,
          totalSpent: 0.0,
          completedSpent: 0.0,
        );
      }

      final stats = dailyStats[dateKey]!;
      dailyStats[dateKey] = CustomerDailyStats(
        date: stats.date,
        totalOrders: stats.totalOrders + 1,
        completedOrders: status == 'delivered' ? stats.completedOrders + 1 : stats.completedOrders,
        cancelledOrders: status == 'cancelled' ? stats.cancelledOrders + 1 : stats.cancelledOrders,
        totalSpent: stats.totalSpent + amount,
        completedSpent: status == 'delivered' ? stats.completedSpent + amount : stats.completedSpent,
      );
    }

    debugPrint('🛒 Daily Stats: Processed statistics for ${dailyStats.length} days');
    return dailyStats;
  } catch (e) {
    debugPrint('🛒 Daily Stats: Error fetching statistics: $e');
    throw Exception('Failed to fetch daily customer order statistics: $e');
  }
});

/// Real-time provider for customer order updates
final customerOrderUpdatesStreamProvider = StreamProvider.family<List<Order>, String>((ref, customerId) async* {
  debugPrint('🛒 Real-time: Setting up order updates stream for customer: $customerId');
  
  final supabase = Supabase.instance.client;
  
  // Initial data fetch
  try {
    final initialResponse = await supabase
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
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .limit(50);

    final initialOrders = initialResponse.map((json) => Order.fromJson(json)).toList();
    debugPrint('🛒 Real-time: Initial fetch returned ${initialOrders.length} orders');
    yield initialOrders;
  } catch (e) {
    debugPrint('🛒 Real-time: Error in initial fetch: $e');
    yield <Order>[];
  }

  // Set up real-time subscription
  await for (final event in supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('customer_id', customerId)) {
    
    try {
      debugPrint('🛒 Real-time: Received update event with ${event.length} records');
      
      if (event.isEmpty) {
        yield <Order>[];
        continue;
      }

      // Fetch full order details for updated orders
      final orderIds = event.map((json) => json['id'] as String).toList();
      
      final detailedResponse = await supabase
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
          .inFilter('id', orderIds)
          .order('created_at', ascending: false);

      final updatedOrders = detailedResponse.map((json) => Order.fromJson(json)).toList();
      debugPrint('🛒 Real-time: Yielding ${updatedOrders.length} updated orders');
      yield updatedOrders;
    } catch (e) {
      debugPrint('🛒 Real-time: Error processing update: $e');
      // Continue with previous state on error
    }
  }
});

/// Provider for customer order count with caching
final customerOrderCountProvider = FutureProvider.family<int, CustomerDateRangeFilter>((ref, filter) async {
  final authState = ref.read(authStateProvider);
  final userId = authState.user?.id;
  
  if (userId == null) {
    return 0;
  }

  try {
    final supabase = Supabase.instance.client;
    
    var query = supabase
        .from('orders')
        .select('id')
        .eq('customer_id', userId);

    // Apply status filtering
    if (filter.statusFilter != null) {
      switch (filter.statusFilter!) {
        case CustomerOrderFilterStatus.completed:
          query = query.eq('status', 'delivered');
          break;
        case CustomerOrderFilterStatus.cancelled:
          query = query.eq('status', 'cancelled');
          break;
        case CustomerOrderFilterStatus.active:
          query = query.inFilter('status', ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery']);
          break;
      }
    } else {
      query = query.inFilter('status', ['delivered', 'cancelled']);
    }

    // Apply date filtering
    if (filter.startDate != null) {
      query = query.gte('created_at', filter.startDate!.toIso8601String());
    }
    if (filter.endDate != null) {
      query = query.lt('created_at', filter.endDate!.toIso8601String());
    }

    final response = await query;
    final count = response.length;

    debugPrint('🛒 Order Count: Found $count orders for customer with filter');
    return count;
  } catch (e) {
    debugPrint('🛒 Order Count: Error counting orders: $e');
    return 0;
  }
});

/// Lazy loading provider for customer order history with pagination
final customerOrderHistoryLazyProvider = StateNotifierProvider.family<
    CustomerOrderHistoryLazyNotifier,
    CustomerOrderHistoryLazyState,
    CustomerDateRangeFilter>((ref, initialFilter) {
  return CustomerOrderHistoryLazyNotifier(ref, initialFilter);
});

/// State notifier for lazy loading customer order history
class CustomerOrderHistoryLazyNotifier extends StateNotifier<CustomerOrderHistoryLazyState> {
  final Ref _ref;
  CustomerDateRangeFilter _currentFilter;

  CustomerOrderHistoryLazyNotifier(this._ref, this._currentFilter)
      : super(const CustomerOrderHistoryLazyState.initial());

  /// Load initial data
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('🛒 Lazy Loading: Loading initial data with filter: $_currentFilter');

      final orders = await _ref.read(enhancedCustomerOrderHistoryProvider(_currentFilter).future);
      final groupedHistory = CustomerGroupedOrderHistory.fromOrders(orders);

      state = CustomerOrderHistoryLazyState(
        items: groupedHistory,
        hasMore: orders.length >= _currentFilter.limit,
        isLoading: false,
        currentPage: 1,
        totalLoaded: orders.length,
        filter: _currentFilter,
      );

      debugPrint('🛒 Lazy Loading: Initial load complete - ${orders.length} orders, ${groupedHistory.length} groups');
    } catch (e) {
      debugPrint('🛒 Lazy Loading: Error in initial load: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more data (pagination)
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPageFilter = _currentFilter.copyWith(
        offset: _currentFilter.offset + _currentFilter.limit,
      );

      debugPrint('🛒 Lazy Loading: Loading more data - page ${state.currentPage + 1}');

      final newOrders = await _ref.read(enhancedCustomerOrderHistoryProvider(nextPageFilter).future);

      // Combine with existing orders
      final allOrders = [
        ...state.items.expand((group) => group.allOrders),
        ...newOrders,
      ];

      final groupedHistory = CustomerGroupedOrderHistory.fromOrders(allOrders);

      _currentFilter = nextPageFilter;

      state = CustomerOrderHistoryLazyState(
        items: groupedHistory,
        hasMore: newOrders.length >= _currentFilter.limit,
        isLoading: false,
        currentPage: state.currentPage + 1,
        totalLoaded: allOrders.length,
        filter: _currentFilter,
      );

      debugPrint('🛒 Lazy Loading: Load more complete - ${newOrders.length} new orders, ${allOrders.length} total');
    } catch (e) {
      debugPrint('🛒 Lazy Loading: Error loading more: $e');
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

    debugPrint('🛒 Lazy Loading: Refreshing with filter: $_currentFilter');

    // Invalidate the provider to force refresh
    _ref.invalidate(enhancedCustomerOrderHistoryProvider(_currentFilter));

    await loadInitial();
  }

  /// Update filter and refresh
  Future<void> updateFilter(CustomerDateRangeFilter newFilter) async {
    debugPrint('🛒 Lazy Loading: Updating filter from $_currentFilter to $newFilter');
    await refresh(newFilter);
  }
}

/// State for lazy loading customer order history
@immutable
class CustomerOrderHistoryLazyState {
  final List<CustomerGroupedOrderHistory> items;
  final bool hasMore;
  final bool isLoading;
  final int currentPage;
  final int totalLoaded;
  final String? error;
  final CustomerDateRangeFilter? filter;

  const CustomerOrderHistoryLazyState({
    required this.items,
    required this.hasMore,
    required this.isLoading,
    required this.currentPage,
    required this.totalLoaded,
    this.error,
    this.filter,
  });

  const CustomerOrderHistoryLazyState.initial()
      : items = const [],
        hasMore = true,
        isLoading = false,
        currentPage = 0,
        totalLoaded = 0,
        error = null,
        filter = null;

  CustomerOrderHistoryLazyState copyWith({
    List<CustomerGroupedOrderHistory>? items,
    bool? hasMore,
    bool? isLoading,
    int? currentPage,
    int? totalLoaded,
    String? error,
    CustomerDateRangeFilter? filter,
  }) {
    return CustomerOrderHistoryLazyState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      currentPage: currentPage ?? this.currentPage,
      totalLoaded: totalLoaded ?? this.totalLoaded,
      error: error,
      filter: filter ?? this.filter,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerOrderHistoryLazyState &&
          runtimeType == other.runtimeType &&
          listEquals(items, other.items) &&
          hasMore == other.hasMore &&
          isLoading == other.isLoading &&
          currentPage == other.currentPage &&
          totalLoaded == other.totalLoaded &&
          error == other.error &&
          filter == other.filter;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(items),
        hasMore,
        isLoading,
        currentPage,
        totalLoaded,
        error,
        filter,
      );

  @override
  String toString() => 'CustomerOrderHistoryLazyState('
      'items: ${items.length} groups, '
      'hasMore: $hasMore, '
      'isLoading: $isLoading, '
      'currentPage: $currentPage, '
      'totalLoaded: $totalLoaded'
      ')';
}

/// Daily statistics model for customer orders
@immutable
class CustomerDailyStats {
  final DateTime date;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalSpent;
  final double completedSpent;

  const CustomerDailyStats({
    required this.date,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalSpent,
    required this.completedSpent,
  });

  double get cancellationRate => totalOrders == 0 ? 0.0 : (cancelledOrders / totalOrders) * 100;
  double get completionRate => totalOrders == 0 ? 0.0 : (completedOrders / totalOrders) * 100;
  double get averageOrderValue => totalOrders == 0 ? 0.0 : totalSpent / totalOrders;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerDailyStats &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          totalOrders == other.totalOrders &&
          completedOrders == other.completedOrders &&
          cancelledOrders == other.cancelledOrders &&
          totalSpent == other.totalSpent &&
          completedSpent == other.completedSpent;

  @override
  int get hashCode => Object.hash(
        date,
        totalOrders,
        completedOrders,
        cancelledOrders,
        totalSpent,
        completedSpent,
      );

  @override
  String toString() => 'CustomerDailyStats('
      'date: $date, '
      'totalOrders: $totalOrders, '
      'completedOrders: $completedOrders, '
      'cancelledOrders: $cancelledOrders, '
      'totalSpent: RM${totalSpent.toStringAsFixed(2)}'
      ')';
}
