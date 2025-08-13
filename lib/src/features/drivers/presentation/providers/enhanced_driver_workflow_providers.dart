import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../drivers/data/models/driver_order.dart';
import '../../../../data/models/user_role.dart';
import '../../data/services/enhanced_workflow_integration_service.dart';
import '../../data/services/pickup_confirmation_service.dart';
import '../../data/services/delivery_confirmation_service.dart';

/// Enhanced workflow integration service provider
final enhancedWorkflowIntegrationServiceProvider = Provider<EnhancedWorkflowIntegrationService>((ref) {
  return EnhancedWorkflowIntegrationService();
});

/// Service providers for testing compatibility
final pickupConfirmationServiceProvider = Provider<PickupConfirmationService>((ref) {
  return PickupConfirmationService();
});

final deliveryConfirmationServiceProvider = Provider<DeliveryConfirmationService>((ref) {
  return DeliveryConfirmationService();
});

/// Enhanced current driver order provider with granular workflow support
/// Fixed to ensure proper execution and avoid caching issues
final enhancedCurrentDriverOrderProvider = StreamProvider.autoDispose<DriverOrder?>((ref) async* {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  debugPrint('🚗 [ENHANCED-WORKFLOW] [$timestamp] Provider called - starting enhanced current driver order provider');

  // Watch auth state to ensure provider rebuilds when auth changes
  final authState = ref.watch(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    debugPrint('🚗 [ENHANCED-WORKFLOW] [$timestamp] User is not a driver, role: ${authState.user?.role}');
    yield null;
    return;
  }

  final userId = authState.user?.id;
  if (userId == null) {
    debugPrint('🚗 [ENHANCED-WORKFLOW] [$timestamp] User ID is null');
    yield null;
    return;
  }

  debugPrint('🚗 [ENHANCED-WORKFLOW] [$timestamp] Starting provider for user: $userId');

  try {
    final supabase = Supabase.instance.client;

    // Force provider to always execute by adding a unique identifier
    debugPrint('🚗 [ENHANCED-WORKFLOW] [$timestamp] Provider execution ID: ${DateTime.now().microsecondsSinceEpoch}');
    debugPrint('🚗 [ENHANCED-WORKFLOW] [$timestamp] Streaming current driver order with granular status');

    // First get the driver ID from the user ID
    final driverProfile = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (driverProfile == null) {
      debugPrint('🚗 [ENHANCED-WORKFLOW] No driver profile found for user $userId');
      yield null;
      return;
    }

    final driverId = driverProfile['id'] as String?;
    if (driverId == null) {
      debugPrint('🚗 [ENHANCED-WORKFLOW] Driver profile found but ID is null');
      yield null;
      return;
    }

    debugPrint('🚗 [ENHANCED-WORKFLOW] Found driver ID: $driverId for user: $userId');
    debugPrint('🚗 [ENHANCED-WORKFLOW] Searching for orders assigned to driver: $driverId');

    // Get initial current order using driver ID
    // For granular workflow, we need to get orders assigned to this driver
    // regardless of order status, since granular status is tracked in drivers table
    debugPrint('🚗 [ENHANCED-WORKFLOW] Executing simplified query to fix regression...');

    // TEMPORARY FIX: Use simplified query to resolve regression
    List<Map<String, dynamic>> initialResponse;
    try {
      debugPrint('🚗 [ENHANCED-WORKFLOW] About to execute Supabase query...');
      initialResponse = await supabase
          .from('orders')
          .select('''
            *,
            order_items:order_items(
              *,
              menu_item:menu_items(
                id,
                name,
                image_url,
                base_price
              )
            ),
            vendors:vendors(
              business_name,
              business_address
            ),
            drivers:drivers(
              id,
              current_delivery_status
            )
          ''')
          .eq('assigned_driver_id', driverId)
          .inFilter('status', [
            'assigned',
            'on_route_to_vendor',
            'arrived_at_vendor',
            'picked_up',
            'on_route_to_customer',
            'arrived_at_customer',
            'out_for_delivery', // Include legacy status for real-time updates
            'ready' // Include ready status for order pickup
          ])
          .order('created_at', ascending: false)
          .limit(1);
      debugPrint('🚗 [ENHANCED-WORKFLOW] Query executed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [ENHANCED-WORKFLOW] Query failed with error: $e');
      debugPrint('❌ [ENHANCED-WORKFLOW] Stack trace: $stackTrace');
      yield null;
      return;
    }

    debugPrint('🚗 [ENHANCED-WORKFLOW] Initial query returned ${initialResponse.length} orders');
    debugPrint('🚗 [ENHANCED-WORKFLOW] Query filter: assigned_driver_id = $driverId, status in [ready, out_for_delivery, on_route_to_customer, ...]');

    if (initialResponse.isNotEmpty) {
      debugPrint('🚗 [ENHANCED-WORKFLOW] Raw order data: ${initialResponse.first}');

      // Get the raw order data
      final orderData = Map<String, dynamic>.from(initialResponse.first);

      // Check if driver has granular delivery status
      final driverDeliveryStatus = orderData['drivers']?['current_delivery_status'];
      final orderStatus = orderData['status'];
      debugPrint('🔍 [STATUS-CALCULATION] Analyzing status for effective status calculation');
      debugPrint('🔍 [STATUS-CALCULATION] Order status: $orderStatus');
      debugPrint('🔍 [STATUS-CALCULATION] Driver delivery status: $driverDeliveryStatus');

      // IMPROVED LOGIC: Use driver delivery status only if it's more advanced than order status
      // This prevents using stale driver status from previous orders
      String effectiveStatus = orderStatus;

      if (driverDeliveryStatus != null && driverDeliveryStatus.toString().isNotEmpty) {
        debugPrint('🔍 [STATUS-CALCULATION] Driver delivery status is not null/empty, checking compatibility');
        // Only use driver delivery status if it makes sense for the current order status
        if (_shouldUseDriverDeliveryStatus(orderStatus, driverDeliveryStatus.toString())) {
          debugPrint('✅ [STATUS-CALCULATION] Using driver delivery status: $driverDeliveryStatus (more advanced than order status)');
          effectiveStatus = driverDeliveryStatus.toString();
        } else {
          debugPrint('⚠️ [STATUS-CALCULATION] Ignoring driver delivery status: $driverDeliveryStatus (not compatible with order status: $orderStatus)');
          debugPrint('⚠️ [STATUS-CALCULATION] This could indicate stale data from a previous order');
        }
      } else {
        debugPrint('🔍 [STATUS-CALCULATION] Driver delivery status is null/empty, using order status');
      }

      debugPrint('🎯 [STATUS-CALCULATION] Final effective status: $effectiveStatus');

      orderData['status'] = effectiveStatus;

      final initialOrder = _transformToDriverOrder(orderData, orderData['status']);
      debugPrint('🚗 [ENHANCED-WORKFLOW] Current order ${initialOrder.orderNumber}: ${initialOrder.status.displayName}');
      debugPrint('🚗 [ENHANCED-WORKFLOW] Order ID: ${initialOrder.id}, Status: ${initialOrder.status.value}');
      yield initialOrder;
    } else {
      debugPrint('🚗 [ENHANCED-WORKFLOW] No current orders found for driver $driverId');
      debugPrint('🚗 [ENHANCED-WORKFLOW] This could mean:');
      debugPrint('🚗 [ENHANCED-WORKFLOW] 1. No orders assigned to this driver');
      debugPrint('🚗 [ENHANCED-WORKFLOW] 2. Orders exist but status not in filter list');
      debugPrint('🚗 [ENHANCED-WORKFLOW] 3. Driver ID mismatch in database');
      yield null;
    }

    // Stream real-time updates with enhanced status tracking
    yield* supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('assigned_driver_id', driverId)
        .asyncMap((data) async {
          debugPrint('🚗 [ENHANCED-WORKFLOW] Order stream update: ${data.length} orders');
          
          // Filter for active granular statuses
          final activeStatuses = [
            'assigned',
            'on_route_to_vendor',
            'arrived_at_vendor',
            'picked_up',
            'on_route_to_customer',
            'arrived_at_customer',
            'out_for_delivery' // Include legacy status for real-time updates
          ];
          
          final activeOrders = data.where((json) =>
            activeStatuses.contains(json['status'])
          ).toList();
          
          debugPrint('🚗 [ENHANCED-WORKFLOW] Filtered active orders: ${activeOrders.length} orders');

          if (activeOrders.isEmpty) return null;

          final orderId = activeOrders.first['id'] as String;

          // Fetch full order data with all relationships
          final fullResponse = await supabase
              .from('orders')
              .select('''
                id,
                order_id:id,
                order_number,
                status,
                vendor_id,
                customer_id,
                sales_agent_id,
                delivery_date,
                delivery_address,
                subtotal,
                delivery_fee,
                sst_amount,
                total_amount,
                commission_amount,
                payment_status,
                payment_method,
                payment_reference,
                notes,
                metadata,
                created_at,
                updated_at,
                estimated_delivery_time,
                actual_delivery_time,
                preparation_started_at,
                ready_at,
                out_for_delivery_at,
                delivery_zone,
                special_instructions,
                contact_phone,
                delivery_proof_id,
                assigned_driver_id,
                order_items:order_items(
                  id,
                  quantity,
                  unit_price,
                  total_price,
                  customizations,
                  notes,
                  menu_item:menu_items!order_items_menu_item_id_fkey(
                    id,
                    name,
                    image_url,
                    base_price
                  )
                ),
                vendors:vendors!orders_vendor_id_fkey(
                  business_name,
                  business_address
                ),
                drivers:drivers!orders_assigned_driver_id_fkey(
                  id,
                  current_delivery_status
                )
              ''')
              .eq('id', orderId)
              .single();

          // Get the raw order data and apply driver delivery status
          final orderData = Map<String, dynamic>.from(fullResponse);

          // Check if driver has granular delivery status
          final driverDeliveryStatus = orderData['drivers']?['current_delivery_status'];
          final orderStatus = orderData['status'];
          debugPrint('🔍 [STREAM-STATUS-CALCULATION] Real-time status update received');
          debugPrint('🔍 [STREAM-STATUS-CALCULATION] Order status: $orderStatus');
          debugPrint('🔍 [STREAM-STATUS-CALCULATION] Driver delivery status: $driverDeliveryStatus');

          // IMPROVED LOGIC: Use driver delivery status only if it's more advanced than order status
          String effectiveStatus = orderStatus;

          if (driverDeliveryStatus != null && driverDeliveryStatus.toString().isNotEmpty) {
            debugPrint('🔍 [STREAM-STATUS-CALCULATION] Driver delivery status present, checking compatibility');
            if (_shouldUseDriverDeliveryStatus(orderStatus, driverDeliveryStatus.toString())) {
              debugPrint('✅ [STREAM-STATUS-CALCULATION] Using driver delivery status: $driverDeliveryStatus (more advanced)');
              effectiveStatus = driverDeliveryStatus.toString();
            } else {
              debugPrint('⚠️ [STREAM-STATUS-CALCULATION] Ignoring driver delivery status: $driverDeliveryStatus (incompatible with order status)');
            }
          } else {
            debugPrint('🔍 [STREAM-STATUS-CALCULATION] No driver delivery status, using order status');
          }

          debugPrint('🎯 [STREAM-STATUS-CALCULATION] Final effective status: $effectiveStatus');

          orderData['status'] = effectiveStatus;

          final order = _transformToDriverOrder(orderData, orderData['status']);
          debugPrint('🚗 [ENHANCED-WORKFLOW] Current order ${order.orderNumber}: ${order.status.displayName}');
          debugPrint('🚗 [ENHANCED-WORKFLOW] Raw database status: ${fullResponse['status']}');
          debugPrint('🚗 [ENHANCED-WORKFLOW] Mapped driver status: ${order.status.value}');
          return order;
        });
  } catch (e, stackTrace) {
    debugPrint('❌ [ENHANCED-WORKFLOW] Error streaming current driver order: $e');
    debugPrint('❌ [ENHANCED-WORKFLOW] Stack trace: $stackTrace');
    yield null;
  }
});

