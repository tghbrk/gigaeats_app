import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/driver_earnings_realtime_provider.dart';

/// Real-time earnings notifications widget with Material Design 3 styling
class EarningsNotificationsWidget extends ConsumerStatefulWidget {
  final String driverId;
  final bool showUnreadOnly;
  final int maxNotifications;
  final VoidCallback? onNotificationTap;

  const EarningsNotificationsWidget({
    super.key,
    required this.driverId,
    this.showUnreadOnly = false,
    this.maxNotifications = 10,
    this.onNotificationTap,
  });

  @override
  ConsumerState<EarningsNotificationsWidget> createState() => _EarningsNotificationsWidgetState();
}

class _EarningsNotificationsWidgetState extends ConsumerState<EarningsNotificationsWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationsState = ref.watch(driverEarningsRealtimeProvider(widget.driverId));

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          elevation: 6,
          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerHighest,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(theme, notificationsState),
                
                // Notifications list
                _buildNotificationsList(theme, notificationsState),
                
                // Footer actions
                if (notificationsState.notifications.isNotEmpty)
                  _buildFooter(theme, notificationsState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build header with title and unread count
  Widget _buildHeader(ThemeData theme, EarningsNotificationsState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.notifications_active,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Earnings Notifications',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (state.unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${state.unreadCount} unread',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Real-time indicator
          if (state.isListening) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Live',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build notifications list
  Widget _buildNotificationsList(ThemeData theme, EarningsNotificationsState state) {
    if (state.notifications.isEmpty) {
      return _buildEmptyState(theme);
    }

    final notifications = widget.showUnreadOnly
        ? state.notifications.where((n) => !n.isRead).toList()
        : state.notifications;

    final displayNotifications = notifications.take(widget.maxNotifications).toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: displayNotifications.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        itemBuilder: (context, index) {
          final notification = displayNotifications[index];
          return _buildNotificationItem(theme, notification, index);
        },
      ),
    );
  }

  /// Build individual notification item
  Widget _buildNotificationItem(
    ThemeData theme,
    EarningsNotification notification,
    int index,
  ) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              ref.read(driverEarningsRealtimeProvider(widget.driverId).notifier)
                  .markAsRead(notification.id);
            }
            widget.onNotificationTap?.call();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification.isRead
                  ? Colors.transparent
                  : theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: notification.isRead
                  ? null
                  : Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification type icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    size: 20,
                    color: _getNotificationColor(notification.type),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and amount
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: notification.isRead 
                                    ? FontWeight.w500 
                                    : FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            'RM ${notification.netAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getNotificationColor(notification.type),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Message
                      Text(
                        notification.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Timestamp and status
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(notification.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          if (!notification.isRead) ...[
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.notifications_none,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your earnings notifications will appear here',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build footer with actions
  Widget _buildFooter(ThemeData theme, EarningsNotificationsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          if (state.unreadCount > 0) ...[
            Flexible(
              child: TextButton.icon(
                onPressed: () {
                  ref.read(driverEarningsRealtimeProvider(widget.driverId).notifier)
                      .markAllAsRead();
                },
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text(
                  'Mark read',
                  overflow: TextOverflow.ellipsis,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: TextButton.icon(
              onPressed: () {
                ref.read(driverEarningsRealtimeProvider(widget.driverId).notifier)
                    .clearAllNotifications();
              },
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text(
                'Clear',
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.outline,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${state.notifications.length} total',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// Get notification icon based on type
  IconData _getNotificationIcon(EarningsNotificationType type) {
    switch (type) {
      case EarningsNotificationType.earningsUpdate:
        return Icons.account_balance_wallet;
      case EarningsNotificationType.paymentReceived:
        return Icons.payment;
      case EarningsNotificationType.bonusEarned:
        return Icons.star;
      case EarningsNotificationType.commissionUpdate:
        return Icons.trending_up;
      case EarningsNotificationType.paymentPending:
        return Icons.schedule;
      case EarningsNotificationType.paymentFailed:
        return Icons.error_outline;
    }
  }

  /// Get notification color based on type
  Color _getNotificationColor(EarningsNotificationType type) {
    switch (type) {
      case EarningsNotificationType.earningsUpdate:
        return Colors.green;
      case EarningsNotificationType.paymentReceived:
        return Colors.blue;
      case EarningsNotificationType.bonusEarned:
        return Colors.orange;
      case EarningsNotificationType.commissionUpdate:
        return Colors.purple;
      case EarningsNotificationType.paymentPending:
        return Colors.amber;
      case EarningsNotificationType.paymentFailed:
        return Colors.red;
    }
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

/// Floating notification badge for showing unread count
class EarningsNotificationBadge extends ConsumerWidget {
  final String driverId;
  final VoidCallback? onTap;

  const EarningsNotificationBadge({
    super.key,
    required this.driverId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unreadCount = ref.watch(unreadEarningsNotificationsCountProvider(driverId));

    if (unreadCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_active,
              size: 16,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              unreadCount.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Notification toast for showing new earnings notifications
class EarningsNotificationToast extends StatefulWidget {
  final EarningsNotification notification;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const EarningsNotificationToast({
    super.key,
    required this.notification,
    this.onDismiss,
    this.onTap,
  });

  @override
  State<EarningsNotificationToast> createState() => _EarningsNotificationToastState();
}

class _EarningsNotificationToastState extends State<EarningsNotificationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceContainerHighest,
                  ],
                ),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(widget.notification.type).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getNotificationIcon(widget.notification.type),
                      size: 24,
                      color: _getNotificationColor(widget.notification.type),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.notification.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.notification.message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'RM ${widget.notification.netAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getNotificationColor(widget.notification.type),
                        ),
                      ),
                      const SizedBox(height: 4),
                      IconButton(
                        onPressed: _dismiss,
                        icon: const Icon(Icons.close, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get notification icon based on type
  IconData _getNotificationIcon(EarningsNotificationType type) {
    switch (type) {
      case EarningsNotificationType.earningsUpdate:
        return Icons.account_balance_wallet;
      case EarningsNotificationType.paymentReceived:
        return Icons.payment;
      case EarningsNotificationType.bonusEarned:
        return Icons.star;
      case EarningsNotificationType.commissionUpdate:
        return Icons.trending_up;
      case EarningsNotificationType.paymentPending:
        return Icons.schedule;
      case EarningsNotificationType.paymentFailed:
        return Icons.error_outline;
    }
  }

  /// Get notification color based on type
  Color _getNotificationColor(EarningsNotificationType type) {
    switch (type) {
      case EarningsNotificationType.earningsUpdate:
        return Colors.green;
      case EarningsNotificationType.paymentReceived:
        return Colors.blue;
      case EarningsNotificationType.bonusEarned:
        return Colors.orange;
      case EarningsNotificationType.commissionUpdate:
        return Colors.purple;
      case EarningsNotificationType.paymentPending:
        return Colors.amber;
      case EarningsNotificationType.paymentFailed:
        return Colors.red;
    }
  }
}
