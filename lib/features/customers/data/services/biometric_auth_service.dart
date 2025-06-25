import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart' as local_auth;

/// Service for handling biometric authentication using local_auth package
class BiometricAuthService {
  final local_auth.LocalAuthentication _localAuth = local_auth.LocalAuthentication();

  /// Check if biometric authentication is available on the device
  Future<bool> isAvailable() async {
    try {
      final bool isAvailable = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      return isAvailable && canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.map((type) => _mapBiometricType(type)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Map local_auth BiometricType to our custom enum
  BiometricType _mapBiometricType(local_auth.BiometricType type) {
    switch (type) {
      case local_auth.BiometricType.face:
        return BiometricType.face;
      case local_auth.BiometricType.fingerprint:
        return BiometricType.fingerprint;
      case local_auth.BiometricType.iris:
        return BiometricType.iris;
      case local_auth.BiometricType.weak:
        return BiometricType.weak;
      case local_auth.BiometricType.strong:
        return BiometricType.strong;
    }
  }

  /// Authenticate using biometrics
  Future<BiometricAuthResult> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const local_auth.AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: false,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        return BiometricAuthResult.success();
      } else {
        return BiometricAuthResult.error(BiometricAuthError.userCancel);
      }
      
    } on PlatformException catch (e) {
      return BiometricAuthResult.error(_mapPlatformException(e));
    } catch (e) {
      return BiometricAuthResult.error(BiometricAuthError.unknown);
    }
  }

  /// Check if biometric authentication can be used
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Stop biometric authentication
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      // Ignore errors when stopping authentication
    }
  }

  /// Map platform exceptions to biometric auth errors
  BiometricAuthError _mapPlatformException(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return BiometricAuthError.notAvailable;
      case 'NotEnrolled':
        return BiometricAuthError.notEnrolled;
      case 'PasscodeNotSet':
        return BiometricAuthError.passcodeNotSet;
      case 'UserCancel':
        return BiometricAuthError.userCancel;
      case 'UserFallback':
        return BiometricAuthError.userFallback;
      case 'SystemCancel':
        return BiometricAuthError.systemCancel;
      case 'InvalidContext':
        return BiometricAuthError.invalidContext;
      case 'NotInteractive':
        return BiometricAuthError.notInteractive;
      case 'BiometricOnlyNotSupported':
        return BiometricAuthError.biometricOnlyNotSupported;
      case 'DeviceNotSupported':
        return BiometricAuthError.deviceNotSupported;
      case 'ApplicationLock':
        return BiometricAuthError.applicationLock;
      case 'BiometricDisabled':
        return BiometricAuthError.biometricDisabled;
      case 'BiometricLockout':
        return BiometricAuthError.biometricLockout;
      case 'BiometricLockoutPermanent':
        return BiometricAuthError.biometricLockoutPermanent;
      default:
        return BiometricAuthError.unknown;
    }
  }
}

/// Biometric authentication result
class BiometricAuthResult {
  final bool isSuccess;
  final BiometricAuthError? error;

  const BiometricAuthResult._({
    required this.isSuccess,
    this.error,
  });

  factory BiometricAuthResult.success() {
    return const BiometricAuthResult._(isSuccess: true);
  }

  factory BiometricAuthResult.error(BiometricAuthError error) {
    return BiometricAuthResult._(isSuccess: false, error: error);
  }

  /// Get user-friendly error message
  String? get errorMessage {
    if (error == null) return null;
    
    switch (error!) {
      case BiometricAuthError.notAvailable:
        return 'Biometric authentication is not available on this device';
      case BiometricAuthError.notEnrolled:
        return 'No biometrics enrolled. Please set up fingerprint or face recognition in device settings';
      case BiometricAuthError.passcodeNotSet:
        return 'Please set up a passcode on your device first';
      case BiometricAuthError.userCancel:
        return 'Authentication was cancelled by user';
      case BiometricAuthError.userFallback:
        return 'User chose to use fallback authentication';
      case BiometricAuthError.systemCancel:
        return 'Authentication was cancelled by the system';
      case BiometricAuthError.invalidContext:
        return 'Invalid authentication context';
      case BiometricAuthError.notInteractive:
        return 'Authentication is not interactive';
      case BiometricAuthError.biometricOnlyNotSupported:
        return 'Biometric-only authentication is not supported';
      case BiometricAuthError.deviceNotSupported:
        return 'Device does not support biometric authentication';
      case BiometricAuthError.applicationLock:
        return 'Application is locked';
      case BiometricAuthError.biometricDisabled:
        return 'Biometric authentication is disabled';
      case BiometricAuthError.biometricLockout:
        return 'Too many failed attempts. Please try again later';
      case BiometricAuthError.biometricLockoutPermanent:
        return 'Biometric authentication is permanently locked. Please use device passcode';
      case BiometricAuthError.unknown:
        return 'An unknown error occurred during authentication';
    }
  }
}

/// Biometric authentication errors
enum BiometricAuthError {
  notAvailable,
  notEnrolled,
  passcodeNotSet,
  userCancel,
  userFallback,
  systemCancel,
  invalidContext,
  notInteractive,
  biometricOnlyNotSupported,
  deviceNotSupported,
  applicationLock,
  biometricDisabled,
  biometricLockout,
  biometricLockoutPermanent,
  unknown,
}

/// Biometric types
enum BiometricType {
  face,
  fingerprint,
  iris,
  weak,
  strong,
}

extension BiometricTypeExtension on BiometricType {
  String get displayName {
    switch (this) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.weak:
        return 'Weak Biometric';
      case BiometricType.strong:
        return 'Strong Biometric';
    }
  }

  String get description {
    switch (this) {
      case BiometricType.face:
        return 'Use your face to authenticate';
      case BiometricType.fingerprint:
        return 'Use your fingerprint to authenticate';
      case BiometricType.iris:
        return 'Use your iris to authenticate';
      case BiometricType.weak:
        return 'Use weak biometric authentication';
      case BiometricType.strong:
        return 'Use strong biometric authentication';
    }
  }
}

/// Biometric authentication helper methods
class BiometricAuthHelper {
  /// Get biometric icon based on available types
  static String getBiometricIcon(List<BiometricType> availableTypes) {
    if (availableTypes.contains(BiometricType.face)) {
      return 'face_id';
    } else if (availableTypes.contains(BiometricType.fingerprint)) {
      return 'fingerprint';
    } else if (availableTypes.contains(BiometricType.iris)) {
      return 'iris';
    } else {
      return 'biometric';
    }
  }

  /// Get biometric display name based on available types
  static String getBiometricDisplayName(List<BiometricType> availableTypes) {
    if (availableTypes.isEmpty) {
      return 'Biometric Authentication';
    } else if (availableTypes.length == 1) {
      return availableTypes.first.displayName;
    } else {
      return 'Biometric Authentication';
    }
  }

  /// Check if strong biometrics are available
  static bool hasStrongBiometrics(List<BiometricType> availableTypes) {
    return availableTypes.contains(BiometricType.strong) ||
           availableTypes.contains(BiometricType.face) ||
           availableTypes.contains(BiometricType.fingerprint) ||
           availableTypes.contains(BiometricType.iris);
  }
}
