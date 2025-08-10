import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../orders/data/models/order.dart';
import '../../../orders/data/repositories/order_repository.dart';
import '../models/customer_order_history_models.dart';
import '../../../../core/services/base_repository.dart';

/// Service for customer order history operations with enhanced functionality
class CustomerOrderHistoryService extends BaseRepository {
  final OrderRepository _orderRepository;
  final SupabaseClient _supabase = Supabase.instance.client;

  CustomerOrderHistoryService({OrderRepository? orderRepository})
      : _orderRepository = orderRepository ?? OrderRepository(),
        super();

  /// Get current authenticated user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get current user's ID
  String? get currentUserId => currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get customer order history with enhanced filtering
  Future<List<Order>> getCustomerOrderHistory({
    required String customerId,
    CustomerDateRangeFilter? filter,
  }) async {
    return executeQuery(() async {
      debugPrint('🛒 CustomerOrderHistoryService: Getting order history for customer: $customerId');
      
      final actualFilter = filter ?? const CustomerDateRangeFilter();
      
      // Convert status filter to string list
      List<String>? statusFilter;
      if (actualFilter.statusFilter != null) {
        switch (actualFilter.statusFilter!) {
          case CustomerOrderFilterStatus.completed:
            statusFilter = ['delivered'];
            break;
          case CustomerOrderFilterStatus.cancelled:
            statusFilter = ['cancelled'];
            break;
          case CustomerOrderFilterStatus.active:
            statusFilter = ['delivered', 'cancelled'];
            break;
        }
      }

      return await _orderRepository.getCustomerOrderHistory(
        customerId: customerId,
        startDate: actualFilter.startDate,
        endDate: actualFilter.endDate,
        statusFilter: statusFilter,
        limit: actualFilter.limit,
        offset: actualFilter.offset,
      );
    });
  }

  /// Get customer order history with cursor-based pagination
  Future<List<Order>> getCustomerOrderHistoryCursorPaginated({
    required String customerId,
    required CustomerDateRangeFilter filter,
    DateTime? cursorTimestamp,
    String? cursorId,
    String direction = 'next',
  }) async {
    return executeQuery(() async {
      debugPrint('🛒 CustomerOrderHistoryService: Getting cursor-paginated history');
      debugPrint('🛒 CustomerOrderHistoryService: Cursor: $cursorTimestamp, $cursorId');
      
      // Convert status filter to string list
      List<String>? statusFilter;
      if (filter.statusFilter != null) {
        switch (filter.statusFilter!) {
          case CustomerOrderFilterStatus.completed:
            statusFilter = ['delivered'];
            break;
          case CustomerOrderFilterStatus.cancelled:
            statusFilter = ['cancelled'];
            break;
          case CustomerOrderFilterStatus.active:
            statusFilter = ['delivered', 'cancelled'];
            break;
        }
      }

      return await _orderRepository.getCustomerOrderHistoryCursorPaginated(
        customerId: customerId,
        startDate: filter.startDate,
        endDate: filter.endDate,
        statusFilter: statusFilter,
        cursorTimestamp: cursorTimestamp,
        cursorId: cursorId,
        limit: filter.limit,
        direction: direction,
      );
    });
  }

  /// Get customer order count
  Future<int> getCustomerOrderCount({
    required String customerId,
    CustomerDateRangeFilter? filter,
  }) async {
    return executeQuery(() async {
      debugPrint('🛒 CustomerOrderHistoryService: Getting order count for customer: $customerId');
      
      final actualFilter = filter ?? const CustomerDateRangeFilter();
      
      // Convert status filter to string list
      List<String>? statusFilter;
      if (actualFilter.statusFilter != null) {
        switch (actualFilter.statusFilter!) {
          case CustomerOrderFilterStatus.completed:
            statusFilter = ['delivered'];
            break;
          case CustomerOrderFilterStatus.cancelled:
            statusFilter = ['cancelled'];
            break;
          case CustomerOrderFilterStatus.active:
            statusFilter = ['delivered', 'cancelled'];
            break;
        }
      }

      return await _orderRepository.getCustomerOrderCount(
        customerId: customerId,
        startDate: actualFilter.startDate,
        endDate: actualFilter.endDate,
        statusFilter: statusFilter,
      );
    });
  }

