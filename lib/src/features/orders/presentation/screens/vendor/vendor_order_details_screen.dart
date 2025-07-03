import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/order.dart';
// import '../../utils/order_status_update_helper.dart';
import '../../../../../presentation/providers/repository_providers.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../../../../shared/widgets/error_widget.dart';
import '../../../../vendors/presentation/widgets/assign_driver_dialog.dart';

class VendorOrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const VendorOrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<VendorOrderDetailsScreen> createState() => _VendorOrderDetailsScreenState();
}

class _VendorOrderDetailsScreenState extends ConsumerState<VendorOrderDetailsScreen> {
  Order? _order;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 [VENDOR-ORDER-DETAILS] initState() called');
    debugPrint('🔍 [VENDOR-ORDER-DETAILS] Widget order ID: ${widget.orderId}');
    debugPrint('🔍 [VENDOR-ORDER-DETAILS] Order ID length: ${widget.orderId.length}');
    debugPrint('🔍 [VENDOR-ORDER-DETAILS] Order ID format check: ${widget.orderId.contains('-')}');
    debugPrint('🔍 [VENDOR-ORDER-DETAILS] About to call _loadOrderDetails()...');
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    debugPrint('🔍 [VENDOR-ORDER-DETAILS] _loadOrderDetails() started');
    debugPrint('🔍 [VENDOR-ORDER-DETAILS] Loading order with ID: ${widget.orderId}');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔍 [VENDOR-ORDER-DETAILS] Getting orderRepository from ref...');
      final orderRepository = ref.read(orderRepositoryProvider);
      debugPrint('🔍 [VENDOR-ORDER-DETAILS] OrderRepository obtained successfully');

      debugPrint('🔍 [VENDOR-ORDER-DETAILS] Calling getOrderById with ID: ${widget.orderId}');
      final order = await orderRepository.getOrderById(widget.orderId);
      debugPrint('🔍 [VENDOR-ORDER-DETAILS] Order fetched successfully: ${order?.id}');
      debugPrint('🔍 [VENDOR-ORDER-DETAILS] Order number: ${order?.orderNumber}');
      debugPrint('🔍 [VENDOR-ORDER-DETAILS] Order customer: ${order?.customerName}');
      debugPrint('🔍 [VENDOR-ORDER-DETAILS] Order status: ${order?.status}');

