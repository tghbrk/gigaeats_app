import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/orders/data/models/order.dart';
import '../../data/models/delivery_method.dart';
import '../../features/orders/data/repositories/order_repository.dart';
import '../../core/utils/debug_logger.dart';
import 'repository_providers.dart';

/// State for delivery proof real-time updates
class DeliveryProofRealtimeState {
  final Map<String, ProofOfDelivery> deliveryProofs;
  final Map<String, Order> updatedOrders;
  final bool isConnected;
  final DateTime? lastUpdate;
  final String? error;

  const DeliveryProofRealtimeState({
    this.deliveryProofs = const {},
    this.updatedOrders = const {},
    this.isConnected = false,
    this.lastUpdate,
    this.error,
  });

  DeliveryProofRealtimeState copyWith({
    Map<String, ProofOfDelivery>? deliveryProofs,
    Map<String, Order>? updatedOrders,
    bool? isConnected,
    DateTime? lastUpdate,
    String? error,
  }) {
    return DeliveryProofRealtimeState(
      deliveryProofs: deliveryProofs ?? this.deliveryProofs,
      updatedOrders: updatedOrders ?? this.updatedOrders,
      isConnected: isConnected ?? this.isConnected,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      error: error ?? this.error,
    );
  }
}

/// Notifier for real-time delivery proof updates
class DeliveryProofRealtimeNotifier extends StateNotifier<DeliveryProofRealtimeState> {
  final OrderRepository _orderRepository;
  final SupabaseClient _supabase;
  RealtimeChannel? _deliveryProofChannel;
  RealtimeChannel? _orderChannel;

  DeliveryProofRealtimeNotifier(this._orderRepository, this._supabase) 
      : super(const DeliveryProofRealtimeState()) {
    _setupRealtimeSubscriptions();
  }

  void _setupRealtimeSubscriptions() {
    try {
      // Subscribe to delivery_proofs table changes
      _deliveryProofChannel = _supabase
          .channel('delivery_proofs_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'delivery_proofs',
            callback: (payload) {
              _handleDeliveryProofUpdate(payload);
            },
          )
          .subscribe();

      // Subscribe to orders table changes (for status updates)
      _orderChannel = _supabase
          .channel('orders_delivery_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'orders',
            callback: (payload) {
              _handleOrderUpdate(payload);
            },
          )
          .subscribe();

      state = state.copyWith(isConnected: true);
      DebugLogger.info('Delivery proof real-time subscriptions established', tag: 'DeliveryProofRealtime');
    } catch (e) {
      DebugLogger.error('Failed to setup delivery proof real-time subscriptions: $e', tag: 'DeliveryProofRealtime');
      state = state.copyWith(error: e.toString());
    }
  }

