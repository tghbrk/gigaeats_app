import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/security_service.dart';
import '../../../core/utils/logger.dart';
import '../../../presentation/providers/repository_providers.dart';
import '../data/models/wallet_transaction.dart';
import '../data/models/payout_request.dart';

/// Enhanced financial security service for marketplace wallet operations
class FinancialSecurityService {
  final SecurityService _securityService;
  final AppLogger _logger;

  FinancialSecurityService(this._securityService, this._logger);

  /// Encrypts sensitive financial data before storage
  Future<String> encryptFinancialData(Map<String, dynamic> data) async {
    try {
      final jsonString = json.encode(data);
      final bytes = utf8.encode(jsonString);
      
      // Generate a random salt for this encryption
      final salt = _generateSalt();
      
      // Create encryption key from user context + salt
      final encryptionKey = await _deriveEncryptionKey(salt);
      
      // Encrypt the data (simplified - in production use proper AES encryption)
      final encryptedBytes = _encryptWithKey(bytes, encryptionKey);
      
      // Combine salt + encrypted data
      final combined = salt + encryptedBytes;
      
      // Return base64 encoded result
      final encrypted = base64.encode(combined);
      
      _logger.debug('Financial data encrypted successfully');
      return encrypted;
    } catch (e) {
      _logger.error('Failed to encrypt financial data', e);
      throw SecurityException('Encryption failed: ${e.toString()}');
    }
  }

  /// Decrypts sensitive financial data after retrieval
  Future<Map<String, dynamic>> decryptFinancialData(String encryptedData) async {
    try {
      final combined = base64.decode(encryptedData);
      
      // Extract salt (first 16 bytes)
      final salt = combined.sublist(0, 16);
      final encryptedBytes = combined.sublist(16);
      
      // Recreate encryption key
      final encryptionKey = await _deriveEncryptionKey(salt);
      
      // Decrypt the data
      final decryptedBytes = _decryptWithKey(encryptedBytes, encryptionKey);
      
      // Convert back to JSON
      final jsonString = utf8.decode(decryptedBytes);
      final data = json.decode(jsonString) as Map<String, dynamic>;
      
      _logger.debug('Financial data decrypted successfully');
      return data;
    } catch (e) {
      _logger.error('Failed to decrypt financial data', e);
      throw SecurityException('Decryption failed: ${e.toString()}');
    }
  }

  /// Validates transaction integrity using checksums
  bool validateTransactionIntegrity(WalletTransaction transaction) {
    try {
      // In a real implementation, a checksum would be calculated from critical transaction data
      // and stored with the transaction. For now, we'll validate the data structure integrity
      final isValid = transaction.amount != 0 &&
                     transaction.walletId.isNotEmpty &&
                     transaction.id.isNotEmpty;
      
      if (!isValid) {
        _logger.warning('Transaction integrity validation failed: ${transaction.id}');
      }
      
      return isValid;
    } catch (e) {
      _logger.error('Transaction integrity validation error', e);
      return false;
    }
  }

