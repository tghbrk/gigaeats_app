import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'commission.g.dart';

enum CommissionStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('paid')
  paid,
  @JsonValue('disputed')
  disputed,
  @JsonValue('cancelled')
  cancelled,
}

enum PayoutStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
}

enum PayoutMethod {
  @JsonValue('bank_transfer')
  bankTransfer,
  @JsonValue('duitnow')
  duitNow,
  @JsonValue('fpx')
  fpx,
  @JsonValue('ewallet')
  eWallet,
}

@JsonSerializable()
class Commission extends Equatable {
  final String id;
  final String orderId;
  final String orderNumber;
  final String salesAgentId;
  final String salesAgentName;
  final String vendorId;
  final String vendorName;
  final String customerId;
  final String customerName;
  final double orderAmount;
  final double commissionRate;
  final double commissionAmount;
  final double platformFee;
  final double netCommission;
  final CommissionStatus status;
  final DateTime orderDate;
  final DateTime? approvedAt;
  final DateTime? paidAt;
  final String? notes;
  final String? disputeReason;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Commission({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.salesAgentId,
    required this.salesAgentName,
    required this.vendorId,
    required this.vendorName,
    required this.customerId,
    required this.customerName,
    required this.orderAmount,
    required this.commissionRate,
    required this.commissionAmount,
    this.platformFee = 0.0,
    required this.netCommission,
    this.status = CommissionStatus.pending,
    required this.orderDate,
    this.approvedAt,
    this.paidAt,
    this.notes,
    this.disputeReason,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Commission.fromJson(Map<String, dynamic> json) => _$CommissionFromJson(json);
  Map<String, dynamic> toJson() => _$CommissionToJson(this);

  @override
  List<Object?> get props => [
        id,
        orderId,
        orderNumber,
        salesAgentId,
        salesAgentName,
        vendorId,
        vendorName,
        customerId,
        customerName,
        orderAmount,
        commissionRate,
        commissionAmount,
        platformFee,
        netCommission,
        status,
        orderDate,
        approvedAt,
        paidAt,
        notes,
        disputeReason,
        metadata,
        createdAt,
        updatedAt,
      ];

  Commission copyWith({
    String? id,
    String? orderId,
    String? orderNumber,
    String? salesAgentId,
    String? salesAgentName,
    String? vendorId,
    String? vendorName,
    String? customerId,
    String? customerName,
    double? orderAmount,
    double? commissionRate,
    double? commissionAmount,
    double? platformFee,
    double? netCommission,
    CommissionStatus? status,
    DateTime? orderDate,
    DateTime? approvedAt,
    DateTime? paidAt,
    String? notes,
    String? disputeReason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Commission(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      salesAgentId: salesAgentId ?? this.salesAgentId,
      salesAgentName: salesAgentName ?? this.salesAgentName,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      orderAmount: orderAmount ?? this.orderAmount,
      commissionRate: commissionRate ?? this.commissionRate,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      platformFee: platformFee ?? this.platformFee,
      netCommission: netCommission ?? this.netCommission,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      approvedAt: approvedAt ?? this.approvedAt,
      paidAt: paidAt ?? this.paidAt,
      notes: notes ?? this.notes,
      disputeReason: disputeReason ?? this.disputeReason,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class Payout extends Equatable {
  final String id;
  final String salesAgentId;
  final String salesAgentName;
  final List<String> commissionIds;
  final double totalAmount;
  final double platformFee;
  final double netAmount;
  final PayoutStatus status;
  final PayoutMethod method;
  final String? bankAccountNumber;
  final String? bankName;
  final String? bankCode;
  final String? recipientName;
  final String? transactionReference;
  final String? failureReason;
  final DateTime scheduledDate;
  final DateTime? processedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Payout({
    required this.id,
    required this.salesAgentId,
    required this.salesAgentName,
    required this.commissionIds,
    required this.totalAmount,
    this.platformFee = 0.0,
    required this.netAmount,
    this.status = PayoutStatus.pending,
    this.method = PayoutMethod.bankTransfer,
    this.bankAccountNumber,
    this.bankName,
    this.bankCode,
    this.recipientName,
    this.transactionReference,
    this.failureReason,
    required this.scheduledDate,
    this.processedAt,
    this.completedAt,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) => _$PayoutFromJson(json);
  Map<String, dynamic> toJson() => _$PayoutToJson(this);

  @override
  List<Object?> get props => [
        id,
        salesAgentId,
        salesAgentName,
        commissionIds,
        totalAmount,
        platformFee,
        netAmount,
        status,
        method,
        bankAccountNumber,
        bankName,
        bankCode,
        recipientName,
        transactionReference,
        failureReason,
        scheduledDate,
        processedAt,
        completedAt,
        metadata,
        createdAt,
        updatedAt,
      ];

  Payout copyWith({
    String? id,
    String? salesAgentId,
    String? salesAgentName,
    List<String>? commissionIds,
    double? totalAmount,
    double? platformFee,
    double? netAmount,
    PayoutStatus? status,
    PayoutMethod? method,
    String? bankAccountNumber,
    String? bankName,
    String? bankCode,
    String? recipientName,
    String? transactionReference,
    String? failureReason,
    DateTime? scheduledDate,
    DateTime? processedAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payout(
      id: id ?? this.id,
      salesAgentId: salesAgentId ?? this.salesAgentId,
      salesAgentName: salesAgentName ?? this.salesAgentName,
      commissionIds: commissionIds ?? this.commissionIds,
      totalAmount: totalAmount ?? this.totalAmount,
      platformFee: platformFee ?? this.platformFee,
      netAmount: netAmount ?? this.netAmount,
      status: status ?? this.status,
      method: method ?? this.method,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankName: bankName ?? this.bankName,
      bankCode: bankCode ?? this.bankCode,
      recipientName: recipientName ?? this.recipientName,
      transactionReference: transactionReference ?? this.transactionReference,
      failureReason: failureReason ?? this.failureReason,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class CommissionSummary extends Equatable {
  final String salesAgentId;
  final double totalEarnings;
  final double pendingCommissions;
  final double approvedCommissions;
  final double paidCommissions;
  final int totalOrders;
  final int pendingOrders;
  final double averageCommissionRate;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, double> monthlyBreakdown;

  const CommissionSummary({
    required this.salesAgentId,
    required this.totalEarnings,
    required this.pendingCommissions,
    required this.approvedCommissions,
    required this.paidCommissions,
    required this.totalOrders,
    required this.pendingOrders,
    required this.averageCommissionRate,
    required this.periodStart,
    required this.periodEnd,
    this.monthlyBreakdown = const {},
  });

  factory CommissionSummary.fromJson(Map<String, dynamic> json) => _$CommissionSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$CommissionSummaryToJson(this);

  @override
  List<Object?> get props => [
        salesAgentId,
        totalEarnings,
        pendingCommissions,
        approvedCommissions,
        paidCommissions,
        totalOrders,
        pendingOrders,
        averageCommissionRate,
        periodStart,
        periodEnd,
        monthlyBreakdown,
      ];
}
