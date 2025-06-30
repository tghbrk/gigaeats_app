import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

import '../../../orders/data/models/order.dart';
import '../../../orders/data/services/customer/customer_order_service.dart';
import '../../../orders/presentation/providers/customer/customer_order_provider.dart';
import '../../../marketplace_wallet/presentation/providers/loyalty_provider.dart';
import 'customer_profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'customer_order_statistics_provider.freezed.dart';

/// Customer order statistics model
@freezed
class CustomerOrderStatistics with _$CustomerOrderStatistics {
  const factory CustomerOrderStatistics({
    @Default(0) int totalOrders,
    @Default(0) int completedOrders,
    @Default(0) int cancelledOrders,
    @Default(0) int activeOrders,
    @Default(0.0) double totalSpent,
    @Default(0.0) double averageOrderValue,
    @Default(0.0) double monthlySpending,
    @Default(0.0) double yearlySpending,
    Order? lastOrder,
    Order? favoriteVendorOrder,
    @Default([]) List<Order> recentOrders,
    @Default({}) Map<String, int> ordersByStatus,
    @Default({}) Map<String, double> spendingByMonth,
    @Default({}) Map<String, int> ordersByVendor,
    @Default({}) Map<String, double> spendingByVendor,
    DateTime? firstOrderDate,
    DateTime? lastOrderDate,
    @Default(0) int daysAsCustomer,
    @Default(0.0) double averageMonthlyOrders,
  }) = _CustomerOrderStatistics;
}

/// State for customer order statistics
@freezed
class CustomerOrderStatisticsState with _$CustomerOrderStatisticsState {
  const factory CustomerOrderStatisticsState({
    @Default(false) bool isLoading,
    String? error,
    CustomerOrderStatistics? statistics,
    @Default('all_time') String selectedPeriod,
    DateTime? startDate,
    DateTime? endDate,
  }) = _CustomerOrderStatisticsState;
}

/// Customer order statistics notifier
class CustomerOrderStatisticsNotifier extends StateNotifier<CustomerOrderStatisticsState> {
  CustomerOrderStatisticsNotifier({
    required CustomerOrderService orderService,
  }) : _orderService = orderService,
       super(const CustomerOrderStatisticsState());

  final CustomerOrderService _orderService;

