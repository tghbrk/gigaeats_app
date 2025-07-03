import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/logger.dart';
import '../../../core/services/security_service.dart';
import '../../../presentation/providers/repository_providers.dart';
import 'financial_security_service.dart';
import 'audit_logging_service.dart';

/// Enhanced wallet security service with comprehensive compliance and security features
class EnhancedWalletSecurityService {
  final SupabaseClient _supabase;
  final FinancialSecurityService _financialSecurity;
  final AuditLoggingService _auditLogging;
  final SecurityService _securityService;
  final AppLogger _logger = AppLogger();

  EnhancedWalletSecurityService(
    this._supabase,
    this._financialSecurity,
    this._auditLogging,
    this._securityService,
  );

  /// Validates wallet access permissions with comprehensive security checks
  Future<SecurityValidationResult> validateWalletAccess({
    required String walletId,
    required String operation,
    Map<String, dynamic>? context,
  }) async {
    try {
      debugPrint('🔒 [WALLET-SECURITY] Validating wallet access: $walletId for $operation');

      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return SecurityValidationResult.failure('User not authenticated');
      }

      // Validate session
      final session = _supabase.auth.currentSession;
      if (session == null || session.isExpired) {
        return SecurityValidationResult.failure('Session expired');
      }

      // Check wallet ownership using RLS-protected function
      final ownershipResult = await _supabase.rpc('validate_wallet_ownership', params: {
        'wallet_id': walletId,
        'user_id': user.id,
      });

      if (ownershipResult == false) {
        await _logSecurityEvent(
          eventType: 'unauthorized_wallet_access_attempt',
          userId: user.id,
          entityType: 'wallet',
          entityId: walletId,
          eventData: {
            'operation': operation,
            'context': context,
          },
          severity: 'high',
        );
        return SecurityValidationResult.failure('Unauthorized wallet access');
      }

      // Validate operation permissions
      final permissionValid = await _financialSecurity.validateFinancialPermission(
        userId: user.id,
        operation: operation,
        resourceId: walletId,
        context: context,
      );

      if (!permissionValid) {
        await _logSecurityEvent(
          eventType: 'insufficient_permissions',
          userId: user.id,
          entityType: 'wallet',
          entityId: walletId,
          eventData: {
            'operation': operation,
            'context': context,
          },
          severity: 'medium',
        );
        return SecurityValidationResult.failure('Insufficient permissions for operation');
      }

      // Check for suspicious activity patterns
      final suspiciousActivity = await _detectSuspiciousActivity(user.id, operation, context);
      if (suspiciousActivity.isDetected) {
        await _logSecurityEvent(
          eventType: 'suspicious_activity_detected',
          userId: user.id,
          entityType: 'wallet',
          entityId: walletId,
          eventData: {
            'operation': operation,
            'suspicious_indicators': suspiciousActivity.indicators,
            'risk_score': suspiciousActivity.riskScore,
          },
          severity: 'critical',
        );

        if (suspiciousActivity.riskScore > 80) {
          return SecurityValidationResult.failure('Activity blocked due to security concerns');
        }
      }

      debugPrint('✅ [WALLET-SECURITY] Wallet access validated successfully');
      return SecurityValidationResult.success();
    } catch (e) {
      debugPrint('❌ [WALLET-SECURITY] Wallet access validation error: $e');
      return SecurityValidationResult.failure('Security validation failed: $e');
    }
  }

  /// Validates transaction with Malaysian compliance checks
  Future<TransactionValidationResult> validateTransaction({
    required String walletId,
    required double amount,
    required String transactionType,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('🔒 [WALLET-SECURITY] Validating transaction: $transactionType, amount: $amount');

      // Check transaction limits using database function
      final limitsValid = await _supabase.rpc('check_transaction_limits', params: {
        'wallet_id': walletId,
        'transaction_amount': amount,
        'transaction_type': transactionType,
      });

      if (limitsValid == false) {
        await _logSecurityEvent(
          eventType: 'transaction_limit_exceeded',
          userId: _supabase.auth.currentUser?.id,
          entityType: 'transaction',
          entityId: referenceId ?? 'unknown',
          eventData: {
            'wallet_id': walletId,
            'amount': amount,
            'transaction_type': transactionType,
            'limit_type': 'bnm_compliance',
          },
          severity: 'high',
        );
        return TransactionValidationResult.failure(
          'Transaction exceeds regulatory limits (BNM compliance)',
          violationType: 'regulatory_limit',
        );
      }

      // Validate transaction integrity
      final integrityValid = await _validateTransactionIntegrity(
        walletId: walletId,
        amount: amount,
        transactionType: transactionType,
        referenceId: referenceId,
        metadata: metadata,
      );

      if (!integrityValid.isValid) {
        return TransactionValidationResult.failure(
          'Transaction integrity validation failed: ${integrityValid.reason}',
          violationType: 'integrity_check',
        );
      }

      // Check for money laundering patterns
      final amlCheck = await _performAMLCheck(walletId, amount, transactionType, metadata);
      if (amlCheck.requiresReview) {
        await _logSecurityEvent(
          eventType: 'aml_review_required',
          userId: _supabase.auth.currentUser?.id,
          entityType: 'transaction',
          entityId: referenceId ?? 'unknown',
          eventData: {
            'wallet_id': walletId,
            'amount': amount,
            'transaction_type': transactionType,
            'aml_indicators': amlCheck.indicators,
            'risk_score': amlCheck.riskScore,
          },
          severity: 'critical',
        );

        if (amlCheck.riskScore > 90) {
          return TransactionValidationResult.failure(
            'Transaction blocked for AML review',
            violationType: 'aml_violation',
          );
        }
      }

      debugPrint('✅ [WALLET-SECURITY] Transaction validation successful');
      return TransactionValidationResult.success();
    } catch (e) {
      debugPrint('❌ [WALLET-SECURITY] Transaction validation error: $e');
      return TransactionValidationResult.failure(
        'Transaction validation failed: $e',
        violationType: 'system_error',
      );
    }
  }

  /// Encrypts sensitive wallet data before storage
  Future<String> encryptWalletData(Map<String, dynamic> data) async {
    try {
      return await _financialSecurity.encryptFinancialData(data);
    } catch (e) {
      debugPrint('❌ [WALLET-SECURITY] Encryption error: $e');
      rethrow;
    }
  }

  /// Decrypts wallet data after retrieval
  Future<Map<String, dynamic>> decryptWalletData(String encryptedData) async {
    try {
      return await _financialSecurity.decryptFinancialData(encryptedData);
    } catch (e) {
      debugPrint('❌ [WALLET-SECURITY] Decryption error: $e');
      rethrow;
    }
  }

  /// Generates comprehensive audit trail for wallet operations
  Future<String> generateWalletAuditTrail({
    required String operation,
    required String walletId,
    required Map<String, dynamic> operationData,
    String? userId,
    String? ipAddress,
  }) async {
    try {
      final auditTrail = _financialSecurity.generateAuditTrail(
        operation: operation,
        entityType: 'wallet',
        entityId: walletId,
        operationData: operationData,
        userId: userId,
        ipAddress: ipAddress,
      );

      // Store audit trail in database
      final auditId = await _supabase.rpc('log_security_event', params: {
        'event_type': operation,
        'user_id': userId,
        'entity_type': 'wallet',
        'entity_id': walletId,
        'event_data': auditTrail,
        'ip_address': ipAddress,
      });

      return auditId.toString();
    } catch (e) {
      debugPrint('❌ [WALLET-SECURITY] Audit trail generation error: $e');
      rethrow;
    }
  }

  /// Detects suspicious activity patterns
  Future<SuspiciousActivityResult> _detectSuspiciousActivity(
    String userId,
    String operation,
    Map<String, dynamic>? context,
  ) async {
    try {
      // Get recent activity for pattern analysis
      final recentActivity = await _supabase
          .from('financial_audit_log')
          .select('event_type, created_at, event_data')
          .eq('user_id', userId)
          .gte('created_at', DateTime.now().subtract(const Duration(hours: 24)).toIso8601String())
          .order('created_at', ascending: false)
          .limit(50);

      final indicators = <String>[];
      int riskScore = 0;

      // Check for rapid successive operations
      if (recentActivity.length > 20) {
        indicators.add('high_frequency_operations');
        riskScore += 30;
      }

      // Check for unusual operation patterns
      final operationCounts = <String, int>{};
      for (final activity in recentActivity) {
        final eventType = activity['event_type'] as String;
        operationCounts[eventType] = (operationCounts[eventType] ?? 0) + 1;
      }

      if (operationCounts[operation] != null && operationCounts[operation]! > 10) {
        indicators.add('repeated_operation_pattern');
        riskScore += 25;
      }

      // Check for unusual timing (operations outside normal hours)
      final currentHour = DateTime.now().hour;
      if (currentHour < 6 || currentHour > 23) {
        indicators.add('unusual_timing');
        riskScore += 15;
      }

      return SuspiciousActivityResult(
        isDetected: indicators.isNotEmpty,
        indicators: indicators,
        riskScore: riskScore,
      );
    } catch (e) {
      debugPrint('❌ [WALLET-SECURITY] Suspicious activity detection error: $e');
      return SuspiciousActivityResult(isDetected: false, indicators: [], riskScore: 0);
    }
  }

  /// Validates transaction integrity
  Future<IntegrityValidationResult> _validateTransactionIntegrity({
    required String walletId,
    required double amount,
    required String transactionType,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Basic validation
      if (amount <= 0) {
        return IntegrityValidationResult(false, 'Invalid amount: must be greater than 0');
      }

      if (walletId.isEmpty) {
        return IntegrityValidationResult(false, 'Invalid wallet ID');
      }

      // Validate transaction type
      const validTypes = ['top_up', 'order_payment', 'refund', 'transfer_in', 'transfer_out', 'adjustment'];
      if (!validTypes.contains(transactionType)) {
        return IntegrityValidationResult(false, 'Invalid transaction type');
      }

      // Check wallet exists and is active
      final wallet = await _supabase
          .from('stakeholder_wallets')
          .select('id, is_active, available_balance')
          .eq('id', walletId)
          .single();

      if (wallet['is_active'] != true) {
        return IntegrityValidationResult(false, 'Wallet is not active');
      }

      // For debit transactions, check sufficient balance
      if (['order_payment', 'transfer_out'].contains(transactionType)) {
        final currentBalance = wallet['available_balance'] as double;
        if (currentBalance < amount) {
          return IntegrityValidationResult(false, 'Insufficient wallet balance');
        }
      }

      return IntegrityValidationResult(true, null);
    } catch (e) {
      return IntegrityValidationResult(false, 'Integrity validation error: $e');
    }
  }

  /// Performs Anti-Money Laundering (AML) checks
  Future<AMLCheckResult> _performAMLCheck(
    String walletId,
    double amount,
    String transactionType,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final indicators = <String>[];
      int riskScore = 0;

      // Check for large transactions (above RM 1,000)
      if (amount > 1000) {
        indicators.add('large_transaction');
        riskScore += 20;
      }

      // Check for round number transactions (potential structuring)
      if (amount % 100 == 0 && amount >= 500) {
        indicators.add('round_number_transaction');
        riskScore += 15;
      }

      // Get transaction history for pattern analysis
      final recentTransactions = await _supabase
          .from('wallet_transactions')
          .select('amount, transaction_type, created_at')
          .eq('wallet_id', walletId)
          .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
          .order('created_at', ascending: false);

      // Check for structuring patterns (multiple transactions just below reporting threshold)
      final structuringTransactions = recentTransactions
          .where((t) => (t['amount'] as double) > 900 && (t['amount'] as double) < 1000)
          .length;

      if (structuringTransactions > 3) {
        indicators.add('potential_structuring');
        riskScore += 40;
      }

      // Check for rapid succession of transactions
      final rapidTransactions = recentTransactions
          .where((t) => DateTime.parse(t['created_at']).isAfter(DateTime.now().subtract(const Duration(hours: 1))))
          .length;

      if (rapidTransactions > 5) {
        indicators.add('rapid_transaction_pattern');
        riskScore += 25;
      }

      return AMLCheckResult(
        requiresReview: riskScore > 50,
        indicators: indicators,
        riskScore: riskScore,
      );
    } catch (e) {
      debugPrint('❌ [WALLET-SECURITY] AML check error: $e');
      return AMLCheckResult(requiresReview: false, indicators: [], riskScore: 0);
    }
  }

  /// Logs security events
  Future<void> _logSecurityEvent({
    required String eventType,
    String? userId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> eventData,
    required String severity,
  }) async {
    try {
      await _auditLogging.logFinancialEvent(
        eventType: eventType,
        entityType: entityType,
        entityId: entityId,
        eventData: eventData,
        metadata: {
          'severity': severity,
          'security_event': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('❌ [WALLET-SECURITY] Security event logging error: $e');
    }
  }
}

/// Security validation result
class SecurityValidationResult {
  final bool isValid;
  final String? errorMessage;

  const SecurityValidationResult._(this.isValid, this.errorMessage);

  factory SecurityValidationResult.success() => const SecurityValidationResult._(true, null);
  factory SecurityValidationResult.failure(String message) => SecurityValidationResult._(false, message);
}

/// Transaction validation result
class TransactionValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? violationType;

  const TransactionValidationResult._(this.isValid, this.errorMessage, this.violationType);

  factory TransactionValidationResult.success() => const TransactionValidationResult._(true, null, null);
  factory TransactionValidationResult.failure(String message, {String? violationType}) => 
      TransactionValidationResult._(false, message, violationType);
}

/// Suspicious activity detection result
class SuspiciousActivityResult {
  final bool isDetected;
  final List<String> indicators;
  final int riskScore;

  const SuspiciousActivityResult({
    required this.isDetected,
    required this.indicators,
    required this.riskScore,
  });
}

/// Integrity validation result
class IntegrityValidationResult {
  final bool isValid;
  final String? reason;

  const IntegrityValidationResult(this.isValid, this.reason);
}

/// AML check result
class AMLCheckResult {
  final bool requiresReview;
  final List<String> indicators;
  final int riskScore;

  const AMLCheckResult({
    required this.requiresReview,
    required this.indicators,
    required this.riskScore,
  });
}

/// Provider for enhanced wallet security service
final enhancedWalletSecurityServiceProvider = Provider<EnhancedWalletSecurityService>((ref) {
  final supabase = Supabase.instance.client;
  final financialSecurity = ref.watch(financialSecurityServiceProvider);
  final auditLogging = ref.watch(auditLoggingServiceProvider);
  final securityService = ref.watch(securityServiceProvider);

  return EnhancedWalletSecurityService(supabase, financialSecurity, auditLogging, securityService);
});
