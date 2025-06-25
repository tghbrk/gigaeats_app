import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/logger.dart';

/// Customer notification service for handling local notifications and real-time updates
/// Firebase has been removed - this service now only handles local notifications
/// and Supabase real-time notifications
class CustomerNotificationService {
  static final CustomerNotificationService _instance = CustomerNotificationService._internal();
  factory CustomerNotificationService() => _instance;
  CustomerNotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLogger _logger = AppLogger();

  FlutterLocalNotificationsPlugin? _localNotifications;

  bool _isInitialized = false;

  /// Initialize the notification service (local notifications only)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _logger.info('CustomerNotificationService: Initializing local notification service');

      // Initialize local notifications only
      await _initializeLocalNotifications();

      // Set up Supabase realtime subscriptions
      await _setupRealtimeSubscriptions();

      _isInitialized = true;
      _logger.info('CustomerNotificationService: Initialization complete');
    } catch (e) {
      _logger.error('CustomerNotificationService: Initialization failed', e);
      rethrow;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      _localNotifications = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _logger.info('CustomerNotificationService: Local notifications initialized');
    } catch (e) {
      _logger.error('CustomerNotificationService: Local notifications initialization failed', e);
    }
  }

  /// Set up Supabase realtime subscriptions for order notifications
  Future<void> _setupRealtimeSubscriptions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Subscribe to order notifications for the current user
      _supabase
          .from('order_notifications')
          .stream(primaryKey: ['id'])
          .eq('recipient_id', user.id)
          .listen((data) {
            _logger.info('CustomerNotificationService: Received realtime notification update');
            _handleRealtimeNotification(data);
          });

      _logger.info('CustomerNotificationService: Realtime subscriptions set up');
    } catch (e) {
      _logger.error('CustomerNotificationService: Failed to set up realtime subscriptions', e);
    }
  }

  /// Handle realtime notification updates
  void _handleRealtimeNotification(List<Map<String, dynamic>> data) {
    for (final notificationData in data) {
      try {
        // Show local notification for new notifications
        if (notificationData['is_read'] == false) {
          _showLocalNotificationFromData(notificationData);
        }
      } catch (e) {
        _logger.error('CustomerNotificationService: Error handling realtime notification', e);
      }
    }
  }



  /// Show local notification from Supabase data
  Future<void> _showLocalNotificationFromData(Map<String, dynamic> data) async {
    if (_localNotifications == null) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'gigaeats_orders',
        'Order Updates',
        channelDescription: 'Notifications for order status updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications!.show(
        data['id'].hashCode,
        data['title'] ?? 'GigaEats',
        data['message'] ?? 'You have a new update',
        notificationDetails,
        payload: jsonEncode(data),
      );
    } catch (e) {
      _logger.error('CustomerNotificationService: Failed to show local notification from data', e);
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        _handleNotificationTap(data);
      }
    } catch (e) {
      _logger.error('CustomerNotificationService: Error handling notification tap', e);
    }
  }

  /// Handle notification tap navigation
  void _handleNotificationTap(Map<String, dynamic> data) {
    try {
      _logger.info('CustomerNotificationService: Handling notification tap with data: $data');
      
      // TODO: Implement navigation based on notification type
      // This will be handled by the app router when integrated
      
    } catch (e) {
      _logger.error('CustomerNotificationService: Error handling notification tap', e);
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    // Clean up resources if needed
  }
}
