import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/data/models/order.dart';
import '../../../../data/models/user_role.dart';
import '../../data/services/optimized_database_service.dart';
import 'enhanced_driver_order_history_providers.dart';

/// Advanced database optimization providers for driver order history

/// Provider for cursor-based pagination results
@immutable
class CursorPaginationResult {
  final List<Order> orders;
  final String? nextCursor;
  final String? prevCursor;
  final bool hasMore;
  final int totalLoaded;
  final FilterPerformanceMetrics? performanceMetrics;

  const CursorPaginationResult({
    required this.orders,
    this.nextCursor,
    this.prevCursor,
    required this.hasMore,
    required this.totalLoaded,
    this.performanceMetrics,
  });

  CursorPaginationResult copyWith({
    List<Order>? orders,
    String? nextCursor,
    String? prevCursor,
    bool? hasMore,
    int? totalLoaded,
    FilterPerformanceMetrics? performanceMetrics,
  }) {
    return CursorPaginationResult(
      orders: orders ?? this.orders,
      nextCursor: nextCursor ?? this.nextCursor,
      prevCursor: prevCursor ?? this.prevCursor,
      hasMore: hasMore ?? this.hasMore,
      totalLoaded: totalLoaded ?? this.totalLoaded,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
    );
  }

  @override
  String toString() {
    return 'CursorPaginationResult(orders: ${orders.length}, hasMore: $hasMore, totalLoaded: $totalLoaded)';
  }
}

/// Provider for cursor-based paginated order history
final cursorPaginatedOrderHistoryProvider = FutureProvider.family<CursorPaginationResult, CursorPaginationParams>((ref, params) async {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    debugPrint('🚗 CursorPagination: User is not a driver, role: ${authState.user?.role}');
    return const CursorPaginationResult(orders: [], hasMore: false, totalLoaded: 0);
  }

  final userId = authState.user?.id;
  if (userId == null) {
    debugPrint('🚗 CursorPagination: No user ID found');
    return const CursorPaginationResult(orders: [], hasMore: false, totalLoaded: 0);
  }

  try {
    final supabase = Supabase.instance.client;

    // Get driver ID
    final driverResponse = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (driverResponse == null) {
      debugPrint('🚗 CursorPagination: No driver found for user: $userId');
      return const CursorPaginationResult(orders: [], hasMore: false, totalLoaded: 0);
    }

    final driverId = driverResponse['id'] as String;
    debugPrint('🚗 CursorPagination: Found driver ID: $driverId for user: $userId');

    // Use optimized cursor pagination
    final orders = await OptimizedDatabaseService.instance.getDriverOrderHistoryCursorPaginated(
      driverId: driverId,
      startDate: params.filter.startDate,
      endDate: params.filter.endDate,
      cursorTimestamp: params.cursorTimestamp,
      cursorId: params.cursorId,
      limit: params.filter.limit,
      direction: params.direction,
    );

    // Determine cursors for next/prev pagination
    String? nextCursor;
    String? prevCursor;
    
    if (orders.isNotEmpty) {
      final lastOrder = orders.last;
      final firstOrder = orders.first;
      
      // Create cursor from timestamp and ID
      nextCursor = '${lastOrder.actualDeliveryTime?.toIso8601String() ?? lastOrder.createdAt.toIso8601String()}|${lastOrder.id}';
      prevCursor = '${firstOrder.actualDeliveryTime?.toIso8601String() ?? firstOrder.createdAt.toIso8601String()}|${firstOrder.id}';
    }

    final hasMore = orders.length >= params.filter.limit;

    debugPrint('🚗 CursorPagination: Loaded ${orders.length} orders, hasMore: $hasMore');

    return CursorPaginationResult(
      orders: orders,
      nextCursor: hasMore ? nextCursor : null,
      prevCursor: prevCursor,
      hasMore: hasMore,
      totalLoaded: orders.length,
    );
  } catch (e) {
    debugPrint('🚗 CursorPagination: Error loading orders: $e');
    return const CursorPaginationResult(orders: [], hasMore: false, totalLoaded: 0);
  }
});

