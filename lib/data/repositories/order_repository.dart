import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../models/order_status_history.dart';
import '../models/order_notification.dart';
import '../../core/utils/debug_logger.dart';
import 'base_repository.dart';

class OrderRepository extends BaseRepository {
  OrderRepository({
    SupabaseClient? client,
  }) : super(client: client);

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
              .eq('supabase_user_id', currentUserUid!)
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
              .eq('supabase_user_id', currentUserUid!)
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
      // Use authenticated client for order creation (critical for RLS policies)
      final authenticatedClient = await getAuthenticatedClient();

      debugPrint('OrderRepository: Creating order with authenticated client');
      debugPrint('OrderRepository: Order data - Customer: ${order.customerName}, Vendor: ${order.vendorName}');
      debugPrint('OrderRepository: Order has ${order.items.length} items');

      // Debug the order items before JSON conversion
      for (int i = 0; i < order.items.length; i++) {
        final item = order.items[i];
        debugPrint('OrderRepository: Item $i - Type: ${item.runtimeType}, Name: ${item.name}');
      }

      debugPrint('OrderRepository: Converting order to JSON...');
      final orderData = order.toJson();
      debugPrint('OrderRepository: Order JSON conversion successful');

      // Remove nested data that will be handled separately
      orderData.remove('vendor');
      orderData.remove('customer');
      orderData.remove('sales_agent');

      // CRITICAL FIX: Properly handle order items conversion
      final orderItemsRaw = orderData.remove('order_items');
      List<Map<String, dynamic>>? orderItems;

      if (orderItemsRaw != null) {
        if (orderItemsRaw is List<OrderItem>) {
          // Convert OrderItem objects to JSON Maps
          orderItems = orderItemsRaw.map((item) => item.toJson()).toList();
          debugPrint('OrderRepository: Converted ${orderItems.length} OrderItem objects to JSON');
        } else if (orderItemsRaw is List<Map<String, dynamic>>) {
          // Already in correct format
          orderItems = orderItemsRaw;
          debugPrint('OrderRepository: Order items already in JSON format');
        } else {
          debugPrint('OrderRepository: Unexpected order items type: ${orderItemsRaw.runtimeType}');
          throw Exception('Invalid order items format: ${orderItemsRaw.runtimeType}');
        }
      }

      // Remove tracking fields that don't exist in the database schema yet
      // These fields are only used for order updates, not creation
      orderData.remove('actual_delivery_time');
      orderData.remove('preparation_started_at');
      orderData.remove('ready_at');
      orderData.remove('out_for_delivery_at');
      orderData.remove('delivery_zone');
      orderData.remove('special_instructions');
      // Keep contact_phone as it's a valid field for order creation

      // CRITICAL FIX: Remove empty string UUID fields that should be auto-generated or null
      // The database expects either valid UUIDs or NULL, not empty strings
      if (orderData['id'] == '') {
        orderData.remove('id'); // Let database generate UUID
        debugPrint('OrderRepository: Removed empty id field - will be auto-generated');
      }
      if (orderData['order_number'] == '') {
        orderData.remove('order_number'); // Let database generate order number
        debugPrint('OrderRepository: Removed empty order_number field - will be auto-generated');
      }

      // Validate required UUID fields are not empty strings
      final requiredUuidFields = ['vendor_id', 'customer_id'];
      for (final field in requiredUuidFields) {
        if (orderData[field] == '') {
          debugPrint('OrderRepository: ERROR - Required UUID field $field is empty string');
          throw Exception('Invalid $field: cannot be empty. Please refresh and try again.');
        }
      }

      // Handle optional UUID fields - convert empty strings to null
      final optionalUuidFields = ['sales_agent_id'];
      for (final field in optionalUuidFields) {
        if (orderData[field] == '') {
          orderData[field] = null;
          debugPrint('OrderRepository: Converted empty $field to null');
        }
      }

