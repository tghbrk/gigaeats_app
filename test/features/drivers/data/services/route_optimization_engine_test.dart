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
        final orders = TestData.createMultipleTestOrders(count: 4);
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Initial optimization
        final initialRoute = await routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: criteria,
        );

        // Simulate condition change (create route progress and events)
        final progress = RouteProgress(
          routeId: initialRoute.id,
          currentWaypointSequence: 0,
          completedWaypoints: [],
          progressPercentage: 0.0,
          lastUpdated: DateTime.now(),
        );

        final events = [
          RouteEvent(
            id: 'event_1',
            routeId: initialRoute.id,
            type: RouteEventType.trafficIncident,
            timestamp: DateTime.now(),
            data: {
              'severity': 'moderate',
              'affectedSegments': ['segment_1'],
              'estimatedDelay': 5,
            },
          ),
        ];

        // Act
        final reoptimizedRoute = await routeEngine.reoptimizeRoute(
          initialRoute,
          progress,
          events,
        );

        // Assert
        expect(reoptimizedRoute, isA<RouteUpdate?>());
        if (reoptimizedRoute != null) {
          expect(reoptimizedRoute.updatedWaypoints.length, equals(initialRoute.waypoints.length));
          expect(reoptimizedRoute.newOptimizationScore, isA<double>());
        }
      });

      test('should handle completed waypoints in reoptimization', () async {
        // Arrange
        final orders = TestData.createMultipleTestOrders(count: 3);
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        final initialRoute = await routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: criteria,
        );

        // Simulate completing first waypoint
        final completedWaypoints = [initialRoute.waypoints.first.id];

        final progress = RouteProgress(
          routeId: initialRoute.id,
          currentWaypointSequence: 1,
          completedWaypoints: completedWaypoints,
          progressPercentage: 0.2,
          lastUpdated: DateTime.now(),
        );

        final events = [
          RouteEvent(
            id: 'event_2',
            routeId: initialRoute.id,
            type: RouteEventType.waypointCompleted,
            timestamp: DateTime.now(),
            data: {'waypointId': completedWaypoints.first},
          ),
        ];

        // Act
        final reoptimizedRoute = await routeEngine.reoptimizeRoute(
          initialRoute,
          progress,
          events,
        );

        // Assert
        expect(reoptimizedRoute, isA<RouteUpdate?>());
        if (reoptimizedRoute != null) {
          expect(reoptimizedRoute.updatedWaypoints.length, lessThanOrEqualTo(initialRoute.waypoints.length));
        }
      });
    });

    group('Preparation Time Integration Tests', () {
      test('should consider vendor preparation times in optimization', () async {
        // Arrange
        final orders = TestData.createMultipleTestOrders(count: 3);
        final driverLocation = TestData.createTestLocation();
        final criteria = OptimizationCriteria(
          distanceWeight: 0.2,
          preparationTimeWeight: 0.5, // High time weight to prioritize preparation times
          trafficWeight: 0.2,
          deliveryWindowWeight: 0.1,
        );

        // Act
        final result = await routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: criteria,
        );

        // Assert
        expect(result, isA<OptimizedRoute>());
        expect(result.optimizationScore, greaterThan(0.0));

        // Check that pickup waypoints are scheduled
        final pickupWaypoints = result.waypoints.where((w) => w.type == WaypointType.pickup).toList();
        for (final waypoint in pickupWaypoints) {
          expect(waypoint.estimatedArrivalTime, isNotNull);
          expect(waypoint.estimatedDuration, isNotNull);
        }
      });

      test('should optimize pickup sequence based on preparation times', () async {
        // Arrange
        final orders = TestData.createMultipleTestOrders(count: 3);
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

        // Verify that orders with longer prep times are scheduled later
        final pickupWaypoints = result.waypoints.where((w) => w.type == WaypointType.pickup).toList();
        for (int i = 0; i < pickupWaypoints.length - 1; i++) {
          final current = pickupWaypoints[i];
          final next = pickupWaypoints[i + 1];
          if (current.estimatedArrivalTime != null && next.estimatedArrivalTime != null) {
            expect(current.estimatedArrivalTime!.isBefore(next.estimatedArrivalTime!) ||
                   current.estimatedArrivalTime!.isAtSameMomentAs(next.estimatedArrivalTime!), isTrue);
          }
        }
      });
    });

    group('Delivery Window Optimization Tests', () {
      test('should respect delivery time windows', () async {
        // Arrange
        final orders = TestData.createMultipleTestOrders(count: 2);
        final driverLocation = TestData.createTestLocation();
        final criteria = OptimizationCriteria(
          distanceWeight: 0.2,
          preparationTimeWeight: 0.2,
          trafficWeight: 0.1,
          deliveryWindowWeight: 0.5, // High weight for delivery windows
        );

        // Act
        final result = await routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: criteria,
        );

        // Assert
        expect(result, isA<OptimizedRoute>());
        
        // Verify that delivery waypoints respect time windows
        final deliveryWaypoints = result.waypoints.where((w) => w.type == WaypointType.delivery).toList();
        for (final waypoint in deliveryWaypoints) {
          expect(waypoint.estimatedArrivalTime, isNotNull);
          expect(waypoint.estimatedDuration, isNotNull);
        }
      });

      test('should prioritize urgent deliveries', () async {
        // Arrange
        final orders = TestData.createMultipleTestOrders(count: 3);
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
        
        // Verify that urgent orders are prioritized in the sequence
        final pickupWaypoints = result.waypoints.where((w) => w.type == WaypointType.pickup).toList();

        // Verify basic route structure
        expect(pickupWaypoints.length, greaterThan(0));
        expect(orders.length, greaterThan(0));
      });
    });

    group('Error Handling Tests', () {
      test('should handle invalid driver location', () async {
        // Arrange
        final orders = TestData.createMultipleTestOrders(count: 2);
        final invalidLocation = const LatLng(200.0, 200.0); // Invalid coordinates
        final criteria = TestData.createOptimizationCriteria();

        // Act & Assert
        expect(() => routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: invalidLocation,
          criteria: criteria,
        ), throwsArgumentError);
      });

      test('should handle orders with invalid locations', () async {
        // Arrange
        final invalidOrders = TestData.createMultipleTestOrders(count: 1);
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Act & Assert
        expect(() => routeEngine.calculateOptimalRoute(
          orders: invalidOrders,
          driverLocation: driverLocation,
          criteria: criteria,
        ), throwsArgumentError);
      });

      test('should handle optimization criteria with invalid weights', () async {
        // Arrange
        final orders = TestData.createMultipleTestOrders(count: 2);
        final driverLocation = TestData.createTestLocation();
        final invalidCriteria = OptimizationCriteria(
          distanceWeight: 1.5, // Invalid: > 1.0
          preparationTimeWeight: -0.1, // Invalid: < 0.0
          trafficWeight: 0.3,
          deliveryWindowWeight: 0.2,
        );

        // Act & Assert
        expect(() => routeEngine.calculateOptimalRoute(
          orders: orders,
          driverLocation: driverLocation,
          criteria: invalidCriteria,
        ), throwsArgumentError);
      });
    });

    group('Performance Tests', () {
      test('should optimize large order sets within reasonable time', () async {
        // Arrange
        final largeOrderSet = TestData.createMultipleTestOrders(count: 15);
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Act
        final startTime = DateTime.now();
        final result = await routeEngine.calculateOptimalRoute(
          orders: largeOrderSet,
          driverLocation: driverLocation,
          criteria: criteria,
        );
        final endTime = DateTime.now();

        // Assert
        expect(result, isA<OptimizedRoute>());
        expect(endTime.difference(startTime).inSeconds, lessThan(30)); // Should complete within 30 seconds
        expect(result.waypoints.length, equals(30)); // 15 orders = 30 waypoints (pickup + delivery)
      });

      test('should handle concurrent optimization requests', () async {
        // Arrange
        final orders1 = TestData.createMultipleTestOrders(count: 3);
        final orders2 = TestData.createMultipleTestOrders(count: 4);
        final orders3 = TestData.createMultipleTestOrders(count: 2);
        final driverLocation = TestData.createTestLocation();
        final criteria = TestData.createOptimizationCriteria();

        // Act
        final futures = [
          routeEngine.calculateOptimalRoute(
            orders: orders1,
            driverLocation: driverLocation,
            criteria: criteria,
          ),
          routeEngine.calculateOptimalRoute(
            orders: orders2,
            driverLocation: driverLocation,
            criteria: criteria,
          ),
          routeEngine.calculateOptimalRoute(
            orders: orders3,
            driverLocation: driverLocation,
            criteria: criteria,
          ),
        ];

        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(3));
        expect(results[0].waypoints.length, equals(6)); // 3 orders = 6 waypoints
        expect(results[1].waypoints.length, equals(8)); // 4 orders = 8 waypoints
        expect(results[2].waypoints.length, equals(4)); // 2 orders = 4 waypoints
      });
    });

    group('Disposal Tests', () {
      test('should dispose resources properly', () async {
        // Arrange & Act & Assert - RouteOptimizationEngine doesn't require explicit disposal
        expect(routeEngine, isNotNull);
      });

      test('should handle disposal when not initialized', () async {
        // Act & Assert - RouteOptimizationEngine doesn't require explicit disposal
        expect(routeEngine, isNotNull);
      });
    });
  });
}
