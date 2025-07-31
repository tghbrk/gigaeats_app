import 'dart:async';
import 'package:flutter/foundation.dart';
import 'enhanced_supabase_connection_manager.dart';
import 'app_lifecycle_service.dart';

/// Debug logging levels for real-time connections
enum DebugLogLevel {
  verbose,
  info,
  warning,
  error,
  critical,
}

/// Debug log entry for real-time connections
class DebugLogEntry {
  final DateTime timestamp;
  final DebugLogLevel level;
  final String category;
  final String message;
  final Map<String, dynamic>? metadata;
  final String? stackTrace;

  const DebugLogEntry({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.metadata,
    this.stackTrace,
  });

  String get formattedMessage {
    final levelIcon = _getLevelIcon(level);
    final timeStr = timestamp.toIso8601String().substring(11, 23); // HH:mm:ss.SSS
    
    var msg = '$levelIcon [$timeStr] [$category] $message';
    
    if (metadata != null && metadata!.isNotEmpty) {
      msg += ' | ${metadata.toString()}';
    }
    
    return msg;
  }

  String _getLevelIcon(DebugLogLevel level) {
    switch (level) {
      case DebugLogLevel.verbose:
        return '🔍';
      case DebugLogLevel.info:
        return 'ℹ️';
      case DebugLogLevel.warning:
        return '⚠️';
      case DebugLogLevel.error:
        return '❌';
      case DebugLogLevel.critical:
        return '🚨';
    }
  }
}

/// Comprehensive debug logger for real-time connection monitoring
class RealtimeConnectionDebugLogger {
  static final RealtimeConnectionDebugLogger _instance = 
      RealtimeConnectionDebugLogger._internal();
  
  factory RealtimeConnectionDebugLogger() => _instance;
  
  RealtimeConnectionDebugLogger._internal();

  final List<DebugLogEntry> _logEntries = [];
  final StreamController<DebugLogEntry> _logStreamController = 
      StreamController<DebugLogEntry>.broadcast();
  
  bool _isInitialized = false;
  DebugLogLevel _minLogLevel = DebugLogLevel.info;
  int _maxLogEntries = 1000;
  
  StreamSubscription<ConnectionHealth>? _connectionHealthSubscription;
  StreamSubscription<AppLifecycleEvent>? _lifecycleSubscription;
  
  /// Stream of debug log entries
  Stream<DebugLogEntry> get logStream => _logStreamController.stream;
  
  /// Get all log entries
  List<DebugLogEntry> get logEntries => List.unmodifiable(_logEntries);
  
  /// Initialize the debug logger
  Future<void> initialize({
    DebugLogLevel minLogLevel = DebugLogLevel.info,
    int maxLogEntries = 1000,
  }) async {
    if (_isInitialized) return;
    
    _minLogLevel = minLogLevel;
    _maxLogEntries = maxLogEntries;
    
    log(DebugLogLevel.info, 'DEBUG-LOGGER', 'Initializing realtime connection debug logger');
    
    // Monitor connection manager
    await _setupConnectionMonitoring();
    
    // Monitor app lifecycle
    await _setupLifecycleMonitoring();
    
    _isInitialized = true;
    log(DebugLogLevel.info, 'DEBUG-LOGGER', 'Debug logger initialized successfully');
  }
  
  /// Log a debug message
  void log(
    DebugLogLevel level,
    String category,
    String message, {
    Map<String, dynamic>? metadata,
    String? stackTrace,
  }) {
    if (!_shouldLog(level)) return;
    
    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      metadata: metadata,
      stackTrace: stackTrace,
    );
    
    // Add to internal log
    _addLogEntry(entry);
    
    // Print to console in debug mode
    if (kDebugMode) {
      debugPrint(entry.formattedMessage);
      
      if (stackTrace != null && level.index >= DebugLogLevel.error.index) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
    
    // Emit to stream
    _logStreamController.add(entry);
  }
  
  /// Log verbose message
  void verbose(String category, String message, {Map<String, dynamic>? metadata}) {
    log(DebugLogLevel.verbose, category, message, metadata: metadata);
  }
  
  /// Log info message
  void info(String category, String message, {Map<String, dynamic>? metadata}) {
    log(DebugLogLevel.info, category, message, metadata: metadata);
  }
  
  /// Log warning message
  void warning(String category, String message, {Map<String, dynamic>? metadata}) {
    log(DebugLogLevel.warning, category, message, metadata: metadata);
  }
  
  /// Log error message
  void error(String category, String message, {
    Map<String, dynamic>? metadata,
    String? stackTrace,
  }) {
    log(DebugLogLevel.error, category, message, 
        metadata: metadata, stackTrace: stackTrace);
  }
  
  /// Log critical message
  void critical(String category, String message, {
    Map<String, dynamic>? metadata,
    String? stackTrace,
  }) {
    log(DebugLogLevel.critical, category, message, 
        metadata: metadata, stackTrace: stackTrace);
  }
  
  /// Log connection state change
  void logConnectionStateChange(
    String subscriptionId,
    ConnectionState fromState,
    ConnectionState toState, {
    String? reason,
    Duration? duration,
  }) {
    info('CONNECTION-STATE', 
         'Subscription $subscriptionId: ${fromState.name} → ${toState.name}',
         metadata: {
           'subscription_id': subscriptionId,
           'from_state': fromState.name,
           'to_state': toState.name,
           'reason': reason,
           'duration_ms': duration?.inMilliseconds,
         });
  }
  
