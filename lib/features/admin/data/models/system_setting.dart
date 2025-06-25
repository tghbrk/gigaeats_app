import 'package:freezed_annotation/freezed_annotation.dart';

part 'system_setting.freezed.dart';
part 'system_setting.g.dart';

/// System setting model
@freezed
class SystemSetting with _$SystemSetting {
  const factory SystemSetting({
    required String id,
    required String settingKey,
    required dynamic settingValue,
    String? description,
    @Default('general') String category,
    @Default(false) bool isPublic,
    String? updatedBy,
    required DateTime createdAt,
    required DateTime updatedAt,

    // Extended fields for better management
    String? dataType,
    String? validationRules,
    String? defaultValue,
    @Default(false) bool isRequired,
    @Default(false) bool isReadOnly,
    @Default([]) List<String> allowedValues,
    String? unit,
    double? minValue,
    double? maxValue,
    @Default([]) List<String> tags,
  }) = _SystemSetting;

  factory SystemSetting.fromJson(Map<String, dynamic> json) {
    try {
      return SystemSetting(
        id: json['id'] as String,
        settingKey: json['setting_key'] ?? json['settingKey'] as String,
        settingValue: json['setting_value'] ?? json['settingValue'],
        description: json['description'],
        category: json['category'] ?? 'general',
        isPublic: json['is_public'] ?? json['isPublic'] ?? false,
        updatedBy: json['updated_by'] ?? json['updatedBy'],
        createdAt: json['created_at'] is String
            ? DateTime.parse(json['created_at'])
            : json['created_at'] ?? json['createdAt'] ?? DateTime.now(),
        updatedAt: json['updated_at'] is String
            ? DateTime.parse(json['updated_at'])
            : json['updated_at'] ?? json['updatedAt'] ?? DateTime.now(),
        dataType: json['data_type'] ?? json['dataType'],
        validationRules: json['validation_rules'] ?? json['validationRules'],
        defaultValue: json['default_value'] ?? json['defaultValue'],
        isRequired: json['is_required'] ?? json['isRequired'] ?? false,
        isReadOnly: json['is_read_only'] ?? json['isReadOnly'] ?? false,
        allowedValues: json['allowed_values'] is List
            ? List<String>.from(json['allowed_values'])
            : json['allowedValues'] is List
                ? List<String>.from(json['allowedValues'])
                : <String>[],
        unit: json['unit'],
        minValue: json['min_value'] != null
            ? (json['min_value']).toDouble()
            : json['minValue']?.toDouble(),
        maxValue: json['max_value'] != null
            ? (json['max_value']).toDouble()
            : json['maxValue']?.toDouble(),
        tags: json['tags'] is List
            ? List<String>.from(json['tags'])
            : <String>[],
      );
    } catch (e) {
      throw FormatException('Failed to parse SystemSetting from JSON: $e');
    }
  }
}

/// System setting categories
class SettingCategory {
  static const String general = 'general';
  static const String payment = 'payment';
  static const String notification = 'notification';
  static const String security = 'security';
  static const String delivery = 'delivery';
  static const String commission = 'commission';
  static const String ui = 'ui';
  static const String api = 'api';
  static const String maintenance = 'maintenance';
  static const String analytics = 'analytics';

  /// Get all categories
  static List<String> get allCategories => [
    general, payment, notification, security, delivery, 
    commission, ui, api, maintenance, analytics,
  ];

  /// Get category display name
  static String getDisplayName(String category) {
    switch (category) {
      case general: return 'General';
      case payment: return 'Payment';
      case notification: return 'Notification';
      case security: return 'Security';
      case delivery: return 'Delivery';
      case commission: return 'Commission';
      case ui: return 'User Interface';
      case api: return 'API';
      case maintenance: return 'Maintenance';
      case analytics: return 'Analytics';
      default: return category.replaceAll('_', ' ').split(' ')
          .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }
  }
}

/// Predefined system settings
class SystemSettingKey {
  // General settings
  static const String appName = 'app_name';
  static const String appVersion = 'app_version';
  static const String maintenanceMode = 'maintenance_mode';
  static const String supportEmail = 'support_email';
  static const String supportPhone = 'support_phone';
  
  // Order settings
  static const String maxOrderValue = 'max_order_value';
  static const String minOrderValue = 'min_order_value';
  static const String defaultDeliveryFee = 'default_delivery_fee';
  static const String freeDeliveryThreshold = 'free_delivery_threshold';
  
  // Commission settings
  static const String commissionRate = 'commission_rate';
  static const String driverCommissionRate = 'driver_commission_rate';
  static const String salesAgentCommissionRate = 'sales_agent_commission_rate';
  
  // Payment settings
  static const String stripePublishableKey = 'stripe_publishable_key';
  static const String paymentMethods = 'payment_methods';
  static const String autoRefundEnabled = 'auto_refund_enabled';
  
  // Notification settings
  static const String emailNotificationsEnabled = 'email_notifications_enabled';
  static const String smsNotificationsEnabled = 'sms_notifications_enabled';
  static const String pushNotificationsEnabled = 'push_notifications_enabled';
  
