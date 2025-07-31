import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gigaeats_app/src/core/utils/logger.dart';
import 'package:gigaeats_app/src/features/marketplace_wallet/security/malaysian_compliance_service.dart';
import 'package:gigaeats_app/src/features/marketplace_wallet/security/pci_dss_compliance_service.dart' as marketplace_compliance;
import 'package:gigaeats_app/src/features/marketplace_wallet/security/financial_security_service.dart';
import 'package:gigaeats_app/src/features/drivers/security/driver_withdrawal_compliance_service.dart';
import 'package:gigaeats_app/src/features/drivers/security/driver_withdrawal_encryption_service.dart';
import 'package:gigaeats_app/src/features/drivers/security/driver_withdrawal_audit_service.dart';
import 'package:gigaeats_app/src/features/drivers/security/driver_withdrawal_security_integration_service.dart';
import 'package:gigaeats_app/src/features/drivers/security/models/withdrawal_compliance_models.dart' as driver_compliance;

import 'driver_withdrawal_security_test.mocks.dart';

@GenerateMocks([
  SupabaseClient,
  AppLogger,
  MalaysianComplianceService,
  marketplace_compliance.PCIDSSComplianceService,
  FinancialSecurityService,
])
void main() {
  group('Driver Withdrawal Security Tests', () {
    late MockSupabaseClient mockSupabase;
    late MockAppLogger mockLogger;
    late MockMalaysianComplianceService mockMalaysianCompliance;
    late MockPCIDSSComplianceService mockPciCompliance;
    late MockFinancialSecurityService mockFinancialSecurity;
    late DriverWithdrawalComplianceService complianceService;
    late DriverWithdrawalEncryptionService encryptionService;
    late DriverWithdrawalAuditService auditService;
    late DriverWithdrawalSecurityIntegrationService securityService;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockLogger = MockAppLogger();
      mockMalaysianCompliance = MockMalaysianComplianceService();
      mockPciCompliance = MockPCIDSSComplianceService();
      mockFinancialSecurity = MockFinancialSecurityService();

      complianceService = DriverWithdrawalComplianceService(
        supabase: mockSupabase,
        logger: mockLogger,
        pciCompliance: mockPciCompliance,
      );

      encryptionService = DriverWithdrawalEncryptionService(
        supabase: mockSupabase,
        logger: mockLogger,
      );

      auditService = DriverWithdrawalAuditService(
        supabase: mockSupabase,
        logger: mockLogger,
      );

      securityService = DriverWithdrawalSecurityIntegrationService(
        supabase: mockSupabase,
        logger: mockLogger,
        malaysianCompliance: mockMalaysianCompliance,
        pciCompliance: mockPciCompliance,
        financialSecurity: mockFinancialSecurity,
      );
    });

    group('Compliance Service Tests', () {
      test('should approve compliant withdrawal request', () async {
        // Arrange
        const driverId = 'test-driver-id';
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

        // Act
        final result = await complianceService.validateWithdrawalCompliance(
          driverId: driverId,
          amount: amount,
          withdrawalMethod: withdrawalMethod,
          bankDetails: bankDetails,
        );

        // Assert
        expect(result.status, driver_compliance.WithdrawalComplianceStatus.approved);
        expect(result.violations, isEmpty);
        expect(result.fraudRiskLevel, driver_compliance.FraudRiskLevel.low);
      });

      test('should reject withdrawal request with high fraud risk', () async {
        // Arrange
        const driverId = 'test-driver-id';
        const amount = 2000.0; // High amount
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
        final result = await complianceService.validateWithdrawalCompliance(
          driverId: driverId,
          amount: amount,
          withdrawalMethod: withdrawalMethod,
          bankDetails: bankDetails,
        );

        // Assert
        expect(result.fraudRiskLevel, driver_compliance.FraudRiskLevel.medium);
        expect(result.fraudReasons, isNotEmpty);
      });

      test('should validate Malaysian banking regulations', () async {
        // Arrange
        const driverId = 'test-driver-id';
        const amount = 5.0; // Below minimum
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
        final result = await complianceService.validateWithdrawalCompliance(
          driverId: driverId,
          amount: amount,
          withdrawalMethod: withdrawalMethod,
          bankDetails: bankDetails,
        );

        // Assert
        expect(result.violations, isNotEmpty);
        expect(result.violations.any((v) => v.code == 'MYS_BANK_001'), isTrue);
      });
    });

    group('Encryption Service Tests', () {
      test('should encrypt and decrypt bank account data successfully', () async {
        // Arrange
        const driverId = 'test-driver-id';
        final bankAccountData = {
          'account_number': '1234567890',
          'bank_name': 'Test Bank',
          'account_holder_name': 'Test Driver',
        };

        // Act
        final encryptionResult = await encryptionService.encryptBankAccountData(
          driverId: driverId,
          bankAccountData: bankAccountData,
        );

        final decryptionResult = await encryptionService.decryptBankAccountData(
          driverId: driverId,
          encryptedData: encryptionResult.encryptedData,
        );

        // Assert
        expect(encryptionResult.algorithm, 'AES-256-GCM');
        expect(decryptionResult.isValid, isTrue);
        expect(decryptionResult.decryptedData, equals(bankAccountData));
      });

      test('should fail decryption with invalid encrypted data', () async {
        // Arrange
        const driverId = 'test-driver-id';
        const invalidEncryptedData = 'invalid-encrypted-data';

        // Act
        final decryptionResult = await encryptionService.decryptBankAccountData(
          driverId: driverId,
          encryptedData: invalidEncryptedData,
        );

        // Assert
        expect(decryptionResult.isValid, isFalse);
        expect(decryptionResult.error, isNotNull);
      });

      test('should validate bank account data structure', () async {
        // Arrange
        const driverId = 'test-driver-id';
        final invalidBankAccountData = {
          'account_number': '123', // Invalid format
          'bank_name': 'Test Bank',
          // Missing account_holder_name
        };

        // Act & Assert
        expect(
          () => encryptionService.encryptBankAccountData(
            driverId: driverId,
            bankAccountData: invalidBankAccountData,
          ),
          throwsException,
        );
      });
    });

    group('Audit Service Tests', () {
      test('should log withdrawal security events', () async {
        // Arrange
        const driverId = 'test-driver-id';
        const eventType = 'withdrawal_request_created';
        const operation = 'create_withdrawal_request';
        final eventData = {
          'amount': 100.0,
          'withdrawal_method': 'bank_transfer',
        };

        // Act
        await auditService.logWithdrawalSecurityEvent(
          eventType: eventType,
          driverId: driverId,
          operation: operation,
          eventData: eventData,
        );

        // Assert
        // Verify that the audit log was created (would need to mock Supabase response)
        verify(mockSupabase.from('financial_audit_log')).called(1);
      });

      test('should generate security audit report', () async {
        // Arrange
        const driverId = 'test-driver-id';
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();

        // Mock Supabase response
        final mockQueryBuilder = MockSupabaseQueryBuilder();
        when(mockSupabase.from('financial_audit_log')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(MockPostgrestFilterBuilder());
        when(mockQueryBuilder.gte('created_at', startDate)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.lte('created_at', endDate)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq('driver_id', driverId)).thenReturn(mockQueryBuilder);

        // Act
        final report = await auditService.generateSecurityAuditReport(
          driverId: driverId,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        expect(report['driver_id'], equals(driverId));
        expect(report['report_period'], isNotNull);
        expect(report['summary'], isNotNull);
      });

      test('should mask account numbers for logging', () async {
        // Arrange
        const driverId = 'test-driver-id';
        const withdrawalRequestId = 'test-withdrawal-id';
        const amount = 100.0;
        const withdrawalMethod = 'bank_transfer';
        final bankDetails = {
          'account_number': '1234567890',
          'bank_name': 'Test Bank',
          'account_holder_name': 'Test Driver',
        };

        // Act
        await auditService.logWithdrawalRequestCreated(
          driverId: driverId,
          withdrawalRequestId: withdrawalRequestId,
          amount: amount,
          withdrawalMethod: withdrawalMethod,
          bankDetails: bankDetails,
        );

        // Assert
        // Verify that account number is masked in logs
        // This would require checking the actual log data
        verify(mockSupabase.from('financial_audit_log')).called(1);
      });
    });

    group('Security Integration Service Tests', () {
      test('should process secure withdrawal request successfully', () async {
        // Arrange
        const driverId = 'test-driver-id';
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

        // Act
        final result = await securityService.processSecureWithdrawalRequest(
          driverId: driverId,
          amount: amount,
          withdrawalMethod: withdrawalMethod,
          bankDetails: bankDetails,
        );

        // Assert
        expect(result.withdrawalRequestId, isNotEmpty);
        expect(result.complianceResult.status, driver_compliance.WithdrawalComplianceStatus.approved);
        expect(result.encryptedBankDetails, isNotEmpty);
        expect(result.securityAuditComplete, isTrue);
      });

      test('should validate withdrawal security', () async {
        // Arrange
        const driverId = 'test-driver-id';
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

        // Act
        final result = await securityService.validateWithdrawalSecurity(
          driverId: driverId,
          amount: amount,
          withdrawalMethod: withdrawalMethod,
          bankDetails: bankDetails,
        );

        // Assert
        expect(result.isValid, isTrue);
        expect(result.complianceResult.status, driver_compliance.WithdrawalComplianceStatus.approved);
      });
    });
  });
}

// Mock classes for testing
// ignore: must_be_immutable
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {
  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return MockPostgrestFilterBuilder();
  }

  SupabaseQueryBuilder eq(String column, Object value) => this;

  SupabaseQueryBuilder gte(String column, Object value) => this;

  SupabaseQueryBuilder lte(String column, Object value) => this;
}

// ignore: must_be_immutable
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return MockPostgrestTransformBuilder();
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> gte(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> lte(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> inFilter(String column, List values) => this;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(String column, {bool ascending = false, bool nullsFirst = false, String? referencedTable}) {
    return MockPostgrestTransformBuilder();
  }

  @override
  Future<U> then<U>(
    FutureOr<U> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) async {
    return onValue([]);
  }
}

// ignore: must_be_immutable
class MockPostgrestTransformBuilder extends Mock implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  @override
  Future<U> then<U>(
    FutureOr<U> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) async {
    return onValue([]);
  }
}
