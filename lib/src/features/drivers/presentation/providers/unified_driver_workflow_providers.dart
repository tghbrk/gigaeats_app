import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/data/models/order.dart';
import '../../../../data/models/user_role.dart';
import '../../../../core/utils/driver_workflow_logger.dart';
import '../../../drivers/data/models/driver_order.dart';
import '../../../drivers/data/utils/enhanced_status_converter.dart';

/// Unified driver workflow state management to replace multiple conflicting providers
/// This consolidates enhancedCurrentDriverOrderProvider, currentDriverOrderProvider, 
/// incomingOrdersStreamProvider, and activeOrdersStreamProvider

/// Unified current driver order provider - single source of truth
final unifiedCurrentDriverOrderProvider = StreamProvider.autoDispose<DriverOrder?>((ref) async* {
  final authState = ref.watch(authStateProvider); // Use watch for reactivity
  
  DriverWorkflowLogger.logProviderState(
    providerName: 'unifiedCurrentDriverOrderProvider',
    state: 'Provider initialized',
    context: 'UNIFIED_PROVIDER',
  );
  
  if (authState.user?.role != UserRole.driver) {
    DriverWorkflowLogger.logProviderState(
      providerName: 'unifiedCurrentDriverOrderProvider',
      state: 'User is not a driver',
      context: 'UNIFIED_PROVIDER',
    );
    yield null;
    return;
  }

  final userId = authState.user?.id;
  if (userId == null) {
    DriverWorkflowLogger.logProviderState(
      providerName: 'unifiedCurrentDriverOrderProvider',
      state: 'User not authenticated',
      context: 'UNIFIED_PROVIDER',
    );
    yield null;
    return;
  }

  try {
    final supabase = Supabase.instance.client;
    
    // Get driver ID once and cache it
    final driverResponse = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .single();
    
    final driverId = driverResponse['id'] as String;

    DriverWorkflowLogger.logDatabaseOperation(
      operation: 'UNIFIED_CURRENT_ORDER_STREAM',
      orderId: 'unified-workflow',
      data: {'driver_id': driverId},
      context: 'UNIFIED_PROVIDER',
    );

    // Single comprehensive real-time subscription
    yield* supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('assigned_driver_id', driverId)
        .asyncMap((data) async {
          DriverWorkflowLogger.logProviderState(
            providerName: 'unifiedCurrentDriverOrderProvider',
            state: 'Stream update received',
            context: 'UNIFIED_PROVIDER',
            details: {'order_count': data.length},
          );
          
          // Filter for active workflow statuses
          final activeStatuses = [
            'assigned', 'on_route_to_vendor', 'arrived_at_vendor',
            'picked_up', 'on_route_to_customer', 'arrived_at_customer'
          ];
          
          final activeOrders = data.where((json) =>
            activeStatuses.contains(json['status'])
          ).toList();

          if (activeOrders.isEmpty) {
            DriverWorkflowLogger.logProviderState(
              providerName: 'unifiedCurrentDriverOrderProvider',
              state: 'No active orders found',
              context: 'UNIFIED_PROVIDER',
            );
            return null;
          }

          // Get the most recent active order
          final latestOrder = activeOrders.first;
          final orderId = latestOrder['id'] as String;

          // Fetch complete order details with related data
          final fullOrderResponse = await supabase
              .from('orders')
              .select('''
                *,
                order_items:order_items(
                  *,
                  menu_item:menu_items!order_items_menu_item_id_fkey(
                    id,
                    name,
                    image_url
                  )
                ),
                vendors:vendors!orders_vendor_id_fkey(
                  business_name,
                  business_address,
                  business_latitude,
                  business_longitude
                )
              ''')
              .eq('id', orderId)
              .single();

          final driverOrder = DriverOrder.fromJson(fullOrderResponse);
          
          DriverWorkflowLogger.logProviderState(
            providerName: 'unifiedCurrentDriverOrderProvider',
            state: 'Active order loaded',
            context: 'UNIFIED_PROVIDER',
            details: {
              'order_id': orderId,
              'status': driverOrder.status.name,
            },
          );

          return driverOrder;
        });
  } catch (e) {
    DriverWorkflowLogger.logError(
      operation: 'Unified Current Order Provider',
      error: e.toString(),
      context: 'UNIFIED_PROVIDER',
    );
    yield null;
  }
});

