import 'package:equatable/equatable.dart';

/// Enum for different types of earnings
enum EarningsType {
  deliveryFee('delivery_fee'),
  tip('tip'),
  bonus('bonus'),
  commission('commission'),
  penalty('penalty');

  const EarningsType(this.value);
  final String value;

  static EarningsType fromString(String value) {
    return EarningsType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => EarningsType.deliveryFee,
    );
  }
}

/// Enum for earnings status
enum EarningsStatus {
  pending('pending'),
  confirmed('confirmed'),
  paid('paid'),
  disputed('disputed'),
  cancelled('cancelled');

  const EarningsStatus(this.value);
  final String value;

  static EarningsStatus fromString(String value) {
    return EarningsStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => EarningsStatus.pending,
    );
  }
}

/// Individual driver earnings record
class DriverEarnings extends Equatable {
  final String id;
  final String driverId;
  final String? orderId;
  final EarningsType earningsType;
  final double amount;
  final double baseAmount;
  final double tipAmount;
  final double bonusAmount;
  final double commissionRate;
  final double platformFee;
  final double netAmount;
  final EarningsStatus status;
  final DateTime? paymentDate;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DriverEarnings({
    required this.id,
    required this.driverId,
    this.orderId,
    required this.earningsType,
    required this.amount,
    this.baseAmount = 0.0,
    this.tipAmount = 0.0,
    this.bonusAmount = 0.0,
    this.commissionRate = 0.0,
    this.platformFee = 0.0,
    required this.netAmount,
    this.status = EarningsStatus.pending,
    this.paymentDate,
    this.description,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverEarnings.fromJson(Map<String, dynamic> json) {
    return DriverEarnings(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      orderId: json['order_id'] as String?,
      earningsType: EarningsType.fromString(json['earnings_type'] as String? ?? 'delivery_fee'),
      amount: (json['amount'] as num?)?.toDouble() ?? (json['gross_earnings'] as num?)?.toDouble() ?? 0.0,
      baseAmount: (json['base_commission'] as num?)?.toDouble() ?? 0.0,
      tipAmount: (json['other_bonuses'] as num?)?.toDouble() ?? 0.0, // Map to available field
      bonusAmount: (json['completion_bonus'] as num?)?.toDouble() ??
                   (json['peak_hour_bonus'] as num?)?.toDouble() ??
                   (json['rating_bonus'] as num?)?.toDouble() ?? 0.0,
      commissionRate: 0.0, // Not directly available in current schema
      platformFee: (json['deductions'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['net_earnings'] as num?)?.toDouble() ?? 0.0,
      status: EarningsStatus.fromString(json['payment_status'] as String? ?? 'pending'),
      paymentDate: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      description: json['notes'] as String?,
      metadata: null, // Not available in current schema
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'order_id': orderId,
      'earnings_type': earningsType.value,
      'amount': amount,
      'gross_earnings': amount, // Map to actual database column
      'base_commission': baseAmount,
      'other_bonuses': tipAmount, // Map to available field
      'completion_bonus': bonusAmount,
      'deductions': platformFee,
      'net_earnings': netAmount,
      'payment_status': status.value,
      'paid_at': paymentDate?.toIso8601String(),
      'notes': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        driverId,
        orderId,
        earningsType,
        amount,
        baseAmount,
        tipAmount,
        bonusAmount,
        commissionRate,
        platformFee,
        netAmount,
        status,
        paymentDate,
        description,
        metadata,
        createdAt,
        updatedAt,
      ];
}

/// Driver commission structure
class DriverCommissionStructure extends Equatable {
  final String id;
  final String driverId;
  final String vendorId;
  final double baseCommissionRate;
  final double performanceBonusRate;
  final double minimumDeliveryFee;
  final double maximumDeliveryFee;
  final double platformFeeRate;
  final DateTime effectiveFrom;
  final DateTime? effectiveUntil;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DriverCommissionStructure({
    required this.id,
    required this.driverId,
    required this.vendorId,
    this.baseCommissionRate = 15.0,
    this.performanceBonusRate = 0.0,
    this.minimumDeliveryFee = 5.0,
    this.maximumDeliveryFee = 50.0,
    this.platformFeeRate = 5.0,
    required this.effectiveFrom,
    this.effectiveUntil,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverCommissionStructure.fromJson(Map<String, dynamic> json) {
    return DriverCommissionStructure(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      vendorId: json['vendor_id'] as String,
      baseCommissionRate: (json['base_commission_rate'] as num).toDouble(),
      performanceBonusRate: (json['performance_bonus_rate'] as num?)?.toDouble() ?? 0.0,
      minimumDeliveryFee: (json['minimum_delivery_fee'] as num).toDouble(),
      maximumDeliveryFee: (json['maximum_delivery_fee'] as num).toDouble(),
      platformFeeRate: (json['platform_fee_rate'] as num).toDouble(),
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      effectiveUntil: json['effective_until'] != null 
          ? DateTime.parse(json['effective_until'] as String)
          : null,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'vendor_id': vendorId,
      'base_commission_rate': baseCommissionRate,
      'performance_bonus_rate': performanceBonusRate,
      'minimum_delivery_fee': minimumDeliveryFee,
      'maximum_delivery_fee': maximumDeliveryFee,
      'platform_fee_rate': platformFeeRate,
      'effective_from': effectiveFrom.toIso8601String().split('T')[0],
      'effective_until': effectiveUntil?.toIso8601String().split('T')[0],
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        driverId,
        vendorId,
        baseCommissionRate,
        performanceBonusRate,
        minimumDeliveryFee,
        maximumDeliveryFee,
        platformFeeRate,
        effectiveFrom,
        effectiveUntil,
        isActive,
        createdAt,
        updatedAt,
      ];
}

/// Driver earnings summary for a specific period
class DriverEarningsSummary extends Equatable {
  final String id;
  final String driverId;
  final String periodType; // 'daily', 'weekly', 'monthly'
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalEarnings;
  final double deliveryFees;
  final double tips;
  final double bonuses;
  final double platformFees;
  final double netEarnings;
  final int totalDeliveries;
  final int successfulDeliveries;
  final double averageEarningsPerDelivery;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DriverEarningsSummary({
    required this.id,
    required this.driverId,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    this.totalEarnings = 0.0,
    this.deliveryFees = 0.0,
    this.tips = 0.0,
    this.bonuses = 0.0,
    this.platformFees = 0.0,
    this.netEarnings = 0.0,
    this.totalDeliveries = 0,
    this.successfulDeliveries = 0,
    this.averageEarningsPerDelivery = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverEarningsSummary.fromJson(Map<String, dynamic> json) {
    return DriverEarningsSummary(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      periodType: json['period_type'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      deliveryFees: (json['delivery_fees'] as num?)?.toDouble() ?? 0.0,
      tips: (json['tips'] as num?)?.toDouble() ?? 0.0,
      bonuses: (json['bonuses'] as num?)?.toDouble() ?? 0.0,
      platformFees: (json['platform_fees'] as num?)?.toDouble() ?? 0.0,
      netEarnings: (json['net_earnings'] as num?)?.toDouble() ?? 0.0,
      totalDeliveries: (json['total_deliveries'] as num?)?.toInt() ?? 0,
      successfulDeliveries: (json['successful_deliveries'] as num?)?.toInt() ?? 0,
      averageEarningsPerDelivery: (json['average_earnings_per_delivery'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        driverId,
        periodType,
        periodStart,
        periodEnd,
        totalEarnings,
        deliveryFees,
        tips,
        bonuses,
        platformFees,
        netEarnings,
        totalDeliveries,
        successfulDeliveries,
        averageEarningsPerDelivery,
        createdAt,
        updatedAt,
      ];
}
