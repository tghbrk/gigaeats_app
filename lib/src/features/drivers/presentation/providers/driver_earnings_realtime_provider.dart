import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/driver_earnings.dart';
import '../../data/services/driver_earnings_service.dart';
import '../../../../core/services/enhanced_supabase_connection_manager.dart';
import '../../../../core/services/app_lifecycle_service.dart';

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

/// Enhanced real-time earnings notifications state with connection health
class EarningsNotificationsState {
  final List<EarningsNotification> notifications;
  final bool isListening;
  final String? error;
  final int unreadCount;
  final DateTime? lastUpdate;
  final ConnectionHealth? connectionHealth;

  const EarningsNotificationsState({
    this.notifications = const [],
    this.isListening = false,
    this.error,
    this.unreadCount = 0,
    this.lastUpdate,
    this.connectionHealth,
  });

  EarningsNotificationsState copyWith({
    List<EarningsNotification>? notifications,
    bool? isListening,
    String? error,
    int? unreadCount,
    DateTime? lastUpdate,
    ConnectionHealth? connectionHealth,
  }) {
    return EarningsNotificationsState(
      notifications: notifications ?? this.notifications,
      isListening: isListening ?? this.isListening,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      connectionHealth: connectionHealth ?? this.connectionHealth,
    );
  }
}

/// Enhanced real-time earnings notifications provider with robust connection management
class DriverEarningsRealtimeNotifier extends StateNotifier<EarningsNotificationsState> {
  final DriverEarningsService _earningsService;
  final EnhancedSupabaseConnectionManager _connectionManager;
  final AppLifecycleService _lifecycleService;
  final String _driverId;

  String? _subscriptionId;
  Timer? _cleanupTimer;
  Timer? _refreshRateLimitTimer;
  StreamSubscription<ConnectionHealth>? _connectionHealthSubscription;
  StreamSubscription<AppLifecycleEvent>? _lifecycleSubscription;

  // Maximum notifications to keep in memory
  static const int _maxNotifications = 50;

  // Notification cleanup interval (remove old notifications)
  static const Duration _cleanupInterval = Duration(hours: 1);

  // Rate limiting for refresh operations
  static const Duration _minRefreshInterval = Duration(seconds: 30);
  static const Duration _backgroundRefreshInterval = Duration(minutes: 2);
  static const Duration _activeRefreshInterval = Duration(seconds: 45);

  // Refresh state tracking
  DateTime? _lastRefreshTime;
  DateTime? _lastConnectionRestoreTime;
  bool _isRefreshInProgress = false;
  int _consecutiveRefreshCount = 0;
  static const int _maxConsecutiveRefreshes = 3;

  DriverEarningsRealtimeNotifier({
    required DriverEarningsService earningsService,
    required String driverId,
    EnhancedSupabaseConnectionManager? connectionManager,
    AppLifecycleService? lifecycleService,
  })  : _earningsService = earningsService,
        _connectionManager = connectionManager ?? EnhancedSupabaseConnectionManager(),
        _lifecycleService = lifecycleService ?? AppLifecycleService(),
        _driverId = driverId,
        super(const EarningsNotificationsState()) {
    _initializeEnhancedRealtimeSubscription();
    _startCleanupTimer();
    _setupConnectionHealthMonitoring();
    _setupLifecycleMonitoring();
  }

  /// Initialize enhanced real-time subscription for earnings updates
  Future<void> _initializeEnhancedRealtimeSubscription() async {
    debugPrint('🔗 [EARNINGS-REALTIME] Initializing enhanced real-time subscription for driver: $_driverId');

    try {
      state = state.copyWith(isListening: true, error: null);

      // Ensure connection manager is initialized
      await _connectionManager.initialize();

      // Create subscription configuration
      final config = SubscriptionConfig(
        id: 'driver_earnings_$_driverId',
        table: 'driver_earnings',
        filter: 'driver_id=eq.$_driverId',
        onData: _handleEarningsUpdate,
        onError: _handleSubscriptionError,
        autoReconnect: true,
        reconnectDelay: const Duration(seconds: 3),
        maxReconnectAttempts: 15,
      );

      // Subscribe using enhanced connection manager
      _subscriptionId = await _connectionManager.subscribe(config);

      debugPrint('✅ [EARNINGS-REALTIME] Enhanced real-time subscription established: $_subscriptionId');
    } catch (e) {
      debugPrint('❌ [EARNINGS-REALTIME] Error initializing enhanced subscription: $e');
      state = state.copyWith(
        isListening: false,
        error: 'Failed to initialize enhanced real-time notifications: $e',
      );
    }
  }

