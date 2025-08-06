import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

/// Service for handling notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize notification service
  Future<void> initialize() async {
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

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to appropriate screen
    // This would typically use a navigation service or router
  }

  /// Show local notification
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'gigaeats_channel',
      'GigaEats Notifications',
      channelDescription: 'Notifications for GigaEats app',
      importance: Importance.high,
      priority: Priority.high,
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

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Schedule notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'gigaeats_scheduled',
      'GigaEats Scheduled',
      channelDescription: 'Scheduled notifications for GigaEats',
      importance: Importance.high,
      priority: Priority.high,
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

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      notificationDetails,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancel notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Send order notification
  Future<void> sendOrderNotification({
    required String userId,
    required String orderId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      // Create database notification
      await _supabase.from('notifications').insert({
        'recipient_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': {'order_id': orderId},
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Show local notification if user is currently using the app
      await showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: message,
        payload: orderId,
      );
    } catch (e) {
      throw Exception('Failed to send order notification: $e');
    }
  }

  /// Send delivery notification
  Future<void> sendDeliveryNotification({
    required String userId,
    required String orderId,
    required String status,
  }) async {
    String title;
    String message;

    switch (status) {
      case 'confirmed':
        title = 'Order Confirmed';
        message = 'Your order has been confirmed and is being prepared.';
        break;
      case 'preparing':
        title = 'Order Being Prepared';
        message = 'Your order is currently being prepared.';
        break;
      case 'ready':
        title = 'Order Ready';
        message = 'Your order is ready for pickup/delivery.';
        break;
      case 'out_for_delivery':
        title = 'Out for Delivery';
        message = 'Your order is on the way!';
        break;
      case 'delivered':
        title = 'Order Delivered';
        message = 'Your order has been delivered. Enjoy your meal!';
        break;
      default:
        title = 'Order Update';
        message = 'Your order status has been updated.';
    }

    await sendOrderNotification(
      userId: userId,
      orderId: orderId,
      title: title,
      message: message,
      type: 'order_status',
    );
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }
}
