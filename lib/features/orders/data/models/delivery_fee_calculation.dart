import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'delivery_fee_calculation.g.dart';

/// Model for delivery fee calculation results
@JsonSerializable()
class DeliveryFeeCalculation extends Equatable {
  @JsonKey(name: 'final_fee')
  final double finalFee;
  
  @JsonKey(name: 'base_fee')
  final double baseFee;
  
  @JsonKey(name: 'distance_fee')
  final double distanceFee;
  
  @JsonKey(name: 'surge_multiplier')
  final double surgeMultiplier;
  
  @JsonKey(name: 'discount_amount')
  final double discountAmount;
  
  @JsonKey(name: 'distance_km')
  final double distanceKm;
  
  @JsonKey(name: 'config_id')
  final String? configId;
  
  final Map<String, dynamic> breakdown;

  const DeliveryFeeCalculation({
    required this.finalFee,
    required this.baseFee,
    required this.distanceFee,
    required this.surgeMultiplier,
    required this.discountAmount,
    required this.distanceKm,
    this.configId,
    required this.breakdown,
  });

  factory DeliveryFeeCalculation.fromJson(Map<String, dynamic> json) =>
      _$DeliveryFeeCalculationFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryFeeCalculationToJson(this);

  /// Create a zero-fee calculation for pickup methods
  factory DeliveryFeeCalculation.pickup(String method) {
    return DeliveryFeeCalculation(
      finalFee: 0.0,
      baseFee: 0.0,
      distanceFee: 0.0,
      surgeMultiplier: 1.0,
      discountAmount: 0.0,
      distanceKm: 0.0,
      breakdown: {
        'method': method,
        'reason': 'No delivery fee for pickup methods',
      },
    );
  }

  /// Create a calculation with error information
  factory DeliveryFeeCalculation.error(String errorMessage, {double fallbackFee = 10.0}) {
    return DeliveryFeeCalculation(
      finalFee: fallbackFee,
      baseFee: fallbackFee,
      distanceFee: 0.0,
      surgeMultiplier: 1.0,
      discountAmount: 0.0,
      distanceKm: 0.0,
      breakdown: {
        'error': errorMessage,
        'calculation_type': 'fallback',
      },
    );
  }

  /// Get the surge fee component
  double get surgeFee {
    final baseTotal = baseFee + distanceFee;
    final surgeAmount = baseTotal * (surgeMultiplier - 1.0);
    return surgeAmount.clamp(0.0, double.infinity);
  }

  /// Get the total fee before discounts
  double get totalBeforeDiscount {
    return baseFee + distanceFee + surgeFee;
  }

  /// Check if delivery is free
  bool get isFree => finalFee == 0.0;

  /// Check if surge pricing is applied
  bool get hasSurge => surgeMultiplier > 1.0;

  /// Check if discount is applied
  bool get hasDiscount => discountAmount > 0.0;

  /// Get formatted fee string
  String get formattedFee {
    if (isFree) return 'Free';
    return 'RM${finalFee.toStringAsFixed(2)}';
  }

  /// Get detailed breakdown for display
  Map<String, String> get displayBreakdown {
    final breakdown = <String, String>{};
    
    if (baseFee > 0) {
      breakdown['Base Fee'] = 'RM${baseFee.toStringAsFixed(2)}';
    }
    
    if (distanceFee > 0) {
      breakdown['Distance Fee'] = 'RM${distanceFee.toStringAsFixed(2)} (${distanceKm.toStringAsFixed(1)}km)';
    }
    
    if (hasSurge) {
      breakdown['Surge Fee'] = 'RM${surgeFee.toStringAsFixed(2)} (${((surgeMultiplier - 1) * 100).toStringAsFixed(0)}%)';
    }
    
    if (hasDiscount) {
      breakdown['Discount'] = '-RM${discountAmount.toStringAsFixed(2)}';
    }
    
    breakdown['Total'] = formattedFee;
    
    return breakdown;
  }

  /// Copy with method for creating modified instances
  DeliveryFeeCalculation copyWith({
    double? finalFee,
    double? baseFee,
    double? distanceFee,
    double? surgeMultiplier,
    double? discountAmount,
    double? distanceKm,
    String? configId,
    Map<String, dynamic>? breakdown,
  }) {
    return DeliveryFeeCalculation(
      finalFee: finalFee ?? this.finalFee,
      baseFee: baseFee ?? this.baseFee,
      distanceFee: distanceFee ?? this.distanceFee,
      surgeMultiplier: surgeMultiplier ?? this.surgeMultiplier,
      discountAmount: discountAmount ?? this.discountAmount,
      distanceKm: distanceKm ?? this.distanceKm,
      configId: configId ?? this.configId,
      breakdown: breakdown ?? this.breakdown,
    );
  }

