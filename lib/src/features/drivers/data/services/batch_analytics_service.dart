import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/delivery_batch.dart';
import '../models/batch_analytics_models.dart';
import '../../../../core/monitoring/performance_monitor.dart';
import '../../../../core/utils/logger.dart';

/// Comprehensive batch analytics service for Phase 4.2
/// Provides performance tracking, metrics collection, and insights for multi-order delivery batches
class BatchAnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final AppLogger _logger = AppLogger();

  // Real-time subscriptions
  RealtimeChannel? _batchMetricsChannel;
  RealtimeChannel? _driverPerformanceChannel;
  
  // Stream controllers for real-time updates
  final StreamController<BatchPerformanceMetrics> _batchMetricsController = 
      StreamController<BatchPerformanceMetrics>.broadcast();
  final StreamController<DriverPerformanceInsights> _driverInsightsController = 
      StreamController<DriverPerformanceInsights>.broadcast();

  // Getters for streams
  Stream<BatchPerformanceMetrics> get batchMetricsStream => _batchMetricsController.stream;
  Stream<DriverPerformanceInsights> get driverInsightsStream => _driverInsightsController.stream;

  /// Initialize batch analytics service
  Future<void> initialize() async {
    debugPrint('📊 [BATCH-ANALYTICS] Initializing batch analytics service');
    
    try {
      // Initialize performance monitoring
      _performanceMonitor.initialize();
      
      debugPrint('📊 [BATCH-ANALYTICS] Batch analytics service initialized successfully');
    } catch (e) {
      _logger.logError('Failed to initialize batch analytics service', e);
      rethrow;
    }
  }

  /// Start real-time analytics tracking for a driver
  Future<void> startDriverAnalytics(String driverId) async {
    debugPrint('📊 [BATCH-ANALYTICS] Starting real-time analytics for driver: $driverId');
    
    try {
      await _subscribeToDriverMetrics(driverId);
      await _subscribeToDriverPerformance(driverId);
      
      debugPrint('📊 [BATCH-ANALYTICS] Real-time analytics started for driver: $driverId');
    } catch (e) {
      _logger.logError('Failed to start driver analytics', e);
      rethrow;
    }
  }

  /// Subscribe to batch metrics updates
  Future<void> _subscribeToDriverMetrics(String driverId) async {
    _batchMetricsChannel = _supabase.channel('batch_metrics_$driverId');
    
    _batchMetricsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'delivery_batches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: driverId,
          ),
          callback: (payload) => _handleBatchMetricsUpdate(payload),
        )
        .subscribe();
  }

  /// Subscribe to driver performance updates
  Future<void> _subscribeToDriverPerformance(String driverId) async {
    _driverPerformanceChannel = _supabase.channel('driver_performance_$driverId');
    
    _driverPerformanceChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'batch_orders',
          callback: (payload) => _handleDriverPerformanceUpdate(payload, driverId),
        )
        .subscribe();
  }

  /// Handle batch metrics updates
  void _handleBatchMetricsUpdate(PostgresChangePayload payload) {
    try {
      debugPrint('📊 [BATCH-ANALYTICS] Batch metrics update received: ${payload.eventType}');
      
      // Process the update and emit new metrics
      _processBatchMetricsUpdate(payload);
    } catch (e) {
      _logger.logError('Failed to handle batch metrics update', e);
    }
  }

  /// Handle driver performance updates
  void _handleDriverPerformanceUpdate(PostgresChangePayload payload, String driverId) {
    try {
      debugPrint('📊 [BATCH-ANALYTICS] Driver performance update received for: $driverId');
      
      // Process the update and emit new insights
      _processDriverPerformanceUpdate(payload, driverId);
    } catch (e) {
      _logger.logError('Failed to handle driver performance update', e);
    }
  }

  /// Record batch creation metrics
  Future<void> recordBatchCreation({
    required String batchId,
    required String driverId,
    required int orderCount,
    required double estimatedDistance,
    required Duration estimatedDuration,
    required Map<String, dynamic> optimizationMetrics,
  }) async {
    debugPrint('📊 [BATCH-ANALYTICS] Recording batch creation metrics for: $batchId');
    
    try {
      final metrics = {
        'batch_id': batchId,
        'driver_id': driverId,
        'order_count': orderCount,
        'estimated_distance_km': estimatedDistance,
        'estimated_duration_minutes': estimatedDuration.inMinutes,
        'optimization_score': optimizationMetrics['score'] ?? 0.0,
        'route_efficiency': optimizationMetrics['efficiency'] ?? 0.0,
        'created_at': DateTime.now().toIso8601String(),
        'event_type': 'batch_created',
      };

      await _supabase.from('batch_analytics_events').insert(metrics);
      
      // Record performance metric
      _performanceMonitor.recordMetric(
        operation: 'batch_creation',
        category: 'analytics',
        durationMs: 0,
        metadata: metrics,
      );
      
      debugPrint('📊 [BATCH-ANALYTICS] Batch creation metrics recorded successfully');
    } catch (e) {
      _logger.logError('Failed to record batch creation metrics', e);
    }
  }

  /// Record batch completion metrics
  Future<void> recordBatchCompletion({
    required String batchId,
    required String driverId,
    required Duration actualDuration,
    required double actualDistance,
    required int completedOrders,
    required int totalOrders,
    required List<Duration> orderCompletionTimes,
    required Map<String, dynamic> performanceData,
  }) async {
    debugPrint('📊 [BATCH-ANALYTICS] Recording batch completion metrics for: $batchId');
    
    try {
      final completionRate = completedOrders / totalOrders;
      final averageOrderTime = orderCompletionTimes.isNotEmpty
          ? orderCompletionTimes.map((d) => d.inMinutes).reduce((a, b) => a + b) / orderCompletionTimes.length
          : 0.0;

      final metrics = {
        'batch_id': batchId,
        'driver_id': driverId,
        'actual_duration_minutes': actualDuration.inMinutes,
        'actual_distance_km': actualDistance,
        'completed_orders': completedOrders,
        'total_orders': totalOrders,
        'completion_rate': completionRate,
        'average_order_time_minutes': averageOrderTime,
        'efficiency_score': performanceData['efficiency'] ?? 0.0,
        'customer_satisfaction': performanceData['satisfaction'] ?? 0.0,
        'completed_at': DateTime.now().toIso8601String(),
        'event_type': 'batch_completed',
      };

      await _supabase.from('batch_analytics_events').insert(metrics);
      
      // Record performance metric
      _performanceMonitor.recordMetric(
        operation: 'batch_completion',
        category: 'analytics',
        durationMs: actualDuration.inMilliseconds,
        metadata: metrics,
      );
      
      debugPrint('📊 [BATCH-ANALYTICS] Batch completion metrics recorded successfully');
    } catch (e) {
      _logger.logError('Failed to record batch completion metrics', e);
    }
  }

  /// Get batch performance metrics for a specific period
  Future<BatchPerformanceMetrics> getBatchPerformanceMetrics({
    required String driverId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    debugPrint('📊 [BATCH-ANALYTICS] Fetching batch performance metrics for driver: $driverId');
    
    try {
      final response = await _supabase
          .from('batch_analytics_events')
          .select('*')
          .eq('driver_id', driverId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      final events = response as List<dynamic>;
      return _calculateBatchPerformanceMetrics(events);
    } catch (e) {
      _logger.logError('Failed to fetch batch performance metrics', e);
      rethrow;
    }
  }

  /// Get driver performance insights
  Future<DriverPerformanceInsights> getDriverPerformanceInsights({
    required String driverId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    debugPrint('📊 [BATCH-ANALYTICS] Fetching driver performance insights for: $driverId');
    
    try {
      // Fetch batch analytics data
      final batchData = await _supabase
          .from('batch_analytics_events')
          .select('*')
          .eq('driver_id', driverId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      // Fetch order completion data
      final orderData = await _supabase
          .from('batch_orders')
          .select('*, orders!inner(*)')
          .eq('orders.driver_id', driverId)
          .gte('completed_at', startDate.toIso8601String())
          .lte('completed_at', endDate.toIso8601String());

      return _calculateDriverPerformanceInsights(batchData, orderData);
    } catch (e) {
      _logger.logError('Failed to fetch driver performance insights', e);
      rethrow;
    }
  }

  /// Calculate batch performance metrics from events
  BatchPerformanceMetrics _calculateBatchPerformanceMetrics(List<dynamic> events) {
    if (events.isEmpty) {
      return BatchPerformanceMetrics.empty();
    }

    final createdEvents = events.where((e) => e['event_type'] == 'batch_created').toList();
    final completedEvents = events.where((e) => e['event_type'] == 'batch_completed').toList();

    final totalBatches = createdEvents.length;
    final completedBatches = completedEvents.length;
    final completionRate = totalBatches > 0 ? completedBatches / totalBatches : 0.0;

    final averageOrdersPerBatch = createdEvents.isNotEmpty
        ? createdEvents.map((e) => e['order_count'] as int).reduce((a, b) => a + b) / createdEvents.length
        : 0.0;

    final averageDistance = completedEvents.isNotEmpty
        ? completedEvents.map((e) => e['actual_distance_km'] as double).reduce((a, b) => a + b) / completedEvents.length
        : 0.0;

    final averageDuration = completedEvents.isNotEmpty
        ? Duration(minutes: (completedEvents.map((e) => e['actual_duration_minutes'] as int).reduce((a, b) => a + b) / completedEvents.length).round())
        : Duration.zero;

    final averageEfficiency = completedEvents.isNotEmpty
        ? completedEvents.map((e) => e['efficiency_score'] as double).reduce((a, b) => a + b) / completedEvents.length
        : 0.0;

    return BatchPerformanceMetrics(
      totalBatches: totalBatches,
      completedBatches: completedBatches,
      completionRate: completionRate,
      averageOrdersPerBatch: averageOrdersPerBatch,
      averageDistance: averageDistance,
      averageDuration: averageDuration,
      averageEfficiencyScore: averageEfficiency,
      totalOrders: createdEvents.fold(0, (sum, e) => sum + (e['order_count'] as int)),
      successfulDeliveries: completedEvents.fold(0, (sum, e) => sum + (e['completed_orders'] as int)),
    );
  }

  /// Calculate driver performance insights
  DriverPerformanceInsights _calculateDriverPerformanceInsights(
    List<dynamic> batchData,
    List<dynamic> orderData,
  ) {
    // Implementation will be added in next chunk
    return DriverPerformanceInsights.empty();
  }

  /// Process batch metrics update for real-time streaming
  void _processBatchMetricsUpdate(PostgresChangePayload payload) {
    // Implementation will be added in next chunk
  }

  /// Process driver performance update for real-time streaming
  void _processDriverPerformanceUpdate(PostgresChangePayload payload, String driverId) {
    // Implementation will be added in next chunk
  }

  /// Stop real-time analytics tracking
  Future<void> stopAnalytics() async {
    debugPrint('📊 [BATCH-ANALYTICS] Stopping real-time analytics');
    
    try {
      await _batchMetricsChannel?.unsubscribe();
      await _driverPerformanceChannel?.unsubscribe();
      
      _batchMetricsChannel = null;
      _driverPerformanceChannel = null;
      
      debugPrint('📊 [BATCH-ANALYTICS] Real-time analytics stopped');
    } catch (e) {
      _logger.logError('Failed to stop analytics', e);
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    debugPrint('📊 [BATCH-ANALYTICS] Disposing batch analytics service');
    
    await stopAnalytics();
    await _batchMetricsController.close();
    await _driverInsightsController.close();
    
    debugPrint('📊 [BATCH-ANALYTICS] Batch analytics service disposed');
  }
}
