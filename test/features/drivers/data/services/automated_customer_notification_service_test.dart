import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/automated_customer_notification_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/notification_models.dart';
import 'package:gigaeats_app/src/core/services/notification_service.dart';

import '../../../../test_helpers/test_data.dart';

// Generate mocks
@GenerateMocks([SupabaseClient, SupabaseQueryBuilder, NotificationService])
import 'automated_customer_notification_service_test.mocks.dart';

void main() {
  group('AutomatedCustomerNotificationService Tests - Phase 5.1', () {
    late AutomatedCustomerNotificationService notificationService;
    late MockSupabaseClient mockSupabase;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockNotificationService mockNotificationService;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockNotificationService = MockNotificationService();
      notificationService = AutomatedCustomerNotificationService();

      // Setup default mock responses
      when(mockSupabase.from(any)).thenReturn(mockQueryBuilder);
      when(mockQueryBuilder.insert(any)).thenAnswer((_) async => {});
      when(mockNotificationService.initialize()).thenAnswer((_) async => {});
      when(mockNotificationService.sendOrderNotification(
        userId: anyNamed('userId'),
        orderId: anyNamed('orderId'),
        title: anyNamed('title'),
        message: anyNamed('message'),
        type: anyNamed('type'),
      )).thenAnswer((_) async => {});
    });

    group('Initialization Tests', () {
      test('should initialize successfully', () async {
        // Act & Assert - should not throw
        expect(() => notificationService.initialize(), returnsNormally);
      });

      test('should initialize notification service dependency', () async {
        // Act
        await notificationService.initialize();

        // Assert
        verify(mockNotificationService.initialize()).called(1);
      });
    });

    group('Batch Assignment Notification Tests', () {
      test('should send batch assignment notifications to all customers', () async {
        // Arrange
        await notificationService.initialize();
        const batchId = 'batch-123';
        const driverId = 'driver-123';
        const driverName = 'John Driver';
        final orders = TestData.createBatchOrdersWithDetails(count: 3);

        // Act
        await notificationService.notifyBatchAssignment(
          batchId: batchId,
          driverId: driverId,
          driverName: driverName,
          orders: orders,
        );

        // Assert
        verify(mockNotificationService.sendOrderNotification(
          userId: anyNamed('userId'),
          orderId: anyNamed('orderId'),
          title: anyNamed('title'),
          message: anyNamed('message'),
          type: anyNamed('type'),
        )).called(3); // Should send to 3 customers

        verify(mockSupabase.from('notification_analytics')).called(1);
      });

      test('should handle empty orders list gracefully', () async {
        // Arrange
        await notificationService.initialize();
        const batchId = 'batch-123';
        const driverId = 'driver-123';
        const driverName = 'John Driver';
        final orders = <dynamic>[];

        // Act & Assert - should not throw
        expect(() => notificationService.notifyBatchAssignment(
          batchId: batchId,
          driverId: driverId,
          driverName: driverName,
          orders: orders,
        ), returnsNormally);
      });

      test('should create correct notification content for batch assignment', () async {
        // Arrange
        await notificationService.initialize();
        const batchId = 'batch-123';
        const driverId = 'driver-123';
        const driverName = 'John Driver';
        final orders = TestData.createBatchOrdersWithDetails(count: 1);
        final order = orders.first.order;

        // Act
        await notificationService.notifyBatchAssignment(
          batchId: batchId,
          driverId: driverId,
          driverName: driverName,
          orders: orders,
        );

        // Assert
        verify(mockNotificationService.sendOrderNotification(
          userId: order.customerId,
          orderId: order.id,
          title: 'Your order is being prepared',
          message: contains(driverName),
          type: 'orderUpdate',
        )).called(1);
      });
    });

    group('Driver En Route Notification Tests', () {
      test('should send driver en route to pickup notifications', () async {
        // Arrange
        await notificationService.initialize();
        const batchId = 'batch-123';
        const driverId = 'driver-123';
        const driverName = 'John Driver';
        final orders = TestData.createBatchOrdersWithDetails(count: 2);
        const estimatedArrival = Duration(minutes: 15);

        // Act
        await notificationService.notifyDriverEnRouteToPickup(
          batchId: batchId,
          driverId: driverId,
          driverName: driverName,
          orders: orders,
          estimatedArrival: estimatedArrival,
        );

        // Assert
        verify(mockNotificationService.sendOrderNotification(
          userId: anyNamed('userId'),
          orderId: anyNamed('orderId'),
          title: 'Driver heading to restaurant',
          message: contains('15 minutes'),
          type: 'driverUpdate',
        )).called(2);
      });

      test('should format ETA correctly in notifications', () async {
        // Arrange
        await notificationService.initialize();
        const batchId = 'batch-123';
        const driverId = 'driver-123';
        const driverName = 'John Driver';
        final orders = TestData.createBatchOrdersWithDetails(count: 1);

        // Test different ETA formats
        const shortETA = Duration(minutes: 5);
        const longETA = Duration(hours: 1, minutes: 30);

        // Act
        await notificationService.notifyDriverEnRouteToPickup(
          batchId: batchId,
          driverId: driverId,
          driverName: driverName,
          orders: orders,
          estimatedArrival: shortETA,
        );

        await notificationService.notifyDriverEnRouteToPickup(
          batchId: batchId,
          driverId: driverId,
          driverName: driverName,
          orders: orders,
          estimatedArrival: longETA,
        );

        // Assert
        verify(mockNotificationService.sendOrderNotification(
          userId: anyNamed('userId'),
          orderId: anyNamed('orderId'),
          title: anyNamed('title'),
          message: contains('5 minutes'),
          type: anyNamed('type'),
        )).called(1);

        verify(mockNotificationService.sendOrderNotification(
          userId: anyNamed('userId'),
          orderId: anyNamed('orderId'),
          title: anyNamed('title'),
          message: contains('1h 30m'),
          type: anyNamed('type'),
        )).called(1);
      });
    });

    group('Order Status Notification Tests', () {
      test('should send order picked up notification', () async {
        // Arrange
        await notificationService.initialize();
        const orderId = 'order-123';
        const customerId = 'customer-123';
        const driverName = 'John Driver';
        const vendorName = 'Test Restaurant';

        // Act
        await notificationService.notifyOrderPickedUp(
          orderId: orderId,
          customerId: customerId,
          driverName: driverName,
          vendorName: vendorName,
        );

        // Assert
        verify(mockNotificationService.sendOrderNotification(
          userId: customerId,
          orderId: orderId,
          title: 'Order picked up!',
          message: contains(driverName),
          type: 'orderUpdate',
        )).called(1);
      });

      test('should send driver en route to delivery notification', () async {
        // Arrange
        await notificationService.initialize();
        const orderId = 'order-123';
        const customerId = 'customer-123';
        const driverName = 'John Driver';
        const estimatedArrival = Duration(minutes: 20);

        // Act
        await notificationService.notifyDriverEnRouteToDelivery(
          orderId: orderId,
          customerId: customerId,
          driverName: driverName,
          estimatedArrival: estimatedArrival,
        );

        // Assert
        verify(mockNotificationService.sendOrderNotification(
          userId: customerId,
          orderId: orderId,
          title: 'Your order is on the way',
          message: allOf(
            contains(driverName),
            contains('20 minutes'),
          ),
          type: 'driverUpdate',
        )).called(1);
      });

      test('should send driver nearby notification', () async {
        // Arrange
        await notificationService.initialize();
        const orderId = 'order-123';
        const customerId = 'customer-123';
        const driverName = 'John Driver';
        const distanceMeters = 500.0;

        // Act
        await notificationService.notifyDriverNearby(
          orderId: orderId,
          customerId: customerId,
          driverName: driverName,
          distanceMeters: distanceMeters,
        );

        // Assert
        verify(mockNotificationService.sendOrderNotification(
          userId: customerId,
          orderId: orderId,
          title: 'Driver is nearby',
          message: allOf(
            contains(driverName),
            contains('500m'),
          ),
          type: 'driverUpdate',
        )).called(1);
      });

      test('should send order delivered notification', () async {
        // Arrange
        await notificationService.initialize();
        const orderId = 'order-123';
        const customerId = 'customer-123';

        // Act
        await notificationService.notifyOrderDelivered(
          orderId: orderId,
          customerId: customerId,
        );

        // Assert
        verify(mockNotificationService.sendOrderNotification(
          userId: customerId,
          orderId: orderId,
          title: 'Order delivered!',
          message: contains('successfully delivered'),
          type: 'orderUpdate',
        )).called(1);
      });
    });

    group('Delay Notification Tests', () {
      test('should send delivery delay notification', () async {
        // Arrange
        await notificationService.initialize();
        const orderId = 'order-123';
        const customerId = 'customer-123';
        const delayDuration = Duration(minutes: 15);
        const reason = 'Heavy traffic';
        const newETA = Duration(minutes: 45);

        // Act
        await notificationService.notifyDeliveryDelay(
          orderId: orderId,
          customerId: customerId,
          delayDuration: delayDuration,
          reason: reason,
          newETA: newETA,
        );

        // Assert
        verify(mockNotificationService.sendOrderNotification(
          userId: customerId,
          orderId: orderId,
          title: 'Delivery update',
          message: allOf(
            contains('15 minutes'),
            contains(reason),
            contains('45 minutes'),
          ),
          type: 'delayAlert',
        )).called(1);
      });

      test('should handle different delay reasons', () async {
        // Arrange
        await notificationService.initialize();
        const orderId = 'order-123';
        const customerId = 'customer-123';
        const delayDuration = Duration(minutes: 10);
        const newETA = Duration(minutes: 30);

        final reasons = [
          'Heavy traffic',
          'Weather conditions',
          'Restaurant delay',
          'Vehicle breakdown',
        ];

        // Act
        for (final reason in reasons) {
          await notificationService.notifyDeliveryDelay(
            orderId: orderId,
            customerId: customerId,
            delayDuration: delayDuration,
            reason: reason,
            newETA: newETA,
          );
        }

        // Assert
        verify(mockNotificationService.sendOrderNotification(
          userId: customerId,
          orderId: orderId,
          title: 'Delivery update',
          message: anyNamed('message'),
          type: 'delayAlert',
        )).called(4);
      });
    });

    group('Batch Optimization Notification Tests', () {
      test('should send batch optimization notifications', () async {
        // Arrange
        await notificationService.initialize();
        const batchId = 'batch-123';
        final customerIds = ['customer-1', 'customer-2', 'customer-3'];
        const timeSaved = Duration(minutes: 10);

        // Act
        await notificationService.notifyBatchOptimization(
          batchId: batchId,
          customerIds: customerIds,
          timeSaved: timeSaved,
        );

        // Assert
        verify(mockNotificationService.sendOrderNotification(
          userId: anyNamed('userId'),
          orderId: '',
          title: 'Delivery optimized',
          message: contains('10 minutes earlier'),
          type: 'orderUpdate',
        )).called(3);
      });

      test('should handle empty customer list for optimization', () async {
        // Arrange
        await notificationService.initialize();
        const batchId = 'batch-123';
        final customerIds = <String>[];
        const timeSaved = Duration(minutes: 5);

        // Act & Assert - should not throw
        expect(() => notificationService.notifyBatchOptimization(
          batchId: batchId,
          customerIds: customerIds,
          timeSaved: timeSaved,
        ), returnsNormally);
      });
    });

    group('Distance and Time Formatting Tests', () {
      test('should format distances correctly', () async {
        // Arrange
        await notificationService.initialize();
        const orderId = 'order-123';
        const customerId = 'customer-123';
        const driverName = 'John Driver';

        // Test different distances
        const shortDistance = 250.0; // meters
        const longDistance = 1500.0; // meters

        // Act
        await notificationService.notifyDriverNearby(
          orderId: orderId,
          customerId: customerId,
          driverName: driverName,
          distanceMeters: shortDistance,
        );

        await notificationService.notifyDriverNearby(
          orderId: orderId,
          customerId: customerId,
          driverName: driverName,
          distanceMeters: longDistance,
        );

        // Assert
        verify(mockNotificationService.sendOrderNotification(
          userId: customerId,
          orderId: orderId,
          title: anyNamed('title'),
          message: contains('250m'),
          type: anyNamed('type'),
        )).called(1);

        verify(mockNotificationService.sendOrderNotification(
          userId: customerId,
          orderId: orderId,
          title: anyNamed('title'),
          message: contains('1.5km'),
          type: anyNamed('type'),
        )).called(1);
      });

      test('should format time durations correctly', () async {
        // Arrange
        await notificationService.initialize();
        const orderId = 'order-123';
        const customerId = 'customer-123';
        const driverName = 'John Driver';

        // Test different durations
        const shortDuration = Duration(minutes: 5);
        const mediumDuration = Duration(minutes: 45);
        const longDuration = Duration(hours: 2, minutes: 15);

        // Act
        await notificationService.notifyDriverEnRouteToDelivery(
          orderId: orderId,
          customerId: customerId,
          driverName: driverName,
          estimatedArrival: shortDuration,
        );

        await notificationService.notifyDriverEnRouteToDelivery(
          orderId: orderId,
          customerId: customerId,
          driverName: driverName,
          estimatedArrival: mediumDuration,
        );

        await notificationService.notifyDriverEnRouteToDelivery(
          orderId: orderId,
          customerId: customerId,
          driverName: driverName,
          estimatedArrival: longDuration,
        );

        // Assert
        verify(mockNotificationService.sendOrderNotification(
          userId: customerId,
          orderId: orderId,
          title: anyNamed('title'),
          message: contains('5 minutes'),
          type: anyNamed('type'),
        )).called(1);

        verify(mockNotificationService.sendOrderNotification(
          userId: customerId,
          orderId: orderId,
          title: anyNamed('title'),
          message: contains('45 minutes'),
          type: anyNamed('type'),
        )).called(1);

        verify(mockNotificationService.sendOrderNotification(
          userId: customerId,
          orderId: orderId,
          title: anyNamed('title'),
          message: contains('2h 15m'),
          type: anyNamed('type'),
        )).called(1);
      });
    });

    group('Error Handling Tests', () {
      test('should handle notification service failures gracefully', () async {
        // Arrange
        await notificationService.initialize();
        when(mockNotificationService.sendOrderNotification(
          userId: anyNamed('userId'),
          orderId: anyNamed('orderId'),
          title: anyNamed('title'),
          message: anyNamed('message'),
          type: anyNamed('type'),
        )).thenThrow(Exception('Notification service error'));

        const orderId = 'order-123';
        const customerId = 'customer-123';

        // Act & Assert - should not throw
        expect(() => notificationService.notifyOrderDelivered(
          orderId: orderId,
          customerId: customerId,
        ), returnsNormally);
      });

      test('should handle database insertion failures gracefully', () async {
        // Arrange
        await notificationService.initialize();
        when(mockQueryBuilder.insert(any)).thenThrow(Exception('Database error'));

        const orderId = 'order-123';
        const customerId = 'customer-123';

        // Act & Assert - should not throw
        expect(() => notificationService.notifyOrderDelivered(
          orderId: orderId,
          customerId: customerId,
        ), returnsNormally);
      });

      test('should handle invalid notification data gracefully', () async {
        // Arrange
        await notificationService.initialize();

        // Act & Assert - should not throw with empty/null values
        expect(() => notificationService.notifyOrderPickedUp(
          orderId: '',
          customerId: '',
          driverName: '',
          vendorName: '',
        ), returnsNormally);
      });
    });

    group('Analytics Recording Tests', () {
      test('should record notification analytics events', () async {
        // Arrange
        await notificationService.initialize();
        const batchId = 'batch-123';
        const driverId = 'driver-123';
        const driverName = 'John Driver';
        final orders = TestData.createBatchOrdersWithDetails(count: 2);

        // Act
        await notificationService.notifyBatchAssignment(
          batchId: batchId,
          driverId: driverId,
          driverName: driverName,
          orders: orders,
        );

        // Assert
        verify(mockSupabase.from('notification_analytics')).called(1);
        verify(mockQueryBuilder.insert(argThat(
          allOf(
            containsPair('event_type', 'batch_assignment_notifications_sent'),
            containsPair('batch_id', batchId),
            containsPair('driver_id', driverId),
            containsPair('order_count', 2),
          ),
        ))).called(1);
      });

      test('should handle analytics recording failures gracefully', () async {
        // Arrange
        await notificationService.initialize();
        when(mockSupabase.from('notification_analytics')).thenThrow(Exception('Analytics error'));

        const batchId = 'batch-123';
        const driverId = 'driver-123';
        const driverName = 'John Driver';
        final orders = TestData.createBatchOrdersWithDetails(count: 1);

        // Act & Assert - should not throw
        expect(() => notificationService.notifyBatchAssignment(
          batchId: batchId,
          driverId: driverId,
          driverName: driverName,
          orders: orders,
        ), returnsNormally);
      });
    });

    group('Disposal Tests', () {
      test('should dispose resources properly', () async {
        // Arrange
        await notificationService.initialize();

        // Act & Assert - should not throw
        expect(() => notificationService.dispose(), returnsNormally);
      });

      test('should handle disposal when not initialized', () async {
        // Act & Assert - should not throw
        expect(() => notificationService.dispose(), returnsNormally);
      });
    });
  });
}
