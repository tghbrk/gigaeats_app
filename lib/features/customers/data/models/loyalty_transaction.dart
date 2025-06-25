import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'loyalty_transaction.g.dart';

/// Loyalty transaction types
enum LoyaltyTransactionType {
  earned,
  redeemed,
  expired,
  bonus,
  cashback,
  referral,
  adjustment,
  promotion,
}

/// Loyalty transaction model
@JsonSerializable()
class LoyaltyTransaction extends Equatable {
  final String id;

  @JsonKey(name: 'loyalty_account_id')
  final String loyaltyAccountId;

  @JsonKey(name: 'transaction_type')
  final LoyaltyTransactionType transactionType;

  @JsonKey(name: 'points_amount')
  final int pointsAmount;

  @JsonKey(name: 'points_balance_before')
  final int pointsBalanceBefore;

  @JsonKey(name: 'points_balance_after')
  final int pointsBalanceAfter;

  @JsonKey(name: 'reference_type')
  final String? referenceType;

  @JsonKey(name: 'reference_id')
  final String? referenceId;

  final String description;
  final Map<String, dynamic>? metadata;

  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const LoyaltyTransaction({
    required this.id,
    required this.loyaltyAccountId,
    required this.transactionType,
    required this.pointsAmount,
    required this.pointsBalanceBefore,
    required this.pointsBalanceAfter,
    this.referenceType,
    this.referenceId,
    required this.description,
    this.metadata,
    this.expiresAt,
    required this.createdAt,
  });

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyTransactionFromJson(json);

  Map<String, dynamic> toJson() => _$LoyaltyTransactionToJson(this);

