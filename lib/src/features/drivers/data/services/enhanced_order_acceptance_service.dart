import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/driver_workflow_logger.dart';

/// Enhanced order acceptance service with comprehensive debugging and race condition handling
class EnhancedOrderAcceptanceService {
  final SupabaseClient _supabase;

  EnhancedOrderAcceptanceService(this._supabase);

  /// Accept an order with enhanced validation, logging, and race condition prevention
  Future<OrderAcceptanceResult> acceptOrder({
    required String orderId,
    required String userId,
  }) async {
    final startTime = DateTime.now();
    
    DriverWorkflowLogger.logDatabaseOperation(
      operation: 'ORDER_ACCEPTANCE_START',
      orderId: orderId,
      data: {'user_id': userId},
      context: 'SERVICE',
    );

    try {
      // Step 1: Validate driver availability and get driver ID
      final driverValidation = await _validateDriverAvailability(userId, orderId);
      if (!driverValidation.isValid) {
        return OrderAcceptanceResult.failure(driverValidation.error!);
      }

      final driverId = driverValidation.driverId!;

      // Step 2: Validate order availability
      final orderValidation = await _validateOrderAvailability(orderId);
      if (!orderValidation.isValid) {
        return OrderAcceptanceResult.failure(orderValidation.error!);
      }

      // Step 3: Perform atomic order assignment
      final assignmentResult = await _performAtomicOrderAssignment(
        orderId: orderId,
        driverId: driverId,
      );

      if (!assignmentResult.isSuccess) {
        return OrderAcceptanceResult.failure(assignmentResult.error!);
      }

      // Step 4: Update driver status
      await _updateDriverStatus(driverId, orderId);

      final duration = DateTime.now().difference(startTime);
      DriverWorkflowLogger.logPerformance(
        operation: 'Order Acceptance',
        duration: duration,
        orderId: orderId,
        context: 'SERVICE',
      );

      DriverWorkflowLogger.logStatusTransition(
        orderId: orderId,
        fromStatus: 'ready',
        toStatus: 'assigned',
        driverId: driverId,
        context: 'SERVICE',
      );

      return OrderAcceptanceResult.success(assignmentResult.orderData!);

    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      DriverWorkflowLogger.logError(
        operation: 'Order Acceptance',
        error: e.toString(),
        orderId: orderId,
        context: 'SERVICE',
      );
      DriverWorkflowLogger.logPerformance(
        operation: 'Order Acceptance (Failed)',
        duration: duration,
        orderId: orderId,
        context: 'SERVICE',
      );
      return OrderAcceptanceResult.failure('Failed to accept order: $e');
    }
  }

  /// Validate driver availability and return driver ID
  Future<DriverValidationResult> _validateDriverAvailability(String userId, String orderId) async {
    try {
      DriverWorkflowLogger.logDatabaseOperation(
        operation: 'DRIVER_VALIDATION',
        orderId: orderId,
        context: 'SERVICE',
      );

      final driverResponse = await _supabase
          .from('drivers')
          .select('id, is_active, status, current_delivery_status')
          .eq('user_id', userId)
          .single();

      final driverId = driverResponse['id'] as String;
      final isActive = driverResponse['is_active'] as bool;
      final currentStatus = driverResponse['status'] as String;
      final deliveryStatus = driverResponse['current_delivery_status'] as String?;

      DriverWorkflowLogger.logValidation(
        validationType: 'Driver Availability',
        isValid: isActive && currentStatus == 'online',
        orderId: orderId,
        context: 'SERVICE',
        reason: 'Active: $isActive, Status: $currentStatus, Delivery: $deliveryStatus',
      );

      if (!isActive) {
        return DriverValidationResult.invalid('Driver account is not active');
      }

      if (currentStatus == 'on_delivery' && deliveryStatus != null) {
        return DriverValidationResult.invalid('Driver is already on a delivery');
      }

      if (currentStatus != 'online') {
        return DriverValidationResult.invalid('Driver must be online to accept orders');
      }

      return DriverValidationResult.valid(driverId);

    } catch (e) {
      DriverWorkflowLogger.logError(
        operation: 'Driver Validation',
        error: e.toString(),
        orderId: orderId,
        context: 'SERVICE',
      );
      return DriverValidationResult.invalid('Failed to validate driver: $e');
    }
  }

  /// Validate order availability
  Future<OrderValidationResult> _validateOrderAvailability(String orderId) async {
    try {
      DriverWorkflowLogger.logDatabaseOperation(
        operation: 'ORDER_VALIDATION',
        orderId: orderId,
        context: 'SERVICE',
      );

      final orderResponse = await _supabase
          .from('orders')
          .select('id, status, assigned_driver_id, delivery_method')
          .eq('id', orderId)
          .single();

      final status = orderResponse['status'] as String;
      final assignedDriverId = orderResponse['assigned_driver_id'] as String?;
      final deliveryMethod = orderResponse['delivery_method'] as String;

      DriverWorkflowLogger.logValidation(
        validationType: 'Order Availability',
        isValid: status == 'ready' && assignedDriverId == null && deliveryMethod == 'own_fleet',
        orderId: orderId,
        context: 'SERVICE',
        reason: 'Status: $status, Assigned: $assignedDriverId, Method: $deliveryMethod',
      );

      if (status != 'ready') {
        return OrderValidationResult.invalid('Order is not ready for assignment (status: $status)');
      }

      if (assignedDriverId != null) {
        return OrderValidationResult.invalid('Order is already assigned to another driver');
      }

      if (deliveryMethod != 'own_fleet') {
        return OrderValidationResult.invalid('Order is not for own fleet delivery');
      }

      return OrderValidationResult.valid();

    } catch (e) {
      DriverWorkflowLogger.logError(
        operation: 'Order Validation',
        error: e.toString(),
        orderId: orderId,
        context: 'SERVICE',
      );
      return OrderValidationResult.invalid('Failed to validate order: $e');
    }
  }

