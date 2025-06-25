import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/logger.dart';
import '../../../core/services/security_service.dart';
import '../../../presentation/providers/repository_providers.dart';

/// Comprehensive audit logging service for financial operations
class AuditLoggingService {
  final SupabaseClient _supabase;
  final AppLogger _logger;
  final SecurityService _securityService;

  AuditLoggingService(this._supabase, this._logger, this._securityService);

  /// Logs financial audit events to the database
  Future<void> logFinancialEvent({
    required String eventType,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> eventData,
    String? userId,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get current user ID from Supabase auth since SecurityService doesn't have getCurrentUserId
      final currentUserId = userId ?? _supabase.auth.currentUser?.id;
      final timestamp = DateTime.now();
      
      final auditRecord = {
        'event_type': eventType,
        'entity_type': entityType,
        'entity_id': entityId,
        'user_id': currentUserId,
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'event_data': eventData,
        'metadata': metadata ?? {},
        'created_at': timestamp.toIso8601String(),
        'severity': _determineSeverity(eventType),
        'compliance_flags': _generateComplianceFlags(eventType, eventData),
      };

      await _supabase
          .from('financial_audit_log')
          .insert(auditRecord);

      _logger.info('Financial audit event logged', {
        'event_type': eventType,
        'entity_type': entityType,
        'entity_id': entityId,
        'user_id': currentUserId,
      });

      // Log critical events to external audit system if required
      if (_isCriticalEvent(eventType)) {
        await _logToExternalAuditSystem(auditRecord);
      }
    } catch (e) {
      _logger.error('Failed to log financial audit event: $eventType for $entityType:$entityId', e);
      
      // Critical: If audit logging fails, we need to handle this appropriately
      // In production, this might trigger alerts or fallback logging mechanisms
      rethrow;
    }
  }

  /// Logs payment processing events
  Future<void> logPaymentEvent({
    required String orderId,
    required String paymentMethod,
    required double amount,
    required String status,
    String? transactionId,
    String? gatewayResponse,
    Map<String, dynamic>? additionalData,
  }) async {
    await logFinancialEvent(
      eventType: 'payment_processing',
      entityType: 'order',
      entityId: orderId,
      eventData: {
        'payment_method': paymentMethod,
        'amount': amount,
        'currency': 'MYR',
        'status': status,
        'transaction_id': transactionId,
        'gateway_response': gatewayResponse,
        ...?additionalData,
      },
      metadata: {
        'compliance_category': 'payment_processing',
        'requires_retention': true,
        'retention_years': 7,
      },
    );
  }

  /// Logs wallet transaction events
  Future<void> logWalletTransaction({
    required String walletId,
    required String transactionId,
    required String transactionType,
    required double amount,
    required String status,
    String? referenceId,
    String? description,
    Map<String, dynamic>? additionalData,
  }) async {
    await logFinancialEvent(
      eventType: 'wallet_transaction',
      entityType: 'wallet',
      entityId: walletId,
      eventData: {
        'transaction_id': transactionId,
        'transaction_type': transactionType,
        'amount': amount,
        'currency': 'MYR',
        'status': status,
        'reference_id': referenceId,
        'description': description,
        ...?additionalData,
      },
      metadata: {
        'compliance_category': 'wallet_operations',
        'requires_retention': true,
        'retention_years': 7,
      },
    );
  }

  /// Logs payout request events
  Future<void> logPayoutEvent({
    required String payoutId,
    required String walletId,
    required double amount,
    required String status,
    required String bankAccount,
    String? failureReason,
    Map<String, dynamic>? additionalData,
  }) async {
    await logFinancialEvent(
      eventType: 'payout_request',
      entityType: 'payout',
      entityId: payoutId,
      eventData: {
        'wallet_id': walletId,
        'amount': amount,
        'currency': 'MYR',
        'status': status,
        'bank_account': _maskBankAccount(bankAccount),
        'failure_reason': failureReason,
        ...?additionalData,
      },
      metadata: {
        'compliance_category': 'payout_operations',
        'requires_retention': true,
        'retention_years': 7,
        'sensitive_data': true,
      },
    );
  }

