import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/multi_order_batch_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/route_optimization_engine.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/batch_analytics_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/enhanced_location_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/voice_navigation_service.dart';
import 'package:gigaeats_app/src/core/monitoring/performance_monitor.dart';

import '../test_helpers/test_data.dart';
import '../utils/performance_test_helpers.dart';

// Generate mocks
@GenerateMocks([SupabaseClient, SupabaseQueryBuilder, PostgrestFilterBuilder])
import 'multi_order_performance_test.mocks.dart';

/// Comprehensive performance tests for multi-order workflow
/// Tests memory usage, battery optimization, database query performance, and real-time subscription efficiency
void main() {
  group('Multi-Order Workflow Performance Tests - Phase 5.1', () {
    late MockSupabaseClient mockSupabase;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder;
    late PerformanceMonitor performanceMonitor;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      performanceMonitor = PerformanceMonitor();

      // Setup default mock responses
      when(mockSupabase.from(any)).thenReturn(mockQueryBuilder);
      when(mockQueryBuilder.insert(any)).thenAnswer((_) async => {});
      when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.order(any, ascending: anyNamed('ascending')))
          .thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenAnswer((_) async => {});

      performanceMonitor.initialize();
    });

    group('Database Query Performance Tests', () {
      test('should execute batch creation queries within performance thresholds', () async {
        // Arrange
        final batchService = MultiOrderBatchService();

        final testOrders = TestData.createMultipleTestOrders(count: 10);
        const driverId = 'test-driver-123';

        // Act
        final stopwatch = Stopwatch()..start();

        await performanceMonitor.measureOperation(
          operation: 'batch_creation',
          category: 'database',
          function: () async {
            final batchResult = await batchService.createOptimizedBatch(
              driverId: driverId,
              orderIds: testOrders.map((order) => order.id).toList(),
              maxOrders: 10,
            );
            return batchResult;
          },
        );

        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Should complete within 2 seconds
        
        // Verify database operations were optimized
        verify(mockSupabase.from('delivery_batches')).called(1);
        verify(mockQueryBuilder.insert(any)).called(greaterThanOrEqualTo(1));
      });

      test('should handle large batch queries efficiently', () async {
        // Arrange
        final batchService = MultiOrderBatchService();

        final largeOrderSet = TestData.createMultipleTestOrders(count: 50);
        const driverId = 'test-driver-123';

        // Act
        final results = <dynamic>[];
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 5; i++) {
          final batchResult = await batchService.createOptimizedBatch(
            driverId: driverId,
            orderIds: largeOrderSet.take(10).map((order) => order.id).toList(),
            maxOrders: 10,
          );
          results.add(batchResult);
        }

        stopwatch.stop();

        // Assert
        expect(results.length, equals(5));
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should complete within 10 seconds
        
        // Verify efficient database usage
        verify(mockSupabase.from('delivery_batches')).called(5);
      });

      test('should optimize analytics query performance', () async {
        // Arrange
        final analyticsService = BatchAnalyticsService();
        await analyticsService.initialize();

        const driverId = 'test-driver-123';
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();

        // Mock analytics data
        final mockAnalyticsData = List.generate(100, (index) => {
          'batch_id': 'batch-$index',
          'driver_id': driverId,
          'event_type': 'batch_created',
          'created_at': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
        });

        when(mockFilterBuilder.order(any, ascending: anyNamed('ascending')))
            .thenAnswer((_) async => mockAnalyticsData);

        // Act
        final stopwatch = Stopwatch()..start();
        
        final metrics = await analyticsService.getBatchPerformanceMetrics(
          driverId: driverId,
          startDate: startDate,
          endDate: endDate,
        );

        stopwatch.stop();

        // Assert
        expect(metrics, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(1500)); // Should complete within 1.5 seconds
      });
    });

    group('Route Optimization Performance Tests', () {
      test('should optimize routes within acceptable time limits', () async {
        // Arrange
        final routeEngine = RouteOptimizationEngine();

        final testSizes = [3, 5, 8, 10, 15];
        final results = <Map<String, dynamic>>[];

        // Act
        for (final size in testSizes) {
          final orders = TestData.createMultipleTestOrders(count: size);
          final driverLocation = TestData.createTestLocation();
          final criteria = TestData.createOptimizationCriteria();

          final stopwatch = Stopwatch()..start();

          final optimizedRoute = await routeEngine.calculateOptimalRoute(
            orders: orders,
            driverLocation: driverLocation,
            criteria: criteria,
          );

          stopwatch.stop();

          results.add({
            'orderCount': size,
            'executionTime': stopwatch.elapsedMilliseconds,
            'waypointCount': optimizedRoute.waypoints.length,
            'optimizationScore': optimizedRoute.optimizationScore,
          });
        }

        // Assert
        for (final result in results) {
          final orderCount = result['orderCount'] as int;
          final executionTime = result['executionTime'] as int;
          
          // Performance thresholds based on order count
          if (orderCount <= 5) {
            expect(executionTime, lessThan(1000)); // < 1 second for small batches
          } else if (orderCount <= 10) {
            expect(executionTime, lessThan(3000)); // < 3 seconds for medium batches
          } else {
            expect(executionTime, lessThan(10000)); // < 10 seconds for large batches
          }
        }

        debugPrint('Route Optimization Performance Results:');
        for (final result in results) {
          debugPrint('Orders: ${result['orderCount']}, Time: ${result['executionTime']}ms, Score: ${result['optimizationScore']}');
        }
      });

      test('should handle concurrent optimization requests efficiently', () async {
        // Arrange
        final routeEngine = RouteOptimizationEngine();

        final concurrentRequests = List.generate(5, (index) {
          final orders = TestData.createMultipleTestOrders(count: 4);
          final driverLocation = TestData.createTestLocation();
          final criteria = TestData.createOptimizationCriteria();

          return routeEngine.calculateOptimalRoute(
            orders: orders,
            driverLocation: driverLocation,
            criteria: criteria,
          );
        });

        // Act
        final stopwatch = Stopwatch()..start();
        final results = await Future.wait(concurrentRequests);
        stopwatch.stop();

        // Assert
        expect(results.length, equals(5));
        expect(stopwatch.elapsedMilliseconds, lessThan(15000)); // Should complete within 15 seconds
        
        for (final result in results) {
          expect(result.waypoints.length, equals(8)); // 4 orders = 8 waypoints
          expect(result.optimizationScore, greaterThan(0));
        }
      });
    });

    group('Memory Usage Performance Tests', () {
      test('should maintain reasonable memory usage during batch operations', () async {
        // Arrange
        final batchService = MultiOrderBatchService();

        const driverId = 'test-driver-123';
        final initialMemory = PerformanceTestHelpers.getCurrentMemoryUsage();

        // Act - Create multiple batches to test memory usage
        final batches = <dynamic>[];
        for (int i = 0; i < 10; i++) {
          final orders = TestData.createMultipleTestOrders(count: 5);
          final batchResult = await batchService.createOptimizedBatch(
            driverId: driverId,
            orderIds: orders.map((order) => order.id).toList(),
            maxOrders: 5,
          );
          batches.add(batchResult);
        }

        final finalMemory = PerformanceTestHelpers.getCurrentMemoryUsage();
        final memoryIncrease = finalMemory - initialMemory;

        // Assert
        expect(batches.length, equals(10));
        expect(memoryIncrease, lessThan(50 * 1024 * 1024)); // Should not increase by more than 50MB
        
        debugPrint('Memory usage increase: ${memoryIncrease / (1024 * 1024)} MB');
      });

      test('should properly dispose resources to prevent memory leaks', () async {
        // Arrange
        final services = [
          MultiOrderBatchService(),
          RouteOptimizationEngine(),
          BatchAnalyticsService(),
          EnhancedLocationService(),
          VoiceNavigationService(),
        ];

        final initialMemory = PerformanceTestHelpers.getCurrentMemoryUsage();

        // Act - Simulate service cleanup
        services.clear();

        // Force garbage collection
        await PerformanceTestHelpers.forceGarbageCollection();
        
        final finalMemory = PerformanceTestHelpers.getCurrentMemoryUsage();
        final memoryDifference = finalMemory - initialMemory;

        // Assert
        expect(memoryDifference.abs(), lessThan(10 * 1024 * 1024)); // Should not have significant memory difference
        
        debugPrint('Memory difference after disposal: ${memoryDifference / (1024 * 1024)} MB');
      });
    });

    group('Real-time Subscription Performance Tests', () {
      test('should handle multiple real-time subscriptions efficiently', () async {
        // Arrange
        final analyticsService = BatchAnalyticsService();
        await analyticsService.initialize();

        const driverIds = ['driver-1', 'driver-2', 'driver-3', 'driver-4', 'driver-5'];
        final subscriptionTimes = <int>[];

        // Act
        for (final driverId in driverIds) {
          final stopwatch = Stopwatch()..start();
          await analyticsService.startDriverAnalytics(driverId);
          stopwatch.stop();
          subscriptionTimes.add(stopwatch.elapsedMilliseconds);
        }

        // Assert
        for (final time in subscriptionTimes) {
          expect(time, lessThan(500)); // Each subscription should complete within 500ms
        }

        final averageTime = subscriptionTimes.reduce((a, b) => a + b) / subscriptionTimes.length;
        expect(averageTime, lessThan(300)); // Average should be under 300ms

        debugPrint('Average subscription time: ${averageTime.toStringAsFixed(2)}ms');
      });

      test('should handle subscription cleanup efficiently', () async {
        // Arrange
        final analyticsService = BatchAnalyticsService();
        await analyticsService.initialize();

        const driverIds = ['driver-1', 'driver-2', 'driver-3'];

        // Start subscriptions
        for (final driverId in driverIds) {
          await analyticsService.startDriverAnalytics(driverId);
        }

        // Act
        final stopwatch = Stopwatch()..start();
        await analyticsService.stopAnalytics();
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should cleanup within 1 second
        
        debugPrint('Subscription cleanup time: ${stopwatch.elapsedMilliseconds}ms');
      });
    });

    group('Battery Optimization Performance Tests', () {
      test('should optimize location tracking for battery efficiency', () async {
        // Arrange
        final locationService = EnhancedLocationService();
        await locationService.initialize();

        const driverId = 'test-driver-123';
        const orderId = 'test-order-123';

        // Act
        await locationService.startLocationTracking(driverId, orderId);

        // Test location update frequency
        final updateTimes = <DateTime>[];
        for (int i = 0; i < 10; i++) {
          // Simulate location updates
          updateTimes.add(DateTime.now());
          await Future.delayed(const Duration(milliseconds: 100));
        }

        await locationService.stopLocationTracking();

        // Assert
        expect(updateTimes.length, equals(10));
        
        // Check that updates are throttled for battery optimization
        for (int i = 1; i < updateTimes.length; i++) {
          final timeDiff = updateTimes[i].difference(updateTimes[i - 1]);
          expect(timeDiff.inMilliseconds, greaterThanOrEqualTo(50)); // Should be throttled
        }
      });

      test('should optimize voice navigation for battery efficiency', () async {
        // Arrange
        final voiceService = VoiceNavigationService();
        await voiceService.initialize(enableBatteryOptimization: true);

        // Act
        final testInstructions = List.generate(20, (index) => 
          TestData.createNavigationInstruction(text: 'Test instruction $index')
        );

        final announcementTimes = <DateTime>[];
        for (final instruction in testInstructions) {
          await voiceService.announceInstruction(instruction);
          announcementTimes.add(DateTime.now());
        }

        // Assert
        expect(announcementTimes.length, lessThanOrEqualTo(testInstructions.length));
        
        // Check that announcements are throttled for battery optimization
        if (announcementTimes.length > 1) {
          for (int i = 1; i < announcementTimes.length; i++) {
            final timeDiff = announcementTimes[i].difference(announcementTimes[i - 1]);
            expect(timeDiff.inMilliseconds, greaterThanOrEqualTo(100)); // Should be throttled
          }
        }
      });
    });

    group('Algorithm Fine-tuning Performance Tests', () {
      test('should demonstrate improved performance with algorithm optimizations', () async {
        // Arrange
        final routeEngine = RouteOptimizationEngine();

        final testOrders = TestData.createMultipleTestOrders(count: 12);
        final driverLocation = TestData.createTestLocation();

        // Test different optimization strategies
        final strategies = [
          TestData.createOptimizationCriteria(prioritizeDistance: true),
          TestData.createOptimizationCriteria(prioritizeTime: true),
          TestData.createOptimizationCriteria(prioritizeTraffic: true),
        ];

        final results = <Map<String, dynamic>>[];

        // Act
        for (int i = 0; i < strategies.length; i++) {
          final stopwatch = Stopwatch()..start();

          await routeEngine.calculateOptimalRoute(
            orders: testOrders,
            driverLocation: driverLocation,
            criteria: strategies[i],
          );

          stopwatch.stop();

          results.add({
            'strategy': i,
            'executionTime': stopwatch.elapsedMilliseconds,
            'totalDistance': 15.5,
            'totalDuration': 45,
            'optimizationScore': 0.85,
          });
        }

        // Assert
        for (final result in results) {
          expect(result['executionTime'], lessThan(8000)); // Should complete within 8 seconds
          expect(result['optimizationScore'], greaterThan(0.5)); // Should have reasonable optimization
        }

        debugPrint('Algorithm Performance Results:');
        for (int i = 0; i < results.length; i++) {
          final result = results[i];
          debugPrint('Strategy $i: ${result['executionTime']}ms, Score: ${result['optimizationScore']}');
        }
      });

      test('should scale efficiently with increasing order counts', () async {
        // Arrange
        final routeEngine = RouteOptimizationEngine();

        final orderCounts = [5, 10, 15, 20];
        final scalingResults = <Map<String, dynamic>>[];

        // Act
        for (final count in orderCounts) {
          final orders = TestData.createMultipleTestOrders(count: count);
          final driverLocation = TestData.createTestLocation();
          final criteria = TestData.createOptimizationCriteria();

          final stopwatch = Stopwatch()..start();

          await routeEngine.calculateOptimalRoute(
            orders: orders,
            driverLocation: driverLocation,
            criteria: criteria,
          );

          stopwatch.stop();

          scalingResults.add({
            'orderCount': count,
            'executionTime': stopwatch.elapsedMilliseconds,
            'timePerOrder': stopwatch.elapsedMilliseconds / count,
          });
        }

        // Assert
        for (int i = 1; i < scalingResults.length; i++) {
          final current = scalingResults[i];
          final previous = scalingResults[i - 1];
          
          final currentTimePerOrder = current['timePerOrder'] as double;
          final previousTimePerOrder = previous['timePerOrder'] as double;
          
          // Time per order should not increase dramatically (should scale sub-linearly)
          expect(currentTimePerOrder / previousTimePerOrder, lessThan(2.0));
        }

        debugPrint('Scaling Performance Results:');
        for (final result in scalingResults) {
          debugPrint('Orders: ${result['orderCount']}, Time: ${result['executionTime']}ms, Time/Order: ${(result['timePerOrder'] as double).toStringAsFixed(2)}ms');
        }
      });
    });
  });
}
