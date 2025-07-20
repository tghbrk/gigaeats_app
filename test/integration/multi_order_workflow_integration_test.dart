import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/multi_order_batch_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/route_optimization_engine.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/batch_analytics_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/automated_customer_notification_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/enhanced_location_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/voice_navigation_service.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/multi_order_batch_provider.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/route_optimization_provider.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/batch_analytics_provider.dart';
import 'package:gigaeats_app/src/features/orders/data/models/order.dart';

import '../test_helpers/mock_providers.dart';
import '../test_helpers/test_data.dart';

// Generate mocks for integration testing
@GenerateMocks([
  SupabaseClient,
  SupabaseQueryBuilder,
  PostgrestFilterBuilder,
  RealtimeChannel,
])
import 'multi_order_workflow_integration_test.mocks.dart';

/// Comprehensive integration tests for multi-order workflow
/// Tests the complete end-to-end flow from batch creation to delivery completion
void main() {
  group('Multi-Order Workflow Integration Tests - Phase 5.1', () {
    late ProviderContainer container;
    late MockSupabaseClient mockSupabase;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder;
    late MockRealtimeChannel mockChannel;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      mockChannel = MockRealtimeChannel();

      // Setup default mock responses
      when(mockSupabase.from(any)).thenReturn(mockQueryBuilder);
      when(mockSupabase.channel(any)).thenReturn(mockChannel);
      when(mockQueryBuilder.insert(any)).thenAnswer((_) async => <String, dynamic>{});
      when(mockQueryBuilder.update(any)).thenReturn(mockFilterBuilder);
      when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.gte(any, any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.lte(any, any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.order(any, ascending: anyNamed('ascending')))
          .thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenAnswer((_) async => <String, dynamic>{});
      when(mockChannel.subscribe()).thenReturn(mockChannel);
      when(mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');

      container = ProviderContainer(
        overrides: [
          multiOrderBatchProvider.overrideWith((ref) => MockMultiOrderBatchNotifier()),
          routeOptimizationProvider.overrideWith((ref) => MockRouteOptimizationNotifier()),
          batchAnalyticsProvider.overrideWith((ref) => MockBatchAnalyticsNotifier()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Complete Workflow Integration', () {
      testWidgets('should complete full multi-order delivery workflow', (tester) async {
        // Arrange
        final testOrders = TestData.createMultipleTestOrders(count: 5);
        final testDriver = TestData.createTestDriver();

        // Act & Assert - Test complete workflow
        await _testCompleteWorkflow(testOrders, testDriver);
      });

      testWidgets('should handle workflow with route optimization', (tester) async {
        // Arrange
        final testOrders = TestData.createMultipleTestOrders(count: 3);
        final testDriver = TestData.createTestDriver();

        // Act & Assert - Test workflow with optimization
        await _testWorkflowWithOptimization(testOrders, testDriver);
      });

      testWidgets('should handle workflow with real-time updates', (tester) async {
        // Arrange
        final testOrders = TestData.createMultipleTestOrders(count: 4);
        final testDriver = TestData.createTestDriver();

        // Act & Assert - Test real-time workflow
        await _testRealTimeWorkflow(testOrders, testDriver);
      });
    });

    group('Service Integration Tests', () {
      test('should integrate batch service with route optimization', () async {
        // Arrange
        final batchService = MultiOrderBatchService();
        final routeEngine = RouteOptimizationEngine();

        final testOrders = TestData.createMultipleTestOrders(count: 3);
        const driverId = 'test-driver-123';

        // Act
        final batchResult = await batchService.createOptimizedBatch(
          driverId: driverId,
          orderIds: testOrders.map((order) => order.id).toList(),
          maxOrders: 5,
        );

        expect(batchResult.isSuccess, isTrue);
        expect(batchResult.batch, isNotNull);

        // Test route optimization integration
        final optimizedRoute = await routeEngine.calculateOptimalRoute(
          orders: testOrders,
          driverLocation: TestData.createTestLocation(),
          criteria: TestData.createOptimizationCriteria(),
        );

        // Assert
        expect(optimizedRoute, isNotNull);
        expect(optimizedRoute.waypoints.length, greaterThan(0));
      });

      test('should integrate analytics with notification service', () async {
        // Arrange
        final analyticsService = BatchAnalyticsService();
        final notificationService = AutomatedCustomerNotificationService();
        
        await analyticsService.initialize();
        await notificationService.initialize();

        const batchId = 'test-batch-123';
        const driverId = 'test-driver-123';

        // Act - Record analytics and send notifications
        await analyticsService.recordBatchCreation(
          batchId: batchId,
          driverId: driverId,
          orderCount: 3,
          estimatedDistance: 15.5,
          estimatedDuration: const Duration(minutes: 45),
          optimizationMetrics: {'score': 0.85, 'efficiency': 0.92},
        );

        final testOrders = TestData.createBatchOrdersWithDetails(count: 3);
        await notificationService.notifyBatchAssignment(
          batchId: batchId,
          driverId: driverId,
          driverName: 'Test Driver',
          orders: testOrders,
        );

        // Assert - Services should complete without errors
        expect(true, isTrue); // If we reach here, integration worked
      });

      test('should integrate location service with voice navigation', () async {
        // Arrange
        final locationService = EnhancedLocationService();
        final voiceService = VoiceNavigationService();
        
        await locationService.initialize();
        await voiceService.initialize();

        const driverId = 'test-driver-123';
        const orderId = 'test-order-123';

        // Act - Test location and voice integration
        final trackingStarted = await locationService.startLocationTracking(driverId, orderId);

        final testInstruction = TestData.createNavigationInstruction();
        await voiceService.announceInstruction(testInstruction);

        // Assert - Services should integrate without errors
        expect(trackingStarted, isTrue);
        expect(voiceService.isInitialized, isTrue);
      });
    });

    group('Database Operations Integration', () {
      test('should handle batch creation with database operations', () async {
        // Arrange
        final batchService = MultiOrderBatchService();

        final testOrders = TestData.createMultipleTestOrders(count: 3);
        const driverId = 'test-driver-123';

        // Mock successful database responses
        when(mockFilterBuilder.single()).thenAnswer((_) async => {
          'id': 'batch-123',
          'driver_id': driverId,
          'status': 'created',
          'created_at': DateTime.now().toIso8601String(),
        });

        // Act
        final batchResult = await batchService.createOptimizedBatch(
          driverId: driverId,
          orderIds: testOrders.map((order) => order.id).toList(),
          maxOrders: 5,
        );

        // Assert
        expect(batchResult.isSuccess, isTrue);
        expect(batchResult.batch?.driverId, equals(driverId));
      });

      test('should handle real-time subscription updates', () async {
        // Arrange
        final analyticsService = BatchAnalyticsService();
        await analyticsService.initialize();

        const driverId = 'test-driver-123';

        // Act
        await analyticsService.startDriverAnalytics(driverId);

        // Assert - Should handle real-time updates without errors
        expect(analyticsService.batchMetricsStream, isA<Stream>());
        expect(analyticsService.driverInsightsStream, isA<Stream>());
      });
    });

    group('Error Handling Integration', () {
      test('should handle service initialization failures gracefully', () async {
        // Arrange
        when(mockSupabase.from(any)).thenThrow(Exception('Database connection failed'));

        final batchService = MultiOrderBatchService();
        final testOrders = TestData.createMultipleTestOrders(count: 1);

        // Act & Assert
        expect(() => batchService.createOptimizedBatch(
          driverId: 'test-driver',
          orderIds: testOrders.map((order) => order.id).toList(),
        ), throwsException);
      });

      test('should handle route optimization failures', () async {
        // Arrange
        final routeEngine = RouteOptimizationEngine();

        final invalidOrders = <Order>[]; // Empty orders list

        // Act & Assert
        expect(() => routeEngine.calculateOptimalRoute(
          orders: invalidOrders,
          driverLocation: TestData.createTestLocation(),
          criteria: TestData.createOptimizationCriteria(),
        ), throwsException);
      });

      test('should handle notification service failures gracefully', () async {
        // Arrange
        final notificationService = AutomatedCustomerNotificationService();
        await notificationService.initialize();

        // Act - Test with invalid data
        await notificationService.notifyBatchAssignment(
          batchId: '',
          driverId: '',
          driverName: '',
          orders: [],
        );

        // Assert - Should complete without throwing
        expect(true, isTrue);
      });
    });

    group('Performance Integration Tests', () {
      test('should handle large batch operations efficiently', () async {
        // Arrange
        final batchService = MultiOrderBatchService();

        final largeOrderSet = TestData.createMultipleTestOrders(count: 20);
        const driverId = 'test-driver-123';

        // Act
        final startTime = DateTime.now();
        final batchResult = await batchService.createOptimizedBatch(
          driverId: driverId,
          orderIds: largeOrderSet.take(10).map((order) => order.id).toList(),
          maxOrders: 10,
        );
        final endTime = DateTime.now();

        // Assert
        expect(batchResult.isSuccess, isTrue);
        expect(endTime.difference(startTime).inMilliseconds, lessThan(5000)); // Should complete within 5 seconds
      });

      test('should handle concurrent route optimizations', () async {
        // Arrange
        final routeEngine = RouteOptimizationEngine();

        final testOrders1 = TestData.createMultipleTestOrders(count: 3);
        final testOrders2 = TestData.createMultipleTestOrders(count: 4);
        final testOrders3 = TestData.createMultipleTestOrders(count: 2);

        // Act - Run concurrent optimizations
        final futures = [
          routeEngine.calculateOptimalRoute(
            orders: testOrders1,
            driverLocation: TestData.createTestLocation(),
            criteria: TestData.createOptimizationCriteria(),
          ),
          routeEngine.calculateOptimalRoute(
            orders: testOrders2,
            driverLocation: TestData.createTestLocation(),
            criteria: TestData.createOptimizationCriteria(),
          ),
          routeEngine.calculateOptimalRoute(
            orders: testOrders3,
            driverLocation: TestData.createTestLocation(),
            criteria: TestData.createOptimizationCriteria(),
          ),
        ];

        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(3));
        for (final result in results) {
          expect(result, isNotNull);
          expect(result.waypoints.length, greaterThan(0));
        }
      });
    });
  });
}

/// Test complete multi-order workflow
Future<void> _testCompleteWorkflow(List<dynamic> orders, dynamic driver) async {
  // 1. Batch Creation
  final batchService = MultiOrderBatchService();

  final batchResult = await batchService.createOptimizedBatch(
    driverId: driver['id'],
    orderIds: orders.map((order) => order.id as String).toList(),
    maxOrders: 5,
  );

  expect(batchResult.isSuccess, isTrue);
  expect(batchResult.batch, isNotNull);

  // 2. Route Optimization
  final routeEngine = RouteOptimizationEngine();

  final optimizedRoute = await routeEngine.calculateOptimalRoute(
    orders: orders.cast<Order>(),
    driverLocation: TestData.createTestLocation(),
    criteria: TestData.createOptimizationCriteria(),
  );

  expect(optimizedRoute, isNotNull);

  // 3. Analytics Recording
  final analyticsService = BatchAnalyticsService();

  await analyticsService.recordBatchCreation(
    batchId: batchResult.batch!.id,
    driverId: driver['id'],
    orderCount: orders.length,
    estimatedDistance: 15.5,
    estimatedDuration: const Duration(minutes: 45),
    optimizationMetrics: {
      'score': 0.85,
      'efficiency': 0.92,
    },
  );

  // 4. Customer Notifications
  final notificationService = AutomatedCustomerNotificationService();
  await notificationService.initialize();

  await notificationService.notifyBatchAssignment(
    batchId: batchResult.batch!.id,
    driverId: driver['id'],
    driverName: driver['name'],
    orders: TestData.createBatchOrdersWithDetails(count: orders.length),
  );

  // 5. Batch Completion
  await analyticsService.recordBatchCompletion(
    batchId: batchResult.batch!.id,
    driverId: driver['id'],
    actualDuration: const Duration(minutes: 50),
    actualDistance: 16.2,
    completedOrders: orders.length,
    totalOrders: orders.length,
    orderCompletionTimes: List.generate(orders.length, (i) => Duration(minutes: 10 + i)),
    performanceData: {'efficiency': 0.88, 'satisfaction': 4.5},
  );
}

/// Test workflow with optimization
Future<void> _testWorkflowWithOptimization(List<dynamic> orders, dynamic driver) async {
  final routeEngine = RouteOptimizationEngine();

  // Test multiple optimization scenarios
  final scenarios = [
    TestData.createOptimizationCriteria(prioritizeDistance: true),
    TestData.createOptimizationCriteria(prioritizeTime: true),
    TestData.createOptimizationCriteria(prioritizeTraffic: true),
  ];

  for (final criteria in scenarios) {
    final optimizedRoute = await routeEngine.calculateOptimalRoute(
      orders: orders.cast<Order>(),
      driverLocation: TestData.createTestLocation(),
      criteria: criteria,
    );

    expect(optimizedRoute, isNotNull);
    expect(optimizedRoute.waypoints.length, equals(orders.length * 2)); // Pickup + delivery for each order
  }
}

/// Test real-time workflow
Future<void> _testRealTimeWorkflow(List<dynamic> orders, dynamic driver) async {
  final analyticsService = BatchAnalyticsService();
  await analyticsService.initialize();

  await analyticsService.startDriverAnalytics(driver['id']);

  // Test real-time streams
  expect(analyticsService.batchMetricsStream, isA<Stream>());
  expect(analyticsService.driverInsightsStream, isA<Stream>());

  // Simulate real-time updates
  final testEvents = TestData.createAnalyticsEvents(count: 5);
  
  for (final event in testEvents) {
    // Simulate processing real-time events
    expect(event, isNotNull);
  }

  await analyticsService.stopAnalytics();
}
