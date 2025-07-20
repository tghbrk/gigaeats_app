import 'package:gigaeats_app/src/features/drivers/data/models/route_optimization_models.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/batch_analytics_models.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/delivery_batch.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/batch_operation_results.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/navigation_models.dart';
import 'package:gigaeats_app/src/features/orders/data/models/order.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Comprehensive test data helpers for Phase 5.1 validation
/// Provides mock data for all multi-order workflow components
class TestData {
  /// Create multiple test orders for batch testing (returns Order objects)
  static List<Order> createMultipleTestOrders({
    required int count,
    String? vendorId,
    String? customerId,
  }) {
    return List.generate(count, (index) => Order(
      id: 'order-${DateTime.now().millisecondsSinceEpoch}-$index',
      orderNumber: 'ORD-TEST-${1000 + index}',
      vendorId: vendorId ?? 'vendor-${index % 3 + 1}',
      vendorName: 'Test Restaurant ${index % 3 + 1}',
      customerId: customerId ?? 'customer-${index + 1}',
      customerName: 'Customer ${index + 1}',
      status: OrderStatus.ready,
      items: [
        OrderItem(
          id: 'item-$index',
          menuItemId: 'menu-item-$index',
          name: 'Test Item $index',
          description: 'Test description',
          unitPrice: 20.0,
          quantity: 1,
          totalPrice: 20.0,
        ),
      ],
      deliveryDate: DateTime.now().add(Duration(hours: 1)),
      deliveryAddress: Address(
        street: '${200 + index} Customer Street',
        city: 'Kuala Lumpur',
        state: 'Selangor',
        postalCode: '50000',
        country: 'Malaysia',
        latitude: 3.1590 + (index * 0.001),
        longitude: 101.7069 + (index * 0.001),
      ),
      subtotal: 20.0,
      deliveryFee: 5.0,
      sstAmount: 1.5,
      totalAmount: 26.5 + (index * 5.0),
      createdAt: DateTime.now().subtract(Duration(minutes: index * 5)),
      updatedAt: DateTime.now(),
    ));
  }

  /// Create multiple test orders for batch testing (returns Map data for legacy tests)
  static List<Map<String, dynamic>> createMultipleTestOrdersData({
    required int count,
    String? vendorId,
    String? customerId,
  }) {
    return List.generate(count, (index) => {
      'id': 'order-${DateTime.now().millisecondsSinceEpoch}-$index',
      'orderNumber': 'ORD-TEST-${1000 + index}',
      'vendorId': vendorId ?? 'vendor-${index % 3 + 1}',
      'vendorName': 'Test Restaurant ${index % 3 + 1}',
      'vendorAddress': '${100 + index} Vendor Street, KL',
      'vendorLatitude': 3.1390 + (index * 0.001),
      'vendorLongitude': 101.6869 + (index * 0.001),
      'customerId': customerId ?? 'customer-${index + 1}',
      'customerName': 'Customer ${index + 1}',
      'customerPhone': '+6012345${6789 + index}',
      'deliveryAddress': '${200 + index} Customer Street, KL',
      'deliveryLatitude': 3.1590 + (index * 0.001),
      'deliveryLongitude': 101.7069 + (index * 0.001),
      'totalAmount': 25.50 + (index * 5.0),
      'deliveryFee': 5.0,
      'status': 'confirmed',
      'preparationTimeMinutes': 20 + (index * 5),
      'specialInstructions': index % 2 == 0 ? 'Extra spicy' : null,
      'estimatedDeliveryTime': DateTime.now().add(Duration(minutes: 30 + (index * 10))),
      'createdAt': DateTime.now().subtract(Duration(minutes: index * 5)),
      'isUrgent': index == 0, // First order is urgent
    });
  }

  /// Create test driver data
  static Map<String, dynamic> createTestDriver({
    String? id,
    String? name,
    String? phone,
  }) {
    return {
      'id': id ?? 'driver-${DateTime.now().millisecondsSinceEpoch}',
      'name': name ?? 'Test Driver',
      'phone': phone ?? '+60123456789',
      'email': 'driver.test@gigaeats.com',
      'vehicleType': 'motorcycle',
      'vehiclePlate': 'ABC1234',
      'status': 'online',
      'currentLatitude': 3.1390,
      'currentLongitude': 101.6869,
      'rating': 4.5,
      'totalDeliveries': 150,
      'isActive': true,
    };
  }

  /// Create test location data
  static LatLng createTestLocation({
    double? latitude,
    double? longitude,
  }) {
    return LatLng(
      latitude ?? 3.1390,
      longitude ?? 101.6869,
    );
  }

  /// Create invalid location for error testing
  static Map<String, dynamic> createInvalidLocation() {
    return {
      'latitude': 200.0, // Invalid latitude
      'longitude': 200.0, // Invalid longitude
      'address': '',
      'accuracy': -1.0, // Invalid accuracy
    };
  }

  /// Create optimization criteria for route testing
  static OptimizationCriteria createOptimizationCriteria({
    bool prioritizeDistance = false,
    bool prioritizeTime = false,
    bool prioritizeTraffic = false,
  }) {
    if (prioritizeDistance) {
      return OptimizationCriteria(
        distanceWeight: 0.6,
        preparationTimeWeight: 0.2,
        trafficWeight: 0.1,
        deliveryWindowWeight: 0.1,
      );
    } else if (prioritizeTime) {
      return OptimizationCriteria(
        distanceWeight: 0.2,
        preparationTimeWeight: 0.6,
        trafficWeight: 0.1,
        deliveryWindowWeight: 0.1,
      );
    } else if (prioritizeTraffic) {
      return OptimizationCriteria(
        distanceWeight: 0.2,
        preparationTimeWeight: 0.2,
        trafficWeight: 0.5,
        deliveryWindowWeight: 0.1,
      );
    } else {
      return OptimizationCriteria(
        distanceWeight: 0.4,
        preparationTimeWeight: 0.3,
        trafficWeight: 0.2,
        deliveryWindowWeight: 0.1,
      );
    }
  }

