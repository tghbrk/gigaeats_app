import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/delivery_method.dart';
import '../models/order_status_history.dart';
// TODO: Remove unused import when Customer class is used
// import '../../../user_management/domain/customer.dart';

/// Service for customer order operations
class CustomerOrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new order for a customer
  Future<Order> createOrder({
    required String customerId,
    required String vendorId,
    required List<OrderItem> items,
    required double totalAmount,
    required DeliveryMethod deliveryMethod,
    required Address deliveryAddress,
    String? customerNotes,
    DateTime? scheduledDeliveryTime,
    String? salesAgentId,
  }) async {
    try {
      final orderData = {
        'customer_id': customerId,
        'vendor_id': vendorId,
        'sales_agent_id': salesAgentId,
        'total_amount': totalAmount,
        'status': OrderStatus.pending.name,
        'delivery_method': deliveryMethod.name,
        'delivery_address': deliveryAddress.toJson(),
        'customer_notes': customerNotes,
        'scheduled_delivery_time': scheduledDeliveryTime?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      // Create order
      final orderResponse = await _supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final orderId = orderResponse['id'];

      // Create order items
      final itemsData = items.map((item) => {
        'order_id': orderId,
        'menu_item_id': item.menuItemId,
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'customizations': item.customizations,
        'notes': item.notes,
        'subtotal': item.subtotal, // Note: subtotal is non-nullable
      }).toList();

      await _supabase
          .from('order_items')
          .insert(itemsData);

      // Fetch complete order with items
      return await getOrderById(orderId);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// Get order by ID
  Future<Order> getOrderById(String orderId) async {
    try {
      final orderResponse = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', orderId)
          .single();

      return Order.fromJson(orderResponse);
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  /// Get orders for a customer
  Future<List<Order>> getCustomerOrders({
    required String customerId,
    OrderStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('orders')
          .select('*, order_items(*), vendors(name, image_url)')
          .eq('customer_id', customerId);

      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch customer orders: $e');
    }
  }

  /// Update order status
  Future<Order> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? notes,
    String? updatedBy,
  }) async {
    try {
      final updateData = {
        'status': newStatus.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add status-specific timestamps
      switch (newStatus) {
        case OrderStatus.confirmed:
          updateData['confirmed_at'] = DateTime.now().toIso8601String();
          break;
        case OrderStatus.preparing:
          updateData['preparing_at'] = DateTime.now().toIso8601String();
          break;
        case OrderStatus.ready:
          updateData['ready_at'] = DateTime.now().toIso8601String();
          break;
        case OrderStatus.outForDelivery:
          updateData['out_for_delivery_at'] = DateTime.now().toIso8601String();
          break;
        case OrderStatus.delivered:
          updateData['delivered_at'] = DateTime.now().toIso8601String();
          updateData['actual_delivery_time'] = DateTime.now().toIso8601String();
          break;
        case OrderStatus.cancelled:
          updateData['cancelled_at'] = DateTime.now().toIso8601String();
          break;
        default:
          break;
      }

      await _supabase
          .from('orders')
          .update(updateData)
          .eq('id', orderId);

      // Create status history record
      await _createStatusHistory(
        orderId: orderId,
        newStatus: newStatus,
        notes: notes,
        updatedBy: updatedBy,
      );

      return await getOrderById(orderId);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// Cancel order
  Future<Order> cancelOrder({
    required String orderId,
    required String reason,
    String? cancelledBy,
  }) async {
    try {
      return await updateOrderStatus(
        orderId: orderId,
        newStatus: OrderStatus.cancelled,
        notes: reason,
        updatedBy: cancelledBy,
      );
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  /// Get order status history
  Future<List<OrderStatusHistory>> getOrderStatusHistory(String orderId) async {
    try {
      final response = await _supabase
          .from('order_status_history')
          .select('*')
          .eq('order_id', orderId)
          .order('timestamp', ascending: true);

      return response.map((json) => OrderStatusHistory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch order status history: $e');
    }
  }

  /// Get active orders for a customer
  Future<List<Order>> getActiveOrders(String customerId) async {
    try {
      final activeStatuses = [
        OrderStatus.pending.name,
        OrderStatus.confirmed.name,
        OrderStatus.preparing.name,
        OrderStatus.ready.name,
        OrderStatus.outForDelivery.name,
      ];

      final response = await _supabase
          .from('orders')
          .select('*, order_items(*), vendors(name, image_url)')
          .eq('customer_id', customerId)
          .inFilter('status', activeStatuses)
          .order('created_at', ascending: false);

      return response.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch active orders: $e');
    }
  }

  /// Get order statistics for a customer
  Future<Map<String, dynamic>> getCustomerOrderStats(String customerId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('id, total_amount, status, created_at')
          .eq('customer_id', customerId);

      final totalOrders = response.length;
      final completedOrders = response.where((o) => o['status'] == 'delivered').toList();
      final totalSpent = completedOrders.fold<double>(
        0, 
        (sum, order) => sum + (order['total_amount'] as num).toDouble()
      );

      final activeOrders = response.where((o) => 
        ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery'].contains(o['status'])
      ).length;

      return {
        'total_orders': totalOrders,
        'completed_orders': completedOrders.length,
        'total_spent': totalSpent,
        'active_orders': activeOrders,
        'average_order_value': completedOrders.isNotEmpty ? totalSpent / completedOrders.length : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to fetch customer order stats: $e');
    }
  }

  /// Create status history record
  Future<void> _createStatusHistory({
    required String orderId,
    required OrderStatus newStatus,
    String? notes,
    String? updatedBy,
  }) async {
    try {
      // Get current order to determine from status
      final currentOrder = await _supabase
          .from('orders')
          .select('status')
          .eq('id', orderId)
          .single();

      final fromStatus = OrderStatus.values.firstWhere(
        (status) => status.name == currentOrder['status'],
        orElse: () => OrderStatus.pending,
      );

      await _supabase
          .from('order_status_history')
          .insert({
            'order_id': orderId,
            'from_status': fromStatus.name,
            'to_status': newStatus.name,
            'notes': notes,
            'updated_by': updatedBy,
            'timestamp': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      // Don't throw here as this is supplementary data
      print('Warning: Failed to create status history: $e');
    }
  }

  /// Estimate delivery time
  Future<DateTime> estimateDeliveryTime({
    required String vendorId,
    required DeliveryMethod deliveryMethod,
    DateTime? scheduledTime,
  }) async {
    try {
      // Base preparation time (in minutes)
      int preparationTime = 30;

      // Get vendor's average preparation time if available
      final vendorResponse = await _supabase
          .from('vendors')
          .select('average_preparation_time')
          .eq('id', vendorId)
          .maybeSingle();

      if (vendorResponse != null && vendorResponse['average_preparation_time'] != null) {
        preparationTime = vendorResponse['average_preparation_time'];
      }

      // Add delivery time based on method
      int deliveryTime = 0;
      switch (deliveryMethod) {
        case DeliveryMethod.customerPickup:
          deliveryTime = 0; // No delivery time for pickup
          break;
        case DeliveryMethod.salesAgentPickup:
          deliveryTime = 15; // Sales agent pickup time
          break;
        case DeliveryMethod.ownFleet:
          deliveryTime = 30; // Own fleet delivery time
          break;
        case DeliveryMethod.thirdParty:
          deliveryTime = 45; // Third party delivery time
          break;
      }

      final baseTime = scheduledTime ?? DateTime.now();
      return baseTime.add(Duration(minutes: preparationTime + deliveryTime));
    } catch (e) {
      // Return default estimate if calculation fails
      final baseTime = scheduledTime ?? DateTime.now();
      return baseTime.add(const Duration(minutes: 60));
    }
  }
}
