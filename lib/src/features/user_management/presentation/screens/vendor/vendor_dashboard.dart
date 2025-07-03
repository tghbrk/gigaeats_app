import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// TODO: Restore when app_constants is used
// import '../../../../core/constants/app_constants.dart';
import '../../../../orders/data/models/order.dart';
import '../../../../../presentation/providers/repository_providers.dart' show
    currentVendorProvider,
    vendorDashboardMetricsProvider,
    vendorTotalOrdersProvider,
    vendorRatingMetricsProvider,
    vendorNotificationsProvider,
    ordersStreamProvider;
import '../../../../shared/widgets/dashboard_card.dart';
import '../../../../shared/widgets/quick_action_button.dart';
import '../../../orders/presentation/screens/vendor/vendor_orders_screen.dart';
import '../../../menu/presentation/screens/vendor/vendor_menu_screen.dart';
import 'driver_management_screen.dart';
import 'vendor_analytics_screen.dart';
import 'vendor_profile_screen.dart';


class VendorDashboard extends ConsumerStatefulWidget {
  const VendorDashboard({super.key});

  @override
  ConsumerState<VendorDashboard> createState() => _VendorDashboardState();
}

class _VendorDashboardState extends ConsumerState<VendorDashboard> {
  int _selectedIndex = 0;

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Orders',
    ),
    const NavigationDestination(
      icon: Icon(Icons.restaurant_menu_outlined),
      selectedIcon: Icon(Icons.restaurant_menu),
      label: 'Menu',
    ),
    const NavigationDestination(
      icon: Icon(Icons.local_shipping_outlined),
      selectedIcon: Icon(Icons.local_shipping),
      label: 'Fleet',
    ),
    const NavigationDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: 'Analytics',
    ),
    const NavigationDestination(
      icon: Icon(Icons.person_outlined),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _destinations,
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return _VendorDashboardTab(onNavigateToTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        });
      case 1:
        return const VendorOrdersScreen();
      case 2:
        return const VendorMenuScreen();
      case 3:
        return const DriverManagementScreen();
      case 4:
        return VendorAnalyticsScreen(onNavigateToTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        });
      case 5:
        return const VendorProfileScreen();
      default:
        // Fallback to dashboard tab but reset index to 0 to prevent confusion
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedIndex != 0) {
            setState(() {
              _selectedIndex = 0;
            });
          }
        });
        return _VendorDashboardTab(onNavigateToTab: (index) {
          setState(() {
            _selectedIndex = index;
          });
        });
    }
  }
}

class _VendorDashboardTab extends ConsumerWidget {
  final ValueChanged<int>? onNavigateToTab;

  const _VendorDashboardTab({this.onNavigateToTab});

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              // TODO: Restore vendorNotificationsProvider when provider is implemented - commented out for analyzer cleanup
              // final notificationsAsync = ref.watch(vendorNotificationsProvider(true)); // unread only
              final notificationsAsync = AsyncValue.data(<Map<String, dynamic>>[]); // Placeholder

