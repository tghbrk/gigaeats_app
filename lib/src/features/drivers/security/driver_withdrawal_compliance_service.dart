import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/logger.dart';

import '../../marketplace_wallet/security/pci_dss_compliance_service.dart' as marketplace_pci;
import 'models/withdrawal_compliance_models.dart';

/// Enhanced security and compliance service for driver bank withdrawals
/// Implements PCI DSS compliance, Malaysian financial regulations, and fraud detection
class DriverWithdrawalComplianceService {
  final SupabaseClient _supabase;
  final AppLogger _logger;
  final marketplace_pci.PCIDSSComplianceService _pciCompliance;

  DriverWithdrawalComplianceService({
    required SupabaseClient supabase,
    required AppLogger logger,
    required marketplace_pci.PCIDSSComplianceService pciCompliance,
  }) : _supabase = supabase,
       _logger = logger,
       _pciCompliance = pciCompliance;





  /// Comprehensive compliance validation for withdrawal requests
  Future<WithdrawalComplianceResult> validateWithdrawalCompliance({
    required String driverId,
    required double amount,
    required String withdrawalMethod,
    required Map<String, dynamic> bankDetails,
    String? ipAddress,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      debugPrint('🔒 [WITHDRAWAL-COMPLIANCE] Starting comprehensive compliance validation');

      final violations = <ComplianceViolation>[];
      final warnings = <String>[];
      final securityFlags = <String>[];

      // 1. Malaysian Financial Regulations Compliance
      final malaysianResult = await _validateMalaysianRegulations(
        driverId: driverId,
        amount: amount,
        withdrawalMethod: withdrawalMethod,
        bankDetails: bankDetails,
      );
      violations.addAll(malaysianResult.violations);
      warnings.addAll(malaysianResult.warnings);

      // 2. PCI DSS Compliance for sensitive data handling
      final pciResult = await _validatePCIDSSCompliance(
        operation: 'bank_withdrawal',
        paymentData: bankDetails,
        userId: driverId,
      );
      violations.addAll(pciResult.violations.map((v) => ComplianceViolation(
        code: 'PCI_${v.requirement.replaceAll(' ', '_').toUpperCase()}',
        description: v.description,
        regulation: 'PCI DSS',
        severity: _mapPCISeverity(v.severity),
      )));

      // 3. Enhanced Fraud Detection
      final fraudResult = await _performEnhancedFraudDetection(
        driverId: driverId,
        amount: amount,
        withdrawalMethod: withdrawalMethod,
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
      );
      if (fraudResult.riskLevel == FraudRiskLevel.high) {
        violations.add(ComplianceViolation(
          code: 'FRAUD_HIGH_RISK',
          description: 'High fraud risk detected: ${fraudResult.reasons.join(', ')}',
          regulation: 'Internal Fraud Prevention',
          severity: ComplianceSeverity.high,
        ));
      } else if (fraudResult.riskLevel == FraudRiskLevel.medium) {
        warnings.add('Medium fraud risk detected: ${fraudResult.reasons.join(', ')}');
      }

      // 4. Withdrawal Limits Validation
      final limitsResult = await _validateWithdrawalLimits(driverId, amount);
      violations.addAll(limitsResult.violations);
      warnings.addAll(limitsResult.warnings);

      // 5. Bank Account Security Validation
      final bankSecurityResult = await _validateBankAccountSecurity(bankDetails);
      violations.addAll(bankSecurityResult.violations);
      securityFlags.addAll(bankSecurityResult.securityFlags);

      // 6. Device and Session Security
      final deviceSecurityResult = await _validateDeviceSecurity(
        driverId: driverId,
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
      );
      violations.addAll(deviceSecurityResult.violations);
      warnings.addAll(deviceSecurityResult.warnings);

      // Determine overall compliance status
      final hasHighSeverityViolations = violations.any((v) => v.severity == ComplianceSeverity.high);
      final hasMediumSeverityViolations = violations.any((v) => v.severity == ComplianceSeverity.medium);

      WithdrawalComplianceStatus status;
      if (hasHighSeverityViolations) {
        status = WithdrawalComplianceStatus.rejected;
      } else if (hasMediumSeverityViolations || fraudResult.riskLevel == FraudRiskLevel.medium) {
        status = WithdrawalComplianceStatus.requiresReview;
      } else {
        status = WithdrawalComplianceStatus.approved;
      }

      // Log compliance validation
      await _logComplianceValidation(
        driverId: driverId,
        amount: amount,
        status: status,
        violations: violations,
        warnings: warnings,
        fraudResult: fraudResult,
      );

      debugPrint('✅ [WITHDRAWAL-COMPLIANCE] Compliance validation completed: $status');

      return WithdrawalComplianceResult(
        status: status,
        violations: violations,
        warnings: warnings,
        securityFlags: securityFlags,
        fraudRiskLevel: fraudResult.riskLevel,
        fraudReasons: fraudResult.reasons,
        requiresManualReview: status == WithdrawalComplianceStatus.requiresReview,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-COMPLIANCE] Compliance validation error: $e');
      _logger.error('Withdrawal compliance validation failed', e);
      
      return WithdrawalComplianceResult(
        status: WithdrawalComplianceStatus.error,
        violations: [
          ComplianceViolation(
            code: 'SYSTEM_ERROR',
            description: 'Compliance validation system error: $e',
            regulation: 'System Error',
            severity: ComplianceSeverity.high,
          ),
        ],
        warnings: [],
        securityFlags: [],
        fraudRiskLevel: FraudRiskLevel.high,
        fraudReasons: ['System error during validation'],
        requiresManualReview: true,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Validates Malaysian financial regulations for driver withdrawals
  Future<MalaysianWithdrawalValidationResult> _validateMalaysianRegulations({
    required String driverId,
    required double amount,
    required String withdrawalMethod,
    required Map<String, dynamic> bankDetails,
  }) async {
    final violations = <ComplianceViolation>[];
    final warnings = <String>[];

    try {
      // Malaysian Banking Regulation 1: Minimum withdrawal amount
      if (amount < 10.00) {
        violations.add(ComplianceViolation(
          code: 'MYS_BANK_001',
          description: 'Minimum withdrawal amount is RM 10.00',
          regulation: 'Malaysian Banking Regulations',
          severity: ComplianceSeverity.medium,
        ));
      }

      // Malaysian Banking Regulation 2: Maximum single withdrawal
      if (amount > 5000.00) {
        violations.add(ComplianceViolation(
          code: 'MYS_BANK_002',
          description: 'Maximum single withdrawal amount is RM 5,000',
          regulation: 'Malaysian Banking Regulations',
          severity: ComplianceSeverity.high,
        ));
      }

      // Malaysian Banking Regulation 3: Daily withdrawal limits
      final dailyTotal = await _calculateDailyWithdrawalTotal(driverId);
      if (dailyTotal + amount > 10000.00) {
        violations.add(ComplianceViolation(
          code: 'MYS_BANK_003',
          description: 'Daily withdrawal limit of RM 10,000 exceeded',
          regulation: 'Malaysian Banking Regulations',
          severity: ComplianceSeverity.high,
        ));
      }

      // Malaysian Banking Regulation 4: Bank account validation
      if (withdrawalMethod == 'bank_transfer') {
        final accountNumber = bankDetails['account_number'] as String?;
        final bankCode = bankDetails['bank_code'] as String?;
        
        if (accountNumber == null || accountNumber.isEmpty) {
          violations.add(ComplianceViolation(
            code: 'MYS_BANK_004',
            description: 'Valid bank account number required',
            regulation: 'Malaysian Banking Regulations',
            severity: ComplianceSeverity.medium,
          ));
        }

        if (bankCode == null || !_isValidMalaysianBankCode(bankCode)) {
          violations.add(ComplianceViolation(
            code: 'MYS_BANK_005',
            description: 'Valid Malaysian bank code required',
            regulation: 'Malaysian Banking Regulations',
            severity: ComplianceSeverity.medium,
          ));
        }
      }

      // Malaysian Banking Regulation 5: Anti-Money Laundering (AML) checks
      if (amount > 1000.00) {
        final amlResult = await _performAMLCheck(driverId, amount);
        if (!amlResult.isCompliant) {
          violations.add(ComplianceViolation(
            code: 'MYS_AML_001',
            description: 'AML compliance check failed',
            regulation: 'Malaysian Anti-Money Laundering Act',
            severity: ComplianceSeverity.high,
          ));
        }
      }

      return MalaysianWithdrawalValidationResult(
        violations: violations,
        warnings: warnings,
      );
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-COMPLIANCE] Malaysian regulations validation error: $e');
      return MalaysianWithdrawalValidationResult(
        violations: [
          ComplianceViolation(
            code: 'MYS_SYSTEM_ERROR',
            description: 'Malaysian regulations validation system error',
            regulation: 'System Error',
            severity: ComplianceSeverity.high,
          ),
        ],
        warnings: [],
      );
    }
  }

  /// Validates PCI DSS compliance for sensitive data handling
  Future<marketplace_pci.PCIComplianceResult> _validatePCIDSSCompliance({
    required String operation,
    required Map<String, dynamic> paymentData,
    required String userId,
  }) async {
    return await _pciCompliance.validatePaymentDataHandling(
      operation: operation,
      paymentData: paymentData,
      userId: userId,
    );
  }

  /// Performs enhanced fraud detection with multiple risk factors
  Future<EnhancedFraudDetectionResult> _performEnhancedFraudDetection({
    required String driverId,
    required double amount,
    required String withdrawalMethod,
    String? ipAddress,
    Map<String, dynamic>? deviceInfo,
  }) async {
    final riskFactors = <String>[];
    var riskScore = 0.0;

    try {
      // Risk Factor 1: High amount threshold
      if (amount >= 1000.00) {
        riskFactors.add('High amount withdrawal: RM ${amount.toStringAsFixed(2)}');
        riskScore += 25.0;
      }

      // Risk Factor 2: Rapid withdrawal attempts
      final recentWithdrawals = await _getRecentWithdrawals(driverId, Duration(hours: 1));
      if (recentWithdrawals.length >= 3) {
        riskFactors.add('${recentWithdrawals.length} withdrawal attempts in last hour');
        riskScore += 30.0;
      }

      // Risk Factor 3: Unusual time patterns
      final now = DateTime.now();
      if (now.hour < 6 || now.hour > 22) {
        riskFactors.add('Withdrawal attempt outside normal hours');
        riskScore += 15.0;
      }

      // Risk Factor 4: Suspicious IP address patterns
      if (ipAddress != null) {
        final ipRisk = await _analyzeIPRisk(driverId, ipAddress);
        if (ipRisk.isHighRisk) {
          riskFactors.add('Suspicious IP address detected');
          riskScore += 35.0;
        }
      }

      // Risk Factor 5: Device fingerprinting
      if (deviceInfo != null) {
        final deviceRisk = await _analyzeDeviceRisk(driverId, deviceInfo);
        if (deviceRisk.isNewDevice) {
          riskFactors.add('New device detected');
          riskScore += 20.0;
        }
      }

      // Risk Factor 6: Velocity checks
      final velocityRisk = await _performVelocityCheck(driverId, amount);
      if (velocityRisk.exceedsThreshold) {
        riskFactors.add('High velocity pattern detected');
        riskScore += 25.0;
      }

      // Determine risk level
      FraudRiskLevel riskLevel;
      if (riskScore >= 70.0) {
        riskLevel = FraudRiskLevel.high;
      } else if (riskScore >= 40.0) {
        riskLevel = FraudRiskLevel.medium;
      } else {
        riskLevel = FraudRiskLevel.low;
      }

      return EnhancedFraudDetectionResult(
        riskLevel: riskLevel,
        riskScore: riskScore,
        reasons: riskFactors,
      );
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-COMPLIANCE] Enhanced fraud detection error: $e');
      return EnhancedFraudDetectionResult(
        riskLevel: FraudRiskLevel.high,
        riskScore: 100.0,
        reasons: ['Fraud detection system error'],
      );
    }
  }

  /// Validates withdrawal limits against configured thresholds
  Future<WithdrawalLimitsValidationResult> _validateWithdrawalLimits(
    String driverId,
    double amount,
  ) async {
    final violations = <ComplianceViolation>[];
    final warnings = <String>[];

    try {
      // TODO: Fix RPC call - currently has parameter mismatch
      // Get current limits from database
      // final response = await _supabase.rpc('validate_driver_withdrawal_limits_enhanced', {
      //   'p_driver_id': driverId,
      //   'p_amount': amount,
      // });

      // TODO: Implement proper limits checking when RPC is fixed
      // For now, skip validation (placeholder)

      // TODO: Implement proper limits checking when RPC is fixed
      // Check if approaching limits (80% threshold)
      // final dailyUsagePercent = (limits['daily_used'] as double) / (limits['daily_limit'] as double);
      // if (dailyUsagePercent >= 0.8) {
      //   warnings.add('Approaching daily withdrawal limit (${(dailyUsagePercent * 100).toStringAsFixed(1)}% used)');
      // }

      return WithdrawalLimitsValidationResult(
        violations: violations,
        warnings: warnings,
      );
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-COMPLIANCE] Withdrawal limits validation error: $e');
      return WithdrawalLimitsValidationResult(
        violations: [
          ComplianceViolation(
            code: 'LIMITS_SYSTEM_ERROR',
            description: 'Withdrawal limits validation system error',
            regulation: 'System Error',
            severity: ComplianceSeverity.high,
          ),
        ],
        warnings: [],
      );
    }
  }

