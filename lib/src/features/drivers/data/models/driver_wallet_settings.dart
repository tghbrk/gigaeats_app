import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'driver_wallet_settings.g.dart';

/// Driver wallet settings model for preferences and configuration
@JsonSerializable()
class DriverWalletSettings extends Equatable {
  final String id;
  @JsonKey(name: 'driver_id')
  final String driverId;
  @JsonKey(name: 'user_id')
  final String userId;
  
  // Auto-payout preferences
  @JsonKey(name: 'auto_payout_enabled')
  final bool autoPayoutEnabled;
  @JsonKey(name: 'auto_payout_threshold')
  final double autoPayoutThreshold;
  @JsonKey(name: 'auto_payout_schedule')
  final String autoPayoutSchedule;
  
  // Withdrawal preferences
  @JsonKey(name: 'preferred_withdrawal_method')
  final String preferredWithdrawalMethod;
  @JsonKey(name: 'minimum_withdrawal_amount')
  final double minimumWithdrawalAmount;
  @JsonKey(name: 'maximum_daily_withdrawal')
  final double maximumDailyWithdrawal;
  
  // Account details
  @JsonKey(name: 'bank_account_details')
  final Map<String, dynamic> bankAccountDetails;
  @JsonKey(name: 'ewallet_details')
  final Map<String, dynamic> ewalletDetails;
  
  // Notification preferences
  @JsonKey(name: 'earnings_notifications')
  final bool earningsNotifications;
  @JsonKey(name: 'withdrawal_notifications')
  final bool withdrawalNotifications;
  @JsonKey(name: 'low_balance_alerts')
  final bool lowBalanceAlerts;
  @JsonKey(name: 'low_balance_threshold')
  final double lowBalanceThreshold;
  
