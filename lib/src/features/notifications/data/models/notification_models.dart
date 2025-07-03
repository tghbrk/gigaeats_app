import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_models.freezed.dart';
part 'notification_models.g.dart';

@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    String? userId,
    List<String>? roleFilter,
    @Default(false) bool isBroadcast,
    required String type,
    required String title,
    required String message,
    @Default({}) Map<String, dynamic> richContent,
    String? actionUrl,
    @Default({}) Map<String, dynamic> actionData,
    @Default('normal') String priority,
    @Default('general') String category,
    @Default([]) List<String> tags,
    @Default(['in_app']) List<String> channels,
    @Default({}) Map<String, dynamic> deliveryStatus,
    @Default(false) bool isRead,
    DateTime? readAt,
    DateTime? expiresAt,
    required DateTime scheduledAt,
    String? relatedEntityType,
    String? relatedEntityId,
    String? createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}

@freezed
class NotificationCounts with _$NotificationCounts {
  const factory NotificationCounts({
    @Default(0) int totalCount,
    @Default(0) int unreadCount,
    @Default(0) int highPriorityUnread,
    @Default(0) int urgentPriorityUnread,
  }) = _NotificationCounts;

  factory NotificationCounts.fromJson(Map<String, dynamic> json) =>
      _$NotificationCountsFromJson(json);
}

@freezed
class NotificationTemplate with _$NotificationTemplate {
  const factory NotificationTemplate({
    required String id,
    required String templateKey,
    required String name,
    String? description,
    required String titleTemplate,
    required String messageTemplate,
    @Default({}) Map<String, dynamic> richContentTemplate,
    required String type,
    @Default('normal') String priority,
    @Default(['in_app']) List<String> defaultChannels,
    @Default('general') String category,
    List<String>? targetRoles,
    @Default([]) List<String> requiredVariables,
    @Default([]) List<String> optionalVariables,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _NotificationTemplate;

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) =>
      _$NotificationTemplateFromJson(json);
}

@freezed
class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    required String id,
    required String userId,
    @Default(true) bool inAppEnabled,
    @Default(true) bool emailEnabled,
    @Default(true) bool pushEnabled,
    @Default(false) bool smsEnabled,
    @Default(true) bool orderNotifications,
    @Default(true) bool paymentNotifications,
    @Default(true) bool accountNotifications,
    @Default(true) bool systemNotifications,
    @Default(false) bool promotionNotifications,
    String? quietHoursStart,
    String? quietHoursEnd,
    @Default('Asia/Kuala_Lumpur') String timezone,
    @Default(10) int maxNotificationsPerHour,
    @Default(50) int maxNotificationsPerDay,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _NotificationPreferences;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);
}

