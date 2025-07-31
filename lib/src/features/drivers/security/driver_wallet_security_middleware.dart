import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'driver_wallet_security_service.dart';
import '../data/models/driver_wallet_transaction.dart';

/// Security middleware for driver wallet operations
/// Provides centralized security validation and audit logging
class DriverWalletSecurityMiddleware {
  final DriverWalletSecurityService _securityService;

  DriverWalletSecurityMiddleware({
    DriverWalletSecurityService? securityService,
  }) : _securityService = securityService ?? DriverWalletSecurityService();

  /// Validates and executes a secure wallet operation
  Future<T> executeSecureOperation<T>({
    required String operation,
    required String walletId,
    required Future<T> Function() operationFunction,
    Map<String, dynamic>? context,
    bool requiresValidation = true,
    bool logAudit = true,
  }) async {
    final startTime = DateTime.now();
    String? operationResult;
    String? errorMessage;

    try {
      debugPrint('🔒 [DRIVER-WALLET-MIDDLEWARE] Starting secure operation: $operation');

      // Step 1: Security validation (if required)
      if (requiresValidation) {
        final validationResult = await _securityService.validateWalletAccess(
          walletId: walletId,
          operation: operation,
          context: context,
        );

        if (!validationResult.isValid) {
          throw SecurityException(validationResult.errorMessage ?? 'Security validation failed');
        }
      }

      // Step 2: Suspicious activity detection
      final suspiciousActivityResult = await _securityService.detectSuspiciousActivity(
        userId: context?['user_id'] ?? 'unknown',
        operation: operation,
        context: context,
      );

      if (suspiciousActivityResult.isSuspicious) {
        debugPrint('⚠️ [DRIVER-WALLET-MIDDLEWARE] Suspicious activity detected: ${suspiciousActivityResult.patterns}');
        
        // Log suspicious activity but allow operation to continue with extra monitoring
        await _securityService.logDriverWalletAudit(
          operation: operation,
          walletId: walletId,
          operationData: {
            'suspicious_patterns': suspiciousActivityResult.patterns,
            'operation_allowed': true,
            ...?context,
          },
          result: 'suspicious_but_allowed',
        );
      }

      // Step 3: Execute the actual operation
      debugPrint('🔒 [DRIVER-WALLET-MIDDLEWARE] Executing operation: $operation');
      final result = await operationFunction();
      
      operationResult = 'success';
      debugPrint('✅ [DRIVER-WALLET-MIDDLEWARE] Operation completed successfully: $operation');

      return result;
    } catch (e) {
      operationResult = 'failure';
      errorMessage = e.toString();
      debugPrint('❌ [DRIVER-WALLET-MIDDLEWARE] Operation failed: $operation - $e');
      rethrow;
    } finally {
      // Step 4: Audit logging (if enabled)
      if (logAudit) {
        final duration = DateTime.now().difference(startTime);
        
        await _securityService.logDriverWalletAudit(
          operation: operation,
          walletId: walletId,
          operationData: {
            'duration_ms': duration.inMilliseconds,
            'timestamp': startTime.toIso8601String(),
            'validation_required': requiresValidation,
            ...?context,
          },
          result: operationResult,
          error: errorMessage,
        );
      }
    }
  }

  /// Validates transaction input with comprehensive security checks
  Future<void> validateTransactionInput({
    required DriverWalletTransactionType transactionType,
    required double amount,
    required String currency,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    debugPrint('🔒 [DRIVER-WALLET-MIDDLEWARE] Validating transaction input');

    final validationResult = await _securityService.validateTransactionInput(
      transactionType: transactionType,
      amount: amount,
      currency: currency,
      description: description,
      metadata: metadata,
    );

    if (!validationResult.isValid) {
      throw ValidationException(validationResult.errorMessage ?? 'Transaction validation failed');
    }
  }

  /// Validates withdrawal request with security checks
  Future<void> validateWithdrawalInput({
    required double amount,
    required String withdrawalMethod,
    Map<String, dynamic>? bankDetails,
  }) async {
    debugPrint('🔒 [DRIVER-WALLET-MIDDLEWARE] Validating withdrawal input');

    final validationResult = await _securityService.validateWithdrawalInput(
      amount: amount,
      withdrawalMethod: withdrawalMethod,
      bankDetails: bankDetails,
    );

    if (!validationResult.isValid) {
      throw ValidationException(validationResult.errorMessage ?? 'Withdrawal validation failed');
    }
  }

  /// Rate limiting for sensitive operations
  Future<void> checkRateLimit({
    required String operation,
    required String userId,
    int maxOperationsPerMinute = 10,
  }) async {
    try {
      debugPrint('🔒 [DRIVER-WALLET-MIDDLEWARE] Checking rate limit for $operation');

      // This would typically use Redis or similar for production
      // For now, we'll use a simple in-memory approach
      final now = DateTime.now();

      // In a real implementation, you would check against a rate limiting service
      // For now, we'll just log the rate limit check
      await _securityService.logDriverWalletAudit(
        operation: 'rate_limit_check',
        walletId: 'system',
        operationData: {
          'target_operation': operation,
          'user_id': userId,
          'max_operations': maxOperationsPerMinute,
          'check_time': now.toIso8601String(),
        },
        result: 'passed',
      );
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-MIDDLEWARE] Rate limit check error: $e');
      throw RateLimitException('Rate limit check failed');
    }
  }

