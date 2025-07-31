import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gigaeats_app/src/core/utils/logger.dart';
import 'package:gigaeats_app/src/features/drivers/data/models/driver_withdrawal_request.dart';
import 'package:gigaeats_app/src/features/drivers/data/repositories/driver_withdrawal_repository.dart';
import 'package:gigaeats_app/src/features/drivers/presentation/providers/driver_withdrawal_provider.dart';
import 'package:gigaeats_app/src/features/drivers/security/driver_withdrawal_security_integration_service.dart';
import 'package:gigaeats_app/src/features/drivers/security/models/withdrawal_compliance_models.dart' as driver_compliance;
import 'package:gigaeats_app/src/features/marketplace_wallet/security/malaysian_compliance_service.dart';
import 'package:gigaeats_app/src/features/marketplace_wallet/security/pci_dss_compliance_service.dart' as marketplace_compliance;
import 'package:gigaeats_app/src/features/marketplace_wallet/security/financial_security_service.dart';

import 'driver_bank_withdrawal_system_integration_test.mocks.dart';

@GenerateMocks([
  SupabaseClient,
  AppLogger,
  MalaysianComplianceService,
  marketplace_compliance.PCIDSSComplianceService,
  FinancialSecurityService,
  DriverWithdrawalRepository,
])
void main() {
  group('Driver Bank Withdrawal System - Comprehensive Integration Tests', () {
    late MockSupabaseClient mockSupabase;
    late MockAppLogger mockLogger;
    late MockMalaysianComplianceService mockMalaysianCompliance;
    late MockPCIDSSComplianceService mockPciCompliance;
    late MockFinancialSecurityService mockFinancialSecurity;
    late MockDriverWithdrawalRepository mockRepository;
    late DriverWithdrawalSecurityIntegrationService securityService;
    late ProviderContainer container;

    const testDriverId = 'test-driver-id';

    const testWithdrawalRequestId = 'test-withdrawal-request-id';

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockLogger = MockAppLogger();
      mockMalaysianCompliance = MockMalaysianComplianceService();
      mockPciCompliance = MockPCIDSSComplianceService();
      mockFinancialSecurity = MockFinancialSecurityService();
      mockRepository = MockDriverWithdrawalRepository();

      securityService = DriverWithdrawalSecurityIntegrationService(
        supabase: mockSupabase,
        logger: mockLogger,
        malaysianCompliance: mockMalaysianCompliance,
        pciCompliance: mockPciCompliance,
        financialSecurity: mockFinancialSecurity,
      );

      container = ProviderContainer(
        overrides: [
          driverWithdrawalRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('End-to-End Withdrawal Flow Integration', () {
      test('should complete full withdrawal request flow with security validation', () async {
        // Arrange
        const amount = 100.0;
        const withdrawalMethod = 'bank_transfer';
        final bankDetails = {
          'account_number': '1234567890',
          'bank_name': 'Test Bank',
          'account_holder_name': 'Test Driver',
          'bank_code': 'MBB',
        };

        // Mock PCI compliance result
        when(mockPciCompliance.validatePaymentDataHandling(
          operation: anyNamed('operation'),
          paymentData: anyNamed('paymentData'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => marketplace_compliance.PCIComplianceResult(
          status: marketplace_compliance.PCIComplianceStatus.compliant,
          violations: [],
          warnings: [],
          timestamp: DateTime.now(),
        ));

        // Mock repository responses
        when(mockRepository.createWithdrawalRequest(
          driverId: anyNamed('driverId'),
          walletId: anyNamed('walletId'),
          amount: anyNamed('amount'),
          withdrawalMethod: anyNamed('withdrawalMethod'),
          destinationDetails: anyNamed('destinationDetails'),
        )).thenAnswer((_) async => DriverWithdrawalRequest.test(
          id: testWithdrawalRequestId,
          driverId: testDriverId,
          amount: amount,
        ));

        when(mockRepository.getDriverWithdrawalRequests(driverId: testDriverId))
            .thenAnswer((_) async => [
              DriverWithdrawalRequest.test(
                id: testWithdrawalRequestId,
                driverId: testDriverId,
                amount: amount,
              ),
            ]);

        // Act
        final securityResult = await securityService.processSecureWithdrawalRequest(
          driverId: testDriverId,
          amount: amount,
          withdrawalMethod: withdrawalMethod,
          bankDetails: bankDetails,
        );

        // Assert
        expect(securityResult.withdrawalRequestId, isNotEmpty);
        expect(securityResult.complianceResult.status, driver_compliance.WithdrawalComplianceStatus.approved);
        expect(securityResult.encryptedBankDetails, isNotEmpty);
        expect(securityResult.securityAuditComplete, isTrue);

        // Verify security validation was performed
        verify(mockPciCompliance.validatePaymentDataHandling(
          operation: 'bank_withdrawal',
          paymentData: bankDetails,
          userId: testDriverId,
        )).called(1);
      });

      test('should handle withdrawal request with fraud detection', () async {
        // Arrange
        const amount = 2000.0; // High amount to trigger fraud detection
        const withdrawalMethod = 'bank_transfer';
        final bankDetails = {
          'account_number': '1234567890',
          'bank_name': 'Test Bank',
          'account_holder_name': 'Test Driver',
          'bank_code': 'MBB',
        };

        // Mock PCI compliance result
        when(mockPciCompliance.validatePaymentDataHandling(
          operation: anyNamed('operation'),
          paymentData: anyNamed('paymentData'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => marketplace_compliance.PCIComplianceResult(
          status: marketplace_compliance.PCIComplianceStatus.compliant,
          violations: [],
          warnings: [],
          timestamp: DateTime.now(),
        ));

        // Act
        final securityResult = await securityService.processSecureWithdrawalRequest(
          driverId: testDriverId,
          amount: amount,
          withdrawalMethod: withdrawalMethod,
          bankDetails: bankDetails,
        );

        // Assert
        expect(securityResult.complianceResult.fraudRiskLevel,
               isIn([driver_compliance.FraudRiskLevel.medium, driver_compliance.FraudRiskLevel.high]));
        expect(securityResult.complianceResult.fraudReasons, isNotEmpty);

        if (securityResult.complianceResult.fraudRiskLevel == driver_compliance.FraudRiskLevel.high) {
          expect(securityResult.complianceResult.status, driver_compliance.WithdrawalComplianceStatus.rejected);
        } else {
          expect(securityResult.complianceResult.requiresManualReview, isTrue);
        }
      });

      test('should validate Malaysian banking regulations compliance', () async {
        // Arrange
        const amount = 5.0; // Below minimum amount
        const withdrawalMethod = 'bank_transfer';
        final bankDetails = {
          'account_number': '1234567890',
          'bank_name': 'Test Bank',
          'account_holder_name': 'Test Driver',
          'bank_code': 'MBB',
        };

        // Mock PCI compliance result
        when(mockPciCompliance.validatePaymentDataHandling(
          operation: anyNamed('operation'),
          paymentData: anyNamed('paymentData'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => marketplace_compliance.PCIComplianceResult(
          status: marketplace_compliance.PCIComplianceStatus.compliant,
          violations: [],
          warnings: [],
          timestamp: DateTime.now(),
        ));

        // Act
        final securityResult = await securityService.processSecureWithdrawalRequest(
          driverId: testDriverId,
          amount: amount,
          withdrawalMethod: withdrawalMethod,
          bankDetails: bankDetails,
        );

        // Assert
        expect(securityResult.complianceResult.violations, isNotEmpty);
        expect(securityResult.complianceResult.violations.any((v) => v.code == 'MYS_BANK_001'), isTrue);
        expect(securityResult.complianceResult.status, driver_compliance.WithdrawalComplianceStatus.rejected);
      });

      test('should handle bank account encryption and decryption', () async {
        // Arrange
        const amount = 100.0;
        const withdrawalMethod = 'bank_transfer';
        final bankDetails = {
          'account_number': '1234567890',
          'bank_name': 'Test Bank',
          'account_holder_name': 'Test Driver',
          'bank_code': 'MBB',
        };

        // Mock PCI compliance result
        when(mockPciCompliance.validatePaymentDataHandling(
          operation: anyNamed('operation'),
          paymentData: anyNamed('paymentData'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => marketplace_compliance.PCIComplianceResult(
          status: marketplace_compliance.PCIComplianceStatus.compliant,
          violations: [],
          warnings: [],
          timestamp: DateTime.now(),
        ));

        // Act - Process secure withdrawal request
        final securityResult = await securityService.processSecureWithdrawalRequest(
          driverId: testDriverId,
          amount: amount,
          withdrawalMethod: withdrawalMethod,
          bankDetails: bankDetails,
        );

        // Act - Decrypt bank details for processing
        final decryptedBankDetails = await securityService.decryptBankDetailsForProcessing(
          driverId: testDriverId,
          encryptedBankDetails: securityResult.encryptedBankDetails,
          withdrawalRequestId: securityResult.withdrawalRequestId,
        );

        // Assert
        expect(securityResult.encryptedBankDetails, isNotEmpty);
        expect(decryptedBankDetails, equals(bankDetails));
      });
    });

    group('Error Scenario Integration Tests', () {
      test('should handle insufficient wallet balance', () async {
        // Arrange
        const amount = 1000.0; // Amount higher than available balance
        const withdrawalMethod = 'bank_transfer';
        final bankDetails = {
          'account_number': '1234567890',
          'bank_name': 'Test Bank',
          'account_holder_name': 'Test Driver',
          'bank_code': 'MBB',
        };

        // Mock insufficient balance scenario
        final mockRpcBuilder = MockPostgrestFilterBuilder();
        when(mockSupabase.rpc('validate_driver_withdrawal_limits_enhanced'))
            .thenReturn(mockRpcBuilder);
        // Note: MockPostgrestFilterBuilder.then() is already implemented to return empty data

        // Mock PCI compliance result
        when(mockPciCompliance.validatePaymentDataHandling(
          operation: anyNamed('operation'),
          paymentData: anyNamed('paymentData'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => marketplace_compliance.PCIComplianceResult(
          status: marketplace_compliance.PCIComplianceStatus.compliant,
          violations: [],
          warnings: [],
          timestamp: DateTime.now(),
        ));

        // Act
        final securityResult = await securityService.processSecureWithdrawalRequest(
          driverId: testDriverId,
          amount: amount,
          withdrawalMethod: withdrawalMethod,
          bankDetails: bankDetails,
        );

        // Assert
        expect(securityResult.complianceResult.violations, isNotEmpty);
        expect(securityResult.complianceResult.violations.any((v) => v.code == 'LIMIT_EXCEEDED'), isTrue);
        expect(securityResult.complianceResult.status, driver_compliance.WithdrawalComplianceStatus.rejected);
      });

      test('should handle invalid bank account details', () async {
        // Arrange
        const amount = 100.0;
        const withdrawalMethod = 'bank_transfer';
        final invalidBankDetails = {
          'account_number': '123', // Invalid format
          'bank_name': 'Test Bank',
          'account_holder_name': 'Test Driver',
          'bank_code': 'INVALID', // Invalid bank code
        };

        // Mock PCI compliance result
        when(mockPciCompliance.validatePaymentDataHandling(
          operation: anyNamed('operation'),
          paymentData: anyNamed('paymentData'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => marketplace_compliance.PCIComplianceResult(
          status: marketplace_compliance.PCIComplianceStatus.compliant,
          violations: [],
          warnings: [],
          timestamp: DateTime.now(),
        ));

        // Act
        final securityResult = await securityService.processSecureWithdrawalRequest(
          driverId: testDriverId,
          amount: amount,
          withdrawalMethod: withdrawalMethod,
          bankDetails: invalidBankDetails,
        );

        // Assert
        expect(securityResult.complianceResult.violations, isNotEmpty);
        expect(securityResult.complianceResult.violations.any((v) => 
               v.code == 'BANK_INVALID_ACCOUNT' || v.code == 'MYS_BANK_005'), isTrue);
        expect(securityResult.complianceResult.status, driver_compliance.WithdrawalComplianceStatus.rejected);
      });

      test('should handle system errors gracefully', () async {
        // Arrange
        const amount = 100.0;
        const withdrawalMethod = 'bank_transfer';
        final bankDetails = {
          'account_number': '1234567890',
          'bank_name': 'Test Bank',
          'account_holder_name': 'Test Driver',
          'bank_code': 'MBB',
        };

        // Mock system error
        when(mockPciCompliance.validatePaymentDataHandling(
          operation: anyNamed('operation'),
          paymentData: anyNamed('paymentData'),
          userId: anyNamed('userId'),
        )).thenThrow(Exception('System error'));

        // Act & Assert
        expect(
          () => securityService.processSecureWithdrawalRequest(
            driverId: testDriverId,
            amount: amount,
            withdrawalMethod: withdrawalMethod,
            bankDetails: bankDetails,
          ),
          throwsException,
        );
      });
    });

    group('Performance and Load Testing', () {
      test('should handle multiple concurrent withdrawal requests', () async {
        // Arrange
        const amount = 100.0;
        const withdrawalMethod = 'bank_transfer';
        final bankDetails = {
          'account_number': '1234567890',
          'bank_name': 'Test Bank',
          'account_holder_name': 'Test Driver',
          'bank_code': 'MBB',
        };

        // Mock PCI compliance result
        when(mockPciCompliance.validatePaymentDataHandling(
          operation: anyNamed('operation'),
          paymentData: anyNamed('paymentData'),
          userId: anyNamed('userId'),
        )).thenAnswer((_) async => marketplace_compliance.PCIComplianceResult(
          status: marketplace_compliance.PCIComplianceStatus.compliant,
          violations: [],
          warnings: [],
          timestamp: DateTime.now(),
        ));

        // Act - Process multiple concurrent requests
        final futures = List.generate(5, (index) => 
          securityService.processSecureWithdrawalRequest(
            driverId: '$testDriverId-$index',
            amount: amount,
            withdrawalMethod: withdrawalMethod,
            bankDetails: bankDetails,
          )
        );

        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(5));
        for (final result in results) {
          expect(result.withdrawalRequestId, isNotEmpty);
          expect(result.securityAuditComplete, isTrue);
        }
      });
    });
  });
}

// Mock classes for testing
// ignore: must_be_immutable
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder<dynamic> {
  @override
  Future<U> then<U>(
    FutureOr<U> Function(dynamic) onValue, {
    Function? onError,
  }) async {
    return onValue({} as dynamic);
  }
}
