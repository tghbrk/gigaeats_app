import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/data/models/order.dart';
import '../../../../data/models/user_role.dart';
import '../../../../core/utils/driver_workflow_logger.dart';

/// Provider for incoming orders (status: 'ready', no assigned driver)
final incomingOrdersStreamProvider = StreamProvider.autoDispose<List<Order>>((ref) async* {
  final authState = ref.read(authStateProvider);
  
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
    
    debugPrint('🚗 Streaming incoming orders for driver');
    
    // First get initial data with order_items
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

    debugPrint('🚗 Initial incoming orders loaded: ${initialResponse.length} orders');
    final initialOrders = initialResponse.map((json) => Order.fromJson(json)).toList();

    // Debug order items count
    for (final order in initialOrders) {
      debugPrint('🚗 Incoming order ${order.orderNumber}: ${order.items.length} items');
    }

    yield initialOrders;

    // Then listen for real-time updates
    // Listen to ALL order changes, then filter in memory for proper real-time updates
    yield* supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .asyncMap((data) async {
          debugPrint('🚗 Incoming orders stream update: ${data.length} total orders');
          // Filter for orders that are ready and have no assigned driver
          final availableOrderIds = data
              .where((json) =>
                json['status'] == 'ready' &&
                json['assigned_driver_id'] == null &&
                json['delivery_method'] == 'own_fleet')
              .map((json) => json['id'] as String)
              .toList();

          if (availableOrderIds.isEmpty) {
            debugPrint('🚗 No incoming orders after filtering');
            return <Order>[];
          }

          // Fetch full order data with order_items for the filtered orders
          final fullResponse = await supabase
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

          debugPrint('🚗 Fetched full data for ${fullResponse.length} incoming orders');
          final orders = fullResponse.map((json) => Order.fromJson(json)).toList();

          // Debug order items count
          for (final order in orders) {
            debugPrint('🚗 Incoming order ${order.orderNumber}: ${order.items.length} items');
          }

          return orders;
        });
  } catch (e) {
    debugPrint('Error streaming incoming orders: $e');
    yield <Order>[];
  }
});

/// Provider for active orders assigned to current driver
final activeOrdersStreamProvider = StreamProvider.autoDispose<List<Order>>((ref) async* {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    debugPrint('🚗 Active: User is not a driver, role: ${authState.user?.role}');
    yield <Order>[];
    return;
  }

  final userId = authState.user?.id;
  if (userId == null) {
    debugPrint('🚗 Active: No user ID found');
    yield <Order>[];
    return;
  }

  try {
    final supabase = Supabase.instance.client;

    debugPrint('🚗 Streaming active orders for auth user: $userId');

    // First, get the driver ID for this user
    final driverResponse = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (driverResponse == null) {
      debugPrint('🚗 Active: No driver profile found for user: $userId');
      yield <Order>[];
      return;
    }

    final driverId = driverResponse['id'] as String;
    debugPrint('🚗 Active: Found driver ID: $driverId for user: $userId');

    // First get initial data with order_items - include all driver workflow statuses
    final activeStatuses = [
      'assigned',
      'confirmed',
      'preparing',
      'ready',
      'out_for_delivery',
      'on_route_to_vendor',
      'arrived_at_vendor',
      'picked_up',
      'on_route_to_customer',
      'arrived_at_customer'
    ];
    debugPrint('🚗 Active: Querying orders with assigned_driver_id: $driverId, statuses: $activeStatuses');

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
        .eq('assigned_driver_id', driverId)
        .inFilter('status', activeStatuses)
        .order('created_at', ascending: false);

    debugPrint('🚗 Initial active orders loaded: ${initialResponse.length} orders');
    final initialOrders = initialResponse.map((json) => Order.fromJson(json)).toList();

    // Debug order items count
    for (final order in initialOrders) {
      debugPrint('🚗 Active order ${order.orderNumber}: ${order.items.length} items, status: ${order.status}');
    }

    yield initialOrders;

    // Then listen for real-time updates
    debugPrint('🚗 Active: Setting up real-time stream for driver: $driverId');
    yield* supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('assigned_driver_id', driverId)
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          debugPrint('🚗 Active orders stream update: ${data.length} total orders for driver: $driverId');
          // Filter for active statuses
          final activeOrderIds = data
              .where((json) => activeStatuses.contains(json['status']))
              .map((json) => json['id'] as String)
              .toList();

          debugPrint('🚗 Active: Found ${activeOrderIds.length} active orders after filtering');

          if (activeOrderIds.isEmpty) {
            debugPrint('🚗 No active orders after filtering');
            return <Order>[];
          }

          // Fetch full order data with order_items for the filtered orders
          debugPrint('🚗 Active: Fetching full data for order IDs: $activeOrderIds');
          final fullResponse = await supabase
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
              .inFilter('id', activeOrderIds)
              .order('created_at', ascending: false);

          debugPrint('🚗 Fetched full data for ${fullResponse.length} active orders');
          final orders = fullResponse.map((json) => Order.fromJson(json)).toList();

          // Debug order items count
          for (final order in orders) {
            debugPrint('🚗 Active order ${order.orderNumber}: ${order.items.length} items, status: ${order.status}');
          }

          return orders;
        });
  } catch (e) {
    debugPrint('🚗 Error streaming active orders: $e');
    yield <Order>[];
  }
});

