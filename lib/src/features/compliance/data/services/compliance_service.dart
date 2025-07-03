import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/compliance.dart';

class ComplianceService {
  static final List<SSMRegistration> _ssmRegistrations = [];
  static final List<HalalCertification> _halalCertifications = [];
  static final List<SSTRegistration> _sstRegistrations = [];
  static final List<PDPACompliance> _pdpaCompliances = [];
  static final _uuid = const Uuid();

  // SSM Registration Methods
  Future<SSMRegistration> createSSMRegistration({
    required String vendorId,
    required String registrationNumber,
    required String companyName,
    required String registrationType,
    required DateTime registrationDate,
    required DateTime expiryDate,
    String? documentUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API delay

    final registration = SSMRegistration(
      id: _uuid.v4(),
      vendorId: vendorId,
      registrationNumber: registrationNumber,
      companyName: companyName,
      registrationType: registrationType,
      registrationDate: registrationDate,
      expiryDate: expiryDate,
      documentUrl: documentUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _ssmRegistrations.add(registration);
    return registration;
  }

  Future<SSMRegistration?> getVendorSSMRegistration(String vendorId) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate API delay

    try {
      return _ssmRegistrations.firstWhere((reg) => reg.vendorId == vendorId);
    } catch (e) {
      return null;
    }
  }

  Future<SSMRegistration> verifySSMRegistration(
    String registrationId,
    ComplianceStatus status, {
    String? verificationNotes,
    String? verifiedBy,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400)); // Simulate API delay

    final index = _ssmRegistrations.indexWhere((reg) => reg.id == registrationId);
    if (index == -1) {
      throw Exception('SSM Registration not found');
    }

    final updated = SSMRegistration(
      id: _ssmRegistrations[index].id,
      vendorId: _ssmRegistrations[index].vendorId,
      registrationNumber: _ssmRegistrations[index].registrationNumber,
      companyName: _ssmRegistrations[index].companyName,
      registrationType: _ssmRegistrations[index].registrationType,
      registrationDate: _ssmRegistrations[index].registrationDate,
      expiryDate: _ssmRegistrations[index].expiryDate,
      status: status,
      documentUrl: _ssmRegistrations[index].documentUrl,
      verificationNotes: verificationNotes,
      verifiedAt: DateTime.now(),
      verifiedBy: verifiedBy,
      createdAt: _ssmRegistrations[index].createdAt,
      updatedAt: DateTime.now(),
    );

    _ssmRegistrations[index] = updated;
    return updated;
  }

  // Halal Certification Methods
  Future<HalalCertification> createHalalCertification({
    required String vendorId,
    required String certificateNumber,
    required String issuingAuthority,
    required String certificateType,
    required DateTime issueDate,
    required DateTime expiryDate,
    List<String>? coveredProducts,
    String? documentUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API delay

    final certification = HalalCertification(
      id: _uuid.v4(),
      vendorId: vendorId,
      certificateNumber: certificateNumber,
      issuingAuthority: issuingAuthority,
      certificateType: certificateType,
      issueDate: issueDate,
      expiryDate: expiryDate,
      coveredProducts: coveredProducts ?? [],
      documentUrl: documentUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _halalCertifications.add(certification);
    return certification;
  }

  Future<List<HalalCertification>> getVendorHalalCertifications(String vendorId) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate API delay

    return _halalCertifications.where((cert) => cert.vendorId == vendorId).toList();
  }

  Future<HalalCertification> verifyHalalCertification(
    String certificationId,
    ComplianceStatus status, {
    String? verificationNotes,
    String? verifiedBy,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400)); // Simulate API delay

    final index = _halalCertifications.indexWhere((cert) => cert.id == certificationId);
    if (index == -1) {
      throw Exception('Halal Certification not found');
    }

    final updated = HalalCertification(
      id: _halalCertifications[index].id,
      vendorId: _halalCertifications[index].vendorId,
      certificateNumber: _halalCertifications[index].certificateNumber,
      issuingAuthority: _halalCertifications[index].issuingAuthority,
      certificateType: _halalCertifications[index].certificateType,
      issueDate: _halalCertifications[index].issueDate,
      expiryDate: _halalCertifications[index].expiryDate,
      status: status,
      coveredProducts: _halalCertifications[index].coveredProducts,
      documentUrl: _halalCertifications[index].documentUrl,
      verificationNotes: verificationNotes,
      verifiedAt: DateTime.now(),
      verifiedBy: verifiedBy,
      createdAt: _halalCertifications[index].createdAt,
      updatedAt: DateTime.now(),
    );

    _halalCertifications[index] = updated;
    return updated;
  }

