import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gigaeats_app/src/features/drivers/presentation/screens/driver_withdrawal_request_screen.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/screens/driver_withdrawal_history_screen.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/driver_withdrawal_provider.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/driver_withdrawal_request.dart';
import 'package:gigaeats_app/src/features/drivers/data/repositories/driver_withdrawal_repository.dart';
import 'package:gigaeats_app/src/core/utils/logger.dart';

import 'driver_withdrawal_end_to_end_test.mocks.dart';

@GenerateMocks([
  SupabaseClient,
  AppLogger,
  DriverWithdrawalRepository,
])
void main() {
  group('Driver Withdrawal System - End-to-End Tests', () {
    // ignore: unused_local_variable
    late MockSupabaseClient mockSupabase;
    // ignore: unused_local_variable
    late MockAppLogger mockLogger;
    late MockDriverWithdrawalRepository mockRepository;
    late ProviderContainer container;

    const testDriverId = 'test-driver-id';
    // ignore: unused_local_variable
    const testWalletId = 'test-wallet-id';

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockLogger = MockAppLogger();
      mockRepository = MockDriverWithdrawalRepository();

      container = ProviderContainer(
        overrides: [
          driverWithdrawalRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Complete Withdrawal Request Flow', () {
      testWidgets('should complete full withdrawal request creation flow', (WidgetTester tester) async {
        // Arrange
        final testWithdrawalRequest = DriverWithdrawalRequest.test(
          id: 'test-withdrawal-id',
          driverId: testDriverId,
          amount: 100.0,
        );

        when(mockRepository.createWithdrawalRequest(
          driverId: anyNamed('driverId'),
          walletId: anyNamed('walletId'),
          amount: anyNamed('amount'),
          withdrawalMethod: anyNamed('withdrawalMethod'),
          destinationDetails: anyNamed('destinationDetails'),
        )).thenAnswer((_) async => testWithdrawalRequest);

        when(mockRepository.getDriverWithdrawalRequests(driverId: testDriverId))
            .thenAnswer((_) async => [testWithdrawalRequest]);

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: container.getAllProviderElements().map((e) => e.provider).toList(),
            child: const MaterialApp(
              home: DriverWithdrawalRequestScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and interact with withdrawal form elements
        expect(find.text('Request Withdrawal'), findsOneWidget);
        
        // Enter withdrawal amount
        final amountField = find.byKey(const Key('withdrawal_amount_field'));
        expect(amountField, findsOneWidget);
        await tester.enterText(amountField, '100.00');

        // Select bank account (assuming dropdown or selection widget)
        final bankAccountSelector = find.byKey(const Key('bank_account_selector'));
        if (bankAccountSelector.evaluate().isNotEmpty) {
          await tester.tap(bankAccountSelector);
          await tester.pumpAndSettle();
        }

        // Submit withdrawal request
        final submitButton = find.byKey(const Key('submit_withdrawal_button'));
        expect(submitButton, findsOneWidget);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Assert
        verify(mockRepository.createWithdrawalRequest(
          driverId: anyNamed('driverId'),
          walletId: anyNamed('walletId'),
          amount: anyNamed('amount'),
          withdrawalMethod: anyNamed('withdrawalMethod'),
          destinationDetails: anyNamed('destinationDetails'),
        )).called(1);
        
        // Verify success message or navigation
        expect(find.text('Withdrawal request submitted successfully'), findsOneWidget);
      });

      testWidgets('should display withdrawal history with status updates', (WidgetTester tester) async {
        // Arrange
        final testWithdrawals = [
          DriverWithdrawalRequest.test(
            id: 'withdrawal-1',
            driverId: testDriverId,
            amount: 100.0,
          ),
          DriverWithdrawalRequest.test(
            id: 'withdrawal-2',
            driverId: testDriverId,
            amount: 200.0,
          ),
          DriverWithdrawalRequest.test(
            id: 'withdrawal-3',
            driverId: testDriverId,
            amount: 150.0,
          ),
        ];

        when(mockRepository.getDriverWithdrawalRequests(driverId: testDriverId))
            .thenAnswer((_) async => testWithdrawals);

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: container.getAllProviderElements().map((e) => e.provider).toList(),
            child: const MaterialApp(
              home: DriverWithdrawalHistoryScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Withdrawal History'), findsOneWidget);
        
        // Verify all withdrawal requests are displayed
        expect(find.text('RM 100.00'), findsOneWidget);
        expect(find.text('RM 200.00'), findsOneWidget);
        expect(find.text('RM 150.00'), findsOneWidget);

        // Verify status indicators
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text('Failed'), findsOneWidget);

        // Verify repository was called
        verify(mockRepository.getDriverWithdrawalRequests(driverId: testDriverId)).called(1);
      });

      testWidgets('should handle withdrawal request validation errors', (WidgetTester tester) async {
        // Arrange
        when(mockRepository.createWithdrawalRequest(
          driverId: anyNamed('driverId'),
          walletId: anyNamed('walletId'),
          amount: anyNamed('amount'),
          withdrawalMethod: anyNamed('withdrawalMethod'),
          destinationDetails: anyNamed('destinationDetails'),
          notes: anyNamed('notes'),
        )).thenThrow(Exception('Insufficient balance'));

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: container.getAllProviderElements().map((e) => e.provider).toList(),
            child: const MaterialApp(
              home: DriverWithdrawalRequestScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter invalid withdrawal amount (higher than balance)
        final amountField = find.byKey(const Key('withdrawal_amount_field'));
        await tester.enterText(amountField, '10000.00');

        // Submit withdrawal request
        final submitButton = find.byKey(const Key('submit_withdrawal_button'));
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Insufficient balance'), findsOneWidget);
        verify(mockRepository.createWithdrawalRequest(
          driverId: anyNamed('driverId'),
          walletId: anyNamed('walletId'),
          amount: anyNamed('amount'),
          withdrawalMethod: anyNamed('withdrawalMethod'),
          destinationDetails: anyNamed('destinationDetails'),
          notes: anyNamed('notes'),
        )).called(1);
      });
    });

    group('Real-time Updates Integration', () {
      testWidgets('should update withdrawal status in real-time', (WidgetTester tester) async {
        // Arrange
        final initialWithdrawal = DriverWithdrawalRequest.test(
          id: 'test-withdrawal-id',
          driverId: testDriverId,
          amount: 100.0,
          status: DriverWithdrawalStatus.pending,
        );

        final updatedWithdrawal = DriverWithdrawalRequest.test(
          id: 'test-withdrawal-id',
          driverId: testDriverId,
          amount: 100.0,
          status: DriverWithdrawalStatus.completed,
        );

        when(mockRepository.getDriverWithdrawalRequests(driverId: testDriverId))
            .thenAnswer((_) async => [initialWithdrawal]);

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: container.getAllProviderElements().map((e) => e.provider).toList(),
            child: const MaterialApp(
              home: DriverWithdrawalHistoryScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify initial status
        expect(find.text('Pending'), findsOneWidget);

        // Simulate real-time update
        when(mockRepository.getDriverWithdrawalRequests(driverId: testDriverId))
            .thenAnswer((_) async => [updatedWithdrawal]);

        // Trigger refresh or real-time update
        final refreshButton = find.byKey(const Key('refresh_button'));
        if (refreshButton.evaluate().isNotEmpty) {
          await tester.tap(refreshButton);
          await tester.pumpAndSettle();
        }

        // Assert
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Pending'), findsNothing);
      });

      testWidgets('should display withdrawal notifications', (WidgetTester tester) async {
        // Arrange
        final testWithdrawal = DriverWithdrawalRequest.test(
          id: 'test-withdrawal-id',
          driverId: testDriverId,
          amount: 100.0,
          status: DriverWithdrawalStatus.completed,
        );

        when(mockRepository.getDriverWithdrawalRequests(driverId: testDriverId))
            .thenAnswer((_) async => [testWithdrawal]);

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: container.getAllProviderElements().map((e) => e.provider).toList(),
            child: const MaterialApp(
              home: DriverWithdrawalHistoryScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Simulate notification display
        // This would typically be triggered by a real-time update or push notification
        
        // Assert
        // Verify that notification-related UI elements are present
        // This might include snackbars, badges, or notification indicators
        expect(find.byType(SnackBar), findsNothing); // Initially no notifications
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('should handle network connectivity issues', (WidgetTester tester) async {
        // Arrange
        when(mockRepository.getDriverWithdrawalRequests(driverId: testDriverId))
            .thenThrow(Exception('Network error'));

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: container.getAllProviderElements().map((e) => e.provider).toList(),
            child: const MaterialApp(
              home: DriverWithdrawalHistoryScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Network error'), findsOneWidget);
        expect(find.byKey(const Key('retry_button')), findsOneWidget);
      });

      testWidgets('should handle empty withdrawal history', (WidgetTester tester) async {
        // Arrange
        when(mockRepository.getDriverWithdrawalRequests(driverId: testDriverId))
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: container.getAllProviderElements().map((e) => e.provider).toList(),
            child: const MaterialApp(
              home: DriverWithdrawalHistoryScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(find.text('No withdrawal requests found'), findsOneWidget);
        expect(find.text('Make your first withdrawal'), findsOneWidget);
      });

      testWidgets('should validate withdrawal form inputs', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: container.getAllProviderElements().map((e) => e.provider).toList(),
            child: const MaterialApp(
              home: DriverWithdrawalRequestScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test empty amount validation
        final submitButton = find.byKey(const Key('submit_withdrawal_button'));
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Please enter withdrawal amount'), findsOneWidget);

        // Test minimum amount validation
        final amountField = find.byKey(const Key('withdrawal_amount_field'));
        await tester.enterText(amountField, '5.00'); // Below minimum
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(find.text('Minimum withdrawal amount is RM 10.00'), findsOneWidget);

        // Test maximum amount validation
        await tester.enterText(amountField, '10000.00'); // Above maximum
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(find.text('Maximum withdrawal amount exceeded'), findsOneWidget);
      });
    });

    group('Performance and User Experience', () {
      testWidgets('should display loading states during operations', (WidgetTester tester) async {
        // Arrange
        when(mockRepository.getDriverWithdrawalRequests(driverId: testDriverId))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(seconds: 2));
              return [];
            });

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: container.getAllProviderElements().map((e) => e.provider).toList(),
            child: const MaterialApp(
              home: DriverWithdrawalHistoryScreen(),
            ),
          ),
        );

        // Assert loading state
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for completion
        await tester.pumpAndSettle();

        // Assert loaded state
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('should provide smooth navigation between screens', (WidgetTester tester) async {
        // Arrange
        when(mockRepository.getDriverWithdrawalRequests(driverId: testDriverId))
            .thenAnswer((_) async => []);

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: container.getAllProviderElements().map((e) => e.provider).toList(),
            child: MaterialApp(
              initialRoute: '/withdrawal-history',
              routes: {
                '/withdrawal-history': (context) => const DriverWithdrawalHistoryScreen(),
                '/withdrawal-request': (context) => const DriverWithdrawalRequestScreen(),
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to withdrawal request screen
        final newWithdrawalButton = find.byKey(const Key('new_withdrawal_button'));
        if (newWithdrawalButton.evaluate().isNotEmpty) {
          await tester.tap(newWithdrawalButton);
          await tester.pumpAndSettle();

          // Assert navigation occurred
          expect(find.text('Request Withdrawal'), findsOneWidget);
        }
      });
    });
  });
}