@freezed
class NotificationDeliveryLog with _$NotificationDeliveryLog {
  const factory NotificationDeliveryLog({
    required String id,
    required String notificationId,
    required String channel,
    @Default('pending') String status,
    String? recipientAddress,
    String? provider,
    String? providerMessageId,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? failedAt,
    String? errorCode,
    String? errorMessage,
    @Default(0) int retryCount,
    @Default(3) int maxRetries,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _NotificationDeliveryLog;

  factory NotificationDeliveryLog.fromJson(Map<String, dynamic> json) =>
      _$NotificationDeliveryLogFromJson(json);
}

// Enums for notification types
enum NotificationType {
  orderCreated('order_created'),
  orderUpdated('order_updated'),
  orderConfirmed('order_confirmed'),
  orderPreparing('order_preparing'),
  orderReady('order_ready'),
  orderOutForDelivery('order_out_for_delivery'),
  orderDelivered('order_delivered'),
  orderCancelled('order_cancelled'),
  paymentReceived('payment_received'),
  paymentFailed('payment_failed'),
  driverAssigned('driver_assigned'),
  driverLocationUpdate('driver_location_update'),
  accountVerified('account_verified'),
  roleChanged('role_changed'),
  invitationReceived('invitation_received'),
  systemAnnouncement('system_announcement'),
  promotionAvailable('promotion_available'),
  reviewRequest('review_request');

  const NotificationType(this.value);
  final String value;
}

enum NotificationPriority {
  low('low'),
  normal('normal'),
  high('high'),
  urgent('urgent');

  const NotificationPriority(this.value);
  final String value;
}

enum NotificationChannel {
  inApp('in_app'),
  email('email'),
  push('push'),
  sms('sms');

  const NotificationChannel(this.value);
  final String value;
}

// Extension methods for AppNotification
extension AppNotificationExtensions on AppNotification {
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  
  bool get isScheduled => scheduledAt.isAfter(DateTime.now());
  
  bool get isActive => !isExpired && !isScheduled;
  
  bool get isHighPriority => priority == 'high' || priority == 'urgent';
  
  bool get isUrgent => priority == 'urgent';
  
  String get priorityIcon {
    switch (priority) {
      case 'urgent':
        return '🚨';
      case 'high':
        return '⚠️';
      case 'normal':
        return 'ℹ️';
      case 'low':
        return '💬';
      default:
        return 'ℹ️';
    }
  }
  
  String get typeIcon {
    switch (type) {
      case 'order_created':
      case 'order_updated':
      case 'order_confirmed':
        return '📋';
      case 'order_preparing':
        return '👨‍🍳';
      case 'order_ready':
        return '✅';
      case 'order_out_for_delivery':
        return '🚚';
      case 'order_delivered':
        return '📦';
      case 'order_cancelled':
        return '❌';
      case 'payment_received':
        return '💰';
      case 'payment_failed':
        return '💳';
      case 'driver_assigned':
        return '🏍️';
      case 'driver_location_update':
        return '📍';
      case 'account_verified':
        return '✅';
      case 'role_changed':
        return '👤';
      case 'invitation_received':
        return '📧';
      case 'system_announcement':
        return '📢';
      case 'promotion_available':
        return '🎉';
      case 'review_request':
        return '⭐';
      default:
        return '📱';
    }
  }
  
  String get categoryDisplayName {
    switch (category) {
      case 'order':
        return 'Orders';
      case 'payment':
        return 'Payments';
      case 'account':
        return 'Account';
      case 'system':
        return 'System';
      case 'promotion':
        return 'Promotions';
      default:
        return 'General';
    }
  }
  
  Duration get age => DateTime.now().difference(createdAt);
  
  String get ageText {
    final duration = age;
    if (duration.inDays > 0) {
      return '${duration.inDays}d ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  bool get hasAction => actionUrl != null || actionData.isNotEmpty;
}

// Extension methods for NotificationCounts
extension NotificationCountsExtensions on NotificationCounts {
  bool get hasUnread => unreadCount > 0;
  
  bool get hasHighPriority => highPriorityUnread > 0;
  
  bool get hasUrgent => urgentPriorityUnread > 0;
  
  String get badgeText {
    if (urgentPriorityUnread > 0) return urgentPriorityUnread.toString();
    if (highPriorityUnread > 0) return highPriorityUnread.toString();
    if (unreadCount > 99) return '99+';
    if (unreadCount > 0) return unreadCount.toString();
    return '';
  }
}

// Extension methods for NotificationPreferences
extension NotificationPreferencesExtensions on NotificationPreferences {
  bool get hasQuietHours => quietHoursStart != null && quietHoursEnd != null;
  
  bool get isInQuietHours {
    if (!hasQuietHours) return false;
    
    final now = DateTime.now();
    final start = DateTime.parse('${now.toIso8601String().split('T')[0]}T$quietHoursStart:00');
    final end = DateTime.parse('${now.toIso8601String().split('T')[0]}T$quietHoursEnd:00');
    
    if (start.isBefore(end)) {
      return now.isAfter(start) && now.isBefore(end);
    } else {
      // Quiet hours span midnight
      return now.isAfter(start) || now.isBefore(end);
    }
  }
  
  List<String> get enabledChannels {
    final channels = <String>[];
    if (inAppEnabled) channels.add('in_app');
    if (emailEnabled) channels.add('email');
    if (pushEnabled) channels.add('push');
    if (smsEnabled) channels.add('sms');
    return channels;
  }
}
