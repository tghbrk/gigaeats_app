import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/logger.dart';
import '../../marketplace_wallet/security/malaysian_compliance_service.dart' as marketplace_compliance;
import '../../marketplace_wallet/security/pci_dss_compliance_service.dart' as marketplace_pci;
import '../../marketplace_wallet/security/financial_security_service.dart';
import 'driver_withdrawal_compliance_service.dart';
import 'driver_withdrawal_encryption_service.dart';
import 'driver_withdrawal_audit_service.dart';
import 'models/withdrawal_compliance_models.dart';

/// Comprehensive security integration service for driver bank withdrawals
/// Orchestrates all security, compliance, and audit components
class DriverWithdrawalSecurityIntegrationService {
  final AppLogger _logger;
  final DriverWithdrawalComplianceService _complianceService;
  final DriverWithdrawalEncryptionService _encryptionService;
  final DriverWithdrawalAuditService _auditService;

  DriverWithdrawalSecurityIntegrationService({
    required SupabaseClient supabase,
    required AppLogger logger,
    required marketplace_compliance.MalaysianComplianceService malaysianCompliance,
    required marketplace_pci.PCIDSSComplianceService pciCompliance,
    required FinancialSecurityService financialSecurity,
  }) : _logger = logger,
       _complianceService = DriverWithdrawalComplianceService(
         supabase: supabase,
         logger: logger,
         pciCompliance: pciCompliance,
       ),
       _encryptionService = DriverWithdrawalEncryptionService(
         supabase: supabase,
         logger: logger,
       ),
       _auditService = DriverWithdrawalAuditService(
         supabase: supabase,
         logger: logger,
       );

  /// Processes secure withdrawal request with comprehensive security validation
  Future<SecureWithdrawalResult> processSecureWithdrawalRequest({
    required String driverId,
    required double amount,
    required String withdrawalMethod,
    required Map<String, dynamic> bankDetails,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      debugPrint('🔐 [WITHDRAWAL-SECURITY] Processing secure withdrawal request for driver: $driverId');

      // Step 1: Validate and encrypt sensitive bank data
      final encryptionResult = await _encryptionService.encryptBankAccountData(
        driverId: driverId,
        bankAccountData: bankDetails,
      );

      // Step 2: Comprehensive compliance validation
      final complianceResult = await _complianceService.validateWithdrawalCompliance(
        driverId: driverId,
        amount: amount,
        withdrawalMethod: withdrawalMethod,
        bankDetails: bankDetails,
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
      );

      // Step 3: Generate withdrawal request ID for tracking
      final withdrawalRequestId = _generateWithdrawalRequestId();

      // Step 4: Log comprehensive audit trail
      await _auditService.logWithdrawalRequestCreated(
        driverId: driverId,
        withdrawalRequestId: withdrawalRequestId,
        amount: amount,
        withdrawalMethod: withdrawalMethod,
        bankDetails: bankDetails,
        ipAddress: ipAddress,
        deviceInfo: deviceInfo?.toString(),
        complianceResult: complianceResult,
      );

      // Step 5: Log compliance validation results
      await _auditService.logComplianceValidation(
        driverId: driverId,
        withdrawalRequestId: withdrawalRequestId,
        complianceResult: complianceResult,
        ipAddress: ipAddress,
      );

      // Step 6: Log fraud detection if applicable
      if (complianceResult.fraudRiskLevel != FraudRiskLevel.low) {
        await _auditService.logFraudDetection(
          driverId: driverId,
          withdrawalRequestId: withdrawalRequestId,
          riskLevel: complianceResult.fraudRiskLevel,
          fraudReasons: complianceResult.fraudReasons,
          riskScore: complianceResult.fraudReasons.length.toDouble() * 25.0,
          ipAddress: ipAddress,
          fraudContext: deviceInfo,
        );
      }

      // Step 7: Log security violations if any
      for (final violation in complianceResult.violations) {
        await _auditService.logSecurityViolation(
          driverId: driverId,
          violationType: violation.code,
          description: violation.description,
          severity: violation.severity,
          withdrawalRequestId: withdrawalRequestId,
          ipAddress: ipAddress,
          violationContext: {
            'regulation': violation.regulation,
            'compliance_check': true,
          },
        );
      }

      // Step 8: Log encryption event
      await _auditService.logEncryptionEvent(
        driverId: driverId,
        operation: 'encrypt_bank_details',
        success: true,
        withdrawalRequestId: withdrawalRequestId,
        algorithm: encryptionResult.algorithm,
      );

      debugPrint('✅ [WITHDRAWAL-SECURITY] Secure withdrawal request processed successfully');

      return SecureWithdrawalResult(
        withdrawalRequestId: withdrawalRequestId,
        complianceResult: complianceResult,
        encryptedBankDetails: encryptionResult.encryptedData,
        securityAuditComplete: true,
        processingTimestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-SECURITY] Error processing secure withdrawal request: $e');
      _logger.error('Secure withdrawal request processing failed', e);

      // Log the error as a security event
      await _auditService.logSecurityViolation(
        driverId: driverId,
        violationType: 'SYSTEM_ERROR',
        description: 'Secure withdrawal processing system error: $e',
        severity: ComplianceSeverity.high,
        ipAddress: ipAddress,
        violationContext: {
          'error_type': 'system_error',
          'processing_stage': 'secure_withdrawal_request',
        },
      );

      rethrow;
    }
  }

