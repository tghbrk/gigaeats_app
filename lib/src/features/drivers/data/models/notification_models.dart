import 'package:flutter/foundation.dart';

/// Customer notification model for automated notifications
@immutable
class CustomerNotification {
  final String id;
  final String customerId;
  final String? orderId;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? readAt;

  const CustomerNotification({
    required this.id,
    required this.customerId,
    this.orderId,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    required this.data,
    required this.timestamp,
    this.isRead = false,
    this.readAt,
  });

  CustomerNotification copyWith({
    String? id,
    String? customerId,
    String? orderId,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    DateTime? readAt,
  }) {
    return CustomerNotification(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      orderId: orderId ?? this.orderId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }

  factory CustomerNotification.fromJson(Map<String, dynamic> json) {
    return CustomerNotification(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      orderId: json['order_id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.orderUpdate,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      timestamp: DateTime.parse(json['sent_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'order_id': orderId,
      'title': title,
      'body': body,
      'type': type.name,
      'priority': priority.name,
      'data': data,
      'sent_at': timestamp.toIso8601String(),
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
    };
  }
}

/// Notification template for automated notifications
@immutable
class NotificationTemplate {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final List<String> requiredVariables;
  final Map<String, dynamic> metadata;

  const NotificationTemplate({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    this.requiredVariables = const [],
    this.metadata = const {},
  });

  /// Extract variables from template text
  List<String> get extractedVariables {
    final regex = RegExp(r'\{(\w+)\}');
    final matches = regex.allMatches('$title $body');
    return matches.map((match) => match.group(1)!).toSet().toList();
  }

  /// Validate if all required variables are provided
  bool validateVariables(Map<String, String> variables) {
    final required = requiredVariables.isNotEmpty ? requiredVariables : extractedVariables;
    return required.every((variable) => variables.containsKey(variable));
  }
}

/// Notification preferences for customers
@immutable
class NotificationPreferences {
  final String customerId;
  final bool enableOrderUpdates;
  final bool enableDriverUpdates;
  final bool enableDelayAlerts;
  final bool enablePromotions;
  final bool enablePushNotifications;
  final bool enableSmsNotifications;
  final bool enableEmailNotifications;
  final Map<NotificationType, bool> typePreferences;
  final List<String> quietHours;
  final DateTime? lastUpdated;

  const NotificationPreferences({
    required this.customerId,
    this.enableOrderUpdates = true,
    this.enableDriverUpdates = true,
    this.enableDelayAlerts = true,
    this.enablePromotions = false,
    this.enablePushNotifications = true,
    this.enableSmsNotifications = false,
    this.enableEmailNotifications = true,
    this.typePreferences = const {},
    this.quietHours = const [],
    this.lastUpdated,
  });

  /// Check if notification type is enabled
  bool isTypeEnabled(NotificationType type) {
    return typePreferences[type] ?? _getDefaultForType(type);
  }

  /// Check if notifications are allowed at current time
  bool isAllowedAtCurrentTime() {
    if (quietHours.isEmpty) return true;
    
    final now = DateTime.now();
    final currentHour = now.hour;
    
    // Parse quiet hours (format: "22:00-07:00")
    for (final quietPeriod in quietHours) {
      final parts = quietPeriod.split('-');
      if (parts.length == 2) {
        final startHour = int.tryParse(parts[0].split(':')[0]) ?? 0;
        final endHour = int.tryParse(parts[1].split(':')[0]) ?? 0;
        
        if (startHour <= endHour) {
          // Same day period
          if (currentHour >= startHour && currentHour < endHour) {
            return false;
          }
        } else {
          // Overnight period
          if (currentHour >= startHour || currentHour < endHour) {
            return false;
          }
        }
      }
    }
    
    return true;
  }

  bool _getDefaultForType(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return enableOrderUpdates;
      case NotificationType.driverUpdate:
        return enableDriverUpdates;
      case NotificationType.delayAlert:
        return enableDelayAlerts;
      case NotificationType.promotion:
        return enablePromotions;
      case NotificationType.system:
        return true; // Always enabled for system notifications
    }
  }

  NotificationPreferences copyWith({
    String? customerId,
    bool? enableOrderUpdates,
    bool? enableDriverUpdates,
    bool? enableDelayAlerts,
    bool? enablePromotions,
    bool? enablePushNotifications,
    bool? enableSmsNotifications,
    bool? enableEmailNotifications,
    Map<NotificationType, bool>? typePreferences,
    List<String>? quietHours,
    DateTime? lastUpdated,
  }) {
    return NotificationPreferences(
      customerId: customerId ?? this.customerId,
      enableOrderUpdates: enableOrderUpdates ?? this.enableOrderUpdates,
      enableDriverUpdates: enableDriverUpdates ?? this.enableDriverUpdates,
      enableDelayAlerts: enableDelayAlerts ?? this.enableDelayAlerts,
      enablePromotions: enablePromotions ?? this.enablePromotions,
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      enableSmsNotifications: enableSmsNotifications ?? this.enableSmsNotifications,
      enableEmailNotifications: enableEmailNotifications ?? this.enableEmailNotifications,
      typePreferences: typePreferences ?? this.typePreferences,
      quietHours: quietHours ?? this.quietHours,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Notification analytics for tracking performance
@immutable
class NotificationAnalytics {
  final String id;
  final String notificationId;
  final String customerId;
  final NotificationType type;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? clickedAt;
  final String? deliveryStatus;
  final String? failureReason;
  final Map<String, dynamic> metadata;

  const NotificationAnalytics({
    required this.id,
    required this.notificationId,
    required this.customerId,
    required this.type,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.clickedAt,
    this.deliveryStatus,
    this.failureReason,
    this.metadata = const {},
  });

  /// Calculate delivery time
  Duration? get deliveryTime {
    if (deliveredAt != null) {
      return deliveredAt!.difference(sentAt);
    }
    return null;
  }

  /// Calculate read time
  Duration? get readTime {
    if (readAt != null) {
      return readAt!.difference(sentAt);
    }
    return null;
  }

  /// Check if notification was successful
  bool get wasSuccessful {
    return deliveryStatus == 'delivered' && failureReason == null;
  }

  /// Check if notification was read
  bool get wasRead {
    return readAt != null;
  }

  /// Check if notification was clicked
  bool get wasClicked {
    return clickedAt != null;
  }
}

/// Notification batch for bulk operations
@immutable
class NotificationBatch {
  final String batchId;
  final String driverId;
  final String? batchOrderId;
  final List<CustomerNotification> notifications;
  final DateTime createdAt;
  final DateTime? sentAt;
  final NotificationBatchStatus status;
  final Map<String, dynamic> metadata;

  const NotificationBatch({
    required this.batchId,
    required this.driverId,
    this.batchOrderId,
    required this.notifications,
    required this.createdAt,
    this.sentAt,
    required this.status,
    this.metadata = const {},
  });

  /// Get notification count
  int get notificationCount => notifications.length;

  /// Get unique customer count
  int get customerCount => notifications.map((n) => n.customerId).toSet().length;

  /// Check if all notifications were sent
  bool get allSent => notifications.every((n) => n.timestamp.isBefore(DateTime.now()));

  /// Get success rate
  double get successRate {
    if (notifications.isEmpty) return 0.0;
    // This would be calculated based on delivery status in a real implementation
    return 1.0; // Placeholder
  }
}

/// Enums for notification system
enum NotificationType {
  orderUpdate,
  driverUpdate,
  delayAlert,
  promotion,
  system,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

enum NotificationBatchStatus {
  created,
  sending,
  sent,
  failed,
  partiallyFailed,
}

/// Notification delivery channel
enum NotificationChannel {
  push,
  sms,
  email,
  inApp,
}

/// Notification action for interactive notifications
@immutable
class NotificationAction {
  final String id;
  final String title;
  final String? icon;
  final Map<String, dynamic> data;

  const NotificationAction({
    required this.id,
    required this.title,
    this.icon,
    this.data = const {},
  });

  factory NotificationAction.trackOrder() {
    return const NotificationAction(
      id: 'track_order',
      title: 'Track Order',
      icon: 'location_on',
      data: {'action': 'open_tracking'},
    );
  }

  factory NotificationAction.contactDriver() {
    return const NotificationAction(
      id: 'contact_driver',
      title: 'Contact Driver',
      icon: 'phone',
      data: {'action': 'contact_driver'},
    );
  }

  factory NotificationAction.rateOrder() {
    return const NotificationAction(
      id: 'rate_order',
      title: 'Rate Order',
      icon: 'star',
      data: {'action': 'rate_order'},
    );
  }
}
