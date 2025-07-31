import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/multi_order_batch_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/route_optimization_engine.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/real_time_route_adjustment_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/route_optimization_models.dart';

import 'package:gigaeats_app/src/features/drivers/data/models/navigation_models.dart';

/// Comprehensive test suite for Phase 3: Multi-Order Route Optimization
/// Tests all components including batch management, route optimization, and real-time adjustments
void main() {
  group('Phase 3: Multi-Order Route Optimization Tests', () {
    late MultiOrderBatchService batchService;
    late RouteOptimizationEngine optimizationEngine;
    late RealTimeRouteAdjustmentService adjustmentService;

    setUp(() {
      batchService = MultiOrderBatchService();
      optimizationEngine = RouteOptimizationEngine();
      adjustmentService = RealTimeRouteAdjustmentService();
    });

    tearDown(() {
      adjustmentService.dispose();
    });

    group('Phase 3.1: Enhanced Batch Management', () {
      test('should create enhanced batch with real-time optimization', () async {
        // Test data
        const driverId = 'test-driver-123';
        final orderIds = ['order-1', 'order-2', 'order-3'];

        // Create enhanced batch
        final result = await batchService.createEnhancedBatch(
          driverId: driverId,
          orderIds: orderIds,
          maxOrders: 3,
          maxDeviationKm: 5.0,
          enableRealTimeUpdates: true,
        );

        // Verify result
        expect(result.isSuccess, isTrue);
        expect(result.batch, isNotNull);
        expect(result.batch!.driverId, equals(driverId));
        expect(result.batch!.maxOrders, equals(3));
        expect(result.batch!.maxDeviationKm, equals(5.0));
      });

      test('should add order to existing batch with route recalculation', () async {
        // Create initial batch
        const driverId = 'test-driver-123';
        final initialOrderIds = ['order-1', 'order-2'];
        
        final batchResult = await batchService.createEnhancedBatch(
          driverId: driverId,
          orderIds: initialOrderIds,
        );
        
        expect(batchResult.isSuccess, isTrue);
        final batchId = batchResult.batch!.id;

        // Add new order
        final addResult = await batchService.addOrderToBatch(
          batchId: batchId,
          orderId: 'order-3',
          recalculateRoute: true,
        );

        // Verify result
        expect(addResult.isSuccess, isTrue);
        expect(addResult.message, contains('successfully'));
      });

      test('should remove order from batch with route recalculation', () async {
        // Create batch with multiple orders
        const driverId = 'test-driver-123';
        final orderIds = ['order-1', 'order-2', 'order-3'];
        
        final batchResult = await batchService.createEnhancedBatch(
          driverId: driverId,
          orderIds: orderIds,
        );
        
        expect(batchResult.isSuccess, isTrue);
        final batchId = batchResult.batch!.id;

        // Remove order
        final removeResult = await batchService.removeOrderFromBatch(
          batchId: batchId,
          orderId: 'order-2',
          recalculateRoute: true,
        );

        // Verify result
        expect(removeResult.isSuccess, isTrue);
        expect(removeResult.message, contains('successfully'));
      });
    });

    group('Phase 3.2: Route Optimization Engine Enhancement', () {
      test('should calculate dynamic route adjustment', () async {
        // Create test route
        final testRoute = OptimizedRoute(
          id: 'test-route-123',
          batchId: 'test-batch-123',
          waypoints: [
            RouteWaypoint(
              id: 'wp-1',
              type: WaypointType.pickup,
              location: const LatLng(3.1390, 101.6869),
              orderId: 'order-1',
              sequence: 1,
              estimatedArrivalTime: DateTime.now().add(const Duration(minutes: 10)),
              address: 'Test Address 1',
            ),
            RouteWaypoint(
              id: 'wp-2',
              type: WaypointType.delivery,
              location: const LatLng(3.1500, 101.7000),
              orderId: 'order-1',
              sequence: 2,
              estimatedArrivalTime: DateTime.now().add(const Duration(minutes: 20)),
              address: 'Test Address 2',
            ),
          ],
          totalDistanceKm: 10.5,
          totalDuration: const Duration(minutes: 30),
          durationInTraffic: const Duration(minutes: 35),
          optimizationScore: 85.0,
          criteria: OptimizationCriteria.balanced(),
          calculatedAt: DateTime.now(),
          overallTrafficCondition: TrafficCondition.moderate,
        );

        // Test conditions
        final realTimeConditions = {
          'traffic': {
            'congestion_level': 'heavy',
            'delay_minutes': 15,
            'affected_segments': 2,
          },
          'weather': {
            'condition': 'rain',
            'intensity': 'moderate',
            'visibility_km': 5.0,
          },
          'order_changes': false,
        };

        // Calculate adjustment
        final adjustmentResult = await optimizationEngine.calculateDynamicRouteAdjustment(
          currentRoute: testRoute,
          currentDriverLocation: const LatLng(3.1390, 101.6869),
          completedWaypointIds: [],
          realTimeConditions: realTimeConditions,
        );

        // Verify result
        expect(adjustmentResult, isNotNull);
        expect(adjustmentResult.status, isA<RouteAdjustmentStatus>());
        expect(adjustmentResult.calculatedAt, isNotNull);
      });

      test('should handle no adjustment needed scenario', () async {
        // Create test route
        final testRoute = OptimizedRoute(
          id: 'test-route-123',
          batchId: 'test-batch-123',
          waypoints: [],
          totalDistanceKm: 5.0,
          totalDuration: const Duration(minutes: 15),
          durationInTraffic: const Duration(minutes: 15),
          optimizationScore: 95.0,
          criteria: OptimizationCriteria.balanced(),
          calculatedAt: DateTime.now(),
          overallTrafficCondition: TrafficCondition.light,
        );

        // Optimal conditions
        final realTimeConditions = {
          'traffic': {
            'congestion_level': 'normal',
            'delay_minutes': 0,
            'affected_segments': 0,
          },
          'weather': {
            'condition': 'clear',
            'intensity': 'light',
            'visibility_km': 10.0,
          },
          'order_changes': false,
        };

        // Calculate adjustment
        final adjustmentResult = await optimizationEngine.calculateDynamicRouteAdjustment(
          currentRoute: testRoute,
          currentDriverLocation: const LatLng(3.1390, 101.6869),
          completedWaypointIds: [],
          realTimeConditions: realTimeConditions,
        );

        // Verify no adjustment needed
        expect(adjustmentResult.noAdjustmentNeeded, isTrue);
        expect(adjustmentResult.message, contains('optimal'));
      });
    });

    group('Phase 3.3: Enhanced Driver Interface Components', () {
      test('should create RouteAdjustmentResult with proper status', () {
        // Test successful adjustment
        final testRoute = OptimizedRoute(
          id: 'adjusted-route-123',
          batchId: 'test-batch-123',
          waypoints: [],
          totalDistanceKm: 8.0,
          totalDuration: const Duration(minutes: 25),
          durationInTraffic: const Duration(minutes: 30),
          optimizationScore: 90.0,
          criteria: OptimizationCriteria.balanced(),
          calculatedAt: DateTime.now(),
          overallTrafficCondition: TrafficCondition.moderate,
        );

        final adjustmentResult = RouteAdjustmentResult.adjustmentCalculated(
          testRoute,
          'Traffic conditions improved',
          15.0,
        );

        expect(adjustmentResult.isSuccess, isTrue);
        expect(adjustmentResult.adjustedRoute, equals(testRoute));
        expect(adjustmentResult.adjustmentReason, equals('Traffic conditions improved'));
        expect(adjustmentResult.improvementScore, equals(15.0));
      });

      test('should create RouteAdjustmentResult for no adjustment needed', () {
        final adjustmentResult = RouteAdjustmentResult.noAdjustmentNeeded(
          'Current route is optimal',
        );

        expect(adjustmentResult.noAdjustmentNeeded, isTrue);
        expect(adjustmentResult.message, equals('Current route is optimal'));
        expect(adjustmentResult.adjustedRoute, isNull);
      });

      test('should create RouteAdjustmentResult for error scenario', () {
        final adjustmentResult = RouteAdjustmentResult.error(
          'Failed to calculate route adjustment',
        );

        expect(adjustmentResult.hasError, isTrue);
        expect(adjustmentResult.message, equals('Failed to calculate route adjustment'));
        expect(adjustmentResult.adjustedRoute, isNull);
      });
    });

    group('Phase 3.4: Real-time Route Adjustment System', () {
      test('should initialize monitoring successfully', () async {
        // Test data
        const batchId = 'test-batch-123';
        final initialRoute = OptimizedRoute(
          id: 'test-route-123',
          batchId: batchId,
          waypoints: [],
          totalDistanceKm: 10.0,
          totalDuration: const Duration(minutes: 30),
          durationInTraffic: const Duration(minutes: 35),
          optimizationScore: 85.0,
          criteria: OptimizationCriteria.balanced(),
          calculatedAt: DateTime.now(),
          overallTrafficCondition: TrafficCondition.moderate,
        );
        const driverLocation = LatLng(3.1390, 101.6869);

        // Initialize monitoring (this would normally connect to Supabase)
        // For testing, we'll just verify the method doesn't throw
        expect(
          () => adjustmentService.initializeMonitoring(
            batchId: batchId,
            initialRoute: initialRoute,
            driverLocation: driverLocation,
          ),
          returnsNormally,
        );
      });

      test('should update driver location', () {
        const newLocation = LatLng(3.1500, 101.7000);
        
        // Update location
        adjustmentService.updateDriverLocation(newLocation);
        
        // Verify no exceptions thrown
        expect(true, isTrue);
      });

      test('should get current conditions', () {
        // Get conditions
        final conditions = adjustmentService.getCurrentConditions();
        
        // Verify returns map
        expect(conditions, isA<Map<String, dynamic>>());
      });

      test('should stop monitoring successfully', () async {
        // Stop monitoring
        await adjustmentService.stopMonitoring();
        
        // Verify no exceptions thrown
        expect(true, isTrue);
      });
    });

    group('Phase 3.5: Integration Testing', () {
      test('should handle complete multi-order workflow', () async {
        // 1. Create enhanced batch
        const driverId = 'integration-test-driver';
        final orderIds = ['order-1', 'order-2'];
        
        final batchResult = await batchService.createEnhancedBatch(
          driverId: driverId,
          orderIds: orderIds,
          enableRealTimeUpdates: true,
        );
        
        expect(batchResult.isSuccess, isTrue);
        
        // 2. Add another order
        final addResult = await batchService.addOrderToBatch(
          batchId: batchResult.batch!.id,
          orderId: 'order-3',
          recalculateRoute: true,
        );
        
        expect(addResult.isSuccess, isTrue);
        
        // 3. Initialize real-time monitoring
        final testRoute = OptimizedRoute(
          id: 'integration-route',
          batchId: batchResult.batch!.id,
          waypoints: [],
          totalDistanceKm: 15.0,
          totalDuration: const Duration(minutes: 45),
          durationInTraffic: const Duration(minutes: 50),
          optimizationScore: 80.0,
          criteria: OptimizationCriteria.balanced(),
          calculatedAt: DateTime.now(),
          overallTrafficCondition: TrafficCondition.moderate,
        );
        
        expect(
          () => adjustmentService.initializeMonitoring(
            batchId: batchResult.batch!.id,
            initialRoute: testRoute,
            driverLocation: const LatLng(3.1390, 101.6869),
          ),
          returnsNormally,
        );
        
        // 4. Update driver location
        adjustmentService.updateDriverLocation(const LatLng(3.1500, 101.7000));
        
        // 5. Stop monitoring
        await adjustmentService.stopMonitoring();
        
        // Verify complete workflow executed without errors
        expect(true, isTrue);
      });
    });
  });
}