/// Provider for order history (delivered and cancelled orders)
final historyOrdersStreamProvider = StreamProvider.autoDispose<List<Order>>((ref) async* {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    debugPrint('🚗 History: User is not a driver, role: ${authState.user?.role}');
    yield <Order>[];
    return;
  }

  final userId = authState.user?.id;
  if (userId == null) {
    debugPrint('🚗 History: No user ID found');
    yield <Order>[];
    return;
  }

  try {
    final supabase = Supabase.instance.client;

    debugPrint('🚗 Streaming order history for auth user: $userId');

    // First, get the driver ID for this user
    final driverResponse = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (driverResponse == null) {
      debugPrint('🚗 History: No driver profile found for user: $userId');
      yield <Order>[];
      return;
    }

    final driverId = driverResponse['id'] as String;
    debugPrint('🚗 History: Found driver ID: $driverId for user: $userId');

    // First get initial data with order_items
    final completedStatuses = ['delivered', 'cancelled'];
    debugPrint('🚗 History: Querying orders with assigned_driver_id: $driverId, statuses: $completedStatuses');

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
        .eq('assigned_driver_id', driverId)
        .inFilter('status', completedStatuses)
        .order('created_at', ascending: false)
        .limit(50); // Limit history to recent orders

    debugPrint('🚗 Initial history orders loaded: ${initialResponse.length} orders');
    final initialOrders = initialResponse.map((json) => Order.fromJson(json)).toList();

    // Debug order items count
    for (final order in initialOrders) {
      debugPrint('🚗 History order ${order.orderNumber}: ${order.items.length} items, status: ${order.status}');
    }

    yield initialOrders;

    // Then listen for real-time updates
    debugPrint('🚗 History: Setting up real-time stream for driver: $driverId');
    yield* supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('assigned_driver_id', driverId)
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          debugPrint('🚗 History orders stream update: ${data.length} total orders for driver: $driverId');
          // Filter for completed statuses
          final historyOrderIds = data
              .where((json) => completedStatuses.contains(json['status']))
              .take(50) // Limit to recent orders
              .map((json) => json['id'] as String)
              .toList();

          debugPrint('🚗 History: Found ${historyOrderIds.length} completed orders after filtering');

          if (historyOrderIds.isEmpty) {
            debugPrint('🚗 No history orders after filtering');
            return <Order>[];
          }

          // Fetch full order data with order_items for the filtered orders
          debugPrint('🚗 History: Fetching full data for order IDs: $historyOrderIds');
          final fullResponse = await supabase
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
              .inFilter('id', historyOrderIds)
              .order('created_at', ascending: false);

          debugPrint('🚗 Fetched full data for ${fullResponse.length} history orders');
          final orders = fullResponse.map((json) => Order.fromJson(json)).toList();

          // Debug order items count
          for (final order in orders) {
            debugPrint('🚗 History order ${order.orderNumber}: ${order.items.length} items, status: ${order.status}');
          }

          return orders;
        });
  } catch (e) {
    debugPrint('Error streaming order history: $e');
    yield <Order>[];
  }
});