  /// Create orders with different preparation times
  static List<Map<String, dynamic>> createOrdersWithDifferentPrepTimes() {
    final baseOrder = createMultipleTestOrders(count: 1).first.toJson();
    return [
      {
        ...baseOrder,
        'id': 'order-fast-prep',
        'preparationTimeMinutes': 10,
        'vendorName': 'Fast Food Place',
      },
      {
        ...baseOrder,
        'id': 'order-medium-prep',
        'preparationTimeMinutes': 25,
        'vendorName': 'Regular Restaurant',
      },
      {
        ...baseOrder,
        'id': 'order-slow-prep',
        'preparationTimeMinutes': 45,
        'vendorName': 'Gourmet Kitchen',
      },
    ];
  }

  /// Create orders with delivery windows
  static List<Map<String, dynamic>> createOrdersWithDeliveryWindows() {
    final now = DateTime.now();
    final baseOrder = createMultipleTestOrders(count: 1).first.toJson();
    return [
      {
        ...baseOrder,
        'id': 'order-morning-window',
        'deliveryWindowStart': now.add(const Duration(hours: 1)),
        'deliveryWindowEnd': now.add(const Duration(hours: 2)),
      },
      {
        ...baseOrder,
        'id': 'order-afternoon-window',
        'deliveryWindowStart': now.add(const Duration(hours: 3)),
        'deliveryWindowEnd': now.add(const Duration(hours: 4)),
      },
    ];
  }

  /// Create orders with urgent deliveries
  static List<Map<String, dynamic>> createOrdersWithUrgentDeliveries() {
    final baseOrder = createMultipleTestOrders(count: 1).first.toJson();
    return [
      {
        ...baseOrder,
        'id': 'order-urgent-1',
        'isUrgent': true,
        'priority': 'high',
      },
      {
        ...baseOrder,
        'id': 'order-normal-1',
        'isUrgent': false,
        'priority': 'normal',
      },
      {
        ...baseOrder,
        'id': 'order-urgent-2',
        'isUrgent': true,
        'priority': 'high',
      },
    ];
  }

  /// Create orders with invalid locations for error testing
  static List<Map<String, dynamic>> createOrdersWithInvalidLocations() {
    final baseOrder = createMultipleTestOrders(count: 1).first.toJson();
    return [
      {
        ...baseOrder,
        'vendorLatitude': 200.0, // Invalid
        'vendorLongitude': 200.0, // Invalid
      },
    ];
  }

  /// Create batch orders with details for notification testing
  static List<BatchOrderWithDetails> createBatchOrdersWithDetails({required int count}) {
    final orders = createMultipleTestOrders(count: count);
    return orders.asMap().entries.map((entry) {
      final index = entry.key;
      final order = entry.value;

      final batchOrder = BatchOrder(
        id: 'batch-order-${order.id}',
        batchId: 'batch-123',
        orderId: order.id,
        pickupSequence: index + 1,
        deliverySequence: index + 1,
        estimatedPickupTime: DateTime.now().add(Duration(minutes: 20 + (index * 10))),
        estimatedDeliveryTime: DateTime.now().add(Duration(minutes: 45 + (index * 10))),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return BatchOrderWithDetails(
        batchOrder: batchOrder,
        order: order,
      );
    }).toList();
  }

  /// Create navigation instruction for voice testing
  static NavigationInstruction createNavigationInstruction({
    String? text,
    NavigationInstructionType? type,
  }) {
    final instructionText = text ?? 'Turn left onto Jalan Test';
    return NavigationInstruction(
      id: 'instruction-${DateTime.now().millisecondsSinceEpoch}',
      type: type ?? NavigationInstructionType.turnLeft,
      text: instructionText,
      htmlText: '<div>$instructionText</div>',
      distanceMeters: 100.0,
      durationSeconds: 30,
      location: const LatLng(3.1390, 101.6869),
      streetName: 'Jalan Test',
      timestamp: DateTime.now(),
    );
  }

  /// Create PostgreSQL change payload for real-time testing
  static PostgresChangePayload createPostgresChangePayload({
    String? eventType,
    Map<String, dynamic>? newRecord,
  }) {
    return PostgresChangePayload(
      eventType: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'delivery_batches',
      commitTimestamp: DateTime.now(),
      newRecord: newRecord ?? {
        'id': 'batch-123',
        'driver_id': 'driver-123',
        'status': 'created',
        'created_at': DateTime.now().toIso8601String(),
      },
      oldRecord: {},
      errors: null,
    );
  }

  /// Create analytics events for testing
  static List<AnalyticsEvent> createAnalyticsEvents({required int count}) {
    return List.generate(count, (index) => AnalyticsEvent.batchCreated(
      driverId: 'driver-123',
      batchId: 'batch-$index',
      data: {
        'order_count': 3 + index,
        'estimated_distance': 10.0 + index,
        'optimization_score': 0.8 + (index * 0.02),
      },
    ));
  }

  /// Create mock navigation instruction
  static NavigationInstruction mockNavigationInstruction() {
    return NavigationInstruction(
      id: 'nav-instruction-123',
      type: NavigationInstructionType.turnRight,
      text: 'Turn right onto Jalan Ampang',
      htmlText: '<div>Turn right onto Jalan Ampang</div>',
      distanceMeters: 100.0,
      durationSeconds: 45,
      location: const LatLng(3.1590, 101.7069),
      streetName: 'Jalan Ampang',
      timestamp: DateTime.now(),
    );
  }
}
