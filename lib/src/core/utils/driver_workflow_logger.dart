import 'package:flutter/foundation.dart';

/// Centralized logging utility for driver workflow debugging
/// Provides structured logging with consistent formatting and filtering
class DriverWorkflowLogger {
  static const String _prefix = '🚗 [DRIVER-WORKFLOW]';
  
  /// Log workflow state transitions
  static void logStatusTransition({
    required String orderId,
    required String fromStatus,
    required String toStatus,
    String? driverId,
    String? context,
  }) {
    if (kDebugMode) {
      final contextStr = context != null ? ' [$context]' : '';
      final driverStr = driverId != null ? ' (Driver: ${driverId.substring(0, 8)}...)' : '';
      debugPrint('$_prefix$contextStr Status Transition: $fromStatus → $toStatus for order ${orderId.substring(0, 8)}...$driverStr');
    }
  }
  
  /// Log button interactions
  static void logButtonInteraction({
    required String buttonName,
    required String orderId,
    required String currentStatus,
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    if (kDebugMode) {
      final contextStr = context != null ? ' [$context]' : '';
      final metadataStr = metadata != null ? ' | Metadata: $metadata' : '';
      debugPrint('$_prefix$contextStr Button Pressed: "$buttonName" | Order: ${orderId.substring(0, 8)}... | Status: $currentStatus$metadataStr');
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
  
  /// Enable/disable debug logging (useful for production)
  static bool _isEnabled = kDebugMode;
  
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }
  
  static bool get isEnabled => _isEnabled;
}
