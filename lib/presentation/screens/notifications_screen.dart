import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/notification.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationState = ref.watch(notificationProvider);
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          if (notificationState.unreadCount > 0)
            TextButton(
              onPressed: () => _markAllAsRead(userId),
              child: const Text('Mark all read'),
            ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, userId),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read),
                    SizedBox(width: 8),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Notification settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'All',
              icon: notificationState.unreadCount > 0
                  ? Badge(
                      label: Text('${notificationState.unreadCount}'),
                      child: const Icon(Icons.notifications),
                    )
                  : const Icon(Icons.notifications),
            ),
            const Tab(text: 'Unread', icon: Icon(Icons.mark_email_unread)),
            const Tab(text: 'Important', icon: Icon(Icons.priority_high)),
          ],
        ),
      ),
      body: notificationState.isLoading
          ? const LoadingWidget(message: 'Loading notifications...')
          : notificationState.errorMessage != null
              ? CustomErrorWidget(
                  message: notificationState.errorMessage!,
                  onRetry: () => ref.read(notificationProvider.notifier)._initialize(),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllNotifications(userId),
                    _buildUnreadNotifications(userId),
                    _buildImportantNotifications(userId),
                  ],
                ),
    );
  }

  Widget _buildAllNotifications(String? userId) {
    final notifications = userId != null
        ? ref.watch(userNotificationsProvider(userId))
        : ref.watch(notificationProvider).notifications;

    return _buildNotificationsList(notifications);
  }

  Widget _buildUnreadNotifications(String? userId) {
    final notifications = userId != null
        ? ref.watch(unreadUserNotificationsProvider(userId))
        : ref.watch(notificationProvider).notifications.where((n) => !n.isRead).toList();

    return _buildNotificationsList(notifications);
  }

  Widget _buildImportantNotifications(String? userId) {
    final allNotifications = userId != null
        ? ref.watch(userNotificationsProvider(userId))
        : ref.watch(notificationProvider).notifications;

    final importantNotifications = allNotifications
        .where((n) => n.priority == NotificationPriority.high || 
                     n.priority == NotificationPriority.urgent)
        .toList();

    return _buildNotificationsList(importantNotifications);
  }

  Widget _buildNotificationsList(List<AppNotification> notifications) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh notifications
        ref.read(notificationProvider.notifier)._initialize();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnread ? 2 : 1,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isUnread
                ? Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: notification.type.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        notification.type.icon,
                        color: notification.type.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            notification.type.displayName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: notification.type.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (notification.priority == NotificationPriority.high ||
                        notification.priority == NotificationPriority.urgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: notification.priority.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          notification.priority.displayName,
                          style: TextStyle(
                            color: notification.priority.color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Message
                Text(
                  notification.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 12),

                // Footer
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(notification.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleNotificationAction(value, notification),
                      itemBuilder: (context) => [
                        if (!notification.isRead)
                          const PopupMenuItem(
                            value: 'mark_read',
                            child: Row(
                              children: [
                                Icon(Icons.mark_email_read),
                                SizedBox(width: 8),
                                Text('Mark as read'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive),
                              SizedBox(width: 8),
                              Text('Archive'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up! New notifications will appear here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read if unread
    if (!notification.isRead) {
      ref.read(notificationProvider.notifier).markAsRead(notification.id);
    }

    // Navigate based on notification type and data
    if (notification.orderId != null) {
      context.push('/order-details/${notification.orderId}');
    } else if (notification.customerId != null) {
      context.push('/customers/${notification.customerId}');
    } else if (notification.vendorId != null) {
      context.push('/vendors/${notification.vendorId}');
    }
  }

  void _handleNotificationAction(String action, AppNotification notification) {
    switch (action) {
      case 'mark_read':
        ref.read(notificationProvider.notifier).markAsRead(notification.id);
        break;
      case 'archive':
        ref.read(notificationProvider.notifier).archiveNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification archived')),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(notification);
        break;
    }
  }

  void _handleMenuAction(String action, String? userId) {
    switch (action) {
      case 'mark_all_read':
        _markAllAsRead(userId);
        break;
      case 'settings':
        _showNotificationSettings();
        break;
    }
  }

  void _markAllAsRead(String? userId) {
    ref.read(notificationProvider.notifier).markAllAsRead(userId: userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _showDeleteConfirmation(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(notificationProvider.notifier).deleteNotification(notification.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
