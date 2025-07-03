import 'package:equatable/equatable.dart';

/// Model representing customer wallet settings and preferences
class CustomerWalletSettings extends Equatable {
  // Display Preferences
  final String currencyFormat;
  final bool showBalanceOnDashboard;
  final int transactionHistoryLimit;

  // Security Settings
  final bool requirePinForTransactions;
  final bool enableBiometricAuth;
  final double largeAmountThreshold;
  final bool autoLockWallet;

  // Notification Preferences
  final bool transactionNotifications;
  final bool lowBalanceAlerts;
  final bool spendingLimitAlerts;
  final bool promotionalNotifications;

  // Auto-reload Settings
  final bool enableAutoReload;
  final double? autoReloadThreshold;
  final double? autoReloadAmount;
  final String? autoReloadPaymentMethodId;

  // Spending Limits
  final double? dailySpendingLimit;
  final double? weeklySpendingLimit;
  final double? monthlySpendingLimit;

  // Privacy Settings
  final bool allowAnalytics;
  final bool allowMarketing;
  final bool shareDataWithPartners;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerWalletSettings({
    // Display Preferences
    this.currencyFormat = 'MYR',
    this.showBalanceOnDashboard = true,
    this.transactionHistoryLimit = 50,

    // Security Settings
    this.requirePinForTransactions = false,
    this.enableBiometricAuth = false,
    this.largeAmountThreshold = 500.0,
    this.autoLockWallet = false,

    // Notification Preferences
    this.transactionNotifications = true,
    this.lowBalanceAlerts = true,
    this.spendingLimitAlerts = true,
    this.promotionalNotifications = false,

    // Auto-reload Settings
    this.enableAutoReload = false,
    this.autoReloadThreshold,
    this.autoReloadAmount,
    this.autoReloadPaymentMethodId,

    // Spending Limits
    this.dailySpendingLimit,
    this.weeklySpendingLimit,
    this.monthlySpendingLimit,

    // Privacy Settings
    this.allowAnalytics = true,
    this.allowMarketing = false,
    this.shareDataWithPartners = false,

    // Metadata
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create CustomerWalletSettings from JSON
  factory CustomerWalletSettings.fromJson(Map<String, dynamic> json) {
    return CustomerWalletSettings(
      // Display Preferences
      currencyFormat: json['currency_format'] as String? ?? 'MYR',
      showBalanceOnDashboard: json['show_balance_on_dashboard'] as bool? ?? true,
      transactionHistoryLimit: json['transaction_history_limit'] as int? ?? 50,

      // Security Settings
      requirePinForTransactions: json['require_pin_for_transactions'] as bool? ?? false,
      enableBiometricAuth: json['enable_biometric_auth'] as bool? ?? false,
      largeAmountThreshold: (json['large_amount_threshold'] as num?)?.toDouble() ?? 500.0,
      autoLockWallet: json['auto_lock_wallet'] as bool? ?? false,

      // Notification Preferences
      transactionNotifications: json['transaction_notifications'] as bool? ?? true,
      lowBalanceAlerts: json['low_balance_alerts'] as bool? ?? true,
      spendingLimitAlerts: json['spending_limit_alerts'] as bool? ?? true,
      promotionalNotifications: json['promotional_notifications'] as bool? ?? false,

      // Auto-reload Settings
      enableAutoReload: json['enable_auto_reload'] as bool? ?? false,
      autoReloadThreshold: (json['auto_reload_threshold'] as num?)?.toDouble(),
      autoReloadAmount: (json['auto_reload_amount'] as num?)?.toDouble(),
      autoReloadPaymentMethodId: json['auto_reload_payment_method_id'] as String?,

      // Spending Limits
      dailySpendingLimit: (json['daily_spending_limit'] as num?)?.toDouble(),
      weeklySpendingLimit: (json['weekly_spending_limit'] as num?)?.toDouble(),
      monthlySpendingLimit: (json['monthly_spending_limit'] as num?)?.toDouble(),

      // Privacy Settings
      allowAnalytics: json['allow_analytics'] as bool? ?? true,
      allowMarketing: json['allow_marketing'] as bool? ?? false,
      shareDataWithPartners: json['share_data_with_partners'] as bool? ?? false,

      // Metadata
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert CustomerWalletSettings to JSON
  Map<String, dynamic> toJson() {
    return {
      // Display Preferences
      'currency_format': currencyFormat,
      'show_balance_on_dashboard': showBalanceOnDashboard,
      'transaction_history_limit': transactionHistoryLimit,

      // Security Settings
      'require_pin_for_transactions': requirePinForTransactions,
      'enable_biometric_auth': enableBiometricAuth,
      'large_amount_threshold': largeAmountThreshold,
      'auto_lock_wallet': autoLockWallet,

      // Notification Preferences
      'transaction_notifications': transactionNotifications,
      'low_balance_alerts': lowBalanceAlerts,
      'spending_limit_alerts': spendingLimitAlerts,
      'promotional_notifications': promotionalNotifications,

      // Auto-reload Settings
      'enable_auto_reload': enableAutoReload,
      'auto_reload_threshold': autoReloadThreshold,
      'auto_reload_amount': autoReloadAmount,
      'auto_reload_payment_method_id': autoReloadPaymentMethodId,

      // Spending Limits
      'daily_spending_limit': dailySpendingLimit,
      'weekly_spending_limit': weeklySpendingLimit,
      'monthly_spending_limit': monthlySpendingLimit,

      // Privacy Settings
      'allow_analytics': allowAnalytics,
      'allow_marketing': allowMarketing,
      'share_data_with_partners': shareDataWithPartners,

      // Metadata
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  CustomerWalletSettings copyWith({
    // Display Preferences
    String? currencyFormat,
    bool? showBalanceOnDashboard,
    int? transactionHistoryLimit,

    // Security Settings
    bool? requirePinForTransactions,
    bool? enableBiometricAuth,
    double? largeAmountThreshold,
    bool? autoLockWallet,

    // Notification Preferences
    bool? transactionNotifications,
    bool? lowBalanceAlerts,
    bool? spendingLimitAlerts,
    bool? promotionalNotifications,

    // Auto-reload Settings
    bool? enableAutoReload,
    double? autoReloadThreshold,
    double? autoReloadAmount,
    String? autoReloadPaymentMethodId,

    // Spending Limits
    double? dailySpendingLimit,
    double? weeklySpendingLimit,
    double? monthlySpendingLimit,

    // Privacy Settings
    bool? allowAnalytics,
    bool? allowMarketing,
    bool? shareDataWithPartners,

    // Metadata
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerWalletSettings(
      // Display Preferences
      currencyFormat: currencyFormat ?? this.currencyFormat,
      showBalanceOnDashboard: showBalanceOnDashboard ?? this.showBalanceOnDashboard,
      transactionHistoryLimit: transactionHistoryLimit ?? this.transactionHistoryLimit,

      // Security Settings
      requirePinForTransactions: requirePinForTransactions ?? this.requirePinForTransactions,
      enableBiometricAuth: enableBiometricAuth ?? this.enableBiometricAuth,
      largeAmountThreshold: largeAmountThreshold ?? this.largeAmountThreshold,
      autoLockWallet: autoLockWallet ?? this.autoLockWallet,

      // Notification Preferences
      transactionNotifications: transactionNotifications ?? this.transactionNotifications,
      lowBalanceAlerts: lowBalanceAlerts ?? this.lowBalanceAlerts,
      spendingLimitAlerts: spendingLimitAlerts ?? this.spendingLimitAlerts,
      promotionalNotifications: promotionalNotifications ?? this.promotionalNotifications,

      // Auto-reload Settings
      enableAutoReload: enableAutoReload ?? this.enableAutoReload,
      autoReloadThreshold: autoReloadThreshold ?? this.autoReloadThreshold,
      autoReloadAmount: autoReloadAmount ?? this.autoReloadAmount,
      autoReloadPaymentMethodId: autoReloadPaymentMethodId ?? this.autoReloadPaymentMethodId,

      // Spending Limits
      dailySpendingLimit: dailySpendingLimit ?? this.dailySpendingLimit,
      weeklySpendingLimit: weeklySpendingLimit ?? this.weeklySpendingLimit,
      monthlySpendingLimit: monthlySpendingLimit ?? this.monthlySpendingLimit,

      // Privacy Settings
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      allowMarketing: allowMarketing ?? this.allowMarketing,
      shareDataWithPartners: shareDataWithPartners ?? this.shareDataWithPartners,

      // Metadata
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Get formatted currency symbol
  String get currencySymbol {
    switch (currencyFormat) {
      case 'MYR':
        return 'RM';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return 'RM';
    }
  }

  /// Check if auto-reload is properly configured
  bool get isAutoReloadConfigured {
    return enableAutoReload && 
           autoReloadThreshold != null && 
           autoReloadAmount != null &&
           autoReloadPaymentMethodId != null;
  }

  /// Check if any spending limits are set
  bool get hasSpendingLimits {
    return dailySpendingLimit != null || 
           weeklySpendingLimit != null || 
           monthlySpendingLimit != null;
  }

  /// Check if enhanced security is enabled
  bool get hasEnhancedSecurity {
    return requirePinForTransactions || enableBiometricAuth;
  }

  @override
  List<Object?> get props => [
        // Display Preferences
        currencyFormat,
        showBalanceOnDashboard,
        transactionHistoryLimit,

        // Security Settings
        requirePinForTransactions,
        enableBiometricAuth,
        largeAmountThreshold,
        autoLockWallet,

        // Notification Preferences
        transactionNotifications,
        lowBalanceAlerts,
        spendingLimitAlerts,
        promotionalNotifications,

        // Auto-reload Settings
        enableAutoReload,
        autoReloadThreshold,
        autoReloadAmount,
        autoReloadPaymentMethodId,

        // Spending Limits
        dailySpendingLimit,
        weeklySpendingLimit,
        monthlySpendingLimit,

        // Privacy Settings
        allowAnalytics,
        allowMarketing,
        shareDataWithPartners,

        // Metadata
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'CustomerWalletSettings('
        'currencyFormat: $currencyFormat, '
        'showBalanceOnDashboard: $showBalanceOnDashboard, '
        'requirePinForTransactions: $requirePinForTransactions, '
        'enableAutoReload: $enableAutoReload'
        ')';
  }

  /// Create default settings for a new user
  factory CustomerWalletSettings.defaults() {
    final now = DateTime.now();
    return CustomerWalletSettings(
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create test settings for development
  factory CustomerWalletSettings.test() {
    final now = DateTime.now();
    return CustomerWalletSettings(
      currencyFormat: 'MYR',
      showBalanceOnDashboard: true,
      transactionHistoryLimit: 50,
      requirePinForTransactions: true,
      enableBiometricAuth: true,
      largeAmountThreshold: 500.0,
      autoLockWallet: false,
      transactionNotifications: true,
      lowBalanceAlerts: true,
      spendingLimitAlerts: true,
      promotionalNotifications: false,
      enableAutoReload: true,
      autoReloadThreshold: 20.0,
      autoReloadAmount: 50.0,
      dailySpendingLimit: 200.0,
      weeklySpendingLimit: 1000.0,
      monthlySpendingLimit: 3000.0,
      allowAnalytics: true,
      allowMarketing: false,
      shareDataWithPartners: false,
      createdAt: now,
      updatedAt: now,
    );
  }
}
