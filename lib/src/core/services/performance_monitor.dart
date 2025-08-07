
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Performance monitoring service for tracking app performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, PerformanceMetric> _metrics = {};
  final Queue<PerformanceEvent> _events = Queue<PerformanceEvent>();
  static const int _maxEvents = 1000;

  /// Start tracking a performance metric
  PerformanceTracker startTracking(String name, {Map<String, dynamic>? metadata}) {
    final tracker = PerformanceTracker._(name, metadata);
    debugPrint('📊 Performance: Started tracking $name');
    return tracker;
  }

  /// Record a performance metric
  void recordMetric(String name, int durationMs, {
    Map<String, dynamic>? metadata,
    bool isSuccess = true,
  }) {
    final metric = _metrics.putIfAbsent(name, () => PerformanceMetric(name));
    metric.addMeasurement(durationMs, isSuccess);

    final event = PerformanceEvent(
      name: name,
      durationMs: durationMs,
      timestamp: DateTime.now(),
      metadata: metadata,
      isSuccess: isSuccess,
    );

    _events.addLast(event);
    
    // Keep only recent events
    while (_events.length > _maxEvents) {
      _events.removeFirst();
    }

    debugPrint('📊 Performance: Recorded $name - ${durationMs}ms (success: $isSuccess)');
  }

  /// Get metric by name
  PerformanceMetric? getMetric(String name) => _metrics[name];

  /// Get all metrics
  Map<String, PerformanceMetric> getAllMetrics() => Map.unmodifiable(_metrics);

  /// Get recent events
  List<PerformanceEvent> getRecentEvents([int? limit]) {
    final events = _events.toList();
    if (limit != null && events.length > limit) {
      return events.sublist(events.length - limit);
    }
    return events;
  }

  /// Get performance summary
  PerformanceSummary getSummary() {
    final totalMetrics = _metrics.length;
    final totalEvents = _events.length;
    final averageResponseTime = _metrics.values.isEmpty
        ? 0.0
        : _metrics.values.map((m) => m.averageDuration).reduce((a, b) => a + b) / _metrics.length;
    
    final successRate = _events.isEmpty
        ? 1.0
        : _events.where((e) => e.isSuccess).length / _events.length;

    return PerformanceSummary(
      totalMetrics: totalMetrics,
      totalEvents: totalEvents,
      averageResponseTime: averageResponseTime,
      successRate: successRate,
      slowestMetrics: _getSlowestMetrics(),
      recentErrors: _getRecentErrors(),
    );
  }

  /// Clear all metrics and events
  void clear() {
    _metrics.clear();
    _events.clear();
    debugPrint('📊 Performance: Cleared all metrics and events');
  }

  List<PerformanceMetric> _getSlowestMetrics() {
    final metrics = _metrics.values.toList();
    metrics.sort((a, b) => b.averageDuration.compareTo(a.averageDuration));
    return metrics.take(5).toList();
  }

  List<PerformanceEvent> _getRecentErrors() {
    return _events.where((e) => !e.isSuccess).take(10).toList();
  }
}

/// Performance tracker for measuring duration
class PerformanceTracker {
  final String name;
  final Map<String, dynamic>? metadata;
  final Stopwatch _stopwatch = Stopwatch();

  PerformanceTracker._(this.name, this.metadata) {
    _stopwatch.start();
  }

  /// Stop tracking and record the metric
  void stop({bool isSuccess = true, Map<String, dynamic>? additionalMetadata}) {
    _stopwatch.stop();
    final finalMetadata = <String, dynamic>{
      ...?metadata,
      ...?additionalMetadata,
    };

    PerformanceMonitor().recordMetric(
      name,
      _stopwatch.elapsedMilliseconds,
      metadata: finalMetadata.isEmpty ? null : finalMetadata,
      isSuccess: isSuccess,
    );
  }

  /// Get current elapsed time without stopping
  int get elapsedMs => _stopwatch.elapsedMilliseconds;
}

