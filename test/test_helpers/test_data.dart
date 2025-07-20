import 'package:gigaeats/src/features/drivers/data/models/route_optimization_models.dart';
import 'package:gigaeats/src/features/drivers/data/models/batch_analytics_models.dart';
import 'package:gigaeats/src/features/drivers/data/models/notification_models.dart';
import 'package:gigaeats/src/features/drivers/data/models/delivery_batch.dart';
import 'package:gigaeats/src/features/drivers/data/models/navigation_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Comprehensive test data helpers for Phase 5.1 validation
/// Provides mock data for all multi-order workflow components
class TestData {
  /// Create multiple test orders for batch testing
  static List<Map<String, dynamic>> createMultipleTestOrders({
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
  static Map<String, dynamic> createTestLocation({
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return {
      'latitude': latitude ?? 3.1390,
      'longitude': longitude ?? 101.6869,
      'address': address ?? 'Test Location, Kuala Lumpur',
      'accuracy': 10.0,
      'timestamp': DateTime.now().toIso8601String(),
    };
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
        timeWeight: 0.2,
        trafficWeight: 0.1,
        deliveryWindowWeight: 0.1,
      );
    } else if (prioritizeTime) {
      return OptimizationCriteria(
        distanceWeight: 0.2,
        timeWeight: 0.6,
        trafficWeight: 0.1,
        deliveryWindowWeight: 0.1,
      );
    } else if (prioritizeTraffic) {
      return OptimizationCriteria(
        distanceWeight: 0.2,
        timeWeight: 0.2,
        trafficWeight: 0.5,
        deliveryWindowWeight: 0.1,
      );
    } else {
      return OptimizationCriteria(
        distanceWeight: 0.4,
        timeWeight: 0.3,
        trafficWeight: 0.2,
        deliveryWindowWeight: 0.1,
      );
    }
  }

  /// Create orders with different preparation times
  static List<Map<String, dynamic>> createOrdersWithDifferentPrepTimes() {
    return [
      {
        ...createMultipleTestOrders(count: 1).first,
        'id': 'order-fast-prep',
        'preparationTimeMinutes': 10,
        'vendorName': 'Fast Food Place',
      },
      {
        ...createMultipleTestOrders(count: 1).first,
        'id': 'order-medium-prep',
        'preparationTimeMinutes': 25,
        'vendorName': 'Regular Restaurant',
      },
      {
        ...createMultipleTestOrders(count: 1).first,
        'id': 'order-slow-prep',
        'preparationTimeMinutes': 45,
        'vendorName': 'Gourmet Kitchen',
      },
    ];
  }

  /// Create orders with delivery windows
  static List<Map<String, dynamic>> createOrdersWithDeliveryWindows() {
    final now = DateTime.now();
    return [
      {
        ...createMultipleTestOrders(count: 1).first,
        'id': 'order-morning-window',
        'deliveryWindowStart': now.add(const Duration(hours: 1)),
        'deliveryWindowEnd': now.add(const Duration(hours: 2)),
      },
      {
        ...createMultipleTestOrders(count: 1).first,
        'id': 'order-afternoon-window',
        'deliveryWindowStart': now.add(const Duration(hours: 3)),
        'deliveryWindowEnd': now.add(const Duration(hours: 4)),
      },
    ];
  }

  /// Create orders with urgent deliveries
  static List<Map<String, dynamic>> createOrdersWithUrgentDeliveries() {
    return [
      {
        ...createMultipleTestOrders(count: 1).first,
        'id': 'order-urgent-1',
        'isUrgent': true,
        'priority': 'high',
      },
      {
        ...createMultipleTestOrders(count: 1).first,
        'id': 'order-normal-1',
        'isUrgent': false,
        'priority': 'normal',
      },
      {
        ...createMultipleTestOrders(count: 1).first,
        'id': 'order-urgent-2',
        'isUrgent': true,
        'priority': 'high',
      },
    ];
  }

  /// Create orders with invalid locations for error testing
  static List<Map<String, dynamic>> createOrdersWithInvalidLocations() {
    return [
      {
        ...createMultipleTestOrders(count: 1).first,
        'vendorLatitude': 200.0, // Invalid
        'vendorLongitude': 200.0, // Invalid
      },
    ];
  }

  /// Create batch orders with details for notification testing
  static List<BatchOrderWithDetails> createBatchOrdersWithDetails({required int count}) {
    final orders = createMultipleTestOrders(count: count);
    return orders.map((orderData) => BatchOrderWithDetails(
      order: BatchOrder(
        id: orderData['id'],
        batchId: 'batch-123',
        orderId: orderData['id'],
        customerId: orderData['customerId'],
        vendorId: orderData['vendorId'],
        vendorName: orderData['vendorName'],
        orderNumber: orderData['orderNumber'],
        sequenceNumber: orders.indexOf(orderData) + 1,
        status: BatchOrderStatus.assigned,
        pickupLocation: LatLng(
          orderData['vendorLatitude'],
          orderData['vendorLongitude'],
        ),
        deliveryLocation: LatLng(
          orderData['deliveryLatitude'],
          orderData['deliveryLongitude'],
        ),
        estimatedPickupTime: DateTime.now().add(const Duration(minutes: 15)),
        estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 45)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      orderDetails: orderData,
    )).toList();
  }

  /// Create navigation instruction for voice testing
  static NavigationInstruction createNavigationInstruction({
    String? text,
    NavigationInstructionType? type,
  }) {
    return NavigationInstruction(
      id: 'instruction-${DateTime.now().millisecondsSinceEpoch}',
      type: type ?? NavigationInstructionType.turnLeft,
      text: text ?? 'Turn left onto Jalan Test',
      voiceText: text ?? 'Turn left onto Jalan Test',
      distanceToInstruction: 100,
      distanceText: '100m',
      streetName: 'Jalan Test',
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
      voiceText: 'In 100 meters, turn right onto Jalan Ampang',
      distanceToInstruction: 100,
      distanceText: '100m',
      streetName: 'Jalan Ampang',
    );
  }
}
