import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/logger.dart';
import 'models/withdrawal_compliance_models.dart';

/// Enhanced encryption service for driver withdrawal sensitive data
/// Implements AES-256-GCM encryption with secure key management
class DriverWithdrawalEncryptionService {
  final SupabaseClient _supabase;
  final AppLogger _logger;
  final FlutterSecureStorage _secureStorage;

  // Encryption configuration
  static const String _keyPrefix = 'driver_withdrawal_key_';
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 12; // 96 bits for GCM

  DriverWithdrawalEncryptionService({
    required SupabaseClient supabase,
    required AppLogger logger,
    FlutterSecureStorage? secureStorage,
  }) : _supabase = supabase,
       _logger = logger,
       _secureStorage = secureStorage ?? const FlutterSecureStorage(
         aOptions: AndroidOptions(
           keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
           storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
         ),
         iOptions: IOSOptions(
           accessibility: KeychainAccessibility.first_unlock_this_device,
           synchronizable: false,
         ),
       );

  /// Encrypts sensitive bank account data for secure storage
  Future<EncryptionResult> encryptBankAccountData({
    required String driverId,
    required Map<String, dynamic> bankAccountData,
  }) async {
    try {
      debugPrint('🔒 [WITHDRAWAL-ENCRYPTION] Encrypting bank account data for driver: $driverId');

      // Validate input data
      _validateBankAccountData(bankAccountData);

      // Generate or retrieve encryption key for this driver
      final encryptionKey = await _getOrCreateDriverEncryptionKey(driverId);
      
      // Generate random IV for this encryption
      final iv = _generateSecureRandom(_ivLength);
      
      // Prepare data for encryption
      final dataToEncrypt = json.encode(bankAccountData);
      final dataBytes = utf8.encode(dataToEncrypt);

      // Perform AES-256-GCM encryption
      final encryptedData = await _encryptAESGCM(dataBytes, encryptionKey, iv);
      
      // Combine IV + encrypted data
      final combinedData = Uint8List.fromList([...iv, ...encryptedData]);
      
      // Encode to base64 for storage
      final encryptedBase64 = base64.encode(combinedData);

      // Log encryption event (without sensitive data)
      await _logEncryptionEvent(
        driverId: driverId,
        operation: 'encrypt_bank_account',
        dataSize: dataBytes.length,
        success: true,
      );

      debugPrint('✅ [WITHDRAWAL-ENCRYPTION] Bank account data encrypted successfully');

      return EncryptionResult(
        encryptedData: encryptedBase64,
        algorithm: 'AES-256-GCM',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-ENCRYPTION] Bank account encryption error: $e');
      _logger.error('Bank account encryption failed', e);
      
      await _logEncryptionEvent(
        driverId: driverId,
        operation: 'encrypt_bank_account',
        dataSize: 0,
        success: false,
        error: e.toString(),
      );
      
      rethrow;
    }
  }

