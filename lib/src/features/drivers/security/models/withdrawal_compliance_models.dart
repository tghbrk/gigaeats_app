// Simplified models without freezed for immediate implementation

// Enums for withdrawal compliance system

enum WithdrawalComplianceStatus {
  approved,
  requiresReview,
  rejected,
  error,
}

enum ComplianceSeverity {
  low,
  medium,
  high,
}

enum FraudRiskLevel {
  low,
  medium,
  high,
}

enum PCIViolationSeverity {
  low,
  medium,
  high,
}

enum PCIComplianceStatus {
  compliant,
  requiresReview,
  nonCompliant,
  error,
}

/// Main compliance result model
class WithdrawalComplianceResult {
  final WithdrawalComplianceStatus status;
  final List<ComplianceViolation> violations;
  final List<String> warnings;
  final List<String> securityFlags;
  final FraudRiskLevel fraudRiskLevel;
  final List<String> fraudReasons;
  final bool requiresManualReview;
  final DateTime timestamp;

  const WithdrawalComplianceResult({
    required this.status,
    required this.violations,
    required this.warnings,
    required this.securityFlags,
    required this.fraudRiskLevel,
    required this.fraudReasons,
    required this.requiresManualReview,
    required this.timestamp,
  });
}

/// Compliance violation model
class ComplianceViolation {
  final String code;
  final String description;
  final String regulation;
  final ComplianceSeverity severity;

  const ComplianceViolation({
    required this.code,
    required this.description,
    required this.regulation,
    required this.severity,
  });
}

/// Malaysian withdrawal validation result
class MalaysianWithdrawalValidationResult {
  final List<ComplianceViolation> violations;
  final List<String> warnings;

  const MalaysianWithdrawalValidationResult({
    required this.violations,
    required this.warnings,
  });
}

/// Enhanced fraud detection result
class EnhancedFraudDetectionResult {
  final FraudRiskLevel riskLevel;
  final double riskScore;
  final List<String> reasons;

  const EnhancedFraudDetectionResult({
    required this.riskLevel,
    required this.riskScore,
    required this.reasons,
  });
}

/// Withdrawal limits validation result
class WithdrawalLimitsValidationResult {
  final List<ComplianceViolation> violations;
  final List<String> warnings;

  const WithdrawalLimitsValidationResult({
    required this.violations,
    required this.warnings,
  });
}

/// Bank account security result
class BankAccountSecurityResult {
  final List<ComplianceViolation> violations;
  final List<String> securityFlags;

  const BankAccountSecurityResult({
    required this.violations,
    required this.securityFlags,
  });
}

/// Device security result
class DeviceSecurityResult {
  final List<ComplianceViolation> violations;
  final List<String> warnings;

  const DeviceSecurityResult({
    required this.violations,
    required this.warnings,
  });
}

/// Helper models for various validation checks

class AMLCheckResult {
  final bool isCompliant;

  const AMLCheckResult({
    required this.isCompliant,
  });
}

class AccountHolderValidationResult {
  final bool isValid;

  const AccountHolderValidationResult({
    required this.isValid,
  });
}

class IPRiskAnalysis {
  final bool isHighRisk;

  const IPRiskAnalysis({
    required this.isHighRisk,
  });
}

class DeviceRiskAnalysis {
  final bool isNewDevice;

  const DeviceRiskAnalysis({
    required this.isNewDevice,
  });
}

class VelocityCheckResult {
  final bool exceedsThreshold;

  const VelocityCheckResult({
    required this.exceedsThreshold,
  });
}

class IPAddressAnalysis {
  final bool isVPN;
  final bool isProxy;
  final bool isFromHighRiskCountry;

  const IPAddressAnalysis({
    required this.isVPN,
    required this.isProxy,
    required this.isFromHighRiskCountry,
  });
}

class DeviceValidationResult {
  final bool isNewDevice;
  final bool isVerified;
  final bool hasSecurityConcerns;

  const DeviceValidationResult({
    required this.isNewDevice,
    required this.isVerified,
    required this.hasSecurityConcerns,
  });
}

/// PCI DSS Compliance models

class PCIComplianceResult {
  final PCIComplianceStatus status;
  final List<PCIViolation> violations;
  final List<String> warnings;
  final DateTime timestamp;

  const PCIComplianceResult({
    required this.status,
    required this.violations,
    required this.warnings,
    required this.timestamp,
  });
}

class PCIViolation {
  final String requirement;
  final String description;
  final PCIViolationSeverity severity;

  const PCIViolation({
    required this.requirement,
    required this.description,
    required this.severity,
  });
}

/// Security encryption models

class EncryptionResult {
  final String encryptedData;
  final String algorithm;
  final DateTime timestamp;

  const EncryptionResult({
    required this.encryptedData,
    required this.algorithm,
    required this.timestamp,
  });
}

class DecryptionResult {
  final Map<String, dynamic> decryptedData;
  final bool isValid;
  final String? error;

  const DecryptionResult({
    required this.decryptedData,
    required this.isValid,
    this.error,
  });
}
