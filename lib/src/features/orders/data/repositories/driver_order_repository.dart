import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/base_repository.dart';
import '../../../drivers/data/models/driver_order.dart';

/// Provider for driver order repository
final driverOrderRepositoryProvider = Provider<DriverOrderRepository>((ref) {
  return DriverOrderRepository();
});

/// Repository for driver order operations
class DriverOrderRepository extends BaseRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get the current authenticated user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get the current user's ID
  String? get currentUserId => currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get authenticated client with error handling
  Future<SupabaseClient> getAuthenticatedClient() async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }
    return _supabase;
  }

  /// Get available orders for driver assignment
  /// Only shows orders if the driver doesn't have an active delivery
  Future<List<DriverOrder>> getAvailableOrders(String driverId) async {
    return executeQuery(() async {
      debugPrint('DriverOrderRepository: Getting available orders for driver: $driverId');

      // Get authenticated client to ensure RLS policies are applied
      final authenticatedClient = await getAuthenticatedClient();

      // Debug: Check current user authentication
      final currentUser = authenticatedClient.auth.currentUser;
      debugPrint('DriverOrderRepository: Current auth user: ${currentUser?.id} (${currentUser?.email})');

      // First check if driver has an active delivery
      final activeOrder = await getDriverActiveOrder(driverId);
      if (activeOrder != null) {
        debugPrint('DriverOrderRepository: Driver has active delivery, returning empty list');
        return <DriverOrder>[];
      }

      debugPrint('DriverOrderRepository: Executing available orders query...');
      debugPrint('DriverOrderRepository: Query filters - status: ready, delivery_method: own_fleet, assigned_driver_id: null');

      try {
        final response = await authenticatedClient
            .from('orders')
            .select('''
              id,
              order_number,
              vendor_name,
              customer_name,
              delivery_address,
              contact_phone,
              total_amount,
              delivery_fee,
              status,
              delivery_method,
              estimated_delivery_time,
              special_instructions,
              created_at,
              vendor:vendors!orders_vendor_id_fkey(
                business_address
              )
            ''')
            .eq('status', 'ready')
            .eq('delivery_method', 'own_fleet')
            .isFilter('assigned_driver_id', null)
            .order('created_at', ascending: true);

        debugPrint('DriverOrderRepository: Query executed successfully');
        debugPrint('DriverOrderRepository: Found ${response.length} available orders');

        // Debug: Log first few orders if any
        if (response.isNotEmpty) {
          debugPrint('DriverOrderRepository: First order: ${response.first['order_number']} - ${response.first['vendor_name']}');
        }

        return response.map((order) => DriverOrder.fromJson({
          ...order,
          'status': 'available',
          'vendor_address': order['vendor']?['business_address'],
          'customer_phone': order['contact_phone'], // Map contact_phone to customer_phone for model compatibility
        })).toList();
      } catch (e) {
        debugPrint('DriverOrderRepository: Error executing available orders query: $e');
        rethrow;
      }
    });
  }

  /// Get orders assigned to a specific driver
  Future<List<DriverOrder>> getDriverOrders(String driverId) async {
    return executeQuery(() async {
      debugPrint('DriverOrderRepository: Getting orders for driver: $driverId');

      // Get authenticated client to ensure RLS policies are applied
      final authenticatedClient = await getAuthenticatedClient();

      final response = await authenticatedClient
          .from('orders')
          .select('''
            id,
            order_number,
            vendor_name,
            customer_name,
            delivery_address,
            contact_phone,
            total_amount,
            delivery_fee,
            status,
            estimated_delivery_time,
            special_instructions,
            created_at,
            assigned_at:updated_at,
            picked_up_at:preparation_started_at,
            delivered_at:actual_delivery_time,
            vendor:vendors!orders_vendor_id_fkey(
              business_address
            ),
            order_items:order_items(
              *,
              menu_item:menu_items!order_items_menu_item_id_fkey(
                id,
                name,
                image_url
              )
            )
          ''')
          .eq('assigned_driver_id', driverId)
          .order('created_at', ascending: false);

      debugPrint('DriverOrderRepository: Found ${response.length} orders for driver');

      return response.map((order) => DriverOrder.fromJson({
        ...order,
        'status': _mapOrderStatusToDriverStatus(order['status']),
        'vendor_address': order['vendor']?['business_address'],
        'customer_phone': order['contact_phone'], // Map contact_phone to customer_phone for model compatibility
      })).toList();
    });
  }

  /// Accept an order assignment
  Future<bool> acceptOrder(String orderId, String driverId) async {
    return executeQuery(() async {
      debugPrint('DriverOrderRepository: Driver $driverId accepting order $orderId');

      try {
        // Check authentication before making the call
        final currentUser = _supabase.auth.currentUser;
        debugPrint('DriverOrderRepository: Current authenticated user: ${currentUser?.id} (${currentUser?.email})');

        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        // Verify authentication context is valid
        debugPrint('DriverOrderRepository: Authenticated user verified: ${currentUser.id}');

        // First verify the driver exists and is active
        final driverCheck = await _supabase
            .from('drivers')
            .select('id, status, is_active')
            .eq('id', driverId)
            .eq('is_active', true)
            .single();

        debugPrint('DriverOrderRepository: Driver check result: $driverCheck');

        if (driverCheck['status'] != 'online') {
          throw Exception('Driver must be online to accept orders. Current status: ${driverCheck['status']}');
        }

        // Check order details before attempting update
        final orderCheck = await _supabase
            .from('orders')
            .select('id, order_number, status, assigned_driver_id, delivery_method, vendor_id, customer_id')
            .eq('id', orderId)
            .single();

        debugPrint('DriverOrderRepository: Order check result: $orderCheck');

        // Validate order is available for assignment
        if (orderCheck['status'] != 'ready') {
          throw Exception('Order is not ready for assignment. Current status: ${orderCheck['status']}');
        }

        if (orderCheck['assigned_driver_id'] != null) {
          throw Exception('Order is already assigned to driver: ${orderCheck['assigned_driver_id']}');
        }

        if (orderCheck['delivery_method'] != 'own_fleet') {
          throw Exception('Order delivery method is not own_fleet: ${orderCheck['delivery_method']}');
        }

        debugPrint('DriverOrderRepository: Order validation passed, attempting assignment...');

        // Update order with driver assignment and status
        // Start with 'assigned' status to follow proper workflow
        final response = await _supabase
            .from('orders')
            .update({
              'assigned_driver_id': driverId,
              'status': 'assigned',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', orderId)
            .eq('status', 'ready') // Only accept orders that are ready
            .isFilter('assigned_driver_id', null) // Ensure order is not already assigned
            .select(); // Add select to get the updated rows back

        final success = response.isNotEmpty;
        debugPrint('DriverOrderRepository: Order acceptance result: $success, updated ${response.length} row(s)');

        if (response.isNotEmpty) {
          debugPrint('DriverOrderRepository: Updated order data: ${response.first}');
        }

        if (success) {
          debugPrint('✅ [ORDER-ACCEPTANCE] Order accepted successfully, initializing driver workflow');
          debugPrint('🔄 [ORDER-ACCEPTANCE] Order: $orderId, Driver: $driverId');
          debugPrint('🔄 [ORDER-ACCEPTANCE] Setting driver status to on_delivery and delivery status to assigned');

          // Update driver status to on_delivery and initialize delivery status
          await _supabase
              .from('drivers')
              .update({
                'status': 'on_delivery',
                'current_delivery_status': 'assigned', // Initialize delivery workflow
                'last_seen': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', driverId);

          debugPrint('✅ [ORDER-ACCEPTANCE] Driver status updated to on_delivery');
          debugPrint('✅ [ORDER-ACCEPTANCE] Driver delivery status initialized to assigned');
          debugPrint('✅ [ORDER-ACCEPTANCE] Driver $driverId is ready to start workflow for order $orderId');
        } else {
          debugPrint('❌ [ORDER-ACCEPTANCE] Order acceptance failed - no rows updated');
          debugPrint('❌ [ORDER-ACCEPTANCE] Order: $orderId, Driver: $driverId');
        }

        return success;
      } catch (e) {
        debugPrint('DriverOrderRepository: Error accepting order: $e');
        rethrow;
      }
    });
  }

  /// Reject an order assignment
  Future<bool> rejectOrder(String orderId, String driverId, {String? reason}) async {
    return executeQuery(() async {
      debugPrint('DriverOrderRepository: Driver $driverId rejecting order $orderId');

      try {
        // Create a rejection record for tracking
        await _supabase
            .from('driver_order_rejections')
            .insert({
              'driver_id': driverId,
              'order_id': orderId,
              'reason': reason ?? 'Driver declined',
              'rejected_at': DateTime.now().toIso8601String(),
            });

        // If this was an assigned order, unassign it
        await _supabase
            .from('orders')
            .update({
              'assigned_driver_id': null,
              'status': 'ready',
              'out_for_delivery_at': null,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', orderId)
            .eq('assigned_driver_id', driverId);

        // Update driver status back to online and clear delivery status
        debugPrint('🧹 [ORDER-REJECTION] Cleaning up driver state after order rejection');
        debugPrint('🧹 [ORDER-REJECTION] Order: $orderId, Driver: $driverId');
        debugPrint('🧹 [ORDER-REJECTION] Setting driver to online and clearing delivery status');

        await _supabase
            .from('drivers')
            .update({
              'status': 'online',
              'current_delivery_status': null, // Clear delivery status on rejection
              'last_seen': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', driverId)
            .eq('status', 'on_delivery');

        debugPrint('✅ [ORDER-REJECTION] Order $orderId rejected by driver $driverId');
        debugPrint('✅ [ORDER-REJECTION] Driver $driverId is back online and ready for new orders');
        return true;
      } catch (e) {
        debugPrint('DriverOrderRepository: Error rejecting order: $e');
        rethrow;
      }
    });
  }

  /// Update driver status (online, offline, on_delivery, etc.)
  Future<bool> updateDriverStatus(String driverId, String status) async {
    return executeQuery(() async {
      debugPrint('DriverOrderRepository: Updating driver $driverId status to $status');

      try {
        final response = await _supabase.rpc('update_driver_status', params: {
          'p_driver_id': driverId,
          'p_new_status': status,
        });

        debugPrint('DriverOrderRepository: Driver status update response: $response');

        if (response['success'] == true) {
          debugPrint('DriverOrderRepository: Driver status updated successfully');
          return true;
        } else {
          debugPrint('DriverOrderRepository: Driver status update failed: ${response['error']}');
          throw Exception(response['error']);
        }
      } catch (e) {
        debugPrint('DriverOrderRepository: Error updating driver status: $e');
        rethrow;
      }
    });
  }

  /// Update order status by driver
  Future<bool> updateOrderStatus(String orderId, DriverOrderStatus status, {String? driverId, String? notes}) async {
    return executeQuery(() async {
      debugPrint('DriverOrderRepository: Updating order $orderId status to ${status.value}');

      try {
        // Check authentication before making the call
        final currentUser = _supabase.auth.currentUser;
        debugPrint('DriverOrderRepository: Current authenticated user: ${currentUser?.id} (${currentUser?.email})');

        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        // Get driver ID if not provided
        String actualDriverId;
        if (driverId != null) {
          actualDriverId = driverId;
          debugPrint('DriverOrderRepository: Using provided driver ID: $actualDriverId');
        } else {
          debugPrint('DriverOrderRepository: Driver ID not provided, fetching from user profile');
          try {
            final driverProfile = await _supabase
                .from('drivers')
                .select('id')
                .eq('user_id', currentUser.id)
                .maybeSingle();

            if (driverProfile == null) {
              debugPrint('DriverOrderRepository: No driver profile found for user ${currentUser.id}');
              throw Exception('Driver profile not found for user ${currentUser.id}. Please ensure you are registered as a driver.');
            }

            final driverIdValue = driverProfile['id'];
            if (driverIdValue == null) {
              debugPrint('DriverOrderRepository: Driver profile found but ID is null');
              throw Exception('Driver profile exists but ID is null for user ${currentUser.id}');
            }

            actualDriverId = driverIdValue as String;
            debugPrint('DriverOrderRepository: Found driver ID: $actualDriverId');
          } catch (e) {
            debugPrint('DriverOrderRepository: Error fetching driver ID: $e');
            if (e.toString().contains('Driver profile')) {
              rethrow; // Re-throw our custom exceptions
            }
            throw Exception('Could not find driver profile for user ${currentUser.id}: ${e.toString()}');
          }
        }

        // Handle special cases for granular driver workflow statuses
        // These are tracked internally but don't change the order status
        if (status == DriverOrderStatus.arrivedAtCustomer || status == DriverOrderStatus.onRouteToCustomer) {
          // For granular driver statuses, we update the driver's delivery status
          // without changing the order status. This allows UI to progress.
          debugPrint('🎯 [GRANULAR-STATUS] Granular workflow status detected: ${status.value}');
          debugPrint('🎯 [GRANULAR-STATUS] Order: $orderId, Driver: $actualDriverId');
          debugPrint('🎯 [GRANULAR-STATUS] Updating driver delivery status only (order status unchanged)');

          // Update driver delivery status to track granular state
          await _supabase
              .from('drivers')
              .update({
                'current_delivery_status': status.value, // Track granular driver status
                'last_seen': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', actualDriverId);

          debugPrint('✅ [GRANULAR-STATUS] Driver granular status ${status.value} recorded successfully');
          debugPrint('✅ [GRANULAR-STATUS] UI can now progress while order status remains unchanged');
          return true;
        }

        // Map driver status to order status for the database function
        String orderStatus;
        switch (status) {
          case DriverOrderStatus.pickedUp:
            // Special status for pickup action - handled separately in RPC
            orderStatus = 'picked_up';
            break;
          case DriverOrderStatus.onRouteToVendor:
            orderStatus = 'on_route_to_vendor';
            break;
          case DriverOrderStatus.arrivedAtVendor:
            orderStatus = 'arrived_at_vendor';
            break;
          case DriverOrderStatus.onRouteToCustomer:
            orderStatus = 'on_route_to_customer';
            break;
          case DriverOrderStatus.delivered:
            orderStatus = 'delivered';
            break;
          case DriverOrderStatus.cancelled:
            orderStatus = 'cancelled';
            break;
          default:
            orderStatus = _mapDriverStatusToOrderStatus(status);
        }

        debugPrint('DriverOrderRepository: Calling RPC with params: orderId=$orderId, status=$orderStatus, driverId=$actualDriverId');

        // Use the original function (v2 migration not applied yet)
        final response = await _supabase.rpc('update_driver_order_status', params: {
          'p_order_id': orderId,
          'p_new_status': orderStatus,
          'p_driver_id': actualDriverId,
          'p_notes': notes,
        });

        debugPrint('DriverOrderRepository: RPC response: $response');

        // Check if the response indicates success (enhanced function returns JSON)
        if (response is Map && response['success'] == true) {
          debugPrint('DriverOrderRepository: Order status updated successfully via enhanced database function');
          debugPrint('DriverOrderRepository: Status transition: ${response['old_status']} → ${response['new_status']}');

          // CRITICAL FIX: Clear driver delivery status for terminal states
          // This prevents stale data from interfering with future orders
          if (status == DriverOrderStatus.delivered || status == DriverOrderStatus.cancelled) {
            debugPrint('🧹 [STATUS-CLEANUP] Terminal state detected: ${status.value}');
            debugPrint('🧹 [STATUS-CLEANUP] Order: $orderId, Driver: $actualDriverId');
            debugPrint('🧹 [STATUS-CLEANUP] Clearing driver delivery status and resetting to online');

            await _supabase
                .from('drivers')
                .update({
                  'current_delivery_status': null, // Clear delivery status
                  'status': 'online', // Reset driver to online status
                  'last_seen': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', actualDriverId);

            debugPrint('✅ [STATUS-CLEANUP] Driver delivery status cleared successfully');
            debugPrint('✅ [STATUS-CLEANUP] Driver $actualDriverId is now online and ready for new orders');
          } else {
            // For non-terminal states, update driver delivery status to track workflow
            debugPrint('🔄 [STATUS-UPDATE] Non-terminal state transition: ${status.value}');
            debugPrint('🔄 [STATUS-UPDATE] Order: $orderId, Driver: $actualDriverId');
            debugPrint('🔄 [STATUS-UPDATE] Updating driver delivery status to track workflow progress');

            await _supabase
                .from('drivers')
                .update({
                  'current_delivery_status': status.value, // Track current workflow status
                  'last_seen': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', actualDriverId);

            debugPrint('✅ [STATUS-UPDATE] Driver delivery status updated to: ${status.value}');
            debugPrint('✅ [STATUS-UPDATE] Driver $actualDriverId workflow state synchronized');
          }

          return true;
        } else {
          final errorMessage = response is Map ? response['error'] : 'Unknown error: $response';
          debugPrint('DriverOrderRepository: Order status update failed: $errorMessage');
          throw Exception('Failed to update order status: $errorMessage');
        }
      } catch (e) {
        debugPrint('DriverOrderRepository: Error updating order status: $e');
        rethrow;
      }
    });
  }

  /// Get order details for driver
  Future<DriverOrder?> getOrderDetails(String orderId) async {
    return executeQuery(() async {
      debugPrint('DriverOrderRepository: Getting order details for: $orderId');
      
      final response = await _supabase
          .from('orders')
          .select('''
            id,
            order_number,
            vendor_name,
            customer_name,
            delivery_address,
            contact_phone,
            total_amount,
            delivery_fee,
            status,
            assigned_driver_id,
            estimated_delivery_time,
            special_instructions,
            created_at,
            assigned_at:updated_at,
            picked_up_at:preparation_started_at,
            delivered_at:actual_delivery_time,
            vendor:vendors!orders_vendor_id_fkey(
              business_address
            ),
            driver:drivers!orders_assigned_driver_id_fkey(
              current_delivery_status
            ),
            order_items:order_items(
              *,
              menu_item:menu_items!order_items_menu_item_id_fkey(
                id,
                name,
                image_url
              )
            )
          ''')
          .eq('id', orderId)
          .single();

      debugPrint('DriverOrderRepository: Order details retrieved');
      debugPrint('DriverOrderRepository: Raw response keys: ${response.keys.toList()}');
      debugPrint('DriverOrderRepository: Response id: ${response['id']}, order_number: ${response['order_number']}');

      // Use driver's delivery status if available, otherwise map from order status
      final driverDeliveryStatus = response['driver']?['current_delivery_status'] as String?;
      final effectiveStatus = driverDeliveryStatus ?? _mapOrderStatusToDriverStatus(response['status']);

      debugPrint('DriverOrderRepository: Order status: ${response['status']}, Driver delivery status: $driverDeliveryStatus, Effective status: $effectiveStatus');

      // Create a simplified DriverOrder object with only the available data
      // This avoids the complex model requirements that cause type cast errors
      try {
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

        return DriverOrder.fromJson({
          'id': response['id']?.toString() ?? '',
          'order_id': response['id']?.toString() ?? '',
          'order_number': response['order_number']?.toString() ?? '',
          'driver_id': response['assigned_driver_id']?.toString() ?? '',
          'vendor_id': '', // Not available in this query
          'vendor_name': response['vendor_name']?.toString() ?? 'Unknown Vendor',
          'customer_id': '', // Not available in this query
          'customer_name': response['customer_name']?.toString() ?? 'Unknown Customer',
          'status': effectiveStatus,
          'priority': 'normal', // Default priority
          'delivery_details': {
            'pickup_address': response['vendor']?['business_address']?.toString() ?? '',
            'delivery_address': deliveryAddressStr,
            'contact_phone': response['contact_phone']?.toString(),
          },
          'order_earnings': {
            'base_fee': _safeToDouble(response['delivery_fee']),
            'distance_fee': 0.0,
            'time_bonus': 0.0,
            'peak_hour_bonus': 0.0,
            'tip_amount': 0.0,
            'total_earnings': _safeToDouble(response['delivery_fee']),
          },
          'order_items_count': (response['order_items'] as List?)?.length ?? 0,
          'order_total': _safeToDouble(response['total_amount']),
          'payment_method': null,
          'requires_cash_collection': false,
          'assigned_at': response['assigned_at']?.toString() ?? DateTime.now().toIso8601String(),
          'accepted_at': null,
          'started_route_at': null,
          'arrived_at_vendor_at': null,
          'picked_up_at': response['picked_up_at']?.toString(),
          'arrived_at_customer_at': null,
          'delivered_at': response['delivered_at']?.toString(),
          'created_at': response['created_at']?.toString() ?? DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('DriverOrderRepository: Error creating DriverOrder from JSON: $e');
        debugPrint('DriverOrderRepository: Response data: $response');
        rethrow;
      }
    });
  }

  /// Map order status to driver-specific status
  String _mapOrderStatusToDriverStatus(String orderStatus) {
    switch (orderStatus.toLowerCase()) {
      case 'ready':
        return 'available';
      case 'assigned':
        return 'assigned'; // Direct mapping for assigned orders
      case 'confirmed':
        return 'assigned';
      case 'preparing':
        return 'assigned'; // Restaurant is preparing, driver not involved yet
      case 'on_route_to_vendor':
        return 'on_route_to_vendor';
      case 'arrived_at_vendor':
        return 'arrived_at_vendor';
      case 'picked_up':
        return 'picked_up';
      case 'out_for_delivery':
        return 'picked_up'; // Map legacy status to picked up so driver can navigate to customer
      // Note: arrived_at_customer doesn't exist in order_status_enum
      // Driver arrival is tracked internally but order stays 'out_for_delivery'
      case 'delivered':
        return 'delivered';
      case 'cancelled':
        return 'cancelled';
      default:
        return 'available';
    }
  }

  /// Map driver status to order status
  String _mapDriverStatusToOrderStatus(DriverOrderStatus driverStatus) {
    switch (driverStatus) {
      case DriverOrderStatus.assigned:
        return 'confirmed';
      case DriverOrderStatus.onRouteToVendor:
        return 'on_route_to_vendor';
      case DriverOrderStatus.arrivedAtVendor:
        return 'arrived_at_vendor';
      case DriverOrderStatus.pickedUp:
        return 'out_for_delivery'; // Driver has picked up and is en route
      case DriverOrderStatus.onRouteToCustomer:
        return 'out_for_delivery';
      case DriverOrderStatus.arrivedAtCustomer:
        return 'out_for_delivery'; // Still out for delivery until actually delivered
      case DriverOrderStatus.delivered:
        return 'delivered';
      case DriverOrderStatus.cancelled:
        return 'cancelled';
      case DriverOrderStatus.failed:
        return 'cancelled'; // Map failed to cancelled in the orders system
    }
  }

  /// Get driver's current active order
  Future<DriverOrder?> getDriverActiveOrder(String driverId) async {
    return executeQuery(() async {
      debugPrint('DriverOrderRepository: Getting active order for driver: $driverId');

      // Get authenticated client to ensure RLS policies are applied
      final authenticatedClient = await getAuthenticatedClient();

      final response = await authenticatedClient
          .from('orders')
          .select('''
            id,
            order_number,
            vendor_name,
            customer_name,
            delivery_address,
            contact_phone,
            total_amount,
            delivery_fee,
            status,
            assigned_driver_id,
            estimated_delivery_time,
            special_instructions,
            created_at,
            assigned_at:updated_at,
            picked_up_at:preparation_started_at,
            delivered_at:actual_delivery_time,
            vendor:vendors!orders_vendor_id_fkey(
              business_address
            ),
            driver:drivers!orders_assigned_driver_id_fkey(
              current_delivery_status
            ),
            order_items:order_items(
              *,
              menu_item:menu_items!order_items_menu_item_id_fkey(
                id,
                name,
                image_url
              )
            )
          ''')
          .eq('assigned_driver_id', driverId)
          .inFilter('status', ['assigned', 'confirmed', 'preparing', 'on_route_to_vendor', 'arrived_at_vendor', 'picked_up', 'out_for_delivery'])
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        debugPrint('DriverOrderRepository: No active order found for driver');
        return null;
      }

      debugPrint('DriverOrderRepository: Active order found for driver');

      // Use driver's delivery status if available, otherwise map from order status
      final driverDeliveryStatus = response.first['driver']?['current_delivery_status'] as String?;
      final effectiveStatus = driverDeliveryStatus ?? _mapOrderStatusToDriverStatus(response.first['status']);

      debugPrint('DriverOrderRepository: Active order status: ${response.first['status']}, Driver delivery status: $driverDeliveryStatus, Effective status: $effectiveStatus');

      return DriverOrder.fromJson({
        ...response.first,
        'status': effectiveStatus,
        'vendor_address': response.first['vendor']?['business_address'],
        'customer_phone': response.first['contact_phone'], // Map contact_phone to customer_phone for model compatibility
      });
    });
  }

  /// Get driver's order history
  Future<List<DriverOrder>> getDriverOrderHistory(String driverId, {int limit = 20}) async {
    return executeQuery(() async {
      debugPrint('DriverOrderRepository: Getting order history for driver: $driverId');

      final response = await _supabase
          .from('orders')
          .select('''
            id,
            order_number,
            vendor_name,
            customer_name,
            delivery_address,
            contact_phone,
            total_amount,
            delivery_fee,
            status,
            estimated_delivery_time,
            special_instructions,
            created_at,
            assigned_at:updated_at,
            picked_up_at:preparation_started_at,
            delivered_at:actual_delivery_time,
            vendor:vendors!orders_vendor_id_fkey(
              business_address
            ),
            order_items:order_items(
              *,
              menu_item:menu_items!order_items_menu_item_id_fkey(
                id,
                name,
                image_url
              )
            )
          ''')
          .eq('assigned_driver_id', driverId)
          .inFilter('status', ['delivered', 'cancelled'])
          .order('created_at', ascending: false)
          .limit(limit);

      debugPrint('DriverOrderRepository: Found ${response.length} historical orders');

      return response.map((order) => DriverOrder.fromJson({
        ...order,
        'status': _mapOrderStatusToDriverStatus(order['status']),
        'vendor_address': order['vendor']?['business_address'],
        'customer_phone': order['contact_phone'], // Map contact_phone to customer_phone for model compatibility
      })).toList();
    });
  }

  /// Update driver location during delivery
  Future<bool> updateDriverLocation(String driverId, String orderId, double latitude, double longitude, {double? speed, double? heading, double? accuracy}) async {
    return executeQuery(() async {
      debugPrint('DriverOrderRepository: Updating driver location for order: $orderId');

      try {
        // Insert tracking record
        await _supabase
            .from('delivery_tracking')
            .insert({
              'order_id': orderId,
              'driver_id': driverId,
              'location': 'POINT($longitude $latitude)',
              'speed': speed,
              'heading': heading,
              'accuracy': accuracy,
              'recorded_at': DateTime.now().toIso8601String(),
            });

        // Update driver's last known location
        await _supabase
            .from('drivers')
            .update({
              'last_location': 'POINT($longitude $latitude)',
              'last_seen': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', driverId);

        debugPrint('DriverOrderRepository: Driver location updated successfully');
        return true;
      } catch (e) {
        debugPrint('DriverOrderRepository: Error updating driver location: $e');
        rethrow;
      }
    });
  }

  /// Get driver earnings for a specific period
  Future<Map<String, dynamic>> getDriverEarnings(String driverId, {DateTime? startDate, DateTime? endDate}) async {
    return executeQuery(() async {
      debugPrint('DriverOrderRepository: Getting driver earnings for: $driverId');

      var query = _supabase
          .from('orders')
          .select('delivery_fee, actual_delivery_time')
          .eq('assigned_driver_id', driverId)
          .eq('status', 'delivered');

      // Apply date filters if provided
      if (startDate != null) {
        query = query.gte('actual_delivery_time', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('actual_delivery_time', endDate.toIso8601String());
      }

      final response = await query;

      double totalEarnings = 0.0;
      int totalDeliveries = response.length;

      for (final order in response) {
        totalEarnings += (order['delivery_fee'] as num?)?.toDouble() ?? 0.0;
      }

      debugPrint('DriverOrderRepository: Driver earnings calculated - Total: $totalEarnings, Deliveries: $totalDeliveries');

      return {
        'total_earnings': totalEarnings,
        'total_deliveries': totalDeliveries,
        'average_per_delivery': totalDeliveries > 0 ? totalEarnings / totalDeliveries : 0.0,
        'period_start': startDate?.toIso8601String(),
        'period_end': endDate?.toIso8601String(),
      };
    });
  }



  /// Cancel an order with reason
  Future<void> cancelOrder(String orderId, String reason) async {
    return executeQuery(() async {
      debugPrint('DriverOrderRepository: Cancelling order $orderId with reason: $reason');

      final authenticatedClient = await getAuthenticatedClient();

      await authenticatedClient
          .from('orders')
          .update({
            'status': 'cancelled',
            'cancellation_reason': reason,
            'cancelled_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      debugPrint('DriverOrderRepository: Order $orderId cancelled successfully');
    });
  }

  /// Helper method to safely convert values to double
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }
}