  /// Get customer daily order statistics
  Future<Map<String, Map<String, dynamic>>> getCustomerDailyStats({
    required String customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      debugPrint('🛒 CustomerOrderHistoryService: Getting daily stats for customer: $customerId');
      
      return await _orderRepository.getCustomerDailyStats(
        customerId: customerId,
        startDate: startDate,
        endDate: endDate,
      );
    });
  }

  /// Get customer order summary statistics
  Future<Map<String, dynamic>> getCustomerOrderSummary({
    required String customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      debugPrint('🛒 CustomerOrderHistoryService: Getting order summary for customer: $customerId');
      
      return await _orderRepository.getCustomerOrderSummary(
        customerId: customerId,
        startDate: startDate,
        endDate: endDate,
      );
    });
  }

  /// Get orders by specific date range (optimized for daily grouping)
  Future<List<Order>> getOrdersByDateRange({
    required String customerId,
    required DateTime startDate,
    required DateTime endDate,
    List<String>? statusFilter,
  }) async {
    return executeQuery(() async {
      debugPrint('🛒 CustomerOrderHistoryService: Getting orders by date range');
      debugPrint('🛒 CustomerOrderHistoryService: Date range: $startDate to $endDate');
      
      return await _orderRepository.getCustomerOrdersByDateRange(
        customerId: customerId,
        startDate: startDate,
        endDate: endDate,
        statusFilter: statusFilter,
      );
    });
  }

  /// Get grouped order history for a customer
  Future<List<CustomerGroupedOrderHistory>> getGroupedOrderHistory({
    required String customerId,
    CustomerDateRangeFilter? filter,
  }) async {
    return executeQuery(() async {
      debugPrint('🛒 CustomerOrderHistoryService: Getting grouped order history');
      
      final orders = await getCustomerOrderHistory(
        customerId: customerId,
        filter: filter,
      );
      
      return CustomerGroupedOrderHistory.fromOrders(orders);
    });
  }

  /// Get order history summary with statistics
  Future<CustomerOrderHistorySummary> getOrderHistorySummary({
    required String customerId,
    CustomerDateRangeFilter? filter,
  }) async {
    return executeQuery(() async {
      debugPrint('🛒 CustomerOrderHistoryService: Getting order history summary');
      
      final groupedHistory = await getGroupedOrderHistory(
        customerId: customerId,
        filter: filter,
      );
      
      return CustomerGroupedOrderHistory.getSummary(groupedHistory);
    });
  }

  /// Validate filter parameters
  List<String> validateFilter(CustomerDateRangeFilter filter) {
    return filter.validate();
  }

  /// Get performance impact assessment for a filter
  CustomerFilterPerformanceImpact getFilterPerformanceImpact(CustomerDateRangeFilter filter) {
    return filter.performanceImpact;
  }

  /// Generate cursor for pagination
  String? generateCursor(Order order) {
    // createdAt is non-nullable in Order model
    return '${order.createdAt.toIso8601String()}|${order.id}';
  }

  /// Parse cursor for pagination
  Map<String, dynamic>? parseCursor(String cursor) {
    try {
      final parts = cursor.split('|');
      if (parts.length != 2) return null;
      
      return {
        'timestamp': DateTime.parse(parts[0]),
        'id': parts[1],
      };
    } catch (e) {
      debugPrint('🛒 CustomerOrderHistoryService: Error parsing cursor: $e');
      return null;
    }
  }

  /// Get optimized query suggestions based on filter
  Map<String, dynamic> getQueryOptimizationSuggestions(CustomerDateRangeFilter filter) {
    final suggestions = <String, dynamic>{
      'useIndexes': [],
      'optimizations': [],
      'warnings': [],
    };

    // Date range optimization suggestions
    if (filter.hasDateFilter) {
      suggestions['useIndexes'].add('created_at_index');
      
      final daysDiff = filter.endDate?.difference(filter.startDate ?? DateTime.now()).inDays ?? 365;
      if (daysDiff > 90) {
        suggestions['warnings'].add('Large date range may impact performance');
        suggestions['optimizations'].add('Consider using cursor pagination for large datasets');
      }
    }

    // Status filter optimization
    if (filter.hasStatusFilter) {
      suggestions['useIndexes'].add('status_index');
    }

    // Pagination optimization
    if (filter.limit > 50) {
      suggestions['warnings'].add('Large page size may impact performance');
      suggestions['optimizations'].add('Consider reducing page size to 20-50 items');
    }

    return suggestions;
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
    debugPrint('🛒 CustomerOrderHistoryService: Disposed');
  }
}
