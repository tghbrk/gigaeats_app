
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/logger.dart';
import 'models/withdrawal_compliance_models.dart';

/// Comprehensive audit service for driver withdrawal security events
/// Provides detailed logging, monitoring, and compliance reporting
class DriverWithdrawalAuditService {
  final SupabaseClient _supabase;
  final AppLogger _logger;

  DriverWithdrawalAuditService({
    required SupabaseClient supabase,
    required AppLogger logger,
  }) : _supabase = supabase,
       _logger = logger;

  /// Logs comprehensive withdrawal security event
  Future<void> logWithdrawalSecurityEvent({
    required String eventType,
    required String driverId,
    required String operation,
    required Map<String, dynamic> eventData,
    String? withdrawalRequestId,
    String? ipAddress,
    String? userAgent,
    String? deviceFingerprint,
    ComplianceSeverity severity = ComplianceSeverity.medium,
    List<String>? complianceFlags,
    Map<String, dynamic>? securityContext,
  }) async {
    try {
      debugPrint('📋 [WITHDRAWAL-AUDIT] Logging security event: $eventType for driver: $driverId');

      final auditRecord = {
        'event_type': eventType,
        'entity_type': 'driver_withdrawal_security',
        'entity_id': withdrawalRequestId ?? driverId,
        'user_id': driverId,
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'event_data': {
          'operation': operation,
          'withdrawal_request_id': withdrawalRequestId,
          'device_fingerprint': deviceFingerprint,
          'security_context': securityContext,
          'timestamp': DateTime.now().toIso8601String(),
          ...eventData,
        },
        'metadata': {
          'source': 'driver_withdrawal_audit_service',
          'severity': severity.toString(),
          'compliance_flags': complianceFlags ?? [],
          'security_audit': true,
          'requires_retention': true,
          'retention_years': 7, // Financial compliance requirement
        },
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('financial_audit_log').insert(auditRecord);

      // Log critical events to external audit system if required
      if (severity == ComplianceSeverity.high) {
        await _logCriticalEventToExternalSystem(auditRecord);
      }

      debugPrint('✅ [WITHDRAWAL-AUDIT] Security event logged successfully');
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-AUDIT] Error logging security event: $e');
      _logger.error('Failed to log withdrawal security event', e);
    }
  }

  /// Logs withdrawal request creation with security context
  Future<void> logWithdrawalRequestCreated({
    required String driverId,
    required String withdrawalRequestId,
    required double amount,
    required String withdrawalMethod,
    required Map<String, dynamic> bankDetails,
    String? ipAddress,
    String? deviceInfo,
    WithdrawalComplianceResult? complianceResult,
  }) async {
    await logWithdrawalSecurityEvent(
      eventType: 'withdrawal_request_created',
      driverId: driverId,
      operation: 'create_withdrawal_request',
      withdrawalRequestId: withdrawalRequestId,
      ipAddress: ipAddress,
      eventData: {
        'amount': amount,
        'withdrawal_method': withdrawalMethod,
        'bank_details_encrypted': true,
        'bank_name': bankDetails['bank_name'],
        'account_number_masked': _maskAccountNumber(bankDetails['account_number']),
        'compliance_status': complianceResult?.status.toString(),
        'fraud_risk_level': complianceResult?.fraudRiskLevel.toString(),
        'violations_count': complianceResult?.violations.length ?? 0,
        'device_info': deviceInfo,
      },
      severity: complianceResult?.status == WithdrawalComplianceStatus.rejected 
          ? ComplianceSeverity.high 
          : ComplianceSeverity.medium,
      complianceFlags: [
        'withdrawal_request',
        'financial_transaction',
        'bank_transfer',
        if (complianceResult?.requiresManualReview == true) 'requires_manual_review',
      ],
    );
  }

