import 'package:equatable/equatable.dart';

/// Model representing customer security settings and preferences
class CustomerSecurity extends Equatable {
  final String userId;
  final bool biometricEnabled;
  final bool pinEnabled;
  final String? pinHash;
  final bool autoLockEnabled;
  final int autoLockTimeoutMinutes;
  final bool transactionPinRequired;
  final double largeTransactionThreshold;
  final bool mfaEnabled;
  final List<String> trustedDevices;
  final SecurityLevel securityLevel;
  final DateTime lastSecurityUpdate;
  final Map<String, dynamic>? securitySettings;

  const CustomerSecurity({
    required this.userId,
    this.biometricEnabled = false,
    this.pinEnabled = false,
    this.pinHash,
    this.autoLockEnabled = false,
    this.autoLockTimeoutMinutes = 5,
    this.transactionPinRequired = false,
    this.largeTransactionThreshold = 500.0,
    this.mfaEnabled = false,
    this.trustedDevices = const [],
    this.securityLevel = SecurityLevel.standard,
    required this.lastSecurityUpdate,
    this.securitySettings,
  });

  factory CustomerSecurity.fromJson(Map<String, dynamic> json) {
    return CustomerSecurity(
      userId: json['user_id'] as String,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
      pinEnabled: json['pin_enabled'] as bool? ?? false,
      pinHash: json['pin_hash'] as String?,
      autoLockEnabled: json['auto_lock_enabled'] as bool? ?? false,
      autoLockTimeoutMinutes: json['auto_lock_timeout_minutes'] as int? ?? 5,
      transactionPinRequired: json['transaction_pin_required'] as bool? ?? false,
      largeTransactionThreshold: (json['large_transaction_threshold'] as num?)?.toDouble() ?? 500.0,
      mfaEnabled: json['mfa_enabled'] as bool? ?? false,
      trustedDevices: List<String>.from(json['trusted_devices'] ?? []),
      securityLevel: SecurityLevel.fromString(json['security_level'] as String? ?? 'standard'),
      lastSecurityUpdate: DateTime.parse(json['last_security_update'] as String),
      securitySettings: json['security_settings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'biometric_enabled': biometricEnabled,
      'pin_enabled': pinEnabled,
      'pin_hash': pinHash,
      'auto_lock_enabled': autoLockEnabled,
      'auto_lock_timeout_minutes': autoLockTimeoutMinutes,
      'transaction_pin_required': transactionPinRequired,
      'large_transaction_threshold': largeTransactionThreshold,
      'mfa_enabled': mfaEnabled,
      'trusted_devices': trustedDevices,
      'security_level': securityLevel.value,
      'last_security_update': lastSecurityUpdate.toIso8601String(),
      'security_settings': securitySettings,
    };
  }

  CustomerSecurity copyWith({
    String? userId,
    bool? biometricEnabled,
    bool? pinEnabled,
    String? pinHash,
    bool? autoLockEnabled,
    int? autoLockTimeoutMinutes,
    bool? transactionPinRequired,
    double? largeTransactionThreshold,
    bool? mfaEnabled,
    List<String>? trustedDevices,
    SecurityLevel? securityLevel,
    DateTime? lastSecurityUpdate,
    Map<String, dynamic>? securitySettings,
  }) {
    return CustomerSecurity(
      userId: userId ?? this.userId,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      pinHash: pinHash ?? this.pinHash,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      autoLockTimeoutMinutes: autoLockTimeoutMinutes ?? this.autoLockTimeoutMinutes,
      transactionPinRequired: transactionPinRequired ?? this.transactionPinRequired,
      largeTransactionThreshold: largeTransactionThreshold ?? this.largeTransactionThreshold,
      mfaEnabled: mfaEnabled ?? this.mfaEnabled,
      trustedDevices: trustedDevices ?? this.trustedDevices,
      securityLevel: securityLevel ?? this.securityLevel,
      lastSecurityUpdate: lastSecurityUpdate ?? DateTime.now(),
      securitySettings: securitySettings ?? this.securitySettings,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        biometricEnabled,
        pinEnabled,
        pinHash,
        autoLockEnabled,
        autoLockTimeoutMinutes,
        transactionPinRequired,
        largeTransactionThreshold,
        mfaEnabled,
        trustedDevices,
        securityLevel,
        lastSecurityUpdate,
        securitySettings,
      ];

  /// Check if enhanced security is enabled
  bool get hasEnhancedSecurity {
    return biometricEnabled || pinEnabled || mfaEnabled;
  }

  /// Get security score (0-100)
  int get securityScore {
    int score = 0;
    if (biometricEnabled) score += 25;
    if (pinEnabled) score += 20;
    if (transactionPinRequired) score += 15;
    if (mfaEnabled) score += 20;
    if (autoLockEnabled) score += 10;
    if (trustedDevices.isNotEmpty) score += 10;
    return score;
  }

  /// Get security level description
  String get securityLevelDescription {
    switch (securityLevel) {
      case SecurityLevel.basic:
        return 'Basic security with password protection';
      case SecurityLevel.standard:
        return 'Standard security with additional protections';
      case SecurityLevel.enhanced:
        return 'Enhanced security with biometric authentication';
      case SecurityLevel.maximum:
        return 'Maximum security with all features enabled';
    }
  }
}

/// Security level enumeration
enum SecurityLevel {
  basic('basic'),
  standard('standard'),
  enhanced('enhanced'),
  maximum('maximum');

  const SecurityLevel(this.value);
  final String value;

  static SecurityLevel fromString(String value) {
    return SecurityLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => SecurityLevel.standard,
    );
  }

  String get displayName {
    switch (this) {
      case SecurityLevel.basic:
        return 'Basic';
      case SecurityLevel.standard:
        return 'Standard';
      case SecurityLevel.enhanced:
        return 'Enhanced';
      case SecurityLevel.maximum:
        return 'Maximum';
    }
  }
}

/// Security audit log entry
class SecurityAuditLog extends Equatable {
  final String id;
  final String userId;
  final String action;
  final String description;
  final String? deviceId;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic>? metadata;
  final SecurityEventType eventType;
  final SecurityRiskLevel riskLevel;
  final DateTime timestamp;

