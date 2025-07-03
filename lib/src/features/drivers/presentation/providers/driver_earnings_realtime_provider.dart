import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/driver_earnings.dart';
import '../../data/services/driver_earnings_service.dart';

/// Real-time earnings notification data model
class EarningsNotification {
  final String id;
  final String driverId;
  final String? orderId;
  final double amount;
  final double netAmount;
  final EarningsStatus status;
  final EarningsNotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final bool isRead;

  const EarningsNotification({
    required this.id,
    required this.driverId,
    this.orderId,
    required this.amount,
    required this.netAmount,
    required this.status,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.metadata,
    this.isRead = false,
  });

  EarningsNotification copyWith({
    String? id,
    String? driverId,
    String? orderId,
    double? amount,
    double? netAmount,
    EarningsStatus? status,
    EarningsNotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    bool? isRead,
  }) {
    return EarningsNotification(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      orderId: orderId ?? this.orderId,
      amount: amount ?? this.amount,
      netAmount: netAmount ?? this.netAmount,
      status: status ?? this.status,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
    );
  }

  factory EarningsNotification.fromJson(Map<String, dynamic> json) {
    return EarningsNotification(
      id: json['earnings_id'] ?? json['id'] ?? '',
      driverId: json['driver_id'] ?? '',
      orderId: json['order_id'],
      amount: (json['gross_earnings'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['net_earnings'] as num?)?.toDouble() ?? 0.0,
      status: EarningsStatus.fromString(json['payment_status'] ?? 'pending'),
      type: EarningsNotificationType.fromString(json['type'] ?? 'earnings_update'),
      title: json['title'] ?? 'Earnings Update',
      message: json['message'] ?? 'Your earnings have been updated',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      isRead: json['is_read'] ?? false,
    );
  }
}

/// Types of earnings notifications
enum EarningsNotificationType {
  earningsUpdate('earnings_update'),
  paymentReceived('payment_received'),
  bonusEarned('bonus_earned'),
  commissionUpdate('commission_update'),
  paymentPending('payment_pending'),
  paymentFailed('payment_failed');

  const EarningsNotificationType(this.value);
  final String value;

  static EarningsNotificationType fromString(String value) {
    return EarningsNotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => EarningsNotificationType.earningsUpdate,
    );
  }

  String get displayName {
    switch (this) {
      case EarningsNotificationType.earningsUpdate:
        return 'Earnings Update';
      case EarningsNotificationType.paymentReceived:
        return 'Payment Received';
      case EarningsNotificationType.bonusEarned:
        return 'Bonus Earned';
      case EarningsNotificationType.commissionUpdate:
        return 'Commission Update';
      case EarningsNotificationType.paymentPending:
        return 'Payment Pending';
      case EarningsNotificationType.paymentFailed:
        return 'Payment Failed';
    }
  }
}

/// Real-time earnings notifications state
class EarningsNotificationsState {
  final List<EarningsNotification> notifications;
  final bool isListening;
  final String? error;
  final int unreadCount;
  final DateTime? lastUpdate;

  const EarningsNotificationsState({
    this.notifications = const [],
    this.isListening = false,
    this.error,
    this.unreadCount = 0,
    this.lastUpdate,
  });