  // SST Registration Methods
  Future<SSTRegistration> createSSTRegistration({
    required String vendorId,
    required String sstNumber,
    required String businessType,
    required double annualTurnover,
    bool isRegistered = false,
    DateTime? registrationDate,
    String? documentUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API delay

    final registration = SSTRegistration(
      id: _uuid.v4(),
      vendorId: vendorId,
      sstNumber: sstNumber,
      businessType: businessType,
      annualTurnover: annualTurnover,
      isRegistered: isRegistered,
      registrationDate: registrationDate,
      documentUrl: documentUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _sstRegistrations.add(registration);
    return registration;
  }

  Future<SSTRegistration?> getVendorSSTRegistration(String vendorId) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate API delay

    try {
      return _sstRegistrations.firstWhere((reg) => reg.vendorId == vendorId);
    } catch (e) {
      return null;
    }
  }

  // PDPA Compliance Methods
  Future<PDPACompliance> createPDPACompliance({
    required String vendorId,
    bool hasPrivacyPolicy = false,
    bool hasDataProcessingConsent = false,
    bool hasDataRetentionPolicy = false,
    bool hasDataBreachProcedure = false,
    String? privacyPolicyUrl,
    String? dataProcessingPurpose,
    int dataRetentionPeriodMonths = 24,
    List<String>? complianceDocuments,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API delay

    final now = DateTime.now();
    final compliance = PDPACompliance(
      id: _uuid.v4(),
      vendorId: vendorId,
      hasPrivacyPolicy: hasPrivacyPolicy,
      hasDataProcessingConsent: hasDataProcessingConsent,
      hasDataRetentionPolicy: hasDataRetentionPolicy,
      hasDataBreachProcedure: hasDataBreachProcedure,
      privacyPolicyUrl: privacyPolicyUrl,
      dataProcessingPurpose: dataProcessingPurpose,
      dataRetentionPeriodMonths: dataRetentionPeriodMonths,
      lastAuditDate: now,
      nextAuditDate: now.add(const Duration(days: 365)),
      complianceDocuments: complianceDocuments ?? [],
      createdAt: now,
      updatedAt: now,
    );

    _pdpaCompliances.add(compliance);
    return compliance;
  }

  Future<PDPACompliance?> getVendorPDPACompliance(String vendorId) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate API delay

    try {
      return _pdpaCompliances.firstWhere((comp) => comp.vendorId == vendorId);
    } catch (e) {
      return null;
    }
  }

  // Compliance Summary
  Future<ComplianceSummary> getVendorComplianceSummary(String vendorId) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay

    final ssmReg = await getVendorSSMRegistration(vendorId);
    final halalCerts = await getVendorHalalCertifications(vendorId);
    final sstReg = await getVendorSSTRegistration(vendorId);
    final pdpaComp = await getVendorPDPACompliance(vendorId);

    final ssmCompliant = ssmReg?.isValid ?? false;
    final halalCompliant = halalCerts.any((cert) => cert.isValid);
    final sstCompliant = sstReg?.isCompliant ?? false;
    final pdpaCompliant = pdpaComp?.isCompliant ?? false;

    final totalCertifications = (ssmReg != null ? 1 : 0) + 
                               halalCerts.length + 
                               (sstReg != null ? 1 : 0) + 
                               (pdpaComp != null ? 1 : 0);

    final expiringSoon = <String>[];
    if (ssmReg?.isExpiringSoon == true) expiringSoon.add('SSM Registration');
    for (final cert in halalCerts) {
      if (cert.isExpiringSoon) expiringSoon.add('Halal Certificate ${cert.certificateNumber}');
    }

    final missingCompliances = <String>[];
    if (!ssmCompliant) missingCompliances.add('SSM Registration');
    if (!sstCompliant && (sstReg?.requiresSST ?? false)) missingCompliances.add('SST Registration');
    if (!pdpaCompliant) missingCompliances.add('PDPA Compliance');

    // Calculate compliance score
    double score = 0.0;
    int totalChecks = 3; // SSM, SST (if required), PDPA
    
    if (ssmCompliant) score += 1.0;
    if (sstCompliant || !(sstReg?.requiresSST ?? false)) score += 1.0;
    if (pdpaCompliant) score += 1.0;
    
    // Bonus for halal certification
    if (halalCompliant) {
      score += 0.5;
      totalChecks = 4;
    }

    final complianceScore = totalChecks > 0 ? score / totalChecks : 0.0;

    return ComplianceSummary(
      vendorId: vendorId,
      ssmCompliant: ssmCompliant,
      halalCompliant: halalCompliant,
      sstCompliant: sstCompliant,
      pdpaCompliant: pdpaCompliant,
      totalCertifications: totalCertifications,
      expiringSoonCount: expiringSoon.length,
      missingCompliances: missingCompliances,
      expiringCertifications: expiringSoon,
      complianceScore: complianceScore.clamp(0.0, 1.0),
      lastUpdated: DateTime.now(),
    );
  }

