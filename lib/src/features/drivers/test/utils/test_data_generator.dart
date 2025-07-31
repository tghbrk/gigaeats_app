import 'dart:math';
import 'package:flutter/foundation.dart';

import '../../../orders/data/models/order.dart';
import '../../data/models/grouped_order_history.dart';

/// Test data generator for creating mock order history data
/// Used for performance testing and UI validation with large datasets
class TestDataGenerator {
  static final Random _random = Random();
  
  static const List<String> _vendorNames = [
    'Nasi Lemak Delicious',
    'Char Kuey Teow Master',
    'Roti Canai Corner',
    'Laksa Paradise',
    'Satay King',
    'Dim Sum Palace',
    'Curry House',
    'Fried Rice Express',
    'Mee Goreng Station',
    'Teh Tarik Cafe',
    'Banana Leaf Restaurant',
    'Mamak 24/7',
    'Seafood Village',
    'BBQ Chicken House',
    'Vegetarian Delight',
  ];

  static const List<String> _customerNames = [
    'Ahmad Rahman',
    'Siti Nurhaliza',
    'Lim Wei Ming',
    'Priya Sharma',
    'Muhammad Ali',
    'Tan Mei Ling',
    'Raj Kumar',
    'Fatimah Zahra',
    'Chen Wei Jie',
    'Aisha Abdullah',
    'David Lim',
    'Sarah Wong',
    'Kumar Selvam',
    'Nurul Ain',
    'Jason Tan',
  ];

  static const List<String> _menuItems = [
    'Nasi Lemak',
    'Char Kuey Teow',
    'Roti Canai',
    'Laksa',
    'Satay',
    'Dim Sum',
    'Curry Chicken',
    'Fried Rice',
    'Mee Goreng',
    'Teh Tarik',
    'Rendang',
    'Ayam Penyet',
    'Fish & Chips',
    'Tom Yam',
    'Pad Thai',
  ];

  /// Generate a single mock order for testing
  static Order generateMockOrder({
    String? driverId,
    DateTime? deliveryTime,
    OrderStatus? status,
    bool includeEarnings = true,
  }) {
    final orderId = 'test_order_${_random.nextInt(999999)}';
    final orderNumber = 'ORD${_random.nextInt(999999).toString().padLeft(6, '0')}';
    final vendorName = _vendorNames[_random.nextInt(_vendorNames.length)];
    final customerName = _customerNames[_random.nextInt(_customerNames.length)];
    
    final baseAmount = 15.0 + (_random.nextDouble() * 85.0); // RM 15-100
    final deliveryFee = 3.0 + (_random.nextDouble() * 7.0); // RM 3-10
    final totalAmount = baseAmount + deliveryFee;
    final commissionAmount = includeEarnings ? totalAmount * 0.15 : 0.0; // 15% commission

    final actualDeliveryTime = deliveryTime ?? 
        DateTime.now().subtract(Duration(
          days: _random.nextInt(90), // Last 90 days
          hours: _random.nextInt(24),
          minutes: _random.nextInt(60),
        ));

    return Order(
      id: orderId,
      orderNumber: orderNumber,
      vendorId: 'vendor_${_random.nextInt(100)}',
      vendorName: vendorName,
      customerId: 'customer_${_random.nextInt(1000)}',
      customerName: customerName,
      status: status ?? (includeEarnings ? OrderStatus.delivered : OrderStatus.cancelled),
      subtotal: baseAmount,
      deliveryFee: deliveryFee,
      sstAmount: 0.0,
      totalAmount: totalAmount,
      commissionAmount: commissionAmount,
      deliveryDate: DateTime(actualDeliveryTime.year, actualDeliveryTime.month, actualDeliveryTime.day),
      createdAt: actualDeliveryTime.subtract(Duration(hours: 1, minutes: _random.nextInt(60))),
      updatedAt: actualDeliveryTime,
      actualDeliveryTime: actualDeliveryTime,
      assignedDriverId: driverId ?? 'test_driver_123',
      items: _generateMockOrderItems(orderId),
      deliveryAddress: Address(
        street: '${_random.nextInt(999)} Jalan Test ${_random.nextInt(99)}',
        city: 'Kuala Lumpur',
        state: 'Selangor',
        postalCode: '${40000 + _random.nextInt(9999)}',
        country: 'Malaysia',
      ),
      paymentStatus: 'completed',
      paymentMethod: 'cash',
    );
  }