/// Enhanced available orders provider with better filtering and performance tuning
final enhancedAvailableOrdersProvider = StreamProvider.autoDispose<List<DriverOrder>>((ref) async* {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    yield [];
    return;
  }

  try {
    final supabase = Supabase.instance.client;

    final ts = DateTime.now().toIso8601String();
    debugPrint('🚗 [ENHANCED-WORKFLOW][$ts] Streaming available orders (optimized)');

    // Get initial available orders with minimal columns and tight filters
    final initialSw = Stopwatch()..start();
    final initialResponse = await supabase
        .from('orders')
        .select('''
          id,
          order_number,
          status,
          vendor_id,
          delivery_address,
          total_amount,
          payment_method,
          created_at,
          vendors:vendors!orders_vendor_id_fkey(
            business_name,
            business_address
          ),
          order_items:order_items(id)
        ''')
        .eq('status', 'ready')
        .eq('delivery_method', 'own_fleet')
        .isFilter('assigned_driver_id', null)
        .order('created_at', ascending: true)
        .limit(20);
    initialSw.stop();

    debugPrint('🚗 [ENHANCED-WORKFLOW][$ts] Initial available orders: ${initialResponse.length} orders (took: ${initialSw.elapsedMilliseconds}ms)');
    final initialOrders = initialResponse
        .map((json) => _transformToDriverOrder(json, json['status']))
        .toList();
    yield initialOrders;

    // Stream real-time updates for available orders — pre-filter on server to reduce payload
    yield* supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          final updateTs = DateTime.now().toIso8601String();
          debugPrint('🚗 [ENHANCED-WORKFLOW][$updateTs] Available orders stream update: ${data.length} rows');

          if (data.isEmpty) return <DriverOrder>[];

          // Filter for unassigned orders client-side (stream builder lacks isFilter)
          final unassigned = data.where((row) => row['assigned_driver_id'] == null).toList();
          if (unassigned.isEmpty) return <DriverOrder>[];

          // Limit number processed per update to prevent spikes
          final limited = unassigned.take(25).toList();
          final ids = limited.map((e) => e['id'] as String).toList();

          // Fetch details in a single batched query
          try {
            final sw = Stopwatch()..start();
            final fullResponse = await supabase
                .from('orders')
                .select('''
                  id,
                  order_number,
                  status,
                  vendor_id,
                  delivery_address,
                  total_amount,
                  payment_method,
                  created_at,
                  vendors:vendors!orders_vendor_id_fkey(
                    business_name,
                    business_address
                  )
                ''')
                .inFilter('id', ids)
                .order('created_at', ascending: true);
            sw.stop();

            final orders = fullResponse
                .map((json) => _transformToDriverOrder(json, json['status']))
                .toList();

            debugPrint('🚗 [ENHANCED-WORKFLOW][$updateTs] Batched fetch for ${ids.length} ids returned ${orders.length} orders (took: ${sw.elapsedMilliseconds}ms)');
            return orders;
          } catch (e, st) {
            debugPrint('❌ [ENHANCED-WORKFLOW] Error fetching batched order details: $e');
            debugPrint('❌ [ENHANCED-WORKFLOW] Stack: $st');
            return <DriverOrder>[];
          }
        });
  } catch (e) {
    debugPrint('❌ [ENHANCED-WORKFLOW] Error streaming available orders: $e');
    yield [];
  }
});

