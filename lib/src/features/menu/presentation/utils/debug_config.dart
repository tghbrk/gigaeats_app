import 'package:flutter/foundation.dart';

/// Debug configuration for template-only workflow
class TemplateDebugConfig {
  // Debug flags for different components
  static const bool enableUILogging = kDebugMode;
  static const bool enableStateLogging = kDebugMode;
  static const bool enableDatabaseLogging = kDebugMode;
  static const bool enablePerformanceLogging = kDebugMode;
  static const bool enableCacheLogging = kDebugMode;
  static const bool enableWorkflowLogging = kDebugMode;
  static const bool enableErrorLogging = true; // Always enabled
  
  // Detailed logging flags
  static const bool logTemplateSelection = enableUILogging;
  static const bool logTemplateFiltering = enableUILogging;
  static const bool logTemplateValidation = enableUILogging;
  static const bool logCustomerPreview = enableUILogging;
  static const bool logTemplateManagement = enableUILogging;
  
  // Provider logging flags
  static const bool logProviderStateChanges = enableStateLogging;
  static const bool logProviderCacheOperations = enableCacheLogging;
  static const bool logProviderErrors = enableErrorLogging;
  
  // Database logging flags
  static const bool logDatabaseQueries = enableDatabaseLogging;
  static const bool logDatabaseMutations = enableDatabaseLogging;
  static const bool logDatabasePerformance = enablePerformanceLogging;
  
  // Performance thresholds (in milliseconds)
  static const int slowQueryThreshold = 1000;
  static const int slowUIOperationThreshold = 500;
  static const int slowCacheOperationThreshold = 100;
  
  // Cache configuration
  static const int maxCacheAge = 5; // minutes
  static const int maxCacheSize = 100; // number of items
  
  // Session tracking
  static const bool enableSessionTracking = kDebugMode;
  static const int maxSessionEvents = 50;
  
  /// Check if a specific debug category is enabled
  static bool isEnabled(DebugCategory category) {
    switch (category) {
      case DebugCategory.ui:
        return enableUILogging;
      case DebugCategory.state:
        return enableStateLogging;
      case DebugCategory.database:
        return enableDatabaseLogging;
      case DebugCategory.performance:
        return enablePerformanceLogging;
      case DebugCategory.cache:
        return enableCacheLogging;
      case DebugCategory.workflow:
        return enableWorkflowLogging;
      case DebugCategory.error:
        return enableErrorLogging;
    }
  }
  
  /// Check if performance logging should be triggered based on duration
  static bool shouldLogPerformance(Duration duration, PerformanceType type) {
    if (!enablePerformanceLogging) return false;
    
    final milliseconds = duration.inMilliseconds;
    switch (type) {
      case PerformanceType.query:
        return milliseconds > slowQueryThreshold;
      case PerformanceType.ui:
        return milliseconds > slowUIOperationThreshold;
      case PerformanceType.cache:
        return milliseconds > slowCacheOperationThreshold;
    }
  }
  
  /// Get debug level for a specific operation
  static DebugLevel getDebugLevel(String operation) {
    // Critical operations that should always be logged
    if (operation.contains('error') || operation.contains('fail')) {
      return DebugLevel.error;
    }
    
    // Important operations
    if (operation.contains('create') || 
        operation.contains('update') || 
        operation.contains('delete') ||
        operation.contains('migrate')) {
      return DebugLevel.warning;
    }
    
    // Regular operations
    return DebugLevel.info;
  }
}

/// Debug categories for filtering logs
enum DebugCategory {
  ui,
  state,
  database,
  performance,
  cache,
  workflow,
  error,
}

/// Performance operation types
enum PerformanceType {
  query,
  ui,
  cache,
}

/// Debug levels
enum DebugLevel {
  info,
  warning,
  error,
}

/// Debug metrics collector
class TemplateDebugMetrics {
  static final Map<String, int> _operationCounts = {};
  static final Map<String, List<Duration>> _operationDurations = {};
  static final Map<String, int> _errorCounts = {};
  static final List<String> _recentErrors = [];
  
  /// Record an operation
  static void recordOperation(String operation, Duration duration) {
    if (!kDebugMode) return;
    
    _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;
    _operationDurations.putIfAbsent(operation, () => []).add(duration);
    
    // Keep only recent durations (last 100)
    if (_operationDurations[operation]!.length > 100) {
      _operationDurations[operation]!.removeAt(0);
    }
  }
  
  /// Record an error
  static void recordError(String operation, String error) {
    if (!kDebugMode) return;
    
    _errorCounts[operation] = (_errorCounts[operation] ?? 0) + 1;
    _recentErrors.add('[$operation] $error');
    
    // Keep only recent errors (last 50)
    if (_recentErrors.length > 50) {
      _recentErrors.removeAt(0);
    }
  }
  
