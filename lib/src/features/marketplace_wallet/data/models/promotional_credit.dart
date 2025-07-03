import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'promotional_credit.g.dart';

/// Promotional credit types
enum PromotionalCreditType {
  welcomeBonus,
  seasonalPromo,
  vendorPromo,
  loyaltyBonus,
  referralBonus,
  compensationCredit,
  birthdayBonus,
  anniversaryBonus,
}

/// Promotional credit status
enum PromotionalCreditStatus {
  active,
  used,
  expired,
  cancelled,
  pending,
}

/// Promotional credit model
@JsonSerializable()
class PromotionalCredit extends Equatable {
  final String id;
  final String userId;
  final String walletId;
  final String? loyaltyAccountId;
  
  // Credit details
  final String title;
  final String description;
  final PromotionalCreditType creditType;
  final double amount;
  final String currency;
  
  // Status and usage
  final PromotionalCreditStatus status;
  final double usedAmount;
  final double remainingAmount;
  final bool isFullyUsed;
  
  // Validity
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isExpired;
  
  // Usage restrictions
  final double? minimumOrderAmount;
  final double? maximumDiscountAmount;
  final List<String>? applicableVendorIds;
  final List<String>? applicableCategories;
  final bool isVendorSpecific;
  final bool isCategorySpecific;
  
  // Campaign details
  final String? campaignId;
  final String? campaignName;
  final String? promoCode;
  final String? sourceReference;
  
  // Usage tracking
  final List<String> usedOrderIds;
  final int usageCount;
  final int? maxUsageCount;
  final DateTime? firstUsedAt;
  final DateTime? lastUsedAt;
  
