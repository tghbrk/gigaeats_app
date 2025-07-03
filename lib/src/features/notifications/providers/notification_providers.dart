import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/notification_models.dart';
import '../data/repositories/notification_repository.dart';
import '../data/services/realtime_notification_service.dart';
import '../../auth/presentation/providers/auth_provider.dart';

// Repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

// Realtime service provider
final realtimeNotificationServiceProvider = Provider<RealtimeNotificationService>((ref) {
  return RealtimeNotificationService();
});

// Notification counts provider
final notificationCountsProvider = StreamProvider<NotificationCounts>((ref) {
  final service = ref.watch(realtimeNotificationServiceProvider);
  return service.countsStream;
});

// Real-time notification stream provider
final notificationStreamProvider = StreamProvider<AppNotification>((ref) {
  final service = ref.watch(realtimeNotificationServiceProvider);
  return service.notificationStream;
});

// User notifications provider with pagination
final userNotificationsProvider = FutureProvider.family<List<AppNotification>, NotificationParams>((ref, params) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUserNotifications(
    userId: params.userId,
    limit: params.limit,
    offset: params.offset,
    unreadOnly: params.unreadOnly,
    type: params.type,
    priority: params.priority,
    category: params.category,
  );
});

// Notification preferences provider
final notificationPreferencesProvider = FutureProvider.family<NotificationPreferences?, String>((ref, userId) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUserPreferences(userId);
});

// Notification templates provider
final notificationTemplatesProvider = FutureProvider<List<NotificationTemplate>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotificationTemplates();
});

// Notification service initialization provider
final notificationServiceInitProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authStateProvider);
  final service = ref.watch(realtimeNotificationServiceProvider);

  if (authState.status == AuthStatus.authenticated && authState.user != null) {
    final user = authState.user!;
    // Get user role from the user object
    final userRole = user.role.value; // Use the role from the User object

    await service.initialize(
      userId: user.id,
      userRole: userRole,
    );
    return true;
  }

  return false;
});

// Notification actions provider
final notificationActionsProvider = Provider<NotificationActions>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final service = ref.watch(realtimeNotificationServiceProvider);
  
  return NotificationActions(repository, service);
});

// Parameters class for notifications
class NotificationParams {
  final String? userId;
  final int limit;
  final int offset;
  final bool unreadOnly;
  final String? type;
  final String? priority;
  final String? category;

  const NotificationParams({
    this.userId,
    this.limit = 20,
    this.offset = 0,
    this.unreadOnly = false,
    this.type,
    this.priority,
    this.category,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          limit == other.limit &&
          offset == other.offset &&
          unreadOnly == other.unreadOnly &&
          type == other.type &&
          priority == other.priority &&
          category == other.category;

  @override
  int get hashCode =>
      userId.hashCode ^
      limit.hashCode ^
      offset.hashCode ^
      unreadOnly.hashCode ^
      type.hashCode ^
      priority.hashCode ^
      category.hashCode;
}

// Actions class for notification operations
class NotificationActions {
  final NotificationRepository _repository;
  final RealtimeNotificationService _service;

  NotificationActions(this._repository, this._service);

  // Mark notification as read
  Future<bool> markAsRead(String notificationId, {String? userId}) async {
    try {
      final success = await _repository.markAsRead(notificationId, userId: userId);
      if (success) {
        // Also mark in service for immediate UI update
        await _service.markAsRead(notificationId);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // Mark all notifications as read
  Future<int> markAllAsRead({String? userId}) async {
    try {
      final count = await _repository.markAllAsRead(userId: userId);
      if (count > 0) {
        // Also mark in service for immediate UI update
        await _service.markAllAsRead();
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  // Create notification from template
  Future<String?> createFromTemplate({
    required String templateKey,
    String? userId,
    List<String>? roleFilter,
    bool isBroadcast = false,
    Map<String, dynamic> variables = const {},
    String? relatedEntityType,
    String? relatedEntityId,
    String? createdBy,
  }) async {
    try {
      return await _repository.createNotificationFromTemplate(
        templateKey: templateKey,
        userId: userId,
        roleFilter: roleFilter,
        isBroadcast: isBroadcast,
        variables: variables,
        relatedEntityType: relatedEntityType,
        relatedEntityId: relatedEntityId,
        createdBy: createdBy,
      );
    } catch (e) {
      return null;
    }
  }

  // Create custom notification
  Future<String?> createCustom({
    String? userId,
    List<String>? roleFilter,
    bool isBroadcast = false,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic> richContent = const {},
    String? actionUrl,
    Map<String, dynamic> actionData = const {},
    String priority = 'normal',
    String category = 'general',
    List<String> tags = const [],
    List<String> channels = const ['in_app'],
    DateTime? expiresAt,
    DateTime? scheduledAt,
    String? relatedEntityType,
    String? relatedEntityId,
    String? createdBy,
  }) async {
    try {
      return await _repository.createNotification(
        userId: userId,
        roleFilter: roleFilter,
        isBroadcast: isBroadcast,
        type: type,
        title: title,
        message: message,
        richContent: richContent,
        actionUrl: actionUrl,
        actionData: actionData,
        priority: priority,
        category: category,
        tags: tags,
        channels: channels,
        expiresAt: expiresAt,
        scheduledAt: scheduledAt,
        relatedEntityType: relatedEntityType,
        relatedEntityId: relatedEntityId,
        createdBy: createdBy,
      );
    } catch (e) {
      return null;
    }
  }

  // Update user preferences
  Future<NotificationPreferences?> updatePreferences({
    required String userId,
    bool? inAppEnabled,
    bool? emailEnabled,
    bool? pushEnabled,
    bool? smsEnabled,
    bool? orderNotifications,
    bool? paymentNotifications,
    bool? accountNotifications,
    bool? systemNotifications,
    bool? promotionNotifications,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? timezone,
    int? maxNotificationsPerHour,
    int? maxNotificationsPerDay,
  }) async {
    try {
      return await _repository.updateUserPreferences(
        userId: userId,
        inAppEnabled: inAppEnabled,
        emailEnabled: emailEnabled,
        pushEnabled: pushEnabled,
        smsEnabled: smsEnabled,
        orderNotifications: orderNotifications,
        paymentNotifications: paymentNotifications,
        accountNotifications: accountNotifications,
        systemNotifications: systemNotifications,
        promotionNotifications: promotionNotifications,
        quietHoursStart: quietHoursStart,
        quietHoursEnd: quietHoursEnd,
        timezone: timezone,
        maxNotificationsPerHour: maxNotificationsPerHour,
        maxNotificationsPerDay: maxNotificationsPerDay,
      );
    } catch (e) {
      return null;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      return await _repository.deleteNotification(notificationId);
    } catch (e) {
      return false;
    }
  }

  // Cleanup expired notifications
  Future<int> cleanupExpired() async {
    try {
      return await _repository.cleanupExpiredNotifications();
    } catch (e) {
      return 0;
    }
  }
}
