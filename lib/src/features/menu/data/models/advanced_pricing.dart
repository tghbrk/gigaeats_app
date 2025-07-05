import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'advanced_pricing.g.dart';

/// Enhanced bulk pricing tier with additional features
@JsonSerializable()
class EnhancedBulkPricingTier extends Equatable {
  final String? id;
  final int minimumQuantity;
  final int? maximumQuantity;
  final double pricePerUnit;
  final double? discountPercentage;
  final String? description;
  final bool isActive;
  final DateTime? validFrom;
  final DateTime? validUntil;

  const EnhancedBulkPricingTier({
    this.id,
    required this.minimumQuantity,
    this.maximumQuantity,
    required this.pricePerUnit,
    this.discountPercentage,
    this.description,
    this.isActive = true,
    this.validFrom,
    this.validUntil,
  });

  factory EnhancedBulkPricingTier.fromJson(Map<String, dynamic> json) => 
      _$EnhancedBulkPricingTierFromJson(json);
  Map<String, dynamic> toJson() => _$EnhancedBulkPricingTierToJson(this);

  @override
  List<Object?> get props => [
    id, minimumQuantity, maximumQuantity, pricePerUnit, 
    discountPercentage, description, isActive, validFrom, validUntil
  ];

  EnhancedBulkPricingTier copyWith({
    String? id,
    int? minimumQuantity,
    int? maximumQuantity,
    double? pricePerUnit,
    double? discountPercentage,
    String? description,
    bool? isActive,
    DateTime? validFrom,
    DateTime? validUntil,
  }) {
    return EnhancedBulkPricingTier(
      id: id ?? this.id,
      minimumQuantity: minimumQuantity ?? this.minimumQuantity,
      maximumQuantity: maximumQuantity ?? this.maximumQuantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
    );
  }

  /// Check if this tier is currently valid
  bool get isCurrentlyValid {
    if (!isActive) return false;
    
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return false;
    if (validUntil != null && now.isAfter(validUntil!)) return false;
    
    return true;
  }

  /// Check if quantity falls within this tier's range
  bool isApplicableForQuantity(int quantity) {
    if (quantity < minimumQuantity) return false;
    if (maximumQuantity != null && quantity > maximumQuantity!) return false;
    return true;
  }
}

/// Promotional pricing configuration
@JsonSerializable()
class PromotionalPricing extends Equatable {
  final String? id;
  final String name;
  final String description;
  final PromotionalPricingType type;
  final double value; // Percentage or fixed amount
  final double? minimumOrderAmount;
  final int? minimumQuantity;
  final DateTime validFrom;
  final DateTime validUntil;
  final List<String> applicableDays; // ['monday', 'tuesday', etc.]
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final bool isActive;
  final int? usageLimit;
  final int currentUsage;

  const PromotionalPricing({
    this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    this.minimumOrderAmount,
    this.minimumQuantity,
    required this.validFrom,
    required this.validUntil,
    this.applicableDays = const [],
    this.startTime,
    this.endTime,
    this.isActive = true,
    this.usageLimit,
    this.currentUsage = 0,
  });

  factory PromotionalPricing.fromJson(Map<String, dynamic> json) => 
      _$PromotionalPricingFromJson(json);
  Map<String, dynamic> toJson() => _$PromotionalPricingToJson(this);

  @override
  List<Object?> get props => [
    id, name, description, type, value, minimumOrderAmount, minimumQuantity,
    validFrom, validUntil, applicableDays, startTime, endTime, isActive,
    usageLimit, currentUsage
  ];

  PromotionalPricing copyWith({
    String? id,
    String? name,
    String? description,
    PromotionalPricingType? type,
    double? value,
    double? minimumOrderAmount,
    int? minimumQuantity,
    DateTime? validFrom,
    DateTime? validUntil,
    List<String>? applicableDays,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isActive,
    int? usageLimit,
    int? currentUsage,
  }) {
    return PromotionalPricing(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      minimumQuantity: minimumQuantity ?? this.minimumQuantity,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      applicableDays: applicableDays ?? this.applicableDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      usageLimit: usageLimit ?? this.usageLimit,
      currentUsage: currentUsage ?? this.currentUsage,
    );
  }