      if (mounted) {
        debugPrint('🔍 [VENDOR-ORDER-DETAILS] Widget is still mounted, updating state...');
        setState(() {
          _order = order;
          _isLoading = false;
        });
        debugPrint('🔍 [VENDOR-ORDER-DETAILS] State updated successfully');
      } else {
        debugPrint('⚠️ [VENDOR-ORDER-DETAILS] Widget not mounted, skipping state update');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [VENDOR-ORDER-DETAILS] Error loading order details: $e');
      debugPrint('❌ [VENDOR-ORDER-DETAILS] Stack trace: $stackTrace');

      if (mounted) {
        debugPrint('🔍 [VENDOR-ORDER-DETAILS] Widget is mounted, setting error state...');
        setState(() {
          _errorMessage = 'Failed to load order details: ${e.toString()}';
          _isLoading = false;
        });
        debugPrint('🔍 [VENDOR-ORDER-DETAILS] Error state set');
      } else {
        debugPrint('⚠️ [VENDOR-ORDER-DETAILS] Widget not mounted, skipping error state update');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 [VENDOR-ORDER-DETAILS] build() method called');
    debugPrint('🔍 [VENDOR-ORDER-DETAILS] Current state - isLoading: $_isLoading, hasError: ${_errorMessage != null}, hasOrder: ${_order != null}');
    if (_order != null) {
      debugPrint('🔍 [VENDOR-ORDER-DETAILS] Order loaded: ${_order!.orderNumber}');
      debugPrint('🔍 [VENDOR-ORDER-DETAILS] About to render payment info section for order: ${_order!.id}');
    }
    if (_errorMessage != null) {
      debugPrint('🔍 [VENDOR-ORDER-DETAILS] Error message: $_errorMessage');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_order != null ? 'Order #${_order!.orderNumber}' : 'Order Details'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadOrderDetails,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading order details...')
          : _errorMessage != null
              ? CustomErrorWidget(
                  message: _errorMessage!,
                  onRetry: _loadOrderDetails,
                )
              : _order == null
                  ? _buildOrderNotFound()
                  : RefreshIndicator(
                      onRefresh: _loadOrderDetails,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order Status Header
                            _buildStatusHeader(_order!),

                            const SizedBox(height: 24),

                            // Customer Information
                            _buildCustomerInfo(_order!),

                            const SizedBox(height: 24),

                            // Order Items
                            _buildOrderItems(_order!),

                            const SizedBox(height: 24),

                            // Payment Information
                            Builder(
                              builder: (context) {
                                debugPrint('🔍 [VENDOR-ORDER-DETAILS] ===== PAYMENT INFO SECTION BUILDER CALLED =====');
                                try {
                                  final paymentWidget = _buildPaymentInfo(_order!);
                                  debugPrint('🔍 [VENDOR-ORDER-DETAILS] ===== PAYMENT INFO WIDGET CREATED SUCCESSFULLY =====');
                                  return paymentWidget;
                                } catch (e, stack) {
                                  debugPrint('🔍 [VENDOR-ORDER-DETAILS] ===== ERROR BUILDING PAYMENT INFO: $e =====');
                                  debugPrint('🔍 [VENDOR-ORDER-DETAILS] ===== STACK TRACE: $stack =====');
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Text('Error loading payment info: $e'),
                                  );
                                }
                              },
                            ),

                            const SizedBox(height: 24),

                            // Order Summary
                            _buildOrderSummary(_order!),

                            const SizedBox(height: 24),

                            // Delivery Information
                            _buildDeliveryInfo(_order!),

                            const SizedBox(height: 24),

                            // Vendor Actions
                            _buildVendorActions(_order!),

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
              _getVendorStatusDescription(order.status),
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
                'Order Date: ${_formatMalaysianDateTime(order.createdAt)}',
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

  Widget _buildCustomerInfo(Order order) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow('Customer Name', order.customerName),
            if (order.contactPhone != null)
              _buildDetailRow('Contact Phone', order.contactPhone!),
            _buildDetailRow('Order Number', '#${order.orderNumber}'),
            _buildDetailRow('Order Date', _formatMalaysianDateTime(order.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(Order order) {
    final theme = Theme.of(context);

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
            
            ...order.items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                      Expanded(
                        child: Text(
                          item.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        'RM ${item.totalPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Quantity: ${item.quantity}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Unit Price: RM ${item.unitPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  // Add customizations display
                  if (item.customizations != null && item.customizations!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Customizations: ${_formatCustomizations(item.customizations!)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.note,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Note: ${item.notes}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
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
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo(Order order) {
    final theme = Theme.of(context);
    final isPickup = order.deliveryFee == 0.0;

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

            _buildDetailRow('Delivery Type', isPickup ? 'Pickup' : 'Delivery'),
            _buildDetailRow('Delivery Date', _formatMalaysianDate(order.deliveryDate)),

            if (!isPickup) ...[
              const SizedBox(height: 12),
              Row(
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
              ),
            ],

            if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
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
                              color: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.specialInstructions!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVendorActions(Order order) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Order order) {
    switch (order.status) {
      case OrderStatus.pending:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateOrderStatus(order, OrderStatus.confirmed),
                icon: const Icon(Icons.check),
                label: const Text('Accept Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateOrderStatus(order, OrderStatus.cancelled),
                icon: const Icon(Icons.close),
                label: const Text('Reject Order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );

      case OrderStatus.confirmed:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateOrderStatus(order, OrderStatus.preparing),
            icon: const Icon(Icons.restaurant),
            label: const Text('Start Preparing'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );

      case OrderStatus.preparing:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateOrderStatus(order, OrderStatus.ready),
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark as Ready'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );

      case OrderStatus.ready:
        return Column(
          children: [
            // Show different actions based on delivery method
            if (order.vendorCanHandleDelivery) ...[
              // Assign for Delivery Button (only for own fleet)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAssignDriverDialog(order),
                  icon: const Icon(Icons.local_shipping),
                  label: const Text('Assign Driver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              // For pickup orders, show disabled state with explanation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      order.isCustomerPickup ? Icons.store : Icons.person,
                      color: Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.isCustomerPickup
                          ? 'Customer Pickup Order'
                          : 'Sales Agent Pickup Order',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.isCustomerPickup
                          ? 'Customer will collect this order'
                          : 'Sales agent will collect this order',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );

      case OrderStatus.outForDelivery:
        return Column(
          children: [
            // Note: Driver assignment and tracking features will be available after database migration

            // Mark as delivered button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateOrderStatus(order, OrderStatus.delivered),
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark as Delivered'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Reassign driver button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAssignDriverDialog(order),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Reassign Driver'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  side: const BorderSide(color: Colors.indigo),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );

      default:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'No actions available for this order status',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        );
    }
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
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
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

        // Reload order details
        await _loadOrderDetails();
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

  String _getVendorStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'New order waiting for your confirmation';
      case OrderStatus.confirmed:
        return 'Order confirmed - ready to start preparation';
      case OrderStatus.preparing:
        return 'Order is being prepared in your kitchen';
      case OrderStatus.ready:
        return 'Order is ready for pickup or delivery';
      case OrderStatus.outForDelivery:
        return 'Order is out for delivery';
      case OrderStatus.delivered:
        return 'Order has been successfully delivered';
      case OrderStatus.cancelled:
        return 'This order has been cancelled';
    }
  }

  String _formatMalaysianDateTime(DateTime dateTime) {
    // Convert to Malaysian timezone (UTC+8)
    final malaysianTime = dateTime.add(const Duration(hours: 8));
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(malaysianTime);
  }

  String _formatMalaysianDate(DateTime dateTime) {
    // Convert to Malaysian timezone (UTC+8)
    final malaysianTime = dateTime.add(const Duration(hours: 8));
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(malaysianTime);
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

  Widget _buildPaymentInfo(Order order) {
    debugPrint('🔍 [VENDOR-ORDER-DETAILS] Building payment info section');
    debugPrint('🔍 [VENDOR-ORDER-DETAILS] Payment method: ${order.paymentMethod}');
    debugPrint('🔍 [VENDOR-ORDER-DETAILS] Payment status: ${order.paymentStatus}');
    debugPrint('🔍 [VENDOR-ORDER-DETAILS] Payment reference: ${order.paymentReference}');

    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodRow(order, theme),
            if (order.paymentReference != null && order.paymentReference!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildPaymentReferenceRow(order, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodRow(Order order, ThemeData theme) {
    // Handle cases where payment method might be null or empty
    if (order.paymentMethod == null || order.paymentMethod!.isEmpty) {
      debugPrint('🔍 [VENDOR-ORDER-DETAILS] No payment method data available');
      return Row(
        children: [
          Icon(
            Icons.payment,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Payment method not specified',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
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
      debugPrint('🔍 [VENDOR-ORDER-DETAILS] Payment method parsed: $paymentMethodDisplay');
    } catch (e) {
      // Fallback to raw value if enum parsing fails
      paymentMethodDisplay = order.paymentMethod!.replaceAll('_', ' ').toUpperCase();
      debugPrint('🔍 [VENDOR-ORDER-DETAILS] Payment method fallback: $paymentMethodDisplay');
    }

    // Get payment status display
    String? paymentStatusDisplay;
    Color? statusColor;
    if (order.paymentStatus != null && order.paymentStatus!.isNotEmpty) {
      try {
        final paymentStatus = PaymentStatus.fromString(order.paymentStatus!);
        paymentStatusDisplay = paymentStatus.displayName;
        statusColor = _getPaymentStatusColor(paymentStatus);
        debugPrint('🔍 [VENDOR-ORDER-DETAILS] Payment status parsed: $paymentStatusDisplay');
      } catch (e) {
        paymentStatusDisplay = order.paymentStatus!.toUpperCase();
        statusColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
        debugPrint('🔍 [VENDOR-ORDER-DETAILS] Payment status fallback: $paymentStatusDisplay');
      }
    }

    return Row(
      children: [
        Icon(
          _getPaymentMethodIcon(order.paymentMethod!),
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            paymentMethodDisplay,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (paymentStatusDisplay != null) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor?.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentReferenceRow(Order order, ThemeData theme) {
    debugPrint('🔍 [VENDOR-ORDER-DETAILS] Building payment reference: ${order.paymentReference}');

    return Row(
      children: [
        Icon(
          Icons.receipt_outlined,
          size: 20,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Reference',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                order.paymentReference!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            // Copy payment reference to clipboard
            // TODO: Implement clipboard functionality
            debugPrint('🔍 [VENDOR-ORDER-DETAILS] Copy payment reference: ${order.paymentReference}');
          },
          icon: Icon(
            Icons.copy,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          tooltip: 'Copy Reference',
        ),
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

  void _showAssignDriverDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AssignDriverDialog(
        orderId: order.id, // TODO: Fix parameter name when AssignDriverDialog is updated
        // order: order,
        onDriverAssigned: (String driverId) {
          // Refresh the order details
          _loadOrderDetails();
        },
      ),
    );
  }
}
