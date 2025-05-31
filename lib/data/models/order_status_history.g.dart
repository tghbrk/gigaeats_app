// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_status_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderStatusHistory _$OrderStatusHistoryFromJson(Map<String, dynamic> json) =>
    OrderStatusHistory(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      oldStatus: _orderStatusFromJsonNullable(json['old_status'] as String?),
      newStatus: _orderStatusFromJson(json['new_status'] as String),
      changedBy: json['changed_by'] as String?,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$OrderStatusHistoryToJson(OrderStatusHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'old_status': _orderStatusToJsonNullable(instance.oldStatus),
      'new_status': _orderStatusToJson(instance.newStatus),
      'changed_by': instance.changedBy,
      'reason': instance.reason,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
    };