  /// Check if promotion is currently valid
  bool get isCurrentlyValid {
    if (!isActive) return false;
    
    final now = DateTime.now();
    if (now.isBefore(validFrom) || now.isAfter(validUntil)) return false;
    
    // Check usage limit
    if (usageLimit != null && currentUsage >= usageLimit!) return false;
    
    // Check day of week
    if (applicableDays.isNotEmpty) {
      final currentDay = _getDayName(now.weekday);
      if (!applicableDays.contains(currentDay)) return false;
    }
    
    // Check time of day
    if (startTime != null && endTime != null) {
      final currentTime = TimeOfDay.fromDateTime(now);
      if (!_isTimeInRange(currentTime, startTime!, endTime!)) return false;
    }
    
    return true;
  }

  /// Calculate discount amount for given order details
  double calculateDiscount({
    required double orderAmount,
    required int quantity,
  }) {
    if (!isCurrentlyValid) return 0.0;
    
    // Check minimum requirements
    if (minimumOrderAmount != null && orderAmount < minimumOrderAmount!) return 0.0;
    if (minimumQuantity != null && quantity < minimumQuantity!) return 0.0;
    
    switch (type) {
      case PromotionalPricingType.percentage:
        return orderAmount * (value / 100);
      case PromotionalPricingType.fixedAmount:
        return value;
      case PromotionalPricingType.buyXGetY:
        // For buy X get Y, value represents the free quantity ratio
        final freeItems = (quantity / (value + 1)).floor();
        return freeItems * (orderAmount / quantity);
    }
  }

  String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }

  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Crosses midnight
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
}

/// Time-based pricing rule
@JsonSerializable()
class TimeBasedPricingRule extends Equatable {
  final String? id;
  final String name;
  final String description;
  final TimePricingType type;
  final double multiplier; // Price multiplier (e.g., 1.2 for 20% increase)
  final List<String> applicableDays;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isActive;
  final int priority; // Higher priority rules override lower ones

  const TimeBasedPricingRule({
    this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.multiplier,
    this.applicableDays = const [],
    required this.startTime,
    required this.endTime,
    this.isActive = true,
    this.priority = 0,
  });

  factory TimeBasedPricingRule.fromJson(Map<String, dynamic> json) => 
      _$TimeBasedPricingRuleFromJson(json);
  Map<String, dynamic> toJson() => _$TimeBasedPricingRuleToJson(this);

  @override
  List<Object?> get props => [
    id, name, description, type, multiplier, applicableDays,
    startTime, endTime, isActive, priority
  ];

  TimeBasedPricingRule copyWith({
    String? id,
    String? name,
    String? description,
    TimePricingType? type,
    double? multiplier,
    List<String>? applicableDays,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isActive,
    int? priority,
  }) {
    return TimeBasedPricingRule(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      multiplier: multiplier ?? this.multiplier,
      applicableDays: applicableDays ?? this.applicableDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
    );
  }

  /// Check if rule is currently applicable
  bool get isCurrentlyApplicable {
    if (!isActive) return false;
    
    final now = DateTime.now();
    
    // Check day of week
    if (applicableDays.isNotEmpty) {
      final currentDay = _getDayName(now.weekday);
      if (!applicableDays.contains(currentDay)) return false;
    }
    
    // Check time of day
    final currentTime = TimeOfDay.fromDateTime(now);
    return _isTimeInRange(currentTime, startTime, endTime);
  }

  String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }

  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Crosses midnight
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }
}

