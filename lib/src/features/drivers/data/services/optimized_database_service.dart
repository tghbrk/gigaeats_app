

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../orders/data/models/order.dart';
import '../../data/models/grouped_order_history.dart';
import '../../presentation/providers/enhanced_driver_order_history_providers.dart';

/// Advanced optimized database service with performance monitoring and cursor pagination
class OptimizedDatabaseService {
  static OptimizedDatabaseService? _instance;
  static OptimizedDatabaseService get instance => _instance ??= OptimizedDatabaseService._();

  OptimizedDatabaseService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Performance monitoring
  final Map<String, FilterPerformanceMetrics> _performanceCache = {};
  final Map<String, DateTime> _queryTimestamps = {};

  // Query optimization flags
  static const int _largeDatassetThreshold = 1000;
  static const int _cursorPaginationThreshold = 100;

  /// Get driver order history using optimized database function
  Future<List<Order>> getDriverOrderHistory({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      debugPrint('🚗 OptimizedDB: Fetching order history for driver: $driverId');
      debugPrint('🚗 OptimizedDB: Date range: $startDate to $endDate, limit: $limit, offset: $offset');

      final response = await _supabase.rpc(
        'get_driver_order_history_optimized',
        params: {
          'p_driver_id': driverId,
          'p_start_date': startDate?.toIso8601String(),
          'p_end_date': endDate?.toIso8601String(),
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      if (response == null) {
        debugPrint('🚗 OptimizedDB: No data returned from function');
        return [];
      }

      final orders = <Order>[];
      for (final row in response as List<dynamic>) {
        try {
          // Convert the function result to Order format
          final orderData = _convertFunctionResultToOrder(row as Map<String, dynamic>);
          orders.add(Order.fromJson(orderData));
        } catch (e) {
          debugPrint('🚗 OptimizedDB: Error parsing order row: $e');
          debugPrint('🚗 OptimizedDB: Row data: $row');
        }
      }

      debugPrint('🚗 OptimizedDB: Successfully parsed ${orders.length} orders');
      return orders;
    } catch (e) {
      debugPrint('🚗 OptimizedDB: Error fetching order history: $e');
      rethrow;
    }
  }

  /// Count driver orders using optimized database function
  Future<int> countDriverOrders({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('🚗 OptimizedDB: Counting orders for driver: $driverId');

      final response = await _supabase.rpc(
        'count_driver_orders_optimized',
        params: {
          'p_driver_id': driverId,
          'p_start_date': startDate?.toIso8601String(),
          'p_end_date': endDate?.toIso8601String(),
        },
      );

      final count = response as int? ?? 0;
      debugPrint('🚗 OptimizedDB: Order count: $count');
      return count;
    } catch (e) {
      debugPrint('🚗 OptimizedDB: Error counting orders: $e');
      return 0;
    }
  }

  /// Get driver order statistics using optimized database function
  Future<OrderHistorySummary> getDriverOrderStats({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('🚗 OptimizedDB: Fetching order stats for driver: $driverId');

      final response = await _supabase.rpc(
        'get_driver_order_stats_optimized',
        params: {
          'p_driver_id': driverId,
          'p_start_date': startDate?.toIso8601String(),
          'p_end_date': endDate?.toIso8601String(),
        },
      );

      if (response == null || (response as List).isEmpty) {
        debugPrint('🚗 OptimizedDB: No stats data returned');
        return const OrderHistorySummary(
          totalOrders: 0,
          totalEarnings: 0.0,
          deliveredOrders: 0,
          cancelledOrders: 0,
        );
      }

      final stats = response.first as Map<String, dynamic>;
      
      final summary = OrderHistorySummary(
        totalOrders: stats['total_orders'] as int? ?? 0,
        totalEarnings: (stats['total_earnings'] as num?)?.toDouble() ?? 0.0,
        deliveredOrders: stats['delivered_orders'] as int? ?? 0,
        cancelledOrders: stats['cancelled_orders'] as int? ?? 0,
        dateRange: startDate != null && endDate != null 
            ? DateRange(start: startDate, end: endDate)
            : null,
      );

      debugPrint('🚗 OptimizedDB: Stats - Total: ${summary.totalOrders}, Delivered: ${summary.deliveredOrders}, Earnings: ${summary.totalEarnings}');
      return summary;
    } catch (e) {
      debugPrint('🚗 OptimizedDB: Error fetching order stats: $e');
      return const OrderHistorySummary(
        totalOrders: 0,
        totalEarnings: 0.0,
        deliveredOrders: 0,
        cancelledOrders: 0,
      );
    }
  }

  /// Get daily order statistics using optimized database function
  Future<Map<String, int>> getDailyOrderStats({
    required String driverId,
    int daysBack = 30,
  }) async {
    try {
      debugPrint('🚗 OptimizedDB: Fetching daily stats for driver: $driverId, days back: $daysBack');

      final response = await _supabase.rpc(
        'get_driver_daily_stats_optimized',
        params: {
          'p_driver_id': driverId,
          'p_days_back': daysBack,
        },
      );

      if (response == null) {
        debugPrint('🚗 OptimizedDB: No daily stats data returned');
        return {};
      }

      final dailyStats = <String, int>{};
      for (final row in response as List<dynamic>) {
        final data = row as Map<String, dynamic>;
        final dateStr = data['order_date'] as String?;
        final orderCount = data['order_count'] as int? ?? 0;
        
        if (dateStr != null) {
          dailyStats[dateStr] = orderCount;
        }
      }

      debugPrint('🚗 OptimizedDB: Daily stats for ${dailyStats.length} days');
      return dailyStats;
    } catch (e) {
      debugPrint('🚗 OptimizedDB: Error fetching daily stats: $e');
      return {};
    }
  }

  /// Convert database function result to Order JSON format
  Map<String, dynamic> _convertFunctionResultToOrder(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'order_number': row['order_number'],
      'vendor_id': row['vendor_id'],
      'customer_id': row['customer_id'],
      'customer_name': row['customer_name'],
      'status': row['status'],
      'total_amount': row['total_amount'],
      'delivery_fee': row['delivery_fee'] ?? 0,
      'commission_amount': row['commission_amount'] ?? 0,
      'created_at': row['created_at'],
      'actual_delivery_time': row['actual_delivery_time'],
      'delivery_address': row['delivery_address'] ?? {},
      
      // Vendor information
      'vendors': {
        'business_name': row['vendor_name'],
        'business_address': row['vendor_address'],
      },
      
      // Mock order items (since we have the count)
      'order_items': _generateMockOrderItems(
        row['item_count'] as int? ?? 0,
        row['id'] as String,
      ),
      
      // Additional fields that might be needed
      'delivery_method': 'own_fleet', // Assume own fleet for driver orders
      'payment_status': 'completed', // Assume completed for delivered orders
      'assigned_driver_id': row['assigned_driver_id'] ?? '',
    };
  }

  /// Generate mock order items for the count
  List<Map<String, dynamic>> _generateMockOrderItems(int count, String orderId) {
    return List.generate(count, (index) => {
      'id': 'mock_item_${orderId}_$index',
      'order_id': orderId,
      'quantity': 1,
      'price': 0.0,
      'menu_item': {
        'id': 'mock_menu_item_$index',
        'name': 'Menu Item ${index + 1}',
        'image_url': null,
      },
    });
  }

  /// Test database function performance
  Future<Map<String, dynamic>> testPerformance({
    required String driverId,
    int iterations = 5,
  }) async {
    final results = <String, List<int>>{
      'history_query': [],
      'count_query': [],
      'stats_query': [],
      'daily_stats_query': [],
    };

    for (int i = 0; i < iterations; i++) {
      // Test history query
      final historyStart = DateTime.now();
      await getDriverOrderHistory(driverId: driverId, limit: 20);
      final historyDuration = DateTime.now().difference(historyStart).inMilliseconds;
      results['history_query']!.add(historyDuration);

      // Test count query
      final countStart = DateTime.now();
      await countDriverOrders(driverId: driverId);
      final countDuration = DateTime.now().difference(countStart).inMilliseconds;
      results['count_query']!.add(countDuration);

      // Test stats query
      final statsStart = DateTime.now();
      await getDriverOrderStats(driverId: driverId);
      final statsDuration = DateTime.now().difference(statsStart).inMilliseconds;
      results['stats_query']!.add(statsDuration);

      // Test daily stats query
      final dailyStart = DateTime.now();
      await getDailyOrderStats(driverId: driverId);
      final dailyDuration = DateTime.now().difference(dailyStart).inMilliseconds;
      results['daily_stats_query']!.add(dailyDuration);

      // Small delay between iterations
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Calculate averages
    final performance = <String, dynamic>{};
    for (final entry in results.entries) {
      final times = entry.value;
      final average = times.reduce((a, b) => a + b) / times.length;
      final min = times.reduce((a, b) => a < b ? a : b);
      final max = times.reduce((a, b) => a > b ? a : b);
      
      performance[entry.key] = {
        'average_ms': average.round(),
        'min_ms': min,
        'max_ms': max,
        'iterations': iterations,
      };
    }

    debugPrint('🚗 OptimizedDB: Performance test results: $performance');
    return performance;
  }

  /// Get driver order history using cursor-based pagination for large datasets
  Future<List<Order>> getDriverOrderHistoryCursorPaginated({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? cursorTimestamp,
    String? cursorId,
    int limit = 20,
    String direction = 'next',
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🚗 OptimizedDB: Cursor paginated fetch for driver: $driverId');
      debugPrint('🚗 OptimizedDB: Cursor: $cursorTimestamp, ID: $cursorId, direction: $direction');

      final response = await _supabase.rpc(
        'get_driver_order_history_cursor_paginated',
        params: {
          'p_driver_id': driverId,
          'p_start_date': startDate?.toIso8601String(),
          'p_end_date': endDate?.toIso8601String(),
          'p_cursor_timestamp': cursorTimestamp?.toIso8601String(),
          'p_cursor_id': cursorId,
          'p_limit': limit,
          'p_direction': direction,
        },
      );

      if (response == null) {
        debugPrint('🚗 OptimizedDB: No cursor paginated data returned');
        return [];
      }

      final orders = (response as List)
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();

      stopwatch.stop();
      _recordPerformanceMetrics(
        'cursor_paginated_${driverId}_${direction}',
        stopwatch.elapsed,
        orders.length,
        false, // Not from cache
        'Cursor paginated query: ${startDate ?? 'no start'} to ${endDate ?? 'no end'}',
      );

      debugPrint('🚗 OptimizedDB: Cursor paginated fetch completed: ${orders.length} orders in ${stopwatch.elapsedMilliseconds}ms');
      return orders;
    } catch (e) {
      stopwatch.stop();
      debugPrint('🚗 OptimizedDB: Error in cursor paginated fetch: $e');
      return [];
    }
  }

  /// Get aggregated statistics for driver order history
  Future<Map<String, dynamic>> getDriverOrderAggregatedStats({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('🚗 OptimizedDB: Fetching aggregated stats for driver: $driverId');

      final response = await _supabase.rpc(
        'get_driver_order_history_aggregated_stats',
        params: {
          'p_driver_id': driverId,
          'p_start_date': startDate?.toIso8601String(),
          'p_end_date': endDate?.toIso8601String(),
        },
      );

      if (response == null || response.isEmpty) {
        debugPrint('🚗 OptimizedDB: No aggregated stats data returned');
        return {};
      }

      final stats = (response as List).first;

      stopwatch.stop();
      _recordPerformanceMetrics(
        'aggregated_stats_$driverId',
        stopwatch.elapsed,
        1,
        false,
        'Aggregated statistics query',
      );

      debugPrint('🚗 OptimizedDB: Aggregated stats completed in ${stopwatch.elapsedMilliseconds}ms');
      return stats;
    } catch (e) {
      stopwatch.stop();
      debugPrint('🚗 OptimizedDB: Error fetching aggregated stats: $e');
      return {};
    }
  }

  /// Analyze query performance for optimization recommendations
  Future<Map<String, dynamic>> analyzeQueryPerformance({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
  }) async {
    try {
      debugPrint('🚗 OptimizedDB: Analyzing query performance for driver: $driverId');

      final response = await _supabase.rpc(
        'analyze_driver_order_query_performance',
        params: {
          'p_driver_id': driverId,
          'p_start_date': startDate?.toIso8601String(),
          'p_end_date': endDate?.toIso8601String(),
          'p_limit': limit,
        },
      );

      if (response == null || response.isEmpty) {
        debugPrint('🚗 OptimizedDB: No performance analysis data returned');
        return {};
      }

      final analysis = (response as List).first;
      debugPrint('🚗 OptimizedDB: Query analysis completed');
      return analysis;
    } catch (e) {
      debugPrint('🚗 OptimizedDB: Error analyzing query performance: $e');
      return {};
    }
  }

  /// Get prefetch recommendations based on usage patterns
  Future<List<Map<String, dynamic>>> getPrefetchRecommendations({
    required String driverId,
    String currentFilterType = 'all',
  }) async {
    try {
      debugPrint('🚗 OptimizedDB: Getting prefetch recommendations for driver: $driverId');

      final response = await _supabase.rpc(
        'get_driver_order_prefetch_recommendations',
        params: {
          'p_driver_id': driverId,
          'p_current_filter_type': currentFilterType,
        },
      );

      if (response == null) {
        debugPrint('🚗 OptimizedDB: No prefetch recommendations returned');
        return [];
      }

      final recommendations = (response as List)
          .map((json) => json as Map<String, dynamic>)
          .toList();

      debugPrint('🚗 OptimizedDB: Found ${recommendations.length} prefetch recommendations');
      return recommendations;
    } catch (e) {
      debugPrint('🚗 OptimizedDB: Error getting prefetch recommendations: $e');
      return [];
    }
  }

  /// Record performance metrics for monitoring
  void _recordPerformanceMetrics(
    String queryKey,
    Duration loadTime,
    int recordCount,
    bool fromCache,
    String description,
  ) {
    final metrics = FilterPerformanceMetrics(
      loadTime: loadTime,
      recordCount: recordCount,
      timestamp: DateTime.now(),
      fromCache: fromCache,
      filterDescription: description,
    );

    _performanceCache[queryKey] = metrics;
    _queryTimestamps[queryKey] = DateTime.now();

    // Keep only recent metrics (last 100 entries)
    if (_performanceCache.length > 100) {
      final oldestKey = _queryTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _performanceCache.remove(oldestKey);
      _queryTimestamps.remove(oldestKey);
    }

    debugPrint('🚗 OptimizedDB: Recorded metrics for $queryKey: ${loadTime.inMilliseconds}ms, $recordCount records');
  }

  /// Get performance metrics for monitoring
  Map<String, FilterPerformanceMetrics> getPerformanceMetrics() {
    return Map.unmodifiable(_performanceCache);
  }

  /// Clear performance metrics cache
  void clearPerformanceMetrics() {
    _performanceCache.clear();
    _queryTimestamps.clear();
    debugPrint('🚗 OptimizedDB: Performance metrics cache cleared');
  }
}
