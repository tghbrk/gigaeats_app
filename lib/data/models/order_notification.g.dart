// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderNotification _$OrderNotificationFromJson(Map<String, dynamic> json) =>
    OrderNotification(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      recipientId: json['recipient_id'] as String,
      notificationType: _notificationTypeFromJson(
        json['notification_type'] as String,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      sentAt: DateTime.parse(json['sent_at'] as String),
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$OrderNotificationToJson(OrderNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'recipient_id': instance.recipientId,
      'notification_type': _notificationTypeToJson(instance.notificationType),
      'title': instance.title,
      'message': instance.message,
      'is_read': instance.isRead,
      'sent_at': instance.sentAt.toIso8601String(),
      'read_at': instance.readAt?.toIso8601String(),
      'metadata': instance.metadata,
    };
