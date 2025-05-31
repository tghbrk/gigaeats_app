// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderSummary _$OrderSummaryFromJson(Map<String, dynamic> json) => OrderSummary(
  id: json['id'] as String,
  orderNumber: json['order_number'] as String,
  status: json['status'] as String,
  totalAmount: (json['total_amount'] as num).toDouble(),
  vendorName: json['vendor_name'] as String?,
  customerName: json['customer_name'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$OrderSummaryToJson(OrderSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_number': instance.orderNumber,
      'status': instance.status,
      'total_amount': instance.totalAmount,
      'vendor_name': instance.vendorName,
      'customer_name': instance.customerName,
      'created_at': instance.createdAt.toIso8601String(),
    };
