import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/comprehensive_validation_service.dart';
import '../../../core/utils/logger.dart';
import '../../../../core/errors/error_handler.dart';

/// Enhanced error handling state
class EnhancedErrorHandlingState {
  final Map<String, List<String>> fieldErrors;
  final List<String> globalErrors;
  final List<String> warnings;
  final List<String> recommendations;
  final bool hasErrors;
  final bool hasWarnings;
  final DateTime lastUpdated;

  const EnhancedErrorHandlingState({
    this.fieldErrors = const {},
    this.globalErrors = const [],
    this.warnings = const [],
    this.recommendations = const [],
    this.hasErrors = false,
    this.hasWarnings = false,
    required this.lastUpdated,
  });

  EnhancedErrorHandlingState copyWith({
    Map<String, List<String>>? fieldErrors,
    List<String>? globalErrors,
    List<String>? warnings,
    List<String>? recommendations,
    bool? hasErrors,
    bool? hasWarnings,
    DateTime? lastUpdated,
  }) {
    return EnhancedErrorHandlingState(
      fieldErrors: fieldErrors ?? this.fieldErrors,
      globalErrors: globalErrors ?? this.globalErrors,
      warnings: warnings ?? this.warnings,
      recommendations: recommendations ?? this.recommendations,
      hasErrors: hasErrors ?? this.hasErrors,
      hasWarnings: hasWarnings ?? this.hasWarnings,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  List<String> getFieldErrors(String fieldName) {
    return fieldErrors[fieldName] ?? [];
  }

  bool hasFieldError(String fieldName) {
    return fieldErrors.containsKey(fieldName) && fieldErrors[fieldName]!.isNotEmpty;
  }

  String? getFirstFieldError(String fieldName) {
    final errors = getFieldErrors(fieldName);
    return errors.isNotEmpty ? errors.first : null;
  }

  List<String> get allErrors {
    final all = <String>[];
    all.addAll(globalErrors);
    for (final errors in fieldErrors.values) {
      all.addAll(errors);
    }
    return all;
  }
}

/// Enhanced error handling notifier
class EnhancedErrorHandlingNotifier extends StateNotifier<EnhancedErrorHandlingState> {
  final AppLogger _logger = AppLogger();

  EnhancedErrorHandlingNotifier() : super(EnhancedErrorHandlingState(lastUpdated: DateTime.now()));

  /// Add field-specific error
  void addFieldError(String fieldName, String error) {
    _logger.info('⚠️ [ERROR-HANDLING] Adding field error: $fieldName - $error');

    final updatedFieldErrors = Map<String, List<String>>.from(state.fieldErrors);
    updatedFieldErrors[fieldName] = [...(updatedFieldErrors[fieldName] ?? []), error];

    state = state.copyWith(
      fieldErrors: updatedFieldErrors,
      hasErrors: true,
    );
  }

  /// Set field errors (replaces existing)
  void setFieldErrors(String fieldName, List<String> errors) {
    _logger.info('⚠️ [ERROR-HANDLING] Setting field errors: $fieldName - ${errors.length} errors');

    final updatedFieldErrors = Map<String, List<String>>.from(state.fieldErrors);
    if (errors.isEmpty) {
      updatedFieldErrors.remove(fieldName);
    } else {
      updatedFieldErrors[fieldName] = errors;
    }

    final hasAnyErrors = updatedFieldErrors.values.any((errors) => errors.isNotEmpty) || 
                       state.globalErrors.isNotEmpty;

    state = state.copyWith(
      fieldErrors: updatedFieldErrors,
      hasErrors: hasAnyErrors,
    );
  }

  /// Clear field errors
  void clearFieldErrors(String fieldName) {
    _logger.info('🧹 [ERROR-HANDLING] Clearing field errors: $fieldName');

    final updatedFieldErrors = Map<String, List<String>>.from(state.fieldErrors);
    updatedFieldErrors.remove(fieldName);

    final hasAnyErrors = updatedFieldErrors.values.any((errors) => errors.isNotEmpty) || 
                       state.globalErrors.isNotEmpty;

    state = state.copyWith(
      fieldErrors: updatedFieldErrors,
      hasErrors: hasAnyErrors,
    );
  }

  /// Add global error
  void addGlobalError(String error) {
    _logger.info('⚠️ [ERROR-HANDLING] Adding global error: $error');

    final updatedGlobalErrors = [...state.globalErrors, error];

    state = state.copyWith(
      globalErrors: updatedGlobalErrors,
      hasErrors: true,
    );
  }

  /// Set global errors (replaces existing)
  void setGlobalErrors(List<String> errors) {
    _logger.info('⚠️ [ERROR-HANDLING] Setting global errors: ${errors.length} errors');

    final hasAnyErrors = errors.isNotEmpty || 
                       state.fieldErrors.values.any((fieldErrors) => fieldErrors.isNotEmpty);

    state = state.copyWith(
      globalErrors: errors,
      hasErrors: hasAnyErrors,
    );
  }

  /// Clear global errors
  void clearGlobalErrors() {
    _logger.info('🧹 [ERROR-HANDLING] Clearing global errors');

    final hasAnyErrors = state.fieldErrors.values.any((errors) => errors.isNotEmpty);

    state = state.copyWith(
      globalErrors: [],
      hasErrors: hasAnyErrors,
    );
  }

  /// Add warning
  void addWarning(String warning) {
    _logger.info('⚠️ [ERROR-HANDLING] Adding warning: $warning');

    final updatedWarnings = [...state.warnings, warning];

    state = state.copyWith(
      warnings: updatedWarnings,
      hasWarnings: true,
    );
  }

  /// Set warnings (replaces existing)
  void setWarnings(List<String> warnings) {
    _logger.info('⚠️ [ERROR-HANDLING] Setting warnings: ${warnings.length} warnings');

    state = state.copyWith(
      warnings: warnings,
      hasWarnings: warnings.isNotEmpty,
    );
  }

  /// Clear warnings
  void clearWarnings() {
    _logger.info('🧹 [ERROR-HANDLING] Clearing warnings');

    state = state.copyWith(
      warnings: [],
      hasWarnings: false,
    );
  }

  /// Set recommendations
  void setRecommendations(List<String> recommendations) {
    _logger.info('💡 [ERROR-HANDLING] Setting recommendations: ${recommendations.length} recommendations');

    state = state.copyWith(recommendations: recommendations);
  }

  /// Clear recommendations
  void clearRecommendations() {
    _logger.info('🧹 [ERROR-HANDLING] Clearing recommendations');

    state = state.copyWith(recommendations: []);
  }

  /// Handle validation result
  void handleValidationResult(WorkflowValidationResult validationResult) {
    _logger.info('📋 [ERROR-HANDLING] Handling validation result: ${validationResult.isValid}');

    // Clear existing errors and warnings
    clearAll();

    // Set global errors
    if (validationResult.errors.isNotEmpty) {
      setGlobalErrors(validationResult.errors);
    }

    // Set warnings
    if (validationResult.warnings.isNotEmpty) {
      setWarnings(validationResult.warnings);
    }

    // Set recommendations
    if (validationResult.recommendations.isNotEmpty) {
      setRecommendations(validationResult.recommendations);
    }

    // Set field-specific errors based on validation type
    for (final result in validationResult.validationResults) {
      if (!result.isValid) {
        final fieldName = _getFieldNameFromValidationType(result.type);
        setFieldErrors(fieldName, result.errors);
      }
    }
  }

  /// Handle exception with user-friendly message
  void handleException(Object exception, [StackTrace? stackTrace]) {
    _logger.error('❌ [ERROR-HANDLING] Handling exception', exception, stackTrace);

    final failure = ErrorHandler.handleException(exception, stackTrace);
    final userFriendlyMessage = ErrorHandler.getErrorMessage(failure);

    addGlobalError(userFriendlyMessage);
  }

  /// Clear all errors, warnings, and recommendations
  void clearAll() {
    _logger.info('🧹 [ERROR-HANDLING] Clearing all errors and warnings');

    state = EnhancedErrorHandlingState(lastUpdated: DateTime.now());
  }

  /// Validate field input in real-time
  void validateField(String fieldName, String? value, String? Function(String?) validator) {
    final error = validator(value);
    if (error != null) {
      setFieldErrors(fieldName, [error]);
    } else {
      clearFieldErrors(fieldName);
    }
  }

  /// Get field name from validation type
  String _getFieldNameFromValidationType(ValidationType type) {
    switch (type) {
      case ValidationType.cart:
        return 'cart';
      case ValidationType.delivery:
        return 'delivery';
      case ValidationType.schedule:
        return 'schedule';
      case ValidationType.payment:
        return 'payment';
      case ValidationType.form:
        return 'form';
      case ValidationType.business:
        return 'business';
    }
  }

  /// Get error summary for display
  ErrorSummary getErrorSummary() {
    return ErrorSummary(
      totalErrors: state.allErrors.length,
      totalWarnings: state.warnings.length,
      hasFieldErrors: state.fieldErrors.isNotEmpty,
      hasGlobalErrors: state.globalErrors.isNotEmpty,
      mostCriticalError: state.allErrors.isNotEmpty ? state.allErrors.first : null,
      errorsByType: _groupErrorsByType(),
    );
  }

  /// Group errors by type for analysis
  Map<String, List<String>> _groupErrorsByType() {
    final grouped = <String, List<String>>{};
    
    // Add global errors
    if (state.globalErrors.isNotEmpty) {
      grouped['global'] = state.globalErrors;
    }

    // Add field errors
    for (final entry in state.fieldErrors.entries) {
      if (entry.value.isNotEmpty) {
        grouped[entry.key] = entry.value;
      }
    }

    return grouped;
  }

  /// Check if form is valid for submission
  bool isFormValid() {
    return !state.hasErrors;
  }

  /// Get validation status message
  String? getValidationStatusMessage() {
    if (state.hasErrors) {
      final errorCount = state.allErrors.length;
      return 'Please fix $errorCount error${errorCount > 1 ? 's' : ''} before proceeding';
    }

    if (state.hasWarnings) {
      final warningCount = state.warnings.length;
      return '$warningCount warning${warningCount > 1 ? 's' : ''} detected';
    }

    return null;
  }
}

/// Error summary for display purposes
class ErrorSummary {
  final int totalErrors;
  final int totalWarnings;
  final bool hasFieldErrors;
  final bool hasGlobalErrors;
  final String? mostCriticalError;
  final Map<String, List<String>> errorsByType;

  const ErrorSummary({
    required this.totalErrors,
    required this.totalWarnings,
    required this.hasFieldErrors,
    required this.hasGlobalErrors,
    this.mostCriticalError,
    required this.errorsByType,
  });
}

/// Enhanced error handling provider
final enhancedErrorHandlingProvider = StateNotifierProvider<EnhancedErrorHandlingNotifier, EnhancedErrorHandlingState>((ref) {
  return EnhancedErrorHandlingNotifier();
});

/// Convenience providers
final hasErrorsProvider = Provider<bool>((ref) {
  return ref.watch(enhancedErrorHandlingProvider).hasErrors;
});

final hasWarningsProvider = Provider<bool>((ref) {
  return ref.watch(enhancedErrorHandlingProvider).hasWarnings;
});

final globalErrorsProvider = Provider<List<String>>((ref) {
  return ref.watch(enhancedErrorHandlingProvider).globalErrors;
});

final warningsProvider = Provider<List<String>>((ref) {
  return ref.watch(enhancedErrorHandlingProvider).warnings;
});

final recommendationsProvider = Provider<List<String>>((ref) {
  return ref.watch(enhancedErrorHandlingProvider).recommendations;
});

final errorSummaryProvider = Provider<ErrorSummary>((ref) {
  return ref.watch(enhancedErrorHandlingProvider.notifier).getErrorSummary();
});

final isFormValidProvider = Provider<bool>((ref) {
  return ref.watch(enhancedErrorHandlingProvider.notifier).isFormValid();
});

final validationStatusMessageProvider = Provider<String?>((ref) {
  return ref.watch(enhancedErrorHandlingProvider.notifier).getValidationStatusMessage();
});

/// Field error provider
final fieldErrorProvider = Provider.family<String?, String>((ref, fieldName) {
  return ref.watch(enhancedErrorHandlingProvider).getFirstFieldError(fieldName);
});

/// Field has error provider
final fieldHasErrorProvider = Provider.family<bool, String>((ref, fieldName) {
  return ref.watch(enhancedErrorHandlingProvider).hasFieldError(fieldName);
});
