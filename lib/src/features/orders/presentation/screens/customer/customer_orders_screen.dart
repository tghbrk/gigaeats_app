import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/order.dart';
import '../../../data/models/delivery_method.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../customers/presentation/widgets/customer_order_tracking_widget.dart';
import '../../../../customers/presentation/providers/customer_order_provider.dart';
import '../../../../../presentation/providers/repository_providers.dart';
import '../../providers/customer/customer_cart_provider.dart';
import '../../../../menu/data/models/menu_item.dart';


class CustomerOrdersScreen extends ConsumerStatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  ConsumerState<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends ConsumerState<CustomerOrdersScreen>
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
    // Use AsyncNotifierProvider for better state management
    final ordersAsync = ref.watch(currentCustomerOrdersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          // Real-time connection indicator
          ordersAsync.when(
            data: (_) => Container(
              margin: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Live',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            loading: () => Container(
              margin: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            error: (error, _) => Container(
              margin: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.signal_wifi_connected_no_internet_4,
                size: 20,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
          indicatorColor: theme.colorScheme.onPrimary,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: ordersAsync.when(
        data: (orders) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(_getActiveOrders(orders)),
              _buildOrdersList(_getCompletedOrders(orders)),
              _buildOrdersList(_getCancelledOrders(orders)),
            ],
          );
        },
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, _) {
          return _buildErrorState(error.toString());
        },
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  List<Order> _getActiveOrders(List<Order> orders) {
    return orders.where((order) => 
        order.status != OrderStatus.delivered && 
        order.status != OrderStatus.cancelled
    ).toList();
  }

  List<Order> _getCompletedOrders(List<Order> orders) {
    return orders.where((order) => order.status == OrderStatus.delivered).toList();
  }

  List<Order> _getCancelledOrders(List<Order> orders) {
    return orders.where((order) => order.status == OrderStatus.cancelled).toList();
  }

  Widget _buildOrdersList(List<Order> orders) {
    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(currentCustomerOrdersProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final theme = Theme.of(context);

    return Card(
      key: ValueKey('order_${order.id}_${order.status.value}_${order.updatedAt.millisecondsSinceEpoch}'),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Order #${order.orderNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8), // Add spacing between elements
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _buildStatusChip(order.status, theme),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Vendor name
              Text(
                order.vendorName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Order date
              Text(
                _formatOrderDate(order.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 8),

              // Delivery type indicator
              _buildDeliveryTypeChip(order.deliveryMethod, theme),

              const SizedBox(height: 12),
              
              // Order items preview
              Text(
                _getOrderItemsPreview(order),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Payment method information
              Row(
                children: [
                  Icon(
                    Icons.payment,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getPaymentMethodDisplay(order.paymentMethod),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              
              // Order total and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RM ${order.totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (_buildOrderActionButton(order) != null)
                    _buildOrderActionButton(order)!,
                ],
              ),

              // Live tracking widget for out-for-delivery orders
              CustomerOrderTrackingWidget(
                orderId: order.id,
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
        textColor = Colors.orange[700]!;
        text = 'Pending';
        break;
      case OrderStatus.confirmed:
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue[700]!;
        text = 'Confirmed';
        break;
      case OrderStatus.preparing:
        backgroundColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple[700]!;
        text = 'Preparing';
        break;
      case OrderStatus.ready:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green[700]!;
        text = 'Ready';
        break;
      case OrderStatus.outForDelivery:
        backgroundColor = Colors.indigo.withValues(alpha: 0.1);
        textColor = Colors.indigo[700]!;
        text = 'Out for Delivery';
        break;
      case OrderStatus.delivered:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green[700]!;
        text = 'Delivered';
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red[700]!;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 11, // Make text slightly smaller
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No orders yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start ordering from your favorite restaurants',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Browse Restaurants',
              onPressed: () => context.push('/customer/restaurants'),
              type: ButtonType.primary,
              icon: Icons.restaurant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Try Again',
              onPressed: () async => await ref.read(currentCustomerOrdersProvider.notifier).refresh(),
              type: ButtonType.primary,
              isExpanded: false,
            ),
          ],
        ),
      ),
    );
  }

  String _formatOrderDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today, ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
      // TODO: Restore when lalamove delivery method is implemented
      // case DeliveryMethod.lalamove:
      //   icon = Icons.delivery_dining;
      //   color = Colors.orange;
      //   label = 'Lalamove';
      //   break;

      case DeliveryMethod.thirdParty:
        icon = Icons.local_shipping;
        color = Colors.purple;
        label = 'Third Party';
        break;
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

  String _getOrderItemsPreview(Order order) {
    if (order.items.isEmpty) return 'No items';

    // Show all items with quantities in comma-separated format
    final itemDescriptions = order.items.map((item) => '${item.quantity}x ${item.name}').toList();

    // Join with commas, but limit display to avoid overly long text
    final preview = itemDescriptions.join(', ');

    // If the preview is too long (more than 80 characters), truncate and show count
    if (preview.length > 80) {
      final firstTwo = itemDescriptions.take(2).join(', ');
      final remainingCount = order.items.length - 2;
      if (remainingCount > 0) {
        return '$firstTwo and $remainingCount more item${remainingCount > 1 ? 's' : ''}';
      }
      return firstTwo;
    }

    return preview;
  }

  /// Converts payment method string to user-friendly display name
  String _getPaymentMethodDisplay(String? paymentMethod) {
    if (paymentMethod == null || paymentMethod.isEmpty) {
      return 'Payment method not specified';
    }

    switch (paymentMethod.toLowerCase()) {
      case 'credit_card':
      case 'card':
        return 'Credit/Debit Card';
      case 'wallet':
        return 'GigaEats Wallet';
      case 'cash':
        return 'Cash on Delivery';
      case 'fpx':
        return 'FPX Online Banking';
      case 'grabpay':
        return 'GrabPay';
      case 'touchngo':
      case 'tng':
        return 'Touch \'n Go eWallet';
      case 'boost':
        return 'Boost';
      case 'shopeepay':
        return 'ShopeePay';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        // Fallback: capitalize first letter and replace underscores with spaces
        return paymentMethod
            .split('_')
            .map((word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : word)
            .join(' ');
    }
  }

  /// Determines the appropriate action button for an order based on its status and delivery method
  Widget? _buildOrderActionButton(Order order) {
    // For delivered orders, show reorder button
    if (order.status == OrderStatus.delivered) {
      return CustomButton(
        text: 'Reorder',
        onPressed: () => _reorder(order),
        type: ButtonType.secondary,
        isExpanded: false,
      );
    }

    // For cancelled orders, show contact support
    if (order.status == OrderStatus.cancelled) {
      return CustomButton(
        text: 'Contact Support',
        onPressed: () => _contactSupport(order),
        type: ButtonType.secondary,
        isExpanded: false,
      );
    }

    // For active orders, determine button based on delivery method and status
    final deliveryMethod = order.effectiveDeliveryMethod;

    switch (deliveryMethod) {
      case DeliveryMethod.customerPickup:
        // For customer pickup orders, show pickup confirmation action when ready
        if (order.status == OrderStatus.ready) {
          return CustomButton(
            text: 'Mark as Picked Up',
            onPressed: () => _confirmPickup(order),
            type: ButtonType.primary,
            isExpanded: false,
            icon: Icons.done,
          );
        } else {
          return CustomButton(
            text: 'Order Status',
            onPressed: () => _showOrderDetails(order),
            type: ButtonType.primary,
            isExpanded: false,
          );
        }

      case DeliveryMethod.salesAgentPickup:
        // For sales agent pickup orders, show appropriate action based on status
        if (order.status == OrderStatus.ready) {
          return CustomButton(
            text: 'Ready for Pickup',
            onPressed: () => _showOrderDetails(order),
            type: ButtonType.primary,
            isExpanded: false,
          );
        } else {
          return CustomButton(
            text: 'Order Status',
            onPressed: () => _showOrderDetails(order),
            type: ButtonType.primary,
            isExpanded: false,
          );
        }

      case DeliveryMethod.ownFleet:
        // For own fleet, show track only if driver is assigned and order is out for delivery
        if (order.status == OrderStatus.outForDelivery && order.assignedDriverId != null) {
          return CustomButton(
            text: 'Track Order',
            onPressed: () => _trackOrder(order),
            type: ButtonType.primary,
            isExpanded: false,
          );
        } else {
          return CustomButton(
            text: 'Order Status',
            onPressed: () => _showOrderDetails(order),
            type: ButtonType.primary,
            isExpanded: false,
          );
        }

      // TODO: Restore when lalamove delivery method is implemented
      // case DeliveryMethod.lalamove:
      //   // For Lalamove, show appropriate action based on status
      //   if (order.status == OrderStatus.outForDelivery) {
      //     return CustomButton(
      //       text: 'Track Delivery',
      //       onPressed: () => _showOrderDetails(order), // Show details with Lalamove tracking info
      //       type: ButtonType.primary,
      //       isExpanded: false,
      //     );
      //   } else {
      //     return CustomButton(
      //       text: 'Order Status',
      //       onPressed: () => _showOrderDetails(order),
      //       type: ButtonType.primary,
      //       isExpanded: false,
      //     );
      //   }

      case DeliveryMethod.thirdParty:
        // For third-party delivery, show appropriate action based on status
        if (order.status == OrderStatus.outForDelivery) {
          return CustomButton(
            text: 'Track Delivery',
            onPressed: () => _showOrderDetails(order),
            type: ButtonType.primary,
            isExpanded: false,
          );
        } else {
          return CustomButton(
            text: 'View Details',
            onPressed: () => _showOrderDetails(order),
            type: ButtonType.primary,
            isExpanded: false,
          );
        }
    }
  }

  void _showOrderDetails(Order order) {
    context.push('/customer/order/${order.id}');
  }

  void _trackOrder(Order order) {
    context.push('/customer/order/${order.id}/track');
  }

  Future<void> _reorder(Order order) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Adding items to cart...'),
            ],
          ),
        ),
      );

      final cartNotifier = ref.read(customerCartProvider.notifier);

      // Clear existing cart to avoid conflicts
      cartNotifier.clearCart();

      // Add each order item back to the cart
      for (final orderItem in order.items) {
        // Create a MenuItem from the OrderItem
        final menuItem = MenuItem(
          id: orderItem.menuItemId,
          vendorId: order.vendorId,
          name: orderItem.name,
          description: orderItem.description,
          category: 'Reorder', // Default category for reordered items
          basePrice: orderItem.unitPrice,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        cartNotifier.addMenuItem(
          menuItem: menuItem,
          vendorName: order.vendorName,
          quantity: orderItem.quantity,
          customizations: orderItem.customizations,
          notes: orderItem.notes,
        );
      }

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        // Show success message and navigate to cart
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${order.items.length} items added to cart'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () => context.push('/customer/cart'),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding items to cart: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _contactSupport(Order order) {
    // Navigate to support screen with order context
    context.push('/customer/support/create-ticket?orderId=${order.id}');
  }

  /// Confirms pickup for customer pickup orders directly from the orders list
  Future<void> _confirmPickup(Order order) async {
    debugPrint('🔍 [ORDERS-LIST-PICKUP] ===== _confirmPickup method called =====');
    debugPrint('🔍 [ORDERS-LIST-PICKUP] Order ID: ${order.id}');
    debugPrint('🔍 [ORDERS-LIST-PICKUP] Order number: ${order.orderNumber}');
    debugPrint('🔍 [ORDERS-LIST-PICKUP] Order status: ${order.status}');
    debugPrint('🔍 [ORDERS-LIST-PICKUP] Order delivery method: ${order.deliveryMethod}');
    debugPrint('🔍 [ORDERS-LIST-PICKUP] Order effective delivery method: ${order.effectiveDeliveryMethod}');

    try {
      // Show confirmation dialog
      debugPrint('🔍 [ORDERS-LIST-PICKUP] Showing confirmation dialog...');
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Pickup'),
          content: Text(
            'Are you sure you have picked up order #${order.orderNumber}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      debugPrint('🔍 [ORDERS-LIST-PICKUP] User confirmation result: $confirmed');
      if (confirmed == true && mounted) {
        debugPrint('🔍 [ORDERS-LIST-PICKUP] User confirmed pickup, proceeding with status update...');
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Confirming pickup...'),
              ],
            ),
          ),
        );

        // Update order status to delivered for pickup orders
        debugPrint('🔍 [ORDERS-LIST-PICKUP] About to call orderRepository.updateOrderStatus...');
        debugPrint('🔍 [ORDERS-LIST-PICKUP] Order ID: ${order.id}');
        debugPrint('🔍 [ORDERS-LIST-PICKUP] Target status: delivered');

        final orderRepository = ref.read(orderRepositoryProvider);
        debugPrint('🔍 [ORDERS-LIST-PICKUP] OrderRepository instance obtained');

        try {
          await orderRepository.updateOrderStatus(order.id, OrderStatus.delivered);
          debugPrint('🔍 [ORDERS-LIST-PICKUP] ✅ Order status update completed successfully');
        } catch (e, stackTrace) {
          debugPrint('❌ [ORDERS-LIST-PICKUP] Order status update failed: $e');
          debugPrint('❌ [ORDERS-LIST-PICKUP] Stack trace: $stackTrace');
          rethrow;
        }

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        // Invalidate providers to trigger real-time updates
        if (mounted) {
          // Invalidate the current customer orders provider to refresh the list
          ref.invalidate(currentCustomerOrdersRealtimeProvider);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order #${order.orderNumber} marked as picked up successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error confirming pickup: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 3, // Orders is selected
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/customer/dashboard');
            break;
          case 1:
            context.push('/customer/restaurants');
            break;
          case 2:
            context.push('/customer/cart');
            break;
          case 3:
            // Already on orders
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
}