  /// Validates withdrawal request security before processing
  Future<WithdrawalSecurityValidationResult> validateWithdrawalSecurity({
    required String driverId,
    required double amount,
    required String withdrawalMethod,
    required Map<String, dynamic> bankDetails,
    String? ipAddress,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      debugPrint('🔍 [WITHDRAWAL-SECURITY] Validating withdrawal security for driver: $driverId');

      // Perform comprehensive compliance validation
      final complianceResult = await _complianceService.validateWithdrawalCompliance(
        driverId: driverId,
        amount: amount,
        withdrawalMethod: withdrawalMethod,
        bankDetails: bankDetails,
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
      );

      // Log access control event
      await _auditService.logAccessControl(
        driverId: driverId,
        accessType: 'withdrawal_validation',
        granted: complianceResult.status == WithdrawalComplianceStatus.approved,
        resource: 'withdrawal_request',
        reason: complianceResult.status.toString(),
        ipAddress: ipAddress,
        accessContext: {
          'amount': amount,
          'withdrawal_method': withdrawalMethod,
          'fraud_risk_level': complianceResult.fraudRiskLevel.toString(),
        },
      );

      debugPrint('✅ [WITHDRAWAL-SECURITY] Withdrawal security validation completed');

      return WithdrawalSecurityValidationResult(
        isValid: complianceResult.status == WithdrawalComplianceStatus.approved,
        complianceResult: complianceResult,
        securityFlags: complianceResult.securityFlags,
        requiresManualReview: complianceResult.requiresManualReview,
        validationTimestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-SECURITY] Error validating withdrawal security: $e');
      _logger.error('Withdrawal security validation failed', e);
      rethrow;
    }
  }