  EarningsNotificationsState copyWith({
    List<EarningsNotification>? notifications,
    bool? isListening,
    String? error,
    int? unreadCount,
    DateTime? lastUpdate,
  }) {
    return EarningsNotificationsState(
      notifications: notifications ?? this.notifications,
      isListening: isListening ?? this.isListening,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

/// Real-time earnings notifications provider
class DriverEarningsRealtimeNotifier extends StateNotifier<EarningsNotificationsState> {
  final DriverEarningsService _earningsService;
  final SupabaseClient _supabase;
  final String _driverId;
  
  StreamSubscription<List<Map<String, dynamic>>>? _earningsSubscription;
  Timer? _cleanupTimer;
  
  // Maximum notifications to keep in memory
  static const int _maxNotifications = 50;
  
  // Notification cleanup interval (remove old notifications)
  static const Duration _cleanupInterval = Duration(hours: 1);

  DriverEarningsRealtimeNotifier({
    required DriverEarningsService earningsService,
    required String driverId,
    SupabaseClient? supabaseClient,
  })  : _earningsService = earningsService,
        _supabase = supabaseClient ?? Supabase.instance.client,
        _driverId = driverId,
        super(const EarningsNotificationsState()) {
    _initializeRealtimeSubscription();
    _startCleanupTimer();
  }

  /// Initialize real-time subscription for earnings updates
  void _initializeRealtimeSubscription() {
    debugPrint('DriverEarningsRealtimeNotifier: Initializing real-time subscription for driver: $_driverId');
    
    try {
      state = state.copyWith(isListening: true, error: null);
      
      // Subscribe to driver_earnings table changes for this driver
      _earningsSubscription = _supabase
          .from('driver_earnings')
          .stream(primaryKey: ['id'])
          .eq('driver_id', _driverId)
          .listen(
            _handleEarningsUpdate,
            onError: _handleSubscriptionError,
          );
      
      debugPrint('DriverEarningsRealtimeNotifier: Real-time subscription established');
    } catch (e) {
      debugPrint('DriverEarningsRealtimeNotifier: Error initializing subscription: $e');
      state = state.copyWith(
        isListening: false,
        error: 'Failed to initialize real-time notifications: $e',
      );
    }
  }

  /// Handle earnings updates from real-time subscription
  void _handleEarningsUpdate(List<Map<String, dynamic>> data) {
    debugPrint('DriverEarningsRealtimeNotifier: Received earnings update with ${data.length} records');
    
    try {
      final notifications = <EarningsNotification>[];
      
      for (final record in data) {
        final notification = _createNotificationFromEarningsRecord(record);
        if (notification != null) {
          notifications.add(notification);
        }
      }
      
      if (notifications.isNotEmpty) {
        _addNotifications(notifications);
      }
    } catch (e) {
      debugPrint('DriverEarningsRealtimeNotifier: Error processing earnings update: $e');
      state = state.copyWith(error: 'Error processing earnings update: $e');
    }
  }

  /// Handle subscription errors
  void _handleSubscriptionError(dynamic error) {
    debugPrint('DriverEarningsRealtimeNotifier: Subscription error: $error');
    state = state.copyWith(
      isListening: false,
      error: 'Real-time connection error: $error',
    );
    
    // Attempt to reconnect after a delay
    Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      _reconnect();
    });
  }

  /// Create notification from earnings record
  EarningsNotification? _createNotificationFromEarningsRecord(Map<String, dynamic> record) {
    try {
      final netEarnings = (record['net_earnings'] as num?)?.toDouble() ?? 0.0;
      final grossEarnings = (record['gross_earnings'] as num?)?.toDouble() ?? 0.0;
      final status = EarningsStatus.fromString(record['payment_status'] ?? 'pending');
      
      // Determine notification type and message based on status and amount
      EarningsNotificationType type;
      String title;
      String message;
      
      switch (status) {
        case EarningsStatus.confirmed:
          type = EarningsNotificationType.earningsUpdate;
          title = 'Earnings Confirmed';
          message = 'You earned RM ${netEarnings.toStringAsFixed(2)} from your recent delivery';
          break;
        case EarningsStatus.paid:
          type = EarningsNotificationType.paymentReceived;
          title = 'Payment Received';
          message = 'RM ${netEarnings.toStringAsFixed(2)} has been paid to your account';
          break;
        case EarningsStatus.pending:
          type = EarningsNotificationType.paymentPending;
          title = 'Payment Pending';
          message = 'Your earnings of RM ${netEarnings.toStringAsFixed(2)} are being processed';
          break;
        case EarningsStatus.disputed:
          type = EarningsNotificationType.paymentFailed;
          title = 'Payment Issue';
          message = 'There\'s an issue with your payment of RM ${netEarnings.toStringAsFixed(2)}';
          break;
        case EarningsStatus.cancelled:
          type = EarningsNotificationType.earningsUpdate;
          title = 'Earnings Cancelled';
          message = 'Your earnings of RM ${netEarnings.toStringAsFixed(2)} have been cancelled';
          break;
      }
      
      return EarningsNotification(
        id: record['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        driverId: record['driver_id'] ?? _driverId,
        orderId: record['order_id'],
        amount: grossEarnings,
        netAmount: netEarnings,
        status: status,
        type: type,
        title: title,
        message: message,
        timestamp: DateTime.tryParse(record['updated_at'] ?? '') ?? DateTime.now(),
        metadata: {
          'base_commission': record['base_commission'],
          'distance_fee': record['distance_fee'],
          'time_fee': record['time_fee'],
          'bonuses': record['peak_hour_bonus'] ?? 0 + record['completion_bonus'] ?? 0 + record['rating_bonus'] ?? 0,
        },
      );
    } catch (e) {
      debugPrint('DriverEarningsRealtimeNotifier: Error creating notification: $e');
      return null;
    }
  }

  /// Add notifications to state
  void _addNotifications(List<EarningsNotification> newNotifications) {
    final currentNotifications = List<EarningsNotification>.from(state.notifications);

    // Add new notifications at the beginning (most recent first)
    for (final notification in newNotifications.reversed) {
      // Check if notification already exists
      final existingIndex = currentNotifications.indexWhere((n) => n.id == notification.id);
      if (existingIndex >= 0) {
        // Update existing notification
        currentNotifications[existingIndex] = notification;
      } else {
        // Add new notification
        currentNotifications.insert(0, notification);
      }
    }

    // Limit the number of notifications
    if (currentNotifications.length > _maxNotifications) {
      currentNotifications.removeRange(_maxNotifications, currentNotifications.length);
    }

    // Calculate unread count
    final unreadCount = currentNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: currentNotifications,
      unreadCount: unreadCount,
      lastUpdate: DateTime.now(),
    );

    debugPrint('DriverEarningsRealtimeNotifier: Added ${newNotifications.length} notifications, total: ${currentNotifications.length}, unread: $unreadCount');
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final updatedNotifications = state.notifications.map((notification) {
      if (notification.id == notificationId) {
        return notification.copyWith(isRead: true);
      }
      return notification;
    }).toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );

    debugPrint('DriverEarningsRealtimeNotifier: Marked notification $notificationId as read');
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    final updatedNotifications = state.notifications.map((notification) {
      return notification.copyWith(isRead: true);
    }).toList();

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: 0,
    );

