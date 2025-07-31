import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'driver_wallet.g.dart';

/// Driver wallet model mirroring CustomerWallet patterns
@JsonSerializable()
class DriverWallet extends Equatable {
  final String id;
  final String userId;
  final String driverId;
  final double availableBalance;
  final double pendingBalance;
  final double totalEarned;
  final double totalWithdrawn;
  final String currency;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActivityAt;

  const DriverWallet({
    required this.id,
    required this.userId,
    required this.driverId,
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.currency,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
    this.lastActivityAt,
  });

  factory DriverWallet.fromJson(Map<String, dynamic> json) =>
      _$DriverWalletFromJson(json);

  Map<String, dynamic> toJson() => _$DriverWalletToJson(this);

  /// Create from StakeholderWallet with driver ID
  factory DriverWallet.fromStakeholderWallet(
    Map<String, dynamic> stakeholderWallet,
    String driverId,
  ) {
    return DriverWallet(
      id: stakeholderWallet['id'],
      userId: stakeholderWallet['user_id'],
      driverId: driverId,
      availableBalance: (stakeholderWallet['available_balance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (stakeholderWallet['pending_balance'] as num?)?.toDouble() ?? 0.0,
      totalEarned: (stakeholderWallet['total_earned'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawn: (stakeholderWallet['total_withdrawn'] as num?)?.toDouble() ?? 0.0,
      currency: stakeholderWallet['currency'] ?? 'MYR',
      isActive: stakeholderWallet['is_active'] ?? true,
      isVerified: stakeholderWallet['is_verified'] ?? false,
      createdAt: DateTime.parse(stakeholderWallet['created_at']),
      updatedAt: DateTime.parse(stakeholderWallet['updated_at']),
      lastActivityAt: stakeholderWallet['last_activity_at'] != null
          ? DateTime.parse(stakeholderWallet['last_activity_at'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        driverId,
        availableBalance,
        pendingBalance,
        totalEarned,
        totalWithdrawn,
        currency,
        isActive,
        isVerified,
        createdAt,
        updatedAt,
        lastActivityAt,
      ];

  /// Formatted balance displays
  String get formattedAvailableBalance => 'RM ${availableBalance.toStringAsFixed(2)}';
  String get formattedPendingBalance => 'RM ${pendingBalance.toStringAsFixed(2)}';
  String get formattedTotalEarned => 'RM ${totalEarned.toStringAsFixed(2)}';
  String get formattedTotalWithdrawn => 'RM ${totalWithdrawn.toStringAsFixed(2)}';

  /// Total balance (available + pending)
  double get totalBalance => availableBalance + pendingBalance;
  String get formattedTotalBalance => 'RM ${totalBalance.toStringAsFixed(2)}';

  /// Check if wallet has sufficient balance for withdrawal
  bool hasSufficientBalance(double amount) => availableBalance >= amount;

  /// Check if withdrawal amount meets minimum threshold
  bool meetsMinimumWithdrawal(double amount, double minimumAmount) => amount >= minimumAmount;

  /// Check if wallet can request payout
  bool get canRequestPayout => 
      isActive && 
      isVerified && 
      availableBalance > 0;

  /// Get wallet status
  DriverWalletStatus get status {
    if (!isActive) return DriverWalletStatus.inactive;
    if (!isVerified) return DriverWalletStatus.unverified;
    if (availableBalance <= 0) return DriverWalletStatus.empty;
    return DriverWalletStatus.active;
  }

  /// Create a test wallet for development
  factory DriverWallet.test({
    String? id,
    String? userId,
    String? driverId,
    double? availableBalance,
    double? totalEarned,
  }) {
    final now = DateTime.now();
    return DriverWallet(
      id: id ?? 'test-driver-wallet-id',
      userId: userId ?? 'test-driver-user-id',
      driverId: driverId ?? 'test-driver-id',
      availableBalance: availableBalance ?? 250.00,
      pendingBalance: 0.00,
      totalEarned: totalEarned ?? 1250.00,
      totalWithdrawn: 1000.00,
      currency: 'MYR',
      isActive: true,
      isVerified: true,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      lastActivityAt: now.subtract(const Duration(hours: 1)),
    );
  }

  /// Copy with method for updates
  DriverWallet copyWith({
    String? id,
    String? userId,
    String? driverId,
    double? availableBalance,
    double? pendingBalance,
    double? totalEarned,
    double? totalWithdrawn,
    String? currency,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActivityAt,
  }) {
    return DriverWallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      driverId: driverId ?? this.driverId,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }
}

/// Driver wallet status enumeration
enum DriverWalletStatus {
  active,
  inactive,
  unverified,
  empty,
}

extension DriverWalletStatusExtension on DriverWalletStatus {
  String get displayName {
    switch (this) {
      case DriverWalletStatus.active:
        return 'Active';
      case DriverWalletStatus.inactive:
        return 'Inactive';
      case DriverWalletStatus.unverified:
        return 'Unverified';
      case DriverWalletStatus.empty:
        return 'Empty';
    }
  }

  String get colorHex {
    switch (this) {
      case DriverWalletStatus.active:
        return '#4CAF50'; // Green
      case DriverWalletStatus.inactive:
        return '#9E9E9E'; // Grey
      case DriverWalletStatus.unverified:
        return '#FF9800'; // Orange
      case DriverWalletStatus.empty:
        return '#F44336'; // Red
    }
  }
}
