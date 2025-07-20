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
    debugPrint('🚀 [DELIVERY-SERVICE] ===== STARTING DELIVERY CONFIRMATION SUBMISSION =====');
    debugPrint('📋 [DELIVERY-SERVICE] Order ID: ${confirmation.orderId}');
    debugPrint('📸 [DELIVERY-SERVICE] Photo URL: ${confirmation.photoUrl}');
    debugPrint('📍 [DELIVERY-SERVICE] Location: ${confirmation.location.latitude}, ${confirmation.location.longitude}');
    debugPrint('👤 [DELIVERY-SERVICE] Recipient: ${confirmation.recipientName}');
    debugPrint('📝 [DELIVERY-SERVICE] Notes: ${confirmation.notes}');
    debugPrint('⏰ [DELIVERY-SERVICE] Delivered at: ${confirmation.deliveredAt}');
    debugPrint('🔧 [DELIVERY-SERVICE] Confirmed by: ${confirmation.confirmedBy}');

    // Client-side validation
    debugPrint('🔍 [DELIVERY-SERVICE] Starting client-side validation');
    final validationResult = DriverWorkflowValidators.validateDeliveryConfirmationData(
      photoUrl: confirmation.photoUrl,
      latitude: confirmation.location.latitude,
      longitude: confirmation.location.longitude,
      accuracy: confirmation.location.accuracy,
      recipientName: confirmation.recipientName,
      notes: confirmation.notes,
    );

    if (!validationResult.isValid) {
      debugPrint('❌ [DELIVERY-SERVICE] Validation failed: ${validationResult.errorMessage}');
      return DeliveryConfirmationResult.failure(validationResult.errorMessage!);
    }

    debugPrint('✅ [DELIVERY-SERVICE] Client-side validation passed');

    // Execute with comprehensive error handling
    debugPrint('🔧 [DELIVERY-SERVICE] Starting workflow operation with error handling');
    final result = await _errorHandler.handleWorkflowOperation<void>(
      operation: () async {
        debugPrint('📝 [DELIVERY-SERVICE] Step 1: Storing delivery confirmation');
        await _storeDeliveryConfirmation(confirmation);
        debugPrint('🔧 [DELIVERY-SERVICE] Step 2: Database trigger will automatically update order status');
        debugPrint('✅ [DELIVERY-SERVICE] Delivery confirmation workflow completed - no manual status update needed');
      },
      operationName: 'delivery_confirmation',
      maxRetries: 3,
      requiresNetwork: true,
    );

    if (result.isSuccess) {
      debugPrint('✅ [DELIVERY-SERVICE] ===== DELIVERY CONFIRMATION COMPLETED SUCCESSFULLY =====');
      debugPrint('✅ [DELIVERY-SERVICE] Order ${confirmation.orderId} delivery workflow completed');
      debugPrint('✅ [DELIVERY-SERVICE] Photo proof stored and order status updated automatically');
      _logWorkflowSummary(confirmation, success: true);
      return DeliveryConfirmationResult.success(confirmation);
    } else {
      debugPrint('❌ [DELIVERY-SERVICE] ===== DELIVERY CONFIRMATION FAILED =====');
      debugPrint('❌ [DELIVERY-SERVICE] Error: ${result.error!.message}');
      debugPrint('🔍 [DELIVERY-SERVICE] Error type: ${result.error!.type}');
      _logWorkflowSummary(confirmation, success: false, error: result.error!.message);

      // Queue for retry if network-related error
      if (result.error!.type == WorkflowErrorType.network) {
        debugPrint('🔄 [DELIVERY-SERVICE] Queueing for retry due to network error');
        await _queueDeliveryConfirmationForRetry(confirmation);
      }

      return DeliveryConfirmationResult.failure(result.error!.message);
    }
  }

  /// Store delivery confirmation details in the database with duplicate prevention
  Future<void> _storeDeliveryConfirmation(DeliveryConfirmation confirmation) async {
    debugPrint('🔍 [DELIVERY-SERVICE] ===== DUPLICATE PREVENTION CHECK =====');
    debugPrint('🔍 [DELIVERY-SERVICE] Checking for existing delivery proof for order: ${confirmation.orderId}');

    // Check if delivery proof already exists for this order
    final existingProof = await _supabase
        .from('delivery_proofs')
        .select('id, order_id, created_at, photo_url, delivered_by')
        .eq('order_id', confirmation.orderId)
        .maybeSingle();

    if (existingProof != null) {
      debugPrint('⚠️ [DELIVERY-SERVICE] ===== DUPLICATE DETECTED =====');
      debugPrint('⚠️ [DELIVERY-SERVICE] Delivery proof already exists for order ${confirmation.orderId}');
      debugPrint('📋 [DELIVERY-SERVICE] Existing proof ID: ${existingProof['id']}');
      debugPrint('📅 [DELIVERY-SERVICE] Created at: ${existingProof['created_at']}');
      debugPrint('📸 [DELIVERY-SERVICE] Existing photo URL: ${existingProof['photo_url']}');
      debugPrint('👤 [DELIVERY-SERVICE] Delivered by: ${existingProof['delivered_by']}');

      // Check if order is already marked as delivered
      debugPrint('🔍 [DELIVERY-SERVICE] Checking order completion status...');
      final orderStatus = await _supabase
          .from('orders')
          .select('status, actual_delivery_time, delivery_proof_id')
          .eq('id', confirmation.orderId)
          .single();

      debugPrint('📊 [DELIVERY-SERVICE] Order status: ${orderStatus['status']}');
      debugPrint('📊 [DELIVERY-SERVICE] Actual delivery time: ${orderStatus['actual_delivery_time']}');
      debugPrint('📊 [DELIVERY-SERVICE] Delivery proof ID: ${orderStatus['delivery_proof_id']}');

      if (orderStatus['status'] == 'delivered') {
        debugPrint('✅ [DELIVERY-SERVICE] Order already completed - preventing duplicate proof creation');
        debugPrint('🚫 [DELIVERY-SERVICE] Throwing exception to prevent duplicate workflow');
        throw Exception('This delivery has already been completed. Order status: delivered');
      } else {
        debugPrint('🔧 [DELIVERY-SERVICE] Order exists but not marked as delivered - this should not happen');
        debugPrint('🔧 [DELIVERY-SERVICE] Database trigger may have failed - manual intervention needed');
        // Don't create new proof, just ensure order status is updated
        return;
      }
    } else {
      debugPrint('✅ [DELIVERY-SERVICE] No existing delivery proof found - proceeding with creation');
    }

    debugPrint('📝 [DELIVERY-SERVICE] ===== CREATING NEW DELIVERY PROOF =====');
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

    debugPrint('📝 [DELIVERY-SERVICE] Delivery proof data prepared:');
    debugPrint('📝 [DELIVERY-SERVICE] - Order ID: ${confirmationData['order_id']}');
    debugPrint('📝 [DELIVERY-SERVICE] - Photo URL: ${confirmationData['photo_url']}');
    debugPrint('📝 [DELIVERY-SERVICE] - Location: ${confirmationData['latitude']}, ${confirmationData['longitude']}');
    debugPrint('📝 [DELIVERY-SERVICE] - Delivered at: ${confirmationData['delivered_at']}');
    debugPrint('📝 [DELIVERY-SERVICE] - Delivered by: ${confirmationData['delivered_by']}');
    debugPrint('🗄️ [DELIVERY-SERVICE] Target table: delivery_proofs');

    try {
      debugPrint('🚀 [DELIVERY-SERVICE] Inserting delivery proof into database...');
      // Store in delivery_proofs table (correct table name)
      final insertResult = await _supabase
          .from('delivery_proofs')
          .insert(confirmationData)
          .select();

      debugPrint('✅ [DELIVERY-SERVICE] ===== DELIVERY PROOF CREATED SUCCESSFULLY =====');
      debugPrint('📊 [DELIVERY-SERVICE] Insert result: $insertResult');
      debugPrint('🔧 [DELIVERY-SERVICE] Database trigger will now automatically update order status to delivered');
    } catch (e) {
      debugPrint('❌ [DELIVERY-SERVICE] ===== DATABASE INSERT ERROR =====');
      debugPrint('❌ [DELIVERY-SERVICE] Error details: $e');
      debugPrint('❌ [DELIVERY-SERVICE] Error type: ${e.runtimeType}');

      // Handle potential race condition where proof was created between check and insert
      if (e.toString().contains('unique_order_proof') ||
          e.toString().contains('duplicate key value')) {
        debugPrint('🏁 [DELIVERY-SERVICE] ===== RACE CONDITION DETECTED =====');
        debugPrint('🏁 [DELIVERY-SERVICE] Another process created delivery proof between our check and insert');
        debugPrint('🔄 [DELIVERY-SERVICE] Verifying final order completion status...');

        // Verify the order is properly marked as delivered
        final orderStatus = await _supabase
            .from('orders')
            .select('status, actual_delivery_time, delivery_proof_id')
            .eq('id', confirmation.orderId)
            .single();

        debugPrint('📊 [DELIVERY-SERVICE] Final order status: ${orderStatus['status']}');
        debugPrint('📊 [DELIVERY-SERVICE] Final delivery time: ${orderStatus['actual_delivery_time']}');
        debugPrint('📊 [DELIVERY-SERVICE] Final proof ID: ${orderStatus['delivery_proof_id']}');

        if (orderStatus['status'] != 'delivered') {
          debugPrint('🔧 [DELIVERY-SERVICE] Order not marked as delivered despite existing proof - database trigger issue');
          throw Exception('Delivery proof exists but order status needs update');
        } else {
          debugPrint('✅ [DELIVERY-SERVICE] Order properly completed by another process - race condition resolved');
          throw Exception('This delivery has already been completed');
        }
      } else {
        // Re-throw other errors
        debugPrint('❌ [DELIVERY-SERVICE] Unexpected database error: $e');
        rethrow;
      }
    }
  }

  // NOTE: Order status update is now handled automatically by database trigger
  // when delivery proof is created. No manual status update is needed.
  // This prevents duplicate operations and ensures consistency.

  /// Log comprehensive workflow summary for debugging and monitoring
  void _logWorkflowSummary(DeliveryConfirmation confirmation, {required bool success, String? error}) {
    debugPrint('📊 [DELIVERY-SERVICE] ===== WORKFLOW SUMMARY =====');
    debugPrint('📊 [DELIVERY-SERVICE] Order ID: ${confirmation.orderId}');
    debugPrint('📊 [DELIVERY-SERVICE] Success: $success');
    debugPrint('📊 [DELIVERY-SERVICE] Photo URL: ${confirmation.photoUrl}');
    debugPrint('📊 [DELIVERY-SERVICE] Location: ${confirmation.location.latitude}, ${confirmation.location.longitude}');
    debugPrint('📊 [DELIVERY-SERVICE] Delivered at: ${confirmation.deliveredAt}');
    debugPrint('📊 [DELIVERY-SERVICE] Confirmed by: ${confirmation.confirmedBy}');
    if (confirmation.recipientName != null) {
      debugPrint('📊 [DELIVERY-SERVICE] Recipient: ${confirmation.recipientName}');
    }
    if (confirmation.notes != null) {
      debugPrint('📊 [DELIVERY-SERVICE] Notes: ${confirmation.notes}');
    }
    if (!success && error != null) {
      debugPrint('📊 [DELIVERY-SERVICE] Error: $error');
    }
    debugPrint('📊 [DELIVERY-SERVICE] ===== END SUMMARY =====');
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