  // Security settings
  static const String maxLoginAttempts = 'max_login_attempts';
  static const String sessionTimeout = 'session_timeout';
  static const String passwordMinLength = 'password_min_length';
  static const String twoFactorRequired = 'two_factor_required';
  
  // Delivery settings
  static const String maxDeliveryDistance = 'max_delivery_distance';
  static const String deliveryTimeSlots = 'delivery_time_slots';
  static const String emergencyDeliveryFee = 'emergency_delivery_fee';
  
  // UI settings
  static const String defaultLanguage = 'default_language';
  static const String defaultCurrency = 'default_currency';
  static const String themeMode = 'theme_mode';
  static const String featuredVendorsLimit = 'featured_vendors_limit';

  /// Get all setting keys
  static List<String> get allSettingKeys => [
    appName, appVersion, maintenanceMode, supportEmail, supportPhone,
    maxOrderValue, minOrderValue, defaultDeliveryFee, freeDeliveryThreshold,
    commissionRate, driverCommissionRate, salesAgentCommissionRate,
    stripePublishableKey, paymentMethods, autoRefundEnabled,
    emailNotificationsEnabled, smsNotificationsEnabled, pushNotificationsEnabled,
    maxLoginAttempts, sessionTimeout, passwordMinLength, twoFactorRequired,
    maxDeliveryDistance, deliveryTimeSlots, emergencyDeliveryFee,
    defaultLanguage, defaultCurrency, themeMode, featuredVendorsLimit,
  ];

  /// Get setting display name
  static String getDisplayName(String settingKey) {
    switch (settingKey) {
      case appName: return 'Application Name';
      case appVersion: return 'Application Version';
      case maintenanceMode: return 'Maintenance Mode';
      case supportEmail: return 'Support Email';
      case supportPhone: return 'Support Phone';
      case maxOrderValue: return 'Maximum Order Value';
      case minOrderValue: return 'Minimum Order Value';
      case defaultDeliveryFee: return 'Default Delivery Fee';
      case freeDeliveryThreshold: return 'Free Delivery Threshold';
      case commissionRate: return 'Commission Rate';
      case driverCommissionRate: return 'Driver Commission Rate';
      case salesAgentCommissionRate: return 'Sales Agent Commission Rate';
      case stripePublishableKey: return 'Stripe Publishable Key';
      case paymentMethods: return 'Payment Methods';
      case autoRefundEnabled: return 'Auto Refund Enabled';
      case emailNotificationsEnabled: return 'Email Notifications';
      case smsNotificationsEnabled: return 'SMS Notifications';
      case pushNotificationsEnabled: return 'Push Notifications';
      case maxLoginAttempts: return 'Max Login Attempts';
      case sessionTimeout: return 'Session Timeout';
      case passwordMinLength: return 'Password Min Length';
      case twoFactorRequired: return 'Two Factor Required';
      case maxDeliveryDistance: return 'Max Delivery Distance';
      case deliveryTimeSlots: return 'Delivery Time Slots';
      case emergencyDeliveryFee: return 'Emergency Delivery Fee';
      case defaultLanguage: return 'Default Language';
      case defaultCurrency: return 'Default Currency';
      case themeMode: return 'Theme Mode';
      case featuredVendorsLimit: return 'Featured Vendors Limit';
      default: return settingKey.replaceAll('_', ' ').split(' ')
          .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }
  }

  /// Get setting category
  static String getCategory(String settingKey) {
    if ([appName, appVersion, maintenanceMode, supportEmail, supportPhone].contains(settingKey)) {
      return SettingCategory.general;
    }
    if ([stripePublishableKey, paymentMethods, autoRefundEnabled].contains(settingKey)) {
      return SettingCategory.payment;
    }
    if ([emailNotificationsEnabled, smsNotificationsEnabled, pushNotificationsEnabled].contains(settingKey)) {
      return SettingCategory.notification;
    }
    if ([maxLoginAttempts, sessionTimeout, passwordMinLength, twoFactorRequired].contains(settingKey)) {
      return SettingCategory.security;
    }
    if ([maxDeliveryDistance, deliveryTimeSlots, emergencyDeliveryFee, defaultDeliveryFee, freeDeliveryThreshold].contains(settingKey)) {
      return SettingCategory.delivery;
    }
    if ([commissionRate, driverCommissionRate, salesAgentCommissionRate].contains(settingKey)) {
      return SettingCategory.commission;
    }
    if ([defaultLanguage, defaultCurrency, themeMode, featuredVendorsLimit].contains(settingKey)) {
      return SettingCategory.ui;
    }
    return SettingCategory.general;
  }
}

/// Setting update request
@freezed
class SettingUpdateRequest with _$SettingUpdateRequest {
  const factory SettingUpdateRequest({
    required String settingKey,
    required dynamic settingValue,
    String? reason,
  }) = _SettingUpdateRequest;

  factory SettingUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$SettingUpdateRequestFromJson(json);
}

/// Settings filter
@freezed
class SettingsFilter with _$SettingsFilter {
  const factory SettingsFilter({
    String? category,
    bool? isPublic,
    String? searchQuery,
    @Default(100) int limit,
    @Default(0) int offset,
  }) = _SettingsFilter;

  factory SettingsFilter.fromJson(Map<String, dynamic> json) =>
      _$SettingsFilterFromJson(json);
}
