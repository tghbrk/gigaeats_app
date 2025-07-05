import 'dart:async';

/// Base exception class for all menu-related errors
abstract class MenuException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const MenuException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'MenuException: $message';
}

/// Exception thrown when a menu item or related resource is not found
class MenuNotFoundException extends MenuException {
  const MenuNotFoundException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'MenuNotFoundException: $message';
}

/// Exception thrown when user lacks permission for menu operations
class MenuUnauthorizedException extends MenuException {
  const MenuUnauthorizedException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'MenuUnauthorizedException: $message';
}

/// Exception thrown when menu data validation fails
class MenuValidationException extends MenuException {
  final Map<String, String>? fieldErrors;

  const MenuValidationException(
    super.message, {
    super.code,
    this.fieldErrors,
    super.originalError,
  });

  @override
  String toString() {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      final errors = fieldErrors!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      return 'MenuValidationException: $message. Field errors: $errors';
    }
    return 'MenuValidationException: $message';
  }
}

/// Exception thrown when menu repository operations fail
class MenuRepositoryException extends MenuException {
  const MenuRepositoryException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'MenuRepositoryException: $message';
}

/// Exception thrown when pricing calculations fail
class PricingCalculationException extends MenuException {
  const PricingCalculationException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'PricingCalculationException: $message';
}

/// Exception thrown when customization operations fail
class CustomizationException extends MenuException {
  const CustomizationException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'CustomizationException: $message';
}

/// Exception thrown when menu organization operations fail
class MenuOrganizationException extends MenuException {
  const MenuOrganizationException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'MenuOrganizationException: $message';
}

/// Exception thrown when analytics operations fail
class MenuAnalyticsException extends MenuException {
  const MenuAnalyticsException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'MenuAnalyticsException: $message';
}

/// Exception thrown when file upload operations fail
class MenuFileUploadException extends MenuException {
  const MenuFileUploadException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'MenuFileUploadException: $message';
}

/// Exception thrown when real-time operations fail
class MenuRealtimeException extends MenuException {
  const MenuRealtimeException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'MenuRealtimeException: $message';
}

/// Utility class for creating menu exceptions from various error types
class MenuExceptionFactory {
  /// Create appropriate menu exception from a generic error
  static MenuException fromError(dynamic error, {String? context}) {
    if (error is MenuException) {
      return error;
    }

    final contextMessage = context != null ? '$context: ' : '';

    if (error is FormatException) {
      return MenuValidationException('${contextMessage}Invalid data format: ${error.message}');
    }

    if (error is ArgumentError) {
      return MenuValidationException('${contextMessage}Invalid argument: ${error.message}');
    }

    if (error is StateError) {
      return MenuRepositoryException('${contextMessage}Invalid state: ${error.message}');
    }

    if (error is TimeoutException) {
      return MenuRepositoryException('${contextMessage}Operation timed out');
    }

    // Generic error
    return MenuRepositoryException('$contextMessage${error.toString()}');
  }

  /// Create validation exception with field errors
  static MenuValidationException validationError(
    String message,
    Map<String, String> fieldErrors,
  ) {
    return MenuValidationException(
      message,
      fieldErrors: fieldErrors,
    );
  }

  /// Create not found exception for specific resource
  static MenuNotFoundException notFound(String resourceType, String identifier) {
    return MenuNotFoundException('$resourceType not found: $identifier');
  }

  /// Create unauthorized exception for specific operation
  static MenuUnauthorizedException unauthorized(String operation) {
    return MenuUnauthorizedException('Unauthorized to perform operation: $operation');
  }

  /// Create pricing calculation exception
  static PricingCalculationException pricingError(String details) {
    return PricingCalculationException('Pricing calculation failed: $details');
  }

  /// Create customization exception
  static CustomizationException customizationError(String details) {
    return CustomizationException('Customization operation failed: $details');
  }

  /// Create organization exception
  static MenuOrganizationException organizationError(String details) {
    return MenuOrganizationException('Menu organization operation failed: $details');
  }

  /// Create analytics exception
  static MenuAnalyticsException analyticsError(String details) {
    return MenuAnalyticsException('Analytics operation failed: $details');
  }
}

/// Extension methods for handling menu exceptions
extension MenuExceptionHandling on MenuException {
  /// Get user-friendly error message
  String get userFriendlyMessage {
    switch (runtimeType) {
      case MenuNotFoundException _:
        return 'The requested item could not be found.';
      case MenuUnauthorizedException _:
        return 'You do not have permission to perform this action.';
      case MenuValidationException _:
        return 'Please check your input and try again.';
      case PricingCalculationException _:
        return 'There was an error calculating the price. Please try again.';
      case CustomizationException _:
        return 'There was an error with the customization options.';
      case MenuOrganizationException _:
        return 'There was an error organizing the menu.';
      case MenuAnalyticsException _:
        return 'There was an error loading analytics data.';
      case MenuFileUploadException _:
        return 'There was an error uploading the file.';
      case MenuRealtimeException _:
        return 'There was an error with real-time updates.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Check if this is a recoverable error
  bool get isRecoverable {
    switch (runtimeType) {
      case MenuNotFoundException _:
      case MenuUnauthorizedException _:
        return false;
      case MenuValidationException _:
      case PricingCalculationException _:
      case CustomizationException _:
      case MenuOrganizationException _:
      case MenuAnalyticsException _:
      case MenuFileUploadException _:
      case MenuRealtimeException _:
      case MenuRepositoryException _:
        return true;
      default:
        return false;
    }
  }

  /// Get error severity level
  String get severity {
    switch (runtimeType) {
      case MenuNotFoundException _:
      case MenuUnauthorizedException _:
        return 'error';
      case MenuValidationException _:
        return 'warning';
      case PricingCalculationException _:
      case CustomizationException _:
      case MenuOrganizationException _:
      case MenuAnalyticsException _:
      case MenuFileUploadException _:
      case MenuRealtimeException _:
      case MenuRepositoryException _:
        return 'error';
      default:
        return 'error';
    }
  }
}
