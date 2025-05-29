// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compliance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SSMRegistration _$SSMRegistrationFromJson(Map<String, dynamic> json) =>
    SSMRegistration(
      id: json['id'] as String,
      vendorId: json['vendorId'] as String,
      registrationNumber: json['registrationNumber'] as String,
      companyName: json['companyName'] as String,
      registrationType: json['registrationType'] as String,
      registrationDate: DateTime.parse(json['registrationDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      status:
          $enumDecodeNullable(_$ComplianceStatusEnumMap, json['status']) ??
          ComplianceStatus.pending,
      documentUrl: json['documentUrl'] as String?,
      verificationNotes: json['verificationNotes'] as String?,
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
      verifiedBy: json['verifiedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SSMRegistrationToJson(SSMRegistration instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorId': instance.vendorId,
      'registrationNumber': instance.registrationNumber,
      'companyName': instance.companyName,
      'registrationType': instance.registrationType,
      'registrationDate': instance.registrationDate.toIso8601String(),
      'expiryDate': instance.expiryDate.toIso8601String(),
      'status': _$ComplianceStatusEnumMap[instance.status]!,
      'documentUrl': instance.documentUrl,
      'verificationNotes': instance.verificationNotes,
      'verifiedAt': instance.verifiedAt?.toIso8601String(),
      'verifiedBy': instance.verifiedBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$ComplianceStatusEnumMap = {
  ComplianceStatus.pending: 'pending',
  ComplianceStatus.verified: 'verified',
  ComplianceStatus.rejected: 'rejected',
  ComplianceStatus.expired: 'expired',
  ComplianceStatus.suspended: 'suspended',
};

HalalCertification _$HalalCertificationFromJson(Map<String, dynamic> json) =>
    HalalCertification(
      id: json['id'] as String,
      vendorId: json['vendorId'] as String,
      certificateNumber: json['certificateNumber'] as String,
      issuingAuthority: json['issuingAuthority'] as String,
      certificateType: json['certificateType'] as String,
      issueDate: DateTime.parse(json['issueDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      status:
          $enumDecodeNullable(_$ComplianceStatusEnumMap, json['status']) ??
          ComplianceStatus.pending,
      coveredProducts:
          (json['coveredProducts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      documentUrl: json['documentUrl'] as String?,
      verificationNotes: json['verificationNotes'] as String?,
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
      verifiedBy: json['verifiedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$HalalCertificationToJson(HalalCertification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorId': instance.vendorId,
      'certificateNumber': instance.certificateNumber,
      'issuingAuthority': instance.issuingAuthority,
      'certificateType': instance.certificateType,
      'issueDate': instance.issueDate.toIso8601String(),
      'expiryDate': instance.expiryDate.toIso8601String(),
      'status': _$ComplianceStatusEnumMap[instance.status]!,
      'coveredProducts': instance.coveredProducts,
      'documentUrl': instance.documentUrl,
      'verificationNotes': instance.verificationNotes,
      'verifiedAt': instance.verifiedAt?.toIso8601String(),
      'verifiedBy': instance.verifiedBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

SSTRegistration _$SSTRegistrationFromJson(Map<String, dynamic> json) =>
    SSTRegistration(
      id: json['id'] as String,
      vendorId: json['vendorId'] as String,
      sstNumber: json['sstNumber'] as String,
      businessType: json['businessType'] as String,
      annualTurnover: (json['annualTurnover'] as num).toDouble(),
      isRegistered: json['isRegistered'] as bool? ?? false,
      registrationDate: json['registrationDate'] == null
          ? null
          : DateTime.parse(json['registrationDate'] as String),
      status:
          $enumDecodeNullable(_$ComplianceStatusEnumMap, json['status']) ??
          ComplianceStatus.pending,
      documentUrl: json['documentUrl'] as String?,
      verificationNotes: json['verificationNotes'] as String?,
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
      verifiedBy: json['verifiedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SSTRegistrationToJson(SSTRegistration instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorId': instance.vendorId,
      'sstNumber': instance.sstNumber,
      'businessType': instance.businessType,
      'annualTurnover': instance.annualTurnover,
      'isRegistered': instance.isRegistered,
      'registrationDate': instance.registrationDate?.toIso8601String(),
      'status': _$ComplianceStatusEnumMap[instance.status]!,
      'documentUrl': instance.documentUrl,
      'verificationNotes': instance.verificationNotes,
      'verifiedAt': instance.verifiedAt?.toIso8601String(),
      'verifiedBy': instance.verifiedBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

PDPACompliance _$PDPAComplianceFromJson(Map<String, dynamic> json) =>
    PDPACompliance(
      id: json['id'] as String,
      vendorId: json['vendorId'] as String,
      hasPrivacyPolicy: json['hasPrivacyPolicy'] as bool? ?? false,
      hasDataProcessingConsent:
          json['hasDataProcessingConsent'] as bool? ?? false,
      hasDataRetentionPolicy: json['hasDataRetentionPolicy'] as bool? ?? false,
      hasDataBreachProcedure: json['hasDataBreachProcedure'] as bool? ?? false,
      privacyPolicyUrl: json['privacyPolicyUrl'] as String?,
      dataProcessingPurpose: json['dataProcessingPurpose'] as String?,
      dataRetentionPeriodMonths:
          (json['dataRetentionPeriodMonths'] as num?)?.toInt() ?? 24,
      lastAuditDate: DateTime.parse(json['lastAuditDate'] as String),
      nextAuditDate: DateTime.parse(json['nextAuditDate'] as String),
      status:
          $enumDecodeNullable(_$ComplianceStatusEnumMap, json['status']) ??
          ComplianceStatus.pending,
      complianceDocuments:
          (json['complianceDocuments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      verificationNotes: json['verificationNotes'] as String?,
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
      verifiedBy: json['verifiedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$PDPAComplianceToJson(PDPACompliance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vendorId': instance.vendorId,
      'hasPrivacyPolicy': instance.hasPrivacyPolicy,
      'hasDataProcessingConsent': instance.hasDataProcessingConsent,
      'hasDataRetentionPolicy': instance.hasDataRetentionPolicy,
      'hasDataBreachProcedure': instance.hasDataBreachProcedure,
      'privacyPolicyUrl': instance.privacyPolicyUrl,
      'dataProcessingPurpose': instance.dataProcessingPurpose,
      'dataRetentionPeriodMonths': instance.dataRetentionPeriodMonths,
      'lastAuditDate': instance.lastAuditDate.toIso8601String(),
      'nextAuditDate': instance.nextAuditDate.toIso8601String(),
      'status': _$ComplianceStatusEnumMap[instance.status]!,
      'complianceDocuments': instance.complianceDocuments,
      'verificationNotes': instance.verificationNotes,
      'verifiedAt': instance.verifiedAt?.toIso8601String(),
      'verifiedBy': instance.verifiedBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

ComplianceSummary _$ComplianceSummaryFromJson(Map<String, dynamic> json) =>
    ComplianceSummary(
      vendorId: json['vendorId'] as String,
      ssmCompliant: json['ssmCompliant'] as bool? ?? false,
      halalCompliant: json['halalCompliant'] as bool? ?? false,
      sstCompliant: json['sstCompliant'] as bool? ?? false,
      pdpaCompliant: json['pdpaCompliant'] as bool? ?? false,
      totalCertifications: (json['totalCertifications'] as num?)?.toInt() ?? 0,
      expiringSoonCount: (json['expiringSoonCount'] as num?)?.toInt() ?? 0,
      missingCompliances:
          (json['missingCompliances'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      expiringCertifications:
          (json['expiringCertifications'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      complianceScore: (json['complianceScore'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$ComplianceSummaryToJson(ComplianceSummary instance) =>
    <String, dynamic>{
      'vendorId': instance.vendorId,
      'ssmCompliant': instance.ssmCompliant,
      'halalCompliant': instance.halalCompliant,
      'sstCompliant': instance.sstCompliant,
      'pdpaCompliant': instance.pdpaCompliant,
      'totalCertifications': instance.totalCertifications,
      'expiringSoonCount': instance.expiringSoonCount,
      'missingCompliances': instance.missingCompliances,
      'expiringCertifications': instance.expiringCertifications,
      'complianceScore': instance.complianceScore,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