  /// Perform atomic order assignment with race condition prevention
  Future<AssignmentResult> _performAtomicOrderAssignment({
    required String orderId,
    required String driverId,
  }) async {
    try {
      DriverWorkflowLogger.logDatabaseOperation(
        operation: 'ATOMIC_ORDER_ASSIGNMENT',
        orderId: orderId,
        data: {'driver_id': driverId},
        context: 'SERVICE',
      );

      // Use conditional update to prevent race conditions
      final updateResponse = await _supabase
          .from('orders')
          .update({
            'assigned_driver_id': driverId,
            'status': 'assigned',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .eq('status', 'ready') // Only update if still ready
          .isFilter('assigned_driver_id', null) // Only if no driver assigned
          .eq('delivery_method', 'own_fleet') // Additional safety check
          .select();

      if (updateResponse.isEmpty) {
        DriverWorkflowLogger.logError(
          operation: 'Atomic Order Assignment',
          error: 'Order assignment failed - may have been assigned to another driver',
          orderId: orderId,
          context: 'SERVICE',
        );
        return AssignmentResult.failure('Order may have already been assigned to another driver');
      }

      DriverWorkflowLogger.logDatabaseOperation(
        operation: 'ATOMIC_ORDER_ASSIGNMENT',
        orderId: orderId,
        isSuccess: true,
        data: updateResponse.first,
        context: 'SERVICE',
      );

      return AssignmentResult.success(updateResponse.first);

    } catch (e) {
      DriverWorkflowLogger.logError(
        operation: 'Atomic Order Assignment',
        error: e.toString(),
        orderId: orderId,
        context: 'SERVICE',
      );
      return AssignmentResult.failure('Database error during assignment: $e');
    }
  }

  /// Update driver status after successful order assignment
  Future<void> _updateDriverStatus(String driverId, String orderId) async {
    try {
      DriverWorkflowLogger.logDatabaseOperation(
        operation: 'DRIVER_STATUS_UPDATE',
        orderId: orderId,
        data: {
          'driver_id': driverId,
          'status': 'on_delivery',
          'current_delivery_status': 'assigned',
        },
        context: 'SERVICE',
      );

      await _supabase
          .from('drivers')
          .update({
            'status': 'on_delivery',
            'current_delivery_status': 'assigned',
            'last_seen': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      DriverWorkflowLogger.logDatabaseOperation(
        operation: 'DRIVER_STATUS_UPDATE',
        orderId: orderId,
        isSuccess: true,
        context: 'SERVICE',
      );

    } catch (e) {
      DriverWorkflowLogger.logError(
        operation: 'Driver Status Update',
        error: e.toString(),
        orderId: orderId,
        context: 'SERVICE',
      );
      // Don't throw here - order assignment was successful
      debugPrint('Warning: Driver status update failed but order was assigned: $e');
    }
  }
}

/// Result classes for type-safe error handling
class OrderAcceptanceResult {
  final bool isSuccess;
  final String? error;
  final Map<String, dynamic>? orderData;

  OrderAcceptanceResult._(this.isSuccess, this.error, this.orderData);

  factory OrderAcceptanceResult.success(Map<String, dynamic> orderData) =>
      OrderAcceptanceResult._(true, null, orderData);

  factory OrderAcceptanceResult.failure(String error) =>
      OrderAcceptanceResult._(false, error, null);
}

class DriverValidationResult {
  final bool isValid;
  final String? error;
  final String? driverId;

  DriverValidationResult._(this.isValid, this.error, this.driverId);

  factory DriverValidationResult.valid(String driverId) =>
      DriverValidationResult._(true, null, driverId);

  factory DriverValidationResult.invalid(String error) =>
      DriverValidationResult._(false, error, null);
}

class OrderValidationResult {
  final bool isValid;
  final String? error;

  OrderValidationResult._(this.isValid, this.error);

  factory OrderValidationResult.valid() =>
      OrderValidationResult._(true, null);

  factory OrderValidationResult.invalid(String error) =>
      OrderValidationResult._(false, error);
}

class AssignmentResult {
  final bool isSuccess;
  final String? error;
  final Map<String, dynamic>? orderData;

  AssignmentResult._(this.isSuccess, this.error, this.orderData);

  factory AssignmentResult.success(Map<String, dynamic> orderData) =>
      AssignmentResult._(true, null, orderData);

  factory AssignmentResult.failure(String error) =>
      AssignmentResult._(false, error, null);
}
