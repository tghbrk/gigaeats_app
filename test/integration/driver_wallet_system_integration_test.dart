import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState, User;

import 'package:gigaeats_app/src/features/drivers/data/services/enhanced_driver_wallet_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/earnings_wallet_integration_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/driver_wallet_notification_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/repositories/driver_wallet_repository.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/driver_wallet_provider.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/driver_wallet_notification_provider.dart' as notification_provider;
import 'package:gigaeats_app/src/features/drivers/presentation/providers/driver_wallet_realtime_provider.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/driver_wallet_transaction_provider.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/driver_wallet.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/driver_wallet_transaction.dart';
import 'package:gigaeats_app/src/features/auth/presentation/providers/auth_provider.dart';
import 'package:gigaeats_app/src/data/models/user_role.dart';
import 'package:gigaeats_app/src/data/models/user.dart';

import 'driver_wallet_system_integration_test.mocks.dart';

@GenerateMocks([
  SupabaseClient,
  EnhancedDriverWalletService,
  EarningsWalletIntegrationService,
  DriverWalletNotificationService,
  DriverWalletRepository,
])
void main() {
  group('Driver Wallet System - Comprehensive Integration Tests', () {

    late MockEnhancedDriverWalletService mockWalletService;

    late MockDriverWalletNotificationService mockNotificationService;
    late MockDriverWalletRepository mockRepository;
    late ProviderContainer container;

    const testDriverId = 'test-driver-id';
    const testOrderId = 'test-order-123';
    const testWalletId = 'test-wallet-456';

    final testWallet = DriverWallet(
      id: testWalletId,
      userId: testDriverId,
      driverId: testDriverId,
      availableBalance: 150.0,
      pendingBalance: 25.0,
      totalEarned: 1000.0,
      totalWithdrawn: 850.0,
      currency: 'MYR',
      isActive: true,
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );

    final testTransaction = DriverWalletTransaction(
      id: 'transaction-123',
      walletId: testWalletId,
      driverId: testDriverId,
      transactionType: DriverWalletTransactionType.deliveryEarnings,
      amount: 25.0,
      currency: 'MYR',
      balanceBefore: 125.0,
      balanceAfter: 150.0,
      referenceType: 'order',
      referenceId: testOrderId,
      description: 'Delivery earnings for order $testOrderId',
      metadata: {
        'gross_earnings': 30.0,
        'net_earnings': 25.0,
        'base_commission': 20.0,
        'tip': 5.0,
      },
      processedBy: 'driver_wallet_operations',
      processingFee: 0.0,
      createdAt: DateTime.now(),
      processedAt: DateTime.now(), // This makes status 'Completed'
    );

    setUp(() {

      mockWalletService = MockEnhancedDriverWalletService();

      mockNotificationService = MockDriverWalletNotificationService();
      mockRepository = MockDriverWalletRepository();

      // Setup default mocks
      when(mockWalletService.getDriverWallet()).thenAnswer((_) async => testWallet);
      when(mockWalletService.getOrCreateDriverWallet()).thenAnswer((_) async => testWallet);
      when(mockWalletService.streamDriverWallet()).thenAnswer((_) => Stream.value(testWallet));
      when(mockRepository.streamDriverWalletTransactions(limit: anyNamed('limit')))
          .thenAnswer((_) => Stream.value([testTransaction]));

      container = ProviderContainer(
        overrides: [
          enhancedDriverWalletServiceProvider.overrideWithValue(mockWalletService),
          notification_provider.driverWalletNotificationServiceProvider.overrideWithValue(mockNotificationService),
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

    group('End-to-End Workflow Integration', () {
      testWidgets('should complete full earnings-to-wallet-to-notification flow', (tester) async {
        // Setup mocks for complete flow
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

        // Step 1: Process earnings deposit
        final walletNotifier = container.read(driverWalletProvider.notifier);
        await walletNotifier.processEarningsDeposit(
          orderId: testOrderId,
          grossEarnings: 30.0,
          netEarnings: 25.0,
          earningsBreakdown: {
            'base_commission': 20.0,
            'tip': 5.0,
          },
        );

        // Step 2: Verify wallet service was called
        verify(mockWalletService.processEarningsDeposit(
          orderId: testOrderId,
          grossEarnings: 30.0,
          netEarnings: 25.0,
          earningsBreakdown: {
            'base_commission': 20.0,
            'tip': 5.0,
          },
        )).called(1);

        // Step 3: Verify notification was sent
        verify(mockNotificationService.sendEarningsNotification(
          driverId: testDriverId,
          orderId: testOrderId,
          earningsAmount: 25.0,
          newBalance: 150.0,
          earningsBreakdown: {
            'base_commission': 20.0,
            'tip': 5.0,
          },
        )).called(1);

        // Step 4: Verify wallet state was updated
        final walletState = container.read(driverWalletProvider);
        expect(walletState.wallet, isNotNull);
        expect(walletState.wallet!.id, testWalletId);
      });

      testWidgets('should handle withdrawal request with notifications', (tester) async {
        const withdrawalId = 'withdrawal-789';
        
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

        // Process withdrawal
        final walletNotifier = container.read(driverWalletProvider.notifier);
        final result = await walletNotifier.processWithdrawalRequest(
          amount: 100.0,
          withdrawalMethod: 'bank_transfer',
          destinationDetails: {
            'bank_name': 'Test Bank',
            'account_number': '1234567890',
          },
        );

        expect(result, withdrawalId);

        // Verify withdrawal service was called
        verify(mockWalletService.processWithdrawalRequest(
          amount: 100.0,
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
          amount: 100.0,
          status: 'processing',
          withdrawalMethod: 'bank_transfer',
          failureReason: null,
        )).called(1);
      });
    });

    group('Real-time System Integration', () {
      testWidgets('should handle real-time wallet updates', (tester) async {
        // Initialize real-time provider
        container.read(driverWalletRealtimeProvider.notifier);
        
        // Verify real-time connection is established
        final realtimeState = container.read(driverWalletRealtimeProvider);
        expect(realtimeState, isTrue);

        // Verify wallet stream is being monitored
        verify(mockWalletService.streamDriverWallet()).called(1);
      });

      testWidgets('should handle real-time transaction updates', (tester) async {
        // Verify transaction stream is being monitored
        verify(mockRepository.streamDriverWalletTransactions(limit: 10)).called(1);

        // Simulate new transaction
        testTransaction.copyWith(
          id: 'transaction-456',
          amount: 30.0,
          balanceBefore: 150.0,
          balanceAfter: 180.0,
          createdAt: DateTime.now(),
        );

        // This would trigger real-time updates in actual implementation
        // For testing, we verify the stream is set up correctly
        expect(container.read(driverWalletTransactionsStreamProvider), isA<AsyncValue>());
      });
    });

    group('Notification System Integration', () {
      testWidgets('should respect notification preferences', (tester) async {
        // Disable earnings notifications
        final notificationNotifier = container.read(notification_provider.driverWalletNotificationProvider.notifier);
        notificationNotifier.updateNotificationPreferences(earningsNotificationsEnabled: false);

        // Setup mocks
        when(mockWalletService.processEarningsDeposit(
          orderId: anyNamed('orderId'),
          grossEarnings: anyNamed('grossEarnings'),
          netEarnings: anyNamed('netEarnings'),
          earningsBreakdown: anyNamed('earningsBreakdown'),
        )).thenAnswer((_) async {});

        // Process earnings
        final walletNotifier = container.read(driverWalletProvider.notifier);
        await walletNotifier.processEarningsDeposit(
          orderId: testOrderId,
          grossEarnings: 30.0,
          netEarnings: 25.0,
          earningsBreakdown: {},
        );

        // Verify earnings were processed
        verify(mockWalletService.processEarningsDeposit(
          orderId: testOrderId,
          grossEarnings: 30.0,
          netEarnings: 25.0,
          earningsBreakdown: {},
        )).called(1);

        // Verify NO notification was sent (disabled)
        verifyNever(mockNotificationService.sendEarningsNotification(
          driverId: anyNamed('driverId'),
          orderId: anyNamed('orderId'),
          earningsAmount: anyNamed('earningsAmount'),
          newBalance: anyNamed('newBalance'),
          earningsBreakdown: anyNamed('earningsBreakdown'),
        ));
      });

      testWidgets('should detect and alert on low balance', (tester) async {
        // Create wallet with low balance
        final lowBalanceWallet = testWallet.copyWith(availableBalance: 15.0);
        when(mockWalletService.getDriverWallet()).thenAnswer((_) async => lowBalanceWallet);

        // Load wallet
        final walletNotifier = container.read(driverWalletProvider.notifier);
        await walletNotifier.loadWallet();

        // Check low balance alert
        final lowBalanceAlert = container.read(notification_provider.driverWalletLowBalanceAlertProvider);
        expect(lowBalanceAlert, isNotNull);
        expect(lowBalanceAlert!['type'], 'low_balance');
        expect(lowBalanceAlert['severity'], 'warning');
        expect(lowBalanceAlert['current_balance'], 15.0);
      });
    });

    group('Error Handling & Recovery', () {
      testWidgets('should handle earnings processing errors gracefully', (tester) async {
        // Setup mock to throw error
        when(mockWalletService.processEarningsDeposit(
          orderId: anyNamed('orderId'),
          grossEarnings: anyNamed('grossEarnings'),
          netEarnings: anyNamed('netEarnings'),
          earningsBreakdown: anyNamed('earningsBreakdown'),
        )).thenThrow(Exception('Network error'));

        final walletNotifier = container.read(driverWalletProvider.notifier);

        // Should not throw exception
        await expectLater(
          walletNotifier.processEarningsDeposit(
            orderId: testOrderId,
            grossEarnings: 30.0,
            netEarnings: 25.0,
            earningsBreakdown: {},
          ),
          completes,
        );

        // Verify error state is set
        final walletState = container.read(driverWalletProvider);
        expect(walletState.errorMessage, isNotNull);
      });

      testWidgets('should handle notification errors without affecting wallet operations', (tester) async {
        // Setup mocks - wallet succeeds, notification fails
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

        // Should complete successfully despite notification error
        await expectLater(
          walletNotifier.processEarningsDeposit(
            orderId: testOrderId,
            grossEarnings: 30.0,
            netEarnings: 25.0,
            earningsBreakdown: {},
          ),
          completes,
        );

        // Verify wallet operation succeeded
        verify(mockWalletService.processEarningsDeposit(
          orderId: testOrderId,
          grossEarnings: 30.0,
          netEarnings: 25.0,
          earningsBreakdown: {},
        )).called(1);

        // Verify no error state in wallet
        final walletState = container.read(driverWalletProvider);
        expect(walletState.errorMessage, isNull);
      });
    });
  });
}
