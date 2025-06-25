import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reward_redemption.g.dart';

/// Reward redemption status
enum RewardRedemptionStatus {
  pending,
  confirmed,
  used,
  expired,
  cancelled,
}

/// Reward redemption model
@JsonSerializable()
class RewardRedemption extends Equatable {
  final String id;
  final String loyaltyAccountId;
  final String rewardProgramId;
  final String userId;
  
  // Reward details
  final String rewardTitle;
  final String rewardDescription;
  final int pointsCost;
  final double? monetaryValue;
  
  // Redemption details
  final RewardRedemptionStatus status;
  final String? redemptionCode;
  final String? qrCode;
  final DateTime redeemedAt;
  final DateTime? usedAt;
  final DateTime? expiresAt;
  
  // Usage tracking
  final String? usedOrderId;
  final String? usedVendorId;
  final bool isUsed;
  final int usageCount;
  final int maxUsageCount;
  
  // Metadata
  final Map<String, dynamic>? metadata;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RewardRedemption({
    required this.id,
    required this.loyaltyAccountId,
    required this.rewardProgramId,
    required this.userId,
    required this.rewardTitle,
    required this.rewardDescription,
    required this.pointsCost,
    this.monetaryValue,
    required this.status,
    this.redemptionCode,
    this.qrCode,
    required this.redeemedAt,
    this.usedAt,
    this.expiresAt,
    this.usedOrderId,
    this.usedVendorId,
    required this.isUsed,
    required this.usageCount,
    required this.maxUsageCount,
    this.metadata,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RewardRedemption.fromJson(Map<String, dynamic> json) =>
      _$RewardRedemptionFromJson(json);

  Map<String, dynamic> toJson() => _$RewardRedemptionToJson(this);

  RewardRedemption copyWith({
    String? id,
    String? loyaltyAccountId,
    String? rewardProgramId,
    String? userId,
    String? rewardTitle,
    String? rewardDescription,
    int? pointsCost,
    double? monetaryValue,
    RewardRedemptionStatus? status,
    String? redemptionCode,
    String? qrCode,
    DateTime? redeemedAt,
    DateTime? usedAt,
    DateTime? expiresAt,
    String? usedOrderId,
    String? usedVendorId,
    bool? isUsed,
    int? usageCount,
    int? maxUsageCount,
    Map<String, dynamic>? metadata,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RewardRedemption(
      id: id ?? this.id,
      loyaltyAccountId: loyaltyAccountId ?? this.loyaltyAccountId,
      rewardProgramId: rewardProgramId ?? this.rewardProgramId,
      userId: userId ?? this.userId,
      rewardTitle: rewardTitle ?? this.rewardTitle,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      pointsCost: pointsCost ?? this.pointsCost,
      monetaryValue: monetaryValue ?? this.monetaryValue,
      status: status ?? this.status,
      redemptionCode: redemptionCode ?? this.redemptionCode,
      qrCode: qrCode ?? this.qrCode,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      usedAt: usedAt ?? this.usedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usedOrderId: usedOrderId ?? this.usedOrderId,
      usedVendorId: usedVendorId ?? this.usedVendorId,
      isUsed: isUsed ?? this.isUsed,
      usageCount: usageCount ?? this.usageCount,
      maxUsageCount: maxUsageCount ?? this.maxUsageCount,
      metadata: metadata ?? this.metadata,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        loyaltyAccountId,
        rewardProgramId,
        userId,
        rewardTitle,
        rewardDescription,
        pointsCost,
        monetaryValue,
        status,
        redemptionCode,
        qrCode,
        redeemedAt,
        usedAt,
        expiresAt,
        usedOrderId,
        usedVendorId,
        isUsed,
        usageCount,
        maxUsageCount,
        metadata,
        notes,
        createdAt,
        updatedAt,
      ];

  /// Formatted points cost display
  String get formattedPointsCost => '$pointsCost pts';

  /// Formatted monetary value display
  String? get formattedMonetaryValue {
    if (monetaryValue == null) return null;
    return 'RM ${monetaryValue!.toStringAsFixed(2)}';
  }

  /// Status display name
  String get statusDisplayName {
    switch (status) {
      case RewardRedemptionStatus.pending:
        return 'Pending';
      case RewardRedemptionStatus.confirmed:
        return 'Ready to Use';
      case RewardRedemptionStatus.used:
        return 'Used';
      case RewardRedemptionStatus.expired:
        return 'Expired';
      case RewardRedemptionStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Check if redemption is active and usable
  bool get isActive {
    return status == RewardRedemptionStatus.confirmed && 
           !isExpired && 
           canBeUsed;
  }

  /// Check if redemption is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if redemption can be used
  bool get canBeUsed {
    return status == RewardRedemptionStatus.confirmed &&
           !isExpired &&
           usageCount < maxUsageCount;
  }

  /// Remaining usage count
  int get remainingUsage => maxUsageCount - usageCount;

  /// Days until expiration
  int? get daysUntilExpiration {
    if (expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return 0;
    return expiresAt!.difference(now).inDays;
  }

  /// Formatted expiration display
  String? get formattedExpiration {
    if (expiresAt == null) return 'No expiration';
    final days = daysUntilExpiration;
    if (days == null) return null;
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    if (days <= 7) return 'Expires in $days days';
    return 'Expires ${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}';
  }

  /// Usage progress display
  String get usageProgressDisplay {
    if (maxUsageCount == 1) {
      return isUsed ? 'Used' : 'Available';
    }
    return '$usageCount/$maxUsageCount used';
  }

  /// Create test reward redemption for development
  factory RewardRedemption.test({
    String? id,
    String? rewardTitle,
    RewardRedemptionStatus? status,
    bool? isExpired,
  }) {
    final now = DateTime.now();
    final redemptionStatus = status ?? RewardRedemptionStatus.confirmed;
    
    return RewardRedemption(
      id: id ?? 'test-redemption-id',
      loyaltyAccountId: 'test-loyalty-account-id',
      rewardProgramId: 'test-reward-program-id',
      userId: 'test-user-id',
      rewardTitle: rewardTitle ?? 'RM 5 OFF Your Next Order',
      rewardDescription: 'Get RM 5 discount on your next food order. Valid for orders above RM 20.',
      pointsCost: 500,
      monetaryValue: 5.00,
      status: redemptionStatus,
      redemptionCode: 'GIGA5OFF2024',
      qrCode: 'https://api.qrserver.com/v1/create-qr-code/?data=GIGA5OFF2024',
      redeemedAt: now.subtract(const Duration(hours: 2)),
      usedAt: redemptionStatus == RewardRedemptionStatus.used 
          ? now.subtract(const Duration(hours: 1))
          : null,
      expiresAt: isExpired == true 
          ? now.subtract(const Duration(days: 1))
          : now.add(const Duration(days: 30)),
      usedOrderId: redemptionStatus == RewardRedemptionStatus.used 
          ? 'test-order-id'
          : null,
      isUsed: redemptionStatus == RewardRedemptionStatus.used,
      usageCount: redemptionStatus == RewardRedemptionStatus.used ? 1 : 0,
      maxUsageCount: 1,
      metadata: {
        'minimum_order_amount': 20.00,
        'discount_amount': 5.00,
        'applicable_categories': ['food'],
      },
      notes: 'Redeemed via mobile app',
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now,
    );
  }

  /// Create confirmed redemption
  factory RewardRedemption.confirmed({
    required String id,
    required String loyaltyAccountId,
    required String rewardProgramId,
    required String userId,
    required String rewardTitle,
    required String rewardDescription,
    required int pointsCost,
    double? monetaryValue,
    required String redemptionCode,
    DateTime? expiresAt,
    int maxUsageCount = 1,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return RewardRedemption(
      id: id,
      loyaltyAccountId: loyaltyAccountId,
      rewardProgramId: rewardProgramId,
      userId: userId,
      rewardTitle: rewardTitle,
      rewardDescription: rewardDescription,
      pointsCost: pointsCost,
      monetaryValue: monetaryValue,
      status: RewardRedemptionStatus.confirmed,
      redemptionCode: redemptionCode,
      redeemedAt: now,
      expiresAt: expiresAt,
      isUsed: false,
      usageCount: 0,
      maxUsageCount: maxUsageCount,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );
  }
}
