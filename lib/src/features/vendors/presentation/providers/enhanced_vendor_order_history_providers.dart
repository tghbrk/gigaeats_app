import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/data/models/order.dart';
import '../../../../data/models/user_role.dart';
import '../../data/models/vendor_date_range_filter.dart';
import '../../data/models/vendor_grouped_order_history.dart';

/// Enhanced provider for vendor order history with date filtering and pagination
final enhancedVendorOrderHistoryProvider = FutureProvider.family<List<Order>, VendorDateRangeFilter>((ref, filter) async {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.vendor) {
    debugPrint('🏪 Enhanced History: User is not a vendor, role: ${authState.user?.role}');
    return <Order>[];
  }

  final userId = authState.user?.id;
  if (userId == null) {
    debugPrint('🏪 Enhanced History: No user ID found');
    return <Order>[];
  }

  try {
    final supabase = Supabase.instance.client;
    
    debugPrint('🏪 Enhanced History: Fetching vendor profile for user: $userId');
    
    // Get vendor ID for the current user
    final vendorResponse = await supabase
        .from('vendors')
        .select('id')
        .eq('user_id', userId)
        .single();

    final vendorId = vendorResponse['id'] as String;
    debugPrint('🏪 Enhanced History: Found vendor ID: $vendorId for user: $userId');

    // Build query with date filtering (customer_name is already in orders table)
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
          )
        ''')
        .eq('vendor_id', vendorId);

    // Apply date filtering
    if (filter.startDate != null) {
      query = query.gte('created_at', filter.startDate!.toIso8601String());
      debugPrint('🏪 Enhanced History: Applied start date filter: ${filter.startDate}');
    }

    if (filter.endDate != null) {
      query = query.lte('created_at', filter.endDate!.toIso8601String());
      debugPrint('🏪 Enhanced History: Applied end date filter: ${filter.endDate}');
    }

    // Apply status filtering
    if (filter.statusFilter != null && filter.statusFilter != VendorOrderFilterStatus.all) {
      final statuses = filter.statusFilter!.orderStatuses;
      if (statuses.isNotEmpty) {
        query = query.inFilter('status', statuses);
        debugPrint('🏪 Enhanced History: Applied status filter: $statuses');
      }
    }

    // Apply ordering and pagination
    final finalQuery = query
        .order('created_at', ascending: false)
        .range(filter.offset, filter.offset + filter.limit - 1);

    debugPrint('🏪 Enhanced History: Executing query with limit: ${filter.limit}, offset: ${filter.offset}');

    final response = await finalQuery;
    debugPrint('🏪 Enhanced History: Retrieved ${response.length} orders');

    final orders = response.map((json) => Order.fromJson(json)).toList();

    // Debug order items count
    for (final order in orders) {
      debugPrint('🏪 Enhanced History: Order ${order.orderNumber}: ${order.items.length} items, Status: ${order.status.value}');
    }

    return orders;
  } catch (e, stackTrace) {
    debugPrint('🏪 Enhanced History: ERROR: $e');
    debugPrint('🏪 Enhanced History: Stack trace: $stackTrace');
    rethrow;
  }
});

/// Provider for grouped vendor order history with enhanced organization
final vendorGroupedOrderHistoryProvider = FutureProvider.family<List<VendorGroupedOrderHistory>, VendorDateRangeFilter>((ref, filter) async {
  debugPrint('🔍 [VENDOR-GROUPED-ORDER-HISTORY] ========== PROVIDER CALLED ==========');
  debugPrint('🔍 [VENDOR-GROUPED-ORDER-HISTORY] Timestamp: ${DateTime.now()}');
  debugPrint('🔍 [VENDOR-GROUPED-ORDER-HISTORY] Filter: $filter');
  debugPrint('🔍 [VENDOR-GROUPED-ORDER-HISTORY] Filter type: ${filter.runtimeType}');
  debugPrint('🔍 [VENDOR-GROUPED-ORDER-HISTORY] Filter start date: ${filter.startDate}');
  debugPrint('🔍 [VENDOR-GROUPED-ORDER-HISTORY] Filter end date: ${filter.endDate}');

  try {
    // Get orders using the enhanced provider
    final orders = await ref.read(enhancedVendorOrderHistoryProvider(filter).future);
    debugPrint('🔍 [VENDOR-GROUPED-ORDER-HISTORY] Retrieved ${orders.length} orders from enhanced provider');

    // Group orders by date
    final groupedHistory = VendorGroupedOrderHistory.fromOrders(orders);
    debugPrint('🔍 [VENDOR-GROUPED-ORDER-HISTORY] Grouped into ${groupedHistory.length} date groups');

    // Debug each group
    for (final group in groupedHistory) {
      debugPrint('🔍 [VENDOR-GROUPED-ORDER-HISTORY] Group: ${group.displayDate} (${group.dateKey}) - ${group.totalOrders} orders');
      debugPrint('🔍 [VENDOR-GROUPED-ORDER-HISTORY]   - Active: ${group.activeOrders}, Delivered: ${group.deliveredOrders}, Cancelled: ${group.cancelledOrders}');
      debugPrint('🔍 [VENDOR-GROUPED-ORDER-HISTORY]   - Revenue: RM${group.totalRevenue.toStringAsFixed(2)}, Commission: RM${group.totalCommission.toStringAsFixed(2)}');
    }

    debugPrint('🔍 [VENDOR-GROUPED-ORDER-HISTORY] ========== PROVIDER COMPLETED ==========');
    return groupedHistory;
  } catch (e, stackTrace) {
    debugPrint('🔍 [VENDOR-GROUPED-ORDER-HISTORY] ERROR: $e');
    debugPrint('🔍 [VENDOR-GROUPED-ORDER-HISTORY] Stack trace: $stackTrace');
    rethrow;
  }
});

/// Provider for vendor order history summary statistics
final vendorOrderHistorySummaryProvider = FutureProvider.family<VendorOrderHistorySummary, VendorDateRangeFilter>((ref, filter) async {
  final groupedHistory = await ref.read(vendorGroupedOrderHistoryProvider(filter).future);
  return VendorGroupedOrderHistory.getSummary(groupedHistory);
});

/// Provider for order count by date for vendor orders
final vendorOrderCountByDateProvider = FutureProvider.family<Map<String, int>, VendorDateRangeFilter>((ref, filter) async {
  final groupedHistory = await ref.read(vendorGroupedOrderHistoryProvider(filter).future);
  
  final countByDate = <String, int>{};
  for (final group in groupedHistory) {
    countByDate[group.dateKey] = group.totalOrders;
  }
  
  return countByDate;
});

/// State notifier for managing vendor date filter
class VendorDateFilterNotifier extends StateNotifier<VendorDateRangeFilter> {
  VendorDateFilterNotifier() : super(const VendorDateRangeFilter());

  /// Set custom date range
  void setCustomDateRange(DateTime? startDate, DateTime? endDate) {
    debugPrint('🏪 VendorDateFilter: Setting custom date range - Start: $startDate, End: $endDate');
    state = state.copyWith(
      startDate: startDate,
      endDate: endDate,
      offset: 0, // Reset pagination
    );
  }

  /// Set status filter
  void setStatusFilter(VendorOrderFilterStatus? statusFilter) {
    debugPrint('🏪 VendorDateFilter: Setting status filter: $statusFilter');
    state = state.copyWith(
      statusFilter: statusFilter,
      offset: 0, // Reset pagination
    );
  }

  /// Reset filter to default
  void reset() {
    debugPrint('🏪 VendorDateFilter: Resetting filter to default');
    state = const VendorDateRangeFilter();
  }

  /// Load next page
  void loadNextPage() {
    debugPrint('🏪 VendorDateFilter: Loading next page - Current offset: ${state.offset}');
    state = state.nextPage;
  }

  /// Reset to first page
  void resetPagination() {
    debugPrint('🏪 VendorDateFilter: Resetting pagination');
    state = state.firstPage;
  }

  /// Apply quick filter
  void applyQuickFilter(VendorQuickDateFilter quickFilter) {
    debugPrint('🏪 VendorDateFilter: Applying quick filter: $quickFilter');
    state = quickFilter.toDateRangeFilter();
  }
}

/// Provider for vendor date filter state
final vendorDateFilterProvider = StateNotifierProvider<VendorDateFilterNotifier, VendorDateRangeFilter>((ref) {
  return VendorDateFilterNotifier();
});

/// State notifier for managing vendor quick date filter selection
class VendorSelectedQuickFilterNotifier extends StateNotifier<VendorQuickDateFilter> {
  VendorSelectedQuickFilterNotifier() : super(VendorQuickDateFilter.all);

  void setFilter(VendorQuickDateFilter filter) {
    debugPrint('🏪 VendorQuickFilter: Setting filter: $filter');
    state = filter;
  }

  void reset() {
    debugPrint('🏪 VendorQuickFilter: Resetting to all');
    state = VendorQuickDateFilter.all;
  }
}

/// Provider for selected vendor quick filter
final vendorSelectedQuickFilterProvider = StateNotifierProvider<VendorSelectedQuickFilterNotifier, VendorQuickDateFilter>((ref) {
  return VendorSelectedQuickFilterNotifier();
});

/// Combined filter provider that merges quick filter and custom date filter
final vendorCombinedDateFilterProvider = Provider<VendorDateRangeFilter>((ref) {
  final quickFilter = ref.watch(vendorSelectedQuickFilterProvider);
  final dateFilter = ref.watch(vendorDateFilterProvider);

  debugPrint('🏪 CombinedFilter: Quick filter: $quickFilter, Date filter: ${dateFilter.description}');

  // If quick filter is not 'all' or 'custom', use the quick filter
  if (quickFilter != VendorQuickDateFilter.all && quickFilter != VendorQuickDateFilter.custom) {
    final quickDateFilter = quickFilter.toDateRangeFilter();
    debugPrint('🏪 CombinedFilter: Using quick filter result: ${quickDateFilter.description}');
    return quickDateFilter;
  }

  // Otherwise, use the custom date filter
  debugPrint('🏪 CombinedFilter: Using custom date filter: ${dateFilter.description}');
  return dateFilter;
});

/// Convenience provider that automatically uses the combined filter
final vendorAutoFilteredOrderHistoryProvider = FutureProvider<List<Order>>((ref) async {
  final filter = ref.watch(vendorCombinedDateFilterProvider);
  return ref.read(enhancedVendorOrderHistoryProvider(filter).future);
});

/// Convenience provider for auto-filtered grouped history
final vendorAutoFilteredGroupedHistoryProvider = FutureProvider<List<VendorGroupedOrderHistory>>((ref) async {
  final filter = ref.watch(vendorCombinedDateFilterProvider);
  return ref.read(vendorGroupedOrderHistoryProvider(filter).future);
});

/// Provider for persisting vendor filter preferences
final vendorFilterPersistenceProvider = Provider<VendorFilterPersistenceService>((ref) {
  return VendorFilterPersistenceService();
});

/// Provider for paginated vendor order history with performance optimizations
final paginatedVendorOrderHistoryProvider = StateNotifierProvider.family<PaginatedVendorOrderHistoryNotifier, AsyncValue<List<Order>>, VendorDateRangeFilter>((ref, filter) {
  return PaginatedVendorOrderHistoryNotifier(ref, filter);
});

/// State notifier for paginated vendor order history
class PaginatedVendorOrderHistoryNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  final Ref _ref;
  final VendorDateRangeFilter _baseFilter;
  final List<Order> _allOrders = [];
  bool _hasMore = true;
  bool _isLoading = false;

  PaginatedVendorOrderHistoryNotifier(this._ref, this._baseFilter) : super(const AsyncValue.loading()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      debugPrint('🏪 PaginatedHistory: Loading initial data');
      final orders = await _ref.read(enhancedVendorOrderHistoryProvider(_baseFilter).future);
      _allOrders.clear();
      _allOrders.addAll(orders);
      _hasMore = orders.length >= _baseFilter.limit;
      state = AsyncValue.data(List.from(_allOrders));
      debugPrint('🏪 PaginatedHistory: Loaded ${orders.length} initial orders, hasMore: $_hasMore');
    } catch (e, stackTrace) {
      debugPrint('🏪 PaginatedHistory: Error loading initial data: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) {
      debugPrint('🏪 PaginatedHistory: Skipping loadMore - isLoading: $_isLoading, hasMore: $_hasMore');
      return;
    }

    _isLoading = true;
    try {
      debugPrint('🏪 PaginatedHistory: Loading more data, current count: ${_allOrders.length}');
      final nextPageFilter = _baseFilter.copyWith(offset: _allOrders.length);
      final newOrders = await _ref.read(enhancedVendorOrderHistoryProvider(nextPageFilter).future);

      _allOrders.addAll(newOrders);
      _hasMore = newOrders.length >= _baseFilter.limit;
      state = AsyncValue.data(List.from(_allOrders));
      debugPrint('🏪 PaginatedHistory: Loaded ${newOrders.length} more orders, total: ${_allOrders.length}, hasMore: $_hasMore');
    } catch (e) {
      debugPrint('🏪 PaginatedHistory: Error loading more data: $e');
      // Don't update state on error, keep existing data
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    debugPrint('🏪 PaginatedHistory: Refreshing data');
    _allOrders.clear();
    _hasMore = true;
    state = const AsyncValue.loading();
    await _loadInitialData();
  }

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoading;
}

/// Provider for performance monitoring
final vendorOrderHistoryPerformanceProvider = Provider<VendorOrderHistoryPerformanceMonitor>((ref) {
  return VendorOrderHistoryPerformanceMonitor();
});

/// Performance monitoring service for vendor order history
class VendorOrderHistoryPerformanceMonitor {
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, Duration> _operationDurations = {};
  final List<String> _performanceLogs = [];

  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
    debugPrint('🏪 Performance: Started $operationName');
  }

  void endOperation(String operationName) {
    final startTime = _operationStartTimes[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _operationDurations[operationName] = duration;
      _performanceLogs.add('$operationName: ${duration.inMilliseconds}ms');
      debugPrint('🏪 Performance: Completed $operationName in ${duration.inMilliseconds}ms');
      _operationStartTimes.remove(operationName);
    }
  }

  Duration? getOperationDuration(String operationName) {
    return _operationDurations[operationName];
  }

  List<String> getPerformanceLogs() {
    return List.from(_performanceLogs);
  }

  void clearLogs() {
    _performanceLogs.clear();
    _operationDurations.clear();
  }
}

/// Service for persisting vendor filter preferences
class VendorFilterPersistenceService {
  static const String _keyPrefix = 'vendor_order_filter_';
  static const String _quickFilterKey = '${_keyPrefix}quick_filter';
  static const String _customFilterKey = '${_keyPrefix}custom_filter';

  /// Save quick filter preference
  Future<void> saveQuickFilter(VendorQuickDateFilter filter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_quickFilterKey, filter.name);
      debugPrint('🏪 FilterPersistence: Saved quick filter: $filter');
    } catch (e) {
      debugPrint('🏪 FilterPersistence: Error saving quick filter: $e');
    }
  }

  /// Load quick filter preference
  Future<VendorQuickDateFilter?> loadQuickFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filterName = prefs.getString(_quickFilterKey);
      if (filterName != null) {
        final filter = VendorQuickDateFilter.values.firstWhere(
          (f) => f.name == filterName,
          orElse: () => VendorQuickDateFilter.all,
        );
        debugPrint('🏪 FilterPersistence: Loaded quick filter: $filter');
        return filter;
      }
    } catch (e) {
      debugPrint('🏪 FilterPersistence: Error loading quick filter: $e');
    }
    return null;
  }

  /// Save custom filter preference
  Future<void> saveCustomFilter(VendorDateRangeFilter filter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filterJson = jsonEncode(filter.toJson());
      await prefs.setString(_customFilterKey, filterJson);
      debugPrint('🏪 FilterPersistence: Saved custom filter: ${filter.description}');
    } catch (e) {
      debugPrint('🏪 FilterPersistence: Error saving custom filter: $e');
    }
  }

  /// Load custom filter preference
  Future<VendorDateRangeFilter?> loadCustomFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filterJson = prefs.getString(_customFilterKey);
      if (filterJson != null) {
        final filterMap = jsonDecode(filterJson) as Map<String, dynamic>;
        final filter = VendorDateRangeFilter.fromJson(filterMap);
        debugPrint('🏪 FilterPersistence: Loaded custom filter: ${filter.description}');
        return filter;
      }
    } catch (e) {
      debugPrint('🏪 FilterPersistence: Error loading custom filter: $e');
    }
    return null;
  }

  /// Clear all saved filters
  Future<void> clearAllFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_quickFilterKey);
      await prefs.remove(_customFilterKey);
      debugPrint('🏪 FilterPersistence: Cleared all saved filters');
    } catch (e) {
      debugPrint('🏪 FilterPersistence: Error clearing filters: $e');
    }
  }
}