/// Unified incoming orders provider - replaces multiple incoming order providers
final unifiedIncomingOrdersProvider = StreamProvider.autoDispose<List<Order>>((ref) async* {
  final authState = ref.watch(authStateProvider);
  
  if (authState.user?.role != UserRole.driver) {
    yield <Order>[];
    return;
  }

  final userId = authState.user?.id;
  if (userId == null) {
    yield <Order>[];
    return;
  }

  try {
    final supabase = Supabase.instance.client;
    
    DriverWorkflowLogger.logProviderState(
      providerName: 'unifiedIncomingOrdersProvider',
      state: 'Starting incoming orders stream',
      context: 'UNIFIED_PROVIDER',
    );

    // Get initial data
    final initialResponse = await supabase
        .from('orders')
        .select('''
          *,
          order_items:order_items(
            *,
            menu_item:menu_items!order_items_menu_item_id_fkey(
              id,
              name,
              image_url
            )
          ),
          vendors:vendors!orders_vendor_id_fkey(
            business_name,
            business_address
          )
        ''')
        .eq('status', 'ready')
        .isFilter('assigned_driver_id', null)
        .eq('delivery_method', 'own_fleet')
        .order('created_at', ascending: true);

    if (initialResponse.isNotEmpty) {
      final initialOrders = initialResponse.map((json) => Order.fromJson(json)).toList();
      DriverWorkflowLogger.logProviderState(
        providerName: 'unifiedIncomingOrdersProvider',
        state: 'Initial orders loaded',
        context: 'UNIFIED_PROVIDER',
        details: {'order_count': initialOrders.length},
      );
      yield initialOrders;
    } else {
      yield <Order>[];
    }

    // Real-time updates with optimized filtering
    yield* supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .asyncMap((data) async {
          final availableOrderIds = data
              .where((json) =>
                json['status'] == 'ready' &&
                json['assigned_driver_id'] == null &&
                json['delivery_method'] == 'own_fleet')
              .map((json) => json['id'] as String)
              .toList();

          if (availableOrderIds.isEmpty) {
            return <Order>[];
          }

          // Fetch complete data for available orders
          final detailedResponse = await supabase
              .from('orders')
              .select('''
                *,
                order_items:order_items(
                  *,
                  menu_item:menu_items!order_items_menu_item_id_fkey(
                    id,
                    name,
                    image_url
                  )
                ),
                vendors:vendors!orders_vendor_id_fkey(
                  business_name,
                  business_address
                )
              ''')
              .inFilter('id', availableOrderIds)
              .order('created_at', ascending: true);

          final orders = detailedResponse.map((json) => Order.fromJson(json)).toList();
          
          DriverWorkflowLogger.logProviderState(
            providerName: 'unifiedIncomingOrdersProvider',
            state: 'Stream update processed',
            context: 'UNIFIED_PROVIDER',
            details: {'order_count': orders.length},
          );

          return orders;
        });
  } catch (e) {
    DriverWorkflowLogger.logError(
      operation: 'Unified Incoming Orders Provider',
      error: e.toString(),
      context: 'UNIFIED_PROVIDER',
    );
    yield <Order>[];
  }
});

/// Smart invalidation service to prevent circular dependencies
class SmartInvalidationService {
  static Timer? _invalidationTimer;
  static final Set<ProviderBase> _pendingInvalidations = {};
  
  /// Schedule debounced invalidation to prevent infinite loops
  static void scheduleInvalidation(WidgetRef ref, List<ProviderBase> providers) {
    _pendingInvalidations.addAll(providers);
    
    _invalidationTimer?.cancel();
    _invalidationTimer = Timer(const Duration(milliseconds: 100), () {
      DriverWorkflowLogger.logProviderState(
        providerName: 'SmartInvalidationService',
        state: 'Executing batch invalidation',
        context: 'INVALIDATION',
        details: {'provider_count': _pendingInvalidations.length},
      );
      
      for (final provider in _pendingInvalidations) {
        try {
          ref.invalidate(provider);
        } catch (e) {
          DriverWorkflowLogger.logError(
            operation: 'Provider Invalidation',
            error: e.toString(),
            context: 'INVALIDATION',
          );
        }
      }
      _pendingInvalidations.clear();
    });
  }
  
  /// Immediate invalidation for critical updates
  static void immediateInvalidation(WidgetRef ref, List<ProviderBase> providers) {
    DriverWorkflowLogger.logProviderState(
      providerName: 'SmartInvalidationService',
      state: 'Executing immediate invalidation',
      context: 'INVALIDATION',
      details: {'provider_count': providers.length},
    );
    
    for (final provider in providers) {
      try {
        ref.invalidate(provider);
      } catch (e) {
        DriverWorkflowLogger.logError(
          operation: 'Immediate Provider Invalidation',
          error: e.toString(),
          context: 'INVALIDATION',
        );
      }
    }
  }
}

/// Enhanced order status update provider with smart invalidation
final unifiedOrderStatusUpdateProvider = FutureProvider.family<bool, ({String orderId, String status})>((ref, params) async {
  final authState = ref.read(authStateProvider); // Use read for one-time access
  
  if (authState.user?.role != UserRole.driver) {
    throw Exception('Only drivers can update order status');
  }

  final userId = authState.user?.id;
  if (userId == null) {
    throw Exception('User not authenticated');
  }

  try {
    final supabase = Supabase.instance.client;

    DriverWorkflowLogger.logDatabaseOperation(
      operation: 'UNIFIED_ORDER_STATUS_UPDATE',
      orderId: params.orderId,
      data: {
        'from_status': 'unknown',
        'to_status': params.status,
        'user_id': userId,
      },
      context: 'UNIFIED_PROVIDER',
    );

    // Validate status conversion
    final statusConversion = EnhancedStatusConverter.safeFromDatabaseString(params.status);
    if (!statusConversion.isSuccess) {
      throw Exception('Invalid status: ${params.status}');
    }

    // Update order status
    final updateResponse = await supabase
        .from('orders')
        .update({
          'status': params.status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', params.orderId)
        .select();

    if (updateResponse.isEmpty) {
      throw Exception('Failed to update order status');
    }

    // Note: Smart invalidation would be called here in a widget context
    // SmartInvalidationService.scheduleInvalidation(ref, [...]);

    DriverWorkflowLogger.logDatabaseOperation(
      operation: 'UNIFIED_ORDER_STATUS_UPDATE',
      orderId: params.orderId,
      isSuccess: true,
      context: 'UNIFIED_PROVIDER',
    );

    return true;
  } catch (e) {
    DriverWorkflowLogger.logError(
      operation: 'Unified Order Status Update',
      error: e.toString(),
      orderId: params.orderId,
      context: 'UNIFIED_PROVIDER',
    );
    throw Exception('Failed to update order status: $e');
  }
});
