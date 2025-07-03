import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Enhanced performance monitoring service with real-time metrics
class EnhancedPerformanceMonitoringService {
  static final EnhancedPerformanceMonitoringService _instance = 
      EnhancedPerformanceMonitoringService._internal();
  
  factory EnhancedPerformanceMonitoringService() => _instance;
  
  EnhancedPerformanceMonitoringService._internal();


  final Map<String, PerformanceMetric> _metrics = {};
  final Queue<PerformanceEvent> _events = Queue();
  final Map<String, Stopwatch> _activeOperations = {};
  
  static const int _maxEvents = 1000;
  static const Duration _metricsRetentionPeriod = Duration(hours: 24);

  Timer? _cleanupTimer;
  Timer? _reportingTimer;

  /// Initialize the performance monitoring service
  void initialize() {
    debugPrint('🚀 [PERFORMANCE-MONITOR] Initializing performance monitoring');
    
    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) => _cleanup());
    
    // Start periodic reporting
    _reportingTimer = Timer.periodic(const Duration(minutes: 1), (_) => _generateReport());
    
    // Monitor memory usage
    _startMemoryMonitoring();
  }

  /// Dispose the service
  void dispose() {
    _cleanupTimer?.cancel();
    _reportingTimer?.cancel();
    debugPrint('🚀 [PERFORMANCE-MONITOR] Performance monitoring disposed');
  }

  /// Start timing an operation
  void startOperation(String operationName, {Map<String, dynamic>? metadata}) {
    final stopwatch = Stopwatch()..start();
    _activeOperations[operationName] = stopwatch;
    
    debugPrint('⏱️ [PERFORMANCE-MONITOR] Started operation: $operationName');
    
    _recordEvent(PerformanceEvent(
      name: operationName,
      type: PerformanceEventType.operationStart,
      timestamp: DateTime.now(),
      metadata: metadata,
    ));
  }

  /// End timing an operation and record metrics
  void endOperation(String operationName, {
    bool success = true,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    final stopwatch = _activeOperations.remove(operationName);
    if (stopwatch == null) {
      debugPrint('⚠️ [PERFORMANCE-MONITOR] Operation $operationName was not started');
      return;
    }

    stopwatch.stop();
    final duration = stopwatch.elapsedMilliseconds;
    
    debugPrint('⏱️ [PERFORMANCE-MONITOR] Completed operation: $operationName (${duration}ms)');
    
    // Update metrics
    _updateMetric(operationName, duration, success);
    
    // Record event
    _recordEvent(PerformanceEvent(
      name: operationName,
      type: success ? PerformanceEventType.operationSuccess : PerformanceEventType.operationFailure,
      timestamp: DateTime.now(),
      duration: duration,
      metadata: {
        ...?metadata,
        if (errorMessage != null) 'error': errorMessage,
      },
    ));
  }

  /// Record a custom metric
  void recordMetric(String name, double value, {
    String? unit,
    Map<String, dynamic>? metadata,
  }) {
    _recordEvent(PerformanceEvent(
      name: name,
      type: PerformanceEventType.customMetric,
      timestamp: DateTime.now(),
      value: value,
      metadata: {
        ...?metadata,
        if (unit != null) 'unit': unit,
      },
    ));
    
    debugPrint('📊 [PERFORMANCE-MONITOR] Recorded metric: $name = $value ${unit ?? ''}');
  }

  /// Record memory usage
  void recordMemoryUsage() {
    if (kDebugMode) {
      // In debug mode, we can get more detailed memory info
      _recordEvent(PerformanceEvent(
        name: 'memory_usage',
        type: PerformanceEventType.memoryUsage,
        timestamp: DateTime.now(),
        metadata: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      ));
    }
  }

  /// Record network request metrics
  void recordNetworkRequest({
    required String endpoint,
    required String method,
    required int statusCode,
    required int duration,
    required int requestSize,
    required int responseSize,
    String? errorMessage,
  }) {
    final success = statusCode >= 200 && statusCode < 300;
    
    _recordEvent(PerformanceEvent(
      name: 'network_request',
      type: success ? PerformanceEventType.networkSuccess : PerformanceEventType.networkFailure,
      timestamp: DateTime.now(),
      duration: duration,
      metadata: {
        'endpoint': endpoint,
        'method': method,
        'status_code': statusCode,
        'request_size': requestSize,
        'response_size': responseSize,
        if (errorMessage != null) 'error': errorMessage,
      },
    ));
    
    debugPrint('🌐 [PERFORMANCE-MONITOR] Network request: $method $endpoint (${duration}ms, $statusCode)');
  }

  /// Record database operation metrics
  void recordDatabaseOperation({
    required String operation,
    required String table,
    required int duration,
    required bool success,
    int? recordCount,
    String? errorMessage,
  }) {
    _recordEvent(PerformanceEvent(
      name: 'database_operation',
      type: success ? PerformanceEventType.databaseSuccess : PerformanceEventType.databaseFailure,
      timestamp: DateTime.now(),
      duration: duration,
      metadata: {
        'operation': operation,
        'table': table,
        if (recordCount != null) 'record_count': recordCount,
        if (errorMessage != null) 'error': errorMessage,
      },
    ));
    
    debugPrint('🗄️ [PERFORMANCE-MONITOR] Database operation: $operation on $table (${duration}ms)');
  }

  /// Record cache operation metrics
  void recordCacheOperation({
    required String operation,
    required String key,
    required int duration,
    required bool hit,
    int? size,
  }) {
    _recordEvent(PerformanceEvent(
      name: 'cache_operation',
      type: hit ? PerformanceEventType.cacheHit : PerformanceEventType.cacheMiss,
      timestamp: DateTime.now(),
      duration: duration,
      metadata: {
        'operation': operation,
        'key': key,
        'hit': hit,
        if (size != null) 'size': size,
      },
    ));
    
    debugPrint('💾 [PERFORMANCE-MONITOR] Cache operation: $operation $key (${duration}ms, ${hit ? 'HIT' : 'MISS'})');
  }

  /// Get performance metrics for a specific operation
  PerformanceMetric? getMetric(String operationName) {
    return _metrics[operationName];
  }

  /// Get all performance metrics
  Map<String, PerformanceMetric> getAllMetrics() {
    return Map.unmodifiable(_metrics);
  }

  /// Get recent performance events
  List<PerformanceEvent> getRecentEvents({int? limit}) {
    final events = _events.toList();
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    if (limit != null && events.length > limit) {
      return events.take(limit).toList();
    }
    
    return events;
  }

  /// Get performance summary
  PerformanceSummary getPerformanceSummary({Duration? period}) {
    final now = DateTime.now();
    final startTime = period != null ? now.subtract(period) : now.subtract(const Duration(hours: 1));
    
    final relevantEvents = _events.where((event) => event.timestamp.isAfter(startTime)).toList();
    
    final operationEvents = relevantEvents.where((e) => 
        e.type == PerformanceEventType.operationSuccess || 
        e.type == PerformanceEventType.operationFailure).toList();
    
    final networkEvents = relevantEvents.where((e) => 
        e.type == PerformanceEventType.networkSuccess || 
        e.type == PerformanceEventType.networkFailure).toList();
    
    final databaseEvents = relevantEvents.where((e) => 
        e.type == PerformanceEventType.databaseSuccess || 
        e.type == PerformanceEventType.databaseFailure).toList();
    
    final cacheEvents = relevantEvents.where((e) => 
        e.type == PerformanceEventType.cacheHit || 
        e.type == PerformanceEventType.cacheMiss).toList();

    return PerformanceSummary(
      period: period ?? const Duration(hours: 1),
      totalEvents: relevantEvents.length,
      operationCount: operationEvents.length,
      averageOperationDuration: _calculateAverageDuration(operationEvents),
      operationSuccessRate: _calculateSuccessRate(operationEvents),
      networkRequestCount: networkEvents.length,
      averageNetworkDuration: _calculateAverageDuration(networkEvents),
      networkSuccessRate: _calculateSuccessRate(networkEvents),
      databaseOperationCount: databaseEvents.length,
      averageDatabaseDuration: _calculateAverageDuration(databaseEvents),
      databaseSuccessRate: _calculateSuccessRate(databaseEvents),
      cacheHitRate: _calculateCacheHitRate(cacheEvents),
      generatedAt: now,
    );
  }

  /// Export performance data for analysis
  Map<String, dynamic> exportPerformanceData() {
    return {
      'metrics': _metrics.map((key, value) => MapEntry(key, value.toJson())),
      'events': _events.map((event) => event.toJson()).toList(),
      'summary': getPerformanceSummary().toJson(),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  // Private helper methods
  void _updateMetric(String name, int duration, bool success) {
    final metric = _metrics.putIfAbsent(name, () => PerformanceMetric(name: name));
    metric.addMeasurement(duration, success);
  }

  void _recordEvent(PerformanceEvent event) {
    _events.add(event);
    
    // Keep only recent events
    while (_events.length > _maxEvents) {
      _events.removeFirst();
    }
  }

  void _cleanup() {
    final cutoff = DateTime.now().subtract(_metricsRetentionPeriod);
    
    // Remove old events
    _events.removeWhere((event) => event.timestamp.isBefore(cutoff));
    
    // Clean up metrics
    _metrics.removeWhere((key, metric) => metric.lastUpdated.isBefore(cutoff));
    
    debugPrint('🧹 [PERFORMANCE-MONITOR] Cleaned up old performance data');
  }

  void _generateReport() {
    final summary = getPerformanceSummary();
    debugPrint('📊 [PERFORMANCE-MONITOR] Performance Summary: ${summary.toString()}');
  }

  void _startMemoryMonitoring() {
    Timer.periodic(const Duration(seconds: 30), (_) {
      recordMemoryUsage();
    });
  }

  double _calculateAverageDuration(List<PerformanceEvent> events) {
    if (events.isEmpty) return 0.0;
    
    final durations = events.where((e) => e.duration != null).map((e) => e.duration!);
    if (durations.isEmpty) return 0.0;
    
    return durations.reduce((a, b) => a + b) / durations.length;
  }

  double _calculateSuccessRate(List<PerformanceEvent> events) {
    if (events.isEmpty) return 0.0;
    
    final successEvents = events.where((e) => 
        e.type == PerformanceEventType.operationSuccess ||
        e.type == PerformanceEventType.networkSuccess ||
        e.type == PerformanceEventType.databaseSuccess).length;
    
    return successEvents / events.length;
  }

  double _calculateCacheHitRate(List<PerformanceEvent> events) {
    if (events.isEmpty) return 0.0;
    
    final hitEvents = events.where((e) => e.type == PerformanceEventType.cacheHit).length;
    return hitEvents / events.length;
  }
}

/// Performance metric tracking
class PerformanceMetric {
  final String name;
  final List<int> _durations = [];
  final List<bool> _successes = [];
  DateTime lastUpdated = DateTime.now();

  PerformanceMetric({required this.name});

  void addMeasurement(int duration, bool success) {
    _durations.add(duration);
    _successes.add(success);
    lastUpdated = DateTime.now();
    
    // Keep only recent measurements
    const maxMeasurements = 1000;
    if (_durations.length > maxMeasurements) {
      _durations.removeAt(0);
      _successes.removeAt(0);
    }
  }

  double get averageDuration {
    if (_durations.isEmpty) return 0.0;
    return _durations.reduce((a, b) => a + b) / _durations.length;
  }

  int get minDuration => _durations.isEmpty ? 0 : _durations.reduce((a, b) => a < b ? a : b);
  int get maxDuration => _durations.isEmpty ? 0 : _durations.reduce((a, b) => a > b ? a : b);

  double get successRate {
    if (_successes.isEmpty) return 0.0;
    return _successes.where((s) => s).length / _successes.length;
  }

  int get totalMeasurements => _durations.length;

  Map<String, dynamic> toJson() => {
    'name': name,
    'average_duration': averageDuration,
    'min_duration': minDuration,
    'max_duration': maxDuration,
    'success_rate': successRate,
    'total_measurements': totalMeasurements,
    'last_updated': lastUpdated.toIso8601String(),
  };
}

/// Performance event types
enum PerformanceEventType {
  operationStart,
  operationSuccess,
  operationFailure,
  networkSuccess,
  networkFailure,
  databaseSuccess,
  databaseFailure,
  cacheHit,
  cacheMiss,
  memoryUsage,
  customMetric,
}

/// Performance event
class PerformanceEvent {
  final String name;
  final PerformanceEventType type;
  final DateTime timestamp;
  final int? duration;
  final double? value;
  final Map<String, dynamic>? metadata;

  const PerformanceEvent({
    required this.name,
    required this.type,
    required this.timestamp,
    this.duration,
    this.value,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    if (duration != null) 'duration': duration,
    if (value != null) 'value': value,
    if (metadata != null) 'metadata': metadata,
  };
}

/// Performance summary
class PerformanceSummary {
  final Duration period;
  final int totalEvents;
  final int operationCount;
  final double averageOperationDuration;
  final double operationSuccessRate;
  final int networkRequestCount;
  final double averageNetworkDuration;
  final double networkSuccessRate;
  final int databaseOperationCount;
  final double averageDatabaseDuration;
  final double databaseSuccessRate;
  final double cacheHitRate;
  final DateTime generatedAt;

  const PerformanceSummary({
    required this.period,
    required this.totalEvents,
    required this.operationCount,
    required this.averageOperationDuration,
    required this.operationSuccessRate,
    required this.networkRequestCount,
    required this.averageNetworkDuration,
    required this.networkSuccessRate,
    required this.databaseOperationCount,
    required this.averageDatabaseDuration,
    required this.databaseSuccessRate,
    required this.cacheHitRate,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
    'period_hours': period.inHours,
    'total_events': totalEvents,
    'operation_count': operationCount,
    'average_operation_duration': averageOperationDuration,
    'operation_success_rate': operationSuccessRate,
    'network_request_count': networkRequestCount,
    'average_network_duration': averageNetworkDuration,
    'network_success_rate': networkSuccessRate,
    'database_operation_count': databaseOperationCount,
    'average_database_duration': averageDatabaseDuration,
    'database_success_rate': databaseSuccessRate,
    'cache_hit_rate': cacheHitRate,
    'generated_at': generatedAt.toIso8601String(),
  };

  @override
  String toString() {
    return 'PerformanceSummary(${period.inHours}h): '
           'Operations: $operationCount (${(operationSuccessRate * 100).toStringAsFixed(1)}% success, '
           '${averageOperationDuration.toStringAsFixed(1)}ms avg), '
           'Network: $networkRequestCount (${(networkSuccessRate * 100).toStringAsFixed(1)}% success, '
           '${averageNetworkDuration.toStringAsFixed(1)}ms avg), '
           'Database: $databaseOperationCount (${(databaseSuccessRate * 100).toStringAsFixed(1)}% success, '
           '${averageDatabaseDuration.toStringAsFixed(1)}ms avg), '
           'Cache: ${(cacheHitRate * 100).toStringAsFixed(1)}% hit rate';
  }
}