/// Provider for accepting an order with enhanced debugging and race condition handling
final acceptOrderProvider = FutureProvider.family<bool, String>((ref, orderId) async {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    DriverWorkflowLogger.logError(
      operation: 'Order Acceptance',
      error: 'Only drivers can accept orders',
      orderId: orderId,
      context: 'PROVIDER',
    );
    throw Exception('Only drivers can accept orders');
  }

  final userId = authState.user?.id;
  if (userId == null) {
    DriverWorkflowLogger.logError(
      operation: 'Order Acceptance',
      error: 'User not authenticated',
      orderId: orderId,
      context: 'PROVIDER',
    );
    throw Exception('User not authenticated');
  }

  final startTime = DateTime.now();

  try {
    final supabase = Supabase.instance.client;

    DriverWorkflowLogger.logDatabaseOperation(
      operation: 'ORDER_ACCEPTANCE_START',
      orderId: orderId,
      data: {'user_id': userId},
      context: 'PROVIDER',
    );

    // First, get the driver ID and validate current status
    final driverResponse = await supabase
        .from('drivers')
        .select('id, is_active, status, current_delivery_status')
        .eq('user_id', userId)
        .single();

    final driverId = driverResponse['id'] as String;
    final isActive = driverResponse['is_active'] as bool;
    final currentDriverStatus = driverResponse['status'] as String;
    final currentDeliveryStatus = driverResponse['current_delivery_status'] as String?;

    DriverWorkflowLogger.logValidation(
      validationType: 'Driver Availability Check',
      isValid: isActive && currentDriverStatus == 'online',
      orderId: orderId,
      context: 'PROVIDER',
      reason: 'Active: $isActive, Status: $currentDriverStatus, Delivery Status: $currentDeliveryStatus',
    );

    if (!isActive) {
      throw Exception('Driver account is not active');
    }

    // Validate driver is available for new orders
    if (currentDriverStatus == 'on_delivery' && currentDeliveryStatus != null) {
      throw Exception('Driver is already on a delivery and cannot accept new orders');
    }

    DriverWorkflowLogger.logDatabaseOperation(
      operation: 'ORDER_ASSIGNMENT_ATTEMPT',
      orderId: orderId,
      data: {
        'driver_id': driverId,
        'from_status': 'ready',
        'to_status': 'assigned',
      },
      context: 'PROVIDER',
    );

    // ATOMIC OPERATION: Update order with assigned driver and status
    // Use conditional update to prevent race conditions
    final updateResponse = await supabase
        .from('orders')
        .update({
          'assigned_driver_id': driverId,
          'status': 'assigned',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId)
        .eq('status', 'ready') // Only accept if still ready
        .isFilter('assigned_driver_id', null) // Only if no driver assigned
        .eq('delivery_method', 'own_fleet') // Additional safety check
        .select();

    if (updateResponse.isEmpty) {
      DriverWorkflowLogger.logError(
        operation: 'Order Assignment',
        error: 'Order may have already been assigned to another driver or is no longer available',
        orderId: orderId,
        context: 'PROVIDER',
      );
      throw Exception('Order may have already been assigned to another driver or is no longer available');
    }

    DriverWorkflowLogger.logDatabaseOperation(
      operation: 'ORDER_ASSIGNMENT_SUCCESS',
      orderId: orderId,
      isSuccess: true,
      data: updateResponse.first,
      context: 'PROVIDER',
    );

    // CRITICAL: Update driver's status in a separate operation
    // This ensures proper workflow state synchronization
    await supabase
        .from('drivers')
        .update({
          'status': 'on_delivery',
          'current_delivery_status': 'assigned', // Initialize workflow
          'last_seen': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', driverId);

    final duration = DateTime.now().difference(startTime);
    DriverWorkflowLogger.logPerformance(
      operation: 'Order Acceptance',
      duration: duration,
      orderId: orderId,
      context: 'PROVIDER',
    );

    DriverWorkflowLogger.logStatusTransition(
      orderId: orderId,
      fromStatus: 'ready',
      toStatus: 'assigned',
      driverId: driverId,
      context: 'PROVIDER',
    );

    return true;
  } catch (e) {
    final duration = DateTime.now().difference(startTime);
    DriverWorkflowLogger.logError(
      operation: 'Order Acceptance',
      error: e.toString(),
      orderId: orderId,
      context: 'PROVIDER',
    );
    DriverWorkflowLogger.logPerformance(
      operation: 'Order Acceptance (Failed)',
      duration: duration,
      orderId: orderId,
      context: 'PROVIDER',
    );
    throw Exception('Failed to accept order: $e');
  }
});

/// Enhanced provider for updating order status with granular driver workflow support
final updateOrderStatusProvider = FutureProvider.family<bool, ({String orderId, String status})>((ref, params) async {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    throw Exception('Only drivers can update order status');
  }

  final userId = authState.user?.id;
  if (userId == null) {
    throw Exception('User not authenticated');
  }

  try {
    final supabase = Supabase.instance.client;

    debugPrint('🚗 [PROVIDER] Updating order status: ${params.orderId} to ${params.status}');

    final updateData = <String, dynamic>{
      'status': params.status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Add timestamp fields based on granular driver workflow statuses
    switch (params.status) {
      case 'assigned':
        // Driver has been assigned to the order
        debugPrint('🚗 [PROVIDER] Driver assigned to order');
        break;
      case 'on_route_to_vendor':
        debugPrint('🚗 [PROVIDER] Driver en route to restaurant');
        break;
      case 'arrived_at_vendor':
        debugPrint('🚗 [PROVIDER] Driver arrived at restaurant');
        break;
      case 'picked_up':
        debugPrint('🚗 [PROVIDER] Order picked up from restaurant');
        updateData['out_for_delivery_at'] = DateTime.now().toIso8601String();
        break;
      case 'on_route_to_customer':
        debugPrint('🚗 [PROVIDER] Driver en route to customer');
        break;
      case 'arrived_at_customer':
        debugPrint('🚗 [PROVIDER] Driver arrived at customer location');
        break;
      case 'delivered':
        debugPrint('🚗 [PROVIDER] Order delivered successfully');
        updateData['actual_delivery_time'] = DateTime.now().toIso8601String();
        break;
      // Legacy status support
      case 'preparing':
        updateData['preparation_started_at'] = DateTime.now().toIso8601String();
        break;
      case 'ready':
        updateData['ready_at'] = DateTime.now().toIso8601String();
        break;
      case 'out_for_delivery':
        updateData['out_for_delivery_at'] = DateTime.now().toIso8601String();
        break;
    }

    debugPrint('🚗 [PROVIDER] Updating database with data: $updateData');

    await supabase
        .from('orders')
        .update(updateData)
        .eq('id', params.orderId)
        .eq('assigned_driver_id', userId); // Only update own orders

    debugPrint('🚗 [PROVIDER] Order status updated successfully: ${params.orderId} → ${params.status}');
    return true;
  } catch (e) {
    debugPrint('❌ [PROVIDER] Error updating order status: $e');
    throw Exception('Failed to update order status: $e');
  }
});

/// Enhanced provider specifically for driver workflow status updates with validation
final updateDriverWorkflowStatusProvider = FutureProvider.family<bool, ({String orderId, String fromStatus, String toStatus})>((ref, params) async {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    throw Exception('Only drivers can update order status');
  }

  final userId = authState.user?.id;
  if (userId == null) {
    throw Exception('User not authenticated');
  }

  try {
    final supabase = Supabase.instance.client;

    DriverWorkflowLogger.logStatusTransition(
      orderId: params.orderId,
      fromStatus: params.fromStatus,
      toStatus: params.toStatus,
      driverId: userId,
      context: 'PROVIDER',
    );

    // Validate the status transition using the state machine
    final isValidTransition = _validateDriverStatusTransition(params.fromStatus, params.toStatus);

    DriverWorkflowLogger.logValidation(
      validationType: 'Status Transition',
      isValid: isValidTransition,
      orderId: params.orderId,
      reason: isValidTransition ? null : 'Invalid transition: ${params.fromStatus} → ${params.toStatus}',
      context: 'PROVIDER',
    );

    if (!isValidTransition) {
      throw Exception('Invalid status transition: ${params.fromStatus} → ${params.toStatus}');
    }

    final updateData = <String, dynamic>{
      'status': params.toStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Add workflow-specific timestamp tracking
    switch (params.toStatus) {
      case 'on_route_to_vendor':
        updateData['driver_started_route_at'] = DateTime.now().toIso8601String();
        break;
      case 'arrived_at_vendor':
        updateData['driver_arrived_vendor_at'] = DateTime.now().toIso8601String();
        break;
      case 'picked_up':
        updateData['driver_picked_up_at'] = DateTime.now().toIso8601String();
        updateData['out_for_delivery_at'] = DateTime.now().toIso8601String();
        break;
      case 'on_route_to_customer':
        updateData['driver_started_delivery_at'] = DateTime.now().toIso8601String();
        break;
      case 'arrived_at_customer':
        updateData['driver_arrived_customer_at'] = DateTime.now().toIso8601String();
        break;
      case 'delivered':
        updateData['actual_delivery_time'] = DateTime.now().toIso8601String();
        updateData['driver_completed_at'] = DateTime.now().toIso8601String();
        break;
    }

    DriverWorkflowLogger.logDatabaseOperation(
      operation: 'UPDATE_WORKFLOW',
      orderId: params.orderId,
      data: updateData,
      context: 'PROVIDER',
    );

    final stopwatch = Stopwatch()..start();

    await supabase
        .from('orders')
        .update(updateData)
        .eq('id', params.orderId)
        .eq('assigned_driver_id', userId)
        .eq('status', params.fromStatus); // Ensure current status matches expected

    stopwatch.stop();

    DriverWorkflowLogger.logPerformance(
      operation: 'Database Update',
      duration: stopwatch.elapsed,
      orderId: params.orderId,
      context: 'PROVIDER',
    );

    DriverWorkflowLogger.logDatabaseOperation(
      operation: 'UPDATE_WORKFLOW',
      orderId: params.orderId,
      data: {'status': params.toStatus},
      context: 'PROVIDER',
      isSuccess: true,
    );

    return true;
  } catch (e) {
    DriverWorkflowLogger.logError(
      operation: 'Update Driver Workflow Status',
      error: e.toString(),
      orderId: params.orderId,
      context: 'PROVIDER',
    );
    throw Exception('Failed to update driver workflow status: $e');
  }
});

/// Validate driver status transitions based on workflow rules with legacy status support
bool _validateDriverStatusTransition(String fromStatus, String toStatus) {
  debugPrint('🔍 [TRANSITION-VALIDATION] Validating status transition');
  debugPrint('🔍 [TRANSITION-VALIDATION] From: $fromStatus → To: $toStatus');

  // Normalize legacy statuses to granular workflow statuses
  String normalizedFromStatus = _normalizeLegacyStatus(fromStatus);
  String normalizedToStatus = _normalizeLegacyStatus(toStatus);

  debugPrint('🔍 [TRANSITION-VALIDATION] Normalized: $normalizedFromStatus → $normalizedToStatus');

  const validTransitions = {
    'assigned': ['on_route_to_vendor', 'cancelled'],
    'on_route_to_vendor': ['arrived_at_vendor', 'cancelled'],
    'arrived_at_vendor': ['picked_up', 'cancelled'],
    'picked_up': ['on_route_to_customer', 'cancelled'],
    'on_route_to_customer': ['arrived_at_customer', 'cancelled'],
    'arrived_at_customer': ['delivered', 'cancelled'],
    'delivered': [], // Terminal state
    'cancelled': [], // Terminal state
  };

  final allowedTransitions = validTransitions[normalizedFromStatus] ?? [];
  final isValid = allowedTransitions.contains(normalizedToStatus);

  debugPrint('🔍 [TRANSITION-VALIDATION] Allowed transitions from $normalizedFromStatus: $allowedTransitions');
  debugPrint('🔍 [TRANSITION-VALIDATION] Target status $normalizedToStatus is ${isValid ? 'ALLOWED' : 'NOT ALLOWED'}');
  debugPrint('${isValid ? '✅' : '❌'} [TRANSITION-VALIDATION] Transition $fromStatus → $toStatus: ${isValid ? 'VALID' : 'INVALID'}');

  if (!isValid) {
    debugPrint('⚠️ [TRANSITION-VALIDATION] Invalid transition detected - this may indicate a workflow issue');
  }

  return isValid;
}

/// Normalize legacy status strings to granular workflow statuses
String _normalizeLegacyStatus(String status) {
  switch (status.toLowerCase()) {
    // Legacy status mappings
    case 'out_for_delivery': // snake_case
    case 'outfordelivery': // lowercase and camelCase converted to lowercase
      return 'picked_up'; // Map legacy status to picked_up so driver can navigate to customer
    case 'preparing':
      return 'on_route_to_vendor'; // Map preparing to on route to vendor
    case 'ready':
      return 'arrived_at_vendor'; // Map ready to arrived at vendor
    case 'confirmed':
      return 'assigned'; // Map confirmed to assigned
    // Granular statuses (already normalized)
    case 'assigned':
    case 'on_route_to_vendor':
    case 'arrived_at_vendor':
    case 'picked_up':
    case 'on_route_to_customer':
    case 'arrived_at_customer':
    case 'delivered':
    case 'cancelled':
      return status.toLowerCase();
    default:
      debugPrint('🚗 [VALIDATION] Unknown status "$status", treating as picked_up for legacy compatibility');
      return 'picked_up'; // Default to picked_up for unknown statuses
  }
}
