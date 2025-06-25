import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../orders/data/models/order.dart';
import '../../../orders/data/models/delivery_method.dart';
import '../../../../shared/widgets/dashboard_card.dart';
import '../../../../shared/widgets/quick_action_button.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import '../../../../presentation/providers/repository_providers.dart';
import '../providers/cart_provider.dart';
// TEMPORARILY COMMENTED OUT FOR QUICK WIN
// import '../providers/enhanced_commission_provider.dart';

import 'vendors_screen.dart';
import '../../../orders/presentation/screens/orders_screen.dart';
import '../../../customers/presentation/screens/customers_screen.dart';
import 'sales_agent_profile_screen.dart';

class SalesAgentDashboard extends ConsumerStatefulWidget {
  const SalesAgentDashboard({super.key});

  @override
  ConsumerState<SalesAgentDashboard> createState() => _SalesAgentDashboardState();
}

class _SalesAgentDashboardState extends ConsumerState<SalesAgentDashboard> {
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
      icon: Icon(Icons.store_outlined),
      selectedIcon: Icon(Icons.store),
      label: 'Vendors',
    ),
    const NavigationDestination(
      icon: Icon(Icons.people_outlined),
      selectedIcon: Icon(Icons.people),
      label: 'Customers',
    ),
    const NavigationDestination(
      icon: Icon(Icons.person_outlined),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 SalesAgentDashboard: build() called');
    debugPrint('🏠 SalesAgentDashboard: Current route: ${GoRouterState.of(context).fullPath}');

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _DashboardTab(onNavigateToTab: (index) {
            setState(() {
              _selectedIndex = index;
            });
          }),
          const OrdersScreen(),
          const VendorsScreen(),
          Builder(
            builder: (context) {
              debugPrint('🏗️ SalesAgentDashboard: Building CustomersScreen in IndexedStack');
              return const CustomersScreen();
            },
          ),
          const SalesAgentProfileScreen(),
        ],
      ),
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
}



class _DashboardTab extends ConsumerWidget {
  final ValueChanged<int>? onNavigateToTab;

  const _DashboardTab({this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totalEarnings = ref.watch(totalEarningsProvider);
    final monthlyEarnings = ref.watch(monthlyEarningsProvider);
    final activeOrders = ref.watch(activeOrdersProvider);
    final pendingOrders = ref.watch(pendingOrdersProvider);

    // Real data from repositories
    final recentOrdersAsync = ref.watch(recentOrdersProvider);
    final customerStatsAsync = ref.watch(customerStatisticsProvider);
    // TEMPORARILY COMMENTED OUT FOR QUICK WIN
    // final commissionRateAsync = ref.watch(currentCommissionRateProvider);



    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.developer_mode),
            onPressed: () {
              context.push('/test-sales-agent-profile');
            },
            tooltip: 'Profile Test',
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_checkout),
            onPressed: () {
              context.push('/test-order-creation');
            },
            tooltip: 'Order Creation Test',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              context.go(AppRoutes.settings);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(ordersProvider.notifier).loadOrders();
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
                    Text(
                      'Welcome back!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have ${pendingOrders.length} pending orders to follow up',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Stats
              Row(
                children: [
                  Expanded(
                    child: DashboardCard(
                      title: 'Total Earnings',
                      value: 'RM ${totalEarnings.toStringAsFixed(2)}',
                      subtitle: 'This month: RM ${monthlyEarnings.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DashboardCard(
                      title: 'Active Orders',
                      value: '${activeOrders.length}',
                      subtitle: '${pendingOrders.length} pending',
                      icon: Icons.receipt_long,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: customerStatsAsync.when(
                      data: (stats) => DashboardCard(
                        title: 'Customers',
                        value: '${stats['total_customers'] ?? 0}',
                        subtitle: '${stats['active_customers'] ?? 0} active',
                        icon: Icons.people,
                        color: Colors.purple,
                      ),
                      loading: () => const DashboardCard(
                        title: 'Customers',
                        value: '...',
                        subtitle: 'Loading...',
                        icon: Icons.people,
                        color: Colors.purple,
                      ),
                      error: (_, _) => const DashboardCard(
                        title: 'Customers',
                        value: '0',
                        subtitle: 'Error loading',
                        icon: Icons.people,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: const DashboardCard(
                      title: 'Commission Rate',
                      value: '7.0%',
                      subtitle: 'Default rate',
                      icon: Icons.percent,
                      color: Colors.orange,
                    ),
                  ),
                ],
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
                    child: Consumer(
                      builder: (context, ref, child) {
                        final cartState = ref.watch(cartProvider);
                        return QuickActionButton(
                          icon: cartState.isEmpty
                              ? Icons.add_shopping_cart
                              : Icons.shopping_cart,
                          label: cartState.isEmpty
                              ? 'New Order'
                              : 'New Order (${cartState.totalItems})',
                          onTap: () {
                            // Smart navigation based on cart state
                            if (cartState.isEmpty) {
                              // Navigate directly to vendor browsing for empty cart
                              context.push('/sales-agent/vendors');
                            } else {
                              // Navigate to create order screen for cart with items
                              context.push('/sales-agent/create-order');
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.person_add,
                      label: 'Add Customer',
                      onTap: () {
                        context.push('/sales-agent/customers/add');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.store,
                      label: 'Browse Vendors',
                      onTap: () {
                        // Navigate to vendors tab
                        onNavigateToTab?.call(2); // Vendors tab index
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

              // Recent Orders
              recentOrdersAsync.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No recent orders',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: orders.take(3).map((order) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.restaurant,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: Text('Order #${order.orderNumber}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${order.customerName} • RM ${order.totalAmount.toStringAsFixed(2)}'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildDeliveryTypeIcon(order.deliveryMethod),
                                  const SizedBox(width: 4),
                                  Text(
                                    order.deliveryMethod.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getDeliveryMethodColor(order.deliveryMethod),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.status.displayName,
                              style: TextStyle(
                                color: _getStatusColor(order.status),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          onTap: () {
                            context.push('/order-details/${order.id}');
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Error loading orders: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
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
        return Colors.teal;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _buildDeliveryTypeIcon(DeliveryMethod deliveryMethod) {
    IconData icon;
    Color color = _getDeliveryMethodColor(deliveryMethod);

    switch (deliveryMethod) {
      case DeliveryMethod.customerPickup:
        icon = Icons.store;
        break;
      case DeliveryMethod.salesAgentPickup:
        icon = Icons.person;
        break;
      case DeliveryMethod.ownFleet:
        icon = Icons.local_shipping;
        break;
      case DeliveryMethod.lalamove:
        icon = Icons.delivery_dining;
        break;
    }

    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }

  Color _getDeliveryMethodColor(DeliveryMethod deliveryMethod) {
    switch (deliveryMethod) {
      case DeliveryMethod.customerPickup:
        return Colors.blue;
      case DeliveryMethod.salesAgentPickup:
        return Colors.green;
      case DeliveryMethod.ownFleet:
        return Colors.purple;
      case DeliveryMethod.lalamove:
        return Colors.orange;
    }
  }
}






