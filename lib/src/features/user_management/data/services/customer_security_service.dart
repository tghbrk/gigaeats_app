import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// TODO: Restore when customer_security models are implemented
// import '../models/customer_security.dart';

/// Service for managing customer security features
class CustomerSecurityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get security settings for a user
  // TODO: Restore when CustomerSecurity is implemented
  Future<dynamic> getSecuritySettings(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'security-settings',
        body: {
          'action': 'get',
          'user_id': userId,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to load security settings');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to load security settings: ${data['error']}');
      }

      if (data['settings'] == null) {
        // Return default settings if none exist
        // TODO: Restore when CustomerSecurity is implemented
        // return CustomerSecurity(
        //   userId: userId,
        //   lastSecurityUpdate: DateTime.now(),
        // );
        return {
          'userId': userId,
          'lastSecurityUpdate': DateTime.now().toIso8601String(),
        }; // Placeholder
      }

      // TODO: Restore when CustomerSecurity is implemented
      // return CustomerSecurity.fromJson(data['settings'] as Map<String, dynamic>);
      return data['settings'] as Map<String, dynamic>; // Placeholder
    } on FunctionException catch (e) {
      throw Exception('Failed to load security settings: ${e.details}');
    } catch (e) {
      throw Exception('Failed to load security settings: ${e.toString()}');
    }
  }

  /// Update security settings
  Future<void> updateSecuritySettings(String userId, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase.functions.invoke(
        'security-settings',
        body: {
          'action': 'update',
          'user_id': userId,
          'updates': updates,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to update security settings');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to update security settings: ${data['error']}');
      }
    } on FunctionException catch (e) {
      throw Exception('Failed to update security settings: ${e.details}');
    } catch (e) {
      throw Exception('Failed to update security settings: ${e.toString()}');
    }
  }

  /// Enable biometric authentication
  Future<void> enableBiometric(String userId) async {
    await updateSecuritySettings(userId, {
      'biometric_enabled': true,
      'last_security_update': DateTime.now().toIso8601String(),
    });
  }

  /// Disable biometric authentication
  Future<void> disableBiometric(String userId) async {
    await updateSecuritySettings(userId, {
      'biometric_enabled': false,
      'last_security_update': DateTime.now().toIso8601String(),
    });
  }

  /// Set PIN for user
  Future<void> setPIN(String userId, String pin) async {
    final pinHash = _hashPIN(pin);
    await updateSecuritySettings(userId, {
      'pin_enabled': true,
      'pin_hash': pinHash,
      'last_security_update': DateTime.now().toIso8601String(),
    });
  }

  /// Verify PIN
  Future<bool> verifyPIN(String userId, String pin) async {
    try {
      final security = await getSecuritySettings(userId);
      if (!security.pinEnabled || security.pinHash == null) {
        return false;
      }

      final pinHash = _hashPIN(pin);
      return pinHash == security.pinHash;
    } catch (e) {
      return false;
    }
  }

  /// Remove PIN
  Future<void> removePIN(String userId) async {
    await updateSecuritySettings(userId, {
      'pin_enabled': false,
      'pin_hash': null,
      'last_security_update': DateTime.now().toIso8601String(),
    });
  }

  /// Enable auto-lock
  Future<void> enableAutoLock(String userId, int timeoutMinutes) async {
    await updateSecuritySettings(userId, {
      'auto_lock_enabled': true,
      'auto_lock_timeout_minutes': timeoutMinutes,
      'last_security_update': DateTime.now().toIso8601String(),
    });
  }

  /// Disable auto-lock
  Future<void> disableAutoLock(String userId) async {
    await updateSecuritySettings(userId, {
      'auto_lock_enabled': false,
      'last_security_update': DateTime.now().toIso8601String(),
    });
  }

  /// Enable transaction PIN requirement
  Future<void> enableTransactionPIN(String userId, double threshold) async {
    await updateSecuritySettings(userId, {
      'transaction_pin_required': true,
      'large_transaction_threshold': threshold,
      'last_security_update': DateTime.now().toIso8601String(),
    });
  }

  /// Disable transaction PIN requirement
  Future<void> disableTransactionPIN(String userId) async {
    await updateSecuritySettings(userId, {
      'transaction_pin_required': false,
      'last_security_update': DateTime.now().toIso8601String(),
    });
  }

  /// Enable multi-factor authentication
  Future<void> enableMFA(String userId) async {
    await updateSecuritySettings(userId, {
      'mfa_enabled': true,
      'last_security_update': DateTime.now().toIso8601String(),
    });
  }

  /// Disable multi-factor authentication
  Future<void> disableMFA(String userId) async {
    await updateSecuritySettings(userId, {
      'mfa_enabled': false,
      'last_security_update': DateTime.now().toIso8601String(),
    });
  }

  /// Add trusted device
  Future<void> addTrustedDevice(String userId, String deviceId) async {
    try {
      final security = await getSecuritySettings(userId);
      final trustedDevices = List<String>.from(security.trustedDevices);
      
      if (!trustedDevices.contains(deviceId)) {
        trustedDevices.add(deviceId);
        await updateSecuritySettings(userId, {
          'trusted_devices': trustedDevices,
          'last_security_update': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to add trusted device: ${e.toString()}');
    }
  }

  /// Remove trusted device
  Future<void> removeTrustedDevice(String userId, String deviceId) async {
    try {
      final security = await getSecuritySettings(userId);
      final trustedDevices = List<String>.from(security.trustedDevices);
      
      trustedDevices.remove(deviceId);
      await updateSecuritySettings(userId, {
        'trusted_devices': trustedDevices,
        'last_security_update': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to remove trusted device: ${e.toString()}');
    }
  }

  /// Get security audit logs
  // TODO: Restore when SecurityAuditLog is implemented
  Future<List<dynamic>> getSecurityAuditLogs({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
    // TODO: Restore when SecurityEventType and SecurityRiskLevel are implemented
    dynamic eventType,
    dynamic riskLevel,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'security-audit-logs',
        body: {
          'user_id': userId,
          'limit': limit,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'event_type': eventType?.value,
          'risk_level': riskLevel?.value,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to load security audit logs');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to load security audit logs: ${data['error']}');
      }

      // TODO: Restore when SecurityAuditLog model is implemented
      // return (data['logs'] as List<dynamic>)
      //     .map((item) => SecurityAuditLog.fromJson(item as Map<String, dynamic>))
      //     .toList();
      return (data['logs'] as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } on FunctionException catch (e) {
      throw Exception('Failed to load security audit logs: ${e.details}');
    } catch (e) {
      throw Exception('Failed to load security audit logs: ${e.toString()}');
    }
  }

  /// Log security event
  Future<void> logSecurityEvent({
    required String userId,
    required String action,
    required String description,
    String? deviceId,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? metadata,
    // TODO: Restore when SecurityEventType is implemented
    // required SecurityEventType eventType,
    required String eventType, // Placeholder
    // TODO: Restore when SecurityRiskLevel is implemented
    // required SecurityRiskLevel riskLevel,
    required String riskLevel, // Placeholder
  }) async {
    try {
      await _supabase.functions.invoke(
        'log-security-event',
        body: {
          'user_id': userId,
          'action': action,
          'description': description,
          'device_id': deviceId,
          'ip_address': ipAddress,
          'user_agent': userAgent,
          'metadata': metadata,
          // TODO: Restore when SecurityEventType/SecurityRiskLevel are implemented
          // 'event_type': eventType.value,
          // 'risk_level': riskLevel.value,
          'event_type': eventType, // Placeholder
          'risk_level': riskLevel, // Placeholder
        },
      );
    } catch (e) {
      // Don't throw error for logging failures to avoid breaking main functionality
      print('Failed to log security event: $e');
    }
  }

  /// Check for suspicious activity
  // TODO: Restore when SecurityAuditLog is implemented
  // Future<List<SecurityAuditLog>> checkSuspiciousActivity(String userId) async {
  Future<List<Map<String, dynamic>>> checkSuspiciousActivity(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'check-suspicious-activity',
        body: {
          'user_id': userId,
        },
      );

      if (response.data == null) {
        return [];
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to check suspicious activity: ${data['error']}');
      }

      // TODO: Restore when SecurityAuditLog is implemented
      // return (data['suspicious_activities'] as List<dynamic>?)
      //         ?.map((item) => SecurityAuditLog.fromJson(item as Map<String, dynamic>))
      //         .toList() ??
      //     [];
      return (data['suspicious_activities'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          []; // Placeholder
    } on FunctionException catch (e) {
      throw Exception('Failed to check suspicious activity: ${e.details}');
    } catch (e) {
      throw Exception('Failed to check suspicious activity: ${e.toString()}');
    }
  }

  /// Get device information
  // TODO: Restore when DeviceInfo is implemented
  // Future<List<DeviceInfo>> getUserDevices(String userId) async {
  Future<List<Map<String, dynamic>>> getUserDevices(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'user-devices',
        body: {
          'user_id': userId,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to load user devices');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to load user devices: ${data['error']}');
      }

      // TODO: Restore when DeviceInfo is implemented
      // return (data['devices'] as List<dynamic>)
      //     .map((item) => DeviceInfo.fromJson(item as Map<String, dynamic>))
      //     .toList();
      return (data['devices'] as List<dynamic>)
          .cast<Map<String, dynamic>>(); // Placeholder
    } on FunctionException catch (e) {
      throw Exception('Failed to load user devices: ${e.details}');
    } catch (e) {
      throw Exception('Failed to load user devices: ${e.toString()}');
    }
  }

  /// Register current device
  Future<void> registerDevice({
    required String userId,
    required String deviceId,
    required String deviceName,
    required String platform,
    String? model,
    String? osVersion,
    String? appVersion,
    String? location,
  }) async {
    try {
      await _supabase.functions.invoke(
        'register-device',
        body: {
          'user_id': userId,
          'device_id': deviceId,
          'device_name': deviceName,
          'platform': platform,
          'model': model,
          'os_version': osVersion,
          'app_version': appVersion,
          'location': location,
        },
      );
    } on FunctionException catch (e) {
      throw Exception('Failed to register device: ${e.details}');
    } catch (e) {
      throw Exception('Failed to register device: ${e.toString()}');
    }
  }

  /// Validate transaction security
  Future<Map<String, dynamic>> validateTransactionSecurity({
    required String userId,
    required double amount,
    String? deviceId,
    String? location,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'validate-transaction-security',
        body: {
          'user_id': userId,
          'amount': amount,
          'device_id': deviceId,
          'location': location,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to validate transaction security');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to validate transaction security: ${data['error']}');
      }

      return {
        'requires_pin': data['requires_pin'] as bool,
        'requires_biometric': data['requires_biometric'] as bool,
        'requires_mfa': data['requires_mfa'] as bool,
        'risk_level': data['risk_level'] as String,
        'risk_factors': List<String>.from(data['risk_factors'] ?? []),
        'allowed': data['allowed'] as bool,
      };
    } on FunctionException catch (e) {
      throw Exception('Failed to validate transaction security: ${e.details}');
    } catch (e) {
      throw Exception('Failed to validate transaction security: ${e.toString()}');
    }
  }

  /// Hash PIN using SHA-256
  String _hashPIN(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }


}
