import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';
import 'base_repository.dart';

class OrderRepository extends BaseRepository {
  OrderRepository({
    SupabaseClient? client,
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : super(client: client, firebaseAuth: firebaseAuth);

  /// Get orders for the current user based on their role
  Future<List<Order>> getOrders({
    OrderStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      final currentUser = await _getCurrentUserWithRole();
      if (currentUser == null) throw Exception('User not authenticated');

      var query = client.from('orders').select('''
            *,
            vendor:vendors!orders_vendor_id_fkey(
              id,
              business_name,
              business_address,
              rating
            ),
            customer:customers!orders_customer_id_fkey(
              id,
              organization_name,
              contact_person_name,
              email,
              phone_number
            ),
            sales_agent:users!orders_sales_agent_id_fkey(
              id,
              full_name,
              email
            ),
            order_items:order_items(
              *,
              menu_item:menu_items!order_items_menu_item_id_fkey(
                id,
                name,
                image_url
              )
            )
          ''');

      // Apply role-based filtering
      switch (currentUser['role']) {
        case 'sales_agent':
          query = query.eq('sales_agent_id', currentUser['id']);
          break;
        case 'vendor':
          // Get vendor ID for this user
          final vendorResponse = await client
              .from('vendors')
              .select('id')
              .eq('firebase_uid', currentUserUid!)
              .single();
          query = query.eq('vendor_id', vendorResponse['id']);
          break;
        case 'admin':
          // Admins can see all orders
          break;
        default:
          throw Exception('Invalid user role for order access');
      }

      // Apply filters
      if (status != null) {
        query = query.eq('status', status.value);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      // Apply ordering and pagination and execute query
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return response.map((json) => Order.fromJson(json)).toList();
    });
  }

  /// Get orders stream for real-time updates
  Stream<List<Order>> getOrdersStream({
    OrderStatus? status,
    String? vendorId,
    String? customerId,
  }) {
    return executeStreamQuery(() async* {
      final currentUser = await _getCurrentUserWithRole();
      if (currentUser == null) throw Exception('User not authenticated');

      dynamic streamBuilder = client.from('orders').stream(primaryKey: ['id']);

      // Apply role-based filtering
      switch (currentUser['role']) {
        case 'sales_agent':
          streamBuilder = streamBuilder.eq('sales_agent_id', currentUser['id']);
          break;
        case 'vendor':
          final vendorResponse = await client
              .from('vendors')
              .select('id')
              .eq('firebase_uid', currentUserUid!)
              .single();
          streamBuilder = streamBuilder.eq('vendor_id', vendorResponse['id']);
          break;
      }

      // Apply additional filters
      if (status != null) {
        streamBuilder = streamBuilder.eq('status', status.value);
      }

      if (vendorId != null) {
        streamBuilder = streamBuilder.eq('vendor_id', vendorId);
      }

      if (customerId != null) {
        streamBuilder = streamBuilder.eq('customer_id', customerId);
      }

      yield* streamBuilder
          .map((data) => data.map((json) => Order.fromJson(json)).toList());
    });
  }

  /// Get single order stream for real-time updates
  Stream<Order?> getOrderStream(String orderId) {
    return executeStreamQuery(() async* {
      yield* client
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('id', orderId)
          .map((data) => data.isNotEmpty ? Order.fromJson(data.first) : null);
    });
  }

  /// Get order by ID
  Future<Order?> getOrderById(String orderId) async {
    return executeQuery(() async {
      final response = await client
          .from('orders')
          .select('''
            *,
            vendor:vendors!orders_vendor_id_fkey(
              id,
              business_name,
              business_address,
              rating
            ),
            customer:customers!orders_customer_id_fkey(
              id,
              organization_name,
              contact_person_name,
              email,
              phone_number
            ),
            sales_agent:users!orders_sales_agent_id_fkey(
              id,
              full_name,
              email
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

      return Order.fromJson(response);
    });
  }

  /// Create new order
  Future<Order> createOrder(Order order) async {
    return executeQuery(() async {
      final orderData = order.toJson();
      
      // Remove nested data that will be handled separately
      orderData.remove('vendor');
      orderData.remove('customer');
      orderData.remove('sales_agent');
      final orderItems = orderData.remove('order_items') as List<dynamic>?;

      // Create order
      final orderResponse = await client
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final orderId = orderResponse['id'];

      // Create order items
      if (orderItems != null && orderItems.isNotEmpty) {
        final itemsData = orderItems.map((item) {
          final itemData = Map<String, dynamic>.from(item);
          itemData['order_id'] = orderId;
          itemData.remove('menu_item'); // Remove nested data
          return itemData;
        }).toList();

        await client.from('order_items').insert(itemsData);
      }

      // Return complete order with relations
      return await getOrderById(orderId) ?? Order.fromJson(orderResponse);
    });
  }

  /// Update order status
  Future<Order> updateOrderStatus(String orderId, OrderStatus status) async {
    return executeQuery(() async {
      await client
          .from('orders')
          .update({
            'status': status.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      final order = await getOrderById(orderId);
      if (order == null) throw Exception('Order not found');
      return order;
    });
  }

  /// Update order payment status
  Future<Order> updatePaymentStatus(
    String orderId, 
    PaymentStatus paymentStatus,
    {String? paymentReference}
  ) async {
    return executeQuery(() async {
      final updateData = {
        'payment_status': paymentStatus.value,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (paymentReference != null) {
        updateData['payment_reference'] = paymentReference;
      }

      await client
          .from('orders')
          .update(updateData)
          .eq('id', orderId);

      final order = await getOrderById(orderId);
      if (order == null) throw Exception('Order not found');
      return order;
    });
  }

  /// Get order statistics for dashboard
  Future<Map<String, dynamic>> getOrderStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      final currentUser = await _getCurrentUserWithRole();
      if (currentUser == null) throw Exception('User not authenticated');

      // Build the RPC call based on user role
      final params = <String, dynamic>{
        'user_role': currentUser['role'],
        'user_id': currentUser['id'],
      };

      if (startDate != null) {
        params['start_date'] = startDate.toIso8601String();
      }

      if (endDate != null) {
        params['end_date'] = endDate.toIso8601String();
      }

      final response = await client.rpc('get_order_statistics', params: params);
      return response as Map<String, dynamic>;
    });
  }

  /// Cancel order
  Future<Order> cancelOrder(String orderId, String reason) async {
    return executeQuery(() async {
      await client
          .from('orders')
          .update({
            'status': OrderStatus.cancelled.value,
            'notes': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      final order = await getOrderById(orderId);
      if (order == null) throw Exception('Order not found');
      return order;
    });
  }

  /// Get recent orders for dashboard
  Future<List<Order>> getRecentOrders({int limit = 5}) async {
    return executeQuery(() async {
      final currentUser = await _getCurrentUserWithRole();
      if (currentUser == null) throw Exception('User not authenticated');

      var query = client.from('orders').select('''
            *,
            vendor:vendors!orders_vendor_id_fkey(business_name),
            customer:customers!orders_customer_id_fkey(organization_name)
          ''');

      // Apply role-based filtering
      switch (currentUser['role']) {
        case 'sales_agent':
          query = query.eq('sales_agent_id', currentUser['id']);
          break;
        case 'vendor':
          final vendorResponse = await client
              .from('vendors')
              .select('id')
              .eq('firebase_uid', currentUserUid!)
              .single();
          query = query.eq('vendor_id', vendorResponse['id']);
          break;
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return response.map((json) => Order.fromJson(json)).toList();
    });
  }

  /// Helper method to get current user with role
  Future<Map<String, dynamic>?> _getCurrentUserWithRole() async {
    if (currentUserUid == null) return null;

    final response = await client
        .from('users')
        .select('id, role')
        .eq('firebase_uid', currentUserUid!)
        .single();

    return response;
  }
}
