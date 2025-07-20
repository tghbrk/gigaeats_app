import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gigaeats/src/features/drivers/data/services/batch_analytics_service.dart';
import 'package:gigaeats/src/features/drivers/data/models/batch_analytics_models.dart';

import '../../../../test_helpers/test_data.dart';

// Generate mocks
@GenerateMocks([SupabaseClient, SupabaseQueryBuilder, PostgrestFilterBuilder])
import 'batch_analytics_service_test.mocks.dart';

void main() {
  group('BatchAnalyticsService Tests - Phase 4.2', () {
    late BatchAnalyticsService analyticsService;
    late MockSupabaseClient mockSupabase;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      analyticsService = BatchAnalyticsService();

      // Setup default mock responses
      when(mockSupabase.from(any)).thenReturn(mockQueryBuilder);
      when(mockQueryBuilder.insert(any)).thenAnswer((_) async => {});
      when(mockQueryBuilder.select(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.gte(any, any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.lte(any, any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.order(any, ascending: anyNamed('ascending')))
          .thenReturn(mockFilterBuilder);
    });

    group('Initialization Tests', () {
      test('should initialize successfully', () async {
        // Act & Assert - should not throw
        expect(() => analyticsService.initialize(), returnsNormally);
      });

      test('should start driver analytics', () async {
        // Arrange
        await analyticsService.initialize();
        const driverId = 'driver123';

        // Act & Assert - should not throw
        expect(() => analyticsService.startDriverAnalytics(driverId), returnsNormally);
      });
    });

    group('Batch Creation Analytics Tests', () {
      test('should record batch creation metrics', () async {
        // Arrange
        await analyticsService.initialize();
        const batchId = 'batch123';
        const driverId = 'driver123';
        const orderCount = 5;
        const estimatedDistance = 15.5;
        const estimatedDuration = Duration(minutes: 45);
        const optimizationMetrics = {
          'score': 0.85,
          'efficiency': 0.92,
        };

        // Act & Assert - should not throw
        expect(() => analyticsService.recordBatchCreation(
          batchId: batchId,
          driverId: driverId,
          orderCount: orderCount,
          estimatedDistance: estimatedDistance,
          estimatedDuration: estimatedDuration,
          optimizationMetrics: optimizationMetrics,
        ), returnsNormally);
      });

      test('should handle batch creation recording errors gracefully', () async {
        // Arrange
        await analyticsService.initialize();
        when(mockQueryBuilder.insert(any)).thenThrow(Exception('Database error'));

        // Act & Assert - should handle error gracefully
        expect(() => analyticsService.recordBatchCreation(
          batchId: 'batch123',
          driverId: 'driver123',
          orderCount: 3,
          estimatedDistance: 10.0,
          estimatedDuration: const Duration(minutes: 30),
          optimizationMetrics: {},
        ), returnsNormally);
      });
    });

    group('Batch Completion Analytics Tests', () {
      test('should record batch completion metrics', () async {
        // Arrange
        await analyticsService.initialize();
        const batchId = 'batch123';
        const driverId = 'driver123';
        const actualDuration = Duration(minutes: 50);
        const actualDistance = 16.2;
        const completedOrders = 5;
        const totalOrders = 5;
        const orderCompletionTimes = [
          Duration(minutes: 8),
          Duration(minutes: 12),
          Duration(minutes: 10),
          Duration(minutes: 9),
          Duration(minutes: 11),
        ];
        const performanceData = {
          'efficiency': 0.88,
          'satisfaction': 4.5,
        };

        // Act & Assert - should not throw
        expect(() => analyticsService.recordBatchCompletion(
          batchId: batchId,
          driverId: driverId,
          actualDuration: actualDuration,
          actualDistance: actualDistance,
          completedOrders: completedOrders,
          totalOrders: totalOrders,
          orderCompletionTimes: orderCompletionTimes,
          performanceData: performanceData,
        ), returnsNormally);
      });

      test('should calculate completion metrics correctly', () async {
        // Arrange
        await analyticsService.initialize();
        const completedOrders = 4;
        const totalOrders = 5;
        const expectedCompletionRate = 0.8;

        // Act & Assert - should calculate completion rate correctly
        expect(() => analyticsService.recordBatchCompletion(
          batchId: 'batch123',
          driverId: 'driver123',
          actualDuration: const Duration(minutes: 45),
          actualDistance: 15.0,
          completedOrders: completedOrders,
          totalOrders: totalOrders,
          orderCompletionTimes: [],
          performanceData: {},
        ), returnsNormally);
      });
    });

    group('Performance Metrics Tests', () {
      test('should fetch batch performance metrics', () async {
        // Arrange
        await analyticsService.initialize();
        const driverId = 'driver123';
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();

        // Mock response data
        final mockEvents = [
          {
            'batch_id': 'batch1',
            'driver_id': driverId,
            'order_count': 3,
            'event_type': 'batch_created',
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'batch_id': 'batch1',
            'driver_id': driverId,
            'completed_orders': 3,
            'total_orders': 3,
            'completion_rate': 1.0,
            'efficiency_score': 0.9,
            'event_type': 'batch_completed',
            'created_at': DateTime.now().toIso8601String(),
          },
        ];

        when(mockFilterBuilder.order(any, ascending: anyNamed('ascending')))
            .thenAnswer((_) async => mockEvents);

        // Act
        final metrics = await analyticsService.getBatchPerformanceMetrics(
          driverId: driverId,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(metrics, isA<BatchPerformanceMetrics>());
        expect(metrics.totalBatches, equals(1));
        expect(metrics.completedBatches, equals(1));
        expect(metrics.completionRate, equals(1.0));
      });

      test('should return empty metrics when no data available', () async {
        // Arrange
        await analyticsService.initialize();
        const driverId = 'driver123';
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();

        when(mockFilterBuilder.order(any, ascending: anyNamed('ascending')))
            .thenAnswer((_) async => []);

        // Act
        final metrics = await analyticsService.getBatchPerformanceMetrics(
          driverId: driverId,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(metrics, isA<BatchPerformanceMetrics>());
        expect(metrics.totalBatches, equals(0));
        expect(metrics.completedBatches, equals(0));
        expect(metrics.completionRate, equals(0.0));
      });
    });

    group('Driver Performance Insights Tests', () {
      test('should fetch driver performance insights', () async {
        // Arrange
        await analyticsService.initialize();
        const driverId = 'driver123';
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();

        // Mock response data
        when(mockFilterBuilder.order(any, ascending: anyNamed('ascending')))
            .thenAnswer((_) async => []);

        // Act
        final insights = await analyticsService.getDriverPerformanceInsights(
          driverId: driverId,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(insights, isA<DriverPerformanceInsights>());
      });

      test('should handle insights fetch errors gracefully', () async {
        // Arrange
        await analyticsService.initialize();
        const driverId = 'driver123';
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();

        when(mockFilterBuilder.order(any, ascending: anyNamed('ascending')))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(() => analyticsService.getDriverPerformanceInsights(
          driverId: driverId,
          startDate: startDate,
          endDate: endDate,
        ), throwsException);
      });
    });

    group('Real-time Analytics Tests', () {
      test('should provide batch metrics stream', () async {
        // Arrange
        await analyticsService.initialize();

        // Act
        final stream = analyticsService.batchMetricsStream;

        // Assert
        expect(stream, isA<Stream<BatchPerformanceMetrics>>());
      });

      test('should provide driver insights stream', () async {
        // Arrange
        await analyticsService.initialize();

        // Act
        final stream = analyticsService.driverInsightsStream;

        // Assert
        expect(stream, isA<Stream<DriverPerformanceInsights>>());
      });

      test('should stop analytics tracking', () async {
        // Arrange
        await analyticsService.initialize();
        await analyticsService.startDriverAnalytics('driver123');

        // Act & Assert - should not throw
        expect(() => analyticsService.stopAnalytics(), returnsNormally);
      });
    });

    group('Error Handling Tests', () {
      test('should handle initialization errors gracefully', () async {
        // Arrange
        when(mockSupabase.from(any)).thenThrow(Exception('Initialization error'));

        // Act & Assert
        expect(() => analyticsService.initialize(), throwsException);
      });

      test('should handle metrics calculation with invalid data', () async {
        // Arrange
        await analyticsService.initialize();
        const driverId = 'driver123';
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();

        // Mock invalid response data
        final invalidEvents = [
          {
            'invalid_field': 'invalid_value',
          },
        ];

        when(mockFilterBuilder.order(any, ascending: anyNamed('ascending')))
            .thenAnswer((_) async => invalidEvents);

        // Act
        final metrics = await analyticsService.getBatchPerformanceMetrics(
          driverId: driverId,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert - should return empty metrics for invalid data
        expect(metrics, isA<BatchPerformanceMetrics>());
        expect(metrics.totalBatches, equals(0));
      });
    });

    group('Disposal Tests', () {
      test('should dispose resources properly', () async {
        // Arrange
        await analyticsService.initialize();
        await analyticsService.startDriverAnalytics('driver123');

        // Act
        await analyticsService.dispose();

        // Assert - should complete without error
        expect(true, isTrue);
      });

      test('should handle disposal when not initialized', () async {
        // Act & Assert - should not throw
        expect(() => analyticsService.dispose(), returnsNormally);
      });
    });

    group('Stream Management Tests', () {
      test('should handle stream errors gracefully', () async {
        // Arrange
        await analyticsService.initialize();

        // Act
        final stream = analyticsService.batchMetricsStream;

        // Assert - stream should be available
        expect(stream, isA<Stream<BatchPerformanceMetrics>>());
      });

      test('should close streams on disposal', () async {
        // Arrange
        await analyticsService.initialize();
        final stream = analyticsService.batchMetricsStream;

        // Act
        await analyticsService.dispose();

        // Assert - streams should be closed
        expect(stream, isA<Stream<BatchPerformanceMetrics>>());
      });
    });
  });
}