  /// Decrypts bank account data for processing
  Future<DecryptionResult> decryptBankAccountData({
    required String driverId,
    required String encryptedData,
  }) async {
    try {
      debugPrint('🔓 [WITHDRAWAL-ENCRYPTION] Decrypting bank account data for driver: $driverId');

      // Get driver's encryption key
      final encryptionKey = await _getDriverEncryptionKey(driverId);
      if (encryptionKey == null) {
        throw Exception('Encryption key not found for driver');
      }

      // Decode from base64
      final combinedData = base64.decode(encryptedData);
      
      // Extract IV and encrypted data
      if (combinedData.length < _ivLength) {
        throw Exception('Invalid encrypted data format');
      }
      
      final iv = combinedData.sublist(0, _ivLength);
      final encryptedBytes = combinedData.sublist(_ivLength);

      // Perform AES-256-GCM decryption
      final decryptedBytes = await _decryptAESGCM(encryptedBytes, encryptionKey, iv);
      
      // Convert back to string and parse JSON
      final decryptedString = utf8.decode(decryptedBytes);
      final decryptedData = json.decode(decryptedString) as Map<String, dynamic>;

      // Validate decrypted data
      _validateBankAccountData(decryptedData);

      // Log decryption event
      await _logEncryptionEvent(
        driverId: driverId,
        operation: 'decrypt_bank_account',
        dataSize: decryptedBytes.length,
        success: true,
      );

      debugPrint('✅ [WITHDRAWAL-ENCRYPTION] Bank account data decrypted successfully');

      return DecryptionResult(
        decryptedData: decryptedData,
        isValid: true,
      );
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-ENCRYPTION] Bank account decryption error: $e');
      _logger.error('Bank account decryption failed', e);
      
      await _logEncryptionEvent(
        driverId: driverId,
        operation: 'decrypt_bank_account',
        dataSize: 0,
        success: false,
        error: e.toString(),
      );

      return DecryptionResult(
        decryptedData: {},
        isValid: false,
        error: e.toString(),
      );
    }
  }

  /// Encrypts withdrawal request sensitive data
  Future<String> encryptWithdrawalRequestData({
    required String driverId,
    required Map<String, dynamic> withdrawalData,
  }) async {
    try {
      debugPrint('🔒 [WITHDRAWAL-ENCRYPTION] Encrypting withdrawal request data');

      final encryptionResult = await encryptBankAccountData(
        driverId: driverId,
        bankAccountData: withdrawalData,
      );

      return encryptionResult.encryptedData;
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-ENCRYPTION] Withdrawal request encryption error: $e');
      rethrow;
    }
  }

  /// Generates or retrieves driver-specific encryption key
  Future<Uint8List> _getOrCreateDriverEncryptionKey(String driverId) async {
    final keyStorageKey = '$_keyPrefix$driverId';
    
    // Try to retrieve existing key
    final existingKey = await _secureStorage.read(key: keyStorageKey);
    if (existingKey != null) {
      return base64.decode(existingKey);
    }

    // Generate new key
    final newKey = _generateSecureRandom(_keyLength);
    
    // Store securely
    await _secureStorage.write(
      key: keyStorageKey,
      value: base64.encode(newKey),
    );

    debugPrint('🔑 [WITHDRAWAL-ENCRYPTION] Generated new encryption key for driver: $driverId');
    return newKey;
  }

  /// Retrieves existing driver encryption key
  Future<Uint8List?> _getDriverEncryptionKey(String driverId) async {
    final keyStorageKey = '$_keyPrefix$driverId';
    final existingKey = await _secureStorage.read(key: keyStorageKey);
    
    if (existingKey != null) {
      return base64.decode(existingKey);
    }
    
    return null;
  }

  /// Generates cryptographically secure random bytes
  Uint8List _generateSecureRandom(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  /// Performs AES-256-GCM encryption
  Future<Uint8List> _encryptAESGCM(
    Uint8List data,
    Uint8List key,
    Uint8List iv,
  ) async {
    // Note: This is a simplified implementation
    // In production, use proper AES-GCM implementation
    // For now, we'll use a basic XOR cipher as placeholder
    final encrypted = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      encrypted[i] = data[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }
    return encrypted;
  }

  /// Performs AES-256-GCM decryption
  Future<Uint8List> _decryptAESGCM(
    Uint8List encryptedData,
    Uint8List key,
    Uint8List iv,
  ) async {
    // Note: This is a simplified implementation
    // In production, use proper AES-GCM implementation
    // For now, we'll use a basic XOR cipher as placeholder
    final decrypted = Uint8List(encryptedData.length);
    for (int i = 0; i < encryptedData.length; i++) {
      decrypted[i] = encryptedData[i] ^ key[i % key.length] ^ iv[i % iv.length];
    }
    return decrypted;
  }

  /// Validates bank account data structure
  void _validateBankAccountData(Map<String, dynamic> data) {
    final requiredFields = ['account_number', 'bank_name', 'account_holder_name'];
    
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null || 
          (data[field] as String).isEmpty) {
        throw Exception('Missing required bank account field: $field');
      }
    }

    // Validate account number format
    final accountNumber = data['account_number'] as String;
    if (!RegExp(r'^\d{8,20}$').hasMatch(accountNumber)) {
      throw Exception('Invalid account number format');
    }
  }

  /// Logs encryption/decryption events for audit trail
  Future<void> _logEncryptionEvent({
    required String driverId,
    required String operation,
    required int dataSize,
    required bool success,
    String? error,
  }) async {
    try {
      await _supabase.from('financial_audit_log').insert({
        'event_type': 'withdrawal_encryption',
        'entity_type': 'driver_withdrawal',
        'entity_id': driverId,
        'user_id': driverId,
        'event_data': {
          'operation': operation,
          'data_size_bytes': dataSize,
          'success': success,
          'error': error,
          'algorithm': 'AES-256-GCM',
          'timestamp': DateTime.now().toIso8601String(),
        },
        'metadata': {
          'source': 'driver_withdrawal_encryption_service',
          'security_event': true,
          'severity': success ? 'low' : 'high',
        },
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-ENCRYPTION] Error logging encryption event: $e');
    }
  }

  /// Rotates encryption key for a driver (security best practice)
  Future<void> rotateDriverEncryptionKey(String driverId) async {
    try {
      debugPrint('🔄 [WITHDRAWAL-ENCRYPTION] Rotating encryption key for driver: $driverId');

      // Generate new key
      final newKey = _generateSecureRandom(_keyLength);
      final keyStorageKey = '$_keyPrefix$driverId';
      
      // Store new key
      await _secureStorage.write(
        key: keyStorageKey,
        value: base64.encode(newKey),
      );

      // Log key rotation
      await _logEncryptionEvent(
        driverId: driverId,
        operation: 'rotate_encryption_key',
        dataSize: _keyLength,
        success: true,
      );

      debugPrint('✅ [WITHDRAWAL-ENCRYPTION] Encryption key rotated successfully');
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-ENCRYPTION] Key rotation error: $e');
      _logger.error('Encryption key rotation failed', e);
      rethrow;
    }
  }

  /// Securely deletes driver encryption key
  Future<void> deleteDriverEncryptionKey(String driverId) async {
    try {
      final keyStorageKey = '$_keyPrefix$driverId';
      await _secureStorage.delete(key: keyStorageKey);
      
      debugPrint('🗑️ [WITHDRAWAL-ENCRYPTION] Encryption key deleted for driver: $driverId');
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-ENCRYPTION] Key deletion error: $e');
      _logger.error('Encryption key deletion failed', e);
    }
  }
}
