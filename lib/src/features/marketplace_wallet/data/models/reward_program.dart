import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reward_program.g.dart';

/// Reward types
enum RewardType {
  discount,
  cashback,
  freeItem,
  pointsMultiplier,
  tierUpgrade,
  freeDelivery,
  voucher,
}

/// Reward category
enum RewardCategory {
  food,
  delivery,
  general,
  vendor,
  seasonal,
  tier,
}

/// Reward availability status
enum RewardAvailability {
  available,
  outOfStock,
  expired,
  inactive,
  comingSoon,
}

/// Comprehensive reward program model
@JsonSerializable()
class RewardProgram extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final RewardType rewardType;
  final RewardCategory category;
  
  // Points and value
  final int pointsCost;
  final double? monetaryValue;
  final double? discountPercentage;
  final double? discountAmount;
  
  // Availability
  final RewardAvailability availability;
  final int? totalStock;
  final int? remainingStock;
  final bool isUnlimited;
  
  // Validity
  final DateTime? validFrom;
  final DateTime? validUntil;
  final int? usageLimit;
  final int? usageLimitPerUser;
  
  // Vendor specific
  final String? vendorId;
  final String? vendorName;
  final bool isPlatformWide;
  
  // Tier requirements
  final String? minimumTier;
  final bool isExclusive;
  
  // Terms and conditions
  final List<String> terms;
  final String? redemptionInstructions;
  
  // Metadata
  final Map<String, dynamic>? metadata;
  final bool isActive;
  final bool isFeatured;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RewardProgram({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.rewardType,
    required this.category,
    required this.pointsCost,
    this.monetaryValue,
    this.discountPercentage,
    this.discountAmount,
    required this.availability,
    this.totalStock,
    this.remainingStock,
    required this.isUnlimited,
    this.validFrom,
    this.validUntil,
    this.usageLimit,
    this.usageLimitPerUser,
    this.vendorId,
    this.vendorName,
    required this.isPlatformWide,
    this.minimumTier,
    required this.isExclusive,
    required this.terms,
    this.redemptionInstructions,
    this.metadata,
    required this.isActive,
    required this.isFeatured,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RewardProgram.fromJson(Map<String, dynamic> json) =>
      _$RewardProgramFromJson(json);

  Map<String, dynamic> toJson() => _$RewardProgramToJson(this);

  RewardProgram copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    RewardType? rewardType,
    RewardCategory? category,
    int? pointsCost,
    double? monetaryValue,
    double? discountPercentage,
    double? discountAmount,
    RewardAvailability? availability,
    int? totalStock,
    int? remainingStock,
    bool? isUnlimited,
    DateTime? validFrom,
    DateTime? validUntil,
    int? usageLimit,
    int? usageLimitPerUser,
    String? vendorId,
    String? vendorName,
    bool? isPlatformWide,
    String? minimumTier,
    bool? isExclusive,
    List<String>? terms,
    String? redemptionInstructions,
    Map<String, dynamic>? metadata,
    bool? isActive,
    bool? isFeatured,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RewardProgram(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rewardType: rewardType ?? this.rewardType,
      category: category ?? this.category,
      pointsCost: pointsCost ?? this.pointsCost,
      monetaryValue: monetaryValue ?? this.monetaryValue,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      availability: availability ?? this.availability,
      totalStock: totalStock ?? this.totalStock,
      remainingStock: remainingStock ?? this.remainingStock,
      isUnlimited: isUnlimited ?? this.isUnlimited,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      usageLimit: usageLimit ?? this.usageLimit,
      usageLimitPerUser: usageLimitPerUser ?? this.usageLimitPerUser,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      isPlatformWide: isPlatformWide ?? this.isPlatformWide,
      minimumTier: minimumTier ?? this.minimumTier,
      isExclusive: isExclusive ?? this.isExclusive,
      terms: terms ?? this.terms,
      redemptionInstructions: redemptionInstructions ?? this.redemptionInstructions,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        rewardType,
        category,
        pointsCost,
        monetaryValue,
        discountPercentage,
        discountAmount,
        availability,
        totalStock,
        remainingStock,
        isUnlimited,
        validFrom,
        validUntil,
        usageLimit,
        usageLimitPerUser,
        vendorId,
        vendorName,
        isPlatformWide,
        minimumTier,
        isExclusive,
        terms,
        redemptionInstructions,
        metadata,
        isActive,
        isFeatured,
        sortOrder,
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

  /// Reward type display name
  String get typeDisplayName {
    switch (rewardType) {
      case RewardType.discount:
        return 'Discount';
      case RewardType.cashback:
        return 'Cashback';
      case RewardType.freeItem:
        return 'Free Item';
      case RewardType.pointsMultiplier:
        return 'Points Multiplier';
      case RewardType.tierUpgrade:
        return 'Tier Upgrade';
      case RewardType.freeDelivery:
        return 'Free Delivery';
      case RewardType.voucher:
        return 'Voucher';
    }
  }

  /// Category display name
  String get categoryDisplayName {
    switch (category) {
      case RewardCategory.food:
        return 'Food';
      case RewardCategory.delivery:
        return 'Delivery';
      case RewardCategory.general:
        return 'General';
      case RewardCategory.vendor:
        return 'Vendor';
      case RewardCategory.seasonal:
        return 'Seasonal';
      case RewardCategory.tier:
        return 'Tier';
    }
  }

  /// Check if reward is currently available
  bool get isCurrentlyAvailable {
    if (!isActive) return false;
    if (availability != RewardAvailability.available) return false;
    
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    
    if (!isUnlimited && (remainingStock == null || remainingStock! <= 0)) {
      return false;
    }
    
    return true;
  }

  /// Check if reward is expired
  bool get isExpired {
    if (validUntil == null) return false;
    return DateTime.now().isAfter(validUntil!);
  }

  /// Days until expiration
  int? get daysUntilExpiration {
    if (validUntil == null) return null;
    final now = DateTime.now();
    if (now.isAfter(validUntil!)) return 0;
    return validUntil!.difference(now).inDays;
  }

  /// Stock percentage remaining
  double? get stockPercentage {
    if (isUnlimited || totalStock == null || remainingStock == null) return null;
    if (totalStock == 0) return 0.0;
    return remainingStock! / totalStock!;
  }

  /// Check if stock is low (less than 20%)
  bool get isLowStock {
    final percentage = stockPercentage;
    return percentage != null && percentage < 0.2;
  }

  /// Discount display text
  String? get discountDisplayText {
    if (discountPercentage != null) {
      return '${discountPercentage!.toStringAsFixed(0)}% OFF';
    }
    if (discountAmount != null) {
      return 'RM ${discountAmount!.toStringAsFixed(2)} OFF';
    }
    return null;
  }

  /// Create test reward program for development
  factory RewardProgram.test({
    String? id,
    String? title,
    RewardType? type,
    int? pointsCost,
    bool? isAvailable,
  }) {
    final now = DateTime.now();
    final rewardType = type ?? RewardType.discount;
    
    return RewardProgram(
      id: id ?? 'test-reward-id',
      title: title ?? 'RM 5 OFF Your Next Order',
      description: 'Get RM 5 discount on your next food order. Valid for orders above RM 20.',
      imageUrl: 'https://example.com/reward-image.jpg',
      rewardType: rewardType,
      category: RewardCategory.food,
      pointsCost: pointsCost ?? 500,
      monetaryValue: 5.00,
      discountAmount: 5.00,
      availability: isAvailable == false 
          ? RewardAvailability.outOfStock 
          : RewardAvailability.available,
      totalStock: 100,
      remainingStock: isAvailable == false ? 0 : 75,
      isUnlimited: false,
      validFrom: now.subtract(const Duration(days: 1)),
      validUntil: now.add(const Duration(days: 30)),
      usageLimit: 1,
      usageLimitPerUser: 1,
      isPlatformWide: true,
      isExclusive: false,
      terms: [
        'Valid for orders above RM 20',
        'Cannot be combined with other offers',
        'Valid for 30 days from redemption',
      ],
      redemptionInstructions: 'Redeem this reward and apply the discount code at checkout.',
      isActive: true,
      isFeatured: true,
      sortOrder: 1,
      createdAt: now.subtract(const Duration(days: 7)),
      updatedAt: now,
    );
  }
}
