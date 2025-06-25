import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wallet_settings.g.dart';

/// Comprehensive wallet settings model
@JsonSerializable()
class WalletSettings extends Equatable {
  final String id;
  final String userId;
  final String walletId;
  
  // Display preferences
  final String currencyDisplay;
  final bool showBalanceOnDashboard;
  final bool showRecentTransactions;
  final int transactionHistoryLimit;
  
  // Security preferences
  final bool requirePinForTransactions;
  final bool requireBiometricForTransactions;
  final bool requireConfirmationForLargeAmounts;
  final double largeAmountThreshold;
  final int autoLockTimeoutMinutes;
  
  // Privacy preferences
  final bool allowAnalytics;
  final bool allowMarketingNotifications;
  final bool shareTransactionData;
  
  // Auto-reload preferences
  final bool autoReloadEnabled;
  final double autoReloadThreshold;
  final double autoReloadAmount;
  final String? autoReloadPaymentMethodId;
  
  // Spending alert preferences
  final bool spendingAlertsEnabled;
  final double? dailySpendingAlertThreshold;
  final double? weeklySpendingAlertThreshold;
  final double? monthlySpendingAlertThreshold;
  
  // Audit fields
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletSettings({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.currencyDisplay,
    required this.showBalanceOnDashboard,
    required this.showRecentTransactions,
    required this.transactionHistoryLimit,
    required this.requirePinForTransactions,
    required this.requireBiometricForTransactions,
    required this.requireConfirmationForLargeAmounts,
    required this.largeAmountThreshold,
    required this.autoLockTimeoutMinutes,
    required this.allowAnalytics,
    required this.allowMarketingNotifications,
    required this.shareTransactionData,
    required this.autoReloadEnabled,
    required this.autoReloadThreshold,
    required this.autoReloadAmount,
    this.autoReloadPaymentMethodId,
    required this.spendingAlertsEnabled,
    this.dailySpendingAlertThreshold,
    this.weeklySpendingAlertThreshold,
    this.monthlySpendingAlertThreshold,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletSettings.fromJson(Map<String, dynamic> json) =>
      _$WalletSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$WalletSettingsToJson(this);

  WalletSettings copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? currencyDisplay,
    bool? showBalanceOnDashboard,
    bool? showRecentTransactions,
    int? transactionHistoryLimit,
    bool? requirePinForTransactions,
    bool? requireBiometricForTransactions,
    bool? requireConfirmationForLargeAmounts,
    double? largeAmountThreshold,
    int? autoLockTimeoutMinutes,
    bool? allowAnalytics,
    bool? allowMarketingNotifications,
    bool? shareTransactionData,
    bool? autoReloadEnabled,
    double? autoReloadThreshold,
    double? autoReloadAmount,
    String? autoReloadPaymentMethodId,
    bool? spendingAlertsEnabled,
    double? dailySpendingAlertThreshold,
    double? weeklySpendingAlertThreshold,
    double? monthlySpendingAlertThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      currencyDisplay: currencyDisplay ?? this.currencyDisplay,
      showBalanceOnDashboard: showBalanceOnDashboard ?? this.showBalanceOnDashboard,
      showRecentTransactions: showRecentTransactions ?? this.showRecentTransactions,
      transactionHistoryLimit: transactionHistoryLimit ?? this.transactionHistoryLimit,
      requirePinForTransactions: requirePinForTransactions ?? this.requirePinForTransactions,
      requireBiometricForTransactions: requireBiometricForTransactions ?? this.requireBiometricForTransactions,
      requireConfirmationForLargeAmounts: requireConfirmationForLargeAmounts ?? this.requireConfirmationForLargeAmounts,
      largeAmountThreshold: largeAmountThreshold ?? this.largeAmountThreshold,
      autoLockTimeoutMinutes: autoLockTimeoutMinutes ?? this.autoLockTimeoutMinutes,
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      allowMarketingNotifications: allowMarketingNotifications ?? this.allowMarketingNotifications,
      shareTransactionData: shareTransactionData ?? this.shareTransactionData,
      autoReloadEnabled: autoReloadEnabled ?? this.autoReloadEnabled,
      autoReloadThreshold: autoReloadThreshold ?? this.autoReloadThreshold,
      autoReloadAmount: autoReloadAmount ?? this.autoReloadAmount,
      autoReloadPaymentMethodId: autoReloadPaymentMethodId ?? this.autoReloadPaymentMethodId,
      spendingAlertsEnabled: spendingAlertsEnabled ?? this.spendingAlertsEnabled,
      dailySpendingAlertThreshold: dailySpendingAlertThreshold ?? this.dailySpendingAlertThreshold,
      weeklySpendingAlertThreshold: weeklySpendingAlertThreshold ?? this.weeklySpendingAlertThreshold,
      monthlySpendingAlertThreshold: monthlySpendingAlertThreshold ?? this.monthlySpendingAlertThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        currencyDisplay,
        showBalanceOnDashboard,
        showRecentTransactions,
        transactionHistoryLimit,
        requirePinForTransactions,
        requireBiometricForTransactions,
        requireConfirmationForLargeAmounts,
        largeAmountThreshold,
        autoLockTimeoutMinutes,
        allowAnalytics,
        allowMarketingNotifications,
        shareTransactionData,
        autoReloadEnabled,
        autoReloadThreshold,
        autoReloadAmount,
        autoReloadPaymentMethodId,
        spendingAlertsEnabled,
        dailySpendingAlertThreshold,
        weeklySpendingAlertThreshold,
        monthlySpendingAlertThreshold,
        createdAt,
        updatedAt,
      ];

  /// Get formatted currency display
  String get formattedCurrency => currencyDisplay;

  /// Get formatted large amount threshold
  String get formattedLargeAmountThreshold => 'RM ${largeAmountThreshold.toStringAsFixed(2)}';

  /// Get formatted auto-reload threshold
  String get formattedAutoReloadThreshold => 'RM ${autoReloadThreshold.toStringAsFixed(2)}';

  /// Get formatted auto-reload amount
  String get formattedAutoReloadAmount => 'RM ${autoReloadAmount.toStringAsFixed(2)}';

  /// Get auto-lock timeout display
  String get autoLockTimeoutDisplay {
    if (autoLockTimeoutMinutes < 60) {
      return '$autoLockTimeoutMinutes minutes';
    } else {
      final hours = autoLockTimeoutMinutes ~/ 60;
      final minutes = autoLockTimeoutMinutes % 60;
      if (minutes == 0) {
        return '$hours hour${hours > 1 ? 's' : ''}';
      } else {
        return '$hours hour${hours > 1 ? 's' : ''} $minutes minute${minutes > 1 ? 's' : ''}';
      }
    }
  }

  /// Check if any security features are enabled
  bool get hasSecurityFeaturesEnabled {
    return requirePinForTransactions ||
        requireBiometricForTransactions ||
        requireConfirmationForLargeAmounts;
  }

  /// Check if auto-reload is properly configured
  bool get isAutoReloadConfigured {
    return autoReloadEnabled && autoReloadPaymentMethodId != null;
  }

  /// Check if spending alerts are configured
  bool get hasSpendingAlertsConfigured {
    return spendingAlertsEnabled &&
        (dailySpendingAlertThreshold != null ||
            weeklySpendingAlertThreshold != null ||
            monthlySpendingAlertThreshold != null);
  }

  /// Get privacy level description
  String get privacyLevelDescription {
    if (!allowAnalytics && !allowMarketingNotifications && !shareTransactionData) {
      return 'High Privacy';
    } else if (allowAnalytics && !allowMarketingNotifications && !shareTransactionData) {
      return 'Medium Privacy';
    } else {
      return 'Standard Privacy';
    }
  }

  /// Create default wallet settings
  factory WalletSettings.defaultSettings({
    required String userId,
    required String walletId,
  }) {
    final now = DateTime.now();
    return WalletSettings(
      id: 'default-settings-id',
      userId: userId,
      walletId: walletId,
      currencyDisplay: 'MYR',
      showBalanceOnDashboard: true,
      showRecentTransactions: true,
      transactionHistoryLimit: 10,
      requirePinForTransactions: false,
      requireBiometricForTransactions: false,
      requireConfirmationForLargeAmounts: true,
      largeAmountThreshold: 500.00,
      autoLockTimeoutMinutes: 15,
      allowAnalytics: true,
      allowMarketingNotifications: true,
      shareTransactionData: false,
      autoReloadEnabled: false,
      autoReloadThreshold: 50.00,
      autoReloadAmount: 100.00,
      spendingAlertsEnabled: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create test wallet settings for development
  factory WalletSettings.test({
    String? userId,
    String? walletId,
    bool? autoReloadEnabled,
    bool? requirePinForTransactions,
  }) {
    final now = DateTime.now();
    return WalletSettings(
      id: 'test-settings-id',
      userId: userId ?? 'test-user-id',
      walletId: walletId ?? 'test-wallet-id',
      currencyDisplay: 'MYR',
      showBalanceOnDashboard: true,
      showRecentTransactions: true,
      transactionHistoryLimit: 10,
      requirePinForTransactions: requirePinForTransactions ?? false,
      requireBiometricForTransactions: false,
      requireConfirmationForLargeAmounts: true,
      largeAmountThreshold: 500.00,
      autoLockTimeoutMinutes: 15,
      allowAnalytics: true,
      allowMarketingNotifications: false,
      shareTransactionData: false,
      autoReloadEnabled: autoReloadEnabled ?? false,
      autoReloadThreshold: 50.00,
      autoReloadAmount: 100.00,
      autoReloadPaymentMethodId: autoReloadEnabled == true ? 'test-payment-method-id' : null,
      spendingAlertsEnabled: true,
      dailySpendingAlertThreshold: 200.00,
      weeklySpendingAlertThreshold: 1000.00,
      monthlySpendingAlertThreshold: 3000.00,
      createdAt: now.subtract(const Duration(days: 7)),
      updatedAt: now,
    );
  }
}