/// Parameters for cursor pagination
@immutable
class CursorPaginationParams {
  final DateRangeFilter filter;
  final DateTime? cursorTimestamp;
  final String? cursorId;
  final String direction; // 'next' or 'prev'

  const CursorPaginationParams({
    required this.filter,
    this.cursorTimestamp,
    this.cursorId,
    this.direction = 'next',
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CursorPaginationParams &&
        other.filter == filter &&
        other.cursorTimestamp == cursorTimestamp &&
        other.cursorId == cursorId &&
        other.direction == direction;
  }

  @override
  int get hashCode {
    return Object.hash(filter, cursorTimestamp, cursorId, direction);
  }

  @override
  String toString() {
    return 'CursorPaginationParams(filter: $filter, cursor: $cursorTimestamp|$cursorId, direction: $direction)';
  }
}

/// Provider for aggregated order statistics
final aggregatedOrderStatsProvider = FutureProvider.family<Map<String, dynamic>, DateRangeFilter>((ref, filter) async {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    debugPrint('🚗 AggregatedStats: User is not a driver');
    return {};
  }

  final userId = authState.user?.id;
  if (userId == null) {
    debugPrint('🚗 AggregatedStats: No user ID found');
    return {};
  }

  try {
    final supabase = Supabase.instance.client;

    // Get driver ID
    final driverResponse = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (driverResponse == null) {
      debugPrint('🚗 AggregatedStats: No driver found for user: $userId');
      return {};
    }

    final driverId = driverResponse['id'] as String;
    debugPrint('🚗 AggregatedStats: Found driver ID: $driverId');

    // Get aggregated statistics
    final stats = await OptimizedDatabaseService.instance.getDriverOrderAggregatedStats(
      driverId: driverId,
      startDate: filter.startDate,
      endDate: filter.endDate,
    );

    debugPrint('🚗 AggregatedStats: Retrieved stats: ${stats.keys.join(', ')}');
    return stats;
  } catch (e) {
    debugPrint('🚗 AggregatedStats: Error loading stats: $e');
    return {};
  }
});

/// Provider for query performance analysis
final queryPerformanceAnalysisProvider = FutureProvider.family<Map<String, dynamic>, DateRangeFilter>((ref, filter) async {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    return {};
  }

  final userId = authState.user?.id;
  if (userId == null) {
    return {};
  }

  try {
    final supabase = Supabase.instance.client;

    // Get driver ID
    final driverResponse = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (driverResponse == null) {
      return {};
    }

    final driverId = driverResponse['id'] as String;

    // Analyze query performance
    final analysis = await OptimizedDatabaseService.instance.analyzeQueryPerformance(
      driverId: driverId,
      startDate: filter.startDate,
      endDate: filter.endDate,
      limit: filter.limit,
    );

    debugPrint('🚗 QueryAnalysis: Performance analysis completed');
    return analysis;
  } catch (e) {
    debugPrint('🚗 QueryAnalysis: Error analyzing performance: $e');
    return {};
  }
});

/// Provider for prefetch recommendations
final prefetchRecommendationsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, currentFilterType) async {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    return [];
  }

  final userId = authState.user?.id;
  if (userId == null) {
    return [];
  }

  try {
    final supabase = Supabase.instance.client;

    // Get driver ID
    final driverResponse = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (driverResponse == null) {
      return [];
    }

    final driverId = driverResponse['id'] as String;

    // Get prefetch recommendations
    final recommendations = await OptimizedDatabaseService.instance.getPrefetchRecommendations(
      driverId: driverId,
      currentFilterType: currentFilterType,
    );

    debugPrint('🚗 PrefetchRecommendations: Found ${recommendations.length} recommendations');
    return recommendations;
  } catch (e) {
    debugPrint('🚗 PrefetchRecommendations: Error getting recommendations: $e');
    return [];
  }
});

/// Provider for database performance metrics
final databasePerformanceMetricsProvider = Provider<Map<String, FilterPerformanceMetrics>>((ref) {
  return OptimizedDatabaseService.instance.getPerformanceMetrics();
});