  void _handleDeliveryProofUpdate(PostgresChangePayload payload) {
    try {
      DebugLogger.info('Delivery proof real-time update: ${payload.eventType}', tag: 'DeliveryProofRealtime');

      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
        case PostgresChangeEvent.update:
          final proofData = payload.newRecord;
          if (proofData != null) {
            final proof = ProofOfDelivery.fromJson(proofData);
            final orderId = proofData['order_id'] as String;

            final updatedProofs = Map<String, ProofOfDelivery>.from(state.deliveryProofs);
            updatedProofs[orderId] = proof;

            state = state.copyWith(
              deliveryProofs: updatedProofs,
              lastUpdate: DateTime.now(),
            );

            DebugLogger.info('Delivery proof updated for order: $orderId', tag: 'DeliveryProofRealtime');

            // Trigger order refresh to get updated status
            _refreshOrderData(orderId);
          }
          break;
        case PostgresChangeEvent.delete:
          final oldData = payload.oldRecord;
          if (oldData != null) {
            final orderId = oldData['order_id'] as String;
            final updatedProofs = Map<String, ProofOfDelivery>.from(state.deliveryProofs);
            updatedProofs.remove(orderId);

            state = state.copyWith(
              deliveryProofs: updatedProofs,
              lastUpdate: DateTime.now(),
            );

            DebugLogger.info('Delivery proof deleted for order: $orderId', tag: 'DeliveryProofRealtime');
          }
          break;
        default:
          // Handle all other events including PostgresChangeEvent.all
          DebugLogger.info('Received other event type for delivery proof: ${payload.eventType}', tag: 'DeliveryProofRealtime');
          break;
      }
    } catch (e) {
      DebugLogger.error('Error handling delivery proof update: $e', tag: 'DeliveryProofRealtime');
      state = state.copyWith(error: e.toString());
    }
  }

  void _handleOrderUpdate(PostgresChangePayload payload) {
    try {
      final orderData = payload.newRecord;
      if (orderData != null) {
        // Check if this is a delivery-related status update
        final status = orderData['status'] as String?;
        final deliveryProofId = orderData['delivery_proof_id'] as String?;
        
        if (status == 'delivered' && deliveryProofId != null) {
          DebugLogger.info('Order delivered status update: ${orderData['id']}', tag: 'DeliveryProofRealtime');
          
          // Process the order data to handle JSON fields
          final processedData = _processOrderData(orderData);
          final order = Order.fromJson(processedData);
          
          final updatedOrders = Map<String, Order>.from(state.updatedOrders);
          updatedOrders[order.id] = order;

          state = state.copyWith(
            updatedOrders: updatedOrders,
            lastUpdate: DateTime.now(),
          );
        }
      }
    } catch (e) {
      DebugLogger.error('Error handling order update: $e', tag: 'DeliveryProofRealtime');
      state = state.copyWith(error: e.toString());
    }
  }

  Map<String, dynamic> _processOrderData(Map<String, dynamic> orderData) {
    final processedData = Map<String, dynamic>.from(orderData);

    // Handle delivery_address field - convert from JSON string to Map if needed
    if (processedData['delivery_address'] is String) {
      try {
        processedData['delivery_address'] = 
            Map<String, dynamic>.from(processedData['delivery_address'] as Map);
      } catch (e) {
        DebugLogger.error('Error parsing delivery_address: $e', tag: 'DeliveryProofRealtime');
        processedData['delivery_address'] = {
          'street': 'Unknown',
          'city': 'Unknown',
          'state': 'Unknown',
          'postal_code': '00000',
          'country': 'Malaysia',
        };
      }
    }

    // Handle metadata field
    if (processedData['metadata'] is String) {
      try {
        processedData['metadata'] = 
            Map<String, dynamic>.from(processedData['metadata'] as Map);
      } catch (e) {
        DebugLogger.error('Error parsing metadata: $e', tag: 'DeliveryProofRealtime');
        processedData['metadata'] = null;
      }
    }

    return processedData;
  }

  Future<void> _refreshOrderData(String orderId) async {
    try {
      final order = await _orderRepository.getOrderById(orderId);
      if (order != null) {
        final updatedOrders = Map<String, Order>.from(state.updatedOrders);
        updatedOrders[orderId] = order;

        state = state.copyWith(
          updatedOrders: updatedOrders,
          lastUpdate: DateTime.now(),
        );
      }
    } catch (e) {
      DebugLogger.error('Error refreshing order data: $e', tag: 'DeliveryProofRealtime');
    }
  }

  /// Get delivery proof for a specific order
  ProofOfDelivery? getDeliveryProof(String orderId) {
    return state.deliveryProofs[orderId];
  }

  /// Get updated order data
  Order? getUpdatedOrder(String orderId) {
    return state.updatedOrders[orderId];
  }

  /// Check if an order has been recently updated
  bool hasRecentUpdate(String orderId) {
    return state.updatedOrders.containsKey(orderId) ||
           state.deliveryProofs.containsKey(orderId);
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Manually refresh delivery proof for an order
  Future<void> refreshDeliveryProof(String orderId) async {
    try {
      final proof = await _orderRepository.getDeliveryProof(orderId);
      if (proof != null) {
        final updatedProofs = Map<String, ProofOfDelivery>.from(state.deliveryProofs);
        updatedProofs[orderId] = proof;

        state = state.copyWith(
          deliveryProofs: updatedProofs,
          lastUpdate: DateTime.now(),
        );
      }
    } catch (e) {
      DebugLogger.error('Error refreshing delivery proof: $e', tag: 'DeliveryProofRealtime');
      state = state.copyWith(error: e.toString());
    }
  }

  @override
  void dispose() {
    _deliveryProofChannel?.unsubscribe();
    _orderChannel?.unsubscribe();
    super.dispose();
  }
}

/// Provider for delivery proof real-time updates
final deliveryProofRealtimeProvider = StateNotifierProvider<DeliveryProofRealtimeNotifier, DeliveryProofRealtimeState>((ref) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  final supabase = ref.watch(supabaseProvider);
  return DeliveryProofRealtimeNotifier(orderRepository, supabase);
});

/// Provider to get delivery proof for a specific order
final deliveryProofProvider = Provider.family<ProofOfDelivery?, String>((ref, orderId) {
  final realtimeState = ref.watch(deliveryProofRealtimeProvider);
  return realtimeState.deliveryProofs[orderId];
});

/// Provider to check if an order has recent delivery updates
final hasDeliveryUpdateProvider = Provider.family<bool, String>((ref, orderId) {
  final realtimeState = ref.watch(deliveryProofRealtimeProvider);
  return realtimeState.updatedOrders.containsKey(orderId) ||
         realtimeState.deliveryProofs.containsKey(orderId);
});

/// Provider for real-time connection status
final deliveryRealtimeConnectionProvider = Provider<bool>((ref) {
  final realtimeState = ref.watch(deliveryProofRealtimeProvider);
  return realtimeState.isConnected;
});
