import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import '../models/notification_models.dart';

class RealtimeNotificationService {
  static final RealtimeNotificationService _instance = RealtimeNotificationService._internal();
  factory RealtimeNotificationService() => _instance;
  RealtimeNotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Stream controllers for real-time updates
  final StreamController<AppNotification> _notificationStreamController = 
      StreamController<AppNotification>.broadcast();
  final StreamController<NotificationCounts> _countsStreamController = 
      StreamController<NotificationCounts>.broadcast();
  
  // Subscription management
  RealtimeChannel? _notificationChannel;
  Timer? _reconnectTimer;
  Timer? _countsRefreshTimer;
  
  // Connection state
  bool _isConnected = false;
  bool _isInitialized = false;
  String? _currentUserId;
  String? _currentUserRole;
  
  // Getters for streams
  Stream<AppNotification> get notificationStream => _notificationStreamController.stream;
  Stream<NotificationCounts> get countsStream => _countsStreamController.stream;
  
  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;

  /// Initialize the notification service for a user
  Future<void> initialize({
    required String userId,
    required String userRole,
  }) async {
    try {
      log('Initializing RealtimeNotificationService for user: $userId, role: $userRole');
      
      _currentUserId = userId;
      _currentUserRole = userRole;
      
      // Disconnect any existing connections
      await disconnect();
      
      // Setup realtime subscription
      await _setupRealtimeSubscription();
      
      // Start periodic counts refresh
      _startCountsRefresh();
      
      // Load initial notification counts
      await _refreshNotificationCounts();
      
      _isInitialized = true;
      log('RealtimeNotificationService initialized successfully');
    } catch (e) {
      log('Error initializing RealtimeNotificationService: $e');
      rethrow;
    }
  }

  /// Setup realtime subscription for notifications
  Future<void> _setupRealtimeSubscription() async {
    if (_currentUserId == null) return;

    try {
      // Create channel for user-specific notifications
      _notificationChannel = _supabase.channel('notifications:$_currentUserId');
      
      // Subscribe to notifications table changes
      _notificationChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: _currentUserId!,
            ),
            callback: (payload) {
              _handleNotificationInsert(payload);
            },
          );