  // Metadata
  final Map<String, dynamic>? metadata;
  final String? terms;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PromotionalCredit({
    required this.id,
    required this.userId,
    required this.walletId,
    this.loyaltyAccountId,
    required this.title,
    required this.description,
    required this.creditType,
    required this.amount,
    required this.currency,
    required this.status,
    required this.usedAmount,
    required this.remainingAmount,
    required this.isFullyUsed,
    required this.validFrom,
    required this.validUntil,
    required this.isExpired,
    this.minimumOrderAmount,
    this.maximumDiscountAmount,
    this.applicableVendorIds,
    this.applicableCategories,
    required this.isVendorSpecific,
    required this.isCategorySpecific,
    this.campaignId,
    this.campaignName,
    this.promoCode,
    this.sourceReference,
    required this.usedOrderIds,
    required this.usageCount,
    this.maxUsageCount,
    this.firstUsedAt,
    this.lastUsedAt,
    this.metadata,
    this.terms,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PromotionalCredit.fromJson(Map<String, dynamic> json) =>
      _$PromotionalCreditFromJson(json);

  Map<String, dynamic> toJson() => _$PromotionalCreditToJson(this);

  PromotionalCredit copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? loyaltyAccountId,
    String? title,
    String? description,
    PromotionalCreditType? creditType,
    double? amount,
    String? currency,
    PromotionalCreditStatus? status,
    double? usedAmount,
    double? remainingAmount,
    bool? isFullyUsed,
    DateTime? validFrom,
    DateTime? validUntil,
    bool? isExpired,
    double? minimumOrderAmount,
    double? maximumDiscountAmount,
    List<String>? applicableVendorIds,
    List<String>? applicableCategories,
    bool? isVendorSpecific,
    bool? isCategorySpecific,
    String? campaignId,
    String? campaignName,
    String? promoCode,
    String? sourceReference,
    List<String>? usedOrderIds,
    int? usageCount,
    int? maxUsageCount,
    DateTime? firstUsedAt,
    DateTime? lastUsedAt,
    Map<String, dynamic>? metadata,
    String? terms,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromotionalCredit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      loyaltyAccountId: loyaltyAccountId ?? this.loyaltyAccountId,
      title: title ?? this.title,
      description: description ?? this.description,
      creditType: creditType ?? this.creditType,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      usedAmount: usedAmount ?? this.usedAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      isFullyUsed: isFullyUsed ?? this.isFullyUsed,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      isExpired: isExpired ?? this.isExpired,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      maximumDiscountAmount: maximumDiscountAmount ?? this.maximumDiscountAmount,
      applicableVendorIds: applicableVendorIds ?? this.applicableVendorIds,
      applicableCategories: applicableCategories ?? this.applicableCategories,
      isVendorSpecific: isVendorSpecific ?? this.isVendorSpecific,
      isCategorySpecific: isCategorySpecific ?? this.isCategorySpecific,
      campaignId: campaignId ?? this.campaignId,
      campaignName: campaignName ?? this.campaignName,
      promoCode: promoCode ?? this.promoCode,
      sourceReference: sourceReference ?? this.sourceReference,
      usedOrderIds: usedOrderIds ?? this.usedOrderIds,
      usageCount: usageCount ?? this.usageCount,
      maxUsageCount: maxUsageCount ?? this.maxUsageCount,
      firstUsedAt: firstUsedAt ?? this.firstUsedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      metadata: metadata ?? this.metadata,
      terms: terms ?? this.terms,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        walletId,
        loyaltyAccountId,
        title,
        description,
        creditType,
        amount,
        currency,
        status,
        usedAmount,
        remainingAmount,
        isFullyUsed,
        validFrom,
        validUntil,
        isExpired,
        minimumOrderAmount,
        maximumDiscountAmount,
        applicableVendorIds,
        applicableCategories,
        isVendorSpecific,
        isCategorySpecific,
        campaignId,
        campaignName,
        promoCode,
        sourceReference,
        usedOrderIds,
        usageCount,
        maxUsageCount,
        firstUsedAt,
        lastUsedAt,
        metadata,
        terms,
        notes,
        createdAt,
        updatedAt,
      ];

  /// Formatted amount display
  String get formattedAmount => 'RM ${amount.toStringAsFixed(2)}';
  String get formattedUsedAmount => 'RM ${usedAmount.toStringAsFixed(2)}';
  String get formattedRemainingAmount => 'RM ${remainingAmount.toStringAsFixed(2)}';

  /// Credit type display name
  String get typeDisplayName {
    switch (creditType) {
      case PromotionalCreditType.welcomeBonus:
        return 'Welcome Bonus';
      case PromotionalCreditType.seasonalPromo:
        return 'Seasonal Promotion';
      case PromotionalCreditType.vendorPromo:
        return 'Vendor Promotion';
      case PromotionalCreditType.loyaltyBonus:
        return 'Loyalty Bonus';
      case PromotionalCreditType.referralBonus:
        return 'Referral Bonus';
      case PromotionalCreditType.compensationCredit:
        return 'Compensation Credit';
      case PromotionalCreditType.birthdayBonus:
        return 'Birthday Bonus';
      case PromotionalCreditType.anniversaryBonus:
        return 'Anniversary Bonus';
    }
  }

  /// Status display name
  String get statusDisplayName {
    switch (status) {
      case PromotionalCreditStatus.active:
        return 'Active';
      case PromotionalCreditStatus.used:
        return 'Used';
      case PromotionalCreditStatus.expired:
        return 'Expired';
      case PromotionalCreditStatus.cancelled:
        return 'Cancelled';
      case PromotionalCreditStatus.pending:
        return 'Pending';
    }
  }

  /// Check if credit is currently usable
  bool get isUsable {
    return status == PromotionalCreditStatus.active &&
           !isExpired &&
           !isFullyUsed &&
           DateTime.now().isAfter(validFrom) &&
           DateTime.now().isBefore(validUntil);
  }

  /// Usage percentage
  double get usagePercentage {
    if (amount == 0) return 0.0;
    return usedAmount / amount;
  }

  /// Days until expiration
  int get daysUntilExpiration {
    final now = DateTime.now();
    if (now.isAfter(validUntil)) return 0;
    return validUntil.difference(now).inDays;
  }

  /// Formatted expiration display
  String get formattedExpiration {
    final days = daysUntilExpiration;
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    if (days <= 7) return 'Expires in $days days';
    return 'Expires ${validUntil.day}/${validUntil.month}/${validUntil.year}';
  }

  /// Check if credit can be used for a specific order
  bool canBeUsedForOrder({
    required double orderAmount,
    String? vendorId,
    List<String>? categories,
  }) {
    if (!isUsable) return false;
    
    // Check minimum order amount
    if (minimumOrderAmount != null && orderAmount < minimumOrderAmount!) {
      return false;
    }
    
    // Check vendor restrictions
    if (isVendorSpecific && applicableVendorIds != null && vendorId != null) {
      if (!applicableVendorIds!.contains(vendorId)) return false;
    }
    
    // Check category restrictions
    if (isCategorySpecific && applicableCategories != null && categories != null) {
      final hasMatchingCategory = categories.any(
        (category) => applicableCategories!.contains(category),
      );
      if (!hasMatchingCategory) return false;
    }
    
    // Check usage limits
    if (maxUsageCount != null && usageCount >= maxUsageCount!) {
      return false;
    }
    
    return true;
  }

  /// Calculate applicable discount amount for an order
  double calculateDiscountAmount(double orderAmount) {
    if (!canBeUsedForOrder(orderAmount: orderAmount)) return 0.0;
    
    double discountAmount = remainingAmount;
    
    // Apply maximum discount limit if specified
    if (maximumDiscountAmount != null) {
      discountAmount = discountAmount > maximumDiscountAmount! 
          ? maximumDiscountAmount! 
          : discountAmount;
    }
    
    // Discount cannot exceed order amount
    return discountAmount > orderAmount ? orderAmount : discountAmount;
  }

  /// Create test promotional credit for development
  factory PromotionalCredit.test({
    String? id,
    String? title,
    PromotionalCreditType? type,
    double? amount,
    PromotionalCreditStatus? status,
  }) {
    final now = DateTime.now();
    final creditType = type ?? PromotionalCreditType.welcomeBonus;
    final creditAmount = amount ?? 15.00;
    final creditStatus = status ?? PromotionalCreditStatus.active;
    
    return PromotionalCredit(
      id: id ?? 'test-promo-credit-id',
      userId: 'test-user-id',
      walletId: 'test-wallet-id',
      loyaltyAccountId: 'test-loyalty-account-id',
      title: title ?? 'Welcome Bonus',
      description: 'Welcome to GigaEats! Enjoy RM 15 off your first order.',
      creditType: creditType,
      amount: creditAmount,
      currency: 'MYR',
      status: creditStatus,
      usedAmount: creditStatus == PromotionalCreditStatus.used ? creditAmount : 0.0,
      remainingAmount: creditStatus == PromotionalCreditStatus.used ? 0.0 : creditAmount,
      isFullyUsed: creditStatus == PromotionalCreditStatus.used,
      validFrom: now.subtract(const Duration(days: 1)),
      validUntil: now.add(const Duration(days: 30)),
      isExpired: false,
      minimumOrderAmount: 25.00,
      maximumDiscountAmount: creditAmount,
      isVendorSpecific: false,
      isCategorySpecific: false,
      campaignId: 'welcome-2024',
      campaignName: 'Welcome Campaign 2024',
      promoCode: 'WELCOME15',
      sourceReference: 'user_signup',
      usedOrderIds: creditStatus == PromotionalCreditStatus.used 
          ? ['test-order-id'] 
          : [],
      usageCount: creditStatus == PromotionalCreditStatus.used ? 1 : 0,
      maxUsageCount: 1,
      firstUsedAt: creditStatus == PromotionalCreditStatus.used 
          ? now.subtract(const Duration(hours: 2))
          : null,
      lastUsedAt: creditStatus == PromotionalCreditStatus.used 
          ? now.subtract(const Duration(hours: 2))
          : null,
      metadata: {
        'campaign_type': 'welcome',
        'auto_applied': true,
        'source': 'user_signup',
      },
      terms: 'Valid for 30 days. Minimum order RM 25. Cannot be combined with other offers.',
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    );
  }
}