/// Performance metric aggregation
class PerformanceMetric {
  final String name;
  final List<int> _measurements = [];
  final List<bool> _successes = [];
  DateTime? _firstMeasurement;
  DateTime? _lastMeasurement;

  PerformanceMetric(this.name);

  void addMeasurement(int durationMs, bool isSuccess) {
    _measurements.add(durationMs);
    _successes.add(isSuccess);
    
    final now = DateTime.now();
    _firstMeasurement ??= now;
    _lastMeasurement = now;
  }

  int get count => _measurements.length;
  double get averageDuration => _measurements.isEmpty ? 0.0 : _measurements.reduce((a, b) => a + b) / _measurements.length;
  int get minDuration => _measurements.isEmpty ? 0 : _measurements.reduce((a, b) => a < b ? a : b);
  int get maxDuration => _measurements.isEmpty ? 0 : _measurements.reduce((a, b) => a > b ? a : b);
  double get successRate => _successes.isEmpty ? 1.0 : _successes.where((s) => s).length / _successes.length;
  DateTime? get firstMeasurement => _firstMeasurement;
  DateTime? get lastMeasurement => _lastMeasurement;

  double get p95Duration {
    if (_measurements.isEmpty) return 0.0;
    final sorted = List<int>.from(_measurements)..sort();
    final index = (sorted.length * 0.95).ceil() - 1;
    return sorted[index.clamp(0, sorted.length - 1)].toDouble();
  }

  @override
  String toString() => 'PerformanceMetric('
      'name: $name, '
      'count: $count, '
      'avg: ${averageDuration.toStringAsFixed(1)}ms, '
      'p95: ${p95Duration.toStringAsFixed(1)}ms, '
      'successRate: ${(successRate * 100).toStringAsFixed(1)}%'
      ')';
}

/// Individual performance event
@immutable
class PerformanceEvent {
  final String name;
  final int durationMs;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final bool isSuccess;

  const PerformanceEvent({
    required this.name,
    required this.durationMs,
    required this.timestamp,
    this.metadata,
    required this.isSuccess,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceEvent &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          durationMs == other.durationMs &&
          timestamp == other.timestamp &&
          mapEquals(metadata, other.metadata) &&
          isSuccess == other.isSuccess;

  @override
  int get hashCode => Object.hash(name, durationMs, timestamp, metadata, isSuccess);

  @override
  String toString() => 'PerformanceEvent('
      'name: $name, '
      'duration: ${durationMs}ms, '
      'timestamp: $timestamp, '
      'success: $isSuccess'
      ')';
}

/// Performance summary
@immutable
class PerformanceSummary {
  final int totalMetrics;
  final int totalEvents;
  final double averageResponseTime;
  final double successRate;
  final List<PerformanceMetric> slowestMetrics;
  final List<PerformanceEvent> recentErrors;

  const PerformanceSummary({
    required this.totalMetrics,
    required this.totalEvents,
    required this.averageResponseTime,
    required this.successRate,
    required this.slowestMetrics,
    required this.recentErrors,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceSummary &&
          runtimeType == other.runtimeType &&
          totalMetrics == other.totalMetrics &&
          totalEvents == other.totalEvents &&
          averageResponseTime == other.averageResponseTime &&
          successRate == other.successRate &&
          listEquals(slowestMetrics, other.slowestMetrics) &&
          listEquals(recentErrors, other.recentErrors);

  @override
  int get hashCode => Object.hash(
        totalMetrics,
        totalEvents,
        averageResponseTime,
        successRate,
        Object.hashAll(slowestMetrics),
        Object.hashAll(recentErrors),
      );

  @override
  String toString() => 'PerformanceSummary('
      'metrics: $totalMetrics, '
      'events: $totalEvents, '
      'avgResponse: ${averageResponseTime.toStringAsFixed(1)}ms, '
      'successRate: ${(successRate * 100).toStringAsFixed(1)}%'
      ')';
}
