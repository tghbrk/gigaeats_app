import 'package:flutter/foundation.dart';

import '../models/driver_order.dart';
import '../../../../core/utils/driver_workflow_logger.dart';

/// Enhanced status converter with comprehensive enum conversion and validation
/// Handles conversion between frontend camelCase and database snake_case formats
class EnhancedStatusConverter {
  
  /// Convert database snake_case status to frontend DriverOrderStatus enum
  static DriverOrderStatus fromDatabaseString(String databaseValue) {
    final normalizedValue = databaseValue.toLowerCase().trim();
    
    DriverWorkflowLogger.logValidation(
      validationType: 'Status Conversion',
      isValid: true,
      context: 'CONVERTER',
      reason: 'Converting database value: $databaseValue',
    );

    switch (normalizedValue) {
      // Standard granular workflow statuses
      case 'assigned':
        return DriverOrderStatus.assigned;
      case 'on_route_to_vendor':
        return DriverOrderStatus.onRouteToVendor;
      case 'arrived_at_vendor':
        return DriverOrderStatus.arrivedAtVendor;
      case 'picked_up':
        return DriverOrderStatus.pickedUp;
      case 'on_route_to_customer':
        return DriverOrderStatus.onRouteToCustomer;
      case 'arrived_at_customer':
        return DriverOrderStatus.arrivedAtCustomer;
      case 'delivered':
        return DriverOrderStatus.delivered;
      case 'cancelled':
        return DriverOrderStatus.cancelled;
      case 'failed':
        return DriverOrderStatus.failed;

      // Legacy status mappings (CORRECTED)
      case 'out_for_delivery':
        DriverWorkflowLogger.logValidation(
          validationType: 'Legacy Status Mapping',
          isValid: true,
          context: 'CONVERTER',
          reason: 'Mapping out_for_delivery to onRouteToCustomer (corrected)',
        );
        return DriverOrderStatus.onRouteToCustomer; // FIXED: Correct mapping

      case 'en_route':
        DriverWorkflowLogger.logValidation(
          validationType: 'Legacy Status Mapping',
          isValid: true,
          context: 'CONVERTER',
          reason: 'Mapping en_route to onRouteToCustomer',
        );
        return DriverOrderStatus.onRouteToCustomer;

      // Additional legacy support
      case 'ready':
        DriverWorkflowLogger.logValidation(
          validationType: 'Legacy Status Mapping',
          isValid: true,
          context: 'CONVERTER',
          reason: 'Mapping ready to assigned (order acceptance)',
        );
        return DriverOrderStatus.assigned;

      case 'preparing':
        DriverWorkflowLogger.logValidation(
          validationType: 'Legacy Status Mapping',
          isValid: true,
          context: 'CONVERTER',
          reason: 'Mapping preparing to assigned (vendor preparation)',
        );
        return DriverOrderStatus.assigned;

      // Handle camelCase variants (in case of frontend-to-frontend conversion)
      case 'onroutetovendor':
        return DriverOrderStatus.onRouteToVendor;
      case 'arrivedatvendor':
        return DriverOrderStatus.arrivedAtVendor;
      case 'pickedup':
        return DriverOrderStatus.pickedUp;
      case 'onroutetocustomer':
        return DriverOrderStatus.onRouteToCustomer;
      case 'arrivedatcustomer':
        return DriverOrderStatus.arrivedAtCustomer;

      default:
        DriverWorkflowLogger.logError(
          operation: 'Status Conversion',
          error: 'Unknown status value: $databaseValue',
          context: 'CONVERTER',
        );
        throw ArgumentError('Invalid driver order status: $databaseValue');
    }
  }

  /// Convert frontend DriverOrderStatus enum to database snake_case string
  static String toDatabaseString(DriverOrderStatus status) {
    DriverWorkflowLogger.logValidation(
      validationType: 'Status Conversion',
      isValid: true,
      context: 'CONVERTER',
      reason: 'Converting frontend status: ${status.name} to database format',
    );

    switch (status) {
      case DriverOrderStatus.assigned:
        return 'assigned';
      case DriverOrderStatus.onRouteToVendor:
        return 'on_route_to_vendor';
      case DriverOrderStatus.arrivedAtVendor:
        return 'arrived_at_vendor';
      case DriverOrderStatus.pickedUp:
        return 'picked_up';
      case DriverOrderStatus.onRouteToCustomer:
        return 'on_route_to_customer';
      case DriverOrderStatus.arrivedAtCustomer:
        return 'arrived_at_customer';
      case DriverOrderStatus.delivered:
        return 'delivered';
      case DriverOrderStatus.cancelled:
        return 'cancelled';
      case DriverOrderStatus.failed:
        return 'failed';
    }
  }

