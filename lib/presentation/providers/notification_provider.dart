import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/notification.dart';
import '../../data/services/notification_service.dart';

// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Notification state
class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? errorMessage;
  final int unreadCount;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? errorMessage,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

// Notification notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;

  NotificationNotifier(this._notificationService) : super(const NotificationState()) {
    _initialize();
  }

  Future<void> refresh() async {
    await _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _notificationService.initialize();
      
      // Listen to notification updates
      _notificationService.notificationsStream.listen((notifications) {
        final unreadCount = notifications.where((n) => !n.isRead).length;
        state = state.copyWith(
          notifications: notifications,
          unreadCount: unreadCount,
          isLoading: false,
          errorMessage: null,
        );
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> markAllAsRead({String? userId}) async {
    try {
      await _notificationService.markAllAsRead(userId: userId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> archiveNotification(String notificationId) async {
    try {
      await _notificationService.archiveNotification(notificationId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  List<AppNotification> getNotificationsForUser(String userId) {
    return _notificationService.getNotificationsForUser(userId);
  }

  List<AppNotification> getUnreadNotificationsForUser(String userId) {
    return _notificationService.getUnreadNotificationsForUser(userId);
  }

  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notificationService.getNotificationsByType(type);
  }

  // Utility methods for creating notifications
  Future<void> notifyOrderStatusUpdate({
    required String orderId,
    required String orderNumber,
    required String newStatus,
    required String userId,
  }) async {
    try {
      await _notificationService.notifyOrderStatusUpdate(
        orderId: orderId,
        orderNumber: orderNumber,
        newStatus: newStatus,
        userId: userId,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> notifyNewOrder({
    required String orderId,
    required String orderNumber,
    required String customerName,
    required String vendorId,
  }) async {
    try {
      await _notificationService.notifyNewOrder(
        orderId: orderId,
        orderNumber: orderNumber,
        customerName: customerName,
        vendorId: vendorId,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> notifyPaymentReceived({
    required String orderId,
    required String orderNumber,
    required double amount,
    required String userId,
  }) async {
    try {
      await _notificationService.notifyPaymentReceived(
        orderId: orderId,
        orderNumber: orderNumber,
        amount: amount,
        userId: userId,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> notifySystemAlert({
    required String title,
    required String message,
    String? userId,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      await _notificationService.notifySystemAlert(
        title: title,
        message: message,
        userId: userId,
        priority: priority,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> notifyReminder({
    required String title,
    required String message,
    required String userId,
    DateTime? expiresAt,
  }) async {
    try {
      await _notificationService.notifyReminder(
        title: title,
        message: message,
        userId: userId,
        expiresAt: expiresAt,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

// Notification provider
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return NotificationNotifier(notificationService);
});

// New notification stream provider
final newNotificationStreamProvider = StreamProvider<AppNotification>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.newNotificationStream;
});

// Unread count provider
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.unreadCount;
});

// User-specific notifications provider
final userNotificationsProvider = Provider.family<List<AppNotification>, String>((ref, userId) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.notifications
      .where((n) => n.userId == userId && !n.isArchived)
      .toList();
});

// Unread user notifications provider
final unreadUserNotificationsProvider = Provider.family<List<AppNotification>, String>((ref, userId) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.notifications
      .where((n) => n.userId == userId && !n.isRead && !n.isArchived)
      .toList();
});

// Notifications by type provider
final notificationsByTypeProvider = Provider.family<List<AppNotification>, NotificationType>((ref, type) {
  final notificationState = ref.watch(notificationProvider);
  return notificationState.notifications
      .where((n) => n.type == type && !n.isArchived)
      .toList();
});
