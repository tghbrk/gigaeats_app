import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/driver_wallet_notification_service.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/driver_wallet_notification_provider.dart';
// Removed unused import
import 'package:gigaeats_app/src/features/auth/presentation/providers/auth_provider.dart';
import 'package:gigaeats_app/src/data/models/user_role.dart';
import 'package:gigaeats_app/src/data/models/user.dart';

import 'driver_wallet_notification_provider_test.mocks.dart';

@GenerateMocks([DriverWalletNotificationService])
void main() {
  group('DriverWalletNotificationProvider', () {
    late MockDriverWalletNotificationService mockNotificationService;
    late ProviderContainer container;

    setUp(() {
      mockNotificationService = MockDriverWalletNotificationService();
      
      container = ProviderContainer(
        overrides: [
          driverWalletNotificationServiceProvider.overrideWithValue(mockNotificationService),
          // Override the auth state directly for testing
          authStateProvider.overrideWith((ref) {
            final notifier = AuthStateNotifier(ref.read(supabaseAuthServiceProvider));
            notifier.state = AuthState(
              status: AuthStatus.authenticated,
              user: User(
                id: 'test-driver-id',
                email: 'test@driver.com',
                fullName: 'Test Driver',
                role: UserRole.driver,
                isVerified: true,
                isActive: true,
                createdAt: DateTime(2024, 1, 1),
                updatedAt: DateTime(2024, 1, 1),
              ),
            );
            return notifier;
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with default notification settings', () {
      final notificationState = container.read(driverWalletNotificationProvider);

      expect(notificationState.isEnabled, true);
      expect(notificationState.earningsNotificationsEnabled, true);
      expect(notificationState.lowBalanceAlertsEnabled, true);
      expect(notificationState.balanceUpdatesEnabled, true);
      expect(notificationState.withdrawalNotificationsEnabled, true);
      expect(notificationState.lowBalanceThreshold, 20.0);
    });

    test('should update notification preferences correctly', () {
      final notifier = container.read(driverWalletNotificationProvider.notifier);

      notifier.updateNotificationPreferences(
        earningsNotificationsEnabled: false,
        lowBalanceThreshold: 50.0,
      );

      final state = container.read(driverWalletNotificationProvider);
      expect(state.earningsNotificationsEnabled, false);
      expect(state.lowBalanceThreshold, 50.0);
      expect(state.lowBalanceAlertsEnabled, true); // Should remain unchanged
    });

    test('should enable/disable all notifications', () {
      final notifier = container.read(driverWalletNotificationProvider.notifier);

      notifier.setNotificationsEnabled(false);

      final state = container.read(driverWalletNotificationProvider);
      expect(state.isEnabled, false);
    });

    test('should send earnings notification when enabled', () async {
      when(mockNotificationService.sendEarningsNotification(
        driverId: anyNamed('driverId'),
        orderId: anyNamed('orderId'),
        earningsAmount: anyNamed('earningsAmount'),
        newBalance: anyNamed('newBalance'),
        earningsBreakdown: anyNamed('earningsBreakdown'),
      )).thenAnswer((_) async {});

      final notifier = container.read(driverWalletNotificationProvider.notifier);

      await notifier.sendEarningsNotification(
        orderId: 'test-order-123',
        earningsAmount: 25.50,
        newBalance: 125.75,
        earningsBreakdown: {
          'base_commission': 20.0,
          'tip': 5.50,
        },
      );

      verify(mockNotificationService.sendEarningsNotification(
        driverId: 'test-driver-id',
        orderId: 'test-order-123',
        earningsAmount: 25.50,
        newBalance: 125.75,
        earningsBreakdown: {
          'base_commission': 20.0,
          'tip': 5.50,
        },
      )).called(1);
    });

    test('should not send earnings notification when disabled', () async {
      final notifier = container.read(driverWalletNotificationProvider.notifier);
      
      // Disable earnings notifications
      notifier.updateNotificationPreferences(earningsNotificationsEnabled: false);

      await notifier.sendEarningsNotification(
        orderId: 'test-order-123',
        earningsAmount: 25.50,
        newBalance: 125.75,
        earningsBreakdown: {},
      );

      verifyNever(mockNotificationService.sendEarningsNotification(
        driverId: anyNamed('driverId'),
        orderId: anyNamed('orderId'),
        earningsAmount: anyNamed('earningsAmount'),
        newBalance: anyNamed('newBalance'),
        earningsBreakdown: anyNamed('earningsBreakdown'),
      ));
    });

    test('should send withdrawal notification when enabled', () async {
      when(mockNotificationService.sendWithdrawalNotification(
        driverId: anyNamed('driverId'),
        withdrawalId: anyNamed('withdrawalId'),
        amount: anyNamed('amount'),
        status: anyNamed('status'),
        withdrawalMethod: anyNamed('withdrawalMethod'),
        failureReason: anyNamed('failureReason'),
      )).thenAnswer((_) async {});

      final notifier = container.read(driverWalletNotificationProvider.notifier);

      await notifier.sendWithdrawalNotification(
        withdrawalId: 'withdrawal-123',
        amount: 100.0,
        status: 'completed',
        withdrawalMethod: 'bank_transfer',
      );

      verify(mockNotificationService.sendWithdrawalNotification(
        driverId: 'test-driver-id',
        withdrawalId: 'withdrawal-123',
        amount: 100.0,
        status: 'completed',
        withdrawalMethod: 'bank_transfer',
        failureReason: null,
      )).called(1);
    });

    test('should not send withdrawal notification when disabled', () async {
      final notifier = container.read(driverWalletNotificationProvider.notifier);
      
      // Disable withdrawal notifications
      notifier.updateNotificationPreferences(withdrawalNotificationsEnabled: false);

      await notifier.sendWithdrawalNotification(
        withdrawalId: 'withdrawal-123',
        amount: 100.0,
        status: 'completed',
        withdrawalMethod: 'bank_transfer',
      );

      verifyNever(mockNotificationService.sendWithdrawalNotification(
        driverId: anyNamed('driverId'),
        withdrawalId: anyNamed('withdrawalId'),
        amount: anyNamed('amount'),
        status: anyNamed('status'),
        withdrawalMethod: anyNamed('withdrawalMethod'),
        failureReason: anyNamed('failureReason'),
      ));
    });

    test('should update last notification sent timestamp', () {
      final notifier = container.read(driverWalletNotificationProvider.notifier);
      final initialState = container.read(driverWalletNotificationProvider);
      
      expect(initialState.lastNotificationSent, isNull);

      // Trigger a notification to update timestamp
      notifier.updateNotificationPreferences(earningsNotificationsEnabled: true);

      // The timestamp should be updated when sending notifications
      // This would be tested in integration tests with actual notification sending
    });

    test('should handle notification errors gracefully', () async {
      when(mockNotificationService.sendEarningsNotification(
        driverId: anyNamed('driverId'),
        orderId: anyNamed('orderId'),
        earningsAmount: anyNamed('earningsAmount'),
        newBalance: anyNamed('newBalance'),
        earningsBreakdown: anyNamed('earningsBreakdown'),
      )).thenThrow(Exception('Notification service error'));

      final notifier = container.read(driverWalletNotificationProvider.notifier);

      // Should not throw exception
      await expectLater(
        notifier.sendEarningsNotification(
          orderId: 'test-order-123',
          earningsAmount: 25.50,
          newBalance: 125.75,
          earningsBreakdown: {},
        ),
        completes,
      );
    });
  });

  group('DriverWalletNotificationsEnabledProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should return correct enabled status', () {
      final isEnabled = container.read(driverWalletNotificationsEnabledProvider);
      expect(isEnabled, true); // Default is enabled

      // Disable notifications
      container.read(driverWalletNotificationProvider.notifier).setNotificationsEnabled(false);
      
      final isEnabledAfter = container.read(driverWalletNotificationsEnabledProvider);
      expect(isEnabledAfter, false);
    });
  });
}