  const SecurityAuditLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.description,
    this.deviceId,
    this.ipAddress,
    this.userAgent,
    this.metadata,
    required this.eventType,
    required this.riskLevel,
    required this.timestamp,
  });

  factory SecurityAuditLog.fromJson(Map<String, dynamic> json) {
    return SecurityAuditLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      action: json['action'] as String,
      description: json['description'] as String,
      deviceId: json['device_id'] as String?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      eventType: SecurityEventType.fromString(json['event_type'] as String),
      riskLevel: SecurityRiskLevel.fromString(json['risk_level'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'description': description,
      'device_id': deviceId,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'metadata': metadata,
      'event_type': eventType.value,
      'risk_level': riskLevel.value,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        action,
        description,
        deviceId,
        ipAddress,
        userAgent,
        metadata,
        eventType,
        riskLevel,
        timestamp,
      ];
}

/// Security event types
enum SecurityEventType {
  authentication('authentication'),
  transaction('transaction'),
  settings('settings'),
  device('device'),
  suspicious('suspicious');

  const SecurityEventType(this.value);
  final String value;

  static SecurityEventType fromString(String value) {
    return SecurityEventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SecurityEventType.authentication,
    );
  }
}

/// Security risk levels
enum SecurityRiskLevel {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const SecurityRiskLevel(this.value);
  final String value;

  static SecurityRiskLevel fromString(String value) {
    return SecurityRiskLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => SecurityRiskLevel.low,
    );
  }

  String get displayName {
    switch (this) {
      case SecurityRiskLevel.low:
        return 'Low Risk';
      case SecurityRiskLevel.medium:
        return 'Medium Risk';
      case SecurityRiskLevel.high:
        return 'High Risk';
      case SecurityRiskLevel.critical:
        return 'Critical Risk';
    }
  }
}

/// Device information model
class DeviceInfo extends Equatable {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String? model;
  final String? osVersion;
  final String? appVersion;
  final bool isTrusted;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final String? location;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    this.model,
    this.osVersion,
    this.appVersion,
    this.isTrusted = false,
    required this.firstSeen,
    required this.lastSeen,
    this.location,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String,
      platform: json['platform'] as String,
      model: json['model'] as String?,
      osVersion: json['os_version'] as String?,
      appVersion: json['app_version'] as String?,
      isTrusted: json['is_trusted'] as bool? ?? false,
      firstSeen: DateTime.parse(json['first_seen'] as String),
      lastSeen: DateTime.parse(json['last_seen'] as String),
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
      'model': model,
      'os_version': osVersion,
      'app_version': appVersion,
      'is_trusted': isTrusted,
      'first_seen': firstSeen.toIso8601String(),
      'last_seen': lastSeen.toIso8601String(),
      'location': location,
    };
  }

  @override
  List<Object?> get props => [
        deviceId,
        deviceName,
        platform,
        model,
        osVersion,
        appVersion,
        isTrusted,
        firstSeen,
        lastSeen,
        location,
      ];

  /// Get device display name
  String get displayName {
    if (model != null) {
      return '$deviceName ($model)';
    }
    return deviceName;
  }

  /// Check if device is current
  bool get isCurrent {
    final now = DateTime.now();
    return now.difference(lastSeen).inMinutes < 30;
  }
}
