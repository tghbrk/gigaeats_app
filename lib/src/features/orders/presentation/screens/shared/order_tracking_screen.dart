import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../data/models/order.dart';
import '../../../data/models/delivery_method.dart';
import '../../providers/order_provider.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  @override
  void initState() {
    super.initState();
    // Load order details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ordersProvider.notifier).loadOrderById(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {

    final ordersState = ref.watch(ordersProvider);

    // Find the specific order
    Order? order;
    try {
      order = ordersState.orders.firstWhere(
        (o) => o.id == widget.orderId,
      );
    } catch (e) {
      // Order not found in current state
      order = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(order != null ? 'Track Order #${order.orderNumber}' : 'Order Details'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _refreshOrder(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          if (order != null)
            IconButton(
              onPressed: () => _shareOrder(order!),
              icon: const Icon(Icons.share),
              tooltip: 'Share',
            ),
        ],
      ),
      body: ordersState.isLoading
          ? const LoadingWidget(message: 'Loading order details...')
          : ordersState.errorMessage != null
              ? CustomErrorWidget(
                  message: ordersState.errorMessage!,
                  onRetry: () => _refreshOrder(),
                )
              : order == null
                  ? _buildOrderNotFound()
                  : RefreshIndicator(
                      onRefresh: () async => _refreshOrder(),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order Status Header
                            _buildStatusHeader(order),

                            const SizedBox(height: 24),

                            // Order Timeline
                            _buildOrderTimeline(order),

                            const SizedBox(height: 24),

                            // Order Details
                            _buildOrderDetails(order),

                            const SizedBox(height: 24),

                            // Delivery Information
                            _buildDeliveryInfo(order),

                            const SizedBox(height: 24),

                            // Contact Actions
                            _buildContactActions(order),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildOrderNotFound() {
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
              'Order Not Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The order you are looking for could not be found.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Order order) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(order.status);

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withValues(alpha: 0.1),
              statusColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              _getStatusIcon(order.status),
              size: 60,
              color: statusColor,
            ),
            const SizedBox(height: 12),
            Text(
              order.status.displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusDescription(order.status),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Estimated delivery: ${_formatDeliveryTime(order.deliveryDate)}',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTimeline(Order order) {
    final theme = Theme.of(context);
    final timelineSteps = _getTimelineSteps(order);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Progress',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ...timelineSteps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == timelineSteps.length - 1;
              
              return _buildTimelineStep(step, isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(TimelineStep step, bool isLast) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: step.isCompleted
                    ? step.color
                    : step.color.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: step.color,
                  width: 2,
                ),
              ),
              child: step.isCompleted
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: step.isCompleted
                    ? step.color.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Step content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: step.isCompleted
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (step.timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(step.timestamp!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: step.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails(Order order) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow('Order Number', '#${order.orderNumber}'),
            _buildDetailRow('Customer', order.customerName),
            _buildDetailRow('Vendor', order.vendorName),
            _buildDetailRow('Order Date', _formatDate(order.createdAt)),
            _buildDetailRow('Total Amount', 'RM ${order.totalAmount.toStringAsFixed(2)}'),
            
            const SizedBox(height: 16),
            
            Text(
              'Items (${order.items.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            ...order.items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${item.quantity}x'),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        item.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      )),
                      Text(
                        'RM ${item.totalPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  // Add customizations display
                  if (item.customizations != null && item.customizations!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Customizations: ${_formatCustomizations(item.customizations!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: ${item.notes}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo(Order order) {
    final theme = Theme.of(context);
    final deliveryMethod = order.deliveryMethod;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Delivery Method Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _getDeliveryMethodIcon(deliveryMethod),
                  color: _getDeliveryMethodColor(deliveryMethod),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Method',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getDeliveryMethodColor(deliveryMethod).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getDeliveryMethodColor(deliveryMethod).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          deliveryMethod.displayName,
                          style: TextStyle(
                            color: _getDeliveryMethodColor(deliveryMethod),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getDeliveryMethodDescription(deliveryMethod),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Address or Pickup Location Section
            _buildAddressSection(order, deliveryMethod, theme),

            const SizedBox(height: 20),

            // Delivery Time Section
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deliveryMethod.isPickup ? 'Pickup Time' : 'Delivery Time',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDeliveryTime(order.deliveryDate),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Driver Information (for delivery methods that require drivers)
            if (deliveryMethod.requiresDriver && order.assignedDriverId != null)
              _buildDriverSection(order, theme),

            // Special Instructions
            if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty)
              _buildSpecialInstructionsSection(order, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(Order order, DeliveryMethod deliveryMethod, ThemeData theme) {
    if (deliveryMethod.isPickup) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.store,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup Location',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.vendorName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.deliveryAddress.street}\n'
                  '${order.deliveryAddress.city}, ${order.deliveryAddress.state} ${order.deliveryAddress.postalCode}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Address',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.deliveryAddress.street}\n'
                  '${order.deliveryAddress.city}, ${order.deliveryAddress.state} ${order.deliveryAddress.postalCode}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildDriverSection(Order order, ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(
              Icons.person,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned Driver',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Driver ID: ${order.assignedDriverId}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecialInstructionsSection(Order order, ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.note,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Special Instructions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.specialInstructions!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactActions(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need Help?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactVendor(order),
                    icon: const Icon(Icons.store),
                    label: const Text('Contact Vendor'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactSupport(order),
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Support'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  List<TimelineStep> _getTimelineSteps(Order order) {

    final orderDate = order.createdAt;
    
    return [
      TimelineStep(
        title: 'Order Placed',
        description: 'Your order has been placed successfully',
        isCompleted: true,
        color: Colors.green,
        timestamp: orderDate,
      ),
      TimelineStep(
        title: 'Order Confirmed',
        description: 'Vendor has confirmed your order',
        isCompleted: order.status.index >= OrderStatus.confirmed.index,
        color: Colors.blue,
        timestamp: order.status.index >= OrderStatus.confirmed.index 
            ? orderDate.add(const Duration(minutes: 15))
            : null,
      ),
      TimelineStep(
        title: 'Preparing',
        description: 'Your order is being prepared',
        isCompleted: order.status.index >= OrderStatus.preparing.index,
        color: Colors.orange,
        timestamp: order.status.index >= OrderStatus.preparing.index 
            ? orderDate.add(const Duration(minutes: 30))
            : null,
      ),
      TimelineStep(
        title: 'Ready for Pickup',
        description: 'Your order is ready for delivery',
        isCompleted: order.status.index >= OrderStatus.ready.index,
        color: Colors.purple,
        timestamp: order.status.index >= OrderStatus.ready.index 
            ? orderDate.add(const Duration(hours: 1))
            : null,
      ),
      TimelineStep(
        title: 'Out for Delivery',
        description: 'Your order is on the way',
        isCompleted: order.status.index >= OrderStatus.outForDelivery.index,
        color: Colors.indigo,
        timestamp: order.status.index >= OrderStatus.outForDelivery.index 
            ? orderDate.add(const Duration(hours: 1, minutes: 15))
            : null,
      ),
      TimelineStep(
        title: 'Delivered',
        description: 'Your order has been delivered',
        isCompleted: order.status == OrderStatus.delivered,
        color: Colors.green,
        timestamp: order.status == OrderStatus.delivered 
            ? orderDate.add(const Duration(hours: 2))
            : null,
      ),
    ];
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

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.preparing:
        return Icons.kitchen;
      case OrderStatus.ready:
        return Icons.done_all;
      case OrderStatus.outForDelivery:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Waiting for vendor confirmation';
      case OrderStatus.confirmed:
        return 'Order confirmed and will be prepared soon';
      case OrderStatus.preparing:
        return 'Your delicious food is being prepared';
      case OrderStatus.ready:
        return 'Order is ready and waiting for pickup';
      case OrderStatus.outForDelivery:
        return 'Your order is on its way to you';
      case OrderStatus.delivered:
        return 'Order has been successfully delivered';
      case OrderStatus.cancelled:
        return 'This order has been cancelled';
    }
  }

  String _formatDeliveryTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTimestamp(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _refreshOrder() {
    ref.read(ordersProvider.notifier).loadOrderById(widget.orderId);
  }

  void _shareOrder(Order order) {
    // TODO: Implement order sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order sharing coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _contactVendor(Order order) {
    // TODO: Implement vendor contact
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vendor contact coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _contactSupport(Order order) {
    // TODO: Implement support contact
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support contact coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Helper function to format customizations
  String _formatCustomizations(Map<String, dynamic> customizations) {
    final parts = <String>[];
    customizations.forEach((key, value) {
      if (value is Map && value.containsKey('name')) {
        parts.add(value['name']);
      } else if (value is List) {
        for (var option in value) {
          if (option is Map && option.containsKey('name')) {
            parts.add(option['name']);
          }
        }
      }
    });
    return parts.join(', ');
  }

  // Helper methods for delivery method display
  IconData _getDeliveryMethodIcon(DeliveryMethod deliveryMethod) {
    switch (deliveryMethod) {
      case DeliveryMethod.customerPickup:
        return Icons.store;
      case DeliveryMethod.salesAgentPickup:
        return Icons.person;
      case DeliveryMethod.ownFleet:
        return Icons.local_shipping;
      case DeliveryMethod.thirdParty:
        return Icons.delivery_dining;
    }
  }

  Color _getDeliveryMethodColor(DeliveryMethod deliveryMethod) {
    switch (deliveryMethod) {
      case DeliveryMethod.customerPickup:
        return Colors.blue;
      case DeliveryMethod.salesAgentPickup:
        return Colors.green;
      case DeliveryMethod.ownFleet:
        return Colors.purple;
      case DeliveryMethod.thirdParty:
        return Colors.orange;
    }
  }

  String _getDeliveryMethodDescription(DeliveryMethod deliveryMethod) {
    switch (deliveryMethod) {
      case DeliveryMethod.customerPickup:
        return 'Customer will collect the order from the vendor location';
      case DeliveryMethod.salesAgentPickup:
        return 'Sales agent will collect the order from the vendor';
      case DeliveryMethod.ownFleet:
        return 'Order will be delivered using our own delivery fleet';
      case DeliveryMethod.thirdParty:
        return 'Order will be delivered via Lalamove service';
    }
  }
}

class TimelineStep {
  final String title;
  final String description;
  final bool isCompleted;
  final Color color;
  final DateTime? timestamp;

  TimelineStep({
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.color,
    this.timestamp,
  });
}
