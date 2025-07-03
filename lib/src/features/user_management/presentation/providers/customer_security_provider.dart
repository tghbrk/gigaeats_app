import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
// TODO: Restore when customer_security.dart is implemented
// import '../../data/models/customer_security.dart';
import '../../data/services/customer_security_service.dart';
import '../../data/services/biometric_auth_service.dart';

/// Provider for security service
final customerSecurityServiceProvider = Provider<CustomerSecurityService>((ref) {
  return CustomerSecurityService();
});

/// Provider for biometric auth service
final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

/// State class for customer security
class CustomerSecurityState {
  final bool isLoading;
  final String? errorMessage;
  // TODO: Restore when CustomerSecurity model is implemented
  final Map<String, dynamic>? security; // Placeholder for CustomerSecurity
  // TODO: Restore when SecurityAuditLog model is implemented
  final List<Map<String, dynamic>> auditLogs; // Placeholder for SecurityAuditLog
  // TODO: Restore when DeviceInfo model is implemented
  final List<Map<String, dynamic>> devices; // Placeholder for DeviceInfo
  final bool biometricAvailable;
  final List<BiometricType> availableBiometrics;
  final bool isLocked;
  final DateTime? lastActivity;

  const CustomerSecurityState({
    this.isLoading = false,
    this.errorMessage,
    this.security,
    this.auditLogs = const [],
    this.devices = const [],
    this.biometricAvailable = false,
    this.availableBiometrics = const [],
    this.isLocked = false,
    this.lastActivity,
  });

  CustomerSecurityState copyWith({
    bool? isLoading,
    String? errorMessage,
    // TODO: Restore when CustomerSecurity model is implemented
    Map<String, dynamic>? security, // Placeholder for CustomerSecurity
    // TODO: Restore when SecurityAuditLog model is implemented
    List<Map<String, dynamic>>? auditLogs, // Placeholder for SecurityAuditLog
    // TODO: Restore when DeviceInfo model is implemented
    List<Map<String, dynamic>>? devices, // Placeholder for DeviceInfo
    bool? biometricAvailable,
    List<BiometricType>? availableBiometrics,
    bool? isLocked,
    DateTime? lastActivity,
  }) {
    return CustomerSecurityState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      security: security ?? this.security,
      auditLogs: auditLogs ?? this.auditLogs,
      devices: devices ?? this.devices,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      availableBiometrics: availableBiometrics ?? this.availableBiometrics,
      isLocked: isLocked ?? this.isLocked,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
}

/// Notifier for customer security
class CustomerSecurityNotifier extends StateNotifier<CustomerSecurityState> {
  final CustomerSecurityService _securityService;
  final BiometricAuthService _biometricService;
  final Ref _ref;

  CustomerSecurityNotifier(this._securityService, this._biometricService, this._ref) 
      : super(const CustomerSecurityState());

  /// Load security settings
  Future<void> loadSecuritySettings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Load security settings
      final security = await _securityService.getSecuritySettings(user.id);
      
      // Check biometric availability
      final biometricAvailable = await _biometricService.isAvailable();
      final availableBiometrics = await _biometricService.getAvailableBiometrics();