      // Subscribe to broadcast notifications
      _notificationChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'is_broadcast',
              value: true,
            ),
            callback: (payload) {
              _handleNotificationInsert(payload);
            },
          );

      // Subscribe to role-based notifications
      if (_currentUserRole != null) {
        _notificationChannel!
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'notifications',
              callback: (payload) {
                _handleRoleBasedNotification(payload);
              },
            );
      }

      // Subscribe to notification updates (read status changes)
      _notificationChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: _currentUserId!,
            ),
            callback: (payload) {
              _handleNotificationUpdate(payload);
            },
          );

      // Subscribe to the channel
      await _notificationChannel!.subscribe();
      
      _isConnected = true;
      log('Realtime subscription established');
    } catch (e) {
      log('Error setting up realtime subscription: $e');
      _scheduleReconnect();
    }
  }

  /// Handle new notification insert
  void _handleNotificationInsert(PostgresChangePayload payload) {
    try {
      final notificationData = payload.newRecord;
      final notification = AppNotification.fromJson(notificationData);
      
      log('Received new notification: ${notification.title}');
      
      // Emit the notification
      _notificationStreamController.add(notification);
      
      // Refresh counts
      _refreshNotificationCounts();
      
      // Show local notification if app is in background
      _showLocalNotification(notification);
    } catch (e) {
      log('Error handling notification insert: $e');
    }
  }

  /// Handle role-based notification
  void _handleRoleBasedNotification(PostgresChangePayload payload) {
    try {
      final notificationData = payload.newRecord;
      final roleFilter = notificationData['role_filter'] as List<dynamic>?;
      
      // Check if this notification is for the current user's role
      if (roleFilter != null && 
          _currentUserRole != null && 
          roleFilter.contains(_currentUserRole)) {
        final notification = AppNotification.fromJson(notificationData);
        
        log('Received role-based notification: ${notification.title}');
        
        // Emit the notification
        _notificationStreamController.add(notification);
        
        // Refresh counts
        _refreshNotificationCounts();
        
        // Show local notification
        _showLocalNotification(notification);
      }
    } catch (e) {
      log('Error handling role-based notification: $e');
    }
  }

  /// Handle notification update (read status changes)
  void _handleNotificationUpdate(PostgresChangePayload payload) {
    try {
      log('Notification updated, refreshing counts');
      _refreshNotificationCounts();
    } catch (e) {
      log('Error handling notification update: $e');
    }
  }

  /// Show local notification (placeholder for push notifications)
  void _showLocalNotification(AppNotification notification) {
    // TODO: Implement local/push notification display
    // This would integrate with flutter_local_notifications or firebase_messaging
    if (kDebugMode) {
      log('Local notification: ${notification.title} - ${notification.message}');
    }
  }

  /// Refresh notification counts
  Future<void> _refreshNotificationCounts() async {
    if (_currentUserId == null) return;

    try {
      final response = await _supabase.rpc('get_user_notification_counts', params: {
        'p_user_id': _currentUserId,
      });

      if (response.isNotEmpty) {
        final countsData = response.first;
        final counts = NotificationCounts.fromJson(countsData);
        _countsStreamController.add(counts);
      }
    } catch (e) {
      log('Error refreshing notification counts: $e');
    }
  }

  /// Start periodic counts refresh
  void _startCountsRefresh() {
    _countsRefreshTimer?.cancel();
    _countsRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshNotificationCounts(),
    );
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_isInitialized && !_isConnected) {
        log('Attempting to reconnect...');
        _setupRealtimeSubscription();
      }
    });
  }

  /// Get user notifications with pagination
  Future<List<AppNotification>> getUserNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      var query = _supabase
          .from('notifications')
          .select()
          .or('user_id.eq.$_currentUserId,is_broadcast.eq.true')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // TODO: Fix Supabase API - .eq() method issue
      // if (unreadOnly) {
      //   query = query.eq('is_read', false);
      // }

      final response = await query;
      return response.map((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      log('Error fetching user notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _supabase.rpc('mark_notification_read', params: {
        'p_notification_id': notificationId,
        'p_user_id': _currentUserId,
      });

      return response == true;
    } catch (e) {
      log('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      final response = await _supabase.rpc('mark_all_notifications_read', params: {
        'p_user_id': _currentUserId,
      });

      return response ?? 0;
    } catch (e) {
      log('Error marking all notifications as read: $e');
      return 0;
    }
  }

  /// Create notification from template
  Future<bool> createNotificationFromTemplate({
    required String templateKey,
    String? userId,
    List<String>? roleFilter,
    bool isBroadcast = false,
    Map<String, dynamic> variables = const {},
    String? relatedEntityType,
    String? relatedEntityId,
  }) async {
    try {
      final response = await _supabase.rpc('create_notification_from_template', params: {
        'p_template_key': templateKey,
        'p_user_id': userId,
        'p_role_filter': roleFilter,
        'p_is_broadcast': isBroadcast,
        'p_variables': variables,
        'p_related_entity_type': relatedEntityType,
        'p_related_entity_id': relatedEntityId,
        'p_created_by': _currentUserId,
      });

      final result = response.first;
      return result['success'] == true;
    } catch (e) {
      log('Error creating notification from template: $e');
      return false;
    }
  }

  /// Disconnect from realtime
  Future<void> disconnect() async {
    try {
      _isConnected = false;
      
      // Cancel timers
      _reconnectTimer?.cancel();
      _countsRefreshTimer?.cancel();
      
      // Unsubscribe from channel
      if (_notificationChannel != null) {
        await _supabase.removeChannel(_notificationChannel!);
        _notificationChannel = null;
      }
      
      log('Disconnected from realtime notifications');
    } catch (e) {
      log('Error disconnecting from realtime: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    disconnect();
    _notificationStreamController.close();
    _countsStreamController.close();
    _isInitialized = false;
    _currentUserId = null;
    _currentUserRole = null;
  }
}
