import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/notification_models.dart';
import '../../providers/notification_providers.dart';

// Notification badge widget
class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onTap;

  const NotificationBadge({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(notificationCountsProvider);

    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: child,
        ),
        countsAsync.when(
          data: (counts) {
            if (!counts.hasUnread) return const SizedBox.shrink();
            
            return Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: counts.hasUrgent ? Colors.red : Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  counts.badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// Notification card widget
class NotificationCard extends ConsumerWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: notification.isRead ? 1 : 3,
      color: notification.isRead ? null : theme.colorScheme.surface,
      child: InkWell(
        onTap: () {
          if (!notification.isRead && onMarkAsRead != null) {
            onMarkAsRead!();
          }
          onTap?.call();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Type icon
                  Text(
                    notification.typeIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  
                  // Title
                  Expanded(
                    child: Text(
                      notification.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Priority indicator
                  if (notification.isHighPriority)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: notification.isUrgent ? Colors.red : Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notification.priority.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  
                  // Actions menu
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'mark_read':
                          onMarkAsRead?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!notification.isRead)
                        const PopupMenuItem(
                          value: 'mark_read',
                          child: Row(
                            children: [
                              Icon(Icons.mark_email_read),
                              SizedBox(width: 8),
                              Text('Mark as Read'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Message
              Text(
                notification.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: notification.isRead ? theme.colorScheme.onSurface.withValues(alpha: 0.7) : null,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Footer row
              Row(
                children: [
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      notification.categoryDisplayName,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Time
                  Text(
                    notification.ageText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  
                  // Read indicator
                  if (!notification.isRead) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Notification list widget
class NotificationList extends ConsumerWidget {
  final String? userId;
  final bool unreadOnly;
  final String? type;
  final String? priority;
  final String? category;

  const NotificationList({
    super.key,
    this.userId,
    this.unreadOnly = false,
    this.type,
    this.priority,
    this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider(
      NotificationParams(
        userId: userId,
        unreadOnly: unreadOnly,
        type: type,
        priority: priority,
        category: category,
      ),
    ));

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No notifications',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return NotificationCard(
              notification: notification,
              onTap: () {
                // Handle notification tap
                _handleNotificationTap(context, notification);
              },
              onMarkAsRead: () {
                ref.read(notificationActionsProvider).markAsRead(
                  notification.id,
                  userId: userId,
                );
              },
              onDelete: () {
                ref.read(notificationActionsProvider).deleteNotification(
                  notification.id,
                );
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading notifications',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, AppNotification notification) {
    // Handle different notification types
    switch (notification.type) {
      case 'order_created':
      case 'order_updated':
      case 'order_confirmed':
      case 'order_preparing':
      case 'order_ready':
      case 'order_out_for_delivery':
      case 'order_delivered':
      case 'order_cancelled':
        // Navigate to order details
        if (notification.relatedEntityId != null) {
          // Navigator.pushNamed(context, '/order/${notification.relatedEntityId}');
        }
        break;
      
      case 'payment_received':
      case 'payment_failed':
        // Navigate to payment details
        break;
      
      case 'driver_assigned':
      case 'driver_location_update':
        // Navigate to delivery tracking
        break;
      
      case 'account_verified':
      case 'role_changed':
        // Navigate to account settings
        break;
      
      case 'invitation_received':
        // Handle invitation
        break;
      
      default:
        // Default action or show details
        if (notification.actionUrl != null) {
          // Handle action URL
        }
        break;
    }
  }
}

// Notification summary widget
class NotificationSummary extends ConsumerWidget {
  const NotificationSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(notificationCountsProvider);
    final theme = Theme.of(context);

    return countsAsync.when(
      data: (counts) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildCountItem(
                    context,
                    'Total',
                    counts.totalCount,
                    Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildCountItem(
                    context,
                    'Unread',
                    counts.unreadCount,
                    Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _buildCountItem(
                    context,
                    'Urgent',
                    counts.urgentPriorityUnread,
                    Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCountItem(BuildContext context, String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