  LoyaltyTransaction copyWith({
    String? id,
    String? loyaltyAccountId,
    LoyaltyTransactionType? transactionType,
    int? pointsAmount,
    int? pointsBalanceBefore,
    int? pointsBalanceAfter,
    String? referenceType,
    String? referenceId,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return LoyaltyTransaction(
      id: id ?? this.id,
      loyaltyAccountId: loyaltyAccountId ?? this.loyaltyAccountId,
      transactionType: transactionType ?? this.transactionType,
      pointsAmount: pointsAmount ?? this.pointsAmount,
      pointsBalanceBefore: pointsBalanceBefore ?? this.pointsBalanceBefore,
      pointsBalanceAfter: pointsBalanceAfter ?? this.pointsBalanceAfter,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        loyaltyAccountId,
        transactionType,
        pointsAmount,
        pointsBalanceBefore,
        pointsBalanceAfter,
        referenceType,
        referenceId,
        description,
        metadata,
        expiresAt,
        createdAt,
      ];

  /// Formatted points display
  String get formattedPointsAmount {
    final sign = pointsAmount >= 0 ? '+' : '';
    return '$sign$pointsAmount pts';
  }

  /// Transaction type display
  String get typeDisplayName {
    switch (transactionType) {
      case LoyaltyTransactionType.earned:
        return 'Points Earned';
      case LoyaltyTransactionType.redeemed:
        return 'Points Redeemed';
      case LoyaltyTransactionType.expired:
        return 'Points Expired';
      case LoyaltyTransactionType.bonus:
        return 'Bonus Points';
      case LoyaltyTransactionType.cashback:
        return 'Cashback Earned';
      case LoyaltyTransactionType.referral:
        return 'Referral Bonus';
      case LoyaltyTransactionType.adjustment:
        return 'Points Adjustment';
      case LoyaltyTransactionType.promotion:
        return 'Promotional Points';
    }
  }

  /// Check if transaction is positive (adds points)
  bool get isPositive => pointsAmount > 0;

  /// Check if transaction is negative (removes points)
  bool get isNegative => pointsAmount < 0;

  /// Check if points will expire
  bool get hasExpiration => expiresAt != null;

  /// Check if points are expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Days until expiration
  int? get daysUntilExpiration {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return 0;
    return expiresAt!.difference(now).inDays;
  }

  /// Formatted expiration display
  String? get formattedExpiration {
    if (expiresAt == null) return null;
    final days = daysUntilExpiration;
    if (days == null) return null;
    if (days == 0) return 'Expired';
    if (days == 1) return 'Expires tomorrow';
    if (days <= 7) return 'Expires in $days days';
    return 'Expires ${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}';
  }

  /// Create test loyalty transaction for development
  factory LoyaltyTransaction.test({
    String? id,
    String? loyaltyAccountId,
    LoyaltyTransactionType? type,
    int? pointsAmount,
    String? description,
  }) {
    final now = DateTime.now();
    final transactionType = type ?? LoyaltyTransactionType.earned;
    final points = pointsAmount ?? 50;
    
    return LoyaltyTransaction(
      id: id ?? 'test-loyalty-transaction-id',
      loyaltyAccountId: loyaltyAccountId ?? 'test-loyalty-account-id',
      transactionType: transactionType,
      pointsAmount: points,
      pointsBalanceBefore: 1000,
      pointsBalanceAfter: 1000 + points,
      referenceType: 'order',
      referenceId: 'test-order-id',
      description: description ?? 'Points earned from order #12345',
      metadata: {
        'order_amount': 25.50,
        'multiplier': 1.0,
        'vendor_id': 'test-vendor-id',
      },
      expiresAt: transactionType == LoyaltyTransactionType.earned 
          ? now.add(const Duration(days: 365))
          : null,
      createdAt: now,
    );
  }

  /// Create earned points transaction
  factory LoyaltyTransaction.earned({
    required String id,
    required String loyaltyAccountId,
    required int pointsAmount,
    required int pointsBalanceBefore,
    required String orderId,
    required double orderAmount,
    double multiplier = 1.0,
    String? vendorId,
  }) {
    final now = DateTime.now();
    return LoyaltyTransaction(
      id: id,
      loyaltyAccountId: loyaltyAccountId,
      transactionType: LoyaltyTransactionType.earned,
      pointsAmount: pointsAmount,
      pointsBalanceBefore: pointsBalanceBefore,
      pointsBalanceAfter: pointsBalanceBefore + pointsAmount,
      referenceType: 'order',
      referenceId: orderId,
      description: 'Points earned from order',
      metadata: {
        'order_amount': orderAmount,
        'multiplier': multiplier,
        if (vendorId != null) 'vendor_id': vendorId,
      },
      expiresAt: now.add(const Duration(days: 365)),
      createdAt: now,
    );
  }

  /// Create redeemed points transaction
  factory LoyaltyTransaction.redeemed({
    required String id,
    required String loyaltyAccountId,
    required int pointsAmount,
    required int pointsBalanceBefore,
    required String rewardId,
    required String rewardName,
  }) {
    final now = DateTime.now();
    return LoyaltyTransaction(
      id: id,
      loyaltyAccountId: loyaltyAccountId,
      transactionType: LoyaltyTransactionType.redeemed,
      pointsAmount: -pointsAmount,
      pointsBalanceBefore: pointsBalanceBefore,
      pointsBalanceAfter: pointsBalanceBefore - pointsAmount,
      referenceType: 'reward',
      referenceId: rewardId,
      description: 'Points redeemed for $rewardName',
      metadata: {
        'reward_name': rewardName,
        'points_cost': pointsAmount,
      },
      createdAt: now,
    );
  }

  /// Create referral bonus transaction
  factory LoyaltyTransaction.referralBonus({
    required String id,
    required String loyaltyAccountId,
    required int pointsAmount,
    required int pointsBalanceBefore,
    required String referralId,
    required String refereeUserId,
  }) {
    final now = DateTime.now();
    return LoyaltyTransaction(
      id: id,
      loyaltyAccountId: loyaltyAccountId,
      transactionType: LoyaltyTransactionType.referral,
      pointsAmount: pointsAmount,
      pointsBalanceBefore: pointsBalanceBefore,
      pointsBalanceAfter: pointsBalanceBefore + pointsAmount,
      referenceType: 'referral',
      referenceId: referralId,
      description: 'Referral bonus for successful referral',
      metadata: {
        'referee_user_id': refereeUserId,
        'bonus_amount': pointsAmount,
      },
      createdAt: now,
    );
  }
}