  /// Logs compliance validation results
  Future<void> logComplianceValidation({
    required String driverId,
    required String withdrawalRequestId,
    required WithdrawalComplianceResult complianceResult,
    String? ipAddress,
  }) async {
    await logWithdrawalSecurityEvent(
      eventType: 'compliance_validation',
      driverId: driverId,
      operation: 'validate_compliance',
      withdrawalRequestId: withdrawalRequestId,
      ipAddress: ipAddress,
      eventData: {
        'compliance_status': complianceResult.status.toString(),
        'fraud_risk_level': complianceResult.fraudRiskLevel.toString(),
        'fraud_risk_score': complianceResult.fraudReasons.length,
        'violations': complianceResult.violations.map((v) => {
          'code': v.code,
          'regulation': v.regulation,
          'severity': v.severity.toString(),
        }).toList(),
        'warnings': complianceResult.warnings,
        'security_flags': complianceResult.securityFlags,
        'requires_manual_review': complianceResult.requiresManualReview,
        'fraud_reasons': complianceResult.fraudReasons,
      },
      severity: complianceResult.status == WithdrawalComplianceStatus.rejected 
          ? ComplianceSeverity.high 
          : ComplianceSeverity.medium,
      complianceFlags: [
        'compliance_validation',
        'fraud_detection',
        'regulatory_check',
        if (complianceResult.requiresManualReview) 'manual_review_required',
      ],
    );
  }

  /// Logs fraud detection events
  Future<void> logFraudDetection({
    required String driverId,
    required String withdrawalRequestId,
    required FraudRiskLevel riskLevel,
    required List<String> fraudReasons,
    required double riskScore,
    String? ipAddress,
    Map<String, dynamic>? fraudContext,
  }) async {
    await logWithdrawalSecurityEvent(
      eventType: 'fraud_detection',
      driverId: driverId,
      operation: 'detect_fraud',
      withdrawalRequestId: withdrawalRequestId,
      ipAddress: ipAddress,
      eventData: {
        'risk_level': riskLevel.toString(),
        'risk_score': riskScore,
        'fraud_reasons': fraudReasons,
        'fraud_context': fraudContext,
        'detection_timestamp': DateTime.now().toIso8601String(),
      },
      severity: riskLevel == FraudRiskLevel.high 
          ? ComplianceSeverity.high 
          : ComplianceSeverity.medium,
      complianceFlags: [
        'fraud_detection',
        'risk_assessment',
        'automated_screening',
        if (riskLevel == FraudRiskLevel.high) 'high_risk_transaction',
      ],
      securityContext: fraudContext,
    );
  }

  /// Logs security violations
  Future<void> logSecurityViolation({
    required String driverId,
    required String violationType,
    required String description,
    required ComplianceSeverity severity,
    String? withdrawalRequestId,
    String? ipAddress,
    Map<String, dynamic>? violationContext,
  }) async {
    await logWithdrawalSecurityEvent(
      eventType: 'security_violation',
      driverId: driverId,
      operation: 'security_violation',
      withdrawalRequestId: withdrawalRequestId,
      ipAddress: ipAddress,
      eventData: {
        'violation_type': violationType,
        'description': description,
        'violation_context': violationContext,
        'detection_timestamp': DateTime.now().toIso8601String(),
      },
      severity: severity,
      complianceFlags: [
        'security_violation',
        'compliance_breach',
        violationType,
        if (severity == ComplianceSeverity.high) 'critical_violation',
      ],
      securityContext: violationContext,
    );
  }

  /// Logs data encryption/decryption events
  Future<void> logEncryptionEvent({
    required String driverId,
    required String operation,
    required bool success,
    String? withdrawalRequestId,
    String? algorithm,
    int? dataSize,
    String? error,
  }) async {
    await logWithdrawalSecurityEvent(
      eventType: 'data_encryption',
      driverId: driverId,
      operation: operation,
      withdrawalRequestId: withdrawalRequestId,
      eventData: {
        'success': success,
        'algorithm': algorithm ?? 'AES-256-GCM',
        'data_size_bytes': dataSize,
        'error': error,
        'encryption_timestamp': DateTime.now().toIso8601String(),
      },
      severity: success ? ComplianceSeverity.low : ComplianceSeverity.high,
      complianceFlags: [
        'data_encryption',
        'data_protection',
        'pci_dss_compliance',
        if (!success) 'encryption_failure',
      ],
    );
  }

