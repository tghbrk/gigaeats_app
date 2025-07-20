import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:developer' as developer;

/// Log levels for categorizing log entries
enum LogLevel {
  debug,
  info,
  warning,
  error,
  performance,
}

/// Log entry data structure for history tracking
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String category;
  final String message;
  final String? orderId;
  final String? context;
  final Map<String, dynamic>? metadata;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.orderId,
    this.context,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'category': category,
      'message': message,
      'order_id': orderId,
      'context': context,
      'metadata': metadata,
    };
  }
}

/// Enhanced centralized logging utility for driver workflow debugging
/// Provides structured logging with consistent formatting, filtering, and performance monitoring
class DriverWorkflowLogger {
  static const String _prefix = '🚗 [DRIVER-WORKFLOW]';
  static bool _isEnabled = kDebugMode;
  static final List<LogEntry> _logHistory = [];
  static const int _maxLogHistory = 1000;

  /// Enable or disable logging
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Check if logging is enabled
  static bool get isEnabled => _isEnabled;

  /// Log workflow state transitions with enhanced details
  static void logStatusTransition({
    required String orderId,
    required String fromStatus,
    required String toStatus,
    String? driverId,
    String? context,
    Map<String, dynamic>? metadata,
    Duration? transitionDuration,
  }) {
    if (!_isEnabled) return;

    final contextStr = context != null ? ' [$context]' : '';
    final driverStr = driverId != null ? ' (Driver: ${driverId.substring(0, 8)}...)' : '';
    final durationStr = transitionDuration != null ? ' (${transitionDuration.inMilliseconds}ms)' : '';
    final metadataStr = metadata != null ? ' | Metadata: ${_formatMetadata(metadata)}' : '';

    final message = '$_prefix$contextStr Status Transition: $fromStatus → $toStatus for order ${orderId.substring(0, 8)}...$driverStr$durationStr$metadataStr';

    _logWithHistory(
      level: LogLevel.info,
      category: 'STATUS_TRANSITION',
      message: message,
      orderId: orderId,
      context: context,
      metadata: {
        'from_status': fromStatus,
        'to_status': toStatus,
        'driver_id': driverId,
        'transition_duration_ms': transitionDuration?.inMilliseconds,
        ...?metadata,
      },
    );
  }

  /// Log button interactions with enhanced tracking
  static void logButtonInteraction({
    required String buttonName,
    required String orderId,
    required String currentStatus,
    String? context,
    Map<String, dynamic>? metadata,
    Duration? responseTime,
  }) {
    if (!_isEnabled) return;

    final contextStr = context != null ? ' [$context]' : '';
    final responseStr = responseTime != null ? ' (${responseTime.inMilliseconds}ms)' : '';
    final metadataStr = metadata != null ? ' | Metadata: ${_formatMetadata(metadata)}' : '';

    final message = '$_prefix$contextStr Button Pressed: "$buttonName" | Order: ${orderId.substring(0, 8)}... | Status: $currentStatus$responseStr$metadataStr';

    _logWithHistory(
      level: LogLevel.info,
      category: 'BUTTON_INTERACTION',
      message: message,
      orderId: orderId,
      context: context,
      metadata: {
        'button_name': buttonName,
        'current_status': currentStatus,
        'response_time_ms': responseTime?.inMilliseconds,
        ...?metadata,
      },
    );
  }

  /// Helper method to log with history tracking
  static void _logWithHistory({
    required LogLevel level,
    required String category,
    required String message,
    String? orderId,
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    // Add to history
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      orderId: orderId,
      context: context,
      metadata: metadata,
    );

    _logHistory.add(entry);

    // Maintain history size limit
    if (_logHistory.length > _maxLogHistory) {
      _logHistory.removeAt(0);
    }

    // Output to console
    debugPrint(message);

    // Also log to developer console for better debugging
    developer.log(
      message,
      name: 'DriverWorkflow',
      level: _getLogLevelValue(level),
    );
  }

  /// Helper method to format metadata for display
  static String _formatMetadata(Map<String, dynamic> metadata) {
    try {
      return jsonEncode(metadata);
    } catch (e) {
      return metadata.toString();
    }
  }

