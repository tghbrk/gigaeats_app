import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../notifications/data/models/notification.dart';
import '../../data/services/customer_notification_service.dart';
import '../../../../core/utils/logger.dart';

/// Provider for CustomerNotificationService
final customerNotificationServiceProvider = Provider<CustomerNotificationService>((ref) {
  return CustomerNotificationService();
});

/// State for customer notifications
class CustomerNotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const CustomerNotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  CustomerNotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return CustomerNotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Notifier for customer notifications
class CustomerNotificationNotifier extends StateNotifier<CustomerNotificationState> {
  final CustomerNotificationService _notificationService;
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLogger _logger = AppLogger();

  CustomerNotificationNotifier(this._notificationService) : super(const CustomerNotificationState()) {
    _initialize();
  }

  /// Initialize the notification system
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Initialize the notification service
      await _notificationService.initialize();
      
      // Load existing notifications
      await _loadNotifications();
      
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        error: null,
      );
      
      _logger.info('CustomerNotificationNotifier: Initialization complete');
    } catch (e) {
      _logger.error('CustomerNotificationNotifier: Initialization failed', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load notifications from Supabase
  Future<void> _loadNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('order_notifications')
          .select('*')
          .eq('recipient_id', user.id)
          .order('sent_at', ascending: false)
          .limit(50);

      final notifications = response.map<AppNotification>((data) {
        return AppNotification(
          id: data['id'],
          title: data['title'],
          message: data['message'],
          type: _parseNotificationType(data['notification_type']),
          userId: data['recipient_id'],
          orderId: data['order_id'],
          isRead: data['is_read'] ?? false,
          createdAt: DateTime.parse(data['sent_at'] ?? DateTime.now().toIso8601String()),
          readAt: data['read_at'] != null ? DateTime.parse(data['read_at']) : null,
          data: data['metadata'],
        );
      }).toList();

      final unreadCount = notifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
      );

      _logger.info('CustomerNotificationNotifier: Loaded ${notifications.length} notifications');
    } catch (e) {
      _logger.error('CustomerNotificationNotifier: Failed to load notifications', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Parse notification type from string
  NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'order_update':
        return NotificationType.orderUpdate;
      case 'new_order':
        return NotificationType.newOrder;
      case 'payment_received':
        return NotificationType.paymentReceived;
      case 'delivery_update':
        return NotificationType.orderUpdate; // TODO: Add deliveryUpdate to enum
      case 'promotion':
        return NotificationType.promotion;
      case 'system_alert':
        return NotificationType.systemAlert;
      case 'reminder':
        return NotificationType.reminder;
      default:
        return NotificationType.systemAlert;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('order_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
        return notification;
      }).toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );

      _logger.info('CustomerNotificationNotifier: Marked notification $notificationId as read');
    } catch (e) {
      _logger.error('CustomerNotificationNotifier: Failed to mark notification as read', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('order_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('recipient_id', user.id)
          .eq('is_read', false);

      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        return notification.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );

      _logger.info('CustomerNotificationNotifier: Marked all notifications as read');
    } catch (e) {
      _logger.error('CustomerNotificationNotifier: Failed to mark all notifications as read', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await _loadNotifications();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for customer notifications
final customerNotificationProvider = StateNotifierProvider<CustomerNotificationNotifier, CustomerNotificationState>((ref) {
  final notificationService = ref.watch(customerNotificationServiceProvider);
  return CustomerNotificationNotifier(notificationService);
});

/// Provider for unread notification count
final customerUnreadNotificationCountProvider = Provider<int>((ref) {
  final notificationState = ref.watch(customerNotificationProvider);
  return notificationState.unreadCount;
});

/// Provider for recent notifications (last 10)
final customerRecentNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final notificationState = ref.watch(customerNotificationProvider);
  return notificationState.notifications.take(10).toList();
});

/// Provider for order-related notifications
final customerOrderNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final notificationState = ref.watch(customerNotificationProvider);
  return notificationState.notifications
      .where((n) => n.type == NotificationType.orderUpdate) // TODO: Add deliveryUpdate support
      .toList();
});
