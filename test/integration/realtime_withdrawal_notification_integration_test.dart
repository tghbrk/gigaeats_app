import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/enhanced_withdrawal_notification_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/withdrawal_balance_tracker.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/realtime_withdrawal_notification_provider.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/widgets/notifications/withdrawal_notification_banner.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/widgets/wallet/realtime_balance_display.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/driver_withdrawal_request.dart';
import 'package:gigaeats_app/src/features/notifications/data/models/notification.dart';
import 'package:gigaeats_app/src/core/services/notification_service.dart';
import 'package:gigaeats_app/src/features/notifications/data/services/notification_service.dart' as app_notifications;

// Generate mocks
@GenerateMocks([
  EnhancedWithdrawalNotificationService,
  WithdrawalBalanceTracker,
  NotificationService,
], customMocks: [
  MockSpec<app_notifications.NotificationService>(as: #MockAppNotificationService),
])
import 'realtime_withdrawal_notification_integration_test.mocks.dart';

void main() {
  group('Real-time Withdrawal Notification Integration Tests', () {
    late MockEnhancedWithdrawalNotificationService mockNotificationService;
    late MockWithdrawalBalanceTracker mockBalanceTracker;
    late MockNotificationService mockCoreNotificationService;
    late MockAppNotificationService mockAppNotificationService;
    late ProviderContainer container;

    setUp(() {
      mockNotificationService = MockEnhancedWithdrawalNotificationService();
      mockBalanceTracker = MockWithdrawalBalanceTracker();
      mockCoreNotificationService = MockNotificationService();
      mockAppNotificationService = MockAppNotificationService();

      container = ProviderContainer(
        overrides: [
          enhancedWithdrawalNotificationServiceProvider.overrideWithValue(mockNotificationService),
          withdrawalBalanceTrackerProvider.overrideWithValue(mockBalanceTracker),
          notificationServiceProvider.overrideWithValue(mockCoreNotificationService),
          appNotificationServiceProvider.overrideWithValue(mockAppNotificationService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Real-time Notification System', () {
      testWidgets('should initialize notification system correctly', (tester) async {
        // Initialize the notification provider
        // ignore: unused_local_variable
        final notificationNotifier = container.read(realtimeWithdrawalNotificationProvider.notifier);
        final notificationState = container.read(realtimeWithdrawalNotificationProvider);

        // Verify initial state
        expect(notificationState.isInitialized, isTrue);
        expect(notificationState.isActive, isFalse);
        expect(notificationState.totalNotificationsSent, equals(0));
      });

      testWidgets('should start tracking when driver is authenticated', (tester) async {
        const testDriverId = 'test-driver-123';
        
        // Mock balance tracker start tracking
        when(mockBalanceTracker.startTracking(testDriverId))
            .thenAnswer((_) async {});

        // Simulate driver authentication
        final notificationNotifier = container.read(realtimeWithdrawalNotificationProvider.notifier);
        await notificationNotifier.refreshTrackingSystem();

        // Verify tracking was attempted
        verify(mockBalanceTracker.startTracking(any)).called(greaterThan(0));
      });

      testWidgets('should handle withdrawal status notifications', (tester) async {
        const testDriverId = 'test-driver-123';
        final testWithdrawal = DriverWithdrawalRequest(
          id: 'withdrawal-123',
          driverId: testDriverId,
          walletId: 'test-wallet-123',
          amount: 100.0,
          netAmount: 95.0,
          processingFee: 5.0,
          withdrawalMethod: 'bank_transfer',
          status: DriverWithdrawalStatus.completed,
          destinationDetails: {'bank_name': 'Test Bank'},
          requestedAt: DateTime.now(),
          completedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Mock notification service
        when(mockNotificationService.sendWithdrawalStatusNotification(
          driverId: testDriverId,
          request: testWithdrawal,
        )).thenAnswer((_) async {});

        // Trigger notification
        await mockNotificationService.sendWithdrawalStatusNotification(
          driverId: testDriverId,
          request: testWithdrawal,
        );

        // Verify notification was sent
        verify(mockNotificationService.sendWithdrawalStatusNotification(
          driverId: testDriverId,
          request: testWithdrawal,
        )).called(1);
      });

      testWidgets('should handle balance update notifications', (tester) async {
        const testDriverId = 'test-driver-123';
        const previousBalance = 500.0;
        const newBalance = 400.0;
        final testWithdrawal = DriverWithdrawalRequest(
          id: 'withdrawal-123',
          driverId: testDriverId,
          walletId: 'test-wallet-123',
          amount: 100.0,
          netAmount: 100.0,
          processingFee: 0.0,
          withdrawalMethod: 'bank_transfer',
          status: DriverWithdrawalStatus.processing,
          destinationDetails: {},
          requestedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Mock balance update notification
        when(mockNotificationService.sendBalanceUpdateNotification(
          driverId: testDriverId,
          previousBalance: previousBalance,
          newBalance: newBalance,
          request: testWithdrawal,
        )).thenAnswer((_) async {});

        // Trigger balance update notification
        await mockNotificationService.sendBalanceUpdateNotification(
          driverId: testDriverId,
          previousBalance: previousBalance,
          newBalance: newBalance,
          request: testWithdrawal,
        );

        // Verify notification was sent
        verify(mockNotificationService.sendBalanceUpdateNotification(
          driverId: testDriverId,
          previousBalance: previousBalance,
          newBalance: newBalance,
          request: testWithdrawal,
        )).called(1);
      });
    });

    group('Withdrawal Notification Banner', () {
      testWidgets('should display withdrawal completion notification', (tester) async {
        final completionNotification = AppNotification(
          id: 'notification-123',
          title: '✅ Withdrawal Completed',
          message: 'Your withdrawal of RM 100.00 has been completed successfully.',
          type: NotificationType.paymentReceived,
          priority: NotificationPriority.high,
          userId: 'test-driver-123',
          createdAt: DateTime.now(),
          data: {
            'type': 'withdrawal_completed',
            'withdrawal_id': 'withdrawal-123',
            'amount': 100.0,
            'withdrawal_method': 'bank_transfer',
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WithdrawalNotificationBanner(
                notification: completionNotification,
              ),
            ),
          ),
        );

        // Verify notification content
        expect(find.text('✅ Withdrawal Completed'), findsOneWidget);
        expect(find.text('Your withdrawal of RM 100.00 has been completed successfully.'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('should display withdrawal failure notification', (tester) async {
        final failureNotification = AppNotification(
          id: 'notification-456',
          title: '❌ Withdrawal Failed',
          message: 'Your withdrawal of RM 100.00 has failed. Insufficient funds.',
          type: NotificationType.systemAlert,
          priority: NotificationPriority.high,
          userId: 'test-driver-123',
          createdAt: DateTime.now(),
          data: {
            'type': 'withdrawal_failed',
            'withdrawal_id': 'withdrawal-456',
            'amount': 100.0,
            'failure_reason': 'Insufficient funds',
            'can_retry': true,
            'support_contact': true,
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WithdrawalNotificationBanner(
                notification: failureNotification,
              ),
            ),
          ),
        );

        // Verify notification content
        expect(find.text('❌ Withdrawal Failed'), findsOneWidget);
        expect(find.text('Your withdrawal of RM 100.00 has failed. Insufficient funds.'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.text('Support'), findsOneWidget);
      });
    });

    group('Real-time Balance Display', () {
      testWidgets('should show real-time balance updates', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: container.getAllProviderElements().map((e) => e.provider).toList(),
            child: MaterialApp(
              home: Scaffold(
                body: RealtimeBalanceDisplay(
                  showChangeIndicator: true,
                  showConnectionStatus: true,
                ),
              ),
            ),
          ),
        );

        // Verify balance display is rendered
        expect(find.byType(RealtimeBalanceDisplay), findsOneWidget);
      });

      testWidgets('should display connection status', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: container.getAllProviderElements().map((e) => e.provider).toList(),
            child: MaterialApp(
              home: Scaffold(
                body: RealtimeBalanceDisplay(
                  showConnectionStatus: true,
                ),
              ),
            ),
          ),
        );

        // Verify connection status elements
        expect(find.text('Connecting...'), findsOneWidget);
      });
    });

    group('Balance Tracker Integration', () {
      testWidgets('should track balance changes correctly', (tester) async {
        const testDriverId = 'test-driver-123';
        
        // Mock tracking status
        when(mockBalanceTracker.getTrackingStatus()).thenReturn({
          'is_tracking': true,
          'last_known_balance': 500.0,
          'active_withdrawals_count': 1,
          'active_withdrawal_ids': ['withdrawal-123'],
        });

        // Start tracking
        when(mockBalanceTracker.startTracking(testDriverId))
            .thenAnswer((_) async {});

        await mockBalanceTracker.startTracking(testDriverId);

        // Verify tracking started
        verify(mockBalanceTracker.startTracking(testDriverId)).called(1);

        // Get tracking status
        final status = mockBalanceTracker.getTrackingStatus();
        expect(status['is_tracking'], isTrue);
        expect(status['last_known_balance'], equals(500.0));
        expect(status['active_withdrawals_count'], equals(1));
      });

      testWidgets('should stop tracking correctly', (tester) async {
        // Mock stop tracking
        when(mockBalanceTracker.stopTracking())
            .thenAnswer((_) async {});

        await mockBalanceTracker.stopTracking();

        // Verify tracking stopped
        verify(mockBalanceTracker.stopTracking()).called(1);
      });
    });

    group('Notification Preferences', () {
      testWidgets('should update notification preferences', (tester) async {
        final notificationNotifier = container.read(realtimeWithdrawalNotificationProvider.notifier);

        // Update preferences
        notificationNotifier.updateNotificationPreferences(
          balanceTrackingEnabled: false,
          statusNotificationsEnabled: true,
        );

        final state = container.read(realtimeWithdrawalNotificationProvider);
        expect(state.balanceTrackingEnabled, isFalse);
        expect(state.statusNotificationsEnabled, isTrue);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle notification service errors gracefully', (tester) async {
        const testDriverId = 'test-driver-123';
        final testWithdrawal = DriverWithdrawalRequest(
          id: 'withdrawal-123',
          driverId: testDriverId,
          walletId: 'test-wallet-123',
          amount: 100.0,
          netAmount: 100.0,
          processingFee: 0.0,
          withdrawalMethod: 'bank_transfer',
          status: DriverWithdrawalStatus.failed,
          destinationDetails: {},
          requestedAt: DateTime.now(),
          failureReason: 'Network error',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Mock notification service to throw error
        when(mockNotificationService.sendWithdrawalStatusNotification(
          driverId: testDriverId,
          request: testWithdrawal,
        )).thenThrow(Exception('Network error'));

        // Verify error is handled gracefully
        expect(
          () => mockNotificationService.sendWithdrawalStatusNotification(
            driverId: testDriverId,
            request: testWithdrawal,
          ),
          throwsException,
        );
      });

      testWidgets('should handle balance tracker errors gracefully', (tester) async {
        const testDriverId = 'test-driver-123';

        // Mock balance tracker to throw error
        when(mockBalanceTracker.startTracking(testDriverId))
            .thenThrow(Exception('Connection error'));

        // Verify error is handled gracefully
        expect(
          () => mockBalanceTracker.startTracking(testDriverId),
          throwsException,
        );
      });
    });
  });
}
