import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'compliance.g.dart';

enum ComplianceStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('verified')
  verified,
  @JsonValue('rejected')
  rejected,
  @JsonValue('expired')
  expired,
  @JsonValue('suspended')
  suspended,
}

enum CertificationType {
  @JsonValue('halal')
  halal,
  @JsonValue('haccp')
  haccp,
  @JsonValue('iso22000')
  iso22000,
  @JsonValue('mesti')
  mesti,
  @JsonValue('organic')
  organic,
  @JsonValue('gmp')
  gmp,
}

@JsonSerializable()
class SSMRegistration extends Equatable {
  final String id;
  final String vendorId;
  final String registrationNumber;
  final String companyName;
  final String registrationType; // 'sdn_bhd', 'enterprise', 'partnership', etc.
  final DateTime registrationDate;
  final DateTime expiryDate;
  final ComplianceStatus status;
  final String? documentUrl;
  final String? verificationNotes;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SSMRegistration({
    required this.id,
    required this.vendorId,
    required this.registrationNumber,
    required this.companyName,
    required this.registrationType,
    required this.registrationDate,
    required this.expiryDate,
    this.status = ComplianceStatus.pending,
    this.documentUrl,
    this.verificationNotes,
    this.verifiedAt,
    this.verifiedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SSMRegistration.fromJson(Map<String, dynamic> json) => _$SSMRegistrationFromJson(json);
  Map<String, dynamic> toJson() => _$SSMRegistrationToJson(this);

  @override
  List<Object?> get props => [
        id,
        vendorId,
        registrationNumber,
        companyName,
        registrationType,
        registrationDate,
        expiryDate,
        status,
        documentUrl,
        verificationNotes,
        verifiedAt,
        verifiedBy,
        createdAt,
        updatedAt,
      ];

  bool get isValid => status == ComplianceStatus.verified && expiryDate.isAfter(DateTime.now());
  bool get isExpiringSoon => expiryDate.difference(DateTime.now()).inDays <= 30;
}

@JsonSerializable()
class HalalCertification extends Equatable {
  final String id;
  final String vendorId;
  final String certificateNumber;
  final String issuingAuthority; // 'jakim', 'jain', 'jais', etc.
  final String certificateType; // 'premise', 'product', 'slaughter_house'
  final DateTime issueDate;
  final DateTime expiryDate;
  final ComplianceStatus status;
  final List<String> coveredProducts;
  final String? documentUrl;
  final String? verificationNotes;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HalalCertification({
    required this.id,
    required this.vendorId,
    required this.certificateNumber,
    required this.issuingAuthority,
    required this.certificateType,
    required this.issueDate,
    required this.expiryDate,
    this.status = ComplianceStatus.pending,
    this.coveredProducts = const [],
    this.documentUrl,
    this.verificationNotes,
    this.verifiedAt,
    this.verifiedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HalalCertification.fromJson(Map<String, dynamic> json) => _$HalalCertificationFromJson(json);
  Map<String, dynamic> toJson() => _$HalalCertificationToJson(this);

  @override
  List<Object?> get props => [
        id,
        vendorId,
        certificateNumber,
        issuingAuthority,
        certificateType,
        issueDate,
        expiryDate,
        status,
        coveredProducts,
        documentUrl,
        verificationNotes,
        verifiedAt,
        verifiedBy,
        createdAt,
        updatedAt,
      ];

  bool get isValid => status == ComplianceStatus.verified && expiryDate.isAfter(DateTime.now());
  bool get isExpiringSoon => expiryDate.difference(DateTime.now()).inDays <= 60;
}

@JsonSerializable()
class SSTRegistration extends Equatable {
  final String id;
  final String vendorId;
  final String sstNumber;
  final String businessType;
  final double annualTurnover;
  final bool isRegistered;
  final DateTime? registrationDate;
  final ComplianceStatus status;
  final String? documentUrl;
  final String? verificationNotes;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SSTRegistration({
    required this.id,
    required this.vendorId,
    required this.sstNumber,
    required this.businessType,
    required this.annualTurnover,
    this.isRegistered = false,
    this.registrationDate,
    this.status = ComplianceStatus.pending,
    this.documentUrl,
    this.verificationNotes,
    this.verifiedAt,
    this.verifiedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SSTRegistration.fromJson(Map<String, dynamic> json) => _$SSTRegistrationFromJson(json);
  Map<String, dynamic> toJson() => _$SSTRegistrationToJson(this);

  @override
  List<Object?> get props => [
        id,
        vendorId,
        sstNumber,
        businessType,
        annualTurnover,
        isRegistered,
        registrationDate,
        status,
        documentUrl,
        verificationNotes,
        verifiedAt,
        verifiedBy,
        createdAt,
        updatedAt,
      ];

  // Check if vendor needs to register for SST (threshold: RM 500,000)
  bool get requiresSST => annualTurnover >= 500000;
  bool get isCompliant => !requiresSST || (isRegistered && status == ComplianceStatus.verified);
}

@JsonSerializable()
class PDPACompliance extends Equatable {
  final String id;
  final String vendorId;
  final bool hasPrivacyPolicy;
  final bool hasDataProcessingConsent;
  final bool hasDataRetentionPolicy;
  final bool hasDataBreachProcedure;
  final String? privacyPolicyUrl;
  final String? dataProcessingPurpose;
  final int dataRetentionPeriodMonths;
  final DateTime lastAuditDate;
  final DateTime nextAuditDate;
  final ComplianceStatus status;
  final List<String> complianceDocuments;
  final String? verificationNotes;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PDPACompliance({
    required this.id,
    required this.vendorId,
    this.hasPrivacyPolicy = false,
    this.hasDataProcessingConsent = false,
    this.hasDataRetentionPolicy = false,
    this.hasDataBreachProcedure = false,
    this.privacyPolicyUrl,
    this.dataProcessingPurpose,
    this.dataRetentionPeriodMonths = 24,
    required this.lastAuditDate,
    required this.nextAuditDate,
    this.status = ComplianceStatus.pending,
    this.complianceDocuments = const [],
    this.verificationNotes,
    this.verifiedAt,
    this.verifiedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PDPACompliance.fromJson(Map<String, dynamic> json) => _$PDPAComplianceFromJson(json);
  Map<String, dynamic> toJson() => _$PDPAComplianceToJson(this);

  @override
  List<Object?> get props => [
        id,
        vendorId,
        hasPrivacyPolicy,
        hasDataProcessingConsent,
        hasDataRetentionPolicy,
        hasDataBreachProcedure,
        privacyPolicyUrl,
        dataProcessingPurpose,
        dataRetentionPeriodMonths,
        lastAuditDate,
        nextAuditDate,
        status,
        complianceDocuments,
        verificationNotes,
        verifiedAt,
        verifiedBy,
        createdAt,
        updatedAt,
      ];

  bool get isCompliant => 
      hasPrivacyPolicy && 
      hasDataProcessingConsent && 
      hasDataRetentionPolicy && 
      hasDataBreachProcedure &&
      status == ComplianceStatus.verified;

  bool get needsAudit => nextAuditDate.isBefore(DateTime.now());
}

@JsonSerializable()
class ComplianceSummary extends Equatable {
  final String vendorId;
  final bool ssmCompliant;
  final bool halalCompliant;
  final bool sstCompliant;
  final bool pdpaCompliant;
  final int totalCertifications;
  final int expiringSoonCount;
  final List<String> missingCompliances;
  final List<String> expiringCertifications;
  final double complianceScore; // 0.0 to 1.0
  final DateTime lastUpdated;

  const ComplianceSummary({
    required this.vendorId,
    this.ssmCompliant = false,
    this.halalCompliant = false,
    this.sstCompliant = false,
    this.pdpaCompliant = false,
    this.totalCertifications = 0,
    this.expiringSoonCount = 0,
    this.missingCompliances = const [],
    this.expiringCertifications = const [],
    this.complianceScore = 0.0,
    required this.lastUpdated,
  });

  factory ComplianceSummary.fromJson(Map<String, dynamic> json) => _$ComplianceSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$ComplianceSummaryToJson(this);

  @override
  List<Object?> get props => [
        vendorId,
        ssmCompliant,
        halalCompliant,
        sstCompliant,
        pdpaCompliant,
        totalCertifications,
        expiringSoonCount,
        missingCompliances,
        expiringCertifications,
        complianceScore,
        lastUpdated,
      ];

  bool get isFullyCompliant => 
      ssmCompliant && 
      sstCompliant && 
      pdpaCompliant && 
      missingCompliances.isEmpty;

  String get complianceGrade {
    if (complianceScore >= 0.9) return 'A';
    if (complianceScore >= 0.8) return 'B';
    if (complianceScore >= 0.7) return 'C';
    if (complianceScore >= 0.6) return 'D';
    return 'F';
  }
}
