import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../drivers/data/models/driver_order.dart';
import '../../../orders/data/models/driver_order_state_machine.dart';

/// Comprehensive error handling service for driver workflow operations
/// Provides network failure recovery, validation, and user-friendly error messages
class DriverWorkflowErrorHandler {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Connectivity _connectivity = Connectivity();

  /// Handle workflow operation with comprehensive error handling and retry logic
  Future<WorkflowOperationResult<T>> handleWorkflowOperation<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    bool requiresNetwork = true,
  }) async {
    try {
      debugPrint('🔄 [WORKFLOW-ERROR-HANDLER] Starting operation: $operationName');

      // Check network connectivity if required
      if (requiresNetwork) {
        final networkResult = await _checkNetworkConnectivity();
        if (!networkResult.isSuccess) {
          return WorkflowOperationResult.failure(
            WorkflowError.networkError(networkResult.error?.message ?? 'Network error'),
          );
        }
      }

      // Attempt operation with retry logic
      return await _executeWithRetry(
        operation: operation,
        operationName: operationName,
        maxRetries: maxRetries,
        retryDelay: retryDelay,
      );

    } catch (e) {
      debugPrint('❌ [WORKFLOW-ERROR-HANDLER] Unexpected error in $operationName: $e');
      return WorkflowOperationResult.failure(
        WorkflowError.unexpectedError(e.toString()),
      );
    }
  }

  /// Execute operation with retry logic
  Future<WorkflowOperationResult<T>> _executeWithRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    required int maxRetries,
    required Duration retryDelay,
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      attempts++;
      
      try {
        debugPrint('🔄 [WORKFLOW-ERROR-HANDLER] Attempt $attempts/$maxRetries for $operationName');
        
        final result = await operation();
        debugPrint('✅ [WORKFLOW-ERROR-HANDLER] Operation $operationName succeeded on attempt $attempts');
        
        return WorkflowOperationResult.success(result);

      } on PostgrestException catch (e) {
        lastException = e;
        final error = _handleSupabaseError(e, operationName);
        
        // Don't retry for certain types of errors
        if (!_shouldRetryError(error)) {
          return WorkflowOperationResult.failure(error);
        }

      } on AuthException catch (e) {
        lastException = e;
        final error = _handleAuthError(e, operationName);
        return WorkflowOperationResult.failure(error); // Don't retry auth errors

      } on StorageException catch (e) {
        lastException = e;
        final error = _handleStorageError(e, operationName);
        
        if (!_shouldRetryError(error)) {
          return WorkflowOperationResult.failure(error);
        }

      } catch (e) {
        lastException = Exception(e.toString());
        debugPrint('❌ [WORKFLOW-ERROR-HANDLER] Unexpected error on attempt $attempts: $e');
      }

      // Wait before retry (except on last attempt)
      if (attempts < maxRetries) {
        debugPrint('⏳ [WORKFLOW-ERROR-HANDLER] Waiting ${retryDelay.inSeconds}s before retry...');
        await Future.delayed(retryDelay);
      }
    }

    // All retries exhausted
    debugPrint('❌ [WORKFLOW-ERROR-HANDLER] All retries exhausted for $operationName');
    return WorkflowOperationResult.failure(
      WorkflowError.retryExhausted(
        'Operation failed after $maxRetries attempts: ${lastException?.toString() ?? 'Unknown error'}',
      ),
    );
  }

  /// Check network connectivity
  Future<WorkflowOperationResult<bool>> _checkNetworkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      
      if (connectivityResult.contains(ConnectivityResult.none) || connectivityResult.isEmpty) {
        return WorkflowOperationResult.failure(
          WorkflowError.networkError('No internet connection available'),
        );
      }

      // Test actual connectivity with a simple Supabase query
      await _supabase.from('drivers').select('id').limit(1);
      
      return WorkflowOperationResult.success(true);

    } catch (e) {
      return WorkflowOperationResult.failure(
        WorkflowError.networkError('Network connectivity test failed: $e'),
      );
    }
  }

  /// Handle Supabase PostgrestException
  WorkflowError _handleSupabaseError(PostgrestException e, String operationName) {
    debugPrint('❌ [WORKFLOW-ERROR-HANDLER] Supabase error in $operationName: ${e.message}');

    switch (e.code) {
      case '23505': // Unique constraint violation
        return WorkflowError.validationError('This action has already been completed');
      case '23503': // Foreign key constraint violation
        return WorkflowError.validationError('Invalid order or driver reference');
      case '42501': // Insufficient privilege
        return WorkflowError.permissionError('You do not have permission to perform this action');
      case 'PGRST116': // No rows found
        return WorkflowError.notFoundError('Order or data not found');
      default:
        if (e.message.contains('timeout') || e.message.contains('connection')) {
          return WorkflowError.networkError('Connection timeout. Please try again.');
        }
        return WorkflowError.databaseError('Database error: ${e.message}');
    }
  }

  /// Handle Supabase AuthException
  WorkflowError _handleAuthError(AuthException e, String operationName) {
    debugPrint('❌ [WORKFLOW-ERROR-HANDLER] Auth error in $operationName: ${e.message}');

    if (e.message.contains('JWT expired') || e.message.contains('token')) {
      return WorkflowError.authError('Your session has expired. Please log in again.');
    }
    
    return WorkflowError.authError('Authentication error: ${e.message}');
  }

  /// Handle Supabase StorageException
  WorkflowError _handleStorageError(StorageException e, String operationName) {
    debugPrint('❌ [WORKFLOW-ERROR-HANDLER] Storage error in $operationName: ${e.message}');

    if (e.message.contains('size') || e.message.contains('limit')) {
      return WorkflowError.validationError('File size too large. Please use a smaller image.');
    }
    
    if (e.message.contains('format') || e.message.contains('type')) {
      return WorkflowError.validationError('Invalid file format. Please use a JPEG image.');
    }

    return WorkflowError.storageError('File upload error: ${e.message}');
  }

  /// Determine if an error should be retried
  bool _shouldRetryError(WorkflowError error) {
    switch (error.type) {
      case WorkflowErrorType.network:
      case WorkflowErrorType.database:
      case WorkflowErrorType.storage:
        return true;
      case WorkflowErrorType.validation:
      case WorkflowErrorType.permission:
      case WorkflowErrorType.auth:
      case WorkflowErrorType.notFound:
        return false;
      case WorkflowErrorType.retryExhausted:
      case WorkflowErrorType.unexpected:
        return false;
    }
  }

  /// Validate order status transition
  static ValidationResult validateStatusTransition({
    required DriverOrderStatus fromStatus,
    required DriverOrderStatus toStatus,
    required DriverOrder order,
  }) {
    // Use state machine validation
    final stateValidation = DriverOrderStateMachine.validateTransition(fromStatus, toStatus);
    if (!stateValidation.isValid) {
      return ValidationResult.invalid(stateValidation.errorMessage!);
    }

    // Additional business logic validation
    if (toStatus == DriverOrderStatus.pickedUp) {
      // Validate pickup requirements
      if (!_hasValidPickupLocation(order)) {
        return ValidationResult.invalid('Invalid pickup location. Please ensure you are at the restaurant.');
      }
    }

    if (toStatus == DriverOrderStatus.delivered) {
      // Validate delivery requirements
      if (!_hasValidDeliveryLocation(order)) {
        return ValidationResult.invalid('Invalid delivery location. Please ensure you are at the customer location.');
      }
    }

    return ValidationResult.valid();
  }

  /// Validate pickup confirmation data
  static ValidationResult validatePickupConfirmation(Map<String, dynamic> confirmationData) {
    final errors = <String>[];

    // Check required fields
    if (confirmationData['order_id'] == null || confirmationData['order_id'].toString().isEmpty) {
      errors.add('Order ID is required');
    }

    if (confirmationData['verification_checklist'] == null) {
      errors.add('Verification checklist is required');
    } else {
      final checklist = confirmationData['verification_checklist'] as Map<String, dynamic>?;
      if (checklist == null || checklist.isEmpty) {
        errors.add('Verification checklist cannot be empty');
      } else {
        // Check that at least 80% of items are verified
        final totalItems = checklist.length;
        final verifiedItems = checklist.values.where((v) => v == true).length;
        if (totalItems > 0 && (verifiedItems / totalItems) < 0.8) {
          errors.add('At least 80% of verification items must be completed');
        }
      }
    }

    return errors.isEmpty 
        ? ValidationResult.valid() 
        : ValidationResult.invalid(errors.join(', '));
  }

  /// Validate delivery confirmation data
  static ValidationResult validateDeliveryConfirmation(Map<String, dynamic> confirmationData) {
    final errors = <String>[];

    // Check required fields
    if (confirmationData['order_id'] == null || confirmationData['order_id'].toString().isEmpty) {
      errors.add('Order ID is required');
    }

    if (confirmationData['photo_url'] == null || confirmationData['photo_url'].toString().isEmpty) {
      errors.add('Delivery photo is required');
    }

    if (confirmationData['latitude'] == null || confirmationData['longitude'] == null) {
      errors.add('GPS location is required');
    } else {
      final lat = confirmationData['latitude'] as double?;
      final lng = confirmationData['longitude'] as double?;
      
      if (lat == null || lng == null || lat == 0.0 || lng == 0.0) {
        errors.add('Valid GPS coordinates are required');
      }

      // Check location accuracy if provided
      final accuracy = confirmationData['location_accuracy'] as double?;
      if (accuracy != null && accuracy > 100) {
        errors.add('GPS accuracy is too low (${accuracy.toStringAsFixed(1)}m). Please try again.');
      }
    }

    return errors.isEmpty 
        ? ValidationResult.valid() 
        : ValidationResult.invalid(errors.join(', '));
  }

  // Helper methods for location validation
  static bool _hasValidPickupLocation(DriverOrder order) {
    // TODO: Implement actual location validation logic
    // This would check if driver is within reasonable distance of vendor
    return true;
  }

  static bool _hasValidDeliveryLocation(DriverOrder order) {
    // TODO: Implement actual location validation logic
    // This would check if driver is within reasonable distance of customer
    return true;
  }
}