  /// Get numeric log level for developer.log
  static int _getLogLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.performance:
        return 700;
    }
  }
  
  /// Log database operations
  static void logDatabaseOperation({
    required String operation,
    required String orderId,
    Map<String, dynamic>? data,
    String? context,
    bool isSuccess = true,
    String? error,
  }) {
    if (kDebugMode) {
      final contextStr = context != null ? ' [$context]' : '';
      final statusIcon = isSuccess ? '✅' : '❌';
      final dataStr = data != null ? ' | Data: $data' : '';
      final errorStr = error != null ? ' | Error: $error' : '';
      debugPrint('$_prefix$contextStr DB $operation: $statusIcon Order ${orderId.substring(0, 8)}...$dataStr$errorStr');
    }
  }
  
  /// Log provider state changes
  static void logProviderState({
    required String providerName,
    required String state,
    String? orderId,
    String? context,
    Map<String, dynamic>? details,
  }) {
    if (kDebugMode) {
      final contextStr = context != null ? ' [$context]' : '';
      final orderStr = orderId != null ? ' | Order: ${orderId.substring(0, 8)}...' : '';
      final detailsStr = details != null ? ' | Details: $details' : '';
      debugPrint('$_prefix$contextStr Provider "$providerName": $state$orderStr$detailsStr');
    }
  }
  
  /// Log workflow validation results
  static void logValidation({
    required String validationType,
    required bool isValid,
    String? orderId,
    String? reason,
    String? context,
  }) {
    if (kDebugMode) {
      final contextStr = context != null ? ' [$context]' : '';
      final statusIcon = isValid ? '✅' : '❌';
      final orderStr = orderId != null ? ' | Order: ${orderId.substring(0, 8)}...' : '';
      final reasonStr = reason != null ? ' | Reason: $reason' : '';
      debugPrint('$_prefix$contextStr Validation "$validationType": $statusIcon$orderStr$reasonStr');
    }
  }
  
  /// Log error conditions
  static void logError({
    required String operation,
    required String error,
    String? orderId,
    String? context,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      final contextStr = context != null ? ' [$context]' : '';
      final orderStr = orderId != null ? ' | Order: ${orderId.substring(0, 8)}...' : '';
      debugPrint('$_prefix$contextStr ❌ ERROR in $operation: $error$orderStr');
      if (stackTrace != null) {
        debugPrint('$_prefix$contextStr Stack Trace: $stackTrace');
      }
    }
  }
  
  /// Log performance metrics
  static void logPerformance({
    required String operation,
    required Duration duration,
    String? orderId,
    String? context,
  }) {
    if (kDebugMode) {
      final contextStr = context != null ? ' [$context]' : '';
      final orderStr = orderId != null ? ' | Order: ${orderId.substring(0, 8)}...' : '';
      debugPrint('$_prefix$contextStr ⏱️ Performance "$operation": ${duration.inMilliseconds}ms$orderStr');
    }
  }
  
  /// Log workflow summary for debugging sessions
  static void logWorkflowSummary({
    required String orderId,
    required String currentStatus,
    required List<String> availableActions,
    String? driverId,
    Map<String, DateTime?>? timestamps,
  }) {
    if (kDebugMode) {
      final driverStr = driverId != null ? ' | Driver: ${driverId.substring(0, 8)}...' : '';
      debugPrint('$_prefix [SUMMARY] Order: ${orderId.substring(0, 8)}... | Status: $currentStatus$driverStr');
      debugPrint('$_prefix [SUMMARY] Available Actions: ${availableActions.join(', ')}');
      
      if (timestamps != null && timestamps.isNotEmpty) {
        debugPrint('$_prefix [SUMMARY] Timestamps:');
        timestamps.forEach((key, value) {
          final timeStr = value?.toIso8601String() ?? 'null';
          debugPrint('$_prefix [SUMMARY]   $key: $timeStr');
        });
      }
    }
  }

  /// Get log history for debugging and analysis
  static List<LogEntry> getLogHistory({
    String? orderId,
    LogLevel? level,
    String? category,
    DateTime? since,
  }) {
    return _logHistory.where((entry) {
      if (orderId != null && entry.orderId != orderId) return false;
      if (level != null && entry.level != level) return false;
      if (category != null && entry.category != category) return false;
      if (since != null && entry.timestamp.isBefore(since)) return false;
      return true;
    }).toList();
  }

  /// Export log history as JSON
  static String exportLogHistory({
    String? orderId,
    LogLevel? level,
    String? category,
    DateTime? since,
  }) {
    final filteredLogs = getLogHistory(
      orderId: orderId,
      level: level,
      category: category,
      since: since,
    );

    return jsonEncode({
      'export_timestamp': DateTime.now().toIso8601String(),
      'total_entries': filteredLogs.length,
      'filters': {
        'order_id': orderId,
        'level': level?.name,
        'category': category,
        'since': since?.toIso8601String(),
      },
      'entries': filteredLogs.map((e) => e.toJson()).toList(),
    });
  }

  /// Clear log history
  static void clearHistory() {
    _logHistory.clear();
  }

  /// Get performance statistics from logs
  static Map<String, dynamic> getPerformanceStats() {
    final performanceLogs = _logHistory.where((e) => e.level == LogLevel.performance).toList();

    if (performanceLogs.isEmpty) {
      return {'total_operations': 0};
    }

    final durations = performanceLogs
        .map((e) => e.metadata?['duration_ms'] as int?)
        .where((d) => d != null)
        .cast<int>()
        .toList();

    if (durations.isEmpty) {
      return {'total_operations': performanceLogs.length, 'durations_available': false};
    }

    durations.sort();

    return {
      'total_operations': performanceLogs.length,
      'average_duration_ms': durations.reduce((a, b) => a + b) / durations.length,
      'min_duration_ms': durations.first,
      'max_duration_ms': durations.last,
      'median_duration_ms': durations[durations.length ~/ 2],
      'p95_duration_ms': durations[(durations.length * 0.95).floor()],
    };
  }
}