/// Enhanced earnings provider with granular workflow integration
final enhancedTodayEarningsProvider = FutureProvider.autoDispose<EnhancedEarningsData>((ref) async {
  final authState = ref.read(authStateProvider);
  
  if (authState.user?.role != UserRole.driver) {
    return EnhancedEarningsData.empty();
  }

  final userId = authState.user?.id;
  if (userId == null) {
    return EnhancedEarningsData.empty();
  }

  try {
    final supabase = Supabase.instance.client;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    debugPrint('🚗 [ENHANCED-WORKFLOW] Fetching enhanced today\'s earnings');
    
    // Get driver ID
    final driverResponse = await supabase
        .from('drivers')
        .select('id')
        .eq('user_id', userId)
        .single();
    
    final driverId = driverResponse['id'] as String;
    
    // Get today's earnings from enhanced earnings table
    final earningsResponse = await supabase
        .from('driver_earnings')
        .select('*')
        .eq('driver_id', driverId)
        .gte('created_at', startOfDay.toIso8601String())
        .lt('created_at', endOfDay.toIso8601String());

    // Get today's completed orders with granular status tracking
    final ordersResponse = await supabase
        .from('orders')
        .select('id, total_amount, status, actual_delivery_time')
        .eq('assigned_driver_id', userId)
        .eq('status', 'delivered')
        .gte('actual_delivery_time', startOfDay.toIso8601String())
        .lt('actual_delivery_time', endOfDay.toIso8601String());

    // Calculate enhanced earnings data
    double totalGrossEarnings = 0.0;
    double totalNetEarnings = 0.0;
    double totalBonuses = 0.0;
    double totalDeductions = 0.0;
    
    for (final earning in earningsResponse) {
      totalGrossEarnings += (earning['gross_earnings'] as num?)?.toDouble() ?? 0.0;
      totalNetEarnings += (earning['net_earnings'] as num?)?.toDouble() ?? 0.0;
      totalBonuses += (earning['completion_bonus'] as num?)?.toDouble() ?? 0.0;
      totalBonuses += (earning['peak_hour_bonus'] as num?)?.toDouble() ?? 0.0;
      totalBonuses += (earning['rating_bonus'] as num?)?.toDouble() ?? 0.0;
      totalBonuses += (earning['other_bonuses'] as num?)?.toDouble() ?? 0.0;
      totalDeductions += (earning['deductions'] as num?)?.toDouble() ?? 0.0;
    }

    return EnhancedEarningsData(
      totalGrossEarnings: totalGrossEarnings,
      totalNetEarnings: totalNetEarnings,
      totalBonuses: totalBonuses,
      totalDeductions: totalDeductions,
      orderCount: ordersResponse.length,
      averageOrderValue: ordersResponse.isNotEmpty 
          ? ordersResponse.fold<double>(0.0, (sum, order) => sum + ((order['total_amount'] as num?)?.toDouble() ?? 0.0)) / ordersResponse.length
          : 0.0,
    );

  } catch (e) {
    debugPrint('❌ [ENHANCED-WORKFLOW] Error fetching enhanced earnings: $e');
    return EnhancedEarningsData.empty();
  }
});

