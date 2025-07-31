import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/route_optimization_models.dart';
import '../../../../core/monitoring/performance_monitor.dart';
import '../../../../core/utils/logger.dart';

/// TSP Algorithm Performance Monitoring Service
/// Tracks and analyzes performance metrics for route optimization algorithms
class TSPPerformanceMonitoringService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final AppLogger _logger = AppLogger();

  // Performance thresholds
  static const int _maxCalculationTimeMs = 5000; // 5 seconds
  static const double _minOptimizationScore = 70.0; // 70% efficiency
  static const int _maxMemoryUsageMb = 100; // 100MB

  // Real-time monitoring
  final StreamController<TSPPerformanceAlert> _alertController = 
      StreamController<TSPPerformanceAlert>.broadcast();
  
  Stream<TSPPerformanceAlert> get alertStream => _alertController.stream;

  /// Record TSP algorithm performance metrics
  Future<String> recordTSPPerformance({
    required String batchId,
    required String routeOptimizationId,
    required OptimizationAlgorithm algorithm,
    required int problemSize,
    required int calculationTimeMs,
    required double optimizationScore,
    double? memoryUsageMb,
    int? iterationsPerformed,
    bool? convergenceAchieved,
    Map<String, dynamic>? algorithmParameters,
    double? distanceImprovementPercent,
    double? timeImprovementPercent,
  }) async {
    try {
      // Record to database
      final response = await _supabase
          .from('tsp_performance_metrics')
          .insert({
            'batch_id': batchId,
            'route_optimization_id': routeOptimizationId,
            'algorithm_used': algorithm.name,
            'problem_size': problemSize,
            'calculation_time_ms': calculationTimeMs,
            'optimization_score': optimizationScore,
            'memory_usage_mb': memoryUsageMb,
            'iterations_performed': iterationsPerformed,
            'convergence_achieved': convergenceAchieved,
            'algorithm_parameters': algorithmParameters ?? {},
            'distance_improvement_percent': distanceImprovementPercent,
            'time_improvement_percent': timeImprovementPercent,
            'route_quality_score': _calculateRouteQualityScore(
              optimizationScore,
              calculationTimeMs,
              problemSize,
            ),
            'cpu_usage_percent': await _getCurrentCpuUsage(),
            'system_load': await _getSystemLoad(),
          })
          .select('id')
          .single();

      final metricId = response['id'] as String;

      // Record to performance monitor
      _performanceMonitor.recordMetric(
        operation: 'tsp_optimization',
        category: 'algorithm',
        durationMs: calculationTimeMs,
        metadata: {
          'algorithm': algorithm.name,
          'problem_size': problemSize,
          'optimization_score': optimizationScore,
          'batch_id': batchId,
          'metric_id': metricId,
        },
      );

      // Check for performance alerts
      await _checkPerformanceAlerts(
        algorithm: algorithm,
        problemSize: problemSize,
        calculationTimeMs: calculationTimeMs,
        optimizationScore: optimizationScore,
        memoryUsageMb: memoryUsageMb,
        batchId: batchId,
      );

      _logger.info(
        'TSP performance recorded: ${algorithm.name} - ${calculationTimeMs}ms - Score: $optimizationScore - Batch: $batchId - Metric: $metricId',
      );

      return metricId;
    } catch (e) {
      _logger.logError('Failed to record TSP performance', e);
      rethrow;
    }
  }

  /// Get TSP performance statistics for a specific algorithm
  Future<TSPAlgorithmStats> getAlgorithmStats({
    required OptimizationAlgorithm algorithm,
    DateTime? startDate,
    DateTime? endDate,
    int? problemSizeMin,
    int? problemSizeMax,
  }) async {
    try {
      final query = _supabase
          .from('tsp_performance_metrics')
          .select('*')
          .eq('algorithm_used', algorithm.name);

      if (startDate != null) {
        query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query.lte('created_at', endDate.toIso8601String());
      }
      if (problemSizeMin != null) {
        query.gte('problem_size', problemSizeMin);
      }
      if (problemSizeMax != null) {
        query.lte('problem_size', problemSizeMax);
      }

      final data = await query;
      
      if (data.isEmpty) {
        return TSPAlgorithmStats.empty(algorithm);
      }

      return _calculateAlgorithmStats(algorithm, data);
    } catch (e) {
      _logger.logError('Failed to get algorithm stats', e);
      rethrow;
    }
  }

  /// Get comparative performance analysis across algorithms
  Future<List<TSPAlgorithmComparison>> getAlgorithmComparison({
    DateTime? startDate,
    DateTime? endDate,
    int? problemSize,
  }) async {
    try {
      final query = _supabase
          .from('tsp_performance_metrics')
          .select('*');

      if (startDate != null) {
        query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query.lte('created_at', endDate.toIso8601String());
      }
      if (problemSize != null) {
        query.eq('problem_size', problemSize);
      }

      final data = await query;
      
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
    } catch (e) {
      _logger.logError('Failed to get algorithm comparison', e);
      rethrow;
    }
  }

  /// Get real-time performance dashboard data
  Future<TSPPerformanceDashboard> getDashboardData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? now.subtract(const Duration(hours: 24));
      final end = endDate ?? now;

      final data = await _supabase
          .from('tsp_performance_metrics')
          .select('*')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: false);

      return _buildDashboardData(data, start, end);
    } catch (e) {
      _logger.logError('Failed to get dashboard data', e);
      rethrow;
    }
  }

  /// Monitor TSP operation in real-time
  Future<T> monitorTSPOperation<T>({
    required String operation,
    required OptimizationAlgorithm algorithm,
    required int problemSize,
    required Future<T> Function() function,
    String? batchId,
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    final startMemory = await _getCurrentMemoryUsage();
    
    try {
      final result = await function();
      stopwatch.stop();
      
      final endMemory = await _getCurrentMemoryUsage();
      final memoryUsed = endMemory - startMemory;
      
      // Record performance if we have a batch ID
      if (batchId != null && result is RouteOptimizationResult) {
        await recordTSPPerformance(
          batchId: batchId,
          routeOptimizationId: result.id,
          algorithm: algorithm,
          problemSize: problemSize,
          calculationTimeMs: stopwatch.elapsedMilliseconds,
          optimizationScore: result.optimizationScore,
          memoryUsageMb: memoryUsed,
          algorithmParameters: metadata,
        );
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      _logger.error(
        'TSP operation failed: $operation - Algorithm: ${algorithm.name} - Problem size: $problemSize - Duration: ${stopwatch.elapsedMilliseconds}ms',
        e,
      );
      
      rethrow;
    }
  }

  /// Check for performance alerts and trigger notifications
  Future<void> _checkPerformanceAlerts({
    required OptimizationAlgorithm algorithm,
    required int problemSize,
    required int calculationTimeMs,
    required double optimizationScore,
    double? memoryUsageMb,
    required String batchId,
  }) async {
    final alerts = <TSPPerformanceAlert>[];

    // Check calculation time threshold
    if (calculationTimeMs > _maxCalculationTimeMs) {
      alerts.add(TSPPerformanceAlert(
        type: AlertType.slowCalculation,
        algorithm: algorithm,
        message: 'TSP calculation took ${calculationTimeMs}ms (threshold: ${_maxCalculationTimeMs}ms)',
        severity: calculationTimeMs > _maxCalculationTimeMs * 2 
            ? AlertSeverity.critical 
            : AlertSeverity.warning,
        batchId: batchId,
        value: calculationTimeMs.toDouble(),
        threshold: _maxCalculationTimeMs.toDouble(),
      ));
    }

    // Check optimization score threshold
    if (optimizationScore < _minOptimizationScore) {
      alerts.add(TSPPerformanceAlert(
        type: AlertType.lowOptimizationScore,
        algorithm: algorithm,
        message: 'Low optimization score: $optimizationScore% (threshold: $_minOptimizationScore%)',
        severity: optimizationScore < _minOptimizationScore * 0.8 
            ? AlertSeverity.critical 
            : AlertSeverity.warning,
        batchId: batchId,
        value: optimizationScore,
        threshold: _minOptimizationScore,
      ));
    }

    // Check memory usage threshold
    if (memoryUsageMb != null && memoryUsageMb > _maxMemoryUsageMb) {
      alerts.add(TSPPerformanceAlert(
        type: AlertType.highMemoryUsage,
        algorithm: algorithm,
        message: 'High memory usage: ${memoryUsageMb.toStringAsFixed(1)}MB (threshold: ${_maxMemoryUsageMb}MB)',
        severity: memoryUsageMb > _maxMemoryUsageMb * 1.5 
            ? AlertSeverity.critical 
            : AlertSeverity.warning,
        batchId: batchId,
        value: memoryUsageMb,
        threshold: _maxMemoryUsageMb.toDouble(),
      ));
    }

    // Emit alerts
    for (final alert in alerts) {
      _alertController.add(alert);
      _logger.warning(
        'TSP Performance Alert: ${alert.message} - Type: ${alert.type.name} - Severity: ${alert.severity.name} - Algorithm: ${alert.algorithm.name} - Batch: ${alert.batchId}',
      );
    }
  }

  /// Calculate route quality score based on multiple factors
  double _calculateRouteQualityScore(
    double optimizationScore,
    int calculationTimeMs,
    int problemSize,
  ) {
    // Base score from optimization
    double score = optimizationScore;
    
    // Penalty for slow calculations (relative to problem size)
    final expectedTimeMs = problemSize * problemSize * 10; // Rough estimate
    if (calculationTimeMs > expectedTimeMs) {
      final timePenalty = min(20.0, (calculationTimeMs - expectedTimeMs) / expectedTimeMs * 10);
      score -= timePenalty;
    }
    
    // Bonus for fast calculations
    if (calculationTimeMs < expectedTimeMs * 0.5) {
      score += min(5.0, (expectedTimeMs * 0.5 - calculationTimeMs) / expectedTimeMs * 10);
    }
    
    return max(0.0, min(100.0, score));
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

    return TSPAlgorithmStats(
      algorithm: algorithm,
      totalExecutions: data.length,
      averageCalculationTimeMs: calculationTimes.reduce((a, b) => a + b) / calculationTimes.length,
      medianCalculationTimeMs: _calculateMedian(calculationTimes.map((t) => t.toDouble()).toList()),
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
    final speedScore = max(0.0, 100.0 - (avgTime / 1000.0 * 10)); // Penalty for slow times
    return (avgOptimization * 0.4) + (avgQuality * 0.3) + (speedScore * 0.3);
  }

  /// Build dashboard data from raw metrics
  TSPPerformanceDashboard _buildDashboardData(
    List<Map<String, dynamic>> data,
    DateTime startDate,
    DateTime endDate,
  ) {
    // Implementation would build comprehensive dashboard data
    // This is a simplified version
    return TSPPerformanceDashboard(
      totalOptimizations: data.length,
      averageCalculationTime: data.isEmpty ? 0.0 : 
          data.map((d) => d['calculation_time_ms'] as int).reduce((a, b) => a + b) / data.length,
      averageOptimizationScore: data.isEmpty ? 0.0 :
          data.map((d) => d['optimization_score'] as double).reduce((a, b) => a + b) / data.length,
      alertCount: 0, // Would be calculated based on thresholds
      period: DateRange(start: startDate, end: endDate),
    );
  }

  /// Calculate median value
  double _calculateMedian(List<double> values) {
    values.sort();
    final middle = values.length ~/ 2;
    if (values.length % 2 == 1) {
      return values[middle];
    } else {
      return (values[middle - 1] + values[middle]) / 2.0;
    }
  }

  /// Get current CPU usage (placeholder - would use platform-specific implementation)
  Future<double> _getCurrentCpuUsage() async {
    // Placeholder implementation
    return 0.0;
  }

  /// Get current system load (placeholder - would use platform-specific implementation)
  Future<double> _getSystemLoad() async {
    // Placeholder implementation
    return 0.0;
  }

  /// Get current memory usage (placeholder - would use platform-specific implementation)
  Future<double> _getCurrentMemoryUsage() async {
    // Placeholder implementation
    return 0.0;
  }

  /// Dispose resources
  void dispose() {
    _alertController.close();
  }
}
