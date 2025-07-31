import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/route_optimization_models.dart';
import '../../../../core/monitoring/performance_monitor.dart';
import '../../../../core/utils/logger.dart';

/// Route Optimization Metrics Dashboard Service
/// Provides real-time dashboard data for batch order statistics, route efficiency metrics,
/// driver utilization rates, and system performance indicators
class RouteOptimizationMetricsDashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;
  // ignore: unused_field
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor(); // TODO: Use for performance monitoring
  final AppLogger _logger = AppLogger();

  // Real-time subscriptions
  RealtimeChannel? _batchMetricsChannel;
  RealtimeChannel? _routeOptimizationChannel;
  RealtimeChannel? _performanceMetricsChannel;

  // Dashboard data streams
  final StreamController<RouteOptimizationDashboardData> _dashboardController = 
      StreamController<RouteOptimizationDashboardData>.broadcast();
  
  Stream<RouteOptimizationDashboardData> get dashboardStream => _dashboardController.stream;

  /// Initialize real-time dashboard monitoring
  Future<void> initializeDashboard() async {
    try {
      await _subscribeToMetrics();
      await _loadInitialDashboardData();
      
      _logger.logInfo('Route optimization dashboard initialized');
    } catch (e) {
      _logger.logError('Failed to initialize dashboard', e);
      rethrow;
    }
  }

  /// Get comprehensive dashboard data
  Future<RouteOptimizationDashboardData> getDashboardData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? now.subtract(const Duration(hours: 24));
      final end = endDate ?? now;

      // Fetch all dashboard metrics in parallel
      final results = await Future.wait([
        _getBatchStatistics(start, end),
        _getRouteEfficiencyMetrics(start, end),
        _getDriverUtilizationRates(start, end),
        _getSystemPerformanceIndicators(start, end),
        _getAlgorithmPerformanceComparison(start, end),
        _getRealtimeMetrics(),
      ]);

      final dashboardData = RouteOptimizationDashboardData(
        batchStatistics: results[0] as BatchStatistics,
        routeEfficiencyMetrics: results[1] as RouteEfficiencyMetrics,
        driverUtilizationRates: results[2] as DriverUtilizationRates,
        systemPerformanceIndicators: results[3] as SystemPerformanceIndicators,
        algorithmPerformanceComparison: results[4] as List<TSPAlgorithmComparison>,
        realtimeMetrics: results[5] as RealtimeMetrics,
        period: DateRange(start: start, end: end),
        lastUpdated: DateTime.now(),
      );

      // Emit to stream
      _dashboardController.add(dashboardData);

      return dashboardData;
    } catch (e) {
      _logger.logError('Failed to get dashboard data', e);
      rethrow;
    }
  }

  /// Get batch statistics
  Future<BatchStatistics> _getBatchStatistics(DateTime start, DateTime end) async {
    final data = await _supabase
        .from('delivery_batches')
        .select('*')
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String());

    final totalBatches = data.length;
    final completedBatches = data.where((b) => b['status'] == 'completed').length;
    final activeBatches = data.where((b) => b['status'] == 'active').length;
    final cancelledBatches = data.where((b) => b['status'] == 'cancelled').length;

    final averageOrdersPerBatch = data.isEmpty ? 0.0 : 
        await _getAverageOrdersPerBatch(data.map((b) => b['id'] as String).toList());

    final averageOptimizationScore = data.isEmpty ? 0.0 :
        data.where((b) => b['optimization_score'] != null)
            .map((b) => b['optimization_score'] as double)
            .fold(0.0, (sum, score) => sum + score) / 
        data.where((b) => b['optimization_score'] != null).length;

    return BatchStatistics(
      totalBatches: totalBatches,
      completedBatches: completedBatches,
      activeBatches: activeBatches,
      cancelledBatches: cancelledBatches,
      completionRate: totalBatches > 0 ? (completedBatches / totalBatches) * 100 : 0.0,
      averageOrdersPerBatch: averageOrdersPerBatch,
      averageOptimizationScore: averageOptimizationScore,
    );
  }

  /// Get route efficiency metrics
  Future<RouteEfficiencyMetrics> _getRouteEfficiencyMetrics(DateTime start, DateTime end) async {
    final data = await _supabase
        .from('route_optimizations')
        .select('*')
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String());

    if (data.isEmpty) {
      return RouteEfficiencyMetrics.empty();
    }

    final totalDistanceKm = data
        .map((r) => (r['total_distance_meters'] as int) / 1000.0)
        .fold(0.0, (sum, distance) => sum + distance);

    final totalDurationHours = data
        .map((r) => (r['estimated_duration_seconds'] as int) / 3600.0)
        .fold(0.0, (sum, duration) => sum + duration);

    final averageOptimizationScore = data
        .map((r) => r['optimization_score'] as double)
        .fold(0.0, (sum, score) => sum + score) / data.length;

    final improvementPercentages = data
        .where((r) => r['improvement_over_baseline_percent'] != null)
        .map((r) => r['improvement_over_baseline_percent'] as double)
        .toList();

    final averageImprovement = improvementPercentages.isEmpty ? 0.0 :
        improvementPercentages.fold(0.0, (sum, improvement) => sum + improvement) / improvementPercentages.length;

    return RouteEfficiencyMetrics(
      totalOptimizations: data.length,
      averageDistanceKm: totalDistanceKm / data.length,
      averageDurationHours: totalDurationHours / data.length,
      averageOptimizationScore: averageOptimizationScore,
      averageImprovementPercent: averageImprovement,
      totalDistanceSavedKm: _calculateTotalDistanceSaved(data),
      totalTimeSavedHours: _calculateTotalTimeSaved(data),
    );
  }

  /// Get driver utilization rates
  Future<DriverUtilizationRates> _getDriverUtilizationRates(DateTime start, DateTime end) async {
    // Get all drivers who had batches in the period
    final batchData = await _supabase
        .from('delivery_batches')
        .select('driver_id, status, created_at, actual_completion_time')
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String());

    final driverIds = batchData.map((b) => b['driver_id'] as String).toSet().toList();
    
    if (driverIds.isEmpty) {
      return DriverUtilizationRates.empty();
    }

    // Calculate utilization metrics
    final totalDrivers = driverIds.length;
    final activeDrivers = batchData
        .where((b) => b['status'] == 'active')
        .map((b) => b['driver_id'] as String)
        .toSet()
        .length;

    final averageBatchesPerDriver = batchData.length / totalDrivers;
    
    // Calculate average completion time
    final completedBatches = batchData.where((b) => 
        b['status'] == 'completed' && 
        b['actual_completion_time'] != null).toList();

    final averageCompletionTimeHours = completedBatches.isEmpty ? 0.0 :
        completedBatches
            .map((b) => DateTime.parse(b['actual_completion_time']).difference(
                DateTime.parse(b['created_at'])).inMinutes / 60.0)
            .fold(0.0, (sum, hours) => sum + hours) / completedBatches.length;

    return DriverUtilizationRates(
      totalDrivers: totalDrivers,
      activeDrivers: activeDrivers,
      utilizationRate: totalDrivers > 0 ? (activeDrivers / totalDrivers) * 100 : 0.0,
      averageBatchesPerDriver: averageBatchesPerDriver,
      averageCompletionTimeHours: averageCompletionTimeHours,
    );
  }

  /// Get system performance indicators
  Future<SystemPerformanceIndicators> _getSystemPerformanceIndicators(DateTime start, DateTime end) async {
    final performanceData = await _supabase
        .from('tsp_performance_metrics')
        .select('*')
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String());

    if (performanceData.isEmpty) {
      return SystemPerformanceIndicators.empty();
    }

    final calculationTimes = performanceData
        .map((p) => p['calculation_time_ms'] as int)
        .toList();

    final averageCalculationTimeMs = calculationTimes
        .fold(0, (sum, time) => sum + time) / calculationTimes.length;

    final slowCalculations = calculationTimes.where((time) => time > 5000).length;
    final successfulOptimizations = performanceData
        .where((p) => p['convergence_achieved'] == true).length;

    final memoryUsages = performanceData
        .where((p) => p['memory_usage_mb'] != null)
        .map((p) => p['memory_usage_mb'] as double)
        .toList();

    final averageMemoryUsageMb = memoryUsages.isEmpty ? 0.0 :
        memoryUsages.fold(0.0, (sum, memory) => sum + memory) / memoryUsages.length;

    return SystemPerformanceIndicators(
      totalOptimizations: performanceData.length,
      averageCalculationTimeMs: averageCalculationTimeMs,
      slowCalculationCount: slowCalculations,
      successRate: (successfulOptimizations / performanceData.length) * 100,
      averageMemoryUsageMb: averageMemoryUsageMb,
      systemHealthScore: _calculateSystemHealthScore(performanceData),
    );
  }

  /// Get algorithm performance comparison
  Future<List<TSPAlgorithmComparison>> _getAlgorithmPerformanceComparison(DateTime start, DateTime end) async {
    final data = await _supabase
        .from('tsp_performance_metrics')
        .select('*')
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String());

    // Group by algorithm
    final algorithmGroups = <String, List<Map<String, dynamic>>>{};
    for (final record in data) {
      final algorithm = record['algorithm_used'] as String;
      algorithmGroups.putIfAbsent(algorithm, () => []).add(record);
    }

    // Calculate comparison metrics
    final comparisons = <TSPAlgorithmComparison>[];
    for (final entry in algorithmGroups.entries) {
      final algorithm = OptimizationAlgorithm.values.firstWhere(
        (a) => a.name == entry.key,
        orElse: () => OptimizationAlgorithm.nearestNeighbor,
      );
      
      final stats = _calculateAlgorithmStats(algorithm, entry.value);
      comparisons.add(TSPAlgorithmComparison(
        algorithm: algorithm,
        stats: stats,
        rank: 0, // Will be calculated after all stats are computed
      ));
    }

    // Rank algorithms by overall performance
    comparisons.sort((a, b) => b.stats.overallScore.compareTo(a.stats.overallScore));
    for (int i = 0; i < comparisons.length; i++) {
      comparisons[i] = comparisons[i].copyWith(rank: i + 1);
    }

    return comparisons;
  }

  /// Get real-time metrics
  Future<RealtimeMetrics> _getRealtimeMetrics() async {
    final now = DateTime.now();
    final lastHour = now.subtract(const Duration(hours: 1));

    final recentBatches = await _supabase
        .from('delivery_batches')
        .select('*')
        .gte('created_at', lastHour.toIso8601String())
        .order('created_at', ascending: false);

    final activeBatches = recentBatches.where((b) => b['status'] == 'active').length;
    final recentOptimizations = await _supabase
        .from('route_optimizations')
        .select('*')
        .gte('created_at', lastHour.toIso8601String())
        .order('created_at', ascending: false)
        .limit(10);

    return RealtimeMetrics(
      activeBatches: activeBatches,
      recentOptimizations: recentOptimizations.length,
      systemLoad: await _getCurrentSystemLoad(),
      lastUpdated: now,
    );
  }

  /// Subscribe to real-time metrics updates
  Future<void> _subscribeToMetrics() async {
    // Subscribe to batch updates
    _batchMetricsChannel = _supabase.channel('batch_metrics');
    _batchMetricsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'delivery_batches',
          callback: (payload) => _handleBatchUpdate(payload),
        )
        .subscribe();

    // Subscribe to route optimization updates
    _routeOptimizationChannel = _supabase.channel('route_optimization_metrics');
    _routeOptimizationChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'route_optimizations',
          callback: (payload) => _handleRouteOptimizationUpdate(payload),
        )
        .subscribe();

    // Subscribe to performance metrics updates
    _performanceMetricsChannel = _supabase.channel('performance_metrics');
    _performanceMetricsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tsp_performance_metrics',
          callback: (payload) => _handlePerformanceMetricsUpdate(payload),
        )
        .subscribe();
  }

  /// Load initial dashboard data
  Future<void> _loadInitialDashboardData() async {
    final dashboardData = await getDashboardData();
    _dashboardController.add(dashboardData);
  }

  /// Handle batch update events
  void _handleBatchUpdate(PostgresChangePayload payload) {
    debugPrint('📊 [DASHBOARD] Batch update received: ${payload.eventType}');
    // Refresh dashboard data
    getDashboardData().then((data) => _dashboardController.add(data));
  }

  /// Handle route optimization update events
  void _handleRouteOptimizationUpdate(PostgresChangePayload payload) {
    debugPrint('📊 [DASHBOARD] Route optimization update received: ${payload.eventType}');
    // Refresh dashboard data
    getDashboardData().then((data) => _dashboardController.add(data));
  }

  /// Handle performance metrics update events
  void _handlePerformanceMetricsUpdate(PostgresChangePayload payload) {
    debugPrint('📊 [DASHBOARD] Performance metrics update received: ${payload.eventType}');
    // Refresh dashboard data
    getDashboardData().then((data) => _dashboardController.add(data));
  }

  /// Calculate algorithm statistics from raw data
  TSPAlgorithmStats _calculateAlgorithmStats(
    OptimizationAlgorithm algorithm,
    List<Map<String, dynamic>> data,
  ) {
    if (data.isEmpty) return TSPAlgorithmStats.empty(algorithm);

    final calculationTimes = data.map((d) => d['calculation_time_ms'] as int).toList();
    final optimizationScores = data.map((d) => d['optimization_score'] as double).toList();
    final routeQualityScores = data.map((d) => (d['route_quality_score'] as double?) ?? 0.0).toList();

    calculationTimes.sort();
    final medianTime = calculationTimes.length % 2 == 1
        ? calculationTimes[calculationTimes.length ~/ 2].toDouble()
        : (calculationTimes[calculationTimes.length ~/ 2 - 1] + calculationTimes[calculationTimes.length ~/ 2]) / 2.0;

    return TSPAlgorithmStats(
      algorithm: algorithm,
      totalExecutions: data.length,
      averageCalculationTimeMs: calculationTimes.reduce((a, b) => a + b) / calculationTimes.length,
      medianCalculationTimeMs: medianTime,
      averageOptimizationScore: optimizationScores.reduce((a, b) => a + b) / optimizationScores.length,
      averageRouteQualityScore: routeQualityScores.reduce((a, b) => a + b) / routeQualityScores.length,
      successRate: data.where((d) => d['convergence_achieved'] == true).length / data.length * 100,
      overallScore: _calculateOverallScore(calculationTimes, optimizationScores, routeQualityScores),
    );
  }

  /// Calculate overall algorithm performance score
  double _calculateOverallScore(
    List<int> calculationTimes,
    List<double> optimizationScores,
    List<double> routeQualityScores,
  ) {
    final avgTime = calculationTimes.reduce((a, b) => a + b) / calculationTimes.length;
    final avgOptimization = optimizationScores.reduce((a, b) => a + b) / optimizationScores.length;
    final avgQuality = routeQualityScores.reduce((a, b) => a + b) / routeQualityScores.length;
    
    // Weighted score: 40% optimization, 30% quality, 30% speed
    final speedScore = (avgTime < 1000) ? 100.0 : (avgTime < 5000) ? 80.0 : 60.0;
    return (avgOptimization * 0.4) + (avgQuality * 0.3) + (speedScore * 0.3);
  }

  /// Helper methods for calculations
  Future<double> _getAverageOrdersPerBatch(List<String> batchIds) async {
    if (batchIds.isEmpty) return 0.0;
    
    final orderCounts = await Future.wait(
      batchIds.map((id) async {
        final response = await _supabase
            .from('batch_orders')
            .select('id')
            .eq('batch_id', id)
            .count();
        return response.count;
      }),
    );

    final totalOrders = orderCounts.fold(0, (sum, count) => sum + count);
    return totalOrders / batchIds.length;
  }

  double _calculateTotalDistanceSaved(List<Map<String, dynamic>> data) {
    return data
        .where((r) => r['improvement_over_baseline_percent'] != null)
        .map((r) => (r['total_distance_meters'] as int) / 1000.0 * 
                   (r['improvement_over_baseline_percent'] as double) / 100.0)
        .fold(0.0, (sum, saved) => sum + saved);
  }

  double _calculateTotalTimeSaved(List<Map<String, dynamic>> data) {
    return data
        .where((r) => r['improvement_over_baseline_percent'] != null)
        .map((r) => (r['estimated_duration_seconds'] as int) / 3600.0 * 
                   (r['improvement_over_baseline_percent'] as double) / 100.0)
        .fold(0.0, (sum, saved) => sum + saved);
  }

  double _calculateSystemHealthScore(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 0.0;
    
    final avgTime = data.map((d) => d['calculation_time_ms'] as int).reduce((a, b) => a + b) / data.length;
    final successRate = data.where((d) => d['convergence_achieved'] == true).length / data.length;
    
    // Health score based on speed and success rate
    final timeScore = (avgTime < 1000) ? 100.0 : (avgTime < 5000) ? 80.0 : 60.0;
    final successScore = successRate * 100;
    
    return (timeScore + successScore) / 2;
  }

  Future<double> _getCurrentSystemLoad() async {
    // Placeholder - would implement actual system load monitoring
    return 0.0;
  }

  /// Dispose resources
  void dispose() {
    _batchMetricsChannel?.unsubscribe();
    _routeOptimizationChannel?.unsubscribe();
    _performanceMetricsChannel?.unsubscribe();
    _dashboardController.close();
  }
}
