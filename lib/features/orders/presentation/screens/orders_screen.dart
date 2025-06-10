import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/order.dart';
import '../../data/models/delivery_method.dart';
import '../providers/order_provider.dart';
// import '../utils/order_status_update_helper.dart';
import '../../../../presentation/providers/repository_providers.dart';
import '../../../sales_agent/presentation/providers/cart_provider.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../core/utils/responsive_utils.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
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
    // Use platform-aware data fetching
    if (kIsWeb) {
      // For web platform, use FutureProvider
      final ordersAsync = ref.watch(platformOrdersProvider);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(platformOrdersProvider);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Active', icon: Icon(Icons.pending_actions)),
              Tab(text: 'Ready', icon: Icon(Icons.delivery_dining)),
              Tab(text: 'History', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: ordersAsync.when(
          data: (allOrders) {
            // Filter orders for different tabs
            final activeOrders = allOrders
                .where((order) =>
                    order.status != OrderStatus.delivered &&
                    order.status != OrderStatus.cancelled &&
                    order.status != OrderStatus.ready)
                .toList();
            // Sort by creation date descending (newest first)
            activeOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final readyOrders = allOrders
                .where((order) => order.status == OrderStatus.ready)
                .toList();
            // Sort by creation date descending (newest first)
            readyOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final historyOrders = allOrders
                .where((order) =>
                    order.status == OrderStatus.delivered ||
                    order.status == OrderStatus.cancelled)
                .toList();
            // Sort by creation date descending (newest first)
            historyOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(activeOrders),
                _buildOrdersList(readyOrders),
                _buildOrdersList(historyOrders),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error.toString()),
        ),
        floatingActionButton: Consumer(
          builder: (context, ref, child) {
            final cartState = ref.watch(cartProvider);
            return FloatingActionButton.extended(
              heroTag: "orders_new_order_fab",
              onPressed: () {
                // Smart navigation based on cart state
                if (cartState.isEmpty) {
                  // Navigate directly to vendor browsing for empty cart
                  context.push('/sales-agent/vendors');
                } else {
                  // Navigate to create order screen for cart with items
                  context.push('/sales-agent/create-order');
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('New Order'),
            );
          },
        ),
      );
    } else {
      // For mobile platform, use existing notifier pattern
      final ordersState = ref.watch(ordersProvider);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(ordersProvider.notifier).loadOrders();
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Active', icon: Icon(Icons.pending_actions)),
              Tab(text: 'Ready', icon: Icon(Icons.delivery_dining)),
              Tab(text: 'History', icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: ordersState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ordersState.errorMessage != null
                ? _buildErrorState(ordersState.errorMessage!)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersList(ref.watch(activeOrdersProvider)),
                      _buildOrdersList(ref.watch(readyOrdersProvider)),
                      _buildOrdersList(ref.watch(historyOrdersProvider)),
                    ],
                  ),
        floatingActionButton: Consumer(
          builder: (context, ref, child) {
            final cartState = ref.watch(cartProvider);
            return FloatingActionButton.extended(
              heroTag: "orders_new_order_fab_mobile",
              onPressed: () {
                // Smart navigation based on cart state
                if (cartState.isEmpty) {
                  // Navigate directly to vendor browsing for empty cart
                  context.push('/sales-agent/vendors');
                } else {
                  // Navigate to create order screen for cart with items
                  context.push('/sales-agent/create-order');
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('New Order'),
            );
          },
        ),
      );
    }
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading orders',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Retry',
            onPressed: () {
              ref.read(ordersProvider.notifier).loadOrders();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (kIsWeb) {
          ref.invalidate(platformOrdersProvider);
        } else {
          ref.read(ordersProvider.notifier).loadOrders();
        }
      },
      child: ResponsiveContainer(
        child: context.isDesktop
            ? _buildDesktopOrdersList(orders)
            : _buildMobileOrdersList(orders),
      ),
    );
  }

  Widget _buildMobileOrdersList(List<Order> orders) {
    return ListView.builder(
      padding: context.responsivePadding,
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildDesktopOrdersList(List<Order> orders) {
    return GridView.builder(
      padding: context.responsivePadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first order to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          Consumer(
            builder: (context, ref, child) {
              final cartState = ref.watch(cartProvider);
              return CustomButton(
                text: 'Create Order',
                onPressed: () {
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
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to order details
          context.push('/order-details/${order.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header with status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.orderNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Customer Info with contact
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (order.contactPhone != null) ...[
                    Icon(
                      Icons.phone,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.contactPhone!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),

              // Vendor and Total Amount
              Row(
                children: [
                  Icon(
                    Icons.store,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.vendorName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  Text(
                    'RM ${order.totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Order Items and Commission
              Row(
                children: [
                  Text(
                    '${order.items.length} item(s)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Commission: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    'RM ${(order.commissionAmount ?? 0.0).toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Delivery Type and Date Info
              Row(
                children: [
                  _buildDeliveryTypeChip(order.deliveryMethod),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatDate(order.deliveryDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  // Quick actions for specific statuses
                  if (order.status == OrderStatus.pending ||
                      order.status == OrderStatus.ready)
                    _buildQuickActions(order),
                ],
              ),

              // Main action buttons (only if no quick actions shown)
              if (order.status != OrderStatus.pending &&
                  order.status != OrderStatus.ready) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'View Details',
                    height: 48,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    onPressed: () {
                      context.push('/order-details/${order.id}');
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(Order order) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (order.status == OrderStatus.ready && order.salesAgentCanMarkDelivered) ...[
          _buildActionButton(
            'Delivered',
            Icons.check_circle,
            Colors.green,
            () => _markAsDelivered(order),
          ),
          const SizedBox(width: 8),
        ],
        _buildActionButton(
          'Details',
          Icons.visibility,
          Theme.of(context).colorScheme.primary,
          () => context.push('/order-details/${order.id}'),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 12),
          minimumSize: const Size(0, 32),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDeliveryTypeChip(DeliveryMethod deliveryMethod) {
    final theme = Theme.of(context);

    // Get appropriate icon and color for each delivery method
    IconData icon;
    Color color;

    switch (deliveryMethod) {
      case DeliveryMethod.customerPickup:
        icon = Icons.store;
        color = Colors.blue;
        break;
      case DeliveryMethod.salesAgentPickup:
        icon = Icons.person;
        color = Colors.green;
        break;
      case DeliveryMethod.ownFleet:
        icon = Icons.local_shipping;
        color = Colors.purple;
        break;
      case DeliveryMethod.lalamove:
        icon = Icons.delivery_dining;
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            deliveryMethod.displayName,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsDelivered(Order order) async {
    // Validate that sales agent can mark this order as delivered
    if (!order.salesAgentCanMarkDelivered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can only mark sales agent pickup orders as delivered. '
            'This order uses ${order.deliveryMethod.displayName}.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Update order status
      final orderRepository = ref.read(orderRepositoryProvider);
      await orderRepository.updateOrderStatus(order.id, OrderStatus.delivered);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${order.orderNumber} marked as delivered'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh orders
        if (kIsWeb) {
          ref.invalidate(platformOrdersProvider);
        } else {
          ref.read(ordersProvider.notifier).loadOrders();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