/// Result of workflow operations with comprehensive error handling
class WorkflowOperationResult<T> {
  final bool isSuccess;
  final T? data;
  final WorkflowError? error;

  const WorkflowOperationResult._(this.isSuccess, this.data, this.error);

  factory WorkflowOperationResult.success(T data) => 
      WorkflowOperationResult._(true, data, null);

  factory WorkflowOperationResult.failure(WorkflowError error) => 
      WorkflowOperationResult._(false, null, error);
}

/// Comprehensive workflow error with type and user-friendly messages
class WorkflowError {
  final WorkflowErrorType type;
  final String message;
  final String? technicalDetails;

  const WorkflowError._(this.type, this.message, this.technicalDetails);

  factory WorkflowError.networkError(String message) => 
      WorkflowError._(WorkflowErrorType.network, 'Network connection issue. Please check your internet connection and try again.', message);

  factory WorkflowError.validationError(String message) => 
      WorkflowError._(WorkflowErrorType.validation, message, null);

  factory WorkflowError.permissionError(String message) => 
      WorkflowError._(WorkflowErrorType.permission, message, null);

  factory WorkflowError.authError(String message) => 
      WorkflowError._(WorkflowErrorType.auth, message, null);

  factory WorkflowError.databaseError(String message) => 
      WorkflowError._(WorkflowErrorType.database, 'Database operation failed. Please try again.', message);

  factory WorkflowError.storageError(String message) => 
      WorkflowError._(WorkflowErrorType.storage, 'File operation failed. Please try again.', message);

  factory WorkflowError.notFoundError(String message) => 
      WorkflowError._(WorkflowErrorType.notFound, message, null);

  factory WorkflowError.retryExhausted(String message) => 
      WorkflowError._(WorkflowErrorType.retryExhausted, 'Operation failed after multiple attempts. Please try again later.', message);

  factory WorkflowError.unexpectedError(String message) => 
      WorkflowError._(WorkflowErrorType.unexpected, 'An unexpected error occurred. Please try again.', message);
}

/// Types of workflow errors
enum WorkflowErrorType {
  network,
  validation,
  permission,
  auth,
  database,
  storage,
  notFound,
  retryExhausted,
  unexpected,
}

/// Validation result for workflow operations
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._(this.isValid, this.errorMessage);

  factory ValidationResult.valid() => const ValidationResult._(true, null);
  factory ValidationResult.invalid(String message) => ValidationResult._(false, message);
}
