import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/driver_workflow_logger.dart';
import '../../../../core/monitoring/performance_monitor.dart';
import '../models/driver_order.dart';

/// Enhanced logging integration service for comprehensive driver workflow monitoring
/// Provides automated logging, performance tracking, and debugging capabilities
class EnhancedLoggingIntegrationService {
  final PerformanceMonitor _performanceMonitor;
  final Map<String, Stopwatch> _activeOperations = {};
  final Map<String, List<String>> _operationChains = {};

  EnhancedLoggingIntegrationService({
    required PerformanceMonitor performanceMonitor,
  }) : _performanceMonitor = performanceMonitor;

  /// Start tracking an operation with automatic logging
  String startOperation({
    required String operationType,
    required String orderId,
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    final operationId = '${operationType}_${DateTime.now().millisecondsSinceEpoch}';
    final stopwatch = Stopwatch()..start();
    _activeOperations[operationId] = stopwatch;

    DriverWorkflowLogger.logDatabaseOperation(
      operation: 'START_$operationType',
      orderId: orderId,
      context: context ?? 'LOGGING_SERVICE',
      data: {
        'operation_id': operationId,
        'start_time': DateTime.now().toIso8601String(),
        ...?metadata,
      },
    );

    return operationId;
  }

  /// Complete an operation with performance tracking
  void completeOperation({
    required String operationId,
    required String orderId,
    bool isSuccess = true,
    String? error,
    Map<String, dynamic>? resultData,
    String? context,
  }) {
    final stopwatch = _activeOperations.remove(operationId);
    if (stopwatch == null) return;

    stopwatch.stop();
    final duration = stopwatch.elapsed;

    // Extract operation type from ID
    final operationType = operationId.split('_').first;

    // Log completion
    DriverWorkflowLogger.logDatabaseOperation(
      operation: 'COMPLETE_$operationType',
      orderId: orderId,
      context: context ?? 'LOGGING_SERVICE',
      isSuccess: isSuccess,
      error: error,
      data: {
        'operation_id': operationId,
        'duration_ms': duration.inMilliseconds,
        'end_time': DateTime.now().toIso8601String(),
        ...?resultData,
      },
    );

    // Log performance
    DriverWorkflowLogger.logPerformance(
      operation: operationType,
      duration: duration,
      orderId: orderId,
      context: context ?? 'LOGGING_SERVICE',
    );

    // Record in performance monitor
    _performanceMonitor.recordMetric(
      operation: operationType,
      category: 'driver_workflow',
      durationMs: duration.inMilliseconds,
      metadata: {
        'order_id': orderId,
        'success': isSuccess,
        'error': error,
        ...?resultData,
      },
    );
  }

  /// Log a complete workflow operation with automatic timing
  Future<T> logWorkflowOperation<T>({
    required String operationType,
    required String orderId,
    required Future<T> Function() operation,
    String? context,
    Map<String, dynamic>? metadata,
  }) async {
    final operationId = startOperation(
      operationType: operationType,
      orderId: orderId,
      context: context,
      metadata: metadata,
    );

    try {
      final result = await operation();
      
      completeOperation(
        operationId: operationId,
        orderId: orderId,
        isSuccess: true,
        context: context,
        resultData: {'result_type': result.runtimeType.toString()},
      );
      
      return result;
    } catch (e) {
      completeOperation(
        operationId: operationId,
        orderId: orderId,
        isSuccess: false,
        error: e.toString(),
        context: context,
      );
      rethrow;
    }
  }

  /// Log provider state changes with context
  void logProviderStateChange({
    required String providerName,
    required String state,
    String? orderId,
    String? context,
    Map<String, dynamic>? details,
    String? previousState,
  }) {
    DriverWorkflowLogger.logProviderState(
      providerName: providerName,
      state: state,
      orderId: orderId,
      context: context ?? 'PROVIDER_MONITORING',
      details: {
        'previous_state': previousState,
        'timestamp': DateTime.now().toIso8601String(),
        ...?details,
      },
    );
  }

  /// Log button interactions with enhanced tracking
  void logButtonInteraction({
    required String buttonName,
    required String orderId,
    required String currentStatus,
    String? context,
    Map<String, dynamic>? metadata,
    bool trackResponseTime = true,
  }) {
    final responseTime = trackResponseTime ? _calculateResponseTime(buttonName) : null;
    
    DriverWorkflowLogger.logButtonInteraction(
      buttonName: buttonName,
      orderId: orderId,
      currentStatus: currentStatus,
      context: context ?? 'UI_INTERACTION',
      metadata: {
        'interaction_time': DateTime.now().toIso8601String(),
        'user_agent': 'flutter_app',
        ...?metadata,
      },
      responseTime: responseTime,
    );
  }

  /// Log status transitions with validation tracking
  void logStatusTransition({
    required String orderId,
    required String fromStatus,
    required String toStatus,
    String? driverId,
    String? context,
    bool isValidTransition = true,
    String? validationError,
    Map<String, dynamic>? metadata,
  }) {
    DriverWorkflowLogger.logStatusTransition(
      orderId: orderId,
      fromStatus: fromStatus,
      toStatus: toStatus,
      driverId: driverId,
      context: context ?? 'STATUS_TRANSITION',
      metadata: {
        'is_valid_transition': isValidTransition,
        'validation_error': validationError,
        'transition_time': DateTime.now().toIso8601String(),
        ...?metadata,
      },
    );

    // Track transition in operation chain
    _trackOperationChain(orderId, '$fromStatus→$toStatus');
  }

  /// Log validation results with detailed context
  void logValidation({
    required String validationType,
    required bool isValid,
    required String orderId,
    String? context,
    String? reason,
    Map<String, dynamic>? validationData,
  }) {
    DriverWorkflowLogger.logValidation(
      validationType: validationType,
      isValid: isValid,
      orderId: orderId,
      context: context ?? 'VALIDATION',
      reason: reason,
    );

    // Log additional validation data if provided
    if (validationData != null && validationData.isNotEmpty) {
      debugPrint('🔍 [VALIDATION] Additional data: $validationData');
    }
  }

  /// Log errors with enhanced context and stack traces
  void logError({
    required String operation,
    required String error,
    String? orderId,
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? errorContext,
    String? recoveryAction,
  }) {
    DriverWorkflowLogger.logError(
      operation: operation,
      error: error,
      orderId: orderId,
      context: context ?? 'ERROR_TRACKING',
      stackTrace: stackTrace,
    );

    // Also log to performance monitor for error tracking
    _performanceMonitor.recordMetric(
      operation: '${operation}_error',
      category: 'error',
      durationMs: 0,
      metadata: {
        'error_message': error,
        'order_id': orderId,
        'context': context,
        'recovery_action': recoveryAction,
        'error_time': DateTime.now().toIso8601String(),
        ...?errorContext,
      },
    );
  }

  /// Generate comprehensive workflow summary
  Map<String, dynamic> generateWorkflowSummary({
    required String orderId,
    DateTime? since,
  }) {
    final logs = DriverWorkflowLogger.getLogHistory(
      orderId: orderId,
      since: since,
    );

    final statusTransitions = logs
        .where((log) => log.category == 'STATUS_TRANSITION')
        .map((log) => {
          'timestamp': log.timestamp.toIso8601String(),
          'from_status': log.metadata?['from_status'],
          'to_status': log.metadata?['to_status'],
          'duration_ms': log.metadata?['transition_duration_ms'],
        })
        .toList();

    final buttonInteractions = logs
        .where((log) => log.category == 'BUTTON_INTERACTION')
        .map((log) => {
          'timestamp': log.timestamp.toIso8601String(),
          'button_name': log.metadata?['button_name'],
          'current_status': log.metadata?['current_status'],
          'response_time_ms': log.metadata?['response_time_ms'],
        })
        .toList();

    final errors = logs
        .where((log) => log.level == LogLevel.error)
        .map((log) => {
          'timestamp': log.timestamp.toIso8601String(),
          'operation': log.category,
          'error': log.message,
          'context': log.context,
        })
        .toList();

    final performanceMetrics = logs
        .where((log) => log.level == LogLevel.performance)
        .map((log) => {
          'timestamp': log.timestamp.toIso8601String(),
          'operation': log.category,
          'duration_ms': log.metadata?['duration_ms'],
        })
        .toList();

    return {
      'order_id': orderId,
      'summary_generated_at': DateTime.now().toIso8601String(),
      'total_log_entries': logs.length,
      'status_transitions': statusTransitions,
      'button_interactions': buttonInteractions,
      'errors': errors,
      'performance_metrics': performanceMetrics,
      'operation_chain': _operationChains[orderId] ?? [],
    };
  }

  /// Calculate response time for button interactions
  Duration? _calculateResponseTime(String buttonName) {
    // This is a simplified implementation
    // In a real scenario, you'd track when the button was pressed vs when the action completed
    return const Duration(milliseconds: 150); // Placeholder
  }

  /// Track operation chains for workflow analysis
  void _trackOperationChain(String orderId, String operation) {
    if (!_operationChains.containsKey(orderId)) {
      _operationChains[orderId] = [];
    }
    _operationChains[orderId]!.add(operation);
    
    // Keep only last 20 operations per order
    if (_operationChains[orderId]!.length > 20) {
      _operationChains[orderId]!.removeAt(0);
    }
  }

  /// Export comprehensive logs for debugging
  String exportDebugLogs({
    String? orderId,
    DateTime? since,
    List<LogLevel>? levels,
  }) {
    final logs = DriverWorkflowLogger.getLogHistory(
      orderId: orderId,
      since: since,
    ).where((log) => levels?.contains(log.level) ?? true).toList();

    final performanceStats = DriverWorkflowLogger.getPerformanceStats();
    
    return jsonEncode({
      'export_info': {
        'timestamp': DateTime.now().toIso8601String(),
        'order_id_filter': orderId,
        'since_filter': since?.toIso8601String(),
        'level_filters': levels?.map((l) => l.name).toList(),
        'total_entries': logs.length,
      },
      'performance_stats': performanceStats,
      'operation_chains': _operationChains,
      'active_operations': _activeOperations.keys.toList(),
      'logs': logs.map((log) => log.toJson()).toList(),
    });
  }

  /// Dispose resources
  void dispose() {
    _activeOperations.clear();
    _operationChains.clear();
  }
}

/// Provider for enhanced logging integration service
final enhancedLoggingIntegrationServiceProvider = Provider<EnhancedLoggingIntegrationService>((ref) {
  return EnhancedLoggingIntegrationService(
    performanceMonitor: PerformanceMonitor(),
  );
});
