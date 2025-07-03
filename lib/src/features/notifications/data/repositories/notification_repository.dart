import '../models/notification_models.dart';
import '../../../customers/data/repositories/base_repository.dart';

class NotificationRepository extends BaseRepository {

  // Get user notifications with filtering and pagination
  Future<List<AppNotification>> getUserNotifications({
    String? userId,
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
    String? type,
    String? priority,
    String? category,
  }) async {
    return executeQuery(() async {
      var query = client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // TODO: Fix Supabase API - .or() and .eq() method issues
      // Filter by user (include user-specific, broadcast, and role-based)
      // if (userId != null) {
      //   query = query.or('user_id.eq.$userId,is_broadcast.eq.true');
      // }

      // Filter by read status
      // if (unreadOnly) {
      //   query = query.eq('is_read', false);
      // }

      // Filter by type
      // if (type != null) {
      //   query = query.eq('type', type);
      // }

      // Filter by priority
      // if (priority != null) {
      //   query = query.eq('priority', priority);
      // }

      // Filter by category
      // if (category != null) {
      //   query = query.eq('category', category);
      // }

      // Filter out expired notifications
      // query = query.or('expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}');

      final response = await query;
      return response.map((json) => AppNotification.fromJson(json)).toList();
    });
  }

  // Get notification by ID
  Future<AppNotification?> getNotificationById(String notificationId) async {
    try {
      final response = await client
          .from('notifications')
          .select()
          .eq('id', notificationId)
          .single();

      return AppNotification.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Get notification counts for user
  Future<NotificationCounts> getNotificationCounts({String? userId}) async {
    try {
      final response = await client.rpc('get_user_notification_counts', params: {
        'p_user_id': userId,
      });

      if (response.isNotEmpty) {
        return NotificationCounts.fromJson(response.first);
      }
      return const NotificationCounts();
    } catch (e) {
      throw Exception('Failed to fetch notification counts: $e');
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId, {String? userId}) async {
    try {
      final response = await client.rpc('mark_notification_read', params: {
        'p_notification_id': notificationId,
        'p_user_id': userId,
      });

      return response == true;
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<int> markAllAsRead({String? userId}) async {
    try {
      final response = await client.rpc('mark_all_notifications_read', params: {
        'p_user_id': userId,
      });

      return response ?? 0;
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Create notification from template
  Future<String?> createNotificationFromTemplate({
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
      final response = await client.rpc('create_notification_from_template', params: {
        'p_template_key': templateKey,
        'p_user_id': userId,
        'p_role_filter': roleFilter,
        'p_is_broadcast': isBroadcast,
        'p_variables': variables,
        'p_related_entity_type': relatedEntityType,
        'p_related_entity_id': relatedEntityId,
        'p_created_by': createdBy,
      });

      final result = response.first;
      if (result['success'] == true) {
        return result['notification_id'];
      }
      throw Exception(result['message']);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Create custom notification
  Future<String> createNotification({
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
      final response = await client
          .from('notifications')
          .insert({
            'user_id': userId,
            'role_filter': roleFilter,
            'is_broadcast': isBroadcast,
            'type': type,
            'title': title,
            'message': message,
            'rich_content': richContent,
            'action_url': actionUrl,
            'action_data': actionData,
            'priority': priority,
            'category': category,
            'tags': tags,
            'channels': channels,
            'expires_at': expiresAt?.toIso8601String(),
            'scheduled_at': scheduledAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
            'related_entity_type': relatedEntityType,
            'related_entity_id': relatedEntityId,
            'created_by': createdBy,
          })
          .select()
          .single();

      return response['id'];
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get notification templates
  Future<List<NotificationTemplate>> getNotificationTemplates({
    bool activeOnly = true,
    String? type,
    List<String>? targetRoles,
  }) async {
    try {
      var query = client
          .from('notification_templates')
          .select()
          .order('name');

      // TODO: Fix Supabase API - .eq() method issues
      // if (activeOnly) {
      //   query = query.eq('is_active', true);
      // }

      // if (type != null) {
      //   query = query.eq('type', type);
      // }

      final response = await query;
      return response.map((json) => NotificationTemplate.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notification templates: $e');
    }
  }

  // Get user notification preferences
  Future<NotificationPreferences?> getUserPreferences(String userId) async {
    try {
      final response = await client
          .from('user_notification_preferences')
          .select()
          .eq('user_id', userId)
          .single();

      return NotificationPreferences.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Update user notification preferences
  Future<NotificationPreferences> updateUserPreferences({
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
      final updateData = <String, dynamic>{};
      
      if (inAppEnabled != null) updateData['in_app_enabled'] = inAppEnabled;
      if (emailEnabled != null) updateData['email_enabled'] = emailEnabled;
      if (pushEnabled != null) updateData['push_enabled'] = pushEnabled;
      if (smsEnabled != null) updateData['sms_enabled'] = smsEnabled;
      if (orderNotifications != null) updateData['order_notifications'] = orderNotifications;
      if (paymentNotifications != null) updateData['payment_notifications'] = paymentNotifications;
      if (accountNotifications != null) updateData['account_notifications'] = accountNotifications;
      if (systemNotifications != null) updateData['system_notifications'] = systemNotifications;
      if (promotionNotifications != null) updateData['promotion_notifications'] = promotionNotifications;
      if (quietHoursStart != null) updateData['quiet_hours_start'] = quietHoursStart;
      if (quietHoursEnd != null) updateData['quiet_hours_end'] = quietHoursEnd;
      if (timezone != null) updateData['timezone'] = timezone;
      if (maxNotificationsPerHour != null) updateData['max_notifications_per_hour'] = maxNotificationsPerHour;
      if (maxNotificationsPerDay != null) updateData['max_notifications_per_day'] = maxNotificationsPerDay;

      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from('user_notification_preferences')
          .upsert({
            'user_id': userId,
            ...updateData,
          })
          .select()
          .single();

      return NotificationPreferences.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  // Get notification delivery logs
  Future<List<NotificationDeliveryLog>> getDeliveryLogs({
    String? notificationId,
    String? channel,
    String? status,
    int limit = 50,
  }) async {
    try {
      var query = client
          .from('notification_delivery_log')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      // TODO: Fix Supabase API - .eq() method issues
      // if (notificationId != null) {
      //   query = query.eq('notification_id', notificationId);
      // }

      // if (channel != null) {
      //   query = query.eq('channel', channel);
      // }

      // if (status != null) {
      //   query = query.eq('status', status);
      // }

      final response = await query;
      return response.map((json) => NotificationDeliveryLog.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch delivery logs: $e');
    }
  }

  // Delete notification (soft delete by setting expired)
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await client
          .from('notifications')
          .update({
            'expires_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Cleanup expired notifications
  Future<int> cleanupExpiredNotifications() async {
    try {
      final response = await client.rpc('cleanup_expired_notifications');
      return response ?? 0;
    } catch (e) {
      throw Exception('Failed to cleanup expired notifications: $e');
    }
  }
}
