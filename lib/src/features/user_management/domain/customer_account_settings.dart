import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'customer_account_settings.g.dart';

/// Comprehensive customer account settings model
@JsonSerializable()
class CustomerAccountSettings extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  
  // Notification Preferences
  @JsonKey(name: 'notification_preferences')
  final CustomerNotificationPreferences notificationPreferences;
  
  // Privacy Settings
  @JsonKey(name: 'privacy_settings')
  final CustomerPrivacySettings privacySettings;
  
  // App Preferences
  @JsonKey(name: 'app_preferences')
  final CustomerAppPreferences appPreferences;
  
  // Security Settings
  @JsonKey(name: 'security_settings')
  final CustomerSecuritySettings securitySettings;
  
  // Metadata
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const CustomerAccountSettings({
    required this.id,
    required this.userId,
    required this.notificationPreferences,
    required this.privacySettings,
    required this.appPreferences,
    required this.securitySettings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerAccountSettings.fromJson(Map<String, dynamic> json) =>
      _$CustomerAccountSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerAccountSettingsToJson(this);

  CustomerAccountSettings copyWith({
    String? id,
    String? userId,
    CustomerNotificationPreferences? notificationPreferences,
    CustomerPrivacySettings? privacySettings,
    CustomerAppPreferences? appPreferences,
    CustomerSecuritySettings? securitySettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerAccountSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      privacySettings: privacySettings ?? this.privacySettings,
      appPreferences: appPreferences ?? this.appPreferences,
      securitySettings: securitySettings ?? this.securitySettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create default settings for a new user
  factory CustomerAccountSettings.createDefault(String userId) {
    final now = DateTime.now();
    return CustomerAccountSettings(
      id: 'settings_$userId',
      userId: userId,
      notificationPreferences: const CustomerNotificationPreferences(),
      privacySettings: const CustomerPrivacySettings(),
      appPreferences: const CustomerAppPreferences(),
      securitySettings: const CustomerSecuritySettings(),
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        notificationPreferences,
        privacySettings,
        appPreferences,
        securitySettings,
        createdAt,
        updatedAt,
      ];
}

/// Customer notification preferences
@JsonSerializable()
class CustomerNotificationPreferences extends Equatable {
  // Channel Preferences
  @JsonKey(name: 'push_notifications')
  final bool pushNotifications;
  @JsonKey(name: 'email_notifications')
  final bool emailNotifications;
  @JsonKey(name: 'sms_notifications')
  final bool smsNotifications;
  @JsonKey(name: 'in_app_notifications')
  final bool inAppNotifications;

  // Category Preferences
  @JsonKey(name: 'order_notifications')
  final bool orderNotifications;
  @JsonKey(name: 'payment_notifications')
  final bool paymentNotifications;
  @JsonKey(name: 'promotion_notifications')
  final bool promotionNotifications;
  @JsonKey(name: 'account_notifications')
  final bool accountNotifications;
  @JsonKey(name: 'security_notifications')
  final bool securityNotifications;
  @JsonKey(name: 'delivery_notifications')
  final bool deliveryNotifications;

  // Timing Preferences
  @JsonKey(name: 'quiet_hours_enabled')
  final bool quietHoursEnabled;
  @JsonKey(name: 'quiet_hours_start')
  final String? quietHoursStart; // HH:mm format
  @JsonKey(name: 'quiet_hours_end')
  final String? quietHoursEnd; // HH:mm format
  @JsonKey(name: 'timezone')
  final String timezone;

  const CustomerNotificationPreferences({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.inAppNotifications = true,
    this.orderNotifications = true,
    this.paymentNotifications = true,
    this.promotionNotifications = false,
    this.accountNotifications = true,
    this.securityNotifications = true,
    this.deliveryNotifications = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.timezone = 'Asia/Kuala_Lumpur',
  });

  factory CustomerNotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$CustomerNotificationPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerNotificationPreferencesToJson(this);

  CustomerNotificationPreferences copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? inAppNotifications,
    bool? orderNotifications,
    bool? paymentNotifications,
    bool? promotionNotifications,
    bool? accountNotifications,
    bool? securityNotifications,
    bool? deliveryNotifications,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? timezone,
  }) {
    return CustomerNotificationPreferences(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      inAppNotifications: inAppNotifications ?? this.inAppNotifications,
      orderNotifications: orderNotifications ?? this.orderNotifications,
      paymentNotifications: paymentNotifications ?? this.paymentNotifications,
      promotionNotifications: promotionNotifications ?? this.promotionNotifications,
      accountNotifications: accountNotifications ?? this.accountNotifications,
      securityNotifications: securityNotifications ?? this.securityNotifications,
      deliveryNotifications: deliveryNotifications ?? this.deliveryNotifications,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      timezone: timezone ?? this.timezone,
    );
  }

  @override
  List<Object?> get props => [
        pushNotifications,
        emailNotifications,
        smsNotifications,
        inAppNotifications,
        orderNotifications,
        paymentNotifications,
        promotionNotifications,
        accountNotifications,
        securityNotifications,
        deliveryNotifications,
        quietHoursEnabled,
        quietHoursStart,
        quietHoursEnd,
        timezone,
      ];
}

/// Customer privacy settings
@JsonSerializable()
class CustomerPrivacySettings extends Equatable {
  @JsonKey(name: 'profile_visibility')
  final ProfileVisibility profileVisibility;
  @JsonKey(name: 'allow_analytics')
  final bool allowAnalytics;
  @JsonKey(name: 'allow_marketing')
  final bool allowMarketing;
  @JsonKey(name: 'share_data_with_partners')
  final bool shareDataWithPartners;
  @JsonKey(name: 'location_tracking')
  final bool locationTracking;
  @JsonKey(name: 'order_history_visibility')
  final bool orderHistoryVisibility;

  const CustomerPrivacySettings({
    this.profileVisibility = ProfileVisibility.private,
    this.allowAnalytics = true,
    this.allowMarketing = false,
    this.shareDataWithPartners = false,
    this.locationTracking = true,
    this.orderHistoryVisibility = false,
  });

  factory CustomerPrivacySettings.fromJson(Map<String, dynamic> json) =>
      _$CustomerPrivacySettingsFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerPrivacySettingsToJson(this);

  CustomerPrivacySettings copyWith({
    ProfileVisibility? profileVisibility,
    bool? allowAnalytics,
    bool? allowMarketing,
    bool? shareDataWithPartners,
    bool? locationTracking,
    bool? orderHistoryVisibility,
  }) {
    return CustomerPrivacySettings(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      allowMarketing: allowMarketing ?? this.allowMarketing,
      shareDataWithPartners: shareDataWithPartners ?? this.shareDataWithPartners,
      locationTracking: locationTracking ?? this.locationTracking,
      orderHistoryVisibility: orderHistoryVisibility ?? this.orderHistoryVisibility,
    );
  }

  @override
  List<Object?> get props => [
        profileVisibility,
        allowAnalytics,
        allowMarketing,
        shareDataWithPartners,
        locationTracking,
        orderHistoryVisibility,
      ];
}

/// Customer app preferences
@JsonSerializable()
class CustomerAppPreferences extends Equatable {
  @JsonKey(name: 'language_code')
  final String languageCode;
  @JsonKey(name: 'theme_mode')
  final AppThemeMode themeMode;
  @JsonKey(name: 'currency_code')
  final String currencyCode;
  @JsonKey(name: 'default_delivery_method')
  final String? defaultDeliveryMethod;
  @JsonKey(name: 'remember_payment_method')
  final bool rememberPaymentMethod;
  @JsonKey(name: 'auto_apply_loyalty_points')
  final bool autoApplyLoyaltyPoints;

  const CustomerAppPreferences({
    this.languageCode = 'en',
    this.themeMode = AppThemeMode.system,
    this.currencyCode = 'MYR',
    this.defaultDeliveryMethod,
    this.rememberPaymentMethod = true,
    this.autoApplyLoyaltyPoints = true,
  });

  factory CustomerAppPreferences.fromJson(Map<String, dynamic> json) =>
      _$CustomerAppPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerAppPreferencesToJson(this);

  CustomerAppPreferences copyWith({
    String? languageCode,
    AppThemeMode? themeMode,
    String? currencyCode,
    String? defaultDeliveryMethod,
    bool? rememberPaymentMethod,
    bool? autoApplyLoyaltyPoints,
  }) {
    return CustomerAppPreferences(
      languageCode: languageCode ?? this.languageCode,
      themeMode: themeMode ?? this.themeMode,
      currencyCode: currencyCode ?? this.currencyCode,
      defaultDeliveryMethod: defaultDeliveryMethod ?? this.defaultDeliveryMethod,
      rememberPaymentMethod: rememberPaymentMethod ?? this.rememberPaymentMethod,
      autoApplyLoyaltyPoints: autoApplyLoyaltyPoints ?? this.autoApplyLoyaltyPoints,
    );
  }

  @override
  List<Object?> get props => [
        languageCode,
        themeMode,
        currencyCode,
        defaultDeliveryMethod,
        rememberPaymentMethod,
        autoApplyLoyaltyPoints,
      ];
}

/// Customer security settings
@JsonSerializable()
class CustomerSecuritySettings extends Equatable {
  @JsonKey(name: 'two_factor_enabled')
  final bool twoFactorEnabled;
  @JsonKey(name: 'biometric_login')
  final bool biometricLogin;
  @JsonKey(name: 'session_timeout_minutes')
  final int sessionTimeoutMinutes;
  @JsonKey(name: 'login_notifications')
  final bool loginNotifications;

  const CustomerSecuritySettings({
    this.twoFactorEnabled = false,
    this.biometricLogin = false,
    this.sessionTimeoutMinutes = 30,
    this.loginNotifications = true,
  });

  factory CustomerSecuritySettings.fromJson(Map<String, dynamic> json) =>
      _$CustomerSecuritySettingsFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerSecuritySettingsToJson(this);

  CustomerSecuritySettings copyWith({
    bool? twoFactorEnabled,
    bool? biometricLogin,
    int? sessionTimeoutMinutes,
    bool? loginNotifications,
  }) {
    return CustomerSecuritySettings(
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      biometricLogin: biometricLogin ?? this.biometricLogin,
      sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      loginNotifications: loginNotifications ?? this.loginNotifications,
    );
  }

  @override
  List<Object?> get props => [
        twoFactorEnabled,
        biometricLogin,
        sessionTimeoutMinutes,
        loginNotifications,
      ];
}

/// Enums for settings
enum ProfileVisibility {
  @JsonValue('public')
  public,
  @JsonValue('private')
  private,
  @JsonValue('friends_only')
  friendsOnly,
}

enum AppThemeMode {
  @JsonValue('light')
  light,
  @JsonValue('dark')
  dark,
  @JsonValue('system')
  system,
}
