import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'loyalty_account.g.dart';

/// Loyalty tier levels
enum LoyaltyTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

/// Loyalty account status
enum LoyaltyAccountStatus {
  active,
  inactive,
  suspended,
  pending,
}

/// Comprehensive loyalty account model
@JsonSerializable()
class LoyaltyAccount extends Equatable {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'wallet_id')
  final String? walletId;

  // Points tracking
  @JsonKey(name: 'available_points')
  final int availablePoints;
  @JsonKey(name: 'pending_points')
  final int pendingPoints;
  @JsonKey(name: 'lifetime_earned_points')
  final int lifetimeEarnedPoints;
  @JsonKey(name: 'lifetime_redeemed_points')
  final int lifetimeRedeemedPoints;

  // Tier system
  @JsonKey(name: 'current_tier')
  final LoyaltyTier currentTier;
  @JsonKey(name: 'tier_progress')
  final int tierProgress;
  @JsonKey(name: 'next_tier_requirement')
  final int nextTierRequirement;
  @JsonKey(name: 'tier_multiplier')
  final double tierMultiplier;

  // Cashback tracking
  @JsonKey(name: 'total_cashback_earned')
  final double totalCashbackEarned;
  @JsonKey(name: 'pending_cashback')
  final double pendingCashback;
  @JsonKey(name: 'cashback_rate')
  final double cashbackRate;

  // Referral system
  @JsonKey(name: 'referral_code')
  final String referralCode;
  @JsonKey(name: 'successful_referrals')
  final int successfulReferrals;
  @JsonKey(name: 'total_referral_bonus')
  final double totalReferralBonus;

  // Account status
  final LoyaltyAccountStatus status;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'last_activity_at')
  final DateTime? lastActivityAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const LoyaltyAccount({
    required this.id,
    required this.userId,
    this.walletId,
    required this.availablePoints,
    required this.pendingPoints,
    required this.lifetimeEarnedPoints,
    required this.lifetimeRedeemedPoints,
    required this.currentTier,
    required this.tierProgress,
    required this.nextTierRequirement,
    required this.tierMultiplier,
    required this.totalCashbackEarned,
    required this.pendingCashback,
    required this.cashbackRate,
    required this.referralCode,
    required this.successfulReferrals,
    required this.totalReferralBonus,
    required this.status,
    required this.isVerified,
    this.lastActivityAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyAccountFromJson(json);

  Map<String, dynamic> toJson() => _$LoyaltyAccountToJson(this);

  LoyaltyAccount copyWith({
    String? id,
    String? userId,
    String? walletId,
    int? availablePoints,
    int? pendingPoints,
    int? lifetimeEarnedPoints,
    int? lifetimeRedeemedPoints,
    LoyaltyTier? currentTier,
    int? tierProgress,
    int? nextTierRequirement,
    double? tierMultiplier,
    double? totalCashbackEarned,
    double? pendingCashback,
    double? cashbackRate,
    String? referralCode,
    int? successfulReferrals,
    double? totalReferralBonus,
    LoyaltyAccountStatus? status,
    bool? isVerified,
    DateTime? lastActivityAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoyaltyAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      availablePoints: availablePoints ?? this.availablePoints,
      pendingPoints: pendingPoints ?? this.pendingPoints,
      lifetimeEarnedPoints: lifetimeEarnedPoints ?? this.lifetimeEarnedPoints,
      lifetimeRedeemedPoints: lifetimeRedeemedPoints ?? this.lifetimeRedeemedPoints,
      currentTier: currentTier ?? this.currentTier,
      tierProgress: tierProgress ?? this.tierProgress,
      nextTierRequirement: nextTierRequirement ?? this.nextTierRequirement,
      tierMultiplier: tierMultiplier ?? this.tierMultiplier,
      totalCashbackEarned: totalCashbackEarned ?? this.totalCashbackEarned,
      pendingCashback: pendingCashback ?? this.pendingCashback,
      cashbackRate: cashbackRate ?? this.cashbackRate,
      referralCode: referralCode ?? this.referralCode,
      successfulReferrals: successfulReferrals ?? this.successfulReferrals,
      totalReferralBonus: totalReferralBonus ?? this.totalReferralBonus,
      status: status ?? this.status,
      isVerified: isVerified ?? this.isVerified,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        availablePoints,
        pendingPoints,
        lifetimeEarnedPoints,
        lifetimeRedeemedPoints,
        currentTier,
        tierProgress,
        nextTierRequirement,
        tierMultiplier,
        totalCashbackEarned,
        pendingCashback,
        cashbackRate,
        referralCode,
        successfulReferrals,
        totalReferralBonus,
        status,
        isVerified,
        lastActivityAt,
        createdAt,
        updatedAt,
      ];

  /// Formatted points display
  String get formattedAvailablePoints => '$availablePoints pts';
  String get formattedPendingPoints => '$pendingPoints pts';
  String get formattedLifetimePoints => '$lifetimeEarnedPoints pts';

  /// Formatted cashback display
  String get formattedTotalCashback => 'RM ${totalCashbackEarned.toStringAsFixed(2)}';
  String get formattedPendingCashback => 'RM ${pendingCashback.toStringAsFixed(2)}';

  /// Tier display helpers
  String get tierDisplayName {
    switch (currentTier) {
      case LoyaltyTier.bronze:
        return 'Bronze';
      case LoyaltyTier.silver:
        return 'Silver';
      case LoyaltyTier.gold:
        return 'Gold';
      case LoyaltyTier.platinum:
        return 'Platinum';
      case LoyaltyTier.diamond:
        return 'Diamond';
    }
  }

  /// Tier progress percentage
  double get tierProgressPercentage {
    if (nextTierRequirement == 0) return 1.0;
    return tierProgress / nextTierRequirement;
  }

  /// Check if account is active
  bool get isActive => status == LoyaltyAccountStatus.active && isVerified;

  /// Total points (available + pending)
  int get totalPoints => availablePoints + pendingPoints;

  /// Check if user can redeem points
  bool canRedeemPoints(int pointsRequired) => availablePoints >= pointsRequired;

  /// Create test loyalty account for development
  factory LoyaltyAccount.test({
    String? id,
    String? userId,
    String? walletId,
    int? availablePoints,
    LoyaltyTier? tier,
  }) {
    final now = DateTime.now();
    return LoyaltyAccount(
      id: id ?? 'test-loyalty-account-id',
      userId: userId ?? 'test-user-id',
      walletId: walletId,
      availablePoints: availablePoints ?? 2500,
      pendingPoints: 150,
      lifetimeEarnedPoints: 5000,
      lifetimeRedeemedPoints: 2350,
      currentTier: tier ?? LoyaltyTier.gold,
      tierProgress: 750,
      nextTierRequirement: 1000,
      tierMultiplier: 1.5,
      totalCashbackEarned: 125.50,
      pendingCashback: 15.25,
      cashbackRate: 0.02,
      referralCode: 'GIGA2024',
      successfulReferrals: 3,
      totalReferralBonus: 75.00,
      status: LoyaltyAccountStatus.active,
      isVerified: true,
      lastActivityAt: now.subtract(const Duration(hours: 2)),
      createdAt: now.subtract(const Duration(days: 90)),
      updatedAt: now,
    );
  }
}