  // Get all vendors with compliance issues
  Future<List<String>> getVendorsWithComplianceIssues() async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate API delay

    final vendorIds = <String>{};
    
    // Add vendors with expired/expiring SSM
    for (final reg in _ssmRegistrations) {
      if (!reg.isValid || reg.isExpiringSoon) {
        vendorIds.add(reg.vendorId);
      }
    }

    // Add vendors with expired/expiring Halal certs
    for (final cert in _halalCertifications) {
      if (!cert.isValid || cert.isExpiringSoon) {
        vendorIds.add(cert.vendorId);
      }
    }

    // Add vendors with SST compliance issues
    for (final reg in _sstRegistrations) {
      if (!reg.isCompliant) {
        vendorIds.add(reg.vendorId);
      }
    }

    // Add vendors with PDPA compliance issues
    for (final comp in _pdpaCompliances) {
      if (!comp.isCompliant || comp.needsAudit) {
        vendorIds.add(comp.vendorId);
      }
    }

    return vendorIds.toList();
  }

  // Generate sample compliance data for testing
  Future<void> generateSampleComplianceData(String vendorId) async {
    final random = Random();
    final now = DateTime.now();

    // Create SSM Registration
    await createSSMRegistration(
      vendorId: vendorId,
      registrationNumber: 'SSM${random.nextInt(999999).toString().padLeft(6, '0')}',
      companyName: 'Test Company Sdn Bhd',
      registrationType: 'sdn_bhd',
      registrationDate: now.subtract(Duration(days: random.nextInt(1000) + 365)),
      expiryDate: now.add(Duration(days: random.nextInt(365) + 30)),
    );

    // Create Halal Certification (50% chance)
    if (random.nextBool()) {
      await createHalalCertification(
        vendorId: vendorId,
        certificateNumber: 'JAKIM${random.nextInt(99999).toString().padLeft(5, '0')}',
        issuingAuthority: 'jakim',
        certificateType: 'premise',
        issueDate: now.subtract(Duration(days: random.nextInt(365))),
        expiryDate: now.add(Duration(days: random.nextInt(730) + 30)),
        coveredProducts: ['All food products'],
      );
    }

    // Create SST Registration
    final annualTurnover = 100000.0 + random.nextDouble() * 1000000.0;
    await createSSTRegistration(
      vendorId: vendorId,
      sstNumber: 'SST${random.nextInt(999999).toString().padLeft(6, '0')}',
      businessType: 'Food & Beverage',
      annualTurnover: annualTurnover,
      isRegistered: annualTurnover >= 500000,
      registrationDate: annualTurnover >= 500000 ? now.subtract(Duration(days: random.nextInt(365))) : null,
    );

    // Create PDPA Compliance
    await createPDPACompliance(
      vendorId: vendorId,
      hasPrivacyPolicy: random.nextBool(),
      hasDataProcessingConsent: random.nextBool(),
      hasDataRetentionPolicy: random.nextBool(),
      hasDataBreachProcedure: random.nextBool(),
      dataProcessingPurpose: 'Customer order processing and delivery',
    );
  }
}
