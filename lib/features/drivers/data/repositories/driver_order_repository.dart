import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/base_repository.dart';
import '../models/driver_order.dart';

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
          debugPrint('DriverOrderRepository: Order accepted successfully, updating driver status...');

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

          debugPrint('DriverOrderRepository: Driver status updated to on_delivery');
        } else {
          debugPrint('DriverOrderRepository: Order acceptance failed - no rows updated');
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

        // Update driver status back to online if they were on delivery
        await _supabase
            .from('drivers')
            .update({
              'status': 'online',
              'last_seen': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', driverId)
            .eq('status', 'on_delivery');

        debugPrint('DriverOrderRepository: Order $orderId rejected by driver $driverId');
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

        // Handle special case for arrived_at_customer - this is tracked internally
        // but doesn't change the order status (stays out_for_delivery)
        if (status == DriverOrderStatus.arrivedAtCustomer) {
          // For arrived at customer, we update the driver's delivery status
          // without changing the order status. This allows UI to progress.
          debugPrint('DriverOrderRepository: Driver arrived at customer - updating driver delivery status');

          // Update driver delivery status to track granular state
          if (driverId != null) {
            await _supabase
                .from('drivers')
                .update({
                  'current_delivery_status': status.value, // Track granular driver status
                  'last_seen': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', driverId);
          }

          debugPrint('DriverOrderRepository: Driver arrival recorded successfully');
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
            orderStatus = 'out_for_delivery';
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

        debugPrint('DriverOrderRepository: Calling RPC with params: orderId=$orderId, status=$orderStatus, driverId=$driverId');

        final response = await _supabase.rpc('update_driver_order_status', params: {
          'p_order_id': orderId,
          'p_new_status': orderStatus,
          'p_driver_id': driverId,
          'p_notes': notes,
        });

        debugPrint('DriverOrderRepository: RPC response: $response');

        // Check if the response indicates success
        if (response is Map && response['success'] == true) {
          debugPrint('DriverOrderRepository: Order status updated successfully via database function');

          // Also update driver's delivery status for granular tracking
          if (driverId != null) {
            await _updateDriverDeliveryStatus(driverId, status);
          }

          return true;
        } else {
          final errorMessage = response is Map ? response['error'] : 'Unknown error';
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
            )
          ''')
          .eq('id', orderId)
          .single();

      debugPrint('DriverOrderRepository: Order details retrieved');

      // Use driver's delivery status if available, otherwise map from order status
      final driverDeliveryStatus = response['driver']?['current_delivery_status'] as String?;
      final effectiveStatus = driverDeliveryStatus ?? _mapOrderStatusToDriverStatus(response['status']);

      debugPrint('DriverOrderRepository: Order status: ${response['status']}, Driver delivery status: $driverDeliveryStatus, Effective status: $effectiveStatus');

      return DriverOrder.fromJson({
        ...response,
        'status': effectiveStatus,
        'vendor_address': response['vendor']?['business_address'],
        'customer_phone': response['contact_phone'], // Map contact_phone to customer_phone for model compatibility
      });
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
        return 'on_route_to_customer'; // Driver has order and is en route to customer
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
      case DriverOrderStatus.available:
        return 'ready';
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

  /// Update driver's delivery status for granular tracking
  Future<void> _updateDriverDeliveryStatus(String driverId, DriverOrderStatus status) async {
    try {
      debugPrint('DriverOrderRepository: Updating driver delivery status to: ${status.value}');

      // Clear delivery status when order is completed or cancelled
      final deliveryStatus = (status == DriverOrderStatus.delivered || status == DriverOrderStatus.cancelled)
          ? null
          : status.value;

      // Update driver's current delivery status
      await _supabase
          .from('drivers')
          .update({
            'current_delivery_status': deliveryStatus,
            'last_seen': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      debugPrint('DriverOrderRepository: Driver delivery status updated successfully');
    } catch (e) {
      debugPrint('DriverOrderRepository: Error updating driver delivery status: $e');
      // Don't rethrow - this is supplementary tracking
    }
  }
}