  @override
  List<Object?> get props => [
        finalFee,
        baseFee,
        distanceFee,
        surgeMultiplier,
        discountAmount,
        distanceKm,
        configId,
        breakdown,
      ];

  @override
  String toString() {
    return 'DeliveryFeeCalculation(finalFee: $finalFee, baseFee: $baseFee, distanceFee: $distanceFee, surgeMultiplier: $surgeMultiplier, discountAmount: $discountAmount, distanceKm: $distanceKm)';
  }
}

/// Model for delivery zone information
@JsonSerializable()
class DeliveryZone extends Equatable {
  final String id;
  final String name;
  final String? description;
  @JsonKey(name: 'polygon_coordinates')
  final Map<String, dynamic> polygonCoordinates;
  @JsonKey(name: 'base_delivery_fee')
  final double baseDeliveryFee;
  @JsonKey(name: 'per_km_rate')
  final double perKmRate;
  @JsonKey(name: 'minimum_fee')
  final double minimumFee;
  @JsonKey(name: 'maximum_fee')
  final double? maximumFee;
  @JsonKey(name: 'free_delivery_threshold')
  final double freeDeliveryThreshold;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const DeliveryZone({
    required this.id,
    required this.name,
    this.description,
    required this.polygonCoordinates,
    required this.baseDeliveryFee,
    required this.perKmRate,
    required this.minimumFee,
    this.maximumFee,
    required this.freeDeliveryThreshold,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryZone.fromJson(Map<String, dynamic> json) =>
      _$DeliveryZoneFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryZoneToJson(this);

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        polygonCoordinates,
        baseDeliveryFee,
        perKmRate,
        minimumFee,
        maximumFee,
        freeDeliveryThreshold,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Model for delivery fee configuration
@JsonSerializable()
class DeliveryFeeConfig extends Equatable {
  final String id;
  @JsonKey(name: 'delivery_method')
  final String deliveryMethod;
  @JsonKey(name: 'zone_id')
  final String? zoneId;
  @JsonKey(name: 'vendor_id')
  final String? vendorId;
  @JsonKey(name: 'base_fee')
  final double baseFee;
  @JsonKey(name: 'per_km_rate')
  final double perKmRate;
  @JsonKey(name: 'minimum_fee')
  final double minimumFee;
  @JsonKey(name: 'maximum_fee')
  final double? maximumFee;
  @JsonKey(name: 'distance_tiers')
  final List<Map<String, dynamic>> distanceTiers;
  @JsonKey(name: 'free_delivery_threshold')
  final double freeDeliveryThreshold;
  @JsonKey(name: 'discount_tiers')
  final List<Map<String, dynamic>> discountTiers;
  @JsonKey(name: 'surge_multipliers')
  final Map<String, dynamic> surgeMultipliers;
  @JsonKey(name: 'peak_hours')
  final List<Map<String, dynamic>> peakHours;
  @JsonKey(name: 'maximum_delivery_radius_km')
  final double maximumDeliveryRadiusKm;
  @JsonKey(name: 'estimated_delivery_time_minutes')
  final int estimatedDeliveryTimeMinutes;
  @JsonKey(name: 'is_active')
  final bool isActive;
  final int priority;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const DeliveryFeeConfig({
    required this.id,
    required this.deliveryMethod,
    this.zoneId,
    this.vendorId,
    required this.baseFee,
    required this.perKmRate,
    required this.minimumFee,
    this.maximumFee,
    required this.distanceTiers,
    required this.freeDeliveryThreshold,
    required this.discountTiers,
    required this.surgeMultipliers,
    required this.peakHours,
    required this.maximumDeliveryRadiusKm,
    required this.estimatedDeliveryTimeMinutes,
    required this.isActive,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryFeeConfig.fromJson(Map<String, dynamic> json) =>
      _$DeliveryFeeConfigFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryFeeConfigToJson(this);

  @override
  List<Object?> get props => [
        id,
        deliveryMethod,
        zoneId,
        vendorId,
        baseFee,
        perKmRate,
        minimumFee,
        maximumFee,
        distanceTiers,
        freeDeliveryThreshold,
        discountTiers,
        surgeMultipliers,
        peakHours,
        maximumDeliveryRadiusKm,
        estimatedDeliveryTimeMinutes,
        isActive,
        priority,
        createdAt,
        updatedAt,
      ];
}
