import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for notification-related operations
class NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a notification
  Future<Map<String, dynamic>> createNotification({
    required String recipientId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .insert({
            'recipient_id': recipientId,
            'title': title,
            'message': message,
            'type': type,
            'data': data,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Get notifications for a user
  Future<List<Map<String, dynamic>>> getNotifications({
    required String userId,
    bool? isRead,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('notifications')
          .select('*')
          .eq('recipient_id', userId);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('recipient_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('recipient_id', userId)
          .eq('is_read', false)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Send push notification (placeholder for actual implementation)
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    // In a real implementation, this would integrate with FCM or similar service
    // For now, we'll just create a database notification
    await createNotification(
      recipientId: userId,
      title: title,
      message: message,
      type: 'push',
      data: data,
    );
  }
}