  /// Setup connection health monitoring with intelligent refresh logic
  void _setupConnectionHealthMonitoring() {
    debugPrint('📊 [EARNINGS-REALTIME] Setting up connection health monitoring with rate limiting');

    _connectionHealthSubscription = _connectionManager.connectionHealthStream.listen(
      (health) {
        debugPrint('📊 [EARNINGS-REALTIME] Connection health update: ${health.state.name}');

        // Update state based on connection health
        state = state.copyWith(
          isListening: health.state == ConnectionState.connected,
          error: health.lastError,
          connectionHealth: health,
        );

        // Handle specific connection states with intelligent refresh logic
        switch (health.state) {
          case ConnectionState.connected:
            _handleConnectionRestoredWithRateLimit();
            break;
          case ConnectionState.failed:
            _handleConnectionFailed(health.lastError);
            break;
          case ConnectionState.reconnecting:
            _handleReconnecting();
            break;
          default:
            break;
        }
      },
      onError: (error) {
        debugPrint('❌ [EARNINGS-REALTIME] Connection health monitoring error: $error');
      },
    );
  }

  /// Setup app lifecycle monitoring
  void _setupLifecycleMonitoring() {
    debugPrint('📱 [EARNINGS-REALTIME] Setting up app lifecycle monitoring');

    _lifecycleSubscription = _lifecycleService.lifecycleEventStream.listen(
      (event) {
        debugPrint('📱 [EARNINGS-REALTIME] App lifecycle event: ${event.name}');

        switch (event) {
          case AppLifecycleEvent.resumed:
            _handleAppResumed();
            break;
          case AppLifecycleEvent.paused:
            _handleAppPaused();
            break;
          default:
            break;
        }
      },
      onError: (error) {
        debugPrint('❌ [EARNINGS-REALTIME] Lifecycle monitoring error: $error');
      },
    );
  }

  /// Handle earnings updates from real-time subscription
  Future<void> _handleEarningsUpdate(List<Map<String, dynamic>> data) async {
    debugPrint('📨 [EARNINGS-REALTIME] Received earnings update with ${data.length} records');

    try {
      final notifications = <EarningsNotification>[];

      for (final record in data) {
        final notification = await _createNotificationFromEarningsRecord(record);
        if (notification != null) {
          notifications.add(notification);
        }
      }

      if (notifications.isNotEmpty) {
        _addNotifications(notifications);
      }

      // Update last update timestamp
      state = state.copyWith(lastUpdate: DateTime.now());
    } catch (e) {
      debugPrint('❌ [EARNINGS-REALTIME] Error processing earnings update: $e');
      state = state.copyWith(error: 'Error processing earnings update: $e');
    }
  }

  /// Handle connection restored with intelligent rate limiting
  void _handleConnectionRestoredWithRateLimit() {
    final now = DateTime.now();
    debugPrint('✅ [EARNINGS-REALTIME] Connection restored at ${now.toIso8601String()}');

    // Check if we recently handled a connection restore to prevent loops
    if (_lastConnectionRestoreTime != null) {
      final timeSinceLastRestore = now.difference(_lastConnectionRestoreTime!);
      if (timeSinceLastRestore < _minRefreshInterval) {
        debugPrint('⏸️ [EARNINGS-REALTIME] Skipping refresh - too soon since last connection restore (${timeSinceLastRestore.inSeconds}s < ${_minRefreshInterval.inSeconds}s)');
        return;
      }
    }

    // Check if refresh is already in progress
    if (_isRefreshInProgress) {
      debugPrint('⏸️ [EARNINGS-REALTIME] Skipping refresh - already in progress');
      return;
    }

    // Check consecutive refresh count to prevent excessive refreshing
    if (_consecutiveRefreshCount >= _maxConsecutiveRefreshes) {
      debugPrint('⏸️ [EARNINGS-REALTIME] Skipping refresh - max consecutive refreshes reached ($_consecutiveRefreshCount)');
      _resetRefreshCountAfterDelay();
      return;
    }

    _lastConnectionRestoreTime = now;
    _consecutiveRefreshCount++;

    // Schedule refresh with appropriate delay based on app state
    final refreshDelay = _getOptimalRefreshDelay();
    debugPrint('⏰ [EARNINGS-REALTIME] Scheduling refresh in ${refreshDelay.inSeconds}s (attempt $_consecutiveRefreshCount/$_maxConsecutiveRefreshes)');

    Future.delayed(refreshDelay, () {
      if (mounted && !_isRefreshInProgress) {
        _refreshWithRateLimit();
      }
    });
  }

