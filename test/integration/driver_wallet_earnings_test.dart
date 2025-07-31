import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:gigaeats_app/src/features/drivers/data/services/enhanced_driver_wallet_service.dart';
import 'package:gigaeats_app/src/features/drivers/data/services/earnings_wallet_integration_service.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/driver_wallet_provider.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/driver_wallet.dart';
import 'package:gigaeats_app/src/features/auth/presentation/providers/auth_provider.dart';
import 'package:gigaeats_app/src/data/models/user_role.dart';
import 'package:gigaeats_app/src/data/models/user.dart';

import 'driver_wallet_earnings_test.mocks.dart';

@GenerateMocks([
  EnhancedDriverWalletService,
  EarningsWalletIntegrationService,
])
void main() {
  group('Driver Wallet Earnings Integration Tests', () {
    late MockEnhancedDriverWalletService mockWalletService;

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
      mockWalletService = MockEnhancedDriverWalletService();


      // Setup default mocks
      when(mockWalletService.getDriverWallet()).thenAnswer((_) async => testWallet);
      when(mockWalletService.getOrCreateDriverWallet()).thenAnswer((_) async => testWallet);

      container = ProviderContainer(
        overrides: [
          enhancedDriverWalletServiceProvider.overrideWithValue(mockWalletService),
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

    group('Earnings Processing Flow', () {
      testWidgets('should process earnings deposit successfully', (tester) async {
        // Setup mock for successful earnings processing
        when(mockWalletService.processEarningsDeposit(
          orderId: anyNamed('orderId'),
          grossEarnings: anyNamed('grossEarnings'),
          netEarnings: anyNamed('netEarnings'),
          earningsBreakdown: anyNamed('earningsBreakdown'),
        )).thenAnswer((_) async {});

        // Updated wallet after earnings deposit
        final updatedWallet = testWallet.copyWith(
          availableBalance: 125.0,
          totalEarned: 525.0,
        );
        when(mockWalletService.getDriverWallet()).thenAnswer((_) async => updatedWallet);

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

        // Verify wallet was refreshed
        verify(mockWalletService.getDriverWallet()).called(greaterThan(0));

        // Verify wallet state was updated
        final walletState = container.read(driverWalletProvider);
        expect(walletState.wallet, isNotNull);
        expect(walletState.isLoading, false);
        expect(walletState.errorMessage, isNull);
      });

      testWidgets('should handle multiple earnings deposits', (tester) async {
        // Setup mock for multiple earnings processing
        when(mockWalletService.processEarningsDeposit(
          orderId: anyNamed('orderId'),
          grossEarnings: anyNamed('grossEarnings'),
          netEarnings: anyNamed('netEarnings'),
          earningsBreakdown: anyNamed('earningsBreakdown'),
        )).thenAnswer((_) async {});

        final walletNotifier = container.read(driverWalletProvider.notifier);

        // Process multiple earnings deposits
        final orders = ['order-1', 'order-2', 'order-3'];
        for (final orderId in orders) {
          await walletNotifier.processEarningsDeposit(
            orderId: orderId,
            grossEarnings: 25.0,
            netEarnings: 20.0,
            earningsBreakdown: {
              'base_commission': 18.0,
              'tip': 2.0,
            },
          );
        }

        // Verify all earnings deposits were processed
        verify(mockWalletService.processEarningsDeposit(
          orderId: anyNamed('orderId'),
          grossEarnings: 25.0,
          netEarnings: 20.0,
          earningsBreakdown: {
            'base_commission': 18.0,
            'tip': 2.0,
          },
        )).called(3);
      });

      testWidgets('should handle earnings processing errors', (tester) async {
        // Setup mock to throw error
        when(mockWalletService.processEarningsDeposit(
          orderId: anyNamed('orderId'),
          grossEarnings: anyNamed('grossEarnings'),
          netEarnings: anyNamed('netEarnings'),
          earningsBreakdown: anyNamed('earningsBreakdown'),
        )).thenThrow(Exception('Network error'));

        final walletNotifier = container.read(driverWalletProvider.notifier);

        // Process earnings deposit (should not throw)
        await walletNotifier.processEarningsDeposit(
          orderId: testOrderId,
          grossEarnings: 30.0,
          netEarnings: 25.0,
          earningsBreakdown: {},
        );

        // Verify error state is set
        final walletState = container.read(driverWalletProvider);
        expect(walletState.errorMessage, isNotNull);
        expect(walletState.errorMessage, contains('Network error'));
      });

      testWidgets('should validate earnings data before processing', (tester) async {
        final walletNotifier = container.read(driverWalletProvider.notifier);

        // Test with zero earnings
        await walletNotifier.processEarningsDeposit(
          orderId: testOrderId,
          grossEarnings: 0.0,
          netEarnings: 0.0,
          earningsBreakdown: {},
        );

        // Should not call service for zero earnings
        verifyNever(mockWalletService.processEarningsDeposit(
          orderId: anyNamed('orderId'),
          grossEarnings: anyNamed('grossEarnings'),
          netEarnings: anyNamed('netEarnings'),
          earningsBreakdown: anyNamed('earningsBreakdown'),
        ));

        // Test with negative earnings
        await walletNotifier.processEarningsDeposit(
          orderId: testOrderId,
          grossEarnings: -10.0,
          netEarnings: -5.0,
          earningsBreakdown: {},
        );

        // Should not call service for negative earnings
        verifyNever(mockWalletService.processEarningsDeposit(
          orderId: anyNamed('orderId'),
          grossEarnings: anyNamed('grossEarnings'),
          netEarnings: anyNamed('netEarnings'),
          earningsBreakdown: anyNamed('earningsBreakdown'),
        ));
      });
    });

    group('Earnings Breakdown Processing', () {
      testWidgets('should handle complex earnings breakdown', (tester) async {
        when(mockWalletService.processEarningsDeposit(
          orderId: anyNamed('orderId'),
          grossEarnings: anyNamed('grossEarnings'),
          netEarnings: anyNamed('netEarnings'),
          earningsBreakdown: anyNamed('earningsBreakdown'),
        )).thenAnswer((_) async {});

        final walletNotifier = container.read(driverWalletProvider.notifier);

        // Process earnings with complex breakdown
        await walletNotifier.processEarningsDeposit(
          orderId: testOrderId,
          grossEarnings: 50.0,
          netEarnings: 42.50,
          earningsBreakdown: {
            'base_commission': 35.0,
            'distance_bonus': 5.0,
            'peak_hour_bonus': 10.0,
            'customer_tip': 8.0,
            'platform_fee': -7.50,
            'service_charge': -5.0,
            'tax_deduction': -3.0,
          },
        );

        // Verify complex breakdown was processed
        verify(mockWalletService.processEarningsDeposit(
          orderId: testOrderId,
          grossEarnings: 50.0,
          netEarnings: 42.50,
          earningsBreakdown: {
            'base_commission': 35.0,
            'distance_bonus': 5.0,
            'peak_hour_bonus': 10.0,
            'customer_tip': 8.0,
            'platform_fee': -7.50,
            'service_charge': -5.0,
            'tax_deduction': -3.0,
          },
        )).called(1);
      });

      testWidgets('should handle missing earnings breakdown gracefully', (tester) async {
        when(mockWalletService.processEarningsDeposit(
          orderId: anyNamed('orderId'),
          grossEarnings: anyNamed('grossEarnings'),
          netEarnings: anyNamed('netEarnings'),
          earningsBreakdown: anyNamed('earningsBreakdown'),
        )).thenAnswer((_) async {});

        final walletNotifier = container.read(driverWalletProvider.notifier);

        // Process earnings with empty breakdown
        await walletNotifier.processEarningsDeposit(
          orderId: testOrderId,
          grossEarnings: 25.0,
          netEarnings: 20.0,
          earningsBreakdown: {}, // Empty breakdown
        );

        // Should still process successfully
        verify(mockWalletService.processEarningsDeposit(
          orderId: testOrderId,
          grossEarnings: 25.0,
          netEarnings: 20.0,
          earningsBreakdown: {},
        )).called(1);
      });
    });

    group('Wallet State Management', () {
      testWidgets('should update wallet state after earnings processing', (tester) async {
        when(mockWalletService.processEarningsDeposit(
          orderId: anyNamed('orderId'),
          grossEarnings: anyNamed('grossEarnings'),
          netEarnings: anyNamed('netEarnings'),
          earningsBreakdown: anyNamed('earningsBreakdown'),
        )).thenAnswer((_) async {});

        // Mock updated wallet after earnings
        final updatedWallet = testWallet.copyWith(
          availableBalance: 150.0,
          totalEarned: 550.0,
          updatedAt: DateTime.now(),
        );
        when(mockWalletService.getDriverWallet()).thenAnswer((_) async => updatedWallet);

        final walletNotifier = container.read(driverWalletProvider.notifier);

        // Initial state check
        final initialState = container.read(driverWalletProvider);
        expect(initialState.wallet, isNull);

        // Load wallet first
        await walletNotifier.loadWallet();

        // Process earnings
        await walletNotifier.processEarningsDeposit(
          orderId: testOrderId,
          grossEarnings: 30.0,
          netEarnings: 25.0,
          earningsBreakdown: {
            'base_commission': 20.0,
            'tip': 5.0,
          },
        );

        // Verify final state
        final finalState = container.read(driverWalletProvider);
        expect(finalState.wallet, isNotNull);
        expect(finalState.wallet!.availableBalance, 150.0);
        expect(finalState.wallet!.totalEarned, 550.0);
        expect(finalState.isLoading, false);
        expect(finalState.errorMessage, isNull);
      });

      testWidgets('should maintain loading state during earnings processing', (tester) async {
        // Create a completer to control when the mock completes
        final completer = Completer<void>();
        
        when(mockWalletService.processEarningsDeposit(
          orderId: anyNamed('orderId'),
          grossEarnings: anyNamed('grossEarnings'),
          netEarnings: anyNamed('netEarnings'),
          earningsBreakdown: anyNamed('earningsBreakdown'),
        )).thenAnswer((_) => completer.future);

        final walletNotifier = container.read(driverWalletProvider.notifier);

        // Start earnings processing (don't await)
        final processingFuture = walletNotifier.processEarningsDeposit(
          orderId: testOrderId,
          grossEarnings: 30.0,
          netEarnings: 25.0,
          earningsBreakdown: {},
        );

        // Check loading state
        await tester.pump();
        final loadingState = container.read(driverWalletProvider);
        expect(loadingState.isLoading, true);

        // Complete the processing
        completer.complete();
        await processingFuture;

        // Check final state
        await tester.pump();
        final finalState = container.read(driverWalletProvider);
        expect(finalState.isLoading, false);
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle rapid earnings processing', (tester) async {
        when(mockWalletService.processEarningsDeposit(
          orderId: anyNamed('orderId'),
          grossEarnings: anyNamed('grossEarnings'),
          netEarnings: anyNamed('netEarnings'),
          earningsBreakdown: anyNamed('earningsBreakdown'),
        )).thenAnswer((_) async {});

        final walletNotifier = container.read(driverWalletProvider.notifier);
        final stopwatch = Stopwatch()..start();

        // Process 10 earnings rapidly
        final futures = List.generate(10, (index) =>
          walletNotifier.processEarningsDeposit(
            orderId: 'order-$index',
            grossEarnings: 25.0,
            netEarnings: 20.0,
            earningsBreakdown: {
              'base_commission': 18.0,
              'tip': 2.0,
            },
          )
        );

        await Future.wait(futures);
        stopwatch.stop();

        // Should complete within reasonable time (5 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));

        // Verify all were processed
        verify(mockWalletService.processEarningsDeposit(
          orderId: anyNamed('orderId'),
          grossEarnings: 25.0,
          netEarnings: 20.0,
          earningsBreakdown: {
            'base_commission': 18.0,
            'tip': 2.0,
          },
        )).called(10);
      });
    });
  });
}