  /// Generate mock order items for an order
  static List<OrderItem> _generateMockOrderItems(String orderId) {
    final itemCount = 1 + _random.nextInt(4); // 1-4 items
    return List.generate(itemCount, (index) {
      final menuItem = _menuItems[_random.nextInt(_menuItems.length)];
      final quantity = 1 + _random.nextInt(3); // 1-3 quantity
      final price = 8.0 + (_random.nextDouble() * 22.0); // RM 8-30

      return OrderItem(
        id: 'item_${orderId}_$index',
        menuItemId: 'menu_item_$index',
        name: menuItem,
        description: 'Delicious $menuItem prepared fresh',
        unitPrice: price,
        quantity: quantity,
        totalPrice: price * quantity,
        customizations: {},
      );
    });
  }

  /// Generate a large dataset of mock orders for performance testing
  static List<Order> generateLargeOrderDataset({
    String driverId = 'test_driver_123',
    int orderCount = 1000,
    int daysBack = 90,
    double deliveredRatio = 0.85, // 85% delivered, 15% cancelled
  }) {
    debugPrint('🧪 TestDataGenerator: Generating $orderCount orders over $daysBack days');
    
    final orders = <Order>[];
    final now = DateTime.now();
    
    for (int i = 0; i < orderCount; i++) {
      // Distribute orders across the time period
      final dayOffset = (i / orderCount * daysBack).floor();
      final deliveryTime = now.subtract(Duration(
        days: dayOffset,
        hours: _random.nextInt(24),
        minutes: _random.nextInt(60),
      ));

      // Determine if order is delivered or cancelled
      final isDelivered = _random.nextDouble() < deliveredRatio;
      final status = isDelivered ? OrderStatus.delivered : OrderStatus.cancelled;

      final order = generateMockOrder(
        driverId: driverId,
        deliveryTime: deliveryTime,
        status: status,
        includeEarnings: isDelivered,
      );

      orders.add(order);
    }

    // Sort by delivery time (newest first)
    orders.sort((a, b) => b.actualDeliveryTime!.compareTo(a.actualDeliveryTime!));
    
    debugPrint('🧪 TestDataGenerator: Generated ${orders.length} orders');
    debugPrint('🧪 TestDataGenerator: Date range: ${orders.last.actualDeliveryTime} to ${orders.first.actualDeliveryTime}');
    
    return orders;
  }

  /// Generate orders for specific date ranges for testing date filtering
  static List<Order> generateOrdersForDateRange({
    String driverId = 'test_driver_123',
    required DateTime startDate,
    required DateTime endDate,
    int ordersPerDay = 5,
  }) {
    final orders = <Order>[];
    final daysDifference = endDate.difference(startDate).inDays;
    
    debugPrint('🧪 TestDataGenerator: Generating orders for date range: $startDate to $endDate');
    
    for (int day = 0; day <= daysDifference; day++) {
      final currentDate = startDate.add(Duration(days: day));
      
      for (int orderIndex = 0; orderIndex < ordersPerDay; orderIndex++) {
        final deliveryTime = currentDate.add(Duration(
          hours: 8 + _random.nextInt(12), // Between 8 AM and 8 PM
          minutes: _random.nextInt(60),
        ));

        final order = generateMockOrder(
          driverId: driverId,
          deliveryTime: deliveryTime,
          status: _random.nextDouble() < 0.9 ? OrderStatus.delivered : OrderStatus.cancelled,
        );

        orders.add(order);
      }
    }

    orders.sort((a, b) => b.actualDeliveryTime!.compareTo(a.actualDeliveryTime!));
    
    debugPrint('🧪 TestDataGenerator: Generated ${orders.length} orders for date range');
    return orders;
  }

  /// Generate grouped order history for testing UI components
  static List<GroupedOrderHistory> generateGroupedOrderHistory({
    String driverId = 'test_driver_123',
    int daysBack = 30,
    int ordersPerDay = 8,
  }) {
    final orders = <Order>[];
    final now = DateTime.now();
    
    for (int day = 0; day < daysBack; day++) {
      final currentDate = now.subtract(Duration(days: day));
      
      for (int orderIndex = 0; orderIndex < ordersPerDay; orderIndex++) {
        final deliveryTime = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          8 + _random.nextInt(12), // 8 AM to 8 PM
          _random.nextInt(60),
        );

        final order = generateMockOrder(
          driverId: driverId,
          deliveryTime: deliveryTime,
        );

        orders.add(order);
      }
    }