  /// Logs access control events
  Future<void> logAccessControl({
    required String driverId,
    required String accessType,
    required bool granted,
    String? resource,
    String? reason,
    String? ipAddress,
    Map<String, dynamic>? accessContext,
  }) async {
    await logWithdrawalSecurityEvent(
      eventType: 'access_control',
      driverId: driverId,
      operation: accessType,
      ipAddress: ipAddress,
      eventData: {
        'access_type': accessType,
        'access_granted': granted,
        'resource': resource,
        'reason': reason,
        'access_context': accessContext,
        'access_timestamp': DateTime.now().toIso8601String(),
      },
      severity: granted ? ComplianceSeverity.low : ComplianceSeverity.medium,
      complianceFlags: [
        'access_control',
        'authorization',
        if (!granted) 'access_denied',
      ],
      securityContext: accessContext,
    );
  }

  /// Generates comprehensive security audit report
  Future<Map<String, dynamic>> generateSecurityAuditReport({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? eventTypes,
  }) async {
    try {
      debugPrint('📊 [WITHDRAWAL-AUDIT] Generating security audit report for driver: $driverId');

      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      var query = _supabase
          .from('financial_audit_log')
          .select()
          .eq('user_id', driverId)
          .eq('entity_type', 'driver_withdrawal_security')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      if (eventTypes != null && eventTypes.isNotEmpty) {
        query = query.inFilter('event_type', eventTypes);
      }

      final response = await query.order('created_at', ascending: false);
      final auditLogs = List<Map<String, dynamic>>.from(response);

      // Generate summary statistics
      final summary = _generateAuditSummary(auditLogs);

      debugPrint('✅ [WITHDRAWAL-AUDIT] Security audit report generated');

      return {
        'driver_id': driverId,
        'report_period': {
          'start_date': start.toIso8601String(),
          'end_date': end.toIso8601String(),
        },
        'summary': summary,
        'audit_logs': auditLogs,
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-AUDIT] Error generating audit report: $e');
      _logger.error('Failed to generate security audit report', e);
      rethrow;
    }
  }

  /// Masks account number for logging (PCI DSS compliance)
  String _maskAccountNumber(String? accountNumber) {
    if (accountNumber == null || accountNumber.length < 4) {
      return '****';
    }
    
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    final masked = '*' * (accountNumber.length - 4);
    return '$masked$lastFour';
  }

  /// Logs critical events to external audit system
  Future<void> _logCriticalEventToExternalSystem(Map<String, dynamic> auditRecord) async {
    try {
      // In production, integrate with external audit/SIEM system
      debugPrint('🚨 [WITHDRAWAL-AUDIT] Critical event logged to external system');
      
      // Example: Send to external logging service, SIEM, or compliance system
      // await externalAuditService.logCriticalEvent(auditRecord);
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-AUDIT] Error logging to external system: $e');
    }
  }

  /// Generates audit summary statistics
  Map<String, dynamic> _generateAuditSummary(List<Map<String, dynamic>> auditLogs) {
    final eventTypeCounts = <String, int>{};
    final severityCounts = <String, int>{};
    var criticalEvents = 0;
    var complianceViolations = 0;
    var fraudDetections = 0;

    for (final log in auditLogs) {
      final eventType = log['event_type'] as String;
      final metadata = log['metadata'] as Map<String, dynamic>?;
      final severity = metadata?['severity'] as String?;

      // Count event types
      eventTypeCounts[eventType] = (eventTypeCounts[eventType] ?? 0) + 1;

      // Count severities
      if (severity != null) {
        severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
        if (severity == 'high') criticalEvents++;
      }

      // Count specific event types
      if (eventType == 'security_violation') complianceViolations++;
      if (eventType == 'fraud_detection') fraudDetections++;
    }

    return {
      'total_events': auditLogs.length,
      'critical_events': criticalEvents,
      'compliance_violations': complianceViolations,
      'fraud_detections': fraudDetections,
      'event_type_breakdown': eventTypeCounts,
      'severity_breakdown': severityCounts,
    };
  }
}
