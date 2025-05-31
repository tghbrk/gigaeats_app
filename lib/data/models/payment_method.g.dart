// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_method.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentMethod _$PaymentMethodFromJson(Map<String, dynamic> json) =>
    PaymentMethod(
      id: json['id'] as String,
      type: $enumDecode(_$PaymentMethodTypeEnumMap, json['type']),
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      iconUrl: json['iconUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isDefault: json['isDefault'] as bool? ?? false,
      configuration: json['configuration'] as Map<String, dynamic>?,
      supportedCurrencies:
          (json['supportedCurrencies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['MYR'],
      minimumAmount: (json['minimumAmount'] as num?)?.toDouble(),
      maximumAmount: (json['maximumAmount'] as num?)?.toDouble(),
      processingFee: (json['processingFee'] as num?)?.toDouble(),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$PaymentMethodToJson(PaymentMethod instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$PaymentMethodTypeEnumMap[instance.type]!,
      'name': instance.name,
      'displayName': instance.displayName,
      'iconUrl': instance.iconUrl,
      'isActive': instance.isActive,
      'isDefault': instance.isDefault,
      'configuration': instance.configuration,
      'supportedCurrencies': instance.supportedCurrencies,
      'minimumAmount': instance.minimumAmount,
      'maximumAmount': instance.maximumAmount,
      'processingFee': instance.processingFee,
      'description': instance.description,
    };

const _$PaymentMethodTypeEnumMap = {
  PaymentMethodType.fpx: 'fpx',
  PaymentMethodType.creditCard: 'credit_card',
  PaymentMethodType.grabPay: 'grabpay',
  PaymentMethodType.touchNGo: 'touchngo',
  PaymentMethodType.boost: 'boost',
  PaymentMethodType.shopeePay: 'shopee_pay',
  PaymentMethodType.billplz: 'billplz',
  PaymentMethodType.bankTransfer: 'bank_transfer',
};

PaymentTransaction _$PaymentTransactionFromJson(Map<String, dynamic> json) =>
    PaymentTransaction(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      paymentMethodId: json['paymentMethodId'] as String,
      paymentMethodType: $enumDecode(
        _$PaymentMethodTypeEnumMap,
        json['paymentMethodType'],
      ),
      status: $enumDecode(_$PaymentStatusEnumMap, json['status']),
      amount: (json['amount'] as num).toDouble(),
      processingFee: (json['processingFee'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'MYR',
      transactionReference: json['transactionReference'] as String?,
      gatewayTransactionId: json['gatewayTransactionId'] as String?,
      gatewayResponse: json['gatewayResponse'] as String?,
      failureReason: json['failureReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PaymentTransactionToJson(
  PaymentTransaction instance,
) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'paymentMethodId': instance.paymentMethodId,
  'paymentMethodType': _$PaymentMethodTypeEnumMap[instance.paymentMethodType]!,
  'status': _$PaymentStatusEnumMap[instance.status]!,
  'amount': instance.amount,
  'processingFee': instance.processingFee,
  'currency': instance.currency,
  'transactionReference': instance.transactionReference,
  'gatewayTransactionId': instance.gatewayTransactionId,
  'gatewayResponse': instance.gatewayResponse,
  'failureReason': instance.failureReason,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'metadata': instance.metadata,
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.processing: 'processing',
  PaymentStatus.completed: 'completed',
  PaymentStatus.failed: 'failed',
  PaymentStatus.cancelled: 'cancelled',
  PaymentStatus.refunded: 'refunded',
};