  /// Load order statistics for the current customer
  Future<void> loadStatistics({
    String period = 'all_time',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Get current user ID from Supabase auth
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Get all customer orders
      final orders = await _orderService.getCustomerOrders(user.id);
      
      // Filter orders by period if specified
      final filteredOrders = _filterOrdersByPeriod(orders, period, startDate, endDate);
      
      // Calculate statistics
      final statistics = _calculateStatistics(filteredOrders, orders);
      
      state = state.copyWith(
        isLoading: false,
        statistics: statistics,
        selectedPeriod: period,
        startDate: startDate,
        endDate: endDate,
      );
      
      debugPrint('Customer order statistics loaded: ${statistics.totalOrders} orders, RM${statistics.totalSpent.toStringAsFixed(2)} spent');
    } catch (e) {
      debugPrint('Error loading customer order statistics: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Filter orders by time period
  List<Order> _filterOrdersByPeriod(
    List<Order> orders, 
    String period, 
    DateTime? startDate, 
    DateTime? endDate,
  ) {
    if (period == 'all_time' && startDate == null && endDate == null) {
      return orders;
    }

    final now = DateTime.now();
    DateTime filterStartDate;
    DateTime filterEndDate = endDate ?? now;

    if (startDate != null) {
      filterStartDate = startDate;
    } else {
      switch (period) {
        case 'this_month':
          filterStartDate = DateTime(now.year, now.month, 1);
          break;
        case 'last_month':
          final lastMonth = DateTime(now.year, now.month - 1, 1);
          filterStartDate = lastMonth;
          filterEndDate = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
          break;
        case 'this_year':
          filterStartDate = DateTime(now.year, 1, 1);
          break;
        case 'last_year':
          filterStartDate = DateTime(now.year - 1, 1, 1);
          filterEndDate = DateTime(now.year, 1, 1).subtract(const Duration(days: 1));
          break;
        case 'last_30_days':
          filterStartDate = now.subtract(const Duration(days: 30));
          break;
        case 'last_90_days':
          filterStartDate = now.subtract(const Duration(days: 90));
          break;
        default:
          return orders;
      }
    }

    return orders.where((order) {
      return order.createdAt.isAfter(filterStartDate) && 
             order.createdAt.isBefore(filterEndDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Calculate comprehensive order statistics
  CustomerOrderStatistics _calculateStatistics(List<Order> filteredOrders, List<Order> allOrders) {
    if (filteredOrders.isEmpty) {
      return const CustomerOrderStatistics();
    }

    // Basic counts
    final totalOrders = filteredOrders.length;
    final completedOrders = filteredOrders.where((o) => o.status == OrderStatus.delivered).length;
    final cancelledOrders = filteredOrders.where((o) => o.status == OrderStatus.cancelled).length;
    final activeOrders = filteredOrders.where((o) => 
      o.status != OrderStatus.delivered && 
      o.status != OrderStatus.cancelled
    ).length;

    // Financial calculations
    final completedOrdersList = filteredOrders.where((o) => o.status == OrderStatus.delivered).toList();
    final totalSpent = completedOrdersList.fold<double>(0, (sum, order) => sum + order.totalAmount);
    final averageOrderValue = completedOrders > 0 ? totalSpent / completedOrders : 0.0;

    // Time-based calculations
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final thisYear = DateTime(now.year, 1, 1);
    
    final monthlySpending = allOrders
        .where((o) => o.status == OrderStatus.delivered && o.createdAt.isAfter(thisMonth))
        .fold<double>(0, (sum, order) => sum + order.totalAmount);
    
    final yearlySpending = allOrders
        .where((o) => o.status == OrderStatus.delivered && o.createdAt.isAfter(thisYear))
        .fold<double>(0, (sum, order) => sum + order.totalAmount);

    // Recent orders (last 5)
    final recentOrders = List<Order>.from(filteredOrders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
      ..take(5);

    // Last order
    final lastOrder = filteredOrders.isNotEmpty 
        ? filteredOrders.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
        : null;

    // Orders by status
    final ordersByStatus = <String, int>{};
    for (final status in OrderStatus.values) {
      final count = filteredOrders.where((o) => o.status == status).length;
      if (count > 0) {
        ordersByStatus[status.displayName] = count;
      }
    }

    // Spending by month (last 12 months)
    final spendingByMonth = <String, double>{};
    for (int i = 0; i < 12; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);
      final monthlyTotal = allOrders
          .where((o) => 
            o.status == OrderStatus.delivered &&
            o.createdAt.isAfter(month) && 
            o.createdAt.isBefore(nextMonth))
          .fold<double>(0, (sum, order) => sum + order.totalAmount);
      
      if (monthlyTotal > 0) {
        spendingByMonth['${month.year}-${month.month.toString().padLeft(2, '0')}'] = monthlyTotal;
      }
    }

    // Orders and spending by vendor
    final ordersByVendor = <String, int>{};
    final spendingByVendor = <String, double>{};
    
    for (final order in filteredOrders) {
      ordersByVendor[order.vendorName] = (ordersByVendor[order.vendorName] ?? 0) + 1;
      
      if (order.status == OrderStatus.delivered) {
        spendingByVendor[order.vendorName] = (spendingByVendor[order.vendorName] ?? 0) + order.totalAmount;
      }
    }

    // Favorite vendor (most orders)
    final favoriteVendorOrder = ordersByVendor.isNotEmpty
        ? filteredOrders.firstWhere(
            (order) => order.vendorName == ordersByVendor.entries
                .reduce((a, b) => a.value > b.value ? a : b).key,
            orElse: () => filteredOrders.first,
          )
        : null;

    // Customer tenure
    final firstOrderDate = allOrders.isNotEmpty
        ? allOrders.reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b).createdAt
        : null;
    
    final lastOrderDate = allOrders.isNotEmpty
        ? allOrders.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b).createdAt
        : null;

    final daysAsCustomer = firstOrderDate != null 
        ? now.difference(firstOrderDate).inDays 
        : 0;

    final averageMonthlyOrders = daysAsCustomer > 30 
        ? (allOrders.length / (daysAsCustomer / 30.0)) 
        : 0.0;

    return CustomerOrderStatistics(
      totalOrders: totalOrders,
      completedOrders: completedOrders,
      cancelledOrders: cancelledOrders,
      activeOrders: activeOrders,
      totalSpent: totalSpent,
      averageOrderValue: averageOrderValue,
      monthlySpending: monthlySpending,
      yearlySpending: yearlySpending,
      lastOrder: lastOrder,
      favoriteVendorOrder: favoriteVendorOrder,
      recentOrders: recentOrders.toList(),
      ordersByStatus: ordersByStatus,
      spendingByMonth: spendingByMonth,
      ordersByVendor: ordersByVendor,
      spendingByVendor: spendingByVendor,
      firstOrderDate: firstOrderDate,
      lastOrderDate: lastOrderDate,
      daysAsCustomer: daysAsCustomer,
      averageMonthlyOrders: averageMonthlyOrders,
    );
  }

  /// Refresh statistics
  Future<void> refresh() async {
    await loadStatistics(
      period: state.selectedPeriod,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  /// Change time period and reload
  Future<void> changePeriod(String period) async {
    await loadStatistics(period: period);
  }

  /// Set custom date range
  Future<void> setDateRange(DateTime startDate, DateTime endDate) async {
    await loadStatistics(
      period: 'custom',
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for customer order statistics
final customerOrderStatisticsProvider = StateNotifierProvider<CustomerOrderStatisticsNotifier, CustomerOrderStatisticsState>((ref) {
  final orderService = ref.watch(customerOrderServiceProvider);
  
  return CustomerOrderStatisticsNotifier(
    orderService: orderService,
  );
});

/// Provider for quick order statistics (for profile overview)
final customerOrderQuickStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  if (kDebugMode) debugPrint('🔍 [STATS-PROVIDER] Loading customer order quick stats...');

  // Get current user ID
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    if (kDebugMode) debugPrint('🔍 [STATS-PROVIDER] No authenticated user found');
    return {};
  }

  // Fetch customer orders and calculate statistics
  final orderService = ref.read(customerOrderServiceProvider);
  final orders = await orderService.getCustomerOrders(user.id);

  if (kDebugMode) debugPrint('🔍 [STATS-PROVIDER] Fetched ${orders.length} orders for statistics calculation');

  // Calculate statistics from orders
  final totalOrders = orders.length;
  final completedOrders = orders.where((o) => o.status == OrderStatus.delivered).toList();
  final totalSpent = completedOrders.fold<double>(0, (sum, order) => sum + order.totalAmount);
  final activeOrders = orders.where((o) =>
    o.status != OrderStatus.delivered &&
    o.status != OrderStatus.cancelled
  ).length;
  final averageOrderValue = completedOrders.isNotEmpty ? totalSpent / completedOrders.length : 0.0;

  if (kDebugMode) debugPrint('🔍 [STATS-PROVIDER] Calculated stats: $totalOrders orders, RM$totalSpent spent, ${completedOrders.length} completed');

  // Get loyalty points from loyalty provider (real data from loyalty_accounts table)
  int loyaltyPoints = 0;
  try {
    // Import loyalty provider to get real loyalty points
    final loyaltyState = ref.read(loyaltyProvider);
    loyaltyPoints = loyaltyState.availablePoints;
    if (kDebugMode) debugPrint('🔍 [STATS-PROVIDER] Loyalty points from loyalty provider: $loyaltyPoints');
  } catch (e) {
    if (kDebugMode) debugPrint('🔍 [STATS-PROVIDER] Loyalty provider failed: $e, using profile fallback');
    // Fallback to profile loyalty points if loyalty provider fails
    final profileState = ref.read(customerProfileProvider);
    loyaltyPoints = profileState.profile?.loyaltyPoints ?? 0;
    if (kDebugMode) debugPrint('🔍 [STATS-PROVIDER] Loyalty points from profile: $loyaltyPoints');
  }

  final result = {
    'totalOrders': totalOrders,
    'totalSpent': totalSpent,
    'completedOrders': completedOrders.length,
    'activeOrders': activeOrders,
    'averageOrderValue': averageOrderValue,
    'monthlySpending': 0.0, // Would need separate calculation for current month
    'daysAsCustomer': 0, // Would need separate calculation based on first order date
    'favoriteVendor': null, // Would need separate calculation based on vendor frequency
    'loyaltyPoints': loyaltyPoints, // Real loyalty points from loyalty system
  };

  if (kDebugMode) debugPrint('🔍 [STATS-PROVIDER] Final stats result: $result');
  return result;
});