      state = state.copyWith(
        isLoading: false,
        security: security,
        biometricAvailable: biometricAvailable,
        availableBiometrics: availableBiometrics,
        lastActivity: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Enable biometric authentication
  Future<void> enableBiometric() async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // First authenticate with biometrics to ensure it works
      final authResult = await _biometricService.authenticate(
        reason: 'Enable biometric authentication for your wallet',
      );

      if (!authResult.isSuccess) {
        throw Exception(authResult.errorMessage ?? 'Biometric authentication failed');
      }

      // Enable biometric in settings
      await _securityService.enableBiometric(user.id);

      // Log security event
      await _securityService.logSecurityEvent(
        userId: user.id,
        action: 'enable_biometric',
        description: 'Biometric authentication enabled',
        // TODO: Restore when SecurityEventType and SecurityRiskLevel are implemented
        // eventType: SecurityEventType.settings,
        // riskLevel: SecurityRiskLevel.low,
        eventType: 'settings', // Placeholder
        riskLevel: 'low', // Placeholder
      );

      // Reload settings
      await loadSecuritySettings();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _securityService.disableBiometric(user.id);

      // Log security event
      await _securityService.logSecurityEvent(
        userId: user.id,
        action: 'disable_biometric',
        description: 'Biometric authentication disabled',
        // TODO: Restore when SecurityEventType and SecurityRiskLevel are implemented
        // eventType: SecurityEventType.settings,
        // riskLevel: SecurityRiskLevel.medium,
        eventType: 'settings', // Placeholder
        riskLevel: 'medium', // Placeholder
      );

      // Reload settings
      await loadSecuritySettings();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Set PIN
  Future<void> setPIN(String pin) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _securityService.setPIN(user.id, pin);

      // Log security event
      await _securityService.logSecurityEvent(
        userId: user.id,
        action: 'set_pin',
        description: 'PIN authentication enabled',
        // TODO: Restore when SecurityEventType and SecurityRiskLevel are implemented
        // eventType: SecurityEventType.settings,
        // riskLevel: SecurityRiskLevel.low,
        eventType: 'settings', // Placeholder
        riskLevel: 'high', // Placeholder
      );

      // Reload settings
      await loadSecuritySettings();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Verify PIN
  Future<bool> verifyPIN(String pin) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final isValid = await _securityService.verifyPIN(user.id, pin);

      // Log security event
      await _securityService.logSecurityEvent(
        userId: user.id,
        action: 'verify_pin',
        description: isValid ? 'PIN verification successful' : 'PIN verification failed',
        // TODO: Restore when SecurityEventType and SecurityRiskLevel are implemented
        // eventType: SecurityEventType.authentication,
        // riskLevel: isValid ? SecurityRiskLevel.low : SecurityRiskLevel.medium,
        eventType: 'authentication', // Placeholder
        riskLevel: isValid ? 'low' : 'medium', // Placeholder
      );

      return isValid;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Remove PIN
  Future<void> removePIN() async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _securityService.removePIN(user.id);

      // Log security event
      await _securityService.logSecurityEvent(
        userId: user.id,
        action: 'remove_pin',
        description: 'PIN authentication disabled',
        // TODO: Restore when SecurityEventType and SecurityRiskLevel are implemented
        // eventType: SecurityEventType.settings,
        // riskLevel: SecurityRiskLevel.medium,
        eventType: 'settings', // Placeholder
        riskLevel: 'medium', // Placeholder
      );

      // Reload settings
      await loadSecuritySettings();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Enable auto-lock
  Future<void> enableAutoLock(int timeoutMinutes) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _securityService.enableAutoLock(user.id, timeoutMinutes);

      // Log security event
      await _securityService.logSecurityEvent(
        userId: user.id,
        action: 'enable_auto_lock',
        description: 'Auto-lock enabled with $timeoutMinutes minute timeout',
        // TODO: Restore when SecurityEventType and SecurityRiskLevel are implemented
        // eventType: SecurityEventType.settings,
        // riskLevel: SecurityRiskLevel.low,
        eventType: 'settings', // Placeholder
        riskLevel: 'low', // Placeholder
      );

      // Reload settings
      await loadSecuritySettings();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Disable auto-lock
  Future<void> disableAutoLock() async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _securityService.disableAutoLock(user.id);

      // Log security event
      await _securityService.logSecurityEvent(
        userId: user.id,
        action: 'disable_auto_lock',
        description: 'Auto-lock disabled',
        // TODO: Restore when SecurityEventType and SecurityRiskLevel are implemented
        // eventType: SecurityEventType.settings,
        // riskLevel: SecurityRiskLevel.medium,
        eventType: 'settings', // Placeholder
        riskLevel: 'medium', // Placeholder
      );

      // Reload settings
      await loadSecuritySettings();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Enable transaction PIN
  Future<void> enableTransactionPIN(double threshold) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _securityService.enableTransactionPIN(user.id, threshold);

      // TODO: Restore when SecurityEventType and SecurityRiskLevel are implemented
      // Log security event
      // await _securityService.logSecurityEvent(
      //   userId: user.id,
      //   action: 'enable_transaction_pin',
      //   description: 'Transaction PIN enabled for amounts above RM ${threshold.toStringAsFixed(2)}',
      //   eventType: SecurityEventType.settings,
      //   riskLevel: SecurityRiskLevel.low,
      // );

      // Reload settings
      await loadSecuritySettings();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Enable multi-factor authentication
  Future<void> enableMFA() async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _securityService.enableMFA(user.id);

      // TODO: Restore when SecurityEventType and SecurityRiskLevel are implemented
      // Log security event
      // await _securityService.logSecurityEvent(
      //   userId: user.id,
      //   action: 'enable_mfa',
      //   description: 'Multi-factor authentication enabled',
      //   eventType: SecurityEventType.settings,
      //   riskLevel: SecurityRiskLevel.low,
      // );

      // Reload settings
      await loadSecuritySettings();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Disable multi-factor authentication
  Future<void> disableMFA() async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _securityService.disableMFA(user.id);

      // TODO: Restore when SecurityEventType and SecurityRiskLevel are implemented
      // Log security event
      // await _securityService.logSecurityEvent(
      //   userId: user.id,
      //   action: 'disable_mfa',
      //   description: 'Multi-factor authentication disabled',
      //   eventType: SecurityEventType.settings,
      //   riskLevel: SecurityRiskLevel.medium,
      // );

      // Reload settings
      await loadSecuritySettings();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Disable transaction PIN requirement
  Future<void> disableTransactionPIN() async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _securityService.disableTransactionPIN(user.id);

      // TODO: Restore when SecurityEventType and SecurityRiskLevel are implemented
      // Log security event
      // await _securityService.logSecurityEvent(
      //   userId: user.id,
      //   action: 'disable_transaction_pin',
      //   description: 'Transaction PIN requirement disabled',
      //   eventType: SecurityEventType.settings,
      //   riskLevel: SecurityRiskLevel.medium,
      // );

      // Reload settings
      await loadSecuritySettings();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Authenticate with biometrics
  Future<BiometricAuthResult> authenticateWithBiometrics(String reason) async {
    try {
      final result = await _biometricService.authenticate(reason: reason);
      
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user != null) {
        // TODO: Restore when SecurityEventType and SecurityRiskLevel are implemented
        // Log authentication attempt
        // await _securityService.logSecurityEvent(
        //   userId: user.id,
        //   action: 'biometric_auth',
        //   description: result.isSuccess ? 'Biometric authentication successful' : 'Biometric authentication failed',
        //   eventType: SecurityEventType.authentication,
        //   riskLevel: result.isSuccess ? SecurityRiskLevel.low : SecurityRiskLevel.medium,
        // );
      }

      return result;
    } catch (e) {
      return BiometricAuthResult.error(BiometricAuthError.unknown);
    }
  }

