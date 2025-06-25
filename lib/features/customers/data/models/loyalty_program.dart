import 'package:freezed_annotation/freezed_annotation.dart';

part 'loyalty_program.freezed.dart';
part 'loyalty_program.g.dart';

/// Loyalty tier model
@freezed
class LoyaltyTier with _$LoyaltyTier {
  const factory LoyaltyTier({
    required String id,
    required String name,
    String? description,
    @Default(0) int minPoints,
    int? maxPoints,
    @Default({}) Map<String, dynamic> benefits,
    @Default('star') String icon,
    @Default('#FFD700') String colorCode,
    @Default(0) int sortOrder,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _LoyaltyTier;

  factory LoyaltyTier.fromJson(Map<String, dynamic> json) => _$LoyaltyTierFromJson(json);
}

/// Loyalty transaction model
@freezed
class LoyaltyTransaction with _$LoyaltyTransaction {
  const factory LoyaltyTransaction({
    required String id,
    required String customerId,
    required LoyaltyTransactionType transactionType,
    required int points,
    String? orderId,
    String? referralId,
    String? rewardId,
    required String description,
    @Default({}) Map<String, dynamic> metadata,
    DateTime? expiresAt,
    required DateTime processedAt,
    required DateTime createdAt,
  }) = _LoyaltyTransaction;

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) => _$LoyaltyTransactionFromJson(json);
}

/// Loyalty reward model
@freezed
class LoyaltyReward with _$LoyaltyReward {
  const factory LoyaltyReward({
    required String id,
    required String name,
    required String description,
    required int pointsRequired,
    required LoyaltyRewardType rewardType,
    double? rewardValue,
    @Default(true) bool isActive,
    int? maxRedemptionsPerCustomer,
    int? maxTotalRedemptions,
    @Default(0) int currentRedemptions,
    required DateTime validFrom,
    DateTime? validUntil,
    double? minOrderAmount,
    @Default([]) List<String> applicableVendors,
    @Default([]) List<String> applicableCategories,
    String? imageUrl,
    String? termsConditions,
    @Default(0) int sortOrder,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _LoyaltyReward;

  factory LoyaltyReward.fromJson(Map<String, dynamic> json) => _$LoyaltyRewardFromJson(json);
}

/// Loyalty redemption model
@freezed
class LoyaltyRedemption with _$LoyaltyRedemption {
  const factory LoyaltyRedemption({
    required String id,
    required String customerId,
    required String rewardId,
    String? orderId,
    required int pointsUsed,
    double? discountAmount,
    @Default(LoyaltyRedemptionStatus.active) LoyaltyRedemptionStatus status,
    DateTime? expiresAt,
    DateTime? usedAt,
    String? voucherCode,
    required DateTime createdAt,
    required DateTime updatedAt,
    
    // Related data
    LoyaltyReward? reward,
  }) = _LoyaltyRedemption;

  factory LoyaltyRedemption.fromJson(Map<String, dynamic> json) => _$LoyaltyRedemptionFromJson(json);
}

/// Loyalty referral model
@freezed
class LoyaltyReferral with _$LoyaltyReferral {
  const factory LoyaltyReferral({
    required String id,
    required String referrerId,
    String? refereeId,
    required String referralCode,
    @Default(LoyaltyReferralStatus.pending) LoyaltyReferralStatus status,
    @Default(0) int referrerPoints,
    @Default(0) int refereePoints,
    DateTime? referrerRewardedAt,
    DateTime? refereeRewardedAt,
    @Default(1) int minRefereeOrders,
    @Default(0.0) double minRefereeSpend,
    @Default(0) int refereeOrdersCount,
    @Default(0.0) double refereeTotalSpend,
    required DateTime expiresAt,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _LoyaltyReferral;

  factory LoyaltyReferral.fromJson(Map<String, dynamic> json) => _$LoyaltyReferralFromJson(json);
}

/// Loyalty program summary for customer
@freezed
class LoyaltyProgramSummary with _$LoyaltyProgramSummary {
  const factory LoyaltyProgramSummary({
    required int currentPoints,
    required LoyaltyTier currentTier,
    LoyaltyTier? nextTier,
    int? pointsToNextTier,
    required int totalPointsEarned,
    required int totalPointsRedeemed,
    required List<LoyaltyTransaction> recentTransactions,
    required List<LoyaltyReward> availableRewards,
    required List<LoyaltyRedemption> activeRedemptions,
    LoyaltyReferral? activeReferral,
  }) = _LoyaltyProgramSummary;

  factory LoyaltyProgramSummary.fromJson(Map<String, dynamic> json) => _$LoyaltyProgramSummaryFromJson(json);
}

/// Loyalty transaction types
enum LoyaltyTransactionType {
  @JsonValue('earned')
  earned,
  @JsonValue('redeemed')
  redeemed,
  @JsonValue('expired')
  expired,
  @JsonValue('bonus')
  bonus,
  @JsonValue('referral')
  referral,
  @JsonValue('adjustment')
  adjustment,
}

/// Loyalty reward types
enum LoyaltyRewardType {
  @JsonValue('discount_percentage')
  discountPercentage,
  @JsonValue('discount_fixed')
  discountFixed,
  @JsonValue('free_delivery')
  freeDelivery,
  @JsonValue('free_item')
  freeItem,
  @JsonValue('cashback')
  cashback,
  @JsonValue('voucher')
  voucher,
}

/// Loyalty redemption status
enum LoyaltyRedemptionStatus {
  @JsonValue('active')
  active,
  @JsonValue('used')
  used,
  @JsonValue('expired')
  expired,
  @JsonValue('cancelled')
  cancelled,
}

/// Loyalty referral status
enum LoyaltyReferralStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('completed')
  completed,
  @JsonValue('expired')
  expired,
  @JsonValue('cancelled')
  cancelled,
}

/// Extensions for loyalty transaction type
extension LoyaltyTransactionTypeExtension on LoyaltyTransactionType {
  String get displayName {
    switch (this) {
      case LoyaltyTransactionType.earned:
        return 'Earned';
      case LoyaltyTransactionType.redeemed:
        return 'Redeemed';
      case LoyaltyTransactionType.expired:
        return 'Expired';
      case LoyaltyTransactionType.bonus:
        return 'Bonus';
      case LoyaltyTransactionType.referral:
        return 'Referral';
      case LoyaltyTransactionType.adjustment:
        return 'Adjustment';
    }
  }

  String get icon {
    switch (this) {
      case LoyaltyTransactionType.earned:
        return 'add_circle';
      case LoyaltyTransactionType.redeemed:
        return 'remove_circle';
      case LoyaltyTransactionType.expired:
        return 'schedule';
      case LoyaltyTransactionType.bonus:
        return 'card_giftcard';
      case LoyaltyTransactionType.referral:
        return 'people';
      case LoyaltyTransactionType.adjustment:
        return 'tune';
    }
  }

  bool get isPositive {
    return this == LoyaltyTransactionType.earned || 
           this == LoyaltyTransactionType.bonus || 
           this == LoyaltyTransactionType.referral;
  }
}

/// Extensions for loyalty reward type
extension LoyaltyRewardTypeExtension on LoyaltyRewardType {
  String get displayName {
    switch (this) {
      case LoyaltyRewardType.discountPercentage:
        return 'Percentage Discount';
      case LoyaltyRewardType.discountFixed:
        return 'Fixed Discount';
      case LoyaltyRewardType.freeDelivery:
        return 'Free Delivery';
      case LoyaltyRewardType.freeItem:
        return 'Free Item';
      case LoyaltyRewardType.cashback:
        return 'Cashback';
      case LoyaltyRewardType.voucher:
        return 'Voucher';
    }
  }

  String get icon {
    switch (this) {
      case LoyaltyRewardType.discountPercentage:
        return 'percent';
      case LoyaltyRewardType.discountFixed:
        return 'money_off';
      case LoyaltyRewardType.freeDelivery:
        return 'local_shipping';
      case LoyaltyRewardType.freeItem:
        return 'redeem';
      case LoyaltyRewardType.cashback:
        return 'account_balance_wallet';
      case LoyaltyRewardType.voucher:
        return 'confirmation_number';
    }
  }
}

/// Extensions for loyalty redemption status
extension LoyaltyRedemptionStatusExtension on LoyaltyRedemptionStatus {
  String get displayName {
    switch (this) {
      case LoyaltyRedemptionStatus.active:
        return 'Active';
      case LoyaltyRedemptionStatus.used:
        return 'Used';
      case LoyaltyRedemptionStatus.expired:
        return 'Expired';
      case LoyaltyRedemptionStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get colorCode {
    switch (this) {
      case LoyaltyRedemptionStatus.active:
        return '#4CAF50'; // Green
      case LoyaltyRedemptionStatus.used:
        return '#757575'; // Grey
      case LoyaltyRedemptionStatus.expired:
        return '#FF9800'; // Orange
      case LoyaltyRedemptionStatus.cancelled:
        return '#F44336'; // Red
    }
  }
}

/// Extensions for loyalty referral status
extension LoyaltyReferralStatusExtension on LoyaltyReferralStatus {
  String get displayName {
    switch (this) {
      case LoyaltyReferralStatus.pending:
        return 'Pending';
      case LoyaltyReferralStatus.completed:
        return 'Completed';
      case LoyaltyReferralStatus.expired:
        return 'Expired';
      case LoyaltyReferralStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get colorCode {
    switch (this) {
      case LoyaltyReferralStatus.pending:
        return '#FF9800'; // Orange
      case LoyaltyReferralStatus.completed:
        return '#4CAF50'; // Green
      case LoyaltyReferralStatus.expired:
        return '#757575'; // Grey
      case LoyaltyReferralStatus.cancelled:
        return '#F44336'; // Red
    }
  }
}

/// Extensions for LoyaltyReward to provide backward compatibility
extension LoyaltyRewardExtension on LoyaltyReward {
  /// Alias for rewardValue to match widget expectations
  double? get discountValue => rewardValue;

  /// Determine discount type based on reward type
  String get discountType {
    switch (rewardType) {
      case LoyaltyRewardType.discountPercentage:
        return 'percentage';
      case LoyaltyRewardType.discountFixed:
        return 'fixed';
      default:
        return 'fixed';
    }
  }

  /// Alias for validUntil to match widget expectations
  DateTime? get expiresAt => validUntil;

  /// Alias for termsConditions to match widget expectations
  String? get termsAndConditions => termsConditions;
}

/// Extensions for LoyaltyTier to provide backward compatibility
extension LoyaltyTierExtension on LoyaltyTier {
  /// Alias for minPoints to match widget expectations
  int get minimumPoints => minPoints;
}
