/// Error types for driver-related operations
enum DriverErrorType {
  authentication,
  driverNotFound,
  orderNotFound,
  invalidStatus,
  networkError,
  permissionDenied,
  validationError,
  orderAcceptance,
  statusUpdate,
  orderCancellation,
  dataFetch,
  unknown,
}

/// Custom exception class for driver-related errors
class DriverException implements Exception {
  final String message;
  final DriverErrorType type;
  final dynamic originalError;

  const DriverException(
    this.message,
    this.type, [
    this.originalError,
  ]);

  @override
  String toString() {
    return 'DriverException: $message (Type: ${type.name})';
  }

  /// Get user-friendly error message
  String get userFriendlyMessage {
    switch (type) {
      case DriverErrorType.authentication:
        return 'Please log in to continue';
      case DriverErrorType.driverNotFound:
        return 'Driver profile not found. Please contact support.';
      case DriverErrorType.orderNotFound:
        return 'Order not found or no longer available';
      case DriverErrorType.invalidStatus:
        return 'Invalid order status transition';
      case DriverErrorType.networkError:
        return 'Network error. Please check your connection and try again.';
      case DriverErrorType.permissionDenied:
        return 'You do not have permission to perform this action';
      case DriverErrorType.validationError:
        return 'Invalid data provided';
      case DriverErrorType.orderAcceptance:
        return 'Failed to accept order. Please try again.';
      case DriverErrorType.statusUpdate:
        return 'Failed to update order status. Please try again.';
      case DriverErrorType.orderCancellation:
        return 'Failed to cancel order. Please try again.';
      case DriverErrorType.dataFetch:
        return 'Failed to load data. Please refresh and try again.';
      case DriverErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Check if error should trigger a retry
  bool get shouldRetry {
    switch (type) {
      case DriverErrorType.networkError:
      case DriverErrorType.unknown:
        return true;
      default:
        return false;
    }
  }

  /// Create DriverException from generic exception
  static DriverException fromException(dynamic error) {
    if (error is DriverException) {
      return error;
    }

    final errorMessage = error.toString().toLowerCase();
    
    if (errorMessage.contains('network') || 
        errorMessage.contains('connection') ||
        errorMessage.contains('timeout')) {
      return DriverException(
        'Network error occurred',
        DriverErrorType.networkError,
        error,
      );
    }

    if (errorMessage.contains('permission') || 
        errorMessage.contains('unauthorized')) {
      return DriverException(
        'Permission denied',
        DriverErrorType.permissionDenied,
        error,
      );
    }

    if (errorMessage.contains('not found')) {
      return DriverException(
        'Resource not found',
        DriverErrorType.orderNotFound,
        error,
      );
    }

    return DriverException(
      error.toString(),
      DriverErrorType.unknown,
      error,
    );
  }
}

/// Result wrapper for driver operations
class DriverResult<T> {
  final T? data;
  final DriverException? error;
  final bool isSuccess;

  const DriverResult._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  /// Create successful result
  factory DriverResult.success(T data) {
    return DriverResult._(
      data: data,
      isSuccess: true,
    );
  }

  /// Create error result
  factory DriverResult.error(DriverException error) {
    return DriverResult._(
      error: error,
      isSuccess: false,
    );
  }

  /// Create error result from exception
  factory DriverResult.fromException(dynamic exception) {
    return DriverResult.error(DriverException.fromException(exception));
  }

  /// Get data or throw error
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data as T;
    }
    throw error ?? DriverException('Unknown error', DriverErrorType.unknown);
  }

  /// Map result to another type
  DriverResult<U> map<U>(U Function(T data) mapper) {
    if (isSuccess && data != null) {
      try {
        return DriverResult.success(mapper(data as T));
      } catch (e) {
        return DriverResult.fromException(e);
      }
    }
    return DriverResult.error(error!);
  }

  /// Handle result with callbacks
  R when<R>({
    required R Function(T data) success,
    required R Function(DriverException error) error,
  }) {
    if (isSuccess && data != null) {
      return success(data as T);
    }
    return error(this.error!);
  }
}
