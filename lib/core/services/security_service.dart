import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../utils/logger.dart';
import '../errors/exceptions.dart';

/// Security service for managing tokens, encryption, and secure storage
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final AppLogger _logger = AppLogger();

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _encryptionKeyKey = 'encryption_key';

  // Secure storage configuration
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
    lOptions: LinuxOptions(),
    webOptions: WebOptions(
      dbName: 'gigaeats_secure_storage',
      publicKey: 'gigaeats_public_key',
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );

  /// Stores authentication tokens securely
  Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
  }) async {
    try {
      await Future.wait([
        _secureStorage.write(key: _accessTokenKey, value: accessToken),
        _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
        if (userId != null) _secureStorage.write(key: _userIdKey, value: userId),
      ]);
      
      _logger.info('Tokens stored securely');
    } catch (e) {
      _logger.error('Failed to store tokens', e);
      throw StorageException(message: 'Failed to store authentication tokens');
    }
  }

  /// Retrieves access token
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _accessTokenKey);
    } catch (e) {
      _logger.error('Failed to retrieve access token', e);
      return null;
    }
  }

  /// Retrieves refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      _logger.error('Failed to retrieve refresh token', e);
      return null;
    }
  }

  /// Retrieves stored user ID
  Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: _userIdKey);
    } catch (e) {
      _logger.error('Failed to retrieve user ID', e);
      return null;
    }
  }

  /// Clears all stored tokens
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
        _secureStorage.delete(key: _userIdKey),
      ]);
      
      _logger.info('Tokens cleared');
    } catch (e) {
      _logger.error('Failed to clear tokens', e);
      throw StorageException(message: 'Failed to clear authentication tokens');
    }
  }

  /// Validates JWT token format and expiration
  bool isTokenValid(String? token) {
    if (token == null || token.isEmpty) return false;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      
      // Decode payload
      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final decodedPayload = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = json.decode(decodedPayload) as Map<String, dynamic>;
      
      // Check expiration
      final exp = payloadMap['exp'] as int?;
      if (exp == null) return false;
      
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      
      return expirationDate.isAfter(now);
    } catch (e) {
      _logger.warning('Token validation failed', e);
      return false;
    }
  }

  /// Extracts user ID from JWT token
  String? getUserIdFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final decodedPayload = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = json.decode(decodedPayload) as Map<String, dynamic>;
      
      return payloadMap['sub'] as String?;
    } catch (e) {
      _logger.warning('Failed to extract user ID from token', e);
      return null;
    }
  }

  /// Generates a secure random string
  String generateSecureRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Hashes a string using SHA-256
  String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generates API security headers
  Map<String, String> getSecurityHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
    };

    if (!kIsWeb) {
      headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains';
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Stores encrypted data
  Future<void> storeEncryptedData(String key, String data) async {
    try {
      // For now, we rely on FlutterSecureStorage's encryption
      // In a more advanced implementation, you might add additional encryption layers
      await _secureStorage.write(key: key, value: data);
      _logger.debug('Encrypted data stored for key: $key');
    } catch (e) {
      _logger.error('Failed to store encrypted data', e);
      throw StorageException(message: 'Failed to store encrypted data');
    }
  }

  /// Retrieves encrypted data
  Future<String?> getEncryptedData(String key) async {
    try {
      final data = await _secureStorage.read(key: key);
      if (data != null) {
        _logger.debug('Encrypted data retrieved for key: $key');
      }
      return data;
    } catch (e) {
      _logger.error('Failed to retrieve encrypted data', e);
      return null;
    }
  }

  /// Deletes encrypted data
  Future<void> deleteEncryptedData(String key) async {
    try {
      await _secureStorage.delete(key: key);
      _logger.debug('Encrypted data deleted for key: $key');
    } catch (e) {
      _logger.error('Failed to delete encrypted data', e);
      throw StorageException(message: 'Failed to delete encrypted data');
    }
  }

  /// Clears all secure storage
  Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
      _logger.info('All secure data cleared');
    } catch (e) {
      _logger.error('Failed to clear all secure data', e);
      throw StorageException(message: 'Failed to clear all secure data');
    }
  }

  /// Checks if device has secure storage capabilities
  Future<bool> hasSecureStorage() async {
    try {
      // Test write and read
      const testKey = 'test_key';
      const testValue = 'test_value';
      
      await _secureStorage.write(key: testKey, value: testValue);
      final retrievedValue = await _secureStorage.read(key: testKey);
      await _secureStorage.delete(key: testKey);
      
      return retrievedValue == testValue;
    } catch (e) {
      _logger.warning('Secure storage test failed', e);
      return false;
    }
  }
}
