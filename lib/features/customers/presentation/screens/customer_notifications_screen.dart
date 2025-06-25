import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/customer_notification_provider.dart';
import '../widgets/customer_notification_bell.dart';
import '../../../../shared/widgets/custom_error_widget.dart';

/// Customer notifications screen
class CustomerNotificationsScreen extends ConsumerStatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  ConsumerState<CustomerNotificationsScreen> createState() => _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends ConsumerState<CustomerNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh notifications when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerNotificationProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationState = ref.watch(customerNotificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          if (notificationState.unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(customerNotificationProvider.notifier).markAllAsRead();
              },
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(customerNotificationProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: _buildBody(context, notificationState),
    );
  }

  Widget _buildBody(BuildContext context, CustomerNotificationState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const CustomerNotificationLoading();
    }

    if (state.error != null) {
      return CustomErrorWidget(
        message: 'Failed to load notifications: ${state.error}',
        onRetry: () {
          ref.read(customerNotificationProvider.notifier).clearError();
          ref.read(customerNotificationProvider.notifier).refresh();
        },
      );
    }

    if (state.notifications.isEmpty) {
      return const CustomerNotificationEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(customerNotificationProvider.notifier).refresh();
      },
      child: Column(
        children: [
          // Summary header
          if (state.unreadCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '${state.unreadCount} unread notification${state.unreadCount == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          // Notifications list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.notifications.length,
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return CustomerNotificationItem(
                  notificationId: notification.id,
                  title: notification.title,
                  message: notification.message,
                  createdAt: notification.createdAt,
                  isRead: notification.isRead,
                  orderId: notification.orderId,
                  onTap: () {
                    // Handle specific notification types
                    _handleNotificationTap(notification.orderId, notification.data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(String? orderId, Map<String, dynamic>? data) {
    if (orderId != null) {
      // Navigate to order details
      context.push('/customer/orders/$orderId');
    } else if (data != null) {
      // Handle other notification types based on data
      final type = data['type'] as String?;
      switch (type) {
        case 'promotion':
          // Navigate to promotions or specific offer
          break;
        case 'system_alert':
          // Show system alert dialog or navigate to relevant screen
          break;
        default:
          // Default action or no action
          break;
      }
    }
  }
}

/// Notification settings screen
class CustomerNotificationSettingsScreen extends ConsumerWidget {
  const CustomerNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Notifications',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationToggle(
                    context,
                    'Order Status Updates',
                    'Get notified when your order status changes',
                    true,
                    (value) {
                      // TODO: Implement notification preference update
                    },
                  ),
                  _buildNotificationToggle(
                    context,
                    'Delivery Updates',
                    'Get notified about delivery progress',
                    true,
                    (value) {
                      // TODO: Implement notification preference update
                    },
                  ),
                  _buildNotificationToggle(
                    context,
                    'Payment Confirmations',
                    'Get notified when payments are processed',
                    true,
                    (value) {
                      // TODO: Implement notification preference update
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marketing Notifications',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationToggle(
                    context,
                    'Promotions & Offers',
                    'Get notified about special deals and discounts',
                    false,
                    (value) {
                      // TODO: Implement notification preference update
                    },
                  ),
                  _buildNotificationToggle(
                    context,
                    'New Restaurants',
                    'Get notified when new restaurants join',
                    false,
                    (value) {
                      // TODO: Implement notification preference update
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Methods',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationToggle(
                    context,
                    'Push Notifications',
                    'Receive notifications on your device',
                    true,
                    (value) {
                      // TODO: Implement notification method update
                    },
                  ),
                  _buildNotificationToggle(
                    context,
                    'Email Notifications',
                    'Receive notifications via email',
                    true,
                    (value) {
                      // TODO: Implement notification method update
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}
