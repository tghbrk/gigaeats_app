import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/order.dart';
// import '../../utils/order_status_update_helper.dart';
import '../../../../../presentation/providers/repository_providers.dart';
import '../../../../vendors/presentation/widgets/assign_driver_dialog.dart';

import '../../../../../core/utils/responsive_utils.dart';

class VendorOrdersScreen extends ConsumerStatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  ConsumerState<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends ConsumerState<VendorOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Preparing'),
            Tab(text: 'Ready'),
            Tab(text: 'Upcoming'),
            Tab(text: 'History'),
          ],
          onTap: (index) {
            setState(() {
              // Tab selection is handled by TabController
              // Custom filtering is done in the build methods
            });
          },
        ),
        actions: [
          // Real-time connection status indicator
          Consumer(
            builder: (context, ref, child) {
              // TODO: Restore real-time connection status when implemented
              // ignore: unused_local_variable
              final isConnected = true; // Temporarily simplified for quick launch
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green, // Simplified since isConnected is always true
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Live', // Simplified since isConnected is always true
                      style: TextStyle(
                        color: Colors.green, // Simplified since isConnected is always true
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (kIsWeb) {
                ref.invalidate(platformOrdersProvider);
              } else {
                ref.invalidate(ordersStreamProvider);
              }
            },
          ),
        ],
      ),
      body: _buildOrdersList(),
    );
  }

  Widget _buildOrdersList() {
    debugPrint('🔍 [VENDOR-ORDERS-SCREEN] _buildOrdersList called');

    // Use platform-aware data fetching
    if (kIsWeb) {
      debugPrint('🔍 [VENDOR-ORDERS-SCREEN] Using web platform provider');
      // For web platform, use FutureProvider
      final ordersAsync = ref.watch(platformOrdersProvider);

      return ordersAsync.when(
        data: (allOrders) {
          // Apply custom filtering for web based on tab selection
          List<Order> orders;
          final tabIndex = _tabController.index;

          switch (tabIndex) {
            case 0: // Preparing
              orders = allOrders.where((order) => order.status == OrderStatus.preparing).toList();
              break;
            case 1: // Ready
              orders = allOrders.where((order) => order.status == OrderStatus.ready).toList();
              break;
            case 2: // Upcoming
              final now = DateTime.now();
              orders = allOrders.where((order) =>
                order.status == OrderStatus.pending ||
                order.status == OrderStatus.confirmed ||
                (order.deliveryDate.isAfter(now) &&
                 !order.status.isDelivered &&
                 !order.status.isCancelled)
              ).toList();
              break;
            case 3: // History
              orders = allOrders.where((order) =>
                order.status == OrderStatus.delivered ||
                order.status == OrderStatus.cancelled
              ).toList();
              break;
            default:
              orders = allOrders;
          }

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getEmptyStateMessage(tabIndex),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(platformOrdersProvider);
            },
            child: ResponsiveContainer(
              child: context.isDesktop
                  ? _buildDesktopOrdersList(orders)
                  : _buildMobileOrdersList(orders),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading orders: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(platformOrdersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    } else {
      debugPrint('🔍 [VENDOR-ORDERS-SCREEN] Using mobile platform provider');
      // For mobile platform, use StreamProvider with custom filtering
      final ordersStream = ref.watch(ordersStreamProvider(null)); // Get all orders
      debugPrint('🔍 [VENDOR-ORDERS-SCREEN] Watching ordersStreamProvider(null)');

      return ordersStream.when(
        data: (allOrders) {
          debugPrint('🔍 [VENDOR-ORDERS-SCREEN] ordersStream.data received: ${allOrders.length} orders');
          // Apply custom filtering for mobile based on tab selection
          List<Order> orders;
          final tabIndex = _tabController.index;
          debugPrint('🔍 [VENDOR-ORDERS-SCREEN] Current tab index: $tabIndex');

          switch (tabIndex) {
            case 0: // Preparing
              orders = allOrders.where((order) => order.status == OrderStatus.preparing).toList();
              break;
            case 1: // Ready
              orders = allOrders.where((order) => order.status == OrderStatus.ready).toList();
              break;
            case 2: // Upcoming
              final now = DateTime.now();
              orders = allOrders.where((order) =>
                order.status == OrderStatus.pending ||
                order.status == OrderStatus.confirmed ||
                (order.deliveryDate.isAfter(now) &&
                 !order.status.isDelivered &&
                 !order.status.isCancelled)
              ).toList();
              break;
            case 3: // History
              orders = allOrders.where((order) =>
                order.status == OrderStatus.delivered ||
                order.status == OrderStatus.cancelled
              ).toList();
              break;
            default:
              orders = allOrders;
          }
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getEmptyStateMessage(_tabController.index),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ordersStreamProvider);
            },
            child: ResponsiveContainer(
              child: context.isDesktop
                  ? _buildDesktopOrdersList(orders)
                  : _buildMobileOrdersList(orders),
            ),
          );
        },
        loading: () {
          debugPrint('🔍 [VENDOR-ORDERS-SCREEN] ordersStream.loading');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          debugPrint('❌ [VENDOR-ORDERS-SCREEN] ordersStream.error: $error');
          debugPrint('❌ [VENDOR-ORDERS-SCREEN] Stack trace: $stack');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading orders: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    debugPrint('🔄 [VENDOR-ORDERS-SCREEN] Retry button pressed - invalidating ordersStreamProvider');
                    ref.invalidate(ordersStreamProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      );
    }
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
        childAspectRatio: 1.1,
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    final theme = Theme.of(context);

    return Consumer(
      builder: (context, ref, child) {
        // Watch for real-time delivery proof updates
        // TODO: Restore real-time delivery proof updates when implemented
        // ignore: unused_local_variable
        final hasDeliveryUpdate = false; // Temporarily simplified for quick launch
        // ignore: unused_local_variable
        final deliveryProof = null; // Temporarily simplified for quick launch

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Container(
            // TODO: Restore decoration when hasDeliveryUpdate is dynamic
            decoration: null, // Simplified since hasDeliveryUpdate is always false
            child: InkWell(
              onTap: () {
                debugPrint('🔍 [ORDER-CARD-TAP] Order card tapped for order: ${order.id}');
                debugPrint('🔍 [ORDER-CARD-TAP] Order number: ${order.orderNumber}');
                debugPrint('🔍 [ORDER-CARD-TAP] Customer: ${order.customerName}');
                final route = '/vendor/dashboard/order-details/${order.id}';
                debugPrint('🔍 [ORDER-CARD-TAP] Navigating to route: $route');
                debugPrint('🔍 [ORDER-CARD-TAP] About to call context.push()...');
                context.push(route);
                debugPrint('🔍 [ORDER-CARD-TAP] context.push() completed');
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Header with real-time indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                'Order #${order.orderNumber}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // TODO: Restore when hasDeliveryUpdate is dynamic
                              // if (hasDeliveryUpdate) ...[
                              //   const SizedBox(width: 8),
                              //   Container(
                              //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              //     decoration: BoxDecoration(
                              //       color: Colors.green,
                              //       borderRadius: BorderRadius.circular(10),
                              //     ),
                              //     child: Text(
                              //       'UPDATED',
                              //       style: theme.textTheme.labelSmall?.copyWith(
                              //         color: Colors.white,
                              //         fontWeight: FontWeight.bold,
                              //       ),
                              //     ),
                              //   ),
                              // ],
                            ],
                          ),
                        ),
                        Container(
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Customer Info with delivery proof indicator
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.customerName,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        if (deliveryProof != null) ...[
                          Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Delivered',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
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

                    // Payment Method Info
                    _buildPaymentMethodInfo(order, theme),
                    const SizedBox(height: 8),

                    // Order Items Summary
                    Text(
                      '${order.items.length} item(s)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Delivery Info
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Delivery: ${order.deliveryDate.toString().split(' ')[0]}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const Spacer(),
                        if (order.status == OrderStatus.pending ||
                            order.status == OrderStatus.confirmed ||
                            order.status == OrderStatus.preparing ||
                            (order.status == OrderStatus.ready && order.vendorCanHandleDelivery))
                          _buildQuickActions(order),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(Order order) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (order.status == OrderStatus.pending) ...[
          _buildActionButton(
            'Accept',
            Icons.check,
            Colors.green,
            () => _updateOrderStatus(order, OrderStatus.confirmed),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            'Reject',
            Icons.close,
            Colors.red,
            () => _updateOrderStatus(order, OrderStatus.cancelled),
          ),
        ] else if (order.status == OrderStatus.confirmed) ...[
          _buildActionButton(
            'Start Preparing',
            Icons.restaurant,
            Colors.blue,
            () => _updateOrderStatus(order, OrderStatus.preparing),
          ),
        ] else if (order.status == OrderStatus.preparing) ...[
          _buildActionButton(
            'Mark as Ready',
            Icons.check_circle,
            Colors.teal,
            () => _updateOrderStatus(order, OrderStatus.ready),
          ),
        ] else if (order.status == OrderStatus.ready && order.vendorCanHandleDelivery) ...[
          _buildActionButton(
            'Assign Driver',
            Icons.local_shipping,
            Colors.indigo,
            () => _showAssignDriverDialog(order),
          ),
        ],
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

  Widget _buildPaymentMethodInfo(Order order, ThemeData theme) {
    // Handle cases where payment method might be null or empty
    if (order.paymentMethod == null || order.paymentMethod!.isEmpty) {
      return Row(
        children: [
          Icon(
            Icons.payment,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            'Payment method not specified',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    // Get display name for payment method
    String paymentMethodDisplay;
    try {
      final paymentMethod = PaymentMethod.fromString(order.paymentMethod!);
      paymentMethodDisplay = paymentMethod.displayName;
    } catch (e) {
      // Fallback to raw value if enum parsing fails
      paymentMethodDisplay = order.paymentMethod!.replaceAll('_', ' ').toUpperCase();
    }

    // Get payment status display
    String? paymentStatusDisplay;
    Color? statusColor;
    if (order.paymentStatus != null && order.paymentStatus!.isNotEmpty) {
      try {
        final paymentStatus = PaymentStatus.fromString(order.paymentStatus!);
        paymentStatusDisplay = paymentStatus.displayName;
        statusColor = _getPaymentStatusColor(paymentStatus);
      } catch (e) {
        paymentStatusDisplay = order.paymentStatus!.toUpperCase();
        statusColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
      }
    }

    return Row(
      children: [
        Icon(
          _getPaymentMethodIcon(order.paymentMethod!),
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          paymentMethodDisplay,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
        if (paymentStatusDisplay != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor?.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: statusColor?.withValues(alpha: 0.3) ?? Colors.transparent,
                width: 1,
              ),
            ),
            child: Text(
              paymentStatusDisplay,
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.paid:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.blue;
    }
  }

  IconData _getPaymentMethodIcon(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'fpx':
        return Icons.account_balance;
      case 'grabpay':
        return Icons.payment;
      case 'touchngo':
      case 'touch_n_go':
        return Icons.contactless;
      case 'credit_card':
      case 'card':
        return Icons.credit_card;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'cash':
      case 'cod':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Update order status via repository
      final orderRepository = ref.read(orderRepositoryProvider);
      await orderRepository.updateOrderStatus(order.id, newStatus);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order #${order.orderNumber} updated to ${newStatus.displayName}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the orders list for both web and mobile platforms
        if (kIsWeb) {
          ref.invalidate(platformOrdersProvider);
        } else {
          ref.invalidate(ordersStreamProvider);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getEmptyStateMessage(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'No orders being prepared';
      case 1:
        return 'No orders ready for pickup/delivery';
      case 2:
        return 'No upcoming orders';
      case 3:
        return 'No order history';
      default:
        return 'No orders yet';
    }
  }

  void _showAssignDriverDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AssignDriverDialog(
        orderId: order.id, // TODO: Fix parameter name when AssignDriverDialog is updated
        // order: order,
        onDriverAssigned: (String driverId) {
          // Refresh the orders list
          if (kIsWeb) {
            ref.invalidate(platformOrdersProvider);
          } else {
            ref.invalidate(ordersStreamProvider);
          }
        },
      ),
    );
  }
}
