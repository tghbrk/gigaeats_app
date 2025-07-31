import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/driver_wallet_notification_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/enhanced_driver_wallet_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/repositories/driver_wallet_repository.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/driver_wallet_notification_provider.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/driver_wallet_provider.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/driver_wallet.dart';
import 'package:gigaeats_app/src/features/auth/presentation/providers/auth_provider.dart';
import 'package:gigaeats_app/src/data/models/user_role.dart';
import 'package:gigaeats_app/src/data/models/user.dart';

import 'driver_wallet_realtime_notifications_integration_test.mocks.dart';

@GenerateMocks([
  DriverWalletNotificationService,
  EnhancedDriverWalletService,
  DriverWalletRepository,
])
void main() {
  group('Driver Wallet Real-time Notifications Integration', () {
    late MockDriverWalletNotificationService mockNotificationService;
    late MockEnhancedDriverWalletService mockWalletService;
    late MockDriverWalletRepository mockRepository;
    late ProviderContainer container;

    const testDriverId = 'test-driver-id';
    const testOrderId = 'test-order-123';
    const testWalletId = 'test-wallet-456';

    final testWallet = DriverWallet(
      id: testWalletId,
      userId: testDriverId,
      driverId: testDriverId,
      availableBalance: 100.0,
      pendingBalance: 0.0,
      totalEarned: 500.0,
      totalWithdrawn: 400.0,
      currency: 'MYR',
      isActive: true,
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      mockNotificationService = MockDriverWalletNotificationService();
      mockWalletService = MockEnhancedDriverWalletService();
      mockRepository = MockDriverWalletRepository();

      // Setup default mocks
      when(mockWalletService.getDriverWallet()).thenAnswer((_) async => testWallet);
      when(mockWalletService.getOrCreateDriverWallet()).thenAnswer((_) async => testWallet);
      
      container = ProviderContainer(
        overrides: [
          driverWalletNotificationServiceProvider.overrideWithValue(mockNotificationService),
          enhancedDriverWalletServiceProvider.overrideWithValue(mockWalletService),
          driverWalletRepositoryProvider.overrideWithValue(mockRepository),
          authStateProvider.overrideWith((ref) {
            final notifier = AuthStateNotifier(ref.read(supabaseAuthServiceProvider));
            notifier.state = AuthState(
              status: AuthStatus.authenticated,
              user: User(
                id: testDriverId,
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

    testWidgets('should send earnings notification when processing earnings deposit', (tester) async {
      // Setup mocks
      when(mockWalletService.processEarningsDeposit(
        orderId: anyNamed('orderId'),
        grossEarnings: anyNamed('grossEarnings'),
        netEarnings: anyNamed('netEarnings'),
        earningsBreakdown: anyNamed('earningsBreakdown'),
      )).thenAnswer((_) async {});

      when(mockNotificationService.sendEarningsNotification(
        driverId: anyNamed('driverId'),
        orderId: anyNamed('orderId'),
        earningsAmount: anyNamed('earningsAmount'),
        newBalance: anyNamed('newBalance'),
        earningsBreakdown: anyNamed('earningsBreakdown'),
      )).thenAnswer((_) async {});

      final walletNotifier = container.read(driverWalletProvider.notifier);

      // Process earnings deposit
      await walletNotifier.processEarningsDeposit(
        orderId: testOrderId,
        grossEarnings: 30.0,
        netEarnings: 25.0,
        earningsBreakdown: {
          'base_commission': 20.0,
          'tip': 5.0,
        },
      );

      // Verify earnings deposit was processed
      verify(mockWalletService.processEarningsDeposit(
        orderId: testOrderId,
        grossEarnings: 30.0,
        netEarnings: 25.0,
        earningsBreakdown: {
          'base_commission': 20.0,
          'tip': 5.0,
        },
      )).called(1);

      // Verify earnings notification was sent
      verify(mockNotificationService.sendEarningsNotification(
        driverId: testDriverId,
        orderId: testOrderId,
        earningsAmount: 25.0,
        newBalance: 100.0, // Current wallet balance
        earningsBreakdown: {
          'base_commission': 20.0,
          'tip': 5.0,
        },
      )).called(1);
    });

    testWidgets('should send withdrawal notification when processing withdrawal', (tester) async {
      const withdrawalId = 'withdrawal-789';
      
      // Setup mocks
      when(mockWalletService.processWithdrawalRequest(
        amount: anyNamed('amount'),
        withdrawalMethod: anyNamed('withdrawalMethod'),
        destinationDetails: anyNamed('destinationDetails'),
      )).thenAnswer((_) async => withdrawalId);

      when(mockNotificationService.sendWithdrawalNotification(
        driverId: anyNamed('driverId'),
        withdrawalId: anyNamed('withdrawalId'),
        amount: anyNamed('amount'),
        status: anyNamed('status'),
        withdrawalMethod: anyNamed('withdrawalMethod'),
        failureReason: anyNamed('failureReason'),
      )).thenAnswer((_) async {});

      final walletNotifier = container.read(driverWalletProvider.notifier);

      // Process withdrawal request
      final result = await walletNotifier.processWithdrawalRequest(
        amount: 50.0,
        withdrawalMethod: 'bank_transfer',
        destinationDetails: {
          'bank_name': 'Test Bank',
          'account_number': '1234567890',
        },
      );

      expect(result, withdrawalId);

      // Verify withdrawal request was processed
      verify(mockWalletService.processWithdrawalRequest(
        amount: 50.0,
        withdrawalMethod: 'bank_transfer',
        destinationDetails: {
          'bank_name': 'Test Bank',
          'account_number': '1234567890',
        },
      )).called(1);

      // Verify withdrawal notification was sent
      verify(mockNotificationService.sendWithdrawalNotification(
        driverId: testDriverId,
        withdrawalId: withdrawalId,
        amount: 50.0,
        status: 'processing',
        withdrawalMethod: 'bank_transfer',
        failureReason: null,
      )).called(1);
    });

    testWidgets('should detect low balance and provide alert data', (tester) async {
      // Create wallet with low balance
      final lowBalanceWallet = testWallet.copyWith(availableBalance: 15.0);
      
      when(mockWalletService.getDriverWallet()).thenAnswer((_) async => lowBalanceWallet);

      // Override wallet provider to return low balance wallet
      final walletNotifier = container.read(driverWalletProvider.notifier);
      await walletNotifier.loadWallet();

      // Check low balance alert provider
      final lowBalanceAlert = container.read(driverWalletLowBalanceAlertProvider);

      expect(lowBalanceAlert, isNotNull);
      expect(lowBalanceAlert!['type'], 'low_balance');
      expect(lowBalanceAlert['severity'], 'warning');
      expect(lowBalanceAlert['current_balance'], 15.0);
      expect(lowBalanceAlert['threshold'], 20.0);
    });

    testWidgets('should detect critical low balance', (tester) async {
      // Create wallet with critical low balance
      final criticalLowBalanceWallet = testWallet.copyWith(availableBalance: 3.0);
      
      when(mockWalletService.getDriverWallet()).thenAnswer((_) async => criticalLowBalanceWallet);

      // Override wallet provider to return critical low balance wallet
      final walletNotifier = container.read(driverWalletProvider.notifier);
      await walletNotifier.loadWallet();

      // Check low balance alert provider
      final lowBalanceAlert = container.read(driverWalletLowBalanceAlertProvider);

      expect(lowBalanceAlert, isNotNull);
      expect(lowBalanceAlert!['type'], 'low_balance');
      expect(lowBalanceAlert['severity'], 'critical');
      expect(lowBalanceAlert['current_balance'], 3.0);
      expect(lowBalanceAlert['threshold'], 20.0);
    });

    testWidgets('should not show low balance alert when balance is sufficient', (tester) async {
      // Use default wallet with sufficient balance (100.0)
      final walletNotifier = container.read(driverWalletProvider.notifier);
      await walletNotifier.loadWallet();

      // Check low balance alert provider
      final lowBalanceAlert = container.read(driverWalletLowBalanceAlertProvider);

      expect(lowBalanceAlert, isNull);
    });

    testWidgets('should handle notification errors gracefully during earnings processing', (tester) async {
      // Setup mocks - earnings processing succeeds but notification fails
      when(mockWalletService.processEarningsDeposit(
        orderId: anyNamed('orderId'),
        grossEarnings: anyNamed('grossEarnings'),
        netEarnings: anyNamed('netEarnings'),
        earningsBreakdown: anyNamed('earningsBreakdown'),
      )).thenAnswer((_) async {});

      when(mockNotificationService.sendEarningsNotification(
        driverId: anyNamed('driverId'),
        orderId: anyNamed('orderId'),
        earningsAmount: anyNamed('earningsAmount'),
        newBalance: anyNamed('newBalance'),
        earningsBreakdown: anyNamed('earningsBreakdown'),
      )).thenThrow(Exception('Notification service error'));

      final walletNotifier = container.read(driverWalletProvider.notifier);

      // Should not throw exception even if notification fails
      await expectLater(
        walletNotifier.processEarningsDeposit(
          orderId: testOrderId,
          grossEarnings: 30.0,
          netEarnings: 25.0,
          earningsBreakdown: {},
        ),
        completes,
      );

      // Verify earnings deposit was still processed
      verify(mockWalletService.processEarningsDeposit(
        orderId: testOrderId,
        grossEarnings: 30.0,
        netEarnings: 25.0,
        earningsBreakdown: {},
      )).called(1);
    });

    testWidgets('should respect notification preferences', (tester) async {
      // Disable earnings notifications
      final notificationNotifier = container.read(driverWalletNotificationProvider.notifier);
      notificationNotifier.updateNotificationPreferences(earningsNotificationsEnabled: false);

      // Setup mocks
      when(mockWalletService.processEarningsDeposit(
        orderId: anyNamed('orderId'),
        grossEarnings: anyNamed('grossEarnings'),
        netEarnings: anyNamed('netEarnings'),
        earningsBreakdown: anyNamed('earningsBreakdown'),
      )).thenAnswer((_) async {});

      final walletNotifier = container.read(driverWalletProvider.notifier);

      // Process earnings deposit
      await walletNotifier.processEarningsDeposit(
        orderId: testOrderId,
        grossEarnings: 30.0,
        netEarnings: 25.0,
        earningsBreakdown: {},
      );

      // Verify earnings deposit was processed
      verify(mockWalletService.processEarningsDeposit(
        orderId: testOrderId,
        grossEarnings: 30.0,
        netEarnings: 25.0,
        earningsBreakdown: {},
      )).called(1);

      // Verify NO earnings notification was sent (disabled)
      verifyNever(mockNotificationService.sendEarningsNotification(
        driverId: anyNamed('driverId'),
        orderId: anyNamed('orderId'),
        earningsAmount: anyNamed('earningsAmount'),
        newBalance: anyNamed('newBalance'),
        earningsBreakdown: anyNamed('earningsBreakdown'),
      ));
    });
  });
}
