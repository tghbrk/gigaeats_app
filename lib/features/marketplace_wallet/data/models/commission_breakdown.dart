import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'commission_breakdown.g.dart';

@JsonSerializable()
class CommissionBreakdown extends Equatable {
  final double totalAmount;
  final double vendorAmount;
  final double platformFee;
  final double salesAgentCommission;
  final double driverCommission;
  final double deliveryFee;
  final String currency;
  final String? orderId;
  final String? deliveryMethod;
  final DateTime? calculatedAt;

  const CommissionBreakdown({
    required this.totalAmount,
    required this.vendorAmount,
    required this.platformFee,
    required this.salesAgentCommission,
    required this.driverCommission,
    required this.deliveryFee,
    this.currency = 'MYR',
    this.orderId,
    this.deliveryMethod,
    this.calculatedAt,
  });

  factory CommissionBreakdown.fromJson(Map<String, dynamic> json) =>
      _$CommissionBreakdownFromJson(json);

  Map<String, dynamic> toJson() => _$CommissionBreakdownToJson(this);

  CommissionBreakdown copyWith({
    double? totalAmount,
    double? vendorAmount,
    double? platformFee,
    double? salesAgentCommission,
    double? driverCommission,
    double? deliveryFee,
    String? currency,
    String? orderId,
    String? deliveryMethod,
    DateTime? calculatedAt,
  }) {
    return CommissionBreakdown(
      totalAmount: totalAmount ?? this.totalAmount,
      vendorAmount: vendorAmount ?? this.vendorAmount,
      platformFee: platformFee ?? this.platformFee,
      salesAgentCommission: salesAgentCommission ?? this.salesAgentCommission,
      driverCommission: driverCommission ?? this.driverCommission,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      currency: currency ?? this.currency,
      orderId: orderId ?? this.orderId,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  @override
  List<Object?> get props => [
        totalAmount,
        vendorAmount,
        platformFee,
        salesAgentCommission,
        driverCommission,
        deliveryFee,
        currency,
        orderId,
        deliveryMethod,
        calculatedAt,
      ];

  /// Get formatted total amount
  String get formattedTotalAmount => '$currency ${totalAmount.toStringAsFixed(2)}';

  /// Get formatted vendor amount
  String get formattedVendorAmount => '$currency ${vendorAmount.toStringAsFixed(2)}';

  /// Get formatted platform fee
  String get formattedPlatformFee => '$currency ${platformFee.toStringAsFixed(2)}';

  /// Get formatted sales agent commission
  String get formattedSalesAgentCommission => '$currency ${salesAgentCommission.toStringAsFixed(2)}';

  /// Get formatted driver commission
  String get formattedDriverCommission => '$currency ${driverCommission.toStringAsFixed(2)}';

  /// Get formatted delivery fee
  String get formattedDeliveryFee => '$currency ${deliveryFee.toStringAsFixed(2)}';

  /// Get platform fee percentage
  double get platformFeePercentage => (platformFee / totalAmount) * 100;

  /// Get vendor percentage
  double get vendorPercentage => (vendorAmount / totalAmount) * 100;

  /// Get sales agent commission percentage
  double get salesAgentPercentage => (salesAgentCommission / totalAmount) * 100;

  /// Get driver commission percentage
  double get driverPercentage => (driverCommission / totalAmount) * 100;

  /// Get delivery fee percentage
  double get deliveryFeePercentage => (deliveryFee / totalAmount) * 100;

  /// Get formatted platform fee percentage
  String get formattedPlatformFeePercentage => '${platformFeePercentage.toStringAsFixed(1)}%';

  /// Get formatted vendor percentage
  String get formattedVendorPercentage => '${vendorPercentage.toStringAsFixed(1)}%';

  /// Get formatted sales agent percentage
  String get formattedSalesAgentPercentage => '${salesAgentPercentage.toStringAsFixed(1)}%';

  /// Get formatted driver percentage
  String get formattedDriverPercentage => '${driverPercentage.toStringAsFixed(1)}%';

  /// Validate that breakdown adds up to total
  bool get isValid {
    final sum = vendorAmount + platformFee + salesAgentCommission + driverCommission + deliveryFee;
    return (sum - totalAmount).abs() < 0.01; // Allow for rounding differences
  }

  /// Get breakdown as a list of commission items
  List<CommissionItem> get items => [
        CommissionItem(
          name: 'Vendor Share',
          amount: vendorAmount,
          percentage: vendorPercentage,
          currency: currency,
          type: CommissionType.vendor,
        ),
        CommissionItem(
          name: 'Platform Fee',
          amount: platformFee,
          percentage: platformFeePercentage,
          currency: currency,
          type: CommissionType.platform,
        ),
        if (salesAgentCommission > 0)
          CommissionItem(
            name: 'Sales Agent Commission',
            amount: salesAgentCommission,
            percentage: salesAgentPercentage,
            currency: currency,
            type: CommissionType.salesAgent,
          ),
        if (driverCommission > 0)
          CommissionItem(
            name: 'Driver Commission',
            amount: driverCommission,
            percentage: driverPercentage,
            currency: currency,
            type: CommissionType.driver,
          ),
        if (deliveryFee > 0)
          CommissionItem(
            name: 'Delivery Fee',
            amount: deliveryFee,
            percentage: deliveryFeePercentage,
            currency: currency,
            type: CommissionType.delivery,
          ),
      ];

  /// Get delivery method display name
  String get deliveryMethodDisplayName {
    switch (deliveryMethod) {
      case 'customer_pickup':
        return 'Customer Pickup';
      case 'sales_agent_pickup':
        return 'Sales Agent Pickup';
      case 'own_fleet':
        return 'Own Fleet Delivery';
      default:
        return deliveryMethod ?? 'Unknown';
    }
  }

  /// Create a test commission breakdown for development
  factory CommissionBreakdown.test({
    double? totalAmount,
    String? deliveryMethod,
  }) {
    final total = totalAmount ?? 58.00;
    final method = deliveryMethod ?? 'own_fleet';
    
    // Calculate based on delivery method
    double vendorAmount, platformFee, salesAgentCommission, driverCommission, deliveryFee;
    
    switch (method) {
      case 'customer_pickup':
        vendorAmount = total * 0.92; // 92%
        platformFee = total * 0.05; // 5%
        salesAgentCommission = total * 0.03; // 3%
        driverCommission = 0.0;
        deliveryFee = 0.0;
        break;
      case 'sales_agent_pickup':
        vendorAmount = total * 0.85; // 85%
        platformFee = total * 0.05; // 5%
        salesAgentCommission = total * 0.03; // 3%
        driverCommission = 0.0;
        deliveryFee = 3.0;
        break;
      case 'own_fleet':
      default:
        vendorAmount = total * 0.80; // 80%
        platformFee = total * 0.05; // 5%
        salesAgentCommission = total * 0.03; // 3%
        driverCommission = total * 0.12; // 12%
        deliveryFee = 8.0;
        break;
    }
    
    return CommissionBreakdown(
      totalAmount: total,
      vendorAmount: vendorAmount,
      platformFee: platformFee,
      salesAgentCommission: salesAgentCommission,
      driverCommission: driverCommission,
      deliveryFee: deliveryFee,
      currency: 'MYR',
      orderId: 'test-order-id',
      deliveryMethod: method,
      calculatedAt: DateTime.now(),
    );
  }
}

@JsonSerializable()
class CommissionItem extends Equatable {
  final String name;
  final double amount;
  final double percentage;
  final String currency;
  final CommissionType type;

  const CommissionItem({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.currency,
    required this.type,
  });

  factory CommissionItem.fromJson(Map<String, dynamic> json) =>
      _$CommissionItemFromJson(json);

  Map<String, dynamic> toJson() => _$CommissionItemToJson(this);

  @override
  List<Object?> get props => [name, amount, percentage, currency, type];

  /// Get formatted amount
  String get formattedAmount => '$currency ${amount.toStringAsFixed(2)}';

  /// Get formatted percentage
  String get formattedPercentage => '${percentage.toStringAsFixed(1)}%';

  /// Get display text
  String get displayText => '$name: $formattedAmount ($formattedPercentage)';
}

enum CommissionType {
  vendor,
  platform,
  salesAgent,
  driver,
  delivery,
}

extension CommissionTypeExtension on CommissionType {
  String get displayName {
    switch (this) {
      case CommissionType.vendor:
        return 'Vendor';
      case CommissionType.platform:
        return 'Platform';
      case CommissionType.salesAgent:
        return 'Sales Agent';
      case CommissionType.driver:
        return 'Driver';
      case CommissionType.delivery:
        return 'Delivery';
    }
  }

  String get iconName {
    switch (this) {
      case CommissionType.vendor:
        return 'store';
      case CommissionType.platform:
        return 'business';
      case CommissionType.salesAgent:
        return 'person';
      case CommissionType.driver:
        return 'local_shipping';
      case CommissionType.delivery:
        return 'delivery_dining';
    }
  }
}
