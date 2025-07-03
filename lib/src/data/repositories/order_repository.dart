// Import models
import '../../features/user_management/orders/data/models/order.dart';

// Import core services
import '../../core/utils/logger.dart';

// Import base repository
import 'base_repository.dart';

/// Repository for order management operations
class OrderRepository extends BaseRepository {
  final AppLogger _logger = AppLogger();

  OrderRepository() : super();

  /// Get orders by user ID
  Future<List<Order>> getOrdersByUserId(String userId) async {
    return executeQuery(() async {
      _logger.info('📦 [ORDER-REPO] Getting orders for user: $userId');

      final response = await client
          .from('orders')
          .select('''
            *,
            order_items(*),
            vendors!inner(id, business_name, logo_url),
            customers!inner(id, name, email)
          ''')
          .eq('customer_id', userId)
          .order('created_at', ascending: false);

      final orders = response.map((json) => Order.fromJson(json)).toList();
      _logger.info('✅ [ORDER-REPO] Retrieved ${orders.length} orders for user');
      return orders;
    });
  }

  /// Get orders by vendor ID
  Future<List<Order>> getOrdersByVendorId(String vendorId) async {
    return executeQuery(() async {
      _logger.info('🏪 [ORDER-REPO] Getting orders for vendor: $vendorId');

      final response = await client
          .from('orders')
          .select('''
            *,
            order_items(*),
            customers!inner(id, name, email, phone_number)
          ''')
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);

      final orders = response.map((json) => Order.fromJson(json)).toList();
      _logger.info('✅ [ORDER-REPO] Retrieved ${orders.length} orders for vendor');
      return orders;
    });
  }

  /// Get orders by status
  Future<List<Order>> getOrdersByStatus(String userId, OrderStatus status) async {
    return executeQuery(() async {
      _logger.info('📊 [ORDER-REPO] Getting orders with status: ${status.name} for user: $userId');

      final response = await client
          .from('orders')
          .select('''
            *,
            order_items(*),
            vendors!inner(id, business_name, logo_url)
          ''')
          .eq('customer_id', userId)
          .eq('status', status.name)
          .order('created_at', ascending: false);

      final orders = response.map((json) => Order.fromJson(json)).toList();
      _logger.info('✅ [ORDER-REPO] Retrieved ${orders.length} orders with status ${status.name}');
      return orders;
    });
  }

  /// Get single order by ID
  Future<Order?> getOrderById(String orderId) async {
    return executeQuery(() async {
      _logger.info('🔍 [ORDER-REPO] Getting order: $orderId');

      final response = await client
          .from('orders')
          .select('''
            *,
            order_items(*),
            vendors!inner(id, business_name, logo_url, contact_phone),
            customers!inner(id, name, email, phone_number)
          ''')
          .eq('id', orderId)
          .maybeSingle();

      if (response == null) {
        _logger.warning('⚠️ [ORDER-REPO] Order not found: $orderId');
        return null;
      }

      final order = Order.fromJson(response);
      _logger.info('✅ [ORDER-REPO] Retrieved order: ${order.orderNumber}');
      return order;
    });
  }

  /// Create new order
  Future<String?> createOrder(Map<String, dynamic> orderData) async {
    return executeQuery(() async {
      _logger.info('➕ [ORDER-REPO] Creating new order');

      // Generate order number
      final orderNumber = _generateOrderNumber();
      
      final orderPayload = {
        'order_number': orderNumber,
        'customer_id': orderData['customer_id'],
        'vendor_id': orderData['vendor_id'],
        'sales_agent_id': orderData['sales_agent_id'],
        'status': OrderStatus.pending.name,
        'delivery_method': orderData['delivery_method'],
        'delivery_date': orderData['delivery_date'],
        'delivery_address': orderData['delivery_address'],
        'payment_method': orderData['payment_method'],
        'payment_status': PaymentStatus.pending.name,
        'subtotal': orderData['subtotal'],
        'delivery_fee': orderData['delivery_fee'],
        'sst_amount': orderData['sst_amount'],
        'total_amount': orderData['total_amount'],
        'notes': orderData['notes'],
        'delivery_notes': orderData['delivery_notes'],
        'special_instructions': orderData['special_instructions'],
        'contact_phone': orderData['contact_phone'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await client
          .from('orders')
          .insert(orderPayload)
          .select('id')
          .single();

      final orderId = response['id'] as String;

      // Create order items
      if (orderData['items'] != null) {
        await _createOrderItems(orderId, orderData['items'] as List);
      }

      _logger.info('✅ [ORDER-REPO] Order created successfully: $orderId');
      return orderId;
    });
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    return executeQuery(() async {
      _logger.info('🔄 [ORDER-REPO] Updating order $orderId status to ${newStatus.name}');

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
          updateData['preparation_started_at'] = DateTime.now().toIso8601String();
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

      await client
          .from('orders')
          .update(updateData)
          .eq('id', orderId);

      _logger.info('✅ [ORDER-REPO] Order status updated successfully');
    });
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId, String reason) async {
    return executeQuery(() async {
      _logger.info('❌ [ORDER-REPO] Cancelling order: $orderId');

      await client
          .from('orders')
          .update({
            'status': OrderStatus.cancelled.name,
            'cancelled_at': DateTime.now().toIso8601String(),
            'cancellation_reason': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      _logger.info('✅ [ORDER-REPO] Order cancelled successfully');
    });
  }

  /// Get recent orders
  Future<List<Order>> getRecentOrders(String userId, {int limit = 10}) async {
    return executeQuery(() async {
      _logger.info('📋 [ORDER-REPO] Getting recent orders for user: $userId');

      final response = await client
          .from('orders')
          .select('''
            *,
            vendors!inner(id, business_name, logo_url)
          ''')
          .eq('customer_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      final orders = response.map((json) => Order.fromJson(json)).toList();
      _logger.info('✅ [ORDER-REPO] Retrieved ${orders.length} recent orders');
      return orders;
    });
  }

  /// Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics(String userId) async {
    return executeQuery(() async {
      _logger.info('📊 [ORDER-REPO] Getting order statistics for user: $userId');

      final response = await client
          .rpc('get_order_statistics', params: {'user_id': userId});

      _logger.info('✅ [ORDER-REPO] Retrieved order statistics');
      return response as Map<String, dynamic>;
    });
  }

  /// Watch order for real-time updates
  Stream<Order?> watchOrder(String orderId) {
    _logger.info('👁️ [ORDER-REPO] Watching order: $orderId');

    return client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((data) {
          if (data.isEmpty) return null;
          return Order.fromJson(data.first);
        });
  }

  /// Create order items
  Future<void> _createOrderItems(String orderId, List<dynamic> items) async {
    final orderItems = items.map((item) => {
      'order_id': orderId,
      'menu_item_id': item['productId'] ?? item['menu_item_id'],
      'name': item['name'],
      'quantity': item['quantity'],
      'unit_price': item['unitPrice'] ?? item['unit_price'],
      'subtotal': item['subtotal'],
      'customizations': item['customizations'],
      'notes': item['notes'],
      'created_at': DateTime.now().toIso8601String(),
    }).toList();

    await client.from('order_items').insert(orderItems);
    _logger.info('✅ [ORDER-REPO] Created ${orderItems.length} order items');
  }

  /// Generate unique order number
  String _generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(8);
    return 'GE${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}$timestamp';
  }
}
