// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Commission _$CommissionFromJson(Map<String, dynamic> json) => Commission(
  id: json['id'] as String,
  orderId: json['orderId'] as String,
  orderNumber: json['orderNumber'] as String,
  salesAgentId: json['salesAgentId'] as String,
  salesAgentName: json['salesAgentName'] as String,
  vendorId: json['vendorId'] as String,
  vendorName: json['vendorName'] as String,
  customerId: json['customerId'] as String,
  customerName: json['customerName'] as String,
  orderAmount: (json['orderAmount'] as num).toDouble(),
  commissionRate: (json['commissionRate'] as num).toDouble(),
  commissionAmount: (json['commissionAmount'] as num).toDouble(),
  platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
  netCommission: (json['netCommission'] as num).toDouble(),
  status:
      $enumDecodeNullable(_$CommissionStatusEnumMap, json['status']) ??
      CommissionStatus.pending,
  orderDate: DateTime.parse(json['orderDate'] as String),
  approvedAt: json['approvedAt'] == null
      ? null
      : DateTime.parse(json['approvedAt'] as String),
  paidAt: json['paidAt'] == null
      ? null
      : DateTime.parse(json['paidAt'] as String),
  notes: json['notes'] as String?,
  disputeReason: json['disputeReason'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CommissionToJson(Commission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'orderNumber': instance.orderNumber,
      'salesAgentId': instance.salesAgentId,
      'salesAgentName': instance.salesAgentName,
      'vendorId': instance.vendorId,
      'vendorName': instance.vendorName,
      'customerId': instance.customerId,
      'customerName': instance.customerName,
      'orderAmount': instance.orderAmount,
      'commissionRate': instance.commissionRate,
      'commissionAmount': instance.commissionAmount,
      'platformFee': instance.platformFee,
      'netCommission': instance.netCommission,
      'status': _$CommissionStatusEnumMap[instance.status]!,
      'orderDate': instance.orderDate.toIso8601String(),
      'approvedAt': instance.approvedAt?.toIso8601String(),
      'paidAt': instance.paidAt?.toIso8601String(),
      'notes': instance.notes,
      'disputeReason': instance.disputeReason,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$CommissionStatusEnumMap = {
  CommissionStatus.pending: 'pending',
  CommissionStatus.approved: 'approved',
  CommissionStatus.paid: 'paid',
  CommissionStatus.disputed: 'disputed',
  CommissionStatus.cancelled: 'cancelled',
};

Payout _$PayoutFromJson(Map<String, dynamic> json) => Payout(
  id: json['id'] as String,
  salesAgentId: json['salesAgentId'] as String,
  salesAgentName: json['salesAgentName'] as String,
  commissionIds: (json['commissionIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
  netAmount: (json['netAmount'] as num).toDouble(),
  status:
      $enumDecodeNullable(_$PayoutStatusEnumMap, json['status']) ??
      PayoutStatus.pending,
  method:
      $enumDecodeNullable(_$PayoutMethodEnumMap, json['method']) ??
      PayoutMethod.bankTransfer,
  bankAccountNumber: json['bankAccountNumber'] as String?,
  bankName: json['bankName'] as String?,
  bankCode: json['bankCode'] as String?,
  recipientName: json['recipientName'] as String?,
  transactionReference: json['transactionReference'] as String?,
  failureReason: json['failureReason'] as String?,
  scheduledDate: DateTime.parse(json['scheduledDate'] as String),
  processedAt: json['processedAt'] == null
      ? null
      : DateTime.parse(json['processedAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$PayoutToJson(Payout instance) => <String, dynamic>{
  'id': instance.id,
  'salesAgentId': instance.salesAgentId,
  'salesAgentName': instance.salesAgentName,
  'commissionIds': instance.commissionIds,
  'totalAmount': instance.totalAmount,
  'platformFee': instance.platformFee,
  'netAmount': instance.netAmount,
  'status': _$PayoutStatusEnumMap[instance.status]!,
  'method': _$PayoutMethodEnumMap[instance.method]!,
  'bankAccountNumber': instance.bankAccountNumber,
  'bankName': instance.bankName,
  'bankCode': instance.bankCode,
  'recipientName': instance.recipientName,
  'transactionReference': instance.transactionReference,
  'failureReason': instance.failureReason,
  'scheduledDate': instance.scheduledDate.toIso8601String(),
  'processedAt': instance.processedAt?.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'metadata': instance.metadata,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$PayoutStatusEnumMap = {
  PayoutStatus.pending: 'pending',
  PayoutStatus.processing: 'processing',
  PayoutStatus.completed: 'completed',
  PayoutStatus.failed: 'failed',
  PayoutStatus.cancelled: 'cancelled',
};

const _$PayoutMethodEnumMap = {
  PayoutMethod.bankTransfer: 'bank_transfer',
  PayoutMethod.duitNow: 'duitnow',
  PayoutMethod.fpx: 'fpx',
  PayoutMethod.eWallet: 'ewallet',
};

CommissionSummary _$CommissionSummaryFromJson(Map<String, dynamic> json) =>
    CommissionSummary(
      salesAgentId: json['salesAgentId'] as String,
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
      pendingCommissions: (json['pendingCommissions'] as num).toDouble(),
      approvedCommissions: (json['approvedCommissions'] as num).toDouble(),
      paidCommissions: (json['paidCommissions'] as num).toDouble(),
      totalOrders: (json['totalOrders'] as num).toInt(),
      pendingOrders: (json['pendingOrders'] as num).toInt(),
      averageCommissionRate: (json['averageCommissionRate'] as num).toDouble(),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      monthlyBreakdown:
          (json['monthlyBreakdown'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
    );

Map<String, dynamic> _$CommissionSummaryToJson(CommissionSummary instance) =>
    <String, dynamic>{
      'salesAgentId': instance.salesAgentId,
      'totalEarnings': instance.totalEarnings,
      'pendingCommissions': instance.pendingCommissions,
      'approvedCommissions': instance.approvedCommissions,
      'paidCommissions': instance.paidCommissions,
      'totalOrders': instance.totalOrders,
      'pendingOrders': instance.pendingOrders,
      'averageCommissionRate': instance.averageCommissionRate,
      'periodStart': instance.periodStart.toIso8601String(),
      'periodEnd': instance.periodEnd.toIso8601String(),
      'monthlyBreakdown': instance.monthlyBreakdown,
    };
