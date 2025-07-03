import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: Restore when go_router is used
// import 'package:go_router/go_router.dart';
// TODO: Restore missing URI imports when customer notification components are implemented
// import '../providers/customer_notification_provider.dart';
// import '../widgets/customer_notification_bell.dart';
// import '../../../../shared/widgets/custom_error_widget.dart';

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
    // TODO: Restore when customerNotificationProvider is implemented
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   ref.read(customerNotificationProvider.notifier).refresh();
    // });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // TODO: Restore when customerNotificationProvider is implemented
    // final notificationState = ref.watch(customerNotificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          // TODO: Restore when customerNotificationProvider is implemented
          /*if (notificationState.unreadCount > 0)
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
            ),*/
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Restore when customerNotificationProvider is implemented
              // ref.read(customerNotificationProvider.notifier).refresh();
            },
          ),
        ],
      ),
      // TODO: Restore when notificationState is implemented
      body: const Center(child: Text('Notifications not available')),
      // body: _buildBody(context, notificationState),
    );
  }

  // TODO: Use _buildBody when notification display is restored
  /*
  Widget _buildBody(BuildContext context, CustomerNotificationState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      // TODO: Restore when CustomerNotificationLoading is implemented
      // return const CustomerNotificationLoading();
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      // TODO: Restore when CustomErrorWidget is implemented
      // return CustomErrorWidget(
      //   message: 'Failed to load notifications: ${state.error}',
      //   onRetry: () {
      //     ref.read(customerNotificationProvider.notifier).clearError();
      //     ref.read(customerNotificationProvider.notifier).refresh();
      //   },
      // );
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Failed to load notifications: ${state.error}'),
            ElevatedButton(
              onPressed: () {
                // TODO: Restore when customerNotificationProvider is implemented
                // ref.read(customerNotificationProvider.notifier).clearError();
                // ref.read(customerNotificationProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.notifications.isEmpty) {
      // TODO: Restore when CustomerNotificationEmptyState is implemented
      // return const CustomerNotificationEmptyState();
      return const Center(child: Text('No notifications available'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Restore when customerNotificationProvider is implemented
        // await ref.read(customerNotificationProvider.notifier).refresh();
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
                // TODO: Restore when CustomerNotificationItem is implemented
                // return CustomerNotificationItem(
                //   notificationId: notification.id,
                //   title: notification.title,
                //   message: notification.message,
                //   createdAt: notification.createdAt,
                //   isRead: notification.isRead,
                //   orderId: notification.orderId,
                //   onTap: () {
                //     // Handle specific notification types
                //     _handleNotificationTap(notification.orderId, notification.data);
                //   },
                // );
                return ListTile(
                  title: Text(notification.title),
                  subtitle: Text(notification.message),
                  trailing: notification.isRead
                    ? null
                    : const Icon(Icons.circle, color: Colors.blue, size: 8),
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
  */
}