              return notificationsAsync.when(
                data: (notifications) {
                  final unreadCount = notifications.length;
                  return IconButton(
                    icon: unreadCount > 0
                      ? Badge(
                          label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
                          child: const Icon(Icons.notifications_outlined),
                        )
                      : const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      // Show notifications bottom sheet
                      _showNotificationsBottomSheet(context, ref);
                    },
                  );
                },
                loading: () => IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    _showNotificationsBottomSheet(context, ref);
                  },
                ),
                error: (_, _) => IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    _showNotificationsBottomSheet(context, ref);
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.developer_mode),
            onPressed: () {
              context.push('/test-consolidated');
            },
            tooltip: 'Vendor Developer Tools',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Restore when AppRoutes is implemented
              // context.go(AppRoutes.settings);
              context.go('/settings'); // Placeholder route
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          debugPrint('🔄 [VENDOR-DASHBOARD] Refreshing vendor data...');

          // Refresh all vendor data
          ref.invalidate(currentVendorProvider);
          ref.invalidate(vendorDashboardMetricsProvider);
          ref.invalidate(vendorTotalOrdersProvider);
          ref.invalidate(vendorRatingMetricsProvider);
          ref.invalidate(vendorNotificationsProvider);

          // Wait for the data to refresh
          try {
            await Future.wait([
              ref.read(currentVendorProvider.future),
              ref.read(vendorDashboardMetricsProvider.future),
              ref.read(vendorTotalOrdersProvider.future),
              ref.read(vendorRatingMetricsProvider.future),
            ]);
            debugPrint('✅ [VENDOR-DASHBOARD] Data refresh completed');
          } catch (e) {
            debugPrint('❌ [VENDOR-DASHBOARD] Data refresh failed: $e');
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        debugPrint('🏪 [VENDOR-DASHBOARD] Building header section...');
                        final vendorAsync = ref.watch(currentVendorProvider);
                        final metricsAsync = ref.watch(vendorDashboardMetricsProvider);

                        return vendorAsync.when(
                          data: (vendor) {
                            final vendorName = vendor?.businessName ?? 'Vendor';
                            final pendingOrders = metricsAsync.when(
                              data: (metrics) => metrics['pending_orders'] ?? 0,
                              loading: () => 0,
                              error: (_, _) => 0,
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, $vendorName!',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  pendingOrders > 0
                                    ? 'You have $pendingOrders new orders to process'
                                    : 'No pending orders at the moment',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome!',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Loading...',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                          error: (error, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome!',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Error loading data',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Quick Stats
              Consumer(
                builder: (context, ref, child) {
                  debugPrint('📊 [VENDOR-DASHBOARD] Building quick stats section...');
                  final metricsAsync = ref.watch(vendorDashboardMetricsProvider);

                  return Row(
                    children: [
                      Expanded(
                        child: metricsAsync.when(
                          data: (metrics) {
                            final todayRevenue = metrics['today_revenue'] ?? 0.0;
                            return DashboardCard(
                              title: 'Today\'s Revenue',
                              value: 'RM ${todayRevenue.toStringAsFixed(2)}',
                              subtitle: 'Today',
                              icon: Icons.trending_up,
                              color: Colors.green,
                            );
                          },
                          loading: () => DashboardCard(
                            title: 'Today\'s Revenue',
                            value: '...',
                            subtitle: 'Loading...',
                            icon: Icons.trending_up,
                            color: Colors.green,
                          ),
                          error: (_, _) => DashboardCard(
                            title: 'Today\'s Revenue',
                            value: 'RM 0.00',
                            subtitle: 'Error',
                            icon: Icons.trending_up,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: metricsAsync.when(
                          data: (metrics) {
                            final pendingOrders = metrics['pending_orders'] ?? 0;
                            return DashboardCard(
                              title: 'Pending Orders',
                              value: '$pendingOrders',
                              subtitle: pendingOrders > 0 ? 'Needs attention' : 'All caught up',
                              icon: Icons.pending_actions,
                              color: pendingOrders > 0 ? Colors.orange : Colors.green,
                            );
                          },
                          loading: () => DashboardCard(
                            title: 'Pending Orders',
                            value: '...',
                            subtitle: 'Loading...',
                            icon: Icons.pending_actions,
                            color: Colors.orange,
                          ),
                          error: (_, _) => DashboardCard(
                            title: 'Pending Orders',
                            value: '0',
                            subtitle: 'Error',
                            icon: Icons.pending_actions,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              Consumer(
                builder: (context, ref, child) {
                  debugPrint('📈 [VENDOR-DASHBOARD] Building metrics section...');
                  final totalOrdersAsync = ref.watch(vendorTotalOrdersProvider);
                  final ratingMetricsAsync = ref.watch(vendorRatingMetricsProvider);

                  return Row(
                    children: [
                      Expanded(
                        child: totalOrdersAsync.when(
                          data: (totalOrders) => DashboardCard(
                            title: 'Total Orders',
                            value: '$totalOrders',
                            subtitle: 'All time',
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                          ),
                          loading: () => DashboardCard(
                            title: 'Total Orders',
                            value: '...',
                            subtitle: 'Loading...',
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                          ),
                          error: (_, _) => DashboardCard(
                            title: 'Total Orders',
                            value: '0',
                            subtitle: 'Error',
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ratingMetricsAsync.when(
                          data: (metrics) => DashboardCard(
                            title: 'Rating',
                            value: '${metrics['rating']}',
                            subtitle: 'Based on ${metrics['total_reviews']} orders',
                            icon: Icons.star,
                            color: Colors.amber,
                          ),
                          loading: () => DashboardCard(
                            title: 'Rating',
                            value: '...',
                            subtitle: 'Loading...',
                            icon: Icons.star,
                            color: Colors.amber,
                          ),
                          error: (_, _) => DashboardCard(
                            title: 'Rating',
                            value: '0.0',
                            subtitle: 'Error',
                            icon: Icons.star,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.add_circle,
                      title: 'Add Menu Item', // Changed from label to title
                      onTap: () {
                        // Navigate to menu tab
                        onNavigateToTab?.call(2);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.inventory,
                      title: 'Update Stock', // Changed from label to title
                      onTap: () {
                        // Navigate to menu tab
                        onNavigateToTab?.call(2);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.analytics,
                      title: 'View Reports', // Changed from label to title
                      onTap: () {
                        // Navigate to analytics tab
                        onNavigateToTab?.call(3);
                      },
                    ),
                  ),
                ],
              ),


              
              const SizedBox(height: 24),
              
              // Recent Orders
              Text(
                'Recent Orders',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Real orders from Supabase using proper Riverpod provider
              Consumer(
                key: const ValueKey('vendor_dashboard_orders_consumer'),
                builder: (context, ref, child) {
                  debugPrint('📋 [VENDOR-DASHBOARD] Building orders section...');
                  final ordersStream = ref.watch(ordersStreamProvider(null));

                  return ordersStream.when(
                    data: (orders) {
                      // Show only recent orders (last 5)
                      final recentOrders = orders.take(5).toList();

                      if (recentOrders.isEmpty) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No orders yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Orders will appear here when customers place them',
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

                      return Column(
                        children: recentOrders.map((order) {
                          Color statusColor;
                          switch (order.status) {
                            case OrderStatus.pending:
                              statusColor = Colors.orange;
                              break;
                            case OrderStatus.confirmed:
                              statusColor = Colors.blue;
                              break;
                            case OrderStatus.preparing:
                              statusColor = Colors.purple;
                              break;
                            case OrderStatus.ready:
                              statusColor = Colors.green;
                              break;
                            case OrderStatus.outForDelivery:
                              statusColor = Colors.indigo;
                              break;
                            case OrderStatus.delivered:
                              statusColor = Colors.teal;
                              break;
                            case OrderStatus.cancelled:
                              statusColor = Colors.red;
                              break;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: statusColor.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.restaurant,
                                  color: statusColor,
                                ),
                              ),
                              title: Text('Order #${order.id.substring(0, 8)}'),
                              subtitle: Text(
                                '${order.customerName} • ${_formatDateTime(order.createdAt)}',
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  order.status.name.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              onTap: () {
                                debugPrint('🔍 [DASHBOARD-ORDER-TAP] Dashboard order card tapped for order: ${order.id}');
                                debugPrint('🔍 [DASHBOARD-ORDER-TAP] Order number: ${order.orderNumber}');
                                final route = '/vendor/dashboard/order-details/${order.id}';
                                debugPrint('🔍 [DASHBOARD-ORDER-TAP] Navigating to route: $route');
                                debugPrint('🔍 [DASHBOARD-ORDER-TAP] About to call context.push()...');
                                context.push(route);
                                debugPrint('🔍 [DASHBOARD-ORDER-TAP] context.push() completed');
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error loading orders: $error',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    debugPrint('🔔 [VENDOR-DASHBOARD] Building notifications section...');
                    final notificationsAsync = ref.watch(vendorNotificationsProvider(null)); // all notifications

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
                                  'No notifications yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: notification['is_read'] == true
                                  ? Colors.grey.withValues(alpha: 0.3)
                                  : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                child: Icon(
                                  _getNotificationIcon(notification['type'] ?? 'info'),
                                  color: notification['is_read'] == true
                                    ? Colors.grey
                                    : Theme.of(context).primaryColor,
                                ),
                              ),
                              title: Text(
                                notification['title'] ?? 'Notification',
                                style: TextStyle(
                                  fontWeight: notification['is_read'] == true
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(notification['message'] ?? ''),
                              trailing: Text(
                                _formatDateTime(DateTime.parse(notification['created_at'])),
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                // Mark as read and handle action
                                if (notification['action_url'] != null) {
                                  // Navigate to action URL
                                }
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, _) => Center(
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
                              'Error loading notifications: $error',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      case 'info':
      default:
        return Icons.info;
    }
  }


}


