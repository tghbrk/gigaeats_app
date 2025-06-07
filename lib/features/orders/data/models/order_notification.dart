import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'order_notification.g.dart';

enum NotificationType {
  statusChange('status_change', 'Status Change'),
  paymentUpdate('payment_update', 'Payment Update'),
  deliveryUpdate('delivery_update', 'Delivery Update');

  const NotificationType(this.value, this.displayName);

  final String value;
  final String displayName;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.statusChange,
    );
  }

  @override
  String toString() => value;
}

@JsonSerializable()
class OrderNotification extends Equatable {
  final String id;
  @JsonKey(name: 'order_id')
  final String orderId;
  @JsonKey(name: 'recipient_id')
  final String recipientId;
  @JsonKey(name: 'notification_type', fromJson: _notificationTypeFromJson, toJson: _notificationTypeToJson)
  final NotificationType notificationType;
  final String title;
  final String message;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'sent_at')
  final DateTime sentAt;
  @JsonKey(name: 'read_at')
  final DateTime? readAt;
  final Map<String, dynamic>? metadata;

  const OrderNotification({
    required this.id,
    required this.orderId,
    required this.recipientId,
    required this.notificationType,
    required this.title,
    required this.message,
    this.isRead = false,
    required this.sentAt,
    this.readAt,
    this.metadata,
  });

  factory OrderNotification.fromJson(Map<String, dynamic> json) => 
      _$OrderNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$OrderNotificationToJson(this);

  OrderNotification copyWith({
    String? id,
    String? orderId,
    String? recipientId,
    NotificationType? notificationType,
    String? title,
    String? message,
    bool? isRead,
    DateTime? sentAt,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
  }) {
    return OrderNotification(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      recipientId: recipientId ?? this.recipientId,
      notificationType: notificationType ?? this.notificationType,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Mark notification as read
  OrderNotification markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  /// Check if notification is unread
  bool get isUnread => !isRead;

  /// Get notification age in minutes
  int get ageInMinutes {
    return DateTime.now().difference(sentAt).inMinutes;
  }

  /// Check if notification is recent (less than 1 hour old)
  bool get isRecent => ageInMinutes < 60;

  @override
  List<Object?> get props => [
        id,
        orderId,
        recipientId,
        notificationType,
        title,
        message,
        isRead,
        sentAt,
        readAt,
        metadata,
      ];

  @override
  String toString() {
    return 'OrderNotification(id: $id, orderId: $orderId, type: $notificationType, isRead: $isRead)';
  }
}

// Helper functions for JSON serialization
NotificationType _notificationTypeFromJson(String value) {
  return NotificationType.fromString(value);
}

String _notificationTypeToJson(NotificationType type) {
  return type.value;
}