/// Provider for order workflow status tracking
final orderWorkflowStatusProvider = FutureProvider.family<WorkflowStatusData, String>((ref, orderId) async {
  try {
    final supabase = Supabase.instance.client;
    
    // Get pickup confirmation status
    final pickupConfirmation = await supabase
        .from('pickup_confirmations')
        .select('*')
        .eq('order_id', orderId)
        .limit(1);

    // Get delivery confirmation status
    final deliveryConfirmation = await supabase
        .from('delivery_confirmations')
        .select('*')
        .eq('order_id', orderId)
        .limit(1);

    // Get order tracking events
    final trackingEvents = await supabase
        .from('order_tracking')
        .select('*')
        .eq('order_id', orderId)
        .order('updated_at', ascending: true);

    return WorkflowStatusData(
      hasPickupConfirmation: pickupConfirmation.isNotEmpty,
      hasDeliveryConfirmation: deliveryConfirmation.isNotEmpty,
      trackingEvents: trackingEvents,
    );

  } catch (e) {
    debugPrint('❌ [ENHANCED-WORKFLOW] Error fetching workflow status: $e');
    return WorkflowStatusData.empty();
  }
});

/// Enhanced earnings data model
class EnhancedEarningsData {
  final double totalGrossEarnings;
  final double totalNetEarnings;
  final double totalBonuses;
  final double totalDeductions;
  final int orderCount;
  final double averageOrderValue;