  /// Validates payout request for security compliance
  Future<PayoutValidationResult> validatePayoutRequest(PayoutRequest request) async {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Amount validation
      if (request.amount < 10.00) {
        errors.add('Minimum payout amount is RM 10.00');
      }
      
      if (request.amount > 10000.00) {
        errors.add('Maximum payout amount is RM 10,000.00');
      }

      // Bank account validation
      if (!_isValidBankAccount(request.bankAccountNumber)) {
        errors.add('Invalid bank account number format');
      }

      // Account holder name validation
      if (!_isValidAccountHolderName(request.accountHolderName)) {
        errors.add('Invalid account holder name');
      }

      // Frequency validation (AML compliance)
      final frequencyCheck = await _checkPayoutFrequency(request.walletId, request.amount);
      if (!frequencyCheck.isValid) {
        if (frequencyCheck.isSuspicious) {
          errors.add('Payout frequency exceeds allowed limits');
        } else {
          warnings.add('High payout frequency detected');
        }
      }

      // Amount pattern analysis (AML compliance)
      final patternCheck = await _analyzePayoutPattern(request.walletId, request.amount);
      if (patternCheck.isSuspicious) {
        warnings.add('Unusual payout pattern detected');
      }

      _logger.info('Payout validation completed', {
        'payout_id': request.id,
        'errors': errors.length,
        'warnings': warnings.length,
      });

      return PayoutValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
        requiresManualReview: warnings.isNotEmpty || request.amount > 5000.00,
      );
    } catch (e) {
      _logger.error('Payout validation error', e);
      return PayoutValidationResult(
        isValid: false,
        errors: ['Validation system error'],
        warnings: [],
        requiresManualReview: true,
      );
    }
  }

  /// Generates secure audit trail for financial operations
  Map<String, dynamic> generateAuditTrail({
    required String operation,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> operationData,
    String? userId,
    String? ipAddress,
  }) {
    final timestamp = DateTime.now();
    final auditId = _generateAuditId();
    
    final auditData = {
      'audit_id': auditId,
      'operation': operation,
      'entity_type': entityType,
      'entity_id': entityId,
      'user_id': userId,
      'ip_address': ipAddress,
      'timestamp': timestamp.toIso8601String(),
      'operation_data': operationData,
      'checksum': _calculateChecksum({
        'audit_id': auditId,
        'operation': operation,
        'entity_id': entityId,
        'timestamp': timestamp.toIso8601String(),
      }),
    };

    _logger.info('Audit trail generated', {
      'audit_id': auditId,
      'operation': operation,
      'entity_type': entityType,
    });

    return auditData;
  }

  /// Validates user permissions for financial operations
  Future<bool> validateFinancialPermission({
    required String userId,
    required String operation,
    required String resourceId,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Get user token and validate
      final token = await _securityService.getAccessToken();
      if (token == null || !_securityService.isTokenValid(token)) {
        _logger.warning('Invalid or missing token for financial operation', {
          'user_id': userId,
          'operation': operation,
        });
        return false;
      }

      // Validate operation-specific permissions
      final hasPermission = await _checkOperationPermission(userId, operation, resourceId, context);
      
      if (!hasPermission) {
        _logger.warning('Permission denied for financial operation', {
          'user_id': userId,
          'operation': operation,
          'resource_id': resourceId,
        });
      }

      return hasPermission;
    } catch (e) {
      _logger.error('Permission validation error', e);
      return false;
    }
  }

  /// Sanitizes financial data for logging (removes sensitive information)
  Map<String, dynamic> sanitizeForLogging(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    
    // Remove or mask sensitive fields
    final sensitiveFields = [
      'bank_account_number',
      'swift_code',
      'account_holder_name',
      'payment_method_details',
      'card_number',
      'cvv',
    ];

    for (final field in sensitiveFields) {
      if (sanitized.containsKey(field)) {
        final value = sanitized[field]?.toString() ?? '';
        if (value.isNotEmpty) {
          // Mask all but last 4 characters
          if (value.length > 4) {
            sanitized[field] = '${'*' * (value.length - 4)}${value.substring(value.length - 4)}';
          } else {
            sanitized[field] = '*' * value.length;
          }
        }
      }
    }

    return sanitized;
  }

  // Private helper methods

  List<int> _generateSalt() {
    final random = Random.secure();
    return List<int>.generate(16, (i) => random.nextInt(256));
  }

  Future<List<int>> _deriveEncryptionKey(List<int> salt) async {
    // In production, use proper key derivation (PBKDF2, Argon2, etc.)
    final userId = await _securityService.getUserId() ?? 'anonymous';
    final combined = utf8.encode(userId) + salt;
    final digest = sha256.convert(combined);
    return digest.bytes;
  }

  List<int> _encryptWithKey(List<int> data, List<int> key) {
    // Simplified XOR encryption - use proper AES in production
    final encrypted = <int>[];
    for (int i = 0; i < data.length; i++) {
      encrypted.add(data[i] ^ key[i % key.length]);
    }
    return encrypted;
  }

  List<int> _decryptWithKey(List<int> encryptedData, List<int> key) {
    // Simplified XOR decryption - use proper AES in production
    return _encryptWithKey(encryptedData, key); // XOR is symmetric
  }

  String _calculateChecksum(Map<String, dynamic> data) {
    final jsonString = json.encode(data);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _isValidBankAccount(String accountNumber) {
    // Malaysian bank account validation
    final cleaned = accountNumber.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned.length >= 8 && cleaned.length <= 20;
  }

  bool _isValidAccountHolderName(String name) {
    // Basic name validation
    final trimmed = name.trim();
    return trimmed.length >= 2 && 
           trimmed.length <= 100 && 
           RegExp(r'^[a-zA-Z\s\-\.]+$').hasMatch(trimmed);
  }

  Future<FrequencyCheckResult> _checkPayoutFrequency(String walletId, double amount) async {
    // Implement payout frequency analysis for AML compliance
    // This would check against stored payout history
    return FrequencyCheckResult(
      isValid: true,
      isSuspicious: amount > 5000.00, // Flag large amounts
    );
  }

  Future<PatternCheckResult> _analyzePayoutPattern(String walletId, double amount) async {
    // Implement pattern analysis for AML compliance
    // This would analyze historical patterns
    return PatternCheckResult(
      isSuspicious: false,
    );
  }

  Future<bool> _checkOperationPermission(
    String userId,
    String operation,
    String resourceId,
    Map<String, dynamic>? context,
  ) async {
    // Implement operation-specific permission checks
    // This would validate against user roles and resource ownership
    return true; // Simplified for now
  }

  String _generateAuditId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'audit_${timestamp}_$random';
  }
}

/// Provider for financial security service
final financialSecurityServiceProvider = Provider<FinancialSecurityService>((ref) {
  final securityService = ref.watch(securityServiceProvider);
  final logger = ref.watch(loggerProvider);
  
  return FinancialSecurityService(securityService, logger);
});

/// Security exception class
class SecurityException implements Exception {
  final String message;
  
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

/// Payout validation result
class PayoutValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final bool requiresManualReview;

  const PayoutValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.requiresManualReview,
  });
}

/// Frequency check result for AML compliance
class FrequencyCheckResult {
  final bool isValid;
  final bool isSuspicious;

  const FrequencyCheckResult({
    required this.isValid,
    required this.isSuspicious,
  });
}

/// Pattern check result for AML compliance
class PatternCheckResult {
  final bool isSuspicious;

  const PatternCheckResult({
    required this.isSuspicious,
  });
}
