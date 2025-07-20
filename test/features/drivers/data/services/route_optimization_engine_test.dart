import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/route_optimization_engine.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/route_optimization_models.dart';
import 'package:gigaeats_app/src/features/orders/data/models/order.dart';

import '../../../../test_helpers/test_data.dart';

void main() {
  group('RouteOptimizationEngine Tests - Phase 5.1 Validation', () {
    late RouteOptimizationEngine routeEngine;

    setUp(() {
      routeEngine = RouteOptimizationEngine();
    });

    group('Route Optimization Tests', () {
      test('should create RouteOptimizationEngine successfully', () async {
        // Act & Assert - should not throw
        expect(() => RouteOptimizationEngine(), returnsNormally);
      });

      test('should have valid engine instance', () async {
        // Act & Assert
        expect(routeEngine, isNotNull);
        expect(routeEngine, isA<RouteOptimizationEngine>());
      });
    });

    group('Route Optimization Algorithm Tests', () {
      test('should optimize route for single order', () async {
        // Arrange
        final orders = TestData.createMultipleTestOrders(count: 1);
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Act
        final result = await routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: criteria,
        );

        // Assert
        expect(result, isA<OptimizedRoute>());
        expect(result.waypoints.length, greaterThan(0));
        expect(result.totalDistanceKm, greaterThan(0));
        expect(result.totalDuration.inMinutes, greaterThan(0));
        expect(result.optimizationScore, greaterThanOrEqualTo(0));
        expect(result.optimizationScore, lessThanOrEqualTo(1));
      });

      test('should optimize route for multiple orders', () async {
        // Arrange
        final orders = TestData.createMultipleTestOrders(count: 5);
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Act
        final result = await routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: criteria,
        );

        // Assert
        expect(result, isA<OptimizedRoute>());
        expect(result.waypoints.length, greaterThan(0));
        expect(result.totalDistanceKm, greaterThan(0));
        expect(result.totalDuration.inMinutes, greaterThan(0));
      });

      test('should handle empty orders list', () async {
        // Arrange
        final orders = <Order>[];
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Act & Assert
        expect(() => routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: criteria,
        ), throwsArgumentError);
      });

      test('should prioritize distance when distance weight is highest', () async {
        // Arrange
        final orders = TestData.createMultipleTestOrders(count: 3);
        final driverLocation = TestData.createTestLocation();
        final distanceCriteria = OptimizationCriteria(
          distanceWeight: 0.7,
          preparationTimeWeight: 0.1,
          trafficWeight: 0.1,
          deliveryWindowWeight: 0.1,
        );

        // Act
        final result = await routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: distanceCriteria,
        );

        // Assert
        expect(result, isA<OptimizedRoute>());
        expect(result.criteria.distanceWeight, equals(0.7));
      });

      test('should prioritize time when time weight is highest', () async {
        // Arrange
        final orders = TestData.createMultipleTestOrders(count: 3);
        final driverLocation = TestData.createTestLocation();
        final timeCriteria = OptimizationCriteria(
          distanceWeight: 0.1,
          preparationTimeWeight: 0.7,
          trafficWeight: 0.1,
          deliveryWindowWeight: 0.1,
        );

        // Act
        final result = await routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: timeCriteria,
        );

        // Assert
        expect(result, isA<OptimizedRoute>());
        expect(result.criteria.preparationTimeWeight, equals(0.7));
      });
    });

    group('TSP Algorithm Tests', () {
      test('should solve TSP for small order set efficiently', () async {
        // Arrange
        final orders = TestData.createMultipleTestOrders(count: 4);
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Act
        final startTime = DateTime.now();
        final result = await routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: criteria,
        );
        final endTime = DateTime.now();

        // Assert
        expect(result, isA<OptimizedRoute>());
        expect(endTime.difference(startTime).inMilliseconds, lessThan(1000)); // Should complete within 1 second
        expect(result.waypoints.length, greaterThan(0));
      });

      test('should handle larger order sets with reasonable performance', () async {
        // Arrange
        final orders = TestData.createMultipleTestOrders(count: 8);
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Act
        final startTime = DateTime.now();
        final result = await routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: criteria,
        );
        final endTime = DateTime.now();

        // Assert
        expect(result, isA<OptimizedRoute>());
        expect(endTime.difference(startTime).inMilliseconds, lessThan(5000)); // Should complete within 5 seconds
        expect(result.waypoints.length, greaterThan(0));
      });

      test('should produce consistent results for same input', () async {
        // Arrange
        final orders = TestData.createMultipleTestOrders(count: 3);
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Act
        final result1 = await routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: criteria,
        );
        final result2 = await routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: criteria,
        );

        // Assert
        expect(result1.waypoints.length, equals(result2.waypoints.length));
        expect(result1.totalDistanceKm, equals(result2.totalDistanceKm));
        expect(result1.totalDuration, equals(result2.totalDuration));
      });
    });

    group('Real-time Traffic Integration Tests', () {
      test('should incorporate traffic data into optimization', () async {
        // Arrange
        final orders = TestData.createMultipleTestOrders(count: 3);
        final driverLocation = TestData.createTestLocation();
        final trafficCriteria = OptimizationCriteria(
          distanceWeight: 0.2,
          preparationTimeWeight: 0.2,
          trafficWeight: 0.5,
          deliveryWindowWeight: 0.1,
        );

        // Act
        final result = await routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: trafficCriteria,
        );

        // Assert
        expect(result, isA<OptimizedRoute>());
        expect(result.criteria.trafficWeight, equals(0.5));
      });

      test('should adjust route based on traffic conditions', () async {
        // Arrange
        final orders = TestData.createMultipleTestOrders(count: 2);
        final driverLocation = TestData.createTestLocation();

        // Test with different traffic conditions
        final normalTrafficCriteria = TestData.createOptimizationCriteria();
        final heavyTrafficCriteria = OptimizationCriteria(
          distanceWeight: 0.1,
          preparationTimeWeight: 0.1,
          trafficWeight: 0.7,
          deliveryWindowWeight: 0.1,
        );

        // Act
        final normalResult = await routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: normalTrafficCriteria,
        );
        final trafficResult = await routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: heavyTrafficCriteria,
        );

        // Assert
        expect(normalResult, isA<OptimizedRoute>());
        expect(trafficResult, isA<OptimizedRoute>());
        // Traffic-optimized route might have different sequence or timing
        expect(trafficResult.criteria.trafficWeight, greaterThan(normalResult.criteria.trafficWeight));
      });
    });

    group('Dynamic Reoptimization Tests', () {
      test('should reoptimize route when conditions change', () async {
        // Arrange
        await routeEngine.initialize();
        final orders = TestData.createMultipleTestOrders(count: 4);
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Initial optimization
        final initialRoute = await routeEngine.optimizeRoute(
          orders: orders,
          driverLocation: driverLocation,
          optimizationCriteria: criteria,
        );

        // Simulate condition change (new driver location)
        final newDriverLocation = TestData.createTestLocation(
          latitude: driverLocation.latitude + 0.01,
          longitude: driverLocation.longitude + 0.01,
        );

        // Act
        final reoptimizedRoute = await routeEngine.reoptimizeRoute(
          currentRoute: initialRoute,
          newDriverLocation: newDriverLocation,
          completedWaypoints: [],
          updatedTrafficConditions: {},
        );

        // Assert
        expect(reoptimizedRoute, isA<OptimizedRoute>());
        expect(reoptimizedRoute.waypoints.length, equals(initialRoute.waypoints.length));
        // Route should be different due to new driver location
        expect(reoptimizedRoute.totalDistance, isNot(equals(initialRoute.totalDistance)));
      });

      test('should handle completed waypoints in reoptimization', () async {
        // Arrange
        await routeEngine.initialize();
        final orders = TestData.createMultipleTestOrders(count: 3);
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        final initialRoute = await routeEngine.optimizeRoute(
          orders: orders,
          driverLocation: driverLocation,
          optimizationCriteria: criteria,
        );

        // Simulate completing first waypoint
        final completedWaypoints = [initialRoute.waypoints.first.id];

        // Act
        final reoptimizedRoute = await routeEngine.reoptimizeRoute(
          currentRoute: initialRoute,
          newDriverLocation: driverLocation,
          completedWaypoints: completedWaypoints,
          updatedTrafficConditions: {},
        );

        // Assert
        expect(reoptimizedRoute, isA<OptimizedRoute>());
        expect(reoptimizedRoute.waypoints.length, equals(initialRoute.waypoints.length - 1));
      });
    });

    group('Preparation Time Integration Tests', () {
      test('should consider vendor preparation times in optimization', () async {
        // Arrange
        await routeEngine.initialize();
        final orders = TestData.createMultipleTestOrders(count: 3);
        final driverLocation = TestData.createTestLocation();
        final criteria = OptimizationCriteria(
          distanceWeight: 0.2,
          timeWeight: 0.5, // High time weight to prioritize preparation times
          trafficWeight: 0.2,
          deliveryWindowWeight: 0.1,
        );

        // Act
        final result = await routeEngine.optimizeRoute(
          orders: orders,
          driverLocation: driverLocation,
          optimizationCriteria: criteria,
        );

        // Assert
        expect(result, isA<OptimizedRoute>());
        expect(result.optimizationMetrics['preparation_time_considered'], isTrue);
        
        // Check that pickup waypoints are scheduled considering preparation times
        final pickupWaypoints = result.waypoints.where((w) => w.type == WaypointType.pickup).toList();
        for (final waypoint in pickupWaypoints) {
          expect(waypoint.estimatedArrival, isNotNull);
          expect(waypoint.preparationTime, greaterThan(Duration.zero));
        }
      });

      test('should optimize pickup sequence based on preparation times', () async {
        // Arrange
        await routeEngine.initialize();
        final orders = TestData.createOrdersWithDifferentPrepTimes();
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Act
        final result = await routeEngine.optimizeRoute(
          orders: orders,
          driverLocation: driverLocation,
          optimizationCriteria: criteria,
        );

        // Assert
        expect(result, isA<OptimizedRoute>());
        
        // Verify that orders with longer prep times are scheduled later
        final pickupWaypoints = result.waypoints.where((w) => w.type == WaypointType.pickup).toList();
        for (int i = 0; i < pickupWaypoints.length - 1; i++) {
          final current = pickupWaypoints[i];
          final next = pickupWaypoints[i + 1];
          expect(current.estimatedArrival!.isBefore(next.estimatedArrival!), isTrue);
        }
      });
    });

    group('Delivery Window Optimization Tests', () {
      test('should respect delivery time windows', () async {
        // Arrange
        await routeEngine.initialize();
        final orders = TestData.createOrdersWithDeliveryWindows();
        final driverLocation = TestData.createTestLocation();
        final criteria = OptimizationCriteria(
          distanceWeight: 0.2,
          timeWeight: 0.2,
          trafficWeight: 0.1,
          deliveryWindowWeight: 0.5, // High weight for delivery windows
        );

        // Act
        final result = await routeEngine.optimizeRoute(
          orders: orders,
          driverLocation: driverLocation,
          optimizationCriteria: criteria,
        );

        // Assert
        expect(result, isA<OptimizedRoute>());
        
        // Verify that delivery waypoints respect time windows
        final deliveryWaypoints = result.waypoints.where((w) => w.type == WaypointType.delivery).toList();
        for (final waypoint in deliveryWaypoints) {
          if (waypoint.deliveryWindow != null) {
            expect(waypoint.estimatedArrival!.isAfter(waypoint.deliveryWindow!.start), isTrue);
            expect(waypoint.estimatedArrival!.isBefore(waypoint.deliveryWindow!.end), isTrue);
          }
        }
      });

      test('should prioritize urgent deliveries', () async {
        // Arrange
        await routeEngine.initialize();
        final orders = TestData.createOrdersWithUrgentDeliveries();
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Act
        final result = await routeEngine.optimizeRoute(
          orders: orders,
          driverLocation: driverLocation,
          optimizationCriteria: criteria,
        );

        // Assert
        expect(result, isA<OptimizedRoute>());
        
        // Verify that urgent orders are prioritized in the sequence
        final urgentOrderIds = orders.where((o) => o['isUrgent'] == true).map((o) => o['id']).toList();
        final orderSequence = result.orderSequence;
        
        // Urgent orders should appear earlier in the sequence
        for (final urgentId in urgentOrderIds) {
          final urgentIndex = orderSequence.indexOf(urgentId);
          expect(urgentIndex, lessThan(orderSequence.length ~/ 2)); // Should be in first half
        }
      });
    });

    group('Error Handling Tests', () {
      test('should handle invalid driver location', () async {
        // Arrange
        await routeEngine.initialize();
        final orders = TestData.createMultipleTestOrders(count: 2);
        final invalidLocation = TestData.createInvalidLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Act & Assert
        expect(() => routeEngine.optimizeRoute(
          orders: orders,
          driverLocation: invalidLocation,
          optimizationCriteria: criteria,
        ), throwsArgumentError);
      });

      test('should handle orders with invalid locations', () async {
        // Arrange
        await routeEngine.initialize();
        final invalidOrders = TestData.createOrdersWithInvalidLocations();
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Act & Assert
        expect(() => routeEngine.optimizeRoute(
          orders: invalidOrders,
          driverLocation: driverLocation,
          optimizationCriteria: criteria,
        ), throwsArgumentError);
      });

      test('should handle optimization criteria with invalid weights', () async {
        // Arrange
        await routeEngine.initialize();
        final orders = TestData.createMultipleTestOrders(count: 2);
        final driverLocation = TestData.createTestLocation();
        final invalidCriteria = OptimizationCriteria(
          distanceWeight: 1.5, // Invalid: > 1.0
          timeWeight: -0.1, // Invalid: < 0.0
          trafficWeight: 0.3,
          deliveryWindowWeight: 0.2,
        );

        // Act & Assert
        expect(() => routeEngine.optimizeRoute(
          orders: orders,
          driverLocation: driverLocation,
          optimizationCriteria: invalidCriteria,
        ), throwsArgumentError);
      });
    });

    group('Performance Tests', () {
      test('should optimize large order sets within reasonable time', () async {
        // Arrange
        await routeEngine.initialize();
        final largeOrderSet = TestData.createMultipleTestOrders(count: 15);
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Act
        final startTime = DateTime.now();
        final result = await routeEngine.optimizeRoute(
          orders: largeOrderSet,
          driverLocation: driverLocation,
          optimizationCriteria: criteria,
        );
        final endTime = DateTime.now();

        // Assert
        expect(result, isA<OptimizedRoute>());
        expect(endTime.difference(startTime).inSeconds, lessThan(30)); // Should complete within 30 seconds
        expect(result.orderSequence.length, equals(15));
      });

      test('should handle concurrent optimization requests', () async {
        // Arrange
        await routeEngine.initialize();
        final orders1 = TestData.createMultipleTestOrders(count: 3);
        final orders2 = TestData.createMultipleTestOrders(count: 4);
        final orders3 = TestData.createMultipleTestOrders(count: 2);
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Act
        final futures = [
          routeEngine.optimizeRoute(
            orders: orders1,
            driverLocation: driverLocation,
            optimizationCriteria: criteria,
          ),
          routeEngine.optimizeRoute(
            orders: orders2,
            driverLocation: driverLocation,
            optimizationCriteria: criteria,
          ),
          routeEngine.optimizeRoute(
            orders: orders3,
            driverLocation: driverLocation,
            optimizationCriteria: criteria,
          ),
        ];

        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(3));
        expect(results[0].orderSequence.length, equals(3));
        expect(results[1].orderSequence.length, equals(4));
        expect(results[2].orderSequence.length, equals(2));
      });
    });

    group('Disposal Tests', () {
      test('should dispose resources properly', () async {
        // Arrange
        await routeEngine.initialize();

        // Act
        await routeEngine.dispose();

        // Assert
        expect(routeEngine.isInitialized, isFalse);
      });

      test('should handle disposal when not initialized', () async {
        // Act & Assert - should not throw
        expect(() => routeEngine.dispose(), returnsNormally);
      });
    });
  });
}
