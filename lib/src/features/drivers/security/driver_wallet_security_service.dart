import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/driver_wallet_transaction.dart';

/// Comprehensive security service for driver wallet operations
/// Provides validation, audit logging, and security enforcement
class DriverWalletSecurityService {
  final SupabaseClient _supabase;

  DriverWalletSecurityService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Validates driver wallet access permissions
  Future<SecurityValidationResult> validateWalletAccess({
    required String walletId,
    required String operation,
    Map<String, dynamic>? context,
  }) async {
    try {
      debugPrint('🔒 [DRIVER-WALLET-SECURITY] Validating wallet access: $walletId for $operation');

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

      // Validate driver role
      final roleValidation = await _validateDriverRole(user.id);
      if (!roleValidation.isValid) {
        return SecurityValidationResult.failure('User is not a valid driver');
      }

      // Skip wallet ownership validation for session checks and pending lookups
      if (walletId != 'session_check' && walletId != 'pending_lookup') {
        // Validate wallet ownership
        final ownershipValidation = await _validateWalletOwnership(walletId, user.id);
        if (!ownershipValidation.isValid) {
          return SecurityValidationResult.failure('Wallet access denied');
        }
      } else {
        debugPrint('🔒 [DRIVER-WALLET-SECURITY] Skipping wallet ownership validation for: $walletId');
      }

      // Validate operation permissions
      final operationValidation = await _validateOperationPermissions(operation, context);
      if (!operationValidation.isValid) {
        return SecurityValidationResult.failure('Operation not permitted');
      }

      // Log security validation success
      await _logSecurityEvent(
        eventType: 'wallet_access_validated',
        userId: user.id,
        walletId: walletId,
        operation: operation,
        result: 'success',
        context: context,
      );

      return SecurityValidationResult.success();
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-SECURITY] Validation error: $e');
      
      // Log security validation failure
      await _logSecurityEvent(
        eventType: 'wallet_access_validation_failed',
        userId: _supabase.auth.currentUser?.id,
        walletId: walletId,
        operation: operation,
        result: 'failure',
        error: e.toString(),
        context: context,
      );

      return SecurityValidationResult.failure('Security validation failed: ${e.toString()}');
    }
  }

  /// Validates transaction input data
  Future<SecurityValidationResult> validateTransactionInput({
    required DriverWalletTransactionType transactionType,
    required double amount,
    required String currency,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('🔒 [DRIVER-WALLET-SECURITY] Validating transaction input');

      final errors = <String>[];

      // Validate amount
      if (amount <= 0) {
        errors.add('Transaction amount must be greater than zero');
      }
      if (amount > 10000.00) {
        errors.add('Transaction amount exceeds maximum limit of RM 10,000');
      }

      // Validate currency
      if (currency != 'MYR') {
        errors.add('Only MYR currency is supported');
      }

      // Validate transaction type
      if (!_isValidDriverTransactionType(transactionType)) {
        errors.add('Invalid transaction type for driver wallet');
      }

      // Validate description length
      if (description != null && description.length > 500) {
        errors.add('Description exceeds maximum length of 500 characters');
      }

      // Validate metadata size
      if (metadata != null && metadata.toString().length > 2000) {
        errors.add('Metadata exceeds maximum size limit');
      }

      if (errors.isNotEmpty) {
        return SecurityValidationResult.failure(errors.join(', '));
      }

      return SecurityValidationResult.success();
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-SECURITY] Transaction validation error: $e');
      return SecurityValidationResult.failure('Transaction validation failed: ${e.toString()}');
    }
  }

  /// Validates withdrawal request input
  Future<SecurityValidationResult> validateWithdrawalInput({
    required double amount,
    required String withdrawalMethod,
    Map<String, dynamic>? bankDetails,
  }) async {
    try {
      debugPrint('🔒 [DRIVER-WALLET-SECURITY] Validating withdrawal input');

      final errors = <String>[];

      // Validate amount
      if (amount <= 0) {
        errors.add('Withdrawal amount must be greater than zero');
      }
      if (amount < 10.00) {
        errors.add('Withdrawal amount below minimum limit of RM 10.00');
      }
      if (amount > 5000.00) {
        errors.add('Withdrawal amount exceeds maximum limit of RM 5,000');
      }

      // Validate withdrawal method
      final validMethods = ['bank_transfer', 'ewallet', 'cash'];
      if (!validMethods.contains(withdrawalMethod)) {
        errors.add('Invalid withdrawal method');
      }

      // Validate bank details for bank transfers
      if (withdrawalMethod == 'bank_transfer') {
        if (bankDetails == null || bankDetails.isEmpty) {
          errors.add('Bank details required for bank transfer');
        } else {
          if (bankDetails['account_number'] == null || 
              (bankDetails['account_number'] as String).isEmpty) {
            errors.add('Bank account number is required');
          }
          if (bankDetails['bank_name'] == null || 
              (bankDetails['bank_name'] as String).isEmpty) {
            errors.add('Bank name is required');
          }
        }
      }

      if (errors.isNotEmpty) {
        return SecurityValidationResult.failure(errors.join(', '));
      }

      return SecurityValidationResult.success();
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-SECURITY] Withdrawal validation error: $e');
      return SecurityValidationResult.failure('Withdrawal validation failed: ${e.toString()}');
    }
  }

  /// Detects suspicious activity patterns
  Future<SuspiciousActivityResult> detectSuspiciousActivity({
    required String userId,
    required String operation,
    Map<String, dynamic>? context,
  }) async {
    try {
      debugPrint('🔒 [DRIVER-WALLET-SECURITY] Checking for suspicious activity');

      final suspiciousPatterns = <String>[];

      // Check for rapid successive operations
      final recentOperations = await _getRecentOperations(userId, operation);
      if (recentOperations.length > 5) {
        suspiciousPatterns.add('Rapid successive operations detected');
      }

      // Check for unusual amounts (if applicable)
      if (context?['amount'] != null) {
        final amount = context!['amount'] as double;
        if (amount > 1000.00) {
          final largeTransactionsToday = await _getLargeTransactionsToday(userId);
          if (largeTransactionsToday.length >= 3) {
            suspiciousPatterns.add('Multiple large transactions in 24 hours');
          }
        }
      }

      // Check for unusual time patterns
      final now = DateTime.now();
      if (now.hour < 6 || now.hour > 22) {
        suspiciousPatterns.add('Operation outside normal hours');
      }

      if (suspiciousPatterns.isNotEmpty) {
        // Log suspicious activity
        await _logSecurityEvent(
          eventType: 'suspicious_activity_detected',
          userId: userId,
          operation: operation,
          result: 'suspicious',
          context: {
            'patterns': suspiciousPatterns,
            'timestamp': now.toIso8601String(),
            ...?context,
          },
        );

        return SuspiciousActivityResult.suspicious(suspiciousPatterns);
      }

      return SuspiciousActivityResult.normal();
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-SECURITY] Suspicious activity check error: $e');
      return SuspiciousActivityResult.error(e.toString());
    }
  }

  /// Logs comprehensive audit trail for driver wallet operations
  Future<void> logDriverWalletAudit({
    required String operation,
    required String walletId,
    required Map<String, dynamic> operationData,
    String? userId,
    String? result,
    String? error,
  }) async {
    try {
      await _logSecurityEvent(
        eventType: 'driver_wallet_operation',
        userId: userId ?? _supabase.auth.currentUser?.id,
        walletId: walletId,
        operation: operation,
        result: result ?? 'unknown',
        error: error,
        context: operationData,
      );
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-SECURITY] Audit logging error: $e');
    }
  }

  // Private helper methods
  Future<SecurityValidationResult> _validateDriverRole(String userId) async {
    try {
      debugPrint('🔒 [DRIVER-WALLET-SECURITY] Validating driver role for user: $userId');

      final response = await _supabase
          .from('drivers')
          .select('id, status, is_active')
          .eq('user_id', userId)
          .maybeSingle();

      debugPrint('🔒 [DRIVER-WALLET-SECURITY] Driver query result: $response');

      if (response == null) {
        debugPrint('❌ [DRIVER-WALLET-SECURITY] Driver profile not found for user: $userId');
        return SecurityValidationResult.failure('Driver profile not found');
      }

      // Check is_active field instead of status field
      // Status can be 'online'/'offline' but driver should still access wallet when offline
      if (response['is_active'] != true) {
        debugPrint('❌ [DRIVER-WALLET-SECURITY] Driver account is not active: is_active=${response['is_active']}, status=${response['status']}');
        return SecurityValidationResult.failure('Driver account is not active');
      }

      debugPrint('✅ [DRIVER-WALLET-SECURITY] Driver role validation successful: driver_id=${response['id']}, status=${response['status']}, is_active=${response['is_active']}');
      return SecurityValidationResult.success();
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-SECURITY] Driver role validation error: $e');
      return SecurityValidationResult.failure('Driver role validation failed');
    }
  }

  Future<SecurityValidationResult> _validateWalletOwnership(String walletId, String userId) async {
    try {
      debugPrint('🔒 [DRIVER-WALLET-SECURITY] Validating wallet ownership: wallet_id=$walletId, user_id=$userId');

      final response = await _supabase.rpc('validate_driver_wallet_ownership', params: {
        'p_wallet_id': walletId,
        'p_user_id': userId,
      });

      debugPrint('🔒 [DRIVER-WALLET-SECURITY] Wallet ownership RPC response: $response (type: ${response.runtimeType})');

      if (response == true) {
        debugPrint('✅ [DRIVER-WALLET-SECURITY] Wallet ownership validation successful');
        return SecurityValidationResult.success();
      } else {
        debugPrint('❌ [DRIVER-WALLET-SECURITY] Wallet ownership validation failed: response=$response');
        return SecurityValidationResult.failure('Wallet ownership validation failed');
      }
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-SECURITY] Wallet ownership check error: $e');
      return SecurityValidationResult.failure('Wallet ownership check failed');
    }
  }

  Future<SecurityValidationResult> _validateOperationPermissions(
    String operation,
    Map<String, dynamic>? context,
  ) async {
    debugPrint('🔒 [DRIVER-WALLET-SECURITY] Validating operation permissions: operation=$operation');

    // Define allowed operations for drivers
    final allowedOperations = [
      'validate_session',
      'view_balance',
      'view_transactions',
      'request_withdrawal',
      'view_settings',
      'update_settings',
    ];

    debugPrint('🔒 [DRIVER-WALLET-SECURITY] Allowed operations: $allowedOperations');

    if (!allowedOperations.contains(operation)) {
      debugPrint('❌ [DRIVER-WALLET-SECURITY] Operation not allowed: $operation not in $allowedOperations');
      return SecurityValidationResult.failure('Operation not allowed for drivers');
    }

    debugPrint('✅ [DRIVER-WALLET-SECURITY] Operation permissions validated successfully: $operation');
    return SecurityValidationResult.success();
  }

  bool _isValidDriverTransactionType(DriverWalletTransactionType type) {
    // Define valid transaction types for drivers
    final validTypes = [
      DriverWalletTransactionType.deliveryEarnings,
      DriverWalletTransactionType.completionBonus,
      DriverWalletTransactionType.tipPayment,
      DriverWalletTransactionType.performanceBonus,
      DriverWalletTransactionType.fuelAllowance,
      DriverWalletTransactionType.withdrawalRequest,
      DriverWalletTransactionType.bankTransfer,
      DriverWalletTransactionType.ewalletPayout,
    ];

    return validTypes.contains(type);
  }

  Future<List<Map<String, dynamic>>> _getRecentOperations(String userId, String operation) async {
    try {
      final response = await _supabase
          .from('financial_audit_log')
          .select('*')
          .eq('user_id', userId)
          .eq('event_type', operation)
          .gte('created_at', DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-SECURITY] Error getting recent operations: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getLargeTransactionsToday(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final response = await _supabase
          .from('financial_audit_log')
          .select('*')
          .eq('user_id', userId)
          .eq('event_type', 'driver_wallet_operation')
          .gte('created_at', startOfDay.toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response).where((log) {
        final eventData = log['event_data'] as Map<String, dynamic>?;
        final amount = eventData?['amount'] as double?;
        return amount != null && amount > 1000.00;
      }).toList();
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-SECURITY] Error getting large transactions: $e');
      return [];
    }
  }

  Future<void> _logSecurityEvent({
    required String eventType,
    String? userId,
    String? walletId,
    String? operation,
    String? result,
    String? error,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Handle special wallet ID cases that are not UUIDs
      // Use predefined system UUIDs for special operations
      String entityId;
      String entityType = 'driver_wallet';

      if (walletId == 'session_check') {
        entityId = '00000000-0000-0000-0000-000000000001'; // System UUID for session checks
        entityType = 'session_validation';
      } else if (walletId == 'pending_lookup') {
        entityId = '00000000-0000-0000-0000-000000000002'; // System UUID for pending lookups
        entityType = 'wallet_lookup';
      } else if (walletId != null && _isValidUuid(walletId)) {
        entityId = walletId; // Use the actual wallet UUID
      } else {
        entityId = '00000000-0000-0000-0000-000000000000'; // System UUID for unknown/invalid IDs
        entityType = 'system_operation';
      }

      await _supabase.from('financial_audit_log').insert({
        'event_type': eventType,
        'entity_type': entityType,
        'entity_id': entityId,
        'user_id': userId,
        'event_data': {
          'operation': operation,
          'result': result,
          'error': error,
          'original_wallet_id': walletId, // Store original value for reference
          'timestamp': DateTime.now().toIso8601String(),
          ...?context,
        },
        'metadata': {
          'source': 'driver_wallet_security_service',
          'severity': _determineSeverity(eventType),
        },
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-SECURITY] Error logging security event: $e');
    }
  }

  /// Helper method to validate UUID format
  bool _isValidUuid(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );
    return uuidRegex.hasMatch(value);
  }

  String _determineSeverity(String eventType) {
    if (eventType.contains('suspicious') || eventType.contains('failed')) {
      return 'high';
    } else if (eventType.contains('validation')) {
      return 'medium';
    } else {
      return 'low';
    }
  }
}

/// Security validation result class
class SecurityValidationResult {
  final bool isValid;
  final String? errorMessage;

  SecurityValidationResult._(this.isValid, this.errorMessage);

  factory SecurityValidationResult.success() => SecurityValidationResult._(true, null);
  factory SecurityValidationResult.failure(String message) => SecurityValidationResult._(false, message);
}

/// Suspicious activity detection result
class SuspiciousActivityResult {
  final bool isSuspicious;
  final List<String> patterns;
  final String? error;

  SuspiciousActivityResult._(this.isSuspicious, this.patterns, this.error);

  factory SuspiciousActivityResult.normal() => SuspiciousActivityResult._(false, [], null);
  factory SuspiciousActivityResult.suspicious(List<String> patterns) => 
      SuspiciousActivityResult._(true, patterns, null);
  factory SuspiciousActivityResult.error(String error) => 
      SuspiciousActivityResult._(false, [], error);
}