  const EnhancedEarningsData({
    required this.totalGrossEarnings,
    required this.totalNetEarnings,
    required this.totalBonuses,
    required this.totalDeductions,
    required this.orderCount,
    required this.averageOrderValue,
  });

  factory EnhancedEarningsData.empty() => const EnhancedEarningsData(
    totalGrossEarnings: 0.0,
    totalNetEarnings: 0.0,
    totalBonuses: 0.0,
    totalDeductions: 0.0,
    orderCount: 0,
    averageOrderValue: 0.0,
  );
}

/// Workflow status data model
class WorkflowStatusData {
  final bool hasPickupConfirmation;
  final bool hasDeliveryConfirmation;
  final List<Map<String, dynamic>> trackingEvents;

  const WorkflowStatusData({
    required this.hasPickupConfirmation,
    required this.hasDeliveryConfirmation,
    required this.trackingEvents,
  });

  factory WorkflowStatusData.empty() => const WorkflowStatusData(
    hasPickupConfirmation: false,
    hasDeliveryConfirmation: false,
    trackingEvents: [],
  );
}

/// Backward compatibility provider aliases - REMOVED TO FIX PROVIDER CONFLICT
/// Use enhancedCurrentDriverOrderProvider directly instead

/// Enhanced driver workflow provider for comprehensive state management
final enhancedDriverWorkflowProvider = StateNotifierProvider<EnhancedDriverWorkflowNotifier, AsyncValue<EnhancedDriverWorkflowState>>((ref) {
  return EnhancedDriverWorkflowNotifier(ref);
});

/// Enhanced driver workflow state
class EnhancedDriverWorkflowState {
  final DriverOrder? currentOrder;
  final bool isLoading;
  final String? errorMessage;

  const EnhancedDriverWorkflowState({
    this.currentOrder,
    required this.isLoading,
    this.errorMessage,
  });