  /// Validate if a status string is a valid database enum value
  static bool isValidDatabaseStatus(String status) {
    try {
      fromDatabaseString(status);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all valid database status values
  static List<String> getAllValidDatabaseStatuses() {
    return [
      'assigned',
      'on_route_to_vendor',
      'arrived_at_vendor',
      'picked_up',
      'on_route_to_customer',
      'arrived_at_customer',
      'delivered',
      'cancelled',
      'failed',
    ];
  }

  /// Get all valid frontend status values
  static List<DriverOrderStatus> getAllValidFrontendStatuses() {
    return DriverOrderStatus.values;
  }

  /// Convert status with validation and error handling
  static ConversionResult<DriverOrderStatus> safeFromDatabaseString(String databaseValue) {
    try {
      final status = fromDatabaseString(databaseValue);
      return ConversionResult.success(status);
    } catch (e) {
      DriverWorkflowLogger.logError(
        operation: 'Safe Status Conversion',
        error: e.toString(),
        context: 'CONVERTER',
      );
      return ConversionResult.failure('Failed to convert status: $databaseValue - ${e.toString()}');
    }
  }

  /// Convert status with validation and error handling
  static ConversionResult<String> safeToDatabaseString(DriverOrderStatus status) {
    try {
      final databaseValue = toDatabaseString(status);
      return ConversionResult.success(databaseValue);
    } catch (e) {
      DriverWorkflowLogger.logError(
        operation: 'Safe Status Conversion',
        error: e.toString(),
        context: 'CONVERTER',
      );
      return ConversionResult.failure('Failed to convert status: ${status.name} - ${e.toString()}');
    }
  }

  /// Get status progression information
  static StatusProgressionInfo getProgressionInfo(DriverOrderStatus status) {
    final allStatuses = [
      DriverOrderStatus.assigned,
      DriverOrderStatus.onRouteToVendor,
      DriverOrderStatus.arrivedAtVendor,
      DriverOrderStatus.pickedUp,
      DriverOrderStatus.onRouteToCustomer,
      DriverOrderStatus.arrivedAtCustomer,
      DriverOrderStatus.delivered,
    ];

    final currentIndex = allStatuses.indexOf(status);
    if (currentIndex == -1) {
      // Handle terminal states
      return StatusProgressionInfo(
        currentStep: 0,
        totalSteps: 7,
        progressPercentage: status == DriverOrderStatus.delivered ? 100.0 : 0.0,
        isTerminal: true,
      );
    }

    return StatusProgressionInfo(
      currentStep: currentIndex + 1,
      totalSteps: 7,
      progressPercentage: ((currentIndex + 1) / 7) * 100,
      isTerminal: status == DriverOrderStatus.delivered,
    );
  }

  /// Check if status requires mandatory confirmation
  static bool requiresMandatoryConfirmation(DriverOrderStatus status) {
    switch (status) {
      case DriverOrderStatus.pickedUp:
        return true; // Pickup confirmation required
      case DriverOrderStatus.delivered:
        return true; // Delivery photo proof required
      default:
        return false;
    }
  }

  /// Get user-friendly status description
  static String getStatusDescription(DriverOrderStatus status) {
    switch (status) {
      case DriverOrderStatus.assigned:
        return 'Order has been assigned to you. Start navigation to the restaurant.';
      case DriverOrderStatus.onRouteToVendor:
        return 'You are on your way to the restaurant to pick up the order.';
      case DriverOrderStatus.arrivedAtVendor:
        return 'You have arrived at the restaurant. Confirm pickup when ready.';
      case DriverOrderStatus.pickedUp:
        return 'Order has been picked up. Start navigation to the customer.';
      case DriverOrderStatus.onRouteToCustomer:
        return 'You are on your way to deliver the order to the customer.';
      case DriverOrderStatus.arrivedAtCustomer:
        return 'You have arrived at the customer location. Complete the delivery.';
      case DriverOrderStatus.delivered:
        return 'Order has been successfully delivered to the customer.';
      case DriverOrderStatus.cancelled:
        return 'This order has been cancelled.';
      case DriverOrderStatus.failed:
        return 'This order has failed and requires attention.';
    }
  }

  /// Debug method to log conversion mapping
  static void logConversionMapping() {
    if (kDebugMode) {
      debugPrint('=== Enhanced Status Converter Mapping ===');
      for (final status in DriverOrderStatus.values) {
        final databaseValue = toDatabaseString(status);
        final backConverted = fromDatabaseString(databaseValue);
        final isConsistent = backConverted == status;
        debugPrint('${status.name} ↔ $databaseValue (Consistent: $isConsistent)');
      }
      debugPrint('==========================================');
    }
  }
}

/// Result class for safe conversion operations
class ConversionResult<T> {
  final bool isSuccess;
  final T? value;
  final String? error;

  ConversionResult._(this.isSuccess, this.value, this.error);

  factory ConversionResult.success(T value) => ConversionResult._(true, value, null);
  factory ConversionResult.failure(String error) => ConversionResult._(false, null, error);
}

/// Status progression information
class StatusProgressionInfo {
  final int currentStep;
  final int totalSteps;
  final double progressPercentage;
  final bool isTerminal;

  StatusProgressionInfo({
    required this.currentStep,
    required this.totalSteps,
    required this.progressPercentage,
    required this.isTerminal,
  });
}