      // Enhanced UUID debugging
      DebugLogger.info('🔍 Final UUID validation before database insert:', tag: 'OrderRepository');
      DebugLogger.info('  - vendor_id: ${orderData['vendor_id']} (type: ${orderData['vendor_id'].runtimeType})', tag: 'OrderRepository');
      DebugLogger.info('  - customer_id: ${orderData['customer_id']} (type: ${orderData['customer_id'].runtimeType})', tag: 'OrderRepository');
      DebugLogger.info('  - sales_agent_id: ${orderData['sales_agent_id']} (type: ${orderData['sales_agent_id'].runtimeType})', tag: 'OrderRepository');

      DebugLogger.info('📋 Inserting order data with fields: ${orderData.keys.join(', ')}', tag: 'OrderRepository');
      DebugLogger.logObject('Full order data being sent to Supabase', orderData, tag: 'OrderRepository');

      try {
        // Log the exact network request being made
        DebugLogger.networkRequest('POST', '/rest/v1/orders?select=*', data: orderData);

        // Create order with authenticated client
        final orderResponse = await authenticatedClient
            .from('orders')
            .insert(orderData)
            .select()
            .single();

        DebugLogger.networkResponse('POST', '/rest/v1/orders', 200, data: orderResponse);
        DebugLogger.success('Order insert successful, response received', tag: 'OrderRepository');

        final orderId = orderResponse['id'];
        debugPrint('OrderRepository: Order created successfully with ID: $orderId');

        // Create order items with authenticated client
        if (orderItems != null && orderItems.isNotEmpty) {
          final itemsData = orderItems.map((item) {
            // item is already a Map<String, dynamic> from our conversion above
            final itemData = Map<String, dynamic>.from(item);
            itemData['order_id'] = orderId;
            itemData.remove('menu_item'); // Remove nested data
            return itemData;
          }).toList();

          debugPrint('OrderRepository: Creating ${itemsData.length} order items');
          await authenticatedClient.from('order_items').insert(itemsData);
          debugPrint('OrderRepository: Order items created successfully');
        }

        // Return complete order with relations
        final completeOrder = await getOrderById(orderId);
        if (completeOrder != null) {
          debugPrint('OrderRepository: Order creation completed successfully');
          return completeOrder;
        } else {
          debugPrint('OrderRepository: Warning - Could not fetch complete order, returning basic order');
          return Order.fromJson(orderResponse);
        }
      } catch (e, stackTrace) {
        DebugLogger.error('Error during order insert', tag: 'OrderRepository', error: e, stackTrace: stackTrace);

        // Log detailed error information for debugging
        if (e.toString().contains('400')) {
          DebugLogger.error('400 Bad Request - likely invalid data format or missing required fields', tag: 'OrderRepository-400');
          DebugLogger.networkResponse('POST', '/rest/v1/orders', 400, error: e.toString());
        } else if (e.toString().contains('401')) {
          DebugLogger.error('401 Unauthorized - authentication failed', tag: 'OrderRepository-401');
        } else if (e.toString().contains('403')) {
          DebugLogger.error('403 Forbidden - permission denied by RLS policies', tag: 'OrderRepository-403');
        } else if (e.toString().contains('422')) {
          DebugLogger.error('422 Unprocessable Entity - data validation failed', tag: 'OrderRepository-422');
        }

        rethrow; // Re-throw to be handled by the provider
      }
    });
  }

  /// Update order status
  Future<Order> updateOrderStatus(String orderId, OrderStatus status) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();

      debugPrint('OrderRepository: Updating order status - ID: $orderId, Status: ${status.value}');

      await authenticatedClient
          .from('orders')
          .update({
            'status': status.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      final order = await getOrderById(orderId);
      if (order == null) throw Exception('Order not found');

      debugPrint('OrderRepository: Order status updated successfully');
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
      final authenticatedClient = await getAuthenticatedClient();

      debugPrint('OrderRepository: Updating payment status - ID: $orderId, Status: ${paymentStatus.value}');

      final updateData = {
        'payment_status': paymentStatus.value,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (paymentReference != null) {
        updateData['payment_reference'] = paymentReference;
      }

      await authenticatedClient
          .from('orders')
          .update(updateData)
          .eq('id', orderId);

      final order = await getOrderById(orderId);
      if (order == null) throw Exception('Order not found');

      debugPrint('OrderRepository: Payment status updated successfully');
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
      final authenticatedClient = await getAuthenticatedClient();

      debugPrint('OrderRepository: Cancelling order - ID: $orderId, Reason: $reason');

      await authenticatedClient
          .from('orders')
          .update({
            'status': OrderStatus.cancelled.value,
            'notes': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      final order = await getOrderById(orderId);
      if (order == null) throw Exception('Order not found');

      debugPrint('OrderRepository: Order cancelled successfully');
      return order;
    });
  }

  /// Get recent orders for dashboard
  Future<List<Order>> getRecentOrders({int limit = 5}) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      final currentUser = await _getCurrentUserWithRole();
      if (currentUser == null) throw Exception('User not authenticated');

      debugPrint('OrderRepository.getRecentOrders: User role: ${currentUser['role']}, User ID: ${currentUser['id']}');

      var query = authenticatedClient.from('orders').select('''
            *,
            vendor:vendors!orders_vendor_id_fkey(business_name),
            customer:customers!orders_customer_id_fkey(organization_name),
            order_items:order_items(*)
          ''');

      // Apply role-based filtering
      switch (currentUser['role']) {
        case 'sales_agent':
          debugPrint('OrderRepository.getRecentOrders: Filtering by sales_agent_id: ${currentUser['id']}');
          query = query.eq('sales_agent_id', currentUser['id']);
          break;
        case 'vendor':
          final vendorResponse = await authenticatedClient
              .from('vendors')
              .select('id')
              .eq('supabase_user_id', currentUser['id'])
              .single();
          debugPrint('OrderRepository.getRecentOrders: Filtering by vendor_id: ${vendorResponse['id']}');
          query = query.eq('vendor_id', vendorResponse['id']);
          break;
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      debugPrint('OrderRepository.getRecentOrders: Found ${response.length} orders');

      // Handle empty results gracefully
      if (response.isEmpty) {
        debugPrint('OrderRepository: No recent orders found for user role: ${currentUser['role']}');
        return [];
      }

      // Transform the data to match Order model expectations
      final orders = response.map((data) {
        final orderData = Map<String, dynamic>.from(data);

        debugPrint('OrderRepository.getRecentOrders: Processing order ${orderData['order_number']}');
        debugPrint('OrderRepository.getRecentOrders: Raw vendor data: ${orderData['vendor']}');
        debugPrint('OrderRepository.getRecentOrders: Raw customer data: ${orderData['customer']}');

        // Extract vendor name from joined data
        if (orderData['vendor'] != null && orderData['vendor'] is Map) {
          final vendorData = orderData['vendor'] as Map<String, dynamic>;
          orderData['vendor_name'] = vendorData['business_name']?.toString() ?? 'Unknown Vendor';
        } else {
          orderData['vendor_name'] = 'Unknown Vendor';
        }

        // Extract customer name from joined data
        if (orderData['customer'] != null && orderData['customer'] is Map) {
          final customerData = orderData['customer'] as Map<String, dynamic>;
          orderData['customer_name'] = customerData['organization_name']?.toString() ?? 'Unknown Customer';
        } else {
          orderData['customer_name'] = 'Unknown Customer';
        }

        // Ensure all required String fields are not null
        orderData['id'] = orderData['id']?.toString() ?? '';
        orderData['order_number'] = orderData['order_number']?.toString() ?? '';
        orderData['vendor_id'] = orderData['vendor_id']?.toString() ?? '';
        orderData['customer_id'] = orderData['customer_id']?.toString() ?? '';

        // Ensure order_items is not null
        if (orderData['order_items'] == null) {
          orderData['order_items'] = [];
        }

        // Remove the nested objects to avoid conflicts
        orderData.remove('vendor');
        orderData.remove('customer');

        debugPrint('OrderRepository.getRecentOrders: Final vendor_name: ${orderData['vendor_name']}');
        debugPrint('OrderRepository.getRecentOrders: Final customer_name: ${orderData['customer_name']}');

        try {
          return Order.fromJson(orderData);
        } catch (e) {
          debugPrint('OrderRepository.getRecentOrders: Error parsing order ${orderData['order_number']}: $e');
          debugPrint('OrderRepository.getRecentOrders: Order data keys: ${orderData.keys.join(', ')}');
          rethrow;
        }
      }).toList();

      debugPrint('OrderRepository.getRecentOrders: Successfully transformed ${orders.length} orders');
      return orders;
    });
  }

  /// Get order status history
  Future<List<OrderStatusHistory>> getOrderStatusHistory(String orderId) async {
    return executeQuery(() async {
      final response = await client
          .from('order_status_history')
          .select('*')
          .eq('order_id', orderId)
          .order('created_at', ascending: false);

      return response.map((json) => OrderStatusHistory.fromJson(json)).toList();
    });
  }

  /// Get order notifications for current user
  Future<List<OrderNotification>> getOrderNotifications({
    bool? isRead,
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      var query = client
          .from('order_notifications')
          .select('*')
          .eq('recipient_id', currentUserUid!);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      final response = await query
          .order('sent_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => OrderNotification.fromJson(json)).toList();
    });
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    return executeQuery(() async {
      await client
          .from('order_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('recipient_id', currentUserUid!);
    });
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    return executeQuery(() async {
      await client
          .from('order_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('recipient_id', currentUserUid!)
          .eq('is_read', false);
    });
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    return executeQuery(() async {
      final response = await client
          .from('order_notifications')
          .select('id')
          .eq('recipient_id', currentUserUid!)
          .eq('is_read', false);

      return response.length;
    });
  }

  /// Get order notifications stream for real-time updates
  Stream<List<OrderNotification>> getOrderNotificationsStream() {
    return executeStreamQuery(() async* {
      yield* client
          .from('order_notifications')
          .stream(primaryKey: ['id'])
          .eq('recipient_id', currentUserUid!)
          .order('sent_at', ascending: false)
          .map((data) => data.map((json) => OrderNotification.fromJson(json)).toList());
    });
  }

  /// Update order with enhanced tracking fields
  Future<Order> updateOrderTracking(
    String orderId, {
    DateTime? estimatedDeliveryTime,
    DateTime? actualDeliveryTime,
    DateTime? preparationStartedAt,
    DateTime? readyAt,
    DateTime? outForDeliveryAt,
    String? deliveryZone,
    String? specialInstructions,
    String? contactPhone,
  }) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (estimatedDeliveryTime != null) {
        updateData['estimated_delivery_time'] = estimatedDeliveryTime.toIso8601String();
      }
      if (actualDeliveryTime != null) {
        updateData['actual_delivery_time'] = actualDeliveryTime.toIso8601String();
      }
      if (preparationStartedAt != null) {
        updateData['preparation_started_at'] = preparationStartedAt.toIso8601String();
      }
      if (readyAt != null) {
        updateData['ready_at'] = readyAt.toIso8601String();
      }
      if (outForDeliveryAt != null) {
        updateData['out_for_delivery_at'] = outForDeliveryAt.toIso8601String();
      }
      if (deliveryZone != null) {
        updateData['delivery_zone'] = deliveryZone;
      }
      if (specialInstructions != null) {
        updateData['special_instructions'] = specialInstructions;
      }
      if (contactPhone != null) {
        updateData['contact_phone'] = contactPhone;
      }

      await authenticatedClient
          .from('orders')
          .update(updateData)
          .eq('id', orderId);

      final order = await getOrderById(orderId);
      if (order == null) throw Exception('Order not found');

      return order;
    });
  }

  /// Helper method to get current user with role
  Future<Map<String, dynamic>?> _getCurrentUserWithRole() async {
    if (currentUserUid == null) {
      debugPrint('OrderRepository: No current user UID available');
      return null;
    }

    try {
      final authenticatedClient = await getAuthenticatedClient();

      debugPrint('OrderRepository: Fetching user role for UID: $currentUserUid');

      final response = await authenticatedClient
          .from('users')
          .select('id, role')
          .eq('supabase_user_id', currentUserUid!)
          .single();

      debugPrint('OrderRepository: User role fetched - ID: ${response['id']}, Role: ${response['role']}');
      return response;
    } catch (e) {
      debugPrint('OrderRepository: Error fetching user role: $e');
      return null;
    }
  }
}
