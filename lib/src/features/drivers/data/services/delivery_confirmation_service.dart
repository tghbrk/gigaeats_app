import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/delivery_confirmation.dart';
import '../../../../core/services/location_service.dart';
import 'driver_workflow_error_handler.dart';
import 'network_failure_recovery_service.dart';
import '../validators/driver_workflow_validators.dart';

/// Enhanced service for handling delivery confirmations with photo and GPS verification
/// Manages the mandatory delivery proof process for drivers with comprehensive error handling
class DeliveryConfirmationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DriverWorkflowErrorHandler _errorHandler = DriverWorkflowErrorHandler();
  final NetworkFailureRecoveryService _recoveryService = NetworkFailureRecoveryService();

  /// Submit delivery confirmation to the backend with enhanced error handling
  Future<DeliveryConfirmationResult> submitDeliveryConfirmation(
    DeliveryConfirmation confirmation,
  ) async {
    // Client-side validation
    final validationResult = DriverWorkflowValidators.validateDeliveryConfirmationData(
      photoUrl: confirmation.photoUrl,
      latitude: confirmation.location.latitude,
      longitude: confirmation.location.longitude,
      accuracy: confirmation.location.accuracy,
      recipientName: confirmation.recipientName,
      notes: confirmation.notes,
    );

    if (!validationResult.isValid) {
      return DeliveryConfirmationResult.failure(validationResult.errorMessage!);
    }

    // Execute with comprehensive error handling
    final result = await _errorHandler.handleWorkflowOperation<void>(
      operation: () async {
        await _storeDeliveryConfirmation(confirmation);
        await _updateOrderStatus(confirmation.orderId);
      },
      operationName: 'delivery_confirmation',
      maxRetries: 3,
      requiresNetwork: true,
    );

    if (result.isSuccess) {
      debugPrint('✅ [DELIVERY-SERVICE] Delivery confirmation submitted successfully');
      return DeliveryConfirmationResult.success(confirmation);
    } else {
      // Queue for retry if network-related error
      if (result.error!.type == WorkflowErrorType.network) {
        await _queueDeliveryConfirmationForRetry(confirmation);
      }

      return DeliveryConfirmationResult.failure(result.error!.message);
    }
  }

  /// Store delivery confirmation details in the database
  Future<void> _storeDeliveryConfirmation(DeliveryConfirmation confirmation) async {
    final confirmationData = {
      'order_id': confirmation.orderId,
      'delivered_at': confirmation.deliveredAt.toIso8601String(),
      'photo_url': confirmation.photoUrl,
      'latitude': confirmation.location.latitude,
      'longitude': confirmation.location.longitude,
      'location_accuracy': confirmation.location.accuracy,
      'recipient_name': confirmation.recipientName,
      'notes': confirmation.notes,
      'delivered_by': confirmation.confirmedBy,
      'created_at': DateTime.now().toIso8601String(),
    };

    debugPrint('📝 [DELIVERY-SERVICE] Storing delivery confirmation data: $confirmationData');

    // Store in delivery_proofs table (correct table name)
    await _supabase
        .from('delivery_proofs')
        .insert(confirmationData);

    debugPrint('📝 [DELIVERY-SERVICE] Delivery confirmation stored in database');
  }

  /// Update order status to delivered using the enhanced RPC function
  Future<void> _updateOrderStatus(String orderId) async {
    try {
      // Use the enhanced driver order status update function
      final result = await _supabase.rpc(
        'update_driver_order_status_v2',
        params: {
          'p_order_id': orderId,
          'p_new_status': 'delivered',
          'p_notes': 'Order delivered with photo proof and GPS verification',
        },
      );

      if (result == null || result == false) {
        throw Exception('Failed to update order status via RPC function');
      }

      debugPrint('📦 [DELIVERY-SERVICE] Order status updated to delivered');

    } catch (e) {
      debugPrint('❌ [DELIVERY-SERVICE] Failed to update order status: $e');
      
      // Fallback to direct table update if RPC fails
      await _fallbackStatusUpdate(orderId);
    }
  }

  /// Fallback method to update order status directly
  Future<void> _fallbackStatusUpdate(String orderId) async {
    debugPrint('🔄 [DELIVERY-SERVICE] Using fallback status update method');

    await _supabase
        .from('orders')
        .update({
          'status': 'delivered',
          'updated_at': DateTime.now().toIso8601String(),
          'actual_delivery_time': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);

    debugPrint('✅ [DELIVERY-SERVICE] Fallback status update completed');
  }

  /// Queue delivery confirmation for retry when network is restored
  Future<void> _queueDeliveryConfirmationForRetry(DeliveryConfirmation confirmation) async {
    try {
      await _recoveryService.queueOperation(
        operationType: 'delivery_confirmation',
        operationData: confirmation.toJson(),
        orderId: confirmation.orderId,
      );
      debugPrint('📝 [DELIVERY-SERVICE] Delivery confirmation queued for retry');
    } catch (e) {
      debugPrint('❌ [DELIVERY-SERVICE] Failed to queue delivery confirmation: $e');
    }
  }

  // Legacy validation method removed - now uses DriverWorkflowValidators directly

  /// Get delivery confirmation history for an order
  Future<List<DeliveryConfirmation>> getDeliveryHistory(String orderId) async {
    try {
      final response = await _supabase
          .from('delivery_proofs')
          .select('*')
          .eq('order_id', orderId)
          .order('created_at', ascending: false);

      return response.map((json) => DeliveryConfirmation(
        orderId: json['order_id'],
        deliveredAt: DateTime.parse(json['delivered_at']),
        photoUrl: json['photo_url'],
        location: LocationData(
          latitude: json['latitude'],
          longitude: json['longitude'],
          accuracy: json['location_accuracy'],
          timestamp: DateTime.now(),
        ),
        recipientName: json['recipient_name'],
        notes: json['notes'],
        confirmedBy: json['delivered_by'], // Use delivered_by field
      )).toList();

    } catch (e) {
      debugPrint('❌ [DELIVERY-SERVICE] Failed to get delivery history: $e');
      return [];
    }
  }

  /// Check if an order has been delivery confirmed
  Future<bool> isOrderDeliveryConfirmed(String orderId) async {
    try {
      final response = await _supabase
          .from('delivery_proofs')
          .select('id')
          .eq('order_id', orderId)
          .limit(1);

      return response.isNotEmpty;

    } catch (e) {
      debugPrint('❌ [DELIVERY-SERVICE] Failed to check delivery confirmation: $e');
      return false;
    }
  }

  /// Get delivery proof photo URL for an order
  Future<String?> getDeliveryProofPhoto(String orderId) async {
    try {
      final response = await _supabase
          .from('delivery_proofs')
          .select('photo_url')
          .eq('order_id', orderId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first['photo_url'];
      }
      return null;

    } catch (e) {
      debugPrint('❌ [DELIVERY-SERVICE] Failed to get delivery proof photo: $e');
      return null;
    }
  }
}