  /// Handle connection failed
  void _handleConnectionFailed(String? error) {
    debugPrint('❌ [EARNINGS-REALTIME] Connection failed: $error');

    // Update state with error information
    state = state.copyWith(
      isListening: false,
      error: 'Connection failed: ${error ?? "Unknown error"}',
    );
  }

  /// Handle reconnecting state
  void _handleReconnecting() {
    debugPrint('🔄 [EARNINGS-REALTIME] Reconnecting...');

    // Update state to show reconnecting status
    state = state.copyWith(
      isListening: false,
      error: 'Reconnecting to real-time updates...',
    );
  }

  /// Handle app resumed with intelligent refresh logic
  void _handleAppResumed() {
    final now = DateTime.now();
    debugPrint('📱 [EARNINGS-REALTIME] App resumed at ${now.toIso8601String()}');

    // Check if we need to refresh data after being backgrounded
    if (_lifecycleService.wasRecentlyBackgrounded) {
      debugPrint('🔄 [EARNINGS-REALTIME] App was backgrounded, checking if refresh is needed');

      // Check if we recently refreshed to prevent unnecessary calls
      if (_lastRefreshTime != null) {
        final timeSinceLastRefresh = now.difference(_lastRefreshTime!);
        if (timeSinceLastRefresh < _backgroundRefreshInterval) {
          debugPrint('⏸️ [EARNINGS-REALTIME] Skipping background refresh - too recent (${timeSinceLastRefresh.inMinutes}m < ${_backgroundRefreshInterval.inMinutes}m)');
          return;
        }
      }

      // Reset consecutive refresh count on app resume
      _consecutiveRefreshCount = 0;

      // Schedule background refresh with longer delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isRefreshInProgress) {
          _refreshWithRateLimit();
        }
      });
    } else {
      debugPrint('📱 [EARNINGS-REALTIME] App resumed but was not recently backgrounded, no refresh needed');
    }
  }

  /// Handle app paused
  void _handleAppPaused() {
    debugPrint('📱 [EARNINGS-REALTIME] App paused');

    // The connection manager will handle subscription suspension
    // We just log the event for debugging
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
  Future<EarningsNotification?> _createNotificationFromEarningsRecord(Map<String, dynamic> record) async {
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

      // Check if this notification already exists and preserve its read status
      final notificationId = record['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      final existingNotification = state.notifications.firstWhere(
        (n) => n.id == notificationId,
        orElse: () => EarningsNotification(
          id: '',
          driverId: '',
          amount: 0,
          netAmount: 0,
          status: EarningsStatus.pending,
          type: EarningsNotificationType.earningsUpdate,
          title: '',
          message: '',
          timestamp: DateTime.now(),
        ),
      );

      // Determine read status: check existing notification first, then load from storage
      bool isRead = false;
      if (existingNotification.id.isNotEmpty) {
        // Use existing notification's read status
        isRead = existingNotification.isRead;
      } else {
        // Load from persistent storage for new notifications
        isRead = await _loadNotificationReadStatus(notificationId);
      }

      return EarningsNotification(
        id: notificationId,
        driverId: record['driver_id'] ?? _driverId,
        orderId: record['order_id'],
        amount: grossEarnings,
        netAmount: netEarnings,
        status: status,
        type: type,
        title: title,
        message: message,
        timestamp: DateTime.tryParse(record['updated_at'] ?? '') ?? DateTime.now(),
        isRead: isRead, // Use determined read status
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
        // Update existing notification but preserve read status
        final existingNotification = currentNotifications[existingIndex];
        final updatedNotification = notification.copyWith(
          isRead: existingNotification.isRead, // Preserve read status
        );
        currentNotifications[existingIndex] = updatedNotification;
        debugPrint('📝 [EARNINGS-REALTIME] Updated existing notification ${notification.id}, preserving isRead: ${existingNotification.isRead}');
      } else {
        // Add new notification (will be unread by default)
        currentNotifications.insert(0, notification);
        debugPrint('➕ [EARNINGS-REALTIME] Added new notification ${notification.id}');
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

    debugPrint('✅ [EARNINGS-REALTIME] Final state: ${currentNotifications.length} total, $unreadCount unread (processed ${newNotifications.length} new notifications)');
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    debugPrint('📖 [EARNINGS-REALTIME] Marking notification $notificationId as read');

    final previousUnreadCount = state.unreadCount;
    bool notificationFound = false;

    final updatedNotifications = state.notifications.map((notification) {
      if (notification.id == notificationId) {
        notificationFound = true;
        if (!notification.isRead) {
          debugPrint('📖 [EARNINGS-REALTIME] Notification $notificationId was unread, marking as read');
          return notification.copyWith(isRead: true);
        } else {
          debugPrint('📖 [EARNINGS-REALTIME] Notification $notificationId was already read');
          return notification;
        }
      }
      return notification;
    }).toList();

    if (!notificationFound) {
      debugPrint('⚠️ [EARNINGS-REALTIME] Notification $notificationId not found in current notifications');
      return;
    }

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );

    // Persist read status locally
    _persistNotificationReadStatus(notificationId, true);

    debugPrint('✅ [EARNINGS-REALTIME] Marked notification $notificationId as read. Unread count: $previousUnreadCount → $unreadCount');
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    final previousUnreadCount = state.unreadCount;
    debugPrint('📖 [EARNINGS-REALTIME] Marking all $previousUnreadCount unread notifications as read');

    final updatedNotifications = state.notifications.map((notification) {
      return notification.copyWith(isRead: true);
    }).toList();

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: 0,
    );

    // Persist read status for all notifications
    for (final notification in updatedNotifications) {
      _persistNotificationReadStatus(notification.id, true);
    }

    debugPrint('✅ [EARNINGS-REALTIME] Marked all notifications as read. Unread count: $previousUnreadCount → 0');
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

  /// Reconnect to real-time subscription (legacy method - now handled by connection manager)
  void _reconnect() {
    debugPrint('🔄 [EARNINGS-REALTIME] Legacy reconnect called - delegating to connection manager');

    // Delegate to connection manager
    _connectionManager.reconnectAll();
  }

  /// Manually refresh notifications with enhanced logging and rate limiting
  Future<void> refresh() async {
    // Delegate to rate-limited refresh method
    await _refreshWithRateLimit();
  }

  /// Rate-limited refresh implementation with intelligent optimization
  Future<void> _refreshWithRateLimit() async {
    final now = DateTime.now();

    // Check if refresh is already in progress
    if (_isRefreshInProgress) {
      debugPrint('⏸️ [EARNINGS-REALTIME] Refresh already in progress, skipping');
      return;
    }

    // Check rate limiting
    if (_lastRefreshTime != null) {
      final timeSinceLastRefresh = now.difference(_lastRefreshTime!);
      final minInterval = _getOptimalRefreshDelay();

      if (timeSinceLastRefresh < minInterval) {
        debugPrint('⏸️ [EARNINGS-REALTIME] Rate limited - too soon since last refresh (${timeSinceLastRefresh.inSeconds}s < ${minInterval.inSeconds}s)');
        return;
      }
    }

    _isRefreshInProgress = true;
    _lastRefreshTime = now;

    debugPrint('🔄 [EARNINGS-REALTIME] Rate-limited refresh started for driver: $_driverId (attempt $_consecutiveRefreshCount)');

    final startTime = DateTime.now();

    try {
      // Skip connection health check to prevent feedback loop
      // The real-time subscription will handle connection issues
      debugPrint('📊 [EARNINGS-REALTIME] Skipping connection health check to prevent refresh loops');

      // Get recent earnings to create notifications
      debugPrint('📊 [EARNINGS-REALTIME] Fetching recent earnings from service');
      final recentEarnings = await _earningsService.getDriverEarnings(
        _driverId,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        limit: 10,
        useCache: false,
      );

      debugPrint('📊 [EARNINGS-REALTIME] Retrieved ${recentEarnings.length} earnings records');

      final notifications = <EarningsNotification>[];
      for (final earning in recentEarnings) {
        final notification = await _createNotificationFromEarningsRecord({
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
        if (notification != null) {
          notifications.add(notification);
        }
      }

      if (notifications.isNotEmpty) {
        debugPrint('📨 [EARNINGS-REALTIME] Adding ${notifications.length} notifications');
        _addNotifications(notifications);
      } else {
        debugPrint('📭 [EARNINGS-REALTIME] No new notifications to add');
      }

      final duration = DateTime.now().difference(startTime);
      state = state.copyWith(
        lastUpdate: DateTime.now(),
        error: null,
      );

      debugPrint('✅ [EARNINGS-REALTIME] Rate-limited refresh completed in ${duration.inMilliseconds}ms with ${notifications.length} notifications');

      // Reset consecutive refresh count on successful refresh
      _consecutiveRefreshCount = 0;
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('❌ [EARNINGS-REALTIME] Rate-limited refresh failed after ${duration.inMilliseconds}ms: $e');
      state = state.copyWith(error: 'Failed to refresh notifications: $e');

      // Increment consecutive refresh count on failure
      _consecutiveRefreshCount++;
    } finally {
      _isRefreshInProgress = false;
    }
  }

  /// Get optimal refresh delay based on app state and driver activity
  Duration _getOptimalRefreshDelay() {
    // Use longer intervals for background or inactive states
    if (_lifecycleService.wasRecentlyBackgrounded) {
      return _backgroundRefreshInterval;
    }

    // Use shorter intervals for active states
    return _activeRefreshInterval;
  }

  /// Reset consecutive refresh count after a delay to allow recovery
  void _resetRefreshCountAfterDelay() {
    _refreshRateLimitTimer?.cancel();
    _refreshRateLimitTimer = Timer(const Duration(minutes: 5), () {
      debugPrint('🔄 [EARNINGS-REALTIME] Resetting consecutive refresh count after cooldown period');
      _consecutiveRefreshCount = 0;
    });
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

  /// Persist notification read status to local storage
  Future<void> _persistNotificationReadStatus(String notificationId, bool isRead) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'earnings_notification_read_${_driverId}_$notificationId';
      await prefs.setBool(key, isRead);
      debugPrint('💾 [EARNINGS-REALTIME] Persisted read status for notification $notificationId: $isRead');
    } catch (e) {
      debugPrint('❌ [EARNINGS-REALTIME] Failed to persist read status for notification $notificationId: $e');
    }
  }

  /// Load notification read status from local storage
  Future<bool> _loadNotificationReadStatus(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'earnings_notification_read_${_driverId}_$notificationId';
      final isRead = prefs.getBool(key) ?? false;
      return isRead;
    } catch (e) {
      debugPrint('❌ [EARNINGS-REALTIME] Failed to load read status for notification $notificationId: $e');
      return false;
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ [EARNINGS-REALTIME] Disposing enhanced earnings realtime notifier');

    // Cancel connection health monitoring
    _connectionHealthSubscription?.cancel();

    // Cancel lifecycle monitoring
    _lifecycleSubscription?.cancel();

    // Unsubscribe from connection manager
    if (_subscriptionId != null) {
      _connectionManager.unsubscribe(_subscriptionId!);
    }

    // Cancel cleanup timer
    _cleanupTimer?.cancel();

    // Cancel refresh rate limit timer
    _refreshRateLimitTimer?.cancel();

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
