import 'dart:async';
import 'dart:math';

import '../models/notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  final StreamController<List<AppNotification>> _notificationsController =
      StreamController<List<AppNotification>>.broadcast();
  final StreamController<AppNotification> _newNotificationController =
      StreamController<AppNotification>.broadcast();

  Stream<List<AppNotification>> get notificationsStream =>
      _notificationsController.stream;
  Stream<AppNotification> get newNotificationStream =>
      _newNotificationController.stream;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> initialize() async {
    // Initialize with some sample notifications
    await _loadSampleNotifications();
    _notificationsController.add(_notifications);
  }

  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
    _notificationsController.add(_notifications);
    _newNotificationController.add(notification);
    
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
      _notificationsController.add(_notifications);
    }
    
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> markAllAsRead({String? userId}) async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead && 
          (userId == null || _notifications[i].userId == userId)) {
        _notifications[i] = _notifications[i].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }
    }
    _notificationsController.add(_notifications);
    
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> archiveNotification(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(
        isArchived: true,
      );
      _notificationsController.add(_notifications);
    }
    
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    _notificationsController.add(_notifications);
    
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 100));
  }

  List<AppNotification> getNotificationsForUser(String userId) {
    return _notifications
        .where((n) => n.userId == userId && !n.isArchived)
        .toList();
  }

  List<AppNotification> getUnreadNotificationsForUser(String userId) {
    return _notifications
        .where((n) => n.userId == userId && !n.isRead && !n.isArchived)
        .toList();
  }

  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type && !n.isArchived).toList();
  }

  Future<void> _loadSampleNotifications() async {
    final now = DateTime.now();
    final random = Random();

    final sampleNotifications = [
      AppNotification(
        id: '1',
        title: 'New Order Received',
        message: 'You have received a new order #ORD-001 from ABC Corporation',
        type: NotificationType.newOrder,
        priority: NotificationPriority.high,
        userId: 'vendor_001',
        orderId: 'order_001',
        createdAt: now.subtract(const Duration(minutes: 5)),
        data: {
          'orderNumber': 'ORD-001',
          'customerName': 'ABC Corporation',
        },
      ),
      AppNotification(
        id: '2',
        title: 'Order Status Updated',
        message: 'Your order #ORD-002 is now being prepared',
        type: NotificationType.orderUpdate,
        priority: NotificationPriority.normal,
        userId: 'customer_001',
        orderId: 'order_002',
        createdAt: now.subtract(const Duration(hours: 1)),
        isRead: true,
        readAt: now.subtract(const Duration(minutes: 30)),
        data: {
          'orderNumber': 'ORD-002',
          'newStatus': 'preparing',
        },
      ),
      AppNotification(
        id: '3',
        title: 'Payment Received',
        message: 'Payment of RM 125.50 has been received for order #ORD-003',
        type: NotificationType.paymentReceived,
        priority: NotificationPriority.normal,
        userId: 'vendor_001',
        orderId: 'order_003',
        createdAt: now.subtract(const Duration(hours: 2)),
        data: {
          'orderNumber': 'ORD-003',
          'amount': 125.50,
        },
      ),
      AppNotification(
        id: '4',
        title: 'System Maintenance',
        message: 'Scheduled maintenance will occur tonight from 2:00 AM to 4:00 AM',
        type: NotificationType.systemAlert,
        priority: NotificationPriority.high,
        createdAt: now.subtract(const Duration(hours: 3)),
        expiresAt: now.add(const Duration(hours: 12)),
      ),
      AppNotification(
        id: '5',
        title: 'Special Promotion',
        message: '20% off on all orders above RM 100 this weekend!',
        type: NotificationType.promotion,
        priority: NotificationPriority.low,
        createdAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 2)),
      ),
      AppNotification(
        id: '6',
        title: 'Order Reminder',
        message: 'Don\'t forget to place your weekly order for next Monday',
        type: NotificationType.reminder,
        priority: NotificationPriority.normal,
        userId: 'customer_002',
        createdAt: now.subtract(const Duration(days: 1)),
        expiresAt: now.add(const Duration(days: 1)),
      ),
      AppNotification(
        id: '7',
        title: 'Customer Message',
        message: 'You have a new message from XYZ School regarding their order',
        type: NotificationType.customerMessage,
        priority: NotificationPriority.normal,
        userId: 'vendor_001',
        customerId: 'customer_003',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      AppNotification(
        id: '8',
        title: 'Order Delivered',
        message: 'Your order #ORD-004 has been successfully delivered',
        type: NotificationType.orderUpdate,
        priority: NotificationPriority.normal,
        userId: 'customer_001',
        orderId: 'order_004',
        createdAt: now.subtract(const Duration(hours: 6)),
        isRead: true,
        readAt: now.subtract(const Duration(hours: 5)),
        data: {
          'orderNumber': 'ORD-004',
          'newStatus': 'delivered',
        },
      ),
    ];

    _notifications.addAll(sampleNotifications);
  }

  void dispose() {
    _notificationsController.close();
    _newNotificationController.close();
  }

  // Utility methods for creating common notifications
  Future<void> notifyOrderStatusUpdate({
    required String orderId,
    required String orderNumber,
    required String newStatus,
    required String userId,
  }) async {
    final notification = NotificationFactory.orderStatusUpdate(
      orderId: orderId,
      orderNumber: orderNumber,
      newStatus: newStatus,
      userId: userId,
    );
    await addNotification(notification);
  }

  Future<void> notifyNewOrder({
    required String orderId,
    required String orderNumber,
    required String customerName,
    required String vendorId,
  }) async {
    final notification = NotificationFactory.newOrderReceived(
      orderId: orderId,
      orderNumber: orderNumber,
      customerName: customerName,
      vendorId: vendorId,
    );
    await addNotification(notification);
  }

  Future<void> notifyPaymentReceived({
    required String orderId,
    required String orderNumber,
    required double amount,
    required String userId,
  }) async {
    final notification = NotificationFactory.paymentReceived(
      orderId: orderId,
      orderNumber: orderNumber,
      amount: amount,
      userId: userId,
    );
    await addNotification(notification);
  }

  Future<void> notifySystemAlert({
    required String title,
    required String message,
    String? userId,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    final notification = NotificationFactory.systemAlert(
      title: title,
      message: message,
      userId: userId,
      priority: priority,
    );
    await addNotification(notification);
  }

  Future<void> notifyReminder({
    required String title,
    required String message,
    required String userId,
    DateTime? expiresAt,
  }) async {
    final notification = NotificationFactory.reminder(
      title: title,
      message: message,
      userId: userId,
      expiresAt: expiresAt,
    );
    await addNotification(notification);
  }
}
