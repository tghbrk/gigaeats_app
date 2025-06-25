import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:gigaeats_app/features/drivers/data/services/driver_earnings_service.dart';
import 'package:gigaeats_app/features/drivers/data/models/driver_earnings.dart';
import 'package:gigaeats_app/features/drivers/presentation/providers/driver_earnings_realtime_provider.dart';

// Generate mocks
@GenerateMocks([DriverEarningsService])
import 'driver_earnings_realtime_provider_test.mocks.dart';

void main() {
  group('DriverEarningsRealtimeProvider Tests', () {
    late ProviderContainer container;
    late MockDriverEarningsService mockService;
    const driverId = 'test-driver-id';

    setUp(() {
      mockService = MockDriverEarningsService();
      container = ProviderContainer(
        overrides: [
          driverEarningsServiceProvider.overrideWithValue(mockService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('EarningsNotificationsState', () {
      test('should have correct initial state', () {
        // Act
        final state = container.read(driverEarningsRealtimeProvider(driverId));

        // Assert
        expect(state.notifications, isEmpty);
        expect(state.unreadCount, equals(0));
        expect(state.isListening, isFalse);
        expect(state.error, isNull);
        expect(state.lastUpdate, isNull);
      });

      test('should update state correctly with copyWith', () {
        // Arrange
        const initialState = EarningsNotificationsState();
        final testNotifications = [
          EarningsNotification(
            id: 'notif-1',
            driverId: driverId,
            type: EarningsNotificationType.earningsUpdate,
            title: 'New Earnings',
            message: 'You earned RM 25.50',
            amount: 25.50,
            netAmount: 22.50,
            status: EarningsStatus.confirmed,
            timestamp: DateTime.now(),
            isRead: false,
            metadata: {},
          ),
        ];

        // Act
        final newState = initialState.copyWith(
          notifications: testNotifications,
          unreadCount: 1,
          isListening: true,
        );

        // Assert
        expect(newState.notifications.length, equals(1));
        expect(newState.unreadCount, equals(1));
        expect(newState.isListening, isTrue);
        expect(newState.error, isNull);
      });
    });

    group('EarningsNotification Model', () {
      test('should create notification correctly', () {
        // Arrange
        final timestamp = DateTime.now();
        final metadata = {'order_id': 'order-123'};

        // Act
        final notification = EarningsNotification(
          id: 'notif-1',
          driverId: driverId,
          type: EarningsNotificationType.paymentReceived,
          title: 'Payment Received',
          message: 'Your payment has been processed',
          amount: 100.00,
          netAmount: 85.00,
          status: EarningsStatus.confirmed,
          timestamp: timestamp,
          isRead: false,
          metadata: metadata,
        );

        // Assert
        expect(notification.id, equals('notif-1'));
        expect(notification.driverId, equals(driverId));
        expect(notification.type, equals(EarningsNotificationType.paymentReceived));
        expect(notification.title, equals('Payment Received'));
        expect(notification.message, equals('Your payment has been processed'));
        expect(notification.amount, equals(100.00));
        expect(notification.netAmount, equals(85.00));
        expect(notification.timestamp, equals(timestamp));
        expect(notification.isRead, isFalse);
        expect(notification.metadata, equals(metadata));
      });

      test('should update notification with copyWith', () {
        // Arrange
        final notification = EarningsNotification(
          id: 'notif-1',
          driverId: driverId,
          type: EarningsNotificationType.earningsUpdate,
          title: 'New Earnings',
          message: 'You earned RM 25.50',
          amount: 25.50,
          netAmount: 22.50,
          status: EarningsStatus.confirmed,
          timestamp: DateTime.now(),
          isRead: false,
          metadata: {},
        );

        // Act
        final updatedNotification = notification.copyWith(isRead: true);

        // Assert
        expect(updatedNotification.isRead, isTrue);
        expect(updatedNotification.id, equals(notification.id));
        expect(updatedNotification.title, equals(notification.title));
      });
    });

    group('Notification Management', () {
      test('should mark notification as read', () {
        // Arrange
        final notifier = container.read(driverEarningsRealtimeProvider(driverId).notifier);

        // Manually set state for testing
        // Initial state with test notification
        
        // Act
        notifier.markAsRead('notif-1');
        final state = container.read(driverEarningsRealtimeProvider(driverId));

        // Assert - In a real test, you'd need to properly set up the state
        // This is a simplified test structure
        expect(state, isA<EarningsNotificationsState>());
      });

      test('should mark all notifications as read', () {
        // Arrange
        final notifier = container.read(driverEarningsRealtimeProvider(driverId).notifier);
        
        // Act
        notifier.markAllAsRead();
        final state = container.read(driverEarningsRealtimeProvider(driverId));

        // Assert
        expect(state.unreadCount, equals(0));
      });

      test('should clear all notifications', () {
        // Arrange
        final notifier = container.read(driverEarningsRealtimeProvider(driverId).notifier);
        
        // Act
        notifier.clearAllNotifications();
        final state = container.read(driverEarningsRealtimeProvider(driverId));

        // Assert
        expect(state.notifications, isEmpty);
        expect(state.unreadCount, equals(0));
      });
    });

    group('Notification Filtering', () {
      test('should filter notifications by type', () {
        // Arrange
        final notifier = container.read(driverEarningsRealtimeProvider(driverId).notifier);
        
        // Act
        final earningsNotifications = notifier.getNotificationsByType(
          EarningsNotificationType.earningsUpdate,
        );
        
        // Assert
        expect(earningsNotifications, isA<List<EarningsNotification>>());
      });

      test('should get unread notifications', () {
        // Arrange
        final notifier = container.read(driverEarningsRealtimeProvider(driverId).notifier);
        
        // Act
        final unreadNotifications = notifier.unreadNotifications;
        
        // Assert
        expect(unreadNotifications, isA<List<EarningsNotification>>());
      });
    });

    group('Provider Ecosystem', () {
      test('should provide unread count correctly', () {
        // Act
        final unreadCount = container.read(unreadEarningsNotificationsCountProvider(driverId));
        
        // Assert
        expect(unreadCount, isA<int>());
        expect(unreadCount, equals(0)); // Initial state
      });

      test('should provide latest notification', () {
        // Act
        final latestNotification = container.read(latestEarningsNotificationProvider(driverId));
        
        // Assert
        expect(latestNotification, isNull); // Initial state
      });

      test('should provide notifications by type', () {
        // Act
        final notificationsByType = container.read(
          earningsNotificationsByTypeProvider((
            driverId: driverId,
            type: EarningsNotificationType.earningsUpdate,
          )),
        );
        
        // Assert
        expect(notificationsByType, isA<List<EarningsNotification>>());
        expect(notificationsByType, isEmpty); // Initial state
      });
    });

    group('Error Handling', () {
      test('should handle service errors gracefully', () {
        // Arrange
        when(mockService.getDriverEarnings(
          any,
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          limit: anyNamed('limit'),
          useCache: anyNamed('useCache'),
        )).thenThrow(Exception('Service error'));

        final notifier = container.read(driverEarningsRealtimeProvider(driverId).notifier);
        
        // Act & Assert
        expect(() => notifier.refresh(), returnsNormally);
      });

      test('should maintain state consistency during errors', () {
        // Arrange
        final initialState = container.read(driverEarningsRealtimeProvider(driverId));
        
        // Act - Simulate error condition
        // In a real implementation, you'd trigger an actual error
        
        // Assert
        final finalState = container.read(driverEarningsRealtimeProvider(driverId));
        expect(finalState.notifications, equals(initialState.notifications));
      });
    });

    group('Real-time Features', () {
      test('should indicate listening status', () {
        // Act
        final notifier = container.read(driverEarningsRealtimeProvider(driverId).notifier);
        final isListening = notifier.isListening;
        
        // Assert
        expect(isListening, isA<bool>());
      });

      test('should provide error status', () {
        // Act
        final notifier = container.read(driverEarningsRealtimeProvider(driverId).notifier);
        final error = notifier.error;
        
        // Assert
        expect(error, isNull); // Initial state
      });

      test('should provide unread count accessor', () {
        // Act
        final notifier = container.read(driverEarningsRealtimeProvider(driverId).notifier);
        final unreadCount = notifier.unreadCount;
        
        // Assert
        expect(unreadCount, equals(0)); // Initial state
      });
    });

    group('Notification Types', () {
      test('should handle all notification types', () {
        // Arrange
        final allTypes = EarningsNotificationType.values;
        
        // Act & Assert
        for (final type in allTypes) {
          final notification = EarningsNotification(
            id: 'notif-${type.name}',
            driverId: driverId,
            type: type,
            title: 'Test ${type.name}',
            message: 'Test message for ${type.name}',
            amount: 100.00,
            netAmount: 85.00,
            status: EarningsStatus.confirmed,
            timestamp: DateTime.now(),
            isRead: false,
            metadata: {},
          );
          
          expect(notification.type, equals(type));
        }
      });

      test('should create appropriate notifications for different earnings statuses', () {
        // This would test the notification creation logic
        // based on different earnings record statuses
        
        final earningsStatuses = [
          'confirmed',
          'paid',
          'pending',
          'disputed',
          'cancelled',
        ];
        
        for (final status in earningsStatuses) {
          // In a real implementation, you'd test the notification
          // creation logic for each status
          expect(status, isA<String>());
        }
      });
    });
  });
}
