import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'stakeholder_wallet.g.dart';

@JsonSerializable()
class StakeholderWallet extends Equatable {
  final String id;
  final String userId;
  final String userRole;
  final double availableBalance;
  final double pendingBalance;
  final double totalEarned;
  final double totalWithdrawn;
  final String currency;
  final bool autoPayoutEnabled;
  final double? autoPayoutThreshold;
  final Map<String, dynamic>? bankAccountDetails;
  final String payoutSchedule;
  final bool isActive;
  final bool isVerified;
  final Map<String, dynamic>? verificationDocuments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActivityAt;

  const StakeholderWallet({
    required this.id,
    required this.userId,
    required this.userRole,
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.currency,
    required this.autoPayoutEnabled,
    this.autoPayoutThreshold,
    this.bankAccountDetails,
    required this.payoutSchedule,
    required this.isActive,
    required this.isVerified,
    this.verificationDocuments,
    required this.createdAt,
    required this.updatedAt,
    this.lastActivityAt,
  });

  factory StakeholderWallet.fromJson(Map<String, dynamic> json) =>
      _$StakeholderWalletFromJson(json);

  Map<String, dynamic> toJson() => _$StakeholderWalletToJson(this);

  StakeholderWallet copyWith({
    String? id,
    String? userId,
    String? userRole,
    double? availableBalance,
    double? pendingBalance,
    double? totalEarned,
    double? totalWithdrawn,
    String? currency,
    bool? autoPayoutEnabled,
    double? autoPayoutThreshold,
    Map<String, dynamic>? bankAccountDetails,
    String? payoutSchedule,
    bool? isActive,
    bool? isVerified,
    Map<String, dynamic>? verificationDocuments,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActivityAt,
  }) {
    return StakeholderWallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      currency: currency ?? this.currency,
      autoPayoutEnabled: autoPayoutEnabled ?? this.autoPayoutEnabled,
      autoPayoutThreshold: autoPayoutThreshold ?? this.autoPayoutThreshold,
      bankAccountDetails: bankAccountDetails ?? this.bankAccountDetails,
      payoutSchedule: payoutSchedule ?? this.payoutSchedule,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      verificationDocuments: verificationDocuments ?? this.verificationDocuments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userRole,
        availableBalance,
        pendingBalance,
        totalEarned,
        totalWithdrawn,
        currency,
        autoPayoutEnabled,
        autoPayoutThreshold,
        bankAccountDetails,
        payoutSchedule,
        isActive,
        isVerified,
        verificationDocuments,
        createdAt,
        updatedAt,
        lastActivityAt,
      ];

  /// Get formatted available balance
  String get formattedAvailableBalance => 'RM ${availableBalance.toStringAsFixed(2)}';

  /// Get formatted total earned
  String get formattedTotalEarned => 'RM ${totalEarned.toStringAsFixed(2)}';

  /// Get formatted total withdrawn
  String get formattedTotalWithdrawn => 'RM ${totalWithdrawn.toStringAsFixed(2)}';

  /// Check if wallet can request payout
  bool get canRequestPayout => 
      isActive && 
      isVerified && 
      availableBalance > 0 && 
      (autoPayoutThreshold == null || availableBalance >= autoPayoutThreshold!);

  /// Get wallet status
  WalletStatus get status {
    if (!isActive) return WalletStatus.inactive;
    if (!isVerified) return WalletStatus.unverified;
    if (availableBalance <= 0) return WalletStatus.empty;
    return WalletStatus.active;
  }

  /// Get user role display name
  String get userRoleDisplayName {
    switch (userRole) {
      case 'vendor':
        return 'Vendor';
      case 'sales_agent':
        return 'Sales Agent';
      case 'driver':
        return 'Driver';
      case 'customer':
        return 'Customer';
      case 'admin':
        return 'Admin';
      default:
        return userRole.toUpperCase();
    }
  }

  /// Get payout schedule display name
  String get payoutScheduleDisplayName {
    switch (payoutSchedule) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'manual':
        return 'Manual';
      default:
        return payoutSchedule;
    }
  }

  /// Check if auto payout is eligible
  bool get isAutoPayoutEligible =>
      autoPayoutEnabled &&
      autoPayoutThreshold != null &&
      availableBalance >= autoPayoutThreshold! &&
      isActive &&
      isVerified;

  /// Get next payout date estimate
  DateTime? get nextPayoutEstimate {
    if (!autoPayoutEnabled || lastActivityAt == null) return null;

    switch (payoutSchedule) {
      case 'daily':
        return lastActivityAt!.add(const Duration(days: 1));
      case 'weekly':
        return lastActivityAt!.add(const Duration(days: 7));
      case 'monthly':
        return lastActivityAt!.add(const Duration(days: 30));
      default:
        return null;
    }
  }

  /// Create a test wallet for development
  factory StakeholderWallet.test({
    String? id,
    String? userId,
    String? userRole,
    double? availableBalance,
    double? totalEarned,
  }) {
    final now = DateTime.now();
    return StakeholderWallet(
      id: id ?? 'test-wallet-id',
      userId: userId ?? 'test-user-id',
      userRole: userRole ?? 'vendor',
      availableBalance: availableBalance ?? 150.00,
      pendingBalance: 25.00,
      totalEarned: totalEarned ?? 500.00,
      totalWithdrawn: 350.00,
      currency: 'MYR',
      autoPayoutEnabled: true,
      autoPayoutThreshold: 100.00,
      payoutSchedule: 'weekly',
      isActive: true,
      isVerified: true,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      lastActivityAt: now.subtract(const Duration(hours: 2)),
    );
  }
}

enum WalletStatus {
  active,
  inactive,
  unverified,
  empty,
}

extension WalletStatusExtension on WalletStatus {
  String get displayName {
    switch (this) {
      case WalletStatus.active:
        return 'Active';
      case WalletStatus.inactive:
        return 'Inactive';
      case WalletStatus.unverified:
        return 'Unverified';
      case WalletStatus.empty:
        return 'Empty';
    }
  }

  bool get isHealthy => this == WalletStatus.active;
}