    debugPrint('DriverEarningsRealtimeNotifier: Marked all notifications as read');
  }

  /// Clear all notifications
  void clearAllNotifications() {
    state = state.copyWith(
      notifications: [],
      unreadCount: 0,
    );

    debugPrint('DriverEarningsRealtimeNotifier: Cleared all notifications');
  }

  /// Remove old notifications (older than 7 days)
  void _cleanupOldNotifications() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    final filteredNotifications = state.notifications
        .where((notification) => notification.timestamp.isAfter(cutoffDate))
        .toList();

    if (filteredNotifications.length != state.notifications.length) {
      final unreadCount = filteredNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: filteredNotifications,
        unreadCount: unreadCount,
      );

      debugPrint('DriverEarningsRealtimeNotifier: Cleaned up old notifications, remaining: ${filteredNotifications.length}');
    }
  }

  /// Start cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _cleanupOldNotifications();
    });
  }

  /// Reconnect to real-time subscription
  void _reconnect() {
    debugPrint('DriverEarningsRealtimeNotifier: Attempting to reconnect...');

    _earningsSubscription?.cancel();
    _earningsSubscription = null;

    _initializeRealtimeSubscription();
  }

  /// Manually refresh notifications
  Future<void> refresh() async {
    debugPrint('DriverEarningsRealtimeNotifier: Manual refresh requested');

    try {
      // Get recent earnings to create notifications
      final recentEarnings = await _earningsService.getDriverEarnings(
        _driverId,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        limit: 10,
        useCache: false,
      );

      final notifications = recentEarnings.map((earning) {
        return _createNotificationFromEarningsRecord({
          'id': earning.id,
          'driver_id': earning.driverId,
          'order_id': earning.orderId,
          'gross_earnings': earning.amount,
          'net_earnings': earning.netAmount,
          'payment_status': earning.status.value,
          'updated_at': earning.updatedAt.toIso8601String(),
          'base_commission': earning.baseAmount,
          'distance_fee': 0, // These would come from the enhanced schema
          'time_fee': 0,
          'peak_hour_bonus': earning.bonusAmount,
          'completion_bonus': 0,
          'rating_bonus': 0,
        });
      }).where((n) => n != null).cast<EarningsNotification>().toList();

      if (notifications.isNotEmpty) {
        _addNotifications(notifications);
      }

      state = state.copyWith(error: null);
    } catch (e) {
      debugPrint('DriverEarningsRealtimeNotifier: Error during refresh: $e');
      state = state.copyWith(error: 'Failed to refresh notifications: $e');
    }
  }

  /// Get notifications by type
  List<EarningsNotification> getNotificationsByType(EarningsNotificationType type) {
    return state.notifications.where((n) => n.type == type).toList();
  }

  /// Get unread notifications
  List<EarningsNotification> get unreadNotifications {
    return state.notifications.where((n) => !n.isRead).toList();
  }

  /// Check if listening to real-time updates
  bool get isListening => state.isListening;

  /// Get error message if any
  String? get error => state.error;

  /// Get unread count
  int get unreadCount => state.unreadCount;

  @override
  void dispose() {
    debugPrint('DriverEarningsRealtimeNotifier: Disposing...');

    _earningsSubscription?.cancel();
    _cleanupTimer?.cancel();

    super.dispose();
  }
}

/// Provider for driver earnings real-time notifications
final driverEarningsRealtimeProvider = StateNotifierProvider.family<
    DriverEarningsRealtimeNotifier,
    EarningsNotificationsState,
    String>((ref, driverId) {
  final earningsService = ref.watch(driverEarningsServiceProvider);

  return DriverEarningsRealtimeNotifier(
    earningsService: earningsService,
    driverId: driverId,
  );
});

/// Provider for driver earnings service
final driverEarningsServiceProvider = Provider<DriverEarningsService>((ref) {
  return DriverEarningsService();
});

/// Provider for unread notifications count
final unreadEarningsNotificationsCountProvider = Provider.family<int, String>((ref, driverId) {
  final notificationsState = ref.watch(driverEarningsRealtimeProvider(driverId));
  return notificationsState.unreadCount;
});

/// Provider for latest notification
final latestEarningsNotificationProvider = Provider.family<EarningsNotification?, String>((ref, driverId) {
  final notificationsState = ref.watch(driverEarningsRealtimeProvider(driverId));
  return notificationsState.notifications.isNotEmpty ? notificationsState.notifications.first : null;
});

/// Provider for notifications by type
final earningsNotificationsByTypeProvider = Provider.family<List<EarningsNotification>, ({String driverId, EarningsNotificationType type})>((ref, params) {
  final notifier = ref.watch(driverEarningsRealtimeProvider(params.driverId).notifier);
  return notifier.getNotificationsByType(params.type);
});
