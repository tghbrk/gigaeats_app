import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../providers/wallet_notifications_provider.dart';

class WalletNotificationsWidget extends ConsumerWidget {
  final int limit;
  final bool showHeader;

  const WalletNotificationsWidget({
    super.key,
    this.limit = 3,
    this.showHeader = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsState = ref.watch(currentUserWalletNotificationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Notifications',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/wallet/notifications'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        if (notificationsState.isLoading)
          const Center(child: LoadingWidget())
        else if (notificationsState.errorMessage != null)
          _buildErrorState(context, notificationsState.errorMessage!)
        else if (notificationsState.isEmpty)
          _buildEmptyState(context)
        else
          _buildNotificationsList(
            context,
            ref,
            notificationsState.notifications.take(limit).toList(),
          ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load notifications',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_outlined,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No notifications',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You\'ll receive notifications about wallet activities here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    WidgetRef ref,
    List<WalletNotification> notifications,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return NotificationTile(
          notification: notification,
          onTap: () => _handleNotificationTap(context, ref, notification),
          onDismiss: () => _handleNotificationDismiss(ref, notification),
        );
      },
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    WalletNotification notification,
  ) {
    // Mark as read
    final authState = ref.read(authStateProvider);
    final userRole = authState.user?.role.value ?? 'customer';
    
    ref.read(walletNotificationsActionsProvider).markAsRead(userRole, notification.id);

    // Navigate to action URL if available
    if (notification.actionUrl != null) {
      context.push(notification.actionUrl!);
    }
  }

  void _handleNotificationDismiss(WidgetRef ref, WalletNotification notification) {
    final authState = ref.read(authStateProvider);
    final userRole = authState.user?.role.value ?? 'customer';
    
    ref.read(walletNotificationsActionsProvider).removeNotification(userRole, notification.id);
  }
}

class NotificationTile extends StatelessWidget {
  final WalletNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete,
          color: theme.colorScheme.onError,
        ),
      ),
      child: Card(
        elevation: notification.isRead ? 0 : 2,
        color: notification.isRead 
            ? theme.colorScheme.surface.withValues(alpha: 0.7)
            : theme.colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification),
                    color: _getNotificationColor(notification),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Notification Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: notification.isRead 
                                    ? FontWeight.w500 
                                    : FontWeight.bold,
                                color: notification.isRead
                                    ? theme.colorScheme.onSurface.withValues(alpha: 0.8)
                                    : theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: notification.isRead
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            notification.typeDisplayName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getNotificationColor(notification),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(notification.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Indicator
                if (notification.actionUrl != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(WalletNotification notification) {
    switch (notification.type) {
      case WalletNotificationType.balanceUpdate:
        return Icons.account_balance_wallet;
      case WalletNotificationType.transactionReceived:
        return Icons.payment;
      case WalletNotificationType.payoutCompleted:
        return Icons.check_circle;
      case WalletNotificationType.payoutFailed:
        return Icons.error;
      case WalletNotificationType.autoPayoutTriggered:
        return Icons.autorenew;
      case WalletNotificationType.lowBalance:
        return Icons.warning;
      case WalletNotificationType.verificationRequired:
        return Icons.verified_user;
    }
  }

  Color _getNotificationColor(WalletNotification notification) {
    switch (notification.type) {
      case WalletNotificationType.balanceUpdate:
        return AppTheme.primaryColor;
      case WalletNotificationType.transactionReceived:
        return AppTheme.successColor;
      case WalletNotificationType.payoutCompleted:
        return AppTheme.successColor;
      case WalletNotificationType.payoutFailed:
        return AppTheme.errorColor;
      case WalletNotificationType.autoPayoutTriggered:
        return AppTheme.infoColor;
      case WalletNotificationType.lowBalance:
        return AppTheme.warningColor;
      case WalletNotificationType.verificationRequired:
        return AppTheme.warningColor;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(timestamp);
    }
  }
}