    final groupedHistory = GroupedOrderHistory.fromOrders(orders);
    
    debugPrint('🧪 TestDataGenerator: Generated ${groupedHistory.length} grouped days');
    debugPrint('🧪 TestDataGenerator: Total orders: ${orders.length}');
    
    return groupedHistory;
  }

  /// Generate performance test data with specific characteristics
  static Map<String, dynamic> generatePerformanceTestData({
    int smallDatasetSize = 50,
    int mediumDatasetSize = 500,
    int largeDatasetSize = 2000,
    String driverId = 'test_driver_123',
  }) {
    debugPrint('🧪 TestDataGenerator: Generating performance test datasets');
    
    return {
      'small_dataset': generateLargeOrderDataset(
        driverId: driverId,
        orderCount: smallDatasetSize,
        daysBack: 7,
      ),
      'medium_dataset': generateLargeOrderDataset(
        driverId: driverId,
        orderCount: mediumDatasetSize,
        daysBack: 30,
      ),
      'large_dataset': generateLargeOrderDataset(
        driverId: driverId,
        orderCount: largeDatasetSize,
        daysBack: 90,
      ),
      'metadata': {
        'small_size': smallDatasetSize,
        'medium_size': mediumDatasetSize,
        'large_size': largeDatasetSize,
        'driver_id': driverId,
        'generated_at': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Generate test data for specific scenarios
  static Map<String, List<Order>> generateScenarioTestData({
    String driverId = 'test_driver_123',
  }) {
    final now = DateTime.now();
    
    return {
      'today_orders': generateOrdersForDateRange(
        driverId: driverId,
        startDate: DateTime(now.year, now.month, now.day),
        endDate: now,
        ordersPerDay: 12,
      ),
      'yesterday_orders': generateOrdersForDateRange(
        driverId: driverId,
        startDate: DateTime(now.year, now.month, now.day - 1),
        endDate: DateTime(now.year, now.month, now.day - 1, 23, 59),
        ordersPerDay: 8,
      ),
      'this_week_orders': generateOrdersForDateRange(
        driverId: driverId,
        startDate: now.subtract(Duration(days: now.weekday - 1)),
        endDate: now,
        ordersPerDay: 6,
      ),
      'this_month_orders': generateOrdersForDateRange(
        driverId: driverId,
        startDate: DateTime(now.year, now.month, 1),
        endDate: now,
        ordersPerDay: 4,
      ),
      'empty_period': <Order>[], // For testing empty states
    };
  }



  /// Calculate statistics for generated test data
  static Map<String, dynamic> calculateTestDataStatistics(List<Order> orders) {
    if (orders.isEmpty) {
      return {
        'total_orders': 0,
        'delivered_orders': 0,
        'cancelled_orders': 0,
        'total_earnings': 0.0,
        'average_order_value': 0.0,
        'date_range': null,
      };
    }

    final deliveredOrders = orders.where((o) => o.status == OrderStatus.delivered).toList();
    final cancelledOrders = orders.where((o) => o.status == OrderStatus.cancelled).toList();

    final totalEarnings = deliveredOrders.fold<double>(0.0, (sum, order) => sum + order.totalAmount);
    final averageOrderValue = deliveredOrders.isNotEmpty ? totalEarnings / deliveredOrders.length : 0.0;

    final sortedOrders = List<Order>.from(orders)
      ..sort((a, b) => a.actualDeliveryTime!.compareTo(b.actualDeliveryTime!));

    return {
      'total_orders': orders.length,
      'delivered_orders': deliveredOrders.length,
      'cancelled_orders': cancelledOrders.length,
      'total_earnings': totalEarnings,
      'average_order_value': averageOrderValue,
      'success_rate': orders.isNotEmpty ? deliveredOrders.length / orders.length : 0.0,
      'date_range': {
        'start': sortedOrders.first.actualDeliveryTime?.toIso8601String(),
        'end': sortedOrders.last.actualDeliveryTime?.toIso8601String(),
      },
    };
  }
}