  // Security settings
  @JsonKey(name: 'require_pin_for_withdrawals')
  final bool requirePinForWithdrawals;
  @JsonKey(name: 'require_biometric_auth')
  final bool requireBiometricAuth;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const DriverWalletSettings({
    required this.id,
    required this.driverId,
    required this.userId,
    this.autoPayoutEnabled = false,
    this.autoPayoutThreshold = 100.00,
    this.autoPayoutSchedule = 'weekly',
    this.preferredWithdrawalMethod = 'bank_transfer',
    this.minimumWithdrawalAmount = 10.00,
    this.maximumDailyWithdrawal = 1000.00,
    this.bankAccountDetails = const {},
    this.ewalletDetails = const {},
    this.earningsNotifications = true,
    this.withdrawalNotifications = true,
    this.lowBalanceAlerts = true,
    this.lowBalanceThreshold = 20.00,
    this.requirePinForWithdrawals = false,
    this.requireBiometricAuth = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverWalletSettings.fromJson(Map<String, dynamic> json) =>
      _$DriverWalletSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$DriverWalletSettingsToJson(this);

  @override
  List<Object?> get props => [
        id,
        driverId,
        userId,
        autoPayoutEnabled,
        autoPayoutThreshold,
        autoPayoutSchedule,
        preferredWithdrawalMethod,
        minimumWithdrawalAmount,
        maximumDailyWithdrawal,
        bankAccountDetails,
        ewalletDetails,
        earningsNotifications,
        withdrawalNotifications,
        lowBalanceAlerts,
        lowBalanceThreshold,
        requirePinForWithdrawals,
        requireBiometricAuth,
        createdAt,
        updatedAt,
      ];

  /// Formatted minimum withdrawal amount
  String get formattedMinimumWithdrawal => 'RM ${minimumWithdrawalAmount.toStringAsFixed(2)}';

  /// Formatted maximum daily withdrawal
  String get formattedMaximumDailyWithdrawal => 'RM ${maximumDailyWithdrawal.toStringAsFixed(2)}';

  /// Formatted auto-payout threshold
  String get formattedAutoPayoutThreshold => 'RM ${autoPayoutThreshold.toStringAsFixed(2)}';

  /// Formatted low balance threshold
  String get formattedLowBalanceThreshold => 'RM ${lowBalanceThreshold.toStringAsFixed(2)}';

  /// Get withdrawal method display name
  String get withdrawalMethodDisplayName {
    switch (preferredWithdrawalMethod) {
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'ewallet':
        return 'E-Wallet';
      case 'cash':
        return 'Cash Pickup';
      default:
        return 'Unknown';
    }
  }

  /// Get auto-payout schedule display name
  String get autoPayoutScheduleDisplayName {
    switch (autoPayoutSchedule) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return 'Unknown';
    }
  }

  /// Check if bank account details are configured
  bool get hasBankAccountDetails => 
      bankAccountDetails.isNotEmpty &&
      bankAccountDetails.containsKey('account_number') &&
      bankAccountDetails.containsKey('bank_name');

  /// Check if e-wallet details are configured
  bool get hasEwalletDetails => 
      ewalletDetails.isNotEmpty &&
      ewalletDetails.containsKey('account_id') &&
      ewalletDetails.containsKey('provider');

  /// Check if withdrawal method is properly configured
  bool get isWithdrawalMethodConfigured {
    switch (preferredWithdrawalMethod) {
      case 'bank_transfer':
        return hasBankAccountDetails;
      case 'ewallet':
        return hasEwalletDetails;
      case 'cash':
        return true; // Cash pickup doesn't require additional configuration
      default:
        return false;
    }
  }

  /// Create default settings for a new driver
  factory DriverWalletSettings.createDefault({
    required String driverId,
    required String userId,
  }) {
    final now = DateTime.now();
    return DriverWalletSettings(
      id: '', // Will be generated by database
      driverId: driverId,
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create a test settings object for development
  factory DriverWalletSettings.test({
    String? id,
    String? driverId,
    String? userId,
  }) {
    final now = DateTime.now();
    return DriverWalletSettings(
      id: id ?? 'test-driver-wallet-settings-id',
      driverId: driverId ?? 'test-driver-id',
      userId: userId ?? 'test-driver-user-id',
      autoPayoutEnabled: true,
      autoPayoutThreshold: 200.00,
      autoPayoutSchedule: 'weekly',
      preferredWithdrawalMethod: 'bank_transfer',
      minimumWithdrawalAmount: 20.00,
      maximumDailyWithdrawal: 500.00,
      bankAccountDetails: {
        'bank_name': 'Test Bank',
        'account_number': '1234567890',
        'account_holder': 'Test Driver',
      },
      earningsNotifications: true,
      withdrawalNotifications: true,
      lowBalanceAlerts: true,
      lowBalanceThreshold: 50.00,
      requirePinForWithdrawals: true,
      requireBiometricAuth: false,
      createdAt: now.subtract(const Duration(days: 7)),
      updatedAt: now,
    );
  }

  /// Copy with method for updates
  DriverWalletSettings copyWith({
    String? id,
    String? driverId,
    String? userId,
    bool? autoPayoutEnabled,
    double? autoPayoutThreshold,
    String? autoPayoutSchedule,
    String? preferredWithdrawalMethod,
    double? minimumWithdrawalAmount,
    double? maximumDailyWithdrawal,
    Map<String, dynamic>? bankAccountDetails,
    Map<String, dynamic>? ewalletDetails,
    bool? earningsNotifications,
    bool? withdrawalNotifications,
    bool? lowBalanceAlerts,
    double? lowBalanceThreshold,
    bool? requirePinForWithdrawals,
    bool? requireBiometricAuth,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverWalletSettings(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      userId: userId ?? this.userId,
      autoPayoutEnabled: autoPayoutEnabled ?? this.autoPayoutEnabled,
      autoPayoutThreshold: autoPayoutThreshold ?? this.autoPayoutThreshold,
      autoPayoutSchedule: autoPayoutSchedule ?? this.autoPayoutSchedule,
      preferredWithdrawalMethod: preferredWithdrawalMethod ?? this.preferredWithdrawalMethod,
      minimumWithdrawalAmount: minimumWithdrawalAmount ?? this.minimumWithdrawalAmount,
      maximumDailyWithdrawal: maximumDailyWithdrawal ?? this.maximumDailyWithdrawal,
      bankAccountDetails: bankAccountDetails ?? this.bankAccountDetails,
      ewalletDetails: ewalletDetails ?? this.ewalletDetails,
      earningsNotifications: earningsNotifications ?? this.earningsNotifications,
      withdrawalNotifications: withdrawalNotifications ?? this.withdrawalNotifications,
      lowBalanceAlerts: lowBalanceAlerts ?? this.lowBalanceAlerts,
      lowBalanceThreshold: lowBalanceThreshold ?? this.lowBalanceThreshold,
      requirePinForWithdrawals: requirePinForWithdrawals ?? this.requirePinForWithdrawals,
      requireBiometricAuth: requireBiometricAuth ?? this.requireBiometricAuth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
