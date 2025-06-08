import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final List<PerformanceMetric> _metrics = [];
  Timer? _flushTimer;

  // Initialize performance monitoring
  void initialize() {
    // Flush metrics every 30 seconds
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _flushMetrics();
    });
    
    if (kDebugMode) {
      print('📊 PerformanceMonitor: Initialized');
    }
  }

  // Record a performance metric
  void recordMetric({
    required String operation,
    required String category,
    required int durationMs,
    Map<String, dynamic>? metadata,
    String? userId,
    String? sessionId,
  }) {
    final metric = PerformanceMetric(
      operation: operation,
      category: category,
      durationMs: durationMs,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
      userId: userId,
      sessionId: sessionId,
    );

    _metrics.add(metric);

    if (kDebugMode) {
      print('📊 Performance: ${metric.operation} took ${metric.durationMs}ms');
    }

    // Flush immediately if we have too many metrics
    if (_metrics.length >= 50) {
      _flushMetrics();
    }
  }

  // Record customization-specific metrics
  void recordCustomizationMetric({
    required String operation,
    required int durationMs,
    String? menuItemId,
    int? customizationCount,
    int? optionCount,
    Map<String, dynamic>? additionalData,
  }) {
    final metadata = <String, dynamic>{
      if (menuItemId != null) 'menu_item_id': menuItemId,
      if (customizationCount != null) 'customization_count': customizationCount,
      if (optionCount != null) 'option_count': optionCount,
      ...?additionalData,
    };

    recordMetric(
      operation: operation,
      category: 'customization',
      durationMs: durationMs,
      metadata: metadata,
    );
  }

  // Record database operation metrics
  void recordDatabaseMetric({
    required String operation,
    required int durationMs,
    String? table,
    int? recordCount,
    Map<String, dynamic>? queryParams,
  }) {
    final metadata = <String, dynamic>{
      if (table != null) 'table': table,
      if (recordCount != null) 'record_count': recordCount,
      if (queryParams != null) 'query_params': queryParams,
    };

    recordMetric(
      operation: operation,
      category: 'database',
      durationMs: durationMs,
      metadata: metadata,
    );
  }

  // Record UI operation metrics
  void recordUIMetric({
    required String operation,
    required int durationMs,
    String? screen,
    String? component,
    Map<String, dynamic>? userInteraction,
  }) {
    final metadata = <String, dynamic>{
      if (screen != null) 'screen': screen,
      if (component != null) 'component': component,
      if (userInteraction != null) 'user_interaction': userInteraction,
    };

    recordMetric(
      operation: operation,
      category: 'ui',
      durationMs: durationMs,
      metadata: metadata,
    );
  }

  // Measure and record an operation
  Future<T> measureOperation<T>({
    required String operation,
    required String category,
    required Future<T> Function() function,
    Map<String, dynamic>? metadata,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await function();
      stopwatch.stop();
      
      recordMetric(
        operation: operation,
        category: category,
        durationMs: stopwatch.elapsedMilliseconds,
        metadata: metadata,
      );
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      recordMetric(
        operation: '${operation}_error',
        category: category,
        durationMs: stopwatch.elapsedMilliseconds,
        metadata: {
          ...?metadata,
          'error': e.toString(),
        },
      );
      
      rethrow;
    }
  }

  // Flush metrics to database
  Future<void> _flushMetrics() async {
    if (_metrics.isEmpty) return;

    try {
      final metricsToFlush = List<PerformanceMetric>.from(_metrics);
      _metrics.clear();

      final data = metricsToFlush.map((metric) => metric.toJson()).toList();

      await _supabase.from('performance_metrics').insert(data);

      if (kDebugMode) {
        print('📊 PerformanceMonitor: Flushed ${metricsToFlush.length} metrics');
      }
    } catch (e) {
      if (kDebugMode) {
        print('📊 PerformanceMonitor: Error flushing metrics: $e');
      }
      // Re-add metrics if flush failed
      _metrics.addAll(_metrics);
    }
  }

  // Get performance statistics
  Future<PerformanceStats> getStats({
    String? category,
    String? operation,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.from('performance_metrics').select();

      if (category != null) {
        query = query.eq('category', category);
      }
      if (operation != null) {
        query = query.eq('operation', operation);
      }
      if (startDate != null) {
        query = query.gte('timestamp', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('timestamp', endDate.toIso8601String());
      }

      final response = await query;
      final metrics = response.map((data) => PerformanceMetric.fromJson(data)).toList();

      return PerformanceStats.fromMetrics(metrics);
    } catch (e) {
      if (kDebugMode) {
        print('📊 PerformanceMonitor: Error getting stats: $e');
      }
      return PerformanceStats.empty();
    }
  }

  // Dispose resources
  void dispose() {
    _flushTimer?.cancel();
    _flushMetrics();
  }
}

class PerformanceMetric {
  final String operation;
  final String category;
  final int durationMs;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? userId;
  final String? sessionId;

  PerformanceMetric({
    required this.operation,
    required this.category,
    required this.durationMs,
    required this.timestamp,
    required this.metadata,
    this.userId,
    this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'category': category,
      'duration_ms': durationMs,
      'timestamp': timestamp.toIso8601String(),
      'metadata': jsonEncode(metadata),
      'user_id': userId,
      'session_id': sessionId,
    };
  }

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      operation: json['operation'],
      category: json['category'],
      durationMs: json['duration_ms'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'] != null ? jsonDecode(json['metadata']) : {},
      userId: json['user_id'],
      sessionId: json['session_id'],
    );
  }
}

class PerformanceStats {
  final int totalOperations;
  final double averageDuration;
  final int minDuration;
  final int maxDuration;
  final double p95Duration;
  final double p99Duration;
  final Map<String, int> operationCounts;
  final Map<String, double> operationAverages;

  PerformanceStats({
    required this.totalOperations,
    required this.averageDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.p95Duration,
    required this.p99Duration,
    required this.operationCounts,
    required this.operationAverages,
  });

  factory PerformanceStats.fromMetrics(List<PerformanceMetric> metrics) {
    if (metrics.isEmpty) {
      return PerformanceStats.empty();
    }

    final durations = metrics.map((m) => m.durationMs).toList()..sort();
    final operationCounts = <String, int>{};
    final operationDurations = <String, List<int>>{};

    for (final metric in metrics) {
      operationCounts[metric.operation] = (operationCounts[metric.operation] ?? 0) + 1;
      operationDurations.putIfAbsent(metric.operation, () => []).add(metric.durationMs);
    }

    final operationAverages = operationDurations.map(
      (operation, durations) => MapEntry(
        operation,
        durations.reduce((a, b) => a + b) / durations.length,
      ),
    );

    return PerformanceStats(
      totalOperations: metrics.length,
      averageDuration: durations.reduce((a, b) => a + b) / durations.length,
      minDuration: durations.first,
      maxDuration: durations.last,
      p95Duration: durations[(durations.length * 0.95).floor()].toDouble(),
      p99Duration: durations[(durations.length * 0.99).floor()].toDouble(),
      operationCounts: operationCounts,
      operationAverages: operationAverages,
    );
  }

  factory PerformanceStats.empty() {
    return PerformanceStats(
      totalOperations: 0,
      averageDuration: 0,
      minDuration: 0,
      maxDuration: 0,
      p95Duration: 0,
      p99Duration: 0,
      operationCounts: {},
      operationAverages: {},
    );
  }
}