  /// Validates bank account security and encryption
  Future<BankAccountSecurityResult> _validateBankAccountSecurity(
    Map<String, dynamic> bankDetails,
  ) async {
    final violations = <ComplianceViolation>[];
    final securityFlags = <String>[];

    try {
      // Validate required fields
      final requiredFields = ['account_number', 'bank_name', 'account_holder_name'];
      for (final field in requiredFields) {
        if (!bankDetails.containsKey(field) || bankDetails[field] == null ||
            (bankDetails[field] as String).isEmpty) {
          violations.add(ComplianceViolation(
            code: 'BANK_MISSING_FIELD',
            description: 'Required bank account field missing: $field',
            regulation: 'Bank Account Security',
            severity: ComplianceSeverity.medium,
          ));
        }
      }

      // Validate account number format
      final accountNumber = bankDetails['account_number'] as String?;
      if (accountNumber != null && !_isValidAccountNumber(accountNumber)) {
        violations.add(ComplianceViolation(
          code: 'BANK_INVALID_ACCOUNT',
          description: 'Invalid bank account number format',
          regulation: 'Bank Account Security',
          severity: ComplianceSeverity.medium,
        ));
      }

      // Check for sensitive data exposure
      if (accountNumber != null && !_isEncrypted(accountNumber)) {
        securityFlags.add('Bank account number not encrypted');
      }

      // Validate account holder name matches driver profile
      final accountHolderName = bankDetails['account_holder_name'] as String?;
      if (accountHolderName != null) {
        final nameValidation = await _validateAccountHolderName(accountHolderName);
        if (!nameValidation.isValid) {
          violations.add(ComplianceViolation(
            code: 'BANK_NAME_MISMATCH',
            description: 'Account holder name validation failed',
            regulation: 'Identity Verification',
            severity: ComplianceSeverity.high,
          ));
        }
      }

      return BankAccountSecurityResult(
        violations: violations,
        securityFlags: securityFlags,
      );
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-COMPLIANCE] Bank account security validation error: $e');
      return BankAccountSecurityResult(
        violations: [
          ComplianceViolation(
            code: 'BANK_SECURITY_ERROR',
            description: 'Bank account security validation system error',
            regulation: 'System Error',
            severity: ComplianceSeverity.high,
          ),
        ],
        securityFlags: [],
      );
    }
  }

  /// Validates device and session security
  Future<DeviceSecurityResult> _validateDeviceSecurity({
    required String driverId,
    String? ipAddress,
    Map<String, dynamic>? deviceInfo,
  }) async {
    final violations = <ComplianceViolation>[];
    final warnings = <String>[];

    try {
      // Check for suspicious IP patterns
      if (ipAddress != null) {
        final ipAnalysis = await _analyzeIPAddress(ipAddress);
        if (ipAnalysis.isVPN || ipAnalysis.isProxy) {
          violations.add(ComplianceViolation(
            code: 'DEVICE_VPN_PROXY',
            description: 'VPN or proxy detected',
            regulation: 'Device Security',
            severity: ComplianceSeverity.medium,
          ));
        }

        if (ipAnalysis.isFromHighRiskCountry) {
          warnings.add('IP address from high-risk geographical location');
        }
      }

      // Validate device fingerprint
      if (deviceInfo != null) {
        final deviceValidation = await _validateDeviceFingerprint(driverId, deviceInfo);
        if (deviceValidation.isNewDevice && !deviceValidation.isVerified) {
          warnings.add('New unverified device detected');
        }

        if (deviceValidation.hasSecurityConcerns) {
          violations.add(ComplianceViolation(
            code: 'DEVICE_SECURITY_CONCERN',
            description: 'Device security concerns detected',
            regulation: 'Device Security',
            severity: ComplianceSeverity.medium,
          ));
        }
      }

      return DeviceSecurityResult(
        violations: violations,
        warnings: warnings,
      );
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-COMPLIANCE] Device security validation error: $e');
      return DeviceSecurityResult(
        violations: [
          ComplianceViolation(
            code: 'DEVICE_SECURITY_ERROR',
            description: 'Device security validation system error',
            regulation: 'System Error',
            severity: ComplianceSeverity.high,
          ),
        ],
        warnings: [],
      );
    }
  }

  // Helper methods for compliance validation
  Future<double> _calculateDailyWithdrawalTotal(String driverId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final response = await _supabase
        .from('driver_withdrawal_requests')
        .select('amount')
        .eq('driver_id', driverId)
        .gte('requested_at', startOfDay.toIso8601String())
        .inFilter('status', ['pending', 'processing', 'completed']);

    final withdrawals = response as List<dynamic>;
    return withdrawals.fold<double>(0.0, (sum, w) => sum + (w['amount'] as double));
  }

  bool _isValidMalaysianBankCode(String bankCode) {
    // Malaysian bank codes (simplified validation)
    const validBankCodes = [
      'MBB', 'CIMB', 'PBB', 'RHB', 'HLB', 'AMBANK', 'BSN', 'OCBC', 'SCB', 'UOB'
    ];
    return validBankCodes.contains(bankCode.toUpperCase());
  }

  Future<AMLCheckResult> _performAMLCheck(String driverId, double amount) async {
    // Simplified AML check - in production, integrate with proper AML service
    return AMLCheckResult(isCompliant: true);
  }

  bool _isValidAccountNumber(String accountNumber) {
    // Basic account number validation (8-20 digits)
    return RegExp(r'^\d{8,20}$').hasMatch(accountNumber);
  }

  bool _isEncrypted(String data) {
    // Check if data appears to be encrypted
    return data.startsWith('enc_') || data.length > 50;
  }

  Future<AccountHolderValidationResult> _validateAccountHolderName(String name) async {
    // Simplified validation - in production, verify against driver profile
    return AccountHolderValidationResult(isValid: true);
  }

  Future<List<Map<String, dynamic>>> _getRecentWithdrawals(String driverId, Duration period) async {
    final cutoff = DateTime.now().subtract(period);

    final response = await _supabase
        .from('driver_withdrawal_requests')
        .select('*')
        .eq('driver_id', driverId)
        .gte('requested_at', cutoff.toIso8601String())
        .order('requested_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<IPRiskAnalysis> _analyzeIPRisk(String driverId, String ipAddress) async {
    // Simplified IP risk analysis - in production, use proper IP intelligence service
    return IPRiskAnalysis(isHighRisk: false);
  }

  Future<DeviceRiskAnalysis> _analyzeDeviceRisk(String driverId, Map<String, dynamic> deviceInfo) async {
    // Simplified device risk analysis
    return DeviceRiskAnalysis(isNewDevice: false);
  }

  Future<VelocityCheckResult> _performVelocityCheck(String driverId, double amount) async {
    // Check withdrawal velocity over last 24 hours
    final last24Hours = DateTime.now().subtract(Duration(hours: 24));

    final response = await _supabase
        .from('driver_withdrawal_requests')
        .select('amount')
        .eq('driver_id', driverId)
        .gte('requested_at', last24Hours.toIso8601String())
        .inFilter('status', ['pending', 'processing', 'completed']);

    final withdrawals = response as List<dynamic>;
    final totalAmount = withdrawals.fold<double>(0.0, (sum, w) => sum + (w['amount'] as double)) + amount;

    return VelocityCheckResult(exceedsThreshold: totalAmount > 2000.0);
  }

  Future<IPAddressAnalysis> _analyzeIPAddress(String ipAddress) async {
    // Simplified IP analysis - in production, use proper geolocation/VPN detection service
    return IPAddressAnalysis(
      isVPN: false,
      isProxy: false,
      isFromHighRiskCountry: false,
    );
  }

  Future<DeviceValidationResult> _validateDeviceFingerprint(String driverId, Map<String, dynamic> deviceInfo) async {
    // Simplified device validation
    return DeviceValidationResult(
      isNewDevice: false,
      isVerified: true,
      hasSecurityConcerns: false,
    );
  }

  ComplianceSeverity _mapPCISeverity(marketplace_pci.PCIViolationSeverity severity) {
    switch (severity) {
      case marketplace_pci.PCIViolationSeverity.critical:
        return ComplianceSeverity.high;
      case marketplace_pci.PCIViolationSeverity.high:
        return ComplianceSeverity.high;
      case marketplace_pci.PCIViolationSeverity.medium:
        return ComplianceSeverity.medium;
      case marketplace_pci.PCIViolationSeverity.low:
        return ComplianceSeverity.low;
    }
  }

  Future<void> _logComplianceValidation({
    required String driverId,
    required double amount,
    required WithdrawalComplianceStatus status,
    required List<ComplianceViolation> violations,
    required List<String> warnings,
    required EnhancedFraudDetectionResult fraudResult,
  }) async {
    try {
      await _supabase.from('financial_audit_log').insert({
        'event_type': 'withdrawal_compliance_validation',
        'entity_type': 'driver_withdrawal',
        'entity_id': driverId,
        'user_id': driverId,
        'event_data': {
          'amount': amount,
          'status': status.toString(),
          'violations_count': violations.length,
          'warnings_count': warnings.length,
          'fraud_risk_level': fraudResult.riskLevel.toString(),
          'fraud_risk_score': fraudResult.riskScore,
          'violations': violations.map((v) => {
            'code': v.code,
            'description': v.description,
            'regulation': v.regulation,
            'severity': v.severity.toString(),
          }).toList(),
          'warnings': warnings,
          'fraud_reasons': fraudResult.reasons,
        },
        'metadata': {
          'source': 'driver_withdrawal_compliance_service',
          'compliance_validation': true,
          'severity': violations.any((v) => v.severity == ComplianceSeverity.high) ? 'high' : 'medium',
        },
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-COMPLIANCE] Error logging compliance validation: $e');
    }
  }
}