  EnhancedDriverWorkflowState copyWith({
    DriverOrder? currentOrder,
    bool? isLoading,
    String? errorMessage,
  }) {
    return EnhancedDriverWorkflowState(
      currentOrder: currentOrder ?? this.currentOrder,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Enhanced driver workflow notifier
class EnhancedDriverWorkflowNotifier extends StateNotifier<AsyncValue<EnhancedDriverWorkflowState>> {
  final Ref ref;

  EnhancedDriverWorkflowNotifier(this.ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  void _initialize() {
    state = const AsyncValue.data(EnhancedDriverWorkflowState(isLoading: false));
  }

  void updateCurrentOrder(DriverOrder? order) {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(currentOrder: order));
    });
  }

  void setLoading(bool isLoading) {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(isLoading: isLoading));
    });
  }

  void setError(String errorMessage) {
    state.whenData((currentState) {
      state = AsyncValue.data(currentState.copyWith(errorMessage: errorMessage));
    });
  }
}

/// Transform raw database response to DriverOrder model
DriverOrder _transformToDriverOrder(Map<String, dynamic> response, String effectiveStatus) {
  final orderId = response['id']?.toString() ?? '';
  final orderNumber = response['order_number']?.toString() ?? '';

  debugPrint('🔄 [TRANSFORM] Starting transformation for order $orderNumber (ID: ${orderId.substring(0, 8)}...)');
  debugPrint('🔄 [TRANSFORM] Raw database status: $effectiveStatus');
  debugPrint('🔄 [TRANSFORM] Full response keys: ${response.keys.toList()}');

  // Map database status to valid DriverOrderStatus enum value
  String mappedStatus = _mapDatabaseStatusToDriverStatus(effectiveStatus);
  debugPrint('🔄 [TRANSFORM] Mapped status from "$effectiveStatus" to "$mappedStatus"');

  // Parse delivery address safely
  String deliveryAddressStr = '';
  if (response['delivery_address'] != null) {
    final addr = response['delivery_address'];
    if (addr is Map) {
      final parts = <String>[];
      if (addr['street'] != null) parts.add(addr['street'].toString());
      if (addr['city'] != null) parts.add(addr['city'].toString());
      if (addr['state'] != null) parts.add(addr['state'].toString());
      if (addr['postal_code'] != null) parts.add(addr['postal_code'].toString());
      deliveryAddressStr = parts.join(', ');
    } else {
      deliveryAddressStr = addr.toString();
    }
  }

  // Get vendor name from vendors join
  String vendorName = 'Unknown Vendor';
  if (response['vendors'] != null && response['vendors'] is Map) {
    vendorName = response['vendors']['business_name']?.toString() ?? 'Unknown Vendor';
  }

  // Get driver ID from drivers join
  String driverId = '';
  if (response['drivers'] != null && response['drivers'] is Map) {
    driverId = response['drivers']['id']?.toString() ?? '';
  }

  // Create the JSON payload for DriverOrder.fromJson
  final driverOrderJson = {
    'id': orderId,
    'order_id': orderId,
    'order_number': orderNumber,
    'driver_id': driverId,
    'vendor_id': response['vendor_id']?.toString() ?? '',
    'vendor_name': vendorName,
    'customer_id': response['customer_id']?.toString() ?? '',
    'customer_name': 'Unknown Customer', // Not available in current query
    'status': mappedStatus, // Use mapped status instead of raw effectiveStatus
    'priority': 'normal',
    'delivery_details': {
      'pickup_address': response['vendors']?['business_address']?.toString() ?? '',
      'delivery_address': deliveryAddressStr,
      'contact_phone': response['contact_phone']?.toString(),
    },
    'order_earnings': {
      'base_fee': _safeToDouble(response['delivery_fee']),
      'distance_fee': 0.0,
      'time_bonus': 0.0,
      'tip_amount': 0.0,
      'total_earnings': _safeToDouble(response['delivery_fee']),
    },
    'order_items_count': (response['order_items'] as List?)?.length ?? 0,
    'order_total': _safeToDouble(response['total_amount']),
    'payment_method': response['payment_method']?.toString(),
    'requires_cash_collection': false,
    'assigned_at': response['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    'accepted_at': null,
    'started_route_at': null,
    'arrived_at_vendor_at': null,
    'picked_up_at': response['out_for_delivery_at']?.toString(),
    'arrived_at_customer_at': null,
    'delivered_at': response['actual_delivery_time']?.toString(),
    'created_at': response['created_at']?.toString() ?? DateTime.now().toIso8601String(),
    'updated_at': response['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
  };

  debugPrint('🔄 [TRANSFORM] Created JSON payload with status: ${driverOrderJson['status']}');
  debugPrint('🔄 [TRANSFORM] JSON payload keys: ${driverOrderJson.keys.toList()}');

  try {
    final driverOrder = DriverOrder.fromJson(driverOrderJson);
    debugPrint('✅ [TRANSFORM] Successfully created DriverOrder with status: ${driverOrder.status.value}');
    debugPrint('✅ [TRANSFORM] DriverOrder status display name: ${driverOrder.status.displayName}');
    return driverOrder;
  } catch (e, stackTrace) {
    debugPrint('❌ [TRANSFORM] Error creating DriverOrder: $e');
    debugPrint('❌ [TRANSFORM] Stack trace: $stackTrace');
    debugPrint('❌ [TRANSFORM] Problematic JSON: $driverOrderJson');
    rethrow;
  }
}

/// Map database status to valid DriverOrderStatus enum value
/// This ensures that database statuses are properly converted to enum values
/// that can be handled by DriverOrder.fromJson()
String _mapDatabaseStatusToDriverStatus(String databaseStatus) {
  switch (databaseStatus.toLowerCase()) {
    case 'ready':
      // Orders that are ready for pickup should be treated as assigned for driver workflow
      return 'assigned';
    case 'confirmed':
      return 'assigned';
    case 'preparing':
      return 'assigned'; // Restaurant is preparing, driver not involved yet
    case 'assigned':
      return 'assigned';
    case 'on_route_to_vendor':
      return 'on_route_to_vendor';
    case 'arrived_at_vendor':
      return 'arrived_at_vendor';
    case 'picked_up':
      return 'picked_up';
    case 'out_for_delivery':
      return 'picked_up'; // Map legacy status to picked up so driver can navigate to customer
    case 'on_route_to_customer':
      return 'on_route_to_customer';
    case 'arrived_at_customer':
      return 'arrived_at_customer';
    case 'delivered':
      return 'delivered';
    case 'cancelled':
      return 'cancelled';
    case 'failed':
      return 'failed';
    default:
      debugPrint('⚠️ [STATUS-MAPPING] Unknown database status: $databaseStatus, defaulting to assigned');
      return 'assigned'; // Default fallback to prevent enum decode errors
  }
}

/// Safely convert a value to double
double _safeToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

/// Determine if driver delivery status should be used over order status
/// This prevents using stale driver status from previous orders
bool _shouldUseDriverDeliveryStatus(String orderStatus, String driverDeliveryStatus) {
  // Define the workflow progression order
  const statusProgression = [
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'assigned',
    'on_route_to_vendor',
    'arrived_at_vendor',
    'picked_up',
    'on_route_to_customer',
    'arrived_at_customer',
    'delivered',
    'cancelled'
  ];

  final orderIndex = statusProgression.indexOf(orderStatus);
  final driverIndex = statusProgression.indexOf(driverDeliveryStatus);

  // If either status is not found, don't use driver status
  if (orderIndex == -1 || driverIndex == -1) {
    debugPrint('🚗 [STATUS-LOGIC] Unknown status - Order: $orderStatus, Driver: $driverDeliveryStatus');
    return false;
  }

  // STRICT LOGIC: Only use driver status if it's a reasonable progression from order status
  // If driver status is significantly more advanced than order status, it's likely stale
  final maxAllowedGap = 2; // Allow at most 2 steps ahead
  final statusGap = driverIndex - orderIndex;

  // Don't use driver status if:
  // 1. Order is not yet assigned to driver (before 'assigned' status)
  // 2. Driver status is too far ahead (likely from previous order)
  // 3. Driver status is behind order status (shouldn't happen but be safe)
  final shouldUse = orderIndex >= statusProgression.indexOf('assigned') &&
                   statusGap >= 0 &&
                   statusGap <= maxAllowedGap;

  debugPrint('🚗 [STATUS-LOGIC] Order: $orderStatus (index: $orderIndex), Driver: $driverDeliveryStatus (index: $driverIndex)');
  debugPrint('🚗 [STATUS-LOGIC] Status gap: $statusGap, Max allowed: $maxAllowedGap, Use driver status: $shouldUse');

  return shouldUse;
}