/// Advanced pricing configuration for menu items
@JsonSerializable()
class AdvancedPricingConfig extends Equatable {
  final String menuItemId;
  final double basePrice;
  final List<EnhancedBulkPricingTier> bulkPricingTiers;
  final List<PromotionalPricing> promotionalPricing;
  final List<TimeBasedPricingRule> timeBasedRules;
  final bool enableDynamicPricing;
  final double? minimumPrice;
  final double? maximumPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdvancedPricingConfig({
    required this.menuItemId,
    required this.basePrice,
    this.bulkPricingTiers = const [],
    this.promotionalPricing = const [],
    this.timeBasedRules = const [],
    this.enableDynamicPricing = false,
    this.minimumPrice,
    this.maximumPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdvancedPricingConfig.fromJson(Map<String, dynamic> json) => 
      _$AdvancedPricingConfigFromJson(json);
  Map<String, dynamic> toJson() => _$AdvancedPricingConfigToJson(this);

  @override
  List<Object?> get props => [
    menuItemId, basePrice, bulkPricingTiers, promotionalPricing,
    timeBasedRules, enableDynamicPricing, minimumPrice, maximumPrice,
    createdAt, updatedAt
  ];

  /// Calculate effective price for given quantity and context
  PricingCalculationResult calculateEffectivePrice({
    required int quantity,
    DateTime? orderTime,
  }) {
    orderTime ??= DateTime.now();
    
    double effectivePrice = basePrice;
    final appliedRules = <String>[];
    double totalDiscount = 0.0;
    
    // Apply bulk pricing
    final applicableBulkTier = _findApplicableBulkTier(quantity);
    if (applicableBulkTier != null) {
      effectivePrice = applicableBulkTier.pricePerUnit;
      appliedRules.add('Bulk pricing: ${applicableBulkTier.description ?? 'Tier ${applicableBulkTier.minimumQuantity}+'}');
    }
    
    // Apply time-based pricing
    final applicableTimeRule = _findApplicableTimeRule(orderTime);
    if (applicableTimeRule != null) {
      effectivePrice *= applicableTimeRule.multiplier;
      appliedRules.add('Time-based: ${applicableTimeRule.name}');
    }
    
    // Apply promotional pricing
    final applicablePromotion = _findApplicablePromotion(quantity, effectivePrice * quantity);
    if (applicablePromotion != null) {
      final discount = applicablePromotion.calculateDiscount(
        orderAmount: effectivePrice * quantity,
        quantity: quantity,
      );
      totalDiscount = discount;
      appliedRules.add('Promotion: ${applicablePromotion.name}');
    }
    
    // Apply price limits
    if (minimumPrice != null && effectivePrice < minimumPrice!) {
      effectivePrice = minimumPrice!;
      appliedRules.add('Minimum price applied');
    }
    if (maximumPrice != null && effectivePrice > maximumPrice!) {
      effectivePrice = maximumPrice!;
      appliedRules.add('Maximum price applied');
    }
    
    return PricingCalculationResult(
      basePrice: basePrice,
      effectivePrice: effectivePrice,
      totalPrice: (effectivePrice * quantity) - totalDiscount,
      quantity: quantity,
      appliedRules: appliedRules,
      totalDiscount: totalDiscount,
      appliedBulkTier: applicableBulkTier,
      appliedPromotion: applicablePromotion,
      appliedTimeRule: applicableTimeRule,
    );
  }

  EnhancedBulkPricingTier? _findApplicableBulkTier(int quantity) {
    final validTiers = bulkPricingTiers
        .where((tier) => tier.isCurrentlyValid && tier.isApplicableForQuantity(quantity))
        .toList();
    
    if (validTiers.isEmpty) return null;
    
    // Return the tier with the highest minimum quantity (most specific)
    validTiers.sort((a, b) => b.minimumQuantity.compareTo(a.minimumQuantity));
    return validTiers.first;
  }

  TimeBasedPricingRule? _findApplicableTimeRule(DateTime orderTime) {
    final validRules = timeBasedRules
        .where((rule) => rule.isCurrentlyApplicable)
        .toList();
    
    if (validRules.isEmpty) return null;
    
    // Return the rule with the highest priority
    validRules.sort((a, b) => b.priority.compareTo(a.priority));
    return validRules.first;
  }

  PromotionalPricing? _findApplicablePromotion(int quantity, double orderAmount) {
    final validPromotions = promotionalPricing
        .where((promo) => promo.isCurrentlyValid)
        .toList();
    
    if (validPromotions.isEmpty) return null;
    
    // Find the promotion with the highest discount
    PromotionalPricing? bestPromotion;
    double bestDiscount = 0.0;
    
    for (final promotion in validPromotions) {
      final discount = promotion.calculateDiscount(
        orderAmount: orderAmount,
        quantity: quantity,
      );
      if (discount > bestDiscount) {
        bestDiscount = discount;
        bestPromotion = promotion;
      }
    }
    
    return bestPromotion;
  }

  /// Create a copy of this configuration with updated values
  AdvancedPricingConfig copyWith({
    String? menuItemId,
    double? basePrice,
    List<EnhancedBulkPricingTier>? bulkPricingTiers,
    List<PromotionalPricing>? promotionalPricing,
    List<TimeBasedPricingRule>? timeBasedRules,
    bool? enableDynamicPricing,
    double? minimumPrice,
    double? maximumPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdvancedPricingConfig(
      menuItemId: menuItemId ?? this.menuItemId,
      basePrice: basePrice ?? this.basePrice,
      bulkPricingTiers: bulkPricingTiers ?? this.bulkPricingTiers,
      promotionalPricing: promotionalPricing ?? this.promotionalPricing,
      timeBasedRules: timeBasedRules ?? this.timeBasedRules,
      enableDynamicPricing: enableDynamicPricing ?? this.enableDynamicPricing,
      minimumPrice: minimumPrice ?? this.minimumPrice,
      maximumPrice: maximumPrice ?? this.maximumPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Result of pricing calculation
@JsonSerializable()
class PricingCalculationResult extends Equatable {
  final double basePrice;
  final double effectivePrice;
  final double totalPrice;
  final int quantity;
  final List<String> appliedRules;
  final double totalDiscount;
  final EnhancedBulkPricingTier? appliedBulkTier;
  final PromotionalPricing? appliedPromotion;
  final TimeBasedPricingRule? appliedTimeRule;

  const PricingCalculationResult({
    required this.basePrice,
    required this.effectivePrice,
    required this.totalPrice,
    required this.quantity,
    required this.appliedRules,
    required this.totalDiscount,
    this.appliedBulkTier,
    this.appliedPromotion,
    this.appliedTimeRule,
  });

  factory PricingCalculationResult.fromJson(Map<String, dynamic> json) => 
      _$PricingCalculationResultFromJson(json);
  Map<String, dynamic> toJson() => _$PricingCalculationResultToJson(this);

  @override
  List<Object?> get props => [
    basePrice, effectivePrice, totalPrice, quantity, appliedRules,
    totalDiscount, appliedBulkTier, appliedPromotion, appliedTimeRule
  ];

  /// Calculate savings compared to base price
  double get totalSavings => (basePrice * quantity) - totalPrice;

  /// Calculate savings percentage
  double get savingsPercentage {
    final baseTotalPrice = basePrice * quantity;
    if (baseTotalPrice == 0) return 0.0;
    return (totalSavings / baseTotalPrice) * 100;
  }
}

/// Enums for pricing types
enum PromotionalPricingType {
  percentage,
  fixedAmount,
  buyXGetY,
}

enum TimePricingType {
  peakHours,
  offPeakHours,
  happyHour,
  lunchSpecial,
  dinnerSpecial,
  weekendSurcharge,
}

/// Custom TimeOfDay class for JSON serialization
@JsonSerializable()
class TimeOfDay extends Equatable {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  factory TimeOfDay.fromJson(Map<String, dynamic> json) => _$TimeOfDayFromJson(json);
  Map<String, dynamic> toJson() => _$TimeOfDayToJson(this);

  @override
  List<Object?> get props => [hour, minute];

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
