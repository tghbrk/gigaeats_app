import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'notification.g.dart';

enum NotificationType {
  orderUpdate,
  newOrder,
  paymentReceived,
  customerMessage,
  systemAlert,
  promotion,
  reminder,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

@JsonSerializable()
class AppNotification extends Equatable {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final String? userId;
  final String? orderId;
  final String? customerId;
  final String? vendorId;
  final Map<String, dynamic>? data;
  final bool isRead;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.userId,
    this.orderId,
    this.customerId,
    this.vendorId,
    this.data,
    this.isRead = false,
    this.isArchived = false,
    required this.createdAt,
    this.readAt,
    this.expiresAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    String? userId,
    String? orderId,
    String? customerId,
    String? vendorId,
    Map<String, dynamic>? data,
    bool? isRead,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? expiresAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      vendorId: vendorId ?? this.vendorId,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        type,
        priority,
        userId,
        orderId,
        customerId,
        vendorId,
        data,
        isRead,
        isArchived,
        createdAt,
        readAt,
        expiresAt,
      ];
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.orderUpdate:
        return 'Order Update';
      case NotificationType.newOrder:
        return 'New Order';
      case NotificationType.paymentReceived:
        return 'Payment Received';
      case NotificationType.customerMessage:
        return 'Customer Message';
      case NotificationType.systemAlert:
        return 'System Alert';
      case NotificationType.promotion:
        return 'Promotion';
      case NotificationType.reminder:
        return 'Reminder';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.orderUpdate:
        return Icons.receipt_long;
      case NotificationType.newOrder:
        return Icons.add_shopping_cart;
      case NotificationType.paymentReceived:
        return Icons.payment;
      case NotificationType.customerMessage:
        return Icons.message;
      case NotificationType.systemAlert:
        return Icons.warning;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.reminder:
        return Icons.alarm;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.orderUpdate:
        return Colors.blue;
      case NotificationType.newOrder:
        return Colors.green;
      case NotificationType.paymentReceived:
        return Colors.teal;
      case NotificationType.customerMessage:
        return Colors.purple;
      case NotificationType.systemAlert:
        return Colors.red;
      case NotificationType.promotion:
        return Colors.orange;
      case NotificationType.reminder:
        return Colors.amber;
    }
  }
}

extension NotificationPriorityExtension on NotificationPriority {
  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }
}

// Factory methods for common notification types
class NotificationFactory {
  static AppNotification orderStatusUpdate({
    required String orderId,
    required String orderNumber,
    required String newStatus,
    required String userId,
  }) {
    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Order Status Updated',
      message: 'Order #$orderNumber is now $newStatus',
      type: NotificationType.orderUpdate,
      priority: NotificationPriority.normal,
      userId: userId,
      orderId: orderId,
      createdAt: DateTime.now(),
      data: {
        'orderNumber': orderNumber,
        'newStatus': newStatus,
      },
    );
  }

  static AppNotification newOrderReceived({
    required String orderId,
    required String orderNumber,
    required String customerName,
    required String vendorId,
  }) {
    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Order Received',
      message: 'New order #$orderNumber from $customerName',
      type: NotificationType.newOrder,
      priority: NotificationPriority.high,
      userId: vendorId,
      orderId: orderId,
      createdAt: DateTime.now(),
      data: {
        'orderNumber': orderNumber,
        'customerName': customerName,
      },
    );
  }

  static AppNotification paymentReceived({
    required String orderId,
    required String orderNumber,
    required double amount,
    required String userId,
  }) {
    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Payment Received',
      message: 'Payment of RM ${amount.toStringAsFixed(2)} received for order #$orderNumber',
      type: NotificationType.paymentReceived,
      priority: NotificationPriority.normal,
      userId: userId,
      orderId: orderId,
      createdAt: DateTime.now(),
      data: {
        'orderNumber': orderNumber,
        'amount': amount,
      },
    );
  }

  static AppNotification systemAlert({
    required String title,
    required String message,
    String? userId,
    NotificationPriority priority = NotificationPriority.normal,
  }) {
    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.systemAlert,
      priority: priority,
      userId: userId,
      createdAt: DateTime.now(),
    );
  }

  static AppNotification reminder({
    required String title,
    required String message,
    required String userId,
    DateTime? expiresAt,
  }) {
    return AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.reminder,
      priority: NotificationPriority.normal,
      userId: userId,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
    );
  }
}