  // TODO: Restore when SecurityEventType and SecurityRiskLevel are implemented
  // /// Load audit logs
  // Future<void> loadAuditLogs({
  //   int? limit,
  //   DateTime? startDate,
  //   DateTime? endDate,
  //   SecurityEventType? eventType,
  //   SecurityRiskLevel? riskLevel,
  // }) async {
  //   try {
  //     final authState = _ref.read(authStateProvider);
  //     final user = authState.user;
  //
  //     if (user == null) {
  //       throw Exception('User not authenticated');
  //     }
  //
  //     final logs = await _securityService.getSecurityAuditLogs(
  //       userId: user.id,
  //       limit: limit,
  //       startDate: startDate,
  //       endDate: endDate,
  //       eventType: eventType,
  //       riskLevel: riskLevel,
  //     );
  //
  //     state = state.copyWith(auditLogs: logs);
  //   } catch (e) {
  //     state = state.copyWith(errorMessage: e.toString());
  //   }
  // }

  /// Load user devices
  Future<void> loadUserDevices() async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final devices = await _securityService.getUserDevices(user.id);
      state = state.copyWith(devices: devices);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Check for suspicious activity
  // TODO: Restore when SecurityAuditLog is implemented
  Future<List<Map<String, dynamic>>> checkSuspiciousActivity() async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      return await _securityService.checkSuspiciousActivity(user.id);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return [];
    }
  }

  /// Validate transaction security
  Future<Map<String, dynamic>> validateTransactionSecurity({
    required double amount,
    String? deviceId,
    String? location,
  }) async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      return await _securityService.validateTransactionSecurity(
        userId: user.id,
        amount: amount,
        deviceId: deviceId,
        location: location,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Update last activity
  void updateLastActivity() {
    state = state.copyWith(lastActivity: DateTime.now());
  }

  /// Lock the app
  void lockApp() {
    state = state.copyWith(isLocked: true);
  }

  /// Unlock the app
  void unlockApp() {
    state = state.copyWith(isLocked: false, lastActivity: DateTime.now());
  }

  /// Check if app should be auto-locked
  bool shouldAutoLock() {
    // TODO: Restore when autoLockEnabled is implemented in security model
    if (state.security?['autoLockEnabled'] != true || state.lastActivity == null) {
      return false;
    }

    // TODO: Restore when autoLockTimeoutMinutes is implemented in security model
    final timeoutMinutes = state.security!['autoLockTimeoutMinutes'] ?? 5;
    final timeSinceLastActivity = DateTime.now().difference(state.lastActivity!);
    
    return timeSinceLastActivity.inMinutes >= timeoutMinutes;
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Refresh all security data
  Future<void> refreshAll() async {
    await loadSecuritySettings();
    // TODO: Restore when loadAuditLogs is implemented
    // await loadAuditLogs(limit: 20);
    await loadUserDevices();
  }
}

/// Provider for customer security state management
final customerSecurityProvider = StateNotifierProvider<CustomerSecurityNotifier, CustomerSecurityState>((ref) {
  final securityService = ref.watch(customerSecurityServiceProvider);
  final biometricService = ref.watch(biometricAuthServiceProvider);
  return CustomerSecurityNotifier(securityService, biometricService, ref);
});

/// Provider for security settings as AsyncValue
// TODO: Restore when CustomerSecurity is implemented
final securitySettingsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  
  if (user == null) {
    return null;
  }

  final securityService = ref.watch(customerSecurityServiceProvider);
  // TODO: Restore when getSecuritySettings returns proper type
  final result = await securityService.getSecuritySettings(user.id);
  return result as Map<String, dynamic>?;
});

/// Provider for biometric availability
final biometricAvailabilityProvider = FutureProvider<bool>((ref) async {
  final biometricService = ref.watch(biometricAuthServiceProvider);
  return biometricService.isAvailable();
});

/// Provider for available biometric types
final availableBiometricsProvider = FutureProvider<List<BiometricType>>((ref) async {
  final biometricService = ref.watch(biometricAuthServiceProvider);
  return biometricService.getAvailableBiometrics();
});