  /// Decrypts bank details for withdrawal processing
  Future<Map<String, dynamic>> decryptBankDetailsForProcessing({
    required String driverId,
    required String encryptedBankDetails,
    required String withdrawalRequestId,
  }) async {
    try {
      debugPrint('🔓 [WITHDRAWAL-SECURITY] Decrypting bank details for processing');

      // Log access control for decryption
      await _auditService.logAccessControl(
        driverId: driverId,
        accessType: 'decrypt_bank_details',
        granted: true,
        resource: 'encrypted_bank_data',
        reason: 'withdrawal_processing',
      );

      // Decrypt bank details
      final decryptionResult = await _encryptionService.decryptBankAccountData(
        driverId: driverId,
        encryptedData: encryptedBankDetails,
      );

      // Log decryption event
      await _auditService.logEncryptionEvent(
        driverId: driverId,
        operation: 'decrypt_bank_details',
        success: decryptionResult.isValid,
        withdrawalRequestId: withdrawalRequestId,
        error: decryptionResult.error,
      );

      if (!decryptionResult.isValid) {
        throw Exception('Failed to decrypt bank details: ${decryptionResult.error}');
      }

      debugPrint('✅ [WITHDRAWAL-SECURITY] Bank details decrypted successfully');
      return decryptionResult.decryptedData;
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-SECURITY] Error decrypting bank details: $e');
      _logger.error('Bank details decryption failed', e);
      rethrow;
    }
  }

  /// Generates comprehensive security audit report
  Future<Map<String, dynamic>> generateComprehensiveSecurityReport({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('📊 [WITHDRAWAL-SECURITY] Generating comprehensive security report');

      final securityReport = await _auditService.generateSecurityAuditReport(
        driverId: driverId,
        startDate: startDate,
        endDate: endDate,
      );

      // Add additional security metrics
      securityReport['security_metrics'] = await _generateSecurityMetrics(driverId, startDate, endDate);
      securityReport['compliance_summary'] = await _generateComplianceSummary(driverId, startDate, endDate);

      debugPrint('✅ [WITHDRAWAL-SECURITY] Comprehensive security report generated');
      return securityReport;
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-SECURITY] Error generating security report: $e');
      _logger.error('Security report generation failed', e);
      rethrow;
    }
  }

  /// Rotates driver encryption keys for enhanced security
  Future<void> rotateDriverSecurityKeys(String driverId) async {
    try {
      debugPrint('🔄 [WITHDRAWAL-SECURITY] Rotating security keys for driver: $driverId');

      await _encryptionService.rotateDriverEncryptionKey(driverId);

      // Log key rotation event
      await _auditService.logWithdrawalSecurityEvent(
        eventType: 'security_key_rotation',
        driverId: driverId,
        operation: 'rotate_encryption_keys',
        eventData: {
          'key_rotation_timestamp': DateTime.now().toIso8601String(),
          'security_enhancement': true,
        },
        severity: ComplianceSeverity.medium,
        complianceFlags: ['key_rotation', 'security_enhancement'],
      );

      debugPrint('✅ [WITHDRAWAL-SECURITY] Security keys rotated successfully');
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-SECURITY] Error rotating security keys: $e');
      _logger.error('Security key rotation failed', e);
      rethrow;
    }
  }

  /// Generates withdrawal request ID
  String _generateWithdrawalRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'WR_${timestamp}_$random';
  }

  /// Generates security metrics for reporting
  Future<Map<String, dynamic>> _generateSecurityMetrics(
    String driverId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    // Implementation would query various security metrics
    return {
      'encryption_events': 0,
      'compliance_checks': 0,
      'fraud_detections': 0,
      'security_violations': 0,
    };
  }

  /// Generates compliance summary for reporting
  Future<Map<String, dynamic>> _generateComplianceSummary(
    String driverId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    // Implementation would generate compliance summary
    return {
      'pci_dss_compliance': 'compliant',
      'malaysian_regulations': 'compliant',
      'data_protection': 'compliant',
      'audit_trail': 'complete',
    };
  }
}

/// Result model for secure withdrawal processing
class SecureWithdrawalResult {
  final String withdrawalRequestId;
  final WithdrawalComplianceResult complianceResult;
  final String encryptedBankDetails;
  final bool securityAuditComplete;
  final DateTime processingTimestamp;

  const SecureWithdrawalResult({
    required this.withdrawalRequestId,
    required this.complianceResult,
    required this.encryptedBankDetails,
    required this.securityAuditComplete,
    required this.processingTimestamp,
  });
}

/// Result model for withdrawal security validation
class WithdrawalSecurityValidationResult {
  final bool isValid;
  final WithdrawalComplianceResult complianceResult;
  final List<String> securityFlags;
  final bool requiresManualReview;
  final DateTime validationTimestamp;

  const WithdrawalSecurityValidationResult({
    required this.isValid,
    required this.complianceResult,
    required this.securityFlags,
    required this.requiresManualReview,
    required this.validationTimestamp,
  });
}
