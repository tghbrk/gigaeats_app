import 'package:flutter/foundation.dart';

import '../../data/models/customization_template.dart';

/// Comprehensive debug logging system for template-only workflow
class TemplateDebugLogger {
  static const String _prefix = '🔧 [TEMPLATE-DEBUG]';
  static const String _uiPrefix = '🎨 [TEMPLATE-UI]';
  static const String _dbPrefix = '💾 [TEMPLATE-DB]';
  static const String _statePrefix = '📊 [TEMPLATE-STATE]';
  static const String _errorPrefix = '❌ [TEMPLATE-ERROR]';
  static const String _successPrefix = '✅ [TEMPLATE-SUCCESS]';
  static const String _warningPrefix = '⚠️ [TEMPLATE-WARNING]';
  static const String _infoPrefix = '💡 [TEMPLATE-INFO]';

  /// Log template selection events
  static void logTemplateSelection({
    required String templateId,
    required String templateName,
    required String menuItemId,
    required String action, // 'selected', 'deselected', 'reordered'
    Map<String, dynamic>? metadata,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final metadataStr = metadata != null ? ' | Metadata: $metadata' : '';
    
    debugPrint('$_uiPrefix [$timestamp] Template $action: $templateName ($templateId) for menu item: $menuItemId$metadataStr');
  }

  /// Log template search and filtering
  static void logTemplateFiltering({
    required String searchQuery,
    String? categoryFilter,
    String? typeFilter,
    required bool showOnlyRequired,
    required bool showOnlyActive,
    required int totalTemplates,
    required int filteredTemplates,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    debugPrint('$_uiPrefix [$timestamp] Template filtering applied:');
    debugPrint('  Search: "$searchQuery"');
    debugPrint('  Category: ${categoryFilter ?? "All"}');
    debugPrint('  Type: ${typeFilter ?? "All"}');
    debugPrint('  Required Only: $showOnlyRequired');
    debugPrint('  Active Only: $showOnlyActive');
    debugPrint('  Results: $filteredTemplates/$totalTemplates templates');
  }

  /// Log database operations
  static void logDatabaseOperation({
    required String operation, // 'create', 'read', 'update', 'delete', 'link', 'unlink'
    required String entityType, // 'template', 'menu_item', 'template_link'
    required String entityId,
    String? additionalInfo,
    Duration? duration,
    bool success = true,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final prefix = success ? _dbPrefix : _errorPrefix;
    final status = success ? 'SUCCESS' : 'FAILED';
    final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    final infoStr = additionalInfo != null ? ' | Info: $additionalInfo' : '';
    
    debugPrint('$prefix [$timestamp] $operation $entityType ($entityId) - $status$durationStr$infoStr');
  }

  /// Log state changes
  static void logStateChange({
    required String providerName,
    required String changeType, // 'loading', 'loaded', 'error', 'cache_hit', 'cache_miss'
    String? previousState,
    String? newState,
    Map<String, dynamic>? data,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final dataStr = data != null ? ' | Data: $data' : '';
    final stateTransition = previousState != null && newState != null 
        ? ' | Transition: $previousState → $newState' 
        : '';
    
    debugPrint('$_statePrefix [$timestamp] $providerName: $changeType$stateTransition$dataStr');
  }

  /// Log UI interactions
  static void logUIInteraction({
    required String component,
    required String action, // 'tap', 'long_press', 'drag', 'scroll', 'expand', 'collapse'
    String? target,
    Map<String, dynamic>? context,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final targetStr = target != null ? ' on $target' : '';
    final contextStr = context != null ? ' | Context: $context' : '';
    
    debugPrint('$_uiPrefix [$timestamp] $component: $action$targetStr$contextStr');
  }

  /// Log errors with stack trace
  static void logError({
    required String operation,
    required dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' | Context: $context' : '';
    
    debugPrint('$_errorPrefix [$timestamp] Error in $operation: $error$contextStr');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Log success operations
  static void logSuccess({
    required String operation,
    String? message,
    Map<String, dynamic>? data,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final messageStr = message != null ? ': $message' : '';
    final dataStr = data != null ? ' | Data: $data' : '';
    
    debugPrint('$_successPrefix [$timestamp] $operation$messageStr$dataStr');
  }

  /// Log warnings
  static void logWarning({
    required String operation,
    required String warning,
    Map<String, dynamic>? context,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' | Context: $context' : '';
    
    debugPrint('$_warningPrefix [$timestamp] $operation: $warning$contextStr');
  }

  /// Log informational messages
  static void logInfo({
    required String operation,
    required String message,
    Map<String, dynamic>? data,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final dataStr = data != null ? ' | Data: $data' : '';
    
    debugPrint('$_infoPrefix [$timestamp] $operation: $message$dataStr');
  }

  /// Log template validation
  static void logTemplateValidation({
    required CustomizationTemplate template,
    required bool isValid,
    List<String>? validationErrors,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final prefix = isValid ? _successPrefix : _errorPrefix;
    final status = isValid ? 'VALID' : 'INVALID';
    
    debugPrint('$prefix [$timestamp] Template validation: ${template.name} ($status)');
    if (!isValid && validationErrors != null) {
      for (final error in validationErrors) {
        debugPrint('  - $error');
      }
    }
  }

  /// Log performance metrics
  static void logPerformance({
    required String operation,
    required Duration duration,
    Map<String, dynamic>? metrics,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final metricsStr = metrics != null ? ' | Metrics: $metrics' : '';
    
    debugPrint('$_infoPrefix [$timestamp] Performance: $operation took ${duration.inMilliseconds}ms$metricsStr');
  }

  /// Log cache operations
  static void logCacheOperation({
    required String operation, // 'hit', 'miss', 'set', 'clear', 'invalidate'
    required String cacheKey,
    String? additionalInfo,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final infoStr = additionalInfo != null ? ' | Info: $additionalInfo' : '';
    
    debugPrint('$_statePrefix [$timestamp] Cache $operation: $cacheKey$infoStr');
  }

  /// Log template workflow events
  static void logWorkflowEvent({
    required String workflow, // 'template_selection', 'customer_preview', 'template_management'
    required String event, // 'started', 'completed', 'cancelled', 'error'
    String? step,
    Map<String, dynamic>? data,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final stepStr = step != null ? ' | Step: $step' : '';
    final dataStr = data != null ? ' | Data: $data' : '';
    
    debugPrint('$_prefix [$timestamp] Workflow: $workflow - $event$stepStr$dataStr');
  }

  /// Log batch operations
  static void logBatchOperation({
    required String operation,
    required int totalItems,
    required int processedItems,
    required int successCount,
    required int errorCount,
    Duration? duration,
  }) {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final durationStr = duration != null ? ' | Duration: ${duration.inMilliseconds}ms' : '';
    
    debugPrint('$_prefix [$timestamp] Batch $operation completed:');
    debugPrint('  Total: $totalItems');
    debugPrint('  Processed: $processedItems');
    debugPrint('  Success: $successCount');
    debugPrint('  Errors: $errorCount');
    debugPrint('  Success Rate: ${(successCount / totalItems * 100).toStringAsFixed(1)}%$durationStr');
  }

  /// Create a debug session for tracking related operations
  static DebugSession createSession(String sessionName) {
    return DebugSession(sessionName);
  }
}

/// Debug session for tracking related operations
class DebugSession {
  final String sessionName;
  final DateTime startTime;
  final List<String> _events = [];

  DebugSession(this.sessionName) : startTime = DateTime.now() {
    if (kDebugMode) {
      debugPrint('🔧 [DEBUG-SESSION] Started: $sessionName at ${startTime.toIso8601String()}');
    }
  }

  void addEvent(String event) {
    if (!kDebugMode) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final eventLog = '[$timestamp] $event';
    _events.add(eventLog);
    debugPrint('🔧 [DEBUG-SESSION] $sessionName: $event');
  }

  void complete([String? result]) {
    if (!kDebugMode) return;
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    final resultStr = result != null ? ' | Result: $result' : '';
    
    debugPrint('🔧 [DEBUG-SESSION] Completed: $sessionName');
    debugPrint('  Duration: ${duration.inMilliseconds}ms');
    debugPrint('  Events: ${_events.length}$resultStr');
    
    if (_events.isNotEmpty) {
      debugPrint('  Event Timeline:');
      for (final event in _events) {
        debugPrint('    $event');
      }
    }
  }
}
