import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// TODO: Restore when ReorderResult is implemented
// Import ReorderResult from the reorder service
// import '../../../data/services/customer/customer_reorder_service.dart' show ReorderResult;
import 'package:intl/intl.dart';

import '../../../data/models/order.dart';
import '../../../data/models/delivery_method.dart';
import '../../../../../presentation/providers/repository_providers.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../../../../shared/widgets/error_widget.dart';
import '../../../../../design_system/widgets/buttons/ge_button.dart';
import '../../../../customers/presentation/widgets/customer_order_tracking_widget.dart';
// TODO: Restore when customer services are implemented
// import '../../../../customers/data/services/customer_reorder_service.dart';
// import '../../../../customers/data/services/customer_rating_service.dart';
// import '../../../../customers/presentation/screens/customer_order_rating_screen.dart';
import '../../providers/enhanced_order_provider.dart';
import '../../../../customers/presentation/providers/customer_order_provider.dart';

class CustomerOrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const CustomerOrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<CustomerOrderDetailsScreen> createState() => _CustomerOrderDetailsScreenState();
}

class _CustomerOrderDetailsScreenState extends ConsumerState<CustomerOrderDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Watch the customer order provider that includes order items
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: orderAsync.when(
          data: (order) => Text(order != null ? 'Order #${order.orderNumber}' : 'Order Details'),
          loading: () => const Text('Order Details'),
          error: (error, _) => const Text('Order Details'),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Invalidate the provider to force refresh
              ref.invalidate(orderByIdProvider(widget.orderId));
            },
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return _buildOrderNotFound();
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(orderByIdProvider(widget.orderId));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Status Header
                  _buildStatusHeader(order),

                  const SizedBox(height: 24),

                  // Order Tracking Widget (for active orders)
                  if (order.status != OrderStatus.delivered &&
                      order.status != OrderStatus.cancelled)
                    CustomerOrderTrackingWidget(
                      orderId: order.id,
                    ),

                  if (order.status != OrderStatus.delivered &&
                      order.status != OrderStatus.cancelled)
                    const SizedBox(height: 24),

                  // Vendor Information
                  _buildVendorInfo(order),

                  const SizedBox(height: 24),

                  // Order Items
                  _buildOrderItems(order),

                  const SizedBox(height: 24),

                  // Order Summary
                  _buildOrderSummary(order),

                  const SizedBox(height: 24),

                  // Delivery Information
                  _buildDeliveryInfo(order),

                  const SizedBox(height: 24),

                  // Customer Actions
                  _buildCustomerActions(order),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, stackTrace) => CustomErrorWidget(
          message: 'Failed to load order details: ${error.toString()}',
          onRetry: () {
            ref.invalidate(orderByIdProvider(widget.orderId));
          },
        ),
      ),
    );
  }

  Widget _buildOrderNotFound() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Order Not Found',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The order you\'re looking for could not be found.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GEButton.primary(
              text: 'Back to Orders',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Order order) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Status',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(order.status, theme),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow('Order Number', '#${order.orderNumber}'),
            _buildDetailRow('Order Date', _formatMalaysianDateTime(order.createdAt)),
            if (order.estimatedDeliveryTime != null)
              _buildDetailRow('Estimated Delivery', _formatMalaysianDateTime(order.estimatedDeliveryTime!)),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorInfo(Order order) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurant Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.vendorName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Restaurant Location',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _contactVendor(order),
                  icon: const Icon(Icons.phone),
                  tooltip: 'Contact Restaurant',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(Order order) {
    final theme = Theme.of(context);

    debugPrint('🔍 [ORDER-DETAILS-UI] _buildOrderItems called for order ${order.orderNumber}');
    debugPrint('🔍 [ORDER-DETAILS-UI] Order has ${order.items.length} items');

    if (order.items.isEmpty) {
      debugPrint('🔍 [ORDER-DETAILS-UI] ⚠️ Order ${order.orderNumber} has NO ITEMS - this is the bug!');
    } else {
      for (int i = 0; i < order.items.length; i++) {
        final item = order.items[i];
        debugPrint('🔍 [ORDER-DETAILS-UI] Item ${i + 1}: ${item.name} (qty: ${item.quantity})');
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items (${order.items.length})',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            ...order.items.map((item) => _buildOrderItem(item, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.fastfood,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
                if (item.customizations?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Customizations: ${_formatCustomizations(item.customizations!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (item.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Notes: ${item.notes}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.quantity}x',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'RM ${item.totalPrice.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Order order) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildSummaryRow('Subtotal', 'RM ${order.subtotal.toStringAsFixed(2)}'),
            _buildSummaryRow('Delivery Fee', 'RM ${order.deliveryFee.toStringAsFixed(2)}'),
            _buildSummaryRow('SST (6%)', 'RM ${order.sstAmount.toStringAsFixed(2)}'),
            const Divider(height: 24),
            _buildSummaryRow(
              'Total Amount',
              'RM ${order.totalAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),

            if (order.paymentMethod != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow('Payment Method', _getPaymentMethodDisplay(order.paymentMethod!)),
              if (order.paymentStatus != null)
                _buildDetailRow('Payment Status', _getPaymentStatusDisplay(order.paymentStatus!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo(Order order) {
    final theme = Theme.of(context);

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

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Address',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatAddress(order.deliveryAddress),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (order.contactPhone != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Contact: ${order.contactPhone}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],

            if (order.specialInstructions?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Special Instructions',
                          style: theme.textTheme.titleSmall?.copyWith(
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
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerActions(Order order) {
    final theme = Theme.of(context);
    final deliveryMethod = order.effectiveDeliveryMethod;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons based on order status and delivery method
            if (order.status == OrderStatus.delivered) ...[
              Row(
                children: [
                  Expanded(
                    child: GEButton.primary(
                      text: 'Reorder',
                      onPressed: () => _reorder(order),
                      icon: Icons.refresh,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GEButton.secondary(
                      text: 'Rate Order',
                      onPressed: () => _rateOrder(order),
                      icon: Icons.star,
                    ),
                  ),
                ],
              ),
            ] else if (order.status == OrderStatus.cancelled) ...[
              GEButton.secondary(
                text: 'Contact Support',
                onPressed: () => _contactSupport(order),
                icon: Icons.support_agent,
              ),
            ] else ...[
              // Active order actions based on delivery method
              if (deliveryMethod.isPickup) ...[
                _buildPickupActions(order, theme),
              ] else ...[
                _buildDeliveryActions(order, theme),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // Helper methods
  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? theme.colorScheme.onSurface : theme.colorScheme.outline,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTotal ? theme.colorScheme.primary : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status, ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        statusText = 'Pending';
        break;
      case OrderStatus.confirmed:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        statusText = 'Confirmed';
        break;
      case OrderStatus.preparing:
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        statusText = 'Preparing';
        break;
      case OrderStatus.ready:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        statusText = 'Ready';
        break;
      case OrderStatus.outForDelivery:
        backgroundColor = Colors.indigo.shade100;
        textColor = Colors.indigo.shade800;
        statusText = 'Out for Delivery';
        break;
      case OrderStatus.delivered:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        statusText = 'Delivered';
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Utility methods
  String _formatMalaysianDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy, hh:mm a').format(dateTime);
  }

  String _getPaymentMethodDisplay(String paymentMethod) {
    debugPrint('🔍 [CUSTOMER-ORDER-DETAILS] Getting payment method display for: "$paymentMethod"');

    // Use the PaymentMethod enum for consistent display logic
    try {
      debugPrint('🔍 [CUSTOMER-ORDER-DETAILS] Attempting to parse payment method with enum: "$paymentMethod"');
      final method = PaymentMethod.fromString(paymentMethod);
      debugPrint('✅ [CUSTOMER-ORDER-DETAILS] Payment method parsed successfully: ${method.value} -> ${method.displayName}');
      return method.displayName;
    } catch (e) {
      // Fallback to uppercase formatting if enum parsing fails
      final fallbackDisplay = paymentMethod.toUpperCase();
      debugPrint('⚠️ [CUSTOMER-ORDER-DETAILS] Enum parsing failed, using fallback display for "$paymentMethod": "$fallbackDisplay"');
      debugPrint('⚠️ [CUSTOMER-ORDER-DETAILS] Error details: $e');
      return fallbackDisplay;
    }
  }

  String _getPaymentStatusDisplay(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      default:
        return paymentStatus.toUpperCase();
    }
  }

  String _formatAddress(Address address) {
    final parts = [
      address.street,
      address.city,
      '${address.postalCode} ${address.state}',
      address.country,
    ];
    return parts.where((part) => part.isNotEmpty).join(', ');
  }

  // Action methods
  void _contactVendor(Order order) {
    // TODO: Implement vendor contact functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact vendor functionality coming soon!'),
      ),
    );
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

      // TODO: Restore when customerReorderServiceProvider is implemented
      // final reorderService = ref.read(customerReorderServiceProvider);
      // final result = await reorderService.reorderFromOrder(order, ref);
      // final result = false; // Temporary placeholder - unused variable

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        // TODO: Restore when customerReorderServiceProvider is implemented
        // if (result.success) {
        //   // Show success dialog with details
        //   _showReorderResultDialog(result);
        // } else {
        //   // Show error
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text(result.error ?? 'Failed to reorder items'),
        //       backgroundColor: Colors.red,
        //     ),
        //   );
        // }

        // Temporary placeholder
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reorder functionality not yet implemented'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during reorder: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // TODO: Restore unused method _showReorderResultDialog when reorder functionality is implemented
  // void _showReorderResultDialog(dynamic result) {
  //   // Placeholder method - implementation commented out due to ReorderResult dependency
  // }


  Future<void> _rateOrder(Order order) async {
    // TODO: Restore when canRateOrderProvider is implemented
    // Check if order can be rated
    // final canRate = await ref.read(canRateOrderProvider(order.id).future);

    // Temporary: Check if order can be rated based on status
    final canRate = order.status == OrderStatus.delivered;

    if (!canRate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              order.status == OrderStatus.delivered
                  ? 'You have already rated this order'
                  : 'You can only rate delivered orders'
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Navigate to rating screen
    if (mounted) {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            // TODO: Restore when CustomerOrderRatingScreen is implemented
            // child: CustomerOrderRatingScreen(order: order),
            child: const Center(
              child: Text('Rating screen not yet implemented'),
            ),
          ),
        ),
      );

      // If rating was submitted successfully, show a success message
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your rating!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _contactSupport(Order order) {
    // Navigate to support screen with order context
    context.push('/customer/support/create-ticket?orderId=${order.id}');
  }

  // Delivery-specific action methods
  Widget _buildPickupActions(Order order, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ready for pickup notification
        if (order.status == OrderStatus.ready) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready for Pickup!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your order is ready for collection',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Pickup actions
        Builder(
          builder: (context) {
            // Debug logging for button visibility
            debugPrint('🔍 [BUTTON-DEBUG] Checking pickup button visibility...');
            debugPrint('🔍 [BUTTON-DEBUG] Order status: ${order.status}');
            debugPrint('🔍 [BUTTON-DEBUG] Order delivery method: ${order.deliveryMethod}');
            debugPrint('🔍 [BUTTON-DEBUG] Effective delivery method: ${order.effectiveDeliveryMethod}');
            debugPrint('🔍 [BUTTON-DEBUG] Status == ready: ${order.status == OrderStatus.ready}');
            debugPrint('🔍 [BUTTON-DEBUG] Effective delivery == customerPickup: ${order.effectiveDeliveryMethod == DeliveryMethod.customerPickup}');

            final shouldShowPickupButton = order.status == OrderStatus.ready && order.effectiveDeliveryMethod == DeliveryMethod.customerPickup;
            debugPrint('🔍 [BUTTON-DEBUG] Should show pickup button: $shouldShowPickupButton');

            return Row(
              children: [
                // Only show 'Mark as Picked Up' for customer pickup orders, not sales agent pickup
                if (shouldShowPickupButton) ...[
              Expanded(
                child: GEButton.primary(
                  text: 'Mark as Picked Up',
                  onPressed: () {
                    debugPrint('🔍 [BUTTON-CLICK] Mark as Picked Up button clicked!');
                    debugPrint('🔍 [BUTTON-CLICK] About to call _confirmPickup...');
                    _confirmPickup(order);
                  },
                  icon: Icons.done,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: GEButton.secondary(
                text: 'Contact Vendor',
                onPressed: () => _contactVendor(order),
                icon: Icons.store,
              ),
            ),
          ],
        );
          },
        ),

        // Show pickup location info
        if (order.status != OrderStatus.pending) ...[
          const SizedBox(height: 16),
          _buildPickupLocationInfo(order, theme),
        ],
      ],
    );
  }

  Widget _buildDeliveryActions(Order order, ThemeData theme) {
    final deliveryMethod = order.effectiveDeliveryMethod;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Driver information (if assigned)
        if (order.assignedDriverId != null) ...[
          _buildDriverInfo(order, theme),
          const SizedBox(height: 16),
        ],

        // Delivery actions based on delivery method and status
        Row(
          children: [
            Expanded(
              child: _buildPrimaryDeliveryAction(order, deliveryMethod, theme),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GEButton.secondary(
                text: order.assignedDriverId != null ? 'Contact Driver' : 'Contact Support',
                onPressed: order.assignedDriverId != null
                    ? () => _contactDriver(order)
                    : () => _contactSupport(order),
                icon: order.assignedDriverId != null ? Icons.phone : Icons.support_agent,
              ),
            ),
          ],
        ),

        // Estimated delivery time
        if (order.estimatedDeliveryTime != null) ...[
          const SizedBox(height: 16),
          _buildEstimatedDeliveryInfo(order, theme),
        ],
      ],
    );
  }

  /// Builds the primary action button based on delivery method and order status
  Widget _buildPrimaryDeliveryAction(Order order, DeliveryMethod deliveryMethod, ThemeData theme) {
    switch (deliveryMethod) {
      case DeliveryMethod.ownFleet:
        // For own fleet, show track only if driver is assigned and order is out for delivery
        if (order.status == OrderStatus.outForDelivery && order.assignedDriverId != null) {
          return GEButton.primary(
            text: 'Track Order',
            onPressed: () => _trackOrder(order),
            icon: Icons.location_on,
          );
        } else {
          return GEButton.primary(
            text: 'Order Status',
            onPressed: () => _showOrderStatusInfo(order),
            icon: Icons.info_outline,
          );
        }

      // TODO: Restore when lalamove delivery method is implemented
      // case DeliveryMethod.lalamove:
      //   // For Lalamove, show tracking info or status
      //   if (order.status == OrderStatus.outForDelivery) {
      //     return CustomButton(
      //       text: 'Track Delivery',
      //       onPressed: () => _showLalamoveTrackingInfo(order),
      //       type: ButtonType.primary,
      //       icon: Icons.delivery_dining,
      //     );
      //   } else {
      //     return CustomButton(
      //       text: 'Order Status',
      //       onPressed: () => _showOrderStatusInfo(order),
      //       type: ButtonType.primary,
      //       icon: Icons.info_outline,
      //     );
      //   }

      case DeliveryMethod.customerPickup:
      case DeliveryMethod.salesAgentPickup:
        // This shouldn't happen as pickup orders use _buildPickupActions
        return GEButton.primary(
          text: 'Order Status',
          onPressed: () => _showOrderStatusInfo(order),
          icon: Icons.info_outline,
        );

      case DeliveryMethod.thirdParty:
        // For third-party delivery, show appropriate action based on status
        if (order.status == OrderStatus.outForDelivery) {
          return GEButton.primary(
            text: 'Track Delivery',
            onPressed: () => _showOrderStatusInfo(order),
            icon: Icons.delivery_dining,
          );
        } else {
          return GEButton.primary(
            text: 'View Details',
            onPressed: () => _showOrderStatusInfo(order),
            icon: Icons.info_outline,
          );
        }
    }
  }

  // Helper methods for delivery-specific UI components
  Widget _buildPickupLocationInfo(Order order, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.store,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pickup Location',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.vendorName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatAddress(order.deliveryAddress),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (order.readyAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ready since ${_formatMalaysianDateTime(order.readyAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDriverInfo(Order order, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.delivery_dining,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Driver Information',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Driver assigned to your order',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Driver ID: ${order.assignedDriverId}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimatedDeliveryInfo(Order order, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Delivery',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMalaysianDateTime(order.estimatedDeliveryTime!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Action methods for delivery-specific functionality
  Future<void> _confirmPickup(Order order) async {
    debugPrint('🔍 [PICKUP-DEBUG] ===== _confirmPickup method called =====');
    debugPrint('🔍 [PICKUP-DEBUG] Order ID: ${order.id}');
    debugPrint('🔍 [PICKUP-DEBUG] Order number: ${order.orderNumber}');
    debugPrint('🔍 [PICKUP-DEBUG] Order status: ${order.status}');
    debugPrint('🔍 [PICKUP-DEBUG] Order delivery method: ${order.deliveryMethod}');
    debugPrint('🔍 [PICKUP-DEBUG] Order effective delivery method: ${order.effectiveDeliveryMethod}');

    try {
      debugPrint('🔍 [PICKUP-DEBUG] Starting pickup confirmation process');
      debugPrint('🔍 [PICKUP-DEBUG] Order ID: ${order.id}');
      debugPrint('🔍 [PICKUP-DEBUG] Order Number: ${order.orderNumber}');
      debugPrint('🔍 [PICKUP-DEBUG] Current order status: ${order.status}');
      debugPrint('🔍 [PICKUP-DEBUG] Target status: delivered');
      debugPrint('🔍 [PICKUP-DEBUG] Delivery method: ${order.deliveryMethod}');
      debugPrint('🔍 [PICKUP-DEBUG] Effective delivery method: ${order.effectiveDeliveryMethod}');
      debugPrint('🔍 [PICKUP-DEBUG] Customer ID: ${order.customerId}');

      // Get current user info for debugging
      final currentUser = Supabase.instance.client.auth.currentUser;
      debugPrint('🔍 [PICKUP-DEBUG] Current authenticated user: ${currentUser?.id}');
      debugPrint('🔍 [PICKUP-DEBUG] Current user email: ${currentUser?.email}');
      debugPrint('🔍 [PICKUP-DEBUG] User matches customer: ${currentUser?.id == order.customerId}');

      // Show confirmation dialog
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

      debugPrint('🔍 [PICKUP-DEBUG] User confirmation result: $confirmed');

      if (confirmed == true && mounted) {
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
        debugPrint('🔍 [PICKUP-DEBUG] About to call orderRepository.updateOrderStatus...');
        debugPrint('🔍 [PICKUP-DEBUG] Order ID: ${order.id}');
        debugPrint('🔍 [PICKUP-DEBUG] Target status: delivered');
        debugPrint('🔍 [PICKUP-DEBUG] Order delivery method: ${order.deliveryMethod}');
        debugPrint('🔍 [PICKUP-DEBUG] Order effective delivery method: ${order.effectiveDeliveryMethod}');

        final orderRepository = ref.read(orderRepositoryProvider);
        debugPrint('🔍 [PICKUP-DEBUG] OrderRepository instance obtained');

        try {
          await orderRepository.updateOrderStatus(order.id, OrderStatus.delivered);
          debugPrint('🔍 [PICKUP-DEBUG] ✅ Order status update completed successfully');
        } catch (e, stackTrace) {
          debugPrint('❌ [PICKUP-DEBUG] Order status update failed: $e');
          debugPrint('❌ [PICKUP-DEBUG] Stack trace: $stackTrace');
          rethrow;
        }

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        // Invalidate providers to trigger real-time updates
        if (mounted) {
          // Invalidate the order details provider to refresh this screen
          ref.invalidate(orderByIdProvider(widget.orderId));

          // Invalidate the enhanced orders provider to update the orders list
          ref.invalidate(enhancedOrdersProvider);

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

  void _showOrderStatusInfo(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Status: ${_getStatusDisplayText(order.status)}'),
            const SizedBox(height: 8),
            Text('Order Number: #${order.orderNumber}'),
            const SizedBox(height: 8),
            Text('Delivery Method: ${order.effectiveDeliveryMethod.displayName}'),
            if (order.estimatedDeliveryTime != null) ...[
              const SizedBox(height: 8),
              Text('Estimated Delivery: ${_formatMalaysianDateTime(order.estimatedDeliveryTime!)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // TODO: Restore unused methods when Lalamove tracking is implemented
  // void _showLalamoveTrackingInfo(Order order) {
  //   // Placeholder method - implementation commented out due to Lalamove dependency
  // }

  // void _showLalamoveTrackingInfoOld(Order order) {
  //   // Placeholder method - implementation commented out due to Lalamove dependency
  // }

  // TODO: Restore unused method _showLalamoveTrackingInfoOldImpl when Lalamove tracking is implemented
  // void _showLalamoveTrackingInfoOldImpl(Order order) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Lalamove Delivery'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text('Your order is being delivered by Lalamove.'),
  //           const SizedBox(height: 16),
  //           const Text('Tracking information:'),
  //           const SizedBox(height: 8),
  //           Text('Order Number: #${order.orderNumber}'),
  //           const SizedBox(height: 8),
  //           Text('Status: ${_getStatusDisplayText(order.status)}'),
  //           if (order.estimatedDeliveryTime != null) ...[
  //             const SizedBox(height: 8),
  //             Text('Estimated Delivery: ${_formatMalaysianDateTime(order.estimatedDeliveryTime!)}'),
  //           ],
  //           const SizedBox(height: 16),
  //           const Text(
  //             'For real-time tracking, please check the Lalamove app or contact customer support.',
  //             style: TextStyle(fontSize: 12),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const Text('Close'),
  //         ),
  //         TextButton(
  //           onPressed: () => _contactSupport(order),
  //           child: const Text('Contact Support'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  String _getStatusDisplayText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  void _contactDriver(Order order) {
    // TODO: Implement driver contact functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Driver contact functionality coming soon!'),
      ),
    );
  }

  // Helper function to format customizations
  String _formatCustomizations(Map<String, dynamic> customizations) {
    final parts = <String>[];

    customizations.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        // Handle nested customization objects
        if (value.containsKey('name')) {
          parts.add(value['name'].toString());
        } else if (value.containsKey('option_name')) {
          parts.add(value['option_name'].toString());
        } else {
          // Fallback to key if no name found
          parts.add(key);
        }
      } else if (value is List) {
        // Handle list of customization options
        for (var option in value) {
          if (option is Map<String, dynamic>) {
            if (option.containsKey('name')) {
              parts.add(option['name'].toString());
            } else if (option.containsKey('option_name')) {
              parts.add(option['option_name'].toString());
            }
          } else {
            parts.add(option.toString());
          }
        }
      } else if (value is String && value.isNotEmpty) {
        // Handle simple string values
        parts.add(value);
      } else if (value != null) {
        // Handle other non-null values
        parts.add(value.toString());
      }
    });

    return parts.isNotEmpty ? parts.join(', ') : 'No customizations';
  }
}
