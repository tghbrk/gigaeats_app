import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/logger.dart';
import 'system_health_models.dart';

/// System Health Monitoring Service
/// Monitors Edge Function performance, database query times, real-time subscription health,
/// and provides automated alerting for critical issues
class SystemHealthMonitoringService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLogger _logger = AppLogger();

  // Health monitoring configuration
  static const String _projectRef = 'abknoalhfltlhhdbclpv';
  static const Duration _monitoringInterval = Duration(minutes: 5);
  static const Duration _healthCheckTimeout = Duration(seconds: 30);

  // Performance thresholds
  static const int _maxEdgeFunctionResponseTimeMs = 10000; // 10 seconds
  static const int _maxDatabaseQueryTimeMs = 5000; // 5 seconds
  static const int _maxRealtimeLatencyMs = 2000; // 2 seconds
  static const double _minSystemHealthScore = 80.0; // 80%

  // Monitoring state
  Timer? _monitoringTimer;
  final StreamController<SystemHealthStatus> _healthStatusController = 
      StreamController<SystemHealthStatus>.broadcast();
  final StreamController<SystemHealthAlert> _alertController = 
      StreamController<SystemHealthAlert>.broadcast();

  // Health metrics cache
  SystemHealthStatus? _lastHealthStatus;
  final List<SystemHealthAlert> _recentAlerts = [];

  Stream<SystemHealthStatus> get healthStatusStream => _healthStatusController.stream;
  Stream<SystemHealthAlert> get alertStream => _alertController.stream;

  /// Initialize system health monitoring
  Future<void> initializeMonitoring() async {
    try {
      _logger.logInfo('Initializing system health monitoring');
      
      // Start periodic health checks
      _monitoringTimer = Timer.periodic(_monitoringInterval, (_) => _performHealthCheck());
      
      // Perform initial health check
      await _performHealthCheck();
      
      _logger.logInfo('System health monitoring initialized successfully');
    } catch (e) {
      _logger.logError('Failed to initialize system health monitoring', e);
      rethrow;
    }
  }

  /// Perform comprehensive system health check
  Future<void> _performHealthCheck() async {
    try {
      final healthCheckStart = DateTime.now();
      
      // Run all health checks in parallel
      final results = await Future.wait([
        _checkEdgeFunctionHealth(),
        _checkDatabaseHealth(),
        _checkRealtimeSubscriptionHealth(),
        _checkSystemResourceHealth(),
      ]);

      final edgeFunctionHealth = results[0] as EdgeFunctionHealth;
      final databaseHealth = results[1] as DatabaseHealth;
      final realtimeHealth = results[2] as RealtimeHealth;
      final systemResourceHealth = results[3] as SystemResourceHealth;

      // Calculate overall system health score
      final overallScore = _calculateOverallHealthScore(
        edgeFunctionHealth,
        databaseHealth,
        realtimeHealth,
        systemResourceHealth,
      );

      final healthStatus = SystemHealthStatus(
        timestamp: DateTime.now(),
        overallHealthScore: overallScore,
        edgeFunctionHealth: edgeFunctionHealth,
        databaseHealth: databaseHealth,
        realtimeHealth: realtimeHealth,
        systemResourceHealth: systemResourceHealth,
        healthCheckDurationMs: DateTime.now().difference(healthCheckStart).inMilliseconds,
      );

      // Check for alerts
      await _checkForAlerts(healthStatus);

      // Update status and emit to stream
      _lastHealthStatus = healthStatus;
      _healthStatusController.add(healthStatus);

      // Log health status
      _logger.info(
        'System health check completed - Score: ${overallScore.toStringAsFixed(1)}% '
        '(Edge: ${edgeFunctionHealth.healthScore.toStringAsFixed(1)}%, '
        'DB: ${databaseHealth.healthScore.toStringAsFixed(1)}%, '
        'RT: ${realtimeHealth.healthScore.toStringAsFixed(1)}%, '
        'Sys: ${systemResourceHealth.healthScore.toStringAsFixed(1)}%)',
      );

    } catch (e) {
      _logger.logError('System health check failed', e);
      
      // Emit critical alert for health check failure
      final alert = SystemHealthAlert(
        type: AlertType.systemFailure,
        severity: AlertSeverity.critical,
        message: 'System health check failed: ${e.toString()}',
        timestamp: DateTime.now(),
        component: 'health_monitoring',
        value: 0.0,
        threshold: 100.0,
      );
      
      _alertController.add(alert);
      _recentAlerts.add(alert);
    }
  }

  /// Check Edge Function health
  Future<EdgeFunctionHealth> _checkEdgeFunctionHealth() async {
    final functions = [
      'create-delivery-batch',
      'optimize-delivery-route',
      'manage-delivery-batch',
    ];

    final functionResults = <String, EdgeFunctionResult>{};
    
    for (final functionName in functions) {
      try {
        final result = await _testEdgeFunction(functionName);
        functionResults[functionName] = result;
      } catch (e) {
        functionResults[functionName] = EdgeFunctionResult(
          functionName: functionName,
          responseTimeMs: -1,
          isHealthy: false,
          errorMessage: e.toString(),
        );
      }
    }

    final healthyFunctions = functionResults.values.where((r) => r.isHealthy).length;
    final averageResponseTime = functionResults.values
        .where((r) => r.responseTimeMs > 0)
        .map((r) => r.responseTimeMs)
        .fold(0.0, (sum, time) => sum + time) / 
        max(1, functionResults.values.where((r) => r.responseTimeMs > 0).length);

    final healthScore = (healthyFunctions / functions.length) * 100;

    return EdgeFunctionHealth(
      healthScore: healthScore,
      averageResponseTimeMs: averageResponseTime,
      functionResults: functionResults,
      totalFunctions: functions.length,
      healthyFunctions: healthyFunctions,
    );
  }

  /// Test individual Edge Function
  Future<EdgeFunctionResult> _testEdgeFunction(String functionName) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final url = 'https://$_projectRef.supabase.co/functions/v1/$functionName';
      final response = await http.head(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken ?? ""}',
        },
      ).timeout(_healthCheckTimeout);

      stopwatch.stop();
      
      final isHealthy = response.statusCode == 200 || response.statusCode == 405; // 405 is OK for HEAD requests
      
      return EdgeFunctionResult(
        functionName: functionName,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        isHealthy: isHealthy,
        statusCode: response.statusCode,
      );
    } catch (e) {
      stopwatch.stop();
      return EdgeFunctionResult(
        functionName: functionName,
        responseTimeMs: stopwatch.elapsedMilliseconds,
        isHealthy: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Check database health
  Future<DatabaseHealth> _checkDatabaseHealth() async {
    final queryResults = <String, DatabaseQueryResult>{};
    
    // Test different types of queries
    final testQueries = {
      'simple_select': 'SELECT 1 as test',
      'delivery_batches_count': 'SELECT COUNT(*) FROM delivery_batches WHERE created_at >= NOW() - INTERVAL \'1 hour\'',
      'route_optimizations_recent': 'SELECT COUNT(*) FROM route_optimizations WHERE created_at >= NOW() - INTERVAL \'1 hour\'',
      'tsp_performance_metrics': 'SELECT AVG(calculation_time_ms) FROM tsp_performance_metrics WHERE created_at >= NOW() - INTERVAL \'1 hour\'',
    };

    for (final entry in testQueries.entries) {
      try {
        final result = await _testDatabaseQuery(entry.key, entry.value);
        queryResults[entry.key] = result;
      } catch (e) {
        queryResults[entry.key] = DatabaseQueryResult(
          queryName: entry.key,
          executionTimeMs: -1,
          isSuccessful: false,
          errorMessage: e.toString(),
        );
      }
    }

    final successfulQueries = queryResults.values.where((r) => r.isSuccessful).length;
    final averageQueryTime = queryResults.values
        .where((r) => r.executionTimeMs > 0)
        .map((r) => r.executionTimeMs)
        .fold(0.0, (sum, time) => sum + time) / 
        max(1, queryResults.values.where((r) => r.executionTimeMs > 0).length);

    final healthScore = (successfulQueries / testQueries.length) * 100;

    return DatabaseHealth(
      healthScore: healthScore,
      averageQueryTimeMs: averageQueryTime,
      queryResults: queryResults,
      totalQueries: testQueries.length,
      successfulQueries: successfulQueries,
    );
  }

  /// Test individual database query
  Future<DatabaseQueryResult> _testDatabaseQuery(String queryName, String query) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      await _supabase.rpc('exec_sql', params: {'sql': query}).timeout(_healthCheckTimeout);
      stopwatch.stop();
      
      return DatabaseQueryResult(
        queryName: queryName,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        isSuccessful: true,
      );
    } catch (e) {
      stopwatch.stop();
      return DatabaseQueryResult(
        queryName: queryName,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        isSuccessful: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Check real-time subscription health
  Future<RealtimeHealth> _checkRealtimeSubscriptionHealth() async {
    try {
      final testChannel = _supabase.channel('health_check_${DateTime.now().millisecondsSinceEpoch}');
      final stopwatch = Stopwatch()..start();
      
      final completer = Completer<bool>();
      
      testChannel.subscribe((status, error) {
        stopwatch.stop();
        if (status == RealtimeSubscribeStatus.subscribed) {
          completer.complete(true);
        } else if (error != null) {
          completer.complete(false);
        }
      });

      final isHealthy = await completer.future.timeout(
        _healthCheckTimeout,
        onTimeout: () => false,
      );

      await testChannel.unsubscribe();

      return RealtimeHealth(
        healthScore: isHealthy ? 100.0 : 0.0,
        connectionLatencyMs: stopwatch.elapsedMilliseconds,
        isConnected: isHealthy,
        activeSubscriptions: _supabase.getChannels().length,
      );
    } catch (e) {
      return RealtimeHealth(
        healthScore: 0.0,
        connectionLatencyMs: -1,
        isConnected: false,
        activeSubscriptions: 0,
        errorMessage: e.toString(),
      );
    }
  }

  /// Check system resource health
  Future<SystemResourceHealth> _checkSystemResourceHealth() async {
    try {
      // Get current memory usage (simplified)
      final memoryUsageMb = await _getCurrentMemoryUsage();
      final cpuUsagePercent = await _getCurrentCpuUsage();
      
      // Calculate health score based on resource usage
      final memoryScore = memoryUsageMb < 500 ? 100.0 : max(0.0, 100.0 - ((memoryUsageMb - 500) / 10));
      final cpuScore = cpuUsagePercent < 80 ? 100.0 : max(0.0, 100.0 - ((cpuUsagePercent - 80) * 5));
      
      final healthScore = (memoryScore + cpuScore) / 2;

      return SystemResourceHealth(
        healthScore: healthScore,
        memoryUsageMb: memoryUsageMb,
        cpuUsagePercent: cpuUsagePercent,
        diskUsagePercent: 0.0, // Placeholder
        networkLatencyMs: 0.0, // Placeholder
      );
    } catch (e) {
      return SystemResourceHealth(
        healthScore: 0.0,
        memoryUsageMb: 0.0,
        cpuUsagePercent: 0.0,
        diskUsagePercent: 0.0,
        networkLatencyMs: 0.0,
        errorMessage: e.toString(),
      );
    }
  }

  /// Calculate overall system health score
  double _calculateOverallHealthScore(
    EdgeFunctionHealth edgeFunctionHealth,
    DatabaseHealth databaseHealth,
    RealtimeHealth realtimeHealth,
    SystemResourceHealth systemResourceHealth,
  ) {
    // Weighted average: Database 40%, Edge Functions 30%, Realtime 20%, System Resources 10%
    return (databaseHealth.healthScore * 0.4) +
           (edgeFunctionHealth.healthScore * 0.3) +
           (realtimeHealth.healthScore * 0.2) +
           (systemResourceHealth.healthScore * 0.1);
  }

  /// Check for alerts based on health status
  Future<void> _checkForAlerts(SystemHealthStatus healthStatus) async {
    final alerts = <SystemHealthAlert>[];

    // Overall health score alert
    if (healthStatus.overallHealthScore < _minSystemHealthScore) {
      alerts.add(SystemHealthAlert(
        type: AlertType.lowHealthScore,
        severity: healthStatus.overallHealthScore < 50 ? AlertSeverity.critical : AlertSeverity.warning,
        message: 'System health score is ${healthStatus.overallHealthScore.toStringAsFixed(1)}% (threshold: $_minSystemHealthScore%)',
        timestamp: DateTime.now(),
        component: 'overall_system',
        value: healthStatus.overallHealthScore,
        threshold: _minSystemHealthScore,
      ));
    }

    // Edge Function alerts
    if (healthStatus.edgeFunctionHealth.averageResponseTimeMs > _maxEdgeFunctionResponseTimeMs) {
      alerts.add(SystemHealthAlert(
        type: AlertType.slowEdgeFunction,
        severity: AlertSeverity.warning,
        message: 'Edge Functions average response time is ${healthStatus.edgeFunctionHealth.averageResponseTimeMs.toStringAsFixed(0)}ms (threshold: ${_maxEdgeFunctionResponseTimeMs}ms)',
        timestamp: DateTime.now(),
        component: 'edge_functions',
        value: healthStatus.edgeFunctionHealth.averageResponseTimeMs,
        threshold: _maxEdgeFunctionResponseTimeMs.toDouble(),
      ));
    }

    // Database alerts
    if (healthStatus.databaseHealth.averageQueryTimeMs > _maxDatabaseQueryTimeMs) {
      alerts.add(SystemHealthAlert(
        type: AlertType.slowDatabase,
        severity: AlertSeverity.warning,
        message: 'Database average query time is ${healthStatus.databaseHealth.averageQueryTimeMs.toStringAsFixed(0)}ms (threshold: ${_maxDatabaseQueryTimeMs}ms)',
        timestamp: DateTime.now(),
        component: 'database',
        value: healthStatus.databaseHealth.averageQueryTimeMs,
        threshold: _maxDatabaseQueryTimeMs.toDouble(),
      ));
    }

    // Real-time alerts
    if (!healthStatus.realtimeHealth.isConnected) {
      alerts.add(SystemHealthAlert(
        type: AlertType.realtimeDisconnected,
        severity: AlertSeverity.critical,
        message: 'Real-time subscriptions are disconnected',
        timestamp: DateTime.now(),
        component: 'realtime',
        value: 0.0,
        threshold: 1.0,
      ));
    } else if (healthStatus.realtimeHealth.connectionLatencyMs > _maxRealtimeLatencyMs) {
      alerts.add(SystemHealthAlert(
        type: AlertType.highRealtimeLatency,
        severity: AlertSeverity.warning,
        message: 'Real-time connection latency is ${healthStatus.realtimeHealth.connectionLatencyMs}ms (threshold: ${_maxRealtimeLatencyMs}ms)',
        timestamp: DateTime.now(),
        component: 'realtime',
        value: healthStatus.realtimeHealth.connectionLatencyMs.toDouble(),
        threshold: _maxRealtimeLatencyMs.toDouble(),
      ));
    }

    // Emit alerts
    for (final alert in alerts) {
      _alertController.add(alert);
      _recentAlerts.add(alert);
      
      // Keep only recent alerts (last 100)
      if (_recentAlerts.length > 100) {
        _recentAlerts.removeAt(0);
      }
      
      _logger.warning(
        'System Health Alert [${alert.severity.displayName}] ${alert.component}: ${alert.message} '
        '(${alert.type.displayName}: ${alert.value} > ${alert.threshold})',
      );
    }
  }

  /// Get current system health status
  SystemHealthStatus? getCurrentHealthStatus() => _lastHealthStatus;

  /// Get recent alerts
  List<SystemHealthAlert> getRecentAlerts({int limit = 10}) {
    return _recentAlerts.reversed.take(limit).toList();
  }

  /// Placeholder methods for system resource monitoring
  Future<double> _getCurrentMemoryUsage() async {
    // Placeholder - would implement actual memory monitoring
    return 256.0; // MB
  }

  Future<double> _getCurrentCpuUsage() async {
    // Placeholder - would implement actual CPU monitoring
    return 25.0; // Percentage
  }

  /// Dispose resources
  void dispose() {
    _monitoringTimer?.cancel();
    _healthStatusController.close();
    _alertController.close();
  }
}
