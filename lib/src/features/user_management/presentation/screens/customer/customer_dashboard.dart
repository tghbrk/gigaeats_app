import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// TODO: Restore when customer_profile_provider is implemented
// import '../providers/customer_profile_provider.dart';
import '../providers/customer_order_provider.dart';
import '../../providers/customer_address_provider.dart' as address_provider;
// TODO: Restore when loyalty_provider is used
// import '../providers/loyalty_provider.dart';
// TODO: Restore when auth_provider is used
// import '../../../../features/auth/presentation/providers/auth_provider.dart';

// Order-related imports - using the correct path that matches the provider
import '../../../../orders/data/models/order.dart';

// Wallet-related imports
import '../../../../marketplace_wallet/presentation/providers/customer_wallet_provider.dart';
import '../../../../marketplace_wallet/presentation/widgets/customer_wallet_balance_card.dart';

class CustomerDashboard extends ConsumerStatefulWidget {
  const CustomerDashboard({super.key});

  @override
  ConsumerState<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends ConsumerState<CustomerDashboard> {
  @override
  void initState() {
    super.initState();
    // Load customer profile when dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // TODO: Restore when customerProfileProvider.notifier is implemented
      // ref.read(customerProfileProvider.notifier).loadProfile();

      // Load customer addresses for dashboard display
      ref.read(address_provider.customerAddressesProvider.notifier).loadAddresses();

      // Load customer wallet data
      ref.read(customerWalletProvider.notifier).loadWallet();

      // 🧪 [LOYALTY-TEST] Load loyalty data for testing real-time updates
      print('🧪 [LOYALTY-TEST] Loading loyalty data from dashboard...');
      // TODO: Restore when loyaltyProvider.notifier.loadLoyaltyData is implemented
      // ref.read(loyaltyProvider.notifier).loadLoyaltyData(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Restore when customerProfileProvider watch is implemented
    // final profileState = ref.watch(customerProfileProvider);
    // TODO: Restore when authStateProvider is implemented
    // final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GigaEats'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/customer/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/customer/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Restore when customerProfileProvider.notifier is implemented
          // ref.read(customerProfileProvider.notifier).refresh();

          // Refresh wallet data
          await ref.read(customerWalletProvider.notifier).loadWallet(forceRefresh: true);

          // Refresh addresses
          ref.read(address_provider.customerAddressesProvider.notifier).loadAddresses();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TODO: Restore when profileState and authState are implemented
              // _buildWelcomeSection(context, profileState, authState),
              _buildWelcomeSection(context, <String, dynamic>{}, <String, dynamic>{}),
              const SizedBox(height: 24),

              // Wallet Balance Card
              const CustomerWalletBalanceCard(compact: true),
              const SizedBox(height: 24),

              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildStatsSection(context),
              const SizedBox(height: 24),
              _buildRecentOrdersSection(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  // TODO: Restore when CustomerProfileState and AuthState classes are implemented
  Widget _buildWelcomeSection(BuildContext context, Map<String, dynamic> profileState, Map<String, dynamic> authState) {
    final theme = Theme.of(context);
    final profile = profileState['profile'];
    final user = authState['user'];

    return Container(
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
            backgroundImage: profile?.profileImageUrl != null
                ? NetworkImage(profile!.profileImageUrl!)
                : null,
            child: profile?.profileImageUrl == null
                ? Icon(
                    Icons.person,
                    size: 30,
                    color: theme.colorScheme.onPrimary,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  profile?.fullName ?? user?.fullName ?? 'Customer',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (profile?.loyaltyPoints != null && profile!.loyaltyPoints > 0)
                  Text(
                    '${profile.loyaltyPoints} loyalty points',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.restaurant,
                title: 'Browse Restaurants',
                subtitle: 'Find your favorite food',
                onTap: () => context.push('/customer/restaurants'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.shopping_cart,
                title: 'My Cart',
                subtitle: 'View cart items',
                onTap: () => context.push('/customer/cart'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.history,
                title: 'Order History',
                subtitle: 'View past orders',
                onTap: () => context.push('/customer/orders'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.account_balance_wallet,
                title: 'Wallet',
                subtitle: 'Manage payments & balance',
                onTap: () => context.push('/customer/wallet'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final addressesState = ref.watch(address_provider.customerAddressesProvider);
                  final addressCount = addressesState.addresses.length;

                  String subtitle;
                  if (addressCount == 0) {
                    subtitle = 'Add delivery address';
                  } else if (addressCount == 1) {
                    subtitle = '1 address saved';
                  } else {
                    subtitle = '$addressCount addresses saved';
                  }

                  return _buildActionCard(
                    context,
                    icon: Icons.location_on,
                    title: 'Addresses',
                    subtitle: subtitle,
                    onTap: () => context.push('/customer/addresses'),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(), // Empty space for symmetry
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Stack(
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  if (badge != null)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    // TODO: Restore when customerStatsProvider watch is implemented
    // final stats = ref.watch(customerStatsProvider);
    final stats = <String, dynamic>{}; // Placeholder
    final theme = Theme.of(context);

    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stats',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Total Orders',
                value: '${stats['totalOrders'] ?? 0}',
                icon: Icons.receipt_long,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Total Spent',
                value: 'RM ${(stats['totalSpent'] ?? 0.0).toStringAsFixed(2)}',
                icon: Icons.attach_money,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection(BuildContext context) {
    debugPrint('🔍 [CUSTOMER-DASHBOARD] ===== _buildRecentOrdersSection CALLED =====');

    final recentOrdersAsync = ref.watch(currentCustomerRecentOrdersProvider);

    debugPrint('🔍 [CUSTOMER-DASHBOARD] Recent orders async state: ${recentOrdersAsync.runtimeType}');
    recentOrdersAsync.when(
      data: (orders) {
        debugPrint('🔍 [CUSTOMER-DASHBOARD] Received ${orders.length} orders from recent orders provider');
        final statusCounts = <String, int>{};
        for (final order in orders) {
          final status = order.status.value;
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        }
        debugPrint('🔍 [CUSTOMER-DASHBOARD] Status distribution: $statusCounts');

        // Log recent orders details
        for (int i = 0; i < orders.length && i < 5; i++) {
          final order = orders[i];
          debugPrint('🔍 [CUSTOMER-DASHBOARD] Recent order ${i + 1}: ${order.orderNumber} - ${order.status.value} (${order.status.displayName}) - ${order.items.length} items');
        }
      },
      loading: () => debugPrint('🔍 [CUSTOMER-DASHBOARD] Recent orders are loading...'),
      error: (error, stack) => debugPrint('🔍 [CUSTOMER-DASHBOARD] Recent orders error: $error'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Orders',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/customer/orders'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        recentOrdersAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return _buildEmptyOrdersCard(context);
            }
            return Column(
              children: orders.take(3).map((order) => _buildOrderCard(context, order)).toList(),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load orders',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please try again later',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildBottomNavigation(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0, // Dashboard is selected
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on dashboard
            break;
          case 1:
            context.push('/customer/restaurants');
            break;
          case 2:
            context.push('/customer/cart');
            break;
          case 3:
            context.push('/customer/orders');
            break;
          case 4:
            context.push('/customer/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant),
          label: 'Restaurants',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildEmptyOrdersCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No recent orders',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Start ordering to see your order history here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/customer/order/${order.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.orderNumber}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.vendorName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(order.status, theme),
                ],
              ),

              const SizedBox(height: 12),

              // Order details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RM ${order.totalAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy').format(order.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('hh:mm a').format(order.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status, ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        text = 'Pending';
        break;
      case OrderStatus.confirmed:
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        text = 'Confirmed';
        break;
      case OrderStatus.preparing:
        backgroundColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple;
        text = 'Preparing';
        break;
      case OrderStatus.ready:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        text = 'Ready';
        break;
      case OrderStatus.outForDelivery:
        backgroundColor = Colors.indigo.withValues(alpha: 0.1);
        textColor = Colors.indigo;
        text = 'Out for Delivery';
        break;
      case OrderStatus.delivered:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        text = 'Delivered';
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // TODO: Restore original Order type when conflicts are resolved
  // Original: Widget _buildOrderCard(BuildContext context, Order order) {
  // Method removed - replaced with _buildPlaceholderOrderCard to avoid type conflicts
  /*
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.push('/customer/order/${order.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderNumber,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.vendorName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              // Delivery type indicator
              // TODO: Restore when order.deliveryMethod is implemented
              // _buildDeliveryTypeChip(order.deliveryMethod, theme),
              _buildDeliveryTypeChip(DeliveryMethod.customerPickup, theme), // Placeholder
              const SizedBox(height: 8),
              Text(
                'RM ${order.totalAmount.toStringAsFixed(2)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(order.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TODO: Restore original OrderStatus type when conflicts are resolved
  // Original: Color _getStatusColor(OrderStatus status) {
  Color _getStatusColor(orders_order.OrderStatus status) {
    switch (status) {
      case orders_order.OrderStatus.pending:
        return Colors.orange;
      case orders_order.OrderStatus.confirmed:
        return Colors.blue;
      case orders_order.OrderStatus.preparing:
        return Colors.purple;
      case orders_order.OrderStatus.ready:
        return Colors.green;
      case orders_order.OrderStatus.outForDelivery:
        return Colors.teal;
      case orders_order.OrderStatus.delivered:
        return Colors.green;
      case orders_order.OrderStatus.cancelled:
        return Colors.red;
    }
  }

  // TODO: Restore original OrderStatus type when conflicts are resolved
  // Original: String _getStatusText(OrderStatus status) {
  String _getStatusText(orders_order.OrderStatus status) {
    switch (status) {
      case orders_order.OrderStatus.pending:
        return 'Pending';
      case orders_order.OrderStatus.confirmed:
        return 'Confirmed';
      case orders_order.OrderStatus.preparing:
        return 'Preparing';
      case orders_order.OrderStatus.ready:
        return 'Ready';
      case orders_order.OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case orders_order.OrderStatus.delivered:
        return 'Delivered';
      case orders_order.OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Widget _buildDeliveryTypeChip(DeliveryMethod deliveryMethod, ThemeData theme) {
    IconData icon;
    Color color;
    String label;

    switch (deliveryMethod) {
      case DeliveryMethod.customerPickup:
        icon = Icons.store;
        color = Colors.blue;
        label = 'Pickup';
        break;
      case DeliveryMethod.salesAgentPickup:
        icon = Icons.person_pin_circle;
        color = Colors.green;
        label = 'Agent Pickup';
        break;
      case DeliveryMethod.ownFleet:
        icon = Icons.local_shipping;
        color = Colors.purple;
        label = 'Own Fleet';
        break;
      // TODO: Restore when DeliveryMethod.lalamove is implemented
      /*case DeliveryMethod.lalamove:
        icon = Icons.delivery_dining;
        color = Colors.orange;
        label = 'Lalamove';
        break;*/
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }
  */

}