  /// Get operation statistics
  static Map<String, dynamic> getOperationStats(String operation) {
    if (!kDebugMode) return {};
    
    final durations = _operationDurations[operation] ?? [];
    if (durations.isEmpty) {
      return {
        'count': _operationCounts[operation] ?? 0,
        'errors': _errorCounts[operation] ?? 0,
      };
    }
    
    final totalMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    final avgMs = totalMs / durations.length;
    final minMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
    final maxMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);
    
    return {
      'count': _operationCounts[operation] ?? 0,
      'errors': _errorCounts[operation] ?? 0,
      'avgDuration': '${avgMs.toStringAsFixed(1)}ms',
      'minDuration': '${minMs}ms',
      'maxDuration': '${maxMs}ms',
      'totalDuration': '${totalMs}ms',
    };
  }
  
  /// Get all metrics
  static Map<String, dynamic> getAllMetrics() {
    if (!kDebugMode) return {};
    
    final metrics = <String, dynamic>{};
    
    for (final operation in _operationCounts.keys) {
      metrics[operation] = getOperationStats(operation);
    }
    
    metrics['summary'] = {
      'totalOperations': _operationCounts.values.fold<int>(0, (sum, count) => sum + count),
      'totalErrors': _errorCounts.values.fold<int>(0, (sum, count) => sum + count),
      'uniqueOperations': _operationCounts.length,
      'recentErrorsCount': _recentErrors.length,
    };
    
    return metrics;
  }
  
  /// Print metrics summary
  static void printMetricsSummary() {
    if (!kDebugMode) return;
    
    debugPrint('📊 [TEMPLATE-DEBUG-METRICS] Summary:');
    
    final summary = getAllMetrics()['summary'] as Map<String, dynamic>;
    debugPrint('  Total Operations: ${summary['totalOperations']}');
    debugPrint('  Total Errors: ${summary['totalErrors']}');
    debugPrint('  Unique Operations: ${summary['uniqueOperations']}');
    debugPrint('  Recent Errors: ${summary['recentErrorsCount']}');
    
    if (_recentErrors.isNotEmpty) {
      debugPrint('  Last 5 Errors:');
      for (final error in _recentErrors.take(5)) {
        debugPrint('    $error');
      }
    }
    
    // Print top 5 operations by count
    final sortedOps = _operationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedOps.isNotEmpty) {
      debugPrint('  Top Operations:');
      for (final entry in sortedOps.take(5)) {
        final stats = getOperationStats(entry.key);
        debugPrint('    ${entry.key}: ${entry.value} calls, ${stats['avgDuration']} avg');
      }
    }
  }
  
  /// Clear all metrics
  static void clearMetrics() {
    if (!kDebugMode) return;
    
    _operationCounts.clear();
    _operationDurations.clear();
    _errorCounts.clear();
    _recentErrors.clear();
    
    debugPrint('📊 [TEMPLATE-DEBUG-METRICS] Metrics cleared');
  }
}

/// Debug session manager
class TemplateDebugSessionManager {
  static final Map<String, DateTime> _activeSessions = {};
  static final Map<String, List<String>> _sessionEvents = {};
  
  /// Start a debug session
  static void startSession(String sessionId) {
    if (!kDebugMode) return;
    
    _activeSessions[sessionId] = DateTime.now();
    _sessionEvents[sessionId] = [];
    
    debugPrint('🔧 [DEBUG-SESSION-MANAGER] Started session: $sessionId');
  }
  
  /// Add event to session
  static void addSessionEvent(String sessionId, String event) {
    if (!kDebugMode) return;
    
    if (_sessionEvents.containsKey(sessionId)) {
      _sessionEvents[sessionId]!.add('${DateTime.now().toIso8601String()}: $event');
      
      // Limit events per session
      if (_sessionEvents[sessionId]!.length > TemplateDebugConfig.maxSessionEvents) {
        _sessionEvents[sessionId]!.removeAt(0);
      }
    }
  }
  
  /// End a debug session
  static void endSession(String sessionId, [String? result]) {
    if (!kDebugMode) return;
    
    final startTime = _activeSessions[sessionId];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      final events = _sessionEvents[sessionId] ?? [];
      
      debugPrint('🔧 [DEBUG-SESSION-MANAGER] Ended session: $sessionId');
      debugPrint('  Duration: ${duration.inMilliseconds}ms');
      debugPrint('  Events: ${events.length}');
      if (result != null) debugPrint('  Result: $result');
      
      _activeSessions.remove(sessionId);
      _sessionEvents.remove(sessionId);
    }
  }
  
  /// Get active sessions
  static List<String> getActiveSessions() {
    if (!kDebugMode) return [];
    return _activeSessions.keys.toList();
  }
  
  /// Clear all sessions
  static void clearSessions() {
    if (!kDebugMode) return;
    
    _activeSessions.clear();
    _sessionEvents.clear();
    
    debugPrint('🔧 [DEBUG-SESSION-MANAGER] All sessions cleared');
  }
}