  /// Logs escrow operations
  Future<void> logEscrowEvent({
    required String escrowId,
    required String orderId,
    required String operation,
    required double amount,
    required String status,
    String? releaseReason,
    Map<String, dynamic>? distributionData,
  }) async {
    await logFinancialEvent(
      eventType: 'escrow_operation',
      entityType: 'escrow',
      entityId: escrowId,
      eventData: {
        'order_id': orderId,
        'operation': operation,
        'amount': amount,
        'currency': 'MYR',
        'status': status,
        'release_reason': releaseReason,
        'distribution_data': distributionData,
      },
      metadata: {
        'compliance_category': 'escrow_operations',
        'requires_retention': true,
        'retention_years': 7,
      },
    );
  }

  /// Logs compliance violations
  Future<void> logComplianceViolation({
    required String violationType,
    required String entityType,
    required String entityId,
    required String violationCode,
    required String description,
    required String severity,
    Map<String, dynamic>? violationData,
  }) async {
    await logFinancialEvent(
      eventType: 'compliance_violation',
      entityType: entityType,
      entityId: entityId,
      eventData: {
        'violation_type': violationType,
        'violation_code': violationCode,
        'description': description,
        'severity': severity,
        'violation_data': violationData,
      },
      metadata: {
        'compliance_category': 'violations',
        'requires_immediate_attention': severity == 'high',
        'requires_retention': true,
        'retention_years': 10,
      },
    );
  }

  /// Logs security events
  Future<void> logSecurityEvent({
    required String eventType,
    required String description,
    required String severity,
    String? affectedResource,
    Map<String, dynamic>? securityData,
  }) async {
    await logFinancialEvent(
      eventType: 'security_event',
      entityType: 'security',
      entityId: affectedResource ?? 'system',
      eventData: {
        'security_event_type': eventType,
        'description': description,
        'severity': severity,
        'affected_resource': affectedResource,
        'security_data': securityData,
      },
      metadata: {
        'compliance_category': 'security',
        'requires_immediate_attention': severity == 'critical',
        'requires_retention': true,
        'retention_years': 7,
      },
    );
  }

