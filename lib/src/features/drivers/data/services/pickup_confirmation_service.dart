import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pickup_confirmation.dart';
import 'driver_workflow_error_handler.dart';
import 'network_failure_recovery_service.dart';
import '../validators/driver_workflow_validators.dart';

/// Enhanced service for handling pickup confirmations at vendor locations
/// Manages the mandatory pickup verification process with comprehensive error handling
class PickupConfirmationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DriverWorkflowErrorHandler _errorHandler = DriverWorkflowErrorHandler();
  final NetworkFailureRecoveryService _recoveryService = NetworkFailureRecoveryService();

  /// Submit pickup confirmation to the backend with enhanced error handling
  Future<PickupConfirmationResult> submitPickupConfirmation(
    PickupConfirmation confirmation,
  ) async {
    // Client-side validation
    final validationResult = DriverWorkflowValidators.validatePickupConfirmationData(
      verificationChecklist: confirmation.verificationChecklist,
      notes: confirmation.notes,
    );

    if (!validationResult.isValid) {
      return PickupConfirmationResult.failure(validationResult.errorMessage!);
    }

    // Execute with comprehensive error handling
    final result = await _errorHandler.handleWorkflowOperation<void>(
      operation: () async {
        await _storePickupConfirmation(confirmation);
        await _updateOrderStatus(confirmation.orderId);
      },
      operationName: 'pickup_confirmation',
      maxRetries: 3,
      requiresNetwork: true,
    );

    if (result.isSuccess) {
      debugPrint('✅ [PICKUP-SERVICE] Pickup confirmation submitted successfully');
      return PickupConfirmationResult.success(confirmation);
    } else {
      // Queue for retry if network-related error
      if (result.error!.type == WorkflowErrorType.network) {
        await _queuePickupConfirmationForRetry(confirmation);
      }

      return PickupConfirmationResult.failure(result.error!.message);
    }
  }

  /// Store pickup confirmation details in the database
  Future<void> _storePickupConfirmation(PickupConfirmation confirmation) async {
    final confirmationData = {
      'order_id': confirmation.orderId,
      'confirmed_at': confirmation.confirmedAt.toIso8601String(),
      'verification_checklist': confirmation.verificationChecklist,
      'notes': confirmation.notes,
      'confirmed_by': confirmation.confirmedBy,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Store in pickup_confirmations table (create if doesn't exist)
    await _supabase
        .from('pickup_confirmations')
        .insert(confirmationData);

    debugPrint('📝 [PICKUP-SERVICE] Pickup confirmation stored in database');
  }

  /// Update order status to picked_up using the enhanced RPC function
  Future<void> _updateOrderStatus(String orderId) async {
    try {
      // Use the enhanced driver order status update function
      final result = await _supabase.rpc(
        'update_driver_order_status_v2',
        params: {
          'p_order_id': orderId,
          'p_new_status': 'picked_up',
          'p_notes': 'Order picked up and verified by driver',
        },
      );

      if (result == null || result == false) {
        throw Exception('Failed to update order status via RPC function');
      }

      debugPrint('📦 [PICKUP-SERVICE] Order status updated to picked_up');

    } catch (e) {
      debugPrint('❌ [PICKUP-SERVICE] Failed to update order status: $e');
      
      // Fallback to direct table update if RPC fails
      await _fallbackStatusUpdate(orderId);
    }
  }

  /// Fallback method to update order status directly
  Future<void> _fallbackStatusUpdate(String orderId) async {
    debugPrint('🔄 [PICKUP-SERVICE] Using fallback status update method');

    await _supabase
        .from('orders')
        .update({
          'status': 'picked_up',
          'updated_at': DateTime.now().toIso8601String(),
          'preparation_started_at': DateTime.now().toIso8601String(), // Mark pickup time
        })
        .eq('id', orderId);

    debugPrint('✅ [PICKUP-SERVICE] Fallback status update completed');
  }

  /// Queue pickup confirmation for retry when network is restored
  Future<void> _queuePickupConfirmationForRetry(PickupConfirmation confirmation) async {
    try {
      await _recoveryService.queueOperation(
        operationType: 'pickup_confirmation',
        operationData: confirmation.toJson(),
        orderId: confirmation.orderId,
      );
      debugPrint('📝 [PICKUP-SERVICE] Pickup confirmation queued for retry');
    } catch (e) {
      debugPrint('❌ [PICKUP-SERVICE] Failed to queue pickup confirmation: $e');
    }
  }

  /// Validate pickup confirmation data (legacy method - now uses validators)
  static PickupValidationResult validatePickupConfirmation(
    PickupConfirmation confirmation,
  ) {
    final validationResult = DriverWorkflowValidators.validatePickupConfirmationData(
      verificationChecklist: confirmation.verificationChecklist,
      notes: confirmation.notes,
    );

    if (validationResult.isValid) {
      return PickupValidationResult.valid();
    } else {
      return PickupValidationResult.invalid([validationResult.errorMessage!]);
    }
  }

  /// Get pickup confirmation history for an order
  Future<List<PickupConfirmation>> getPickupHistory(String orderId) async {
    try {
      final response = await _supabase
          .from('pickup_confirmations')
          .select('*')
          .eq('order_id', orderId)
          .order('created_at', ascending: false);

      return response.map((json) => PickupConfirmation(
        orderId: json['order_id'],
        confirmedAt: DateTime.parse(json['confirmed_at']),
        verificationChecklist: Map<String, bool>.from(json['verification_checklist'] ?? {}),
        notes: json['notes'],
        confirmedBy: json['confirmed_by'],
      )).toList();

    } catch (e) {
      debugPrint('❌ [PICKUP-SERVICE] Failed to get pickup history: $e');
      return [];
    }
  }

  /// Check if an order has been pickup confirmed
  Future<bool> isOrderPickupConfirmed(String orderId) async {
    try {
      final response = await _supabase
          .from('pickup_confirmations')
          .select('id')
          .eq('order_id', orderId)
          .limit(1);

      return response.isNotEmpty;

    } catch (e) {
      debugPrint('❌ [PICKUP-SERVICE] Failed to check pickup confirmation: $e');
      return false;
    }
  }
}

// PickupConfirmationResult class moved to lib/src/features/drivers/data/models/pickup_confirmation.dart

/// Result of pickup confirmation validation
class PickupValidationResult {
  final bool isValid;
  final List<String> errors;

  const PickupValidationResult._(this.isValid, this.errors);

  factory PickupValidationResult.valid() => 
      const PickupValidationResult._(true, []);

  factory PickupValidationResult.invalid(List<String> errors) => 
      PickupValidationResult._(false, errors);

  String get errorMessage => errors.join('\n');
}

/// Provider for pickup confirmation service
final pickupConfirmationServiceProvider = Provider<PickupConfirmationService>((ref) {
  return PickupConfirmationService();
});

/// Provider for pickup confirmation submission
final submitPickupConfirmationProvider = FutureProvider.family<PickupConfirmationResult, PickupConfirmation>(
  (ref, confirmation) async {
    final service = ref.read(pickupConfirmationServiceProvider);
    return service.submitPickupConfirmation(confirmation);
  },
);

/// Provider for checking pickup confirmation status
final pickupConfirmationStatusProvider = FutureProvider.family<bool, String>(
  (ref, orderId) async {
    final service = ref.read(pickupConfirmationServiceProvider);
    return service.isOrderPickupConfirmed(orderId);
  },
);

/// Provider for pickup history
final pickupHistoryProvider = FutureProvider.family<List<PickupConfirmation>, String>(
  (ref, orderId) async {
    final service = ref.read(pickupConfirmationServiceProvider);
    return service.getPickupHistory(orderId);
  },
);