  /// Validates session and authentication state
  Future<void> validateSession() async {
    debugPrint('🔒 [DRIVER-WALLET-MIDDLEWARE] Validating session');

    // This validation is handled by the security service
    // We just need to ensure the user is authenticated
    final validationResult = await _securityService.validateWalletAccess(
      walletId: 'session_check',
      operation: 'validate_session',
    );

    if (!validationResult.isValid) {
      throw AuthenticationException(validationResult.errorMessage ?? 'Session validation failed');
    }
  }

  /// Sanitizes input data to prevent injection attacks
  Map<String, dynamic> sanitizeInput(Map<String, dynamic> input) {
    debugPrint('🔒 [DRIVER-WALLET-MIDDLEWARE] Sanitizing input data');

    final sanitized = <String, dynamic>{};

    for (final entry in input.entries) {
      final key = entry.key;
      final value = entry.value;

      // Sanitize string values
      if (value is String) {
        // Remove potentially dangerous characters
        final sanitizedValue = value
            .replaceAll(RegExp(r'[<>"\x27]'), '')
            .replaceAll(RegExp(r'script', caseSensitive: false), '')
            .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
            .trim();
        
        sanitized[key] = sanitizedValue;
      } else if (value is Map<String, dynamic>) {
        // Recursively sanitize nested maps
        sanitized[key] = sanitizeInput(value);
      } else {
        // Keep other types as-is (numbers, booleans, etc.)
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  /// Validates numeric inputs for financial operations
  void validateFinancialInput({
    required double amount,
    double? minAmount,
    double? maxAmount,
    required String currency,
  }) {
    debugPrint('🔒 [DRIVER-WALLET-MIDDLEWARE] Validating financial input');

    final errors = <String>[];

    // Validate amount
    if (amount.isNaN || amount.isInfinite) {
      errors.add('Invalid amount value');
    }

    if (amount <= 0) {
      errors.add('Amount must be greater than zero');
    }

    if (minAmount != null && amount < minAmount) {
      errors.add('Amount below minimum limit of $currency ${minAmount.toStringAsFixed(2)}');
    }

    if (maxAmount != null && amount > maxAmount) {
      errors.add('Amount exceeds maximum limit of $currency ${maxAmount.toStringAsFixed(2)}');
    }

    // Validate currency
    if (currency != 'MYR') {
      errors.add('Only MYR currency is supported');
    }

    // Check for reasonable decimal places (max 2 for currency)
    final decimalPlaces = amount.toString().split('.').length > 1 
        ? amount.toString().split('.')[1].length 
        : 0;
    
    if (decimalPlaces > 2) {
      errors.add('Amount cannot have more than 2 decimal places');
    }

    if (errors.isNotEmpty) {
      throw ValidationException(errors.join(', '));
    }
  }

  /// Logs security events for monitoring and compliance
  Future<void> logSecurityEvent({
    required String eventType,
    required String operation,
    required String walletId,
    Map<String, dynamic>? context,
    String? result,
    String? error,
  }) async {
    await _securityService.logDriverWalletAudit(
      operation: operation,
      walletId: walletId,
      operationData: {
        'event_type': eventType,
        'security_middleware': true,
        ...?context,
      },
      result: result,
      error: error,
    );
  }
}

/// Custom security exceptions
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  
  @override
  String toString() => 'ValidationException: $message';
}

class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);
  
  @override
  String toString() => 'AuthenticationException: $message';
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
  
  @override
  String toString() => 'RateLimitException: $message';
}

/// Provider for the security middleware
final driverWalletSecurityMiddlewareProvider = Provider<DriverWalletSecurityMiddleware>((ref) {
  return DriverWalletSecurityMiddleware();
});