  /// Log subscription error
  void logSubscriptionError(
    String subscriptionId,
    dynamic error, {
    String? errorType,
    int? attemptNumber,
  }) {
    this.error('SUBSCRIPTION-ERROR',
              'Subscription $subscriptionId failed: $error',
              metadata: {
                'subscription_id': subscriptionId,
                'error_type': errorType ?? error.runtimeType.toString(),
                'attempt_number': attemptNumber,
                'error_message': error.toString(),
              },
              stackTrace: error is Error ? error.stackTrace?.toString() : null);
  }
  
  /// Log network event
  void logNetworkEvent(
    String eventType,
    bool isConnected, {
    String? networkType,
    Duration? downtime,
  }) {
    info('NETWORK-EVENT',
         'Network $eventType: ${isConnected ? "Connected" : "Disconnected"}',
         metadata: {
           'event_type': eventType,
           'is_connected': isConnected,
           'network_type': networkType,
           'downtime_ms': downtime?.inMilliseconds,
         });
  }
  
  /// Log app lifecycle event
  void logAppLifecycleEvent(
    AppLifecycleEvent event, {
    Duration? backgroundDuration,
    bool? wasRecentlyBackgrounded,
  }) {
    info('APP-LIFECYCLE',
         'App lifecycle: ${event.name}',
         metadata: {
           'event': event.name,
           'background_duration_ms': backgroundDuration?.inMilliseconds,
           'was_recently_backgrounded': wasRecentlyBackgrounded,
         });
  }
  
  /// Get logs by category
  List<DebugLogEntry> getLogsByCategory(String category) {
    return _logEntries.where((entry) => entry.category == category).toList();
  }
  
  /// Get logs by level
  List<DebugLogEntry> getLogsByLevel(DebugLogLevel level) {
    return _logEntries.where((entry) => entry.level == level).toList();
  }
  
  /// Get recent logs
  List<DebugLogEntry> getRecentLogs(Duration duration) {
    final cutoff = DateTime.now().subtract(duration);
    return _logEntries.where((entry) => entry.timestamp.isAfter(cutoff)).toList();
  }
  
  /// Clear all logs
  void clearLogs() {
    _logEntries.clear();
    info('DEBUG-LOGGER', 'All logs cleared');
  }
  
  /// Export logs to string
  String exportLogs({
    DebugLogLevel? minLevel,
    String? category,
    Duration? timeRange,
  }) {
    var logs = _logEntries.asMap().entries;
    
    // Apply filters
    if (minLevel != null) {
      logs = logs.where((entry) => entry.value.level.index >= minLevel.index);
    }
    
    if (category != null) {
      logs = logs.where((entry) => entry.value.category == category);
    }
    
    if (timeRange != null) {
      final cutoff = DateTime.now().subtract(timeRange);
      logs = logs.where((entry) => entry.value.timestamp.isAfter(cutoff));
    }
    
    return logs.map((entry) => entry.value.formattedMessage).join('\n');
  }
  
  /// Dispose the debug logger
  Future<void> dispose() async {
    info('DEBUG-LOGGER', 'Disposing debug logger');
    
    await _connectionHealthSubscription?.cancel();
    await _lifecycleSubscription?.cancel();
    await _logStreamController.close();
    
    _isInitialized = false;
  }
  
  // Private methods
  
  bool _shouldLog(DebugLogLevel level) {
    return level.index >= _minLogLevel.index;
  }
  
  void _addLogEntry(DebugLogEntry entry) {
    _logEntries.add(entry);
    
    // Trim old entries if we exceed max
    if (_logEntries.length > _maxLogEntries) {
      _logEntries.removeRange(0, _logEntries.length - _maxLogEntries);
    }
  }
  
  Future<void> _setupConnectionMonitoring() async {
    final connectionManager = EnhancedSupabaseConnectionManager();
    
    _connectionHealthSubscription = connectionManager.connectionHealthStream.listen(
      (health) {
        info('CONNECTION-HEALTH',
             'Connection health update: ${health.state.name}',
             metadata: {
               'state': health.state.name,
               'is_network_available': health.isNetworkAvailable,
               'reconnect_attempts': health.reconnectAttempts,
               'last_error': health.lastError,
               'latency_ms': health.lastLatency?.inMilliseconds,
             });
      },
      onError: (error) {
        this.error('CONNECTION-MONITORING',
                  'Connection health monitoring error: $error');
      },
    );
  }
  
  Future<void> _setupLifecycleMonitoring() async {
    final lifecycleService = AppLifecycleService();
    
    _lifecycleSubscription = lifecycleService.lifecycleEventStream.listen(
      (event) {
        logAppLifecycleEvent(
          event,
          backgroundDuration: lifecycleService.timeSinceLastResume,
          wasRecentlyBackgrounded: lifecycleService.wasRecentlyBackgrounded,
        );
      },
      onError: (error) {
        this.error('LIFECYCLE-MONITORING',
                  'Lifecycle monitoring error: $error');
      },
    );
  }
}