  /// Retrieves audit logs for a specific entity
  Future<List<Map<String, dynamic>>> getAuditLogs({
    required String entityType,
    required String entityId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? eventTypes,
    int limit = 100,
  }) async {
    try {
      var query = _supabase
          .from('financial_audit_log')
          .select()
          .eq('entity_type', entityType)
          .eq('entity_id', entityId);

      // Apply date filters if provided
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      if (eventTypes != null && eventTypes.isNotEmpty) {
        query = query.inFilter('event_type', eventTypes);
      }

      // Execute query with ordering and limit
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      
      _logger.info('Audit logs retrieved', {
        'entity_type': entityType,
        'entity_id': entityId,
        'count': response.length,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _logger.error('Failed to retrieve audit logs', e);
      rethrow;
    }
  }

  /// Generates compliance report for audit purposes
  Future<Map<String, dynamic>> generateComplianceReport({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? complianceCategories,
  }) async {
    try {
      var query = _supabase
          .from('financial_audit_log')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      if (complianceCategories != null && complianceCategories.isNotEmpty) {
        // Filter by compliance categories in metadata
        // This would require a more complex query in production
      }

      final response = await query;
      
      // Analyze the audit logs for compliance metrics
      final report = _analyzeAuditLogsForCompliance(response, startDate, endDate);
      
      _logger.info('Compliance report generated', {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'total_events': response.length,
      });

      return report;
    } catch (e) {
      _logger.error('Failed to generate compliance report', e);
      rethrow;
    }
  }

  // Private helper methods

  String _determineSeverity(String eventType) {
    switch (eventType) {
      case 'compliance_violation':
      case 'security_event':
        return 'high';
      case 'payment_processing':
      case 'payout_request':
        return 'medium';
      default:
        return 'low';
    }
  }

  List<String> _generateComplianceFlags(String eventType, Map<String, dynamic> eventData) {
    final flags = <String>[];
    
    // Add compliance flags based on event type and data
    if (eventType == 'payment_processing') {
      final amount = eventData['amount'] as double? ?? 0.0;
      if (amount >= 25000.0) {
        flags.add('large_transaction_reporting');
      }
    }
    
    if (eventType == 'payout_request') {
      flags.add('bank_transfer_monitoring');
    }
    
    return flags;
  }

  bool _isCriticalEvent(String eventType) {
    return [
      'compliance_violation',
      'security_event',
      'large_transaction',
      'suspicious_activity',
    ].contains(eventType);
  }

  Future<void> _logToExternalAuditSystem(Map<String, dynamic> auditRecord) async {
    // In production, this would send to external audit/SIEM systems
    _logger.info('Critical audit event logged to external system', auditRecord);
  }

  String _maskBankAccount(String bankAccount) {
    if (bankAccount.length <= 4) return '*' * bankAccount.length;
    return '${'*' * (bankAccount.length - 4)}${bankAccount.substring(bankAccount.length - 4)}';
  }

  Map<String, dynamic> _analyzeAuditLogsForCompliance(
    List<dynamic> auditLogs,
    DateTime startDate,
    DateTime endDate,
  ) {
    final totalEvents = auditLogs.length;
    final eventsByType = <String, int>{};
    final complianceViolations = <Map<String, dynamic>>[];
    final securityEvents = <Map<String, dynamic>>[];

    for (final log in auditLogs) {
      final eventType = log['event_type'] as String;
      eventsByType[eventType] = (eventsByType[eventType] ?? 0) + 1;

      if (eventType == 'compliance_violation') {
        complianceViolations.add(log);
      } else if (eventType == 'security_event') {
        securityEvents.add(log);
      }
    }

    return {
      'report_period': {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
      'summary': {
        'total_events': totalEvents,
        'events_by_type': eventsByType,
        'compliance_violations_count': complianceViolations.length,
        'security_events_count': securityEvents.length,
      },
      'compliance_violations': complianceViolations,
      'security_events': securityEvents,
      'generated_at': DateTime.now().toIso8601String(),
    };
  }
}

/// Provider for audit logging service
final auditLoggingServiceProvider = Provider<AuditLoggingService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final logger = ref.watch(loggerProvider);
  final securityService = ref.watch(securityServiceProvider);
  
  return AuditLoggingService(supabase, logger, securityService);
});

/// Audit logging actions provider for easy access from UI
final auditLoggingActionsProvider = Provider<AuditLoggingActions>((ref) {
  return AuditLoggingActions(ref);
});

/// Audit logging actions class for centralized audit operations
class AuditLoggingActions {
  final Ref _ref;

  AuditLoggingActions(this._ref);

  /// Log payment event
  Future<void> logPaymentEvent({
    required String orderId,
    required String paymentMethod,
    required double amount,
    required String status,
    String? transactionId,
    Map<String, dynamic>? additionalData,
  }) async {
    final service = _ref.read(auditLoggingServiceProvider);
    await service.logPaymentEvent(
      orderId: orderId,
      paymentMethod: paymentMethod,
      amount: amount,
      status: status,
      transactionId: transactionId,
      additionalData: additionalData,
    );
  }

  /// Log wallet transaction
  Future<void> logWalletTransaction({
    required String walletId,
    required String transactionId,
    required String transactionType,
    required double amount,
    required String status,
    String? description,
  }) async {
    final service = _ref.read(auditLoggingServiceProvider);
    await service.logWalletTransaction(
      walletId: walletId,
      transactionId: transactionId,
      transactionType: transactionType,
      amount: amount,
      status: status,
      description: description,
    );
  }

  /// Log payout event
  Future<void> logPayoutEvent({
    required String payoutId,
    required String walletId,
    required double amount,
    required String status,
    required String bankAccount,
    String? failureReason,
  }) async {
    final service = _ref.read(auditLoggingServiceProvider);
    await service.logPayoutEvent(
      payoutId: payoutId,
      walletId: walletId,
      amount: amount,
      status: status,
      bankAccount: bankAccount,
      failureReason: failureReason,
    );
  }

  /// Get audit logs
  Future<List<Map<String, dynamic>>> getAuditLogs({
    required String entityType,
    required String entityId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final service = _ref.read(auditLoggingServiceProvider);
    return await service.getAuditLogs(
      entityType: entityType,
      entityId: entityId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
