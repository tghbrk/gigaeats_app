import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Customer-specific providers
import '../providers/customer_order_provider.dart';
import '../../providers/customer_address_provider.dart' as address_provider;

// Order-related imports
import '../../../../orders/data/models/order.dart';

// Wallet-related imports
import '../../../../marketplace_wallet/presentation/providers/customer_wallet_provider.dart';
import '../../../../marketplace_wallet/presentation/widgets/customer_wallet_balance_card.dart';

// Design system imports
import '../../../../../design_system/design_system.dart';
import '../../../../../data/models/user_role.dart';

class CustomerDashboard extends ConsumerStatefulWidget {
  const CustomerDashboard({super.key});

  @override
  ConsumerState<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends ConsumerState<CustomerDashboard> {
  int _selectedIndex = 0;
  
  // Use GE navigation configuration for customer role
  final _navigationConfig = GERoleNavigationConfig.customer;

  @override
  void initState() {
    super.initState();
    // Load customer data when dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load customer addresses for dashboard display
      ref.read(address_provider.customerAddressesProvider.notifier).loadAddresses();
      
      // Load customer wallet data
      ref.read(customerWalletProvider.notifier).loadWallet();
      
      print('🧪 [LOYALTY-TEST] Loading loyalty data from dashboard...');
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: _selectedIndex == 0 ? AppBar(
        title: const Text('GigaEats'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/customer/profile'),
          ),
        ],
      ) : null,
      body: _selectedIndex == 0
        ? RefreshIndicator(
            onRefresh: () async {
              // Refresh customer data
              ref.invalidate(customerOrdersProvider(''));
              ref.invalidate(customerWalletProvider);
              ref.invalidate(address_provider.customerAddressesProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildWelcomeCard(context),
                const SizedBox(height: 24),
                _buildQuickStats(context, ref),
                const SizedBox(height: 24),
                _buildWalletSection(ref),
                const SizedBox(height: 24),
                _buildRecentOrders(context, ref),
              ],
            ),
          )
        : _buildCurrentTab(),
      bottomNavigationBar: GEBottomNavigation.navigationBar(
        destinations: _navigationConfig.destinations,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // Only navigate for non-dashboard tabs
          if (index != 0) {
            _handleNavigation(context, index);
          }
        },
        userRole: UserRole.customer,
      ),
    );
  }

  Widget _buildCurrentTab() {
    // For customer dashboard, we only show content for the home tab (index 0)
    // All other tabs should navigate to their respective screens
    switch (_selectedIndex) {
      case 0:
        return const _CustomerDashboardTab();
      default:
        // This should not be reached as navigation should occur
        return const _CustomerDashboardTab();
    }
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Already on dashboard - no navigation needed
        break;
      case 1:
        // Navigate to restaurants screen
        context.push('/customer/restaurants');
        break;
      case 2:
        // Navigate to orders screen
        context.push('/customer/orders');
        break;
      case 3:
        // Navigate to wallet screen
        context.push('/customer/wallet');
        break;
    }
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hungry?',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discover amazing restaurants near you',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.restaurant_menu,
                  size: 48,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Browse Restaurants'),
                onPressed: () => context.push('/restaurants'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(customerOrdersProvider(''));

    return ordersAsync.when(
      data: (orders) {
        final totalOrders = orders.length;
        final totalSpent = orders.fold<double>(
          0.0,
          (sum, order) => sum + order.totalAmount,
        );

        return Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        '$totalOrders',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Total Orders'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.attach_money, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'RM ${totalSpent.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Total Spent'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '0',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Loading...'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.attach_money, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'RM 0.00',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Loading...'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      error: (_, stackTrace) => Row(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      '0',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Error'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.attach_money, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'RM 0.00',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Error'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSection(WidgetRef ref) {
    return const CustomerWalletBalanceCard();
  }

  Widget _buildRecentOrders(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(customerOrdersProvider(''));

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by browsing restaurants',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/restaurants'),
                    child: const Text('Browse Restaurants'),
                  ),
                ],
              ),
            ),
          );
        }

        // Show recent orders (last 3)
        final recentOrders = orders.take(3).toList();

        return Column(
          children: recentOrders.map((order) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(order.status).withValues(alpha: 0.1),
                  child: Icon(
                    _getStatusIcon(order.status),
                    color: _getStatusColor(order.status),
                  ),
                ),
                title: Text('Order #${order.id.substring(0, 8)}'),
                subtitle: Text(
                  '${order.vendorName} • ${_formatDateTime(order.createdAt)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'RM ${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        order.status.name.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () => context.push('/customer/orders/${order.id}'),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, stackTrace) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading orders',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please try again later',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.teal;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.done_all;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

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
}

class _CustomerDashboardTab extends ConsumerWidget {
  const _CustomerDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This widget is no longer used since we moved the content to the main build method
    return const Center(
      child: Text('Dashboard content moved to main build method'),
    );
  }
}
