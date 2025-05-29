import 'package:uuid/uuid.dart';
import '../models/order.dart';

class OrderService {
  static const _uuid = Uuid();

  // Mock data storage - in production this would be API calls
  static final List<Order> _orders = [];

  Future<List<Order>> getOrders({
    String? salesAgentId,
    String? vendorId,
    String? customerId,
    OrderStatus? status,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    var filteredOrders = List<Order>.from(_orders);

    // For demo purposes, show all orders regardless of sales agent ID
    // In production, this would filter by actual sales agent assignments

    // Uncomment the lines below for production filtering:
    // if (salesAgentId != null) {
    //   filteredOrders = filteredOrders
    //       .where((order) => order.salesAgentId == salesAgentId)
    //       .toList();
    // }

    if (vendorId != null) {
      filteredOrders = filteredOrders
          .where((order) => order.vendorId == vendorId)
          .toList();
    }

    if (customerId != null) {
      filteredOrders = filteredOrders
          .where((order) => order.customerId == customerId)
          .toList();
    }

    if (status != null) {
      filteredOrders = filteredOrders
          .where((order) => order.status == status)
          .toList();
    }

    // Sort by creation date (newest first)
    filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filteredOrders;
  }

  Future<Order?> getOrderById(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  Future<Order> createOrder({
    required List<OrderItem> items,
    required String vendorId,
    required String vendorName,
    required String customerId,
    required String customerName,
    String? salesAgentId,
    String? salesAgentName,
    required DateTime deliveryDate,
    required Address deliveryAddress,
    String? notes,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Calculate totals
    final subtotal = items.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );

    // Malaysian SST is 6%
    final sstAmount = subtotal * 0.06;

    // Delivery fee calculation (simplified)
    final deliveryFee = _calculateDeliveryFee(subtotal);

    final totalAmount = subtotal + sstAmount + deliveryFee;

    // Commission calculation (7% for sales agents)
    final commissionAmount = salesAgentId != null ? subtotal * 0.07 : 0.0;

    final order = Order(
      id: _uuid.v4(),
      orderNumber: _generateOrderNumber(),
      status: OrderStatus.pending,
      items: items,
      vendorId: vendorId,
      vendorName: vendorName,
      customerId: customerId,
      customerName: customerName,
      salesAgentId: salesAgentId,
      salesAgentName: salesAgentName,
      deliveryDate: deliveryDate,
      deliveryAddress: deliveryAddress,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      sstAmount: sstAmount,
      totalAmount: totalAmount,
      commissionAmount: commissionAmount,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _orders.add(order);

    return order;
  }

  Future<Order> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    if (orderIndex == -1) {
      throw Exception('Order not found');
    }

    final updatedOrder = _orders[orderIndex].copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );

    _orders[orderIndex] = updatedOrder;

    return updatedOrder;
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    if (orderIndex == -1) {
      throw Exception('Order not found');
    }

    final updatedOrder = _orders[orderIndex].copyWith(
      status: OrderStatus.cancelled,
      updatedAt: DateTime.now(),
      metadata: {
        ...(_orders[orderIndex].metadata ?? {}),
        'cancellation_reason': reason,
        'cancelled_at': DateTime.now().toIso8601String(),
      },
    );

    _orders[orderIndex] = updatedOrder;
  }

  // Helper methods
  double _calculateDeliveryFee(double subtotal) {
    // Simplified delivery fee calculation
    if (subtotal >= 200) return 0.0; // Free delivery for orders above RM 200
    if (subtotal >= 100) return 5.0; // RM 5 for orders above RM 100
    return 10.0; // RM 10 for smaller orders
  }

  String _generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(8);
    return 'GE$timestamp';
  }

  // Mock data generation for development
  static void generateMockOrders() {
    if (_orders.isNotEmpty) return; // Don't regenerate if already exists

    final mockOrders = [
      Order(
        id: 'order_001',
        orderNumber: 'GE1001',
        status: OrderStatus.pending,
        items: [
          OrderItem(
            id: _uuid.v4(),
            menuItemId: 'item1',
            name: 'Nasi Lemak Set',
            description: 'Traditional Malaysian breakfast',
            unitPrice: 12.50,
            quantity: 20,
            totalPrice: 250.00,
          ),
        ],
        vendorId: 'vendor_1',
        vendorName: 'Nasi Lemak Wangi',
        customerId: 'cust_001',
        customerName: 'Tech Solutions Sdn Bhd',
        salesAgentId: 'default_agent', // Use default agent for demo
        salesAgentName: 'Sales Agent',
        deliveryDate: DateTime.now().add(const Duration(days: 1)),
        deliveryAddress: const Address(
          street: 'Level 15, Menara TM, Jalan Pantai Baharu',
          city: 'Kuala Lumpur',
          state: 'Kuala Lumpur',
          postalCode: '59200',
          country: 'Malaysia',
        ),
        subtotal: 250.00,
        deliveryFee: 5.00,
        sstAmount: 15.00,
        totalAmount: 270.00,
        commissionAmount: 17.50,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Order(
        id: 'order_002',
        orderNumber: 'GE1002',
        status: OrderStatus.confirmed,
        items: [
          OrderItem(
            id: _uuid.v4(),
            menuItemId: 'item2',
            name: 'Chicken Biryani',
            description: 'Fragrant basmati rice with tender chicken',
            unitPrice: 15.00,
            quantity: 15,
            totalPrice: 225.00,
          ),
        ],
        vendorId: 'vendor_3',
        vendorName: 'Spice Garden Indian Kitchen',
        customerId: 'cust_002',
        customerName: 'SMK Taman Desa',
        salesAgentId: 'default_agent',
        salesAgentName: 'Sales Agent',
        deliveryDate: DateTime.now().add(const Duration(hours: 4)),
        deliveryAddress: const Address(
          street: 'Jalan Desa Utama 1/2',
          city: 'Kuala Lumpur',
          state: 'Kuala Lumpur',
          postalCode: '58100',
          country: 'Malaysia',
        ),
        subtotal: 225.00,
        deliveryFee: 5.00,
        sstAmount: 13.50,
        totalAmount: 243.50,
        commissionAmount: 15.75,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Order(
        id: 'order_003',
        orderNumber: 'GE1003',
        status: OrderStatus.delivered,
        items: [
          OrderItem(
            id: _uuid.v4(),
            menuItemId: 'item3',
            name: 'Mixed Dim Sum Platter',
            description: 'Assorted dim sum including har gow and siu mai',
            unitPrice: 25.00,
            quantity: 8,
            totalPrice: 200.00,
          ),
        ],
        vendorId: 'vendor_2',
        vendorName: 'Dragon Palace Chinese Cuisine',
        customerId: 'cust_003',
        customerName: 'Hospital Kuala Lumpur',
        salesAgentId: 'default_agent',
        salesAgentName: 'Sales Agent',
        deliveryDate: DateTime.now().subtract(const Duration(days: 1)),
        deliveryAddress: const Address(
          street: 'Jalan Pahang',
          city: 'Kuala Lumpur',
          state: 'Kuala Lumpur',
          postalCode: '53000',
          country: 'Malaysia',
        ),
        subtotal: 200.00,
        deliveryFee: 0.00, // Free delivery for orders above RM 200
        sstAmount: 12.00,
        totalAmount: 212.00,
        commissionAmount: 14.00,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    _orders.addAll(mockOrders);
  }
}