// DeliveryConfirmationResult class moved to lib/src/features/drivers/data/models/delivery_confirmation.dart

/// Result of delivery confirmation validation
class DeliveryValidationResult {
  final bool isValid;
  final List<String> errors;

  const DeliveryValidationResult._(this.isValid, this.errors);

  factory DeliveryValidationResult.valid() => 
      const DeliveryValidationResult._(true, []);

  factory DeliveryValidationResult.invalid(List<String> errors) => 
      DeliveryValidationResult._(false, errors);

  String get errorMessage => errors.join('\n');
}

// LocationData class is imported from lib/src/core/services/location_service.dart

/// Provider for delivery confirmation service
final deliveryConfirmationServiceProvider = Provider<DeliveryConfirmationService>((ref) {
  return DeliveryConfirmationService();
});

/// Provider for delivery confirmation submission
final submitDeliveryConfirmationProvider = FutureProvider.family<DeliveryConfirmationResult, DeliveryConfirmation>(
  (ref, confirmation) async {
    final service = ref.read(deliveryConfirmationServiceProvider);
    return service.submitDeliveryConfirmation(confirmation);
  },
);

/// Provider for checking delivery confirmation status
final deliveryConfirmationStatusProvider = FutureProvider.family<bool, String>(
  (ref, orderId) async {
    final service = ref.read(deliveryConfirmationServiceProvider);
    return service.isOrderDeliveryConfirmed(orderId);
  },
);

/// Provider for delivery history
final deliveryHistoryProvider = FutureProvider.family<List<DeliveryConfirmation>, String>(
  (ref, orderId) async {
    final service = ref.read(deliveryConfirmationServiceProvider);
    return service.getDeliveryHistory(orderId);
  },
);

/// Provider for delivery proof photo
final deliveryProofPhotoProvider = FutureProvider.family<String?, String>(
  (ref, orderId) async {
    final service = ref.read(deliveryConfirmationServiceProvider);
    return service.getDeliveryProofPhoto(orderId);
  },
);
